import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Product artwork with a placeholder while loading and a fallback on failure.
///
/// Images are disk-cached, so a second launch shows artwork immediately and an
/// offline browse still looks like a store rather than a page of grey boxes.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    this.fit = BoxFit.contain,
    this.semanticLabel,
  });

  final String url;
  final BoxFit fit;
  final String? semanticLabel;

  /// Test seam. Widget tests set this so no test needs an HTTP client or the
  /// image-cache plugin; production never assigns it.
  @visibleForTesting
  static Widget Function(BuildContext context, String url)? debugImageBuilder;

  @override
  Widget build(BuildContext context) {
    final builder = debugImageBuilder;
    if (builder != null) {
      return builder(context, url);
    }

    if (url.isEmpty) {
      return _Fallback(semanticLabel: semanticLabel);
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      fadeInDuration: AppDurations.fast,
      placeholder: (context, _) => const _Placeholder(),
      errorWidget: (context, _, __) => _Fallback(semanticLabel: semanticLabel),
      imageBuilder: (context, imageProvider) => Semantics(
        label: semanticLabel,
        image: true,
        child: Image(image: imageProvider, fit: fit),
      ),
    );
  }
}

/// Neutral greys, not theme colors: product art always sits on a white plate,
/// so a dark-theme placeholder would punch a black hole through it.
const Color _plateFill = Color(0xFFEDEDF0);
// Dark enough to clear the 3:1 WCAG asks of a non-text element against the
// placeholder plate; the lighter grey this started as was 2.4:1.
const Color _plateInk = Color(0xFF6E6E7A);

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: _plateFill,
      child: SizedBox.expand(),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({this.semanticLabel});

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel == null ? null : '$semanticLabel (image unavailable)',
      child: const ColoredBox(
        color: _plateFill,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: _plateInk,
          ),
        ),
      ),
    );
  }
}
