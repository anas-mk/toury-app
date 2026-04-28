import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Tile provider that backs OSM raster tiles with the same disk cache that
/// `cached_network_image` uses for avatars/photos. This eliminates the
/// repeated network round-trip every time the user opens a map screen.
///
/// We rely on `flutter_cache_manager`'s default "libCachedImageData"
/// store; that store is shared with `cached_network_image`, so OSM tiles
/// and helper avatars share a single LRU + disk budget.
///
/// IMPORTANT BUG FIX (Pass #5)
/// --------------------------
/// The previous implementation defaulted `headers` to `const {}` and
/// passed that map straight through to `super.headers`. `flutter_map`
/// then tried to insert its own User-Agent into that map at runtime and
/// crashed the entire screen with:
///
///   Unsupported operation: Cannot modify unmodifiable map
///
/// The fix: never use a `const` map for headers. We accept a copyable
/// `Map<String, String>` and forward a fresh growable copy to the parent
/// so flutter_map can mutate it safely.
class CachedTileProvider extends TileProvider {
  CachedTileProvider({Map<String, String>? headers})
      : super(headers: <String, String>{...?headers});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return CachedNetworkImageProvider(
      getTileUrl(coordinates, options),
      headers: headers,
    );
  }
}
