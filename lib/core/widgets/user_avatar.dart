import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../di/injection_container.dart';
import '../services/auth_service.dart';
import '../theme/brand_tokens.dart';
import '../utils/jwt_payload.dart';

/// Bumps every time we know the cached user changed (e.g. after a
/// successful profile patch). The avatar widgets use it to evict the
/// `Image.network` cache so a fresh photo replaces the previous one
/// even if the URL happens to be identical.
///
/// Exposed via [UserAvatarController.cacheBuster] so screens that
/// render their own avatars (the big circle on the profile page) can
/// participate in the same eviction cycle.
final ValueNotifier<int> _avatarCacheBuster = ValueNotifier<int>(0);

/// In-memory cache of the current tourist's avatar data.
///
/// We can't synchronously read SharedPreferences from `build`, so each
/// `UserAvatar` triggers a one-time async load and stores the result.
/// A [ValueNotifier] broadcasts changes so all avatars across the app
/// refresh after the user updates their photo (the profile cubit calls
/// [refresh] after a successful patch).
class UserAvatarController {
  UserAvatarController._();
  static final UserAvatarController instance = UserAvatarController._();

  final ValueNotifier<UserAvatarData?> _data =
      ValueNotifier<UserAvatarData?>(null);
  Future<void>? _inflight;

  ValueListenable<UserAvatarData?> get listenable => _data;
  ValueListenable<int> get cacheBuster => _avatarCacheBuster;
  UserAvatarData? get current => _data.value;

  Future<UserAvatarData?> ensureLoaded() async {
    if (_data.value != null) return _data.value;
    final existing = _inflight;
    if (existing != null) {
      await existing;
      return _data.value;
    }
    final future = _load();
    _inflight = future;
    try {
      await future;
    } finally {
      _inflight = null;
    }
    return _data.value;
  }

  /// Forces a re-read of the cached user — call after a successful
  /// profile patch so every visible avatar in the app refreshes.
  Future<void> refresh() async {
    _inflight = null;
    await _load();
    // Evict any in-memory copy of the previous photo so `Image.network`
    // re-fetches it (handles backends that serve a new photo at the
    // same URL).
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    _avatarCacheBuster.value = _avatarCacheBuster.value + 1;
  }

  /// Wipes the cached value (call from logout flows).
  void clear() {
    _data.value = null;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('user');
      String? imageUrl;
      String? userName;
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            final url = decoded['profileImageUrl'];
            if (url is String && _isRealImage(url)) imageUrl = url;
            final name = decoded['userName'];
            if (name is String && name.trim().isNotEmpty) {
              userName = name.trim();
            }
          }
        } catch (_) {}
      }
      // JWT fallback for the initial when we don't have a cached user
      // (e.g. fresh install + signed-in state from token only).
      if (userName == null) {
        try {
          final token = sl<AuthService>().getToken();
          final first = JwtPayload.firstName(token);
          if (first != null && first.isNotEmpty) userName = first;
        } catch (_) {}
      }
      _data.value = UserAvatarData(
        imageUrl: imageUrl,
        initial: _initialOf(userName),
      );
    } catch (_) {
      _data.value = const UserAvatarData(imageUrl: null, initial: 'T');
    }
  }

  static bool _isRealImage(String url) {
    if (url.isEmpty) return false;
    if (url.contains('default.png')) return false;
    if (url.contains('e87ab0a15b2b65662020e614f7e05ef1')) return false;
    return true;
  }

  static String _initialOf(String? name) {
    if (name == null || name.isEmpty) return 'T';
    return name[0].toUpperCase();
  }
}

@immutable
class UserAvatarData {
  final String? imageUrl;
  final String initial;
  const UserAvatarData({required this.imageUrl, required this.initial});
}

/// Circular avatar that always reflects the currently logged-in user.
///
/// • If a real `profileImageUrl` is cached, renders it.
/// • Otherwise, renders a brand-tinted circle with the user's initial
///   (matches the existing top-bar design across the app).
///
/// Because the data lives in [UserAvatarController], updating the
/// profile picture instantly refreshes every visible avatar.
class UserAvatar extends StatefulWidget {
  final double size;
  final double fontSize;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.size = 40,
    this.fontSize = 16,
    this.backgroundColor,
    this.foregroundColor,
    this.border,
    this.boxShadow,
    this.onTap,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  @override
  void initState() {
    super.initState();
    UserAvatarController.instance.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.foregroundColor ?? BrandTokens.primaryBlue;
    final bg = widget.backgroundColor ??
        BrandTokens.primaryBlue.withValues(alpha: 0.10);

    final circle = ValueListenableBuilder<UserAvatarData?>(
      valueListenable: UserAvatarController.instance.listenable,
      builder: (context, data, _) {
        final imageUrl = data?.imageUrl;
        final initial = data?.initial ?? 'T';

        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: widget.border,
            boxShadow: widget.boxShadow,
          ),
          alignment: Alignment.center,
          clipBehavior: Clip.antiAlias,
          child: imageUrl != null
              ? ValueListenableBuilder<int>(
                  valueListenable: _avatarCacheBuster,
                  builder: (context, bust, _) {
                    return Image.network(
                      // Append a bust counter so a re-uploaded photo at
                      // the same URL still re-fetches the bytes.
                      bust == 0 ? imageUrl : '$imageUrl?v=$bust',
                      width: widget.size,
                      height: widget.size,
                      fit: BoxFit.cover,
                      // `key` resets the underlying ImageProvider on
                      // every bust, evicting the live frame too.
                      key: ValueKey('$imageUrl#$bust'),
                      errorBuilder: (_, __, ___) =>
                          _initialFallback(initial, fg),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return _initialFallback(initial, fg);
                      },
                    );
                  },
                )
              : _initialFallback(initial, fg),
        );
      },
    );

    final onTap = widget.onTap;
    if (onTap == null) return circle;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: circle,
    );
  }

  Widget _initialFallback(String initial, Color fg) {
    return Text(
      initial,
      style: BrandTokens.heading(
        fontSize: widget.fontSize,
        fontWeight: FontWeight.w800,
        color: fg,
      ),
    );
  }
}
