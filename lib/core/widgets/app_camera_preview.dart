import "package:camera/camera.dart";
import "package:flutter/material.dart";

/// Undistorted [CameraPreview] for portrait phones.
///
/// [CameraController.aspectRatio] is `previewSize.width / previewSize.height`
/// (usually landscape). Using it directly in [AspectRatio] in portrait can
/// squeeze the preview; in portrait we use `1 / base` so layout matches
/// typical recorded video framing.
class AppCameraPreview extends StatelessWidget {
  final CameraController controller;

  const AppCameraPreview({super.key, required this.controller});

  /// width / height for [AspectRatio] in the current orientation.
  static double layoutAspectRatio(
    BuildContext context,
    CameraController controller,
  ) {
    if (!controller.value.isInitialized) return 1;
    final base = controller.value.aspectRatio;
    if (base <= 0 || !base.isFinite) return 1;

    final portrait = MediaQuery.orientationOf(context) == Orientation.portrait;
    return portrait ? 1 / base : base;
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const SizedBox.expand();
    }

    final ratio = layoutAspectRatio(context, controller);

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: ratio,
              child: CameraPreview(controller),
            ),
          ),
        ],
      ),
    );
  }
}
