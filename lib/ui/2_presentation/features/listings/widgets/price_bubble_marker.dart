// lib/ui/2_presentation/features/listings/widgets/price_bubble_marker.dart

import 'package:flutter/material.dart';

// Import domain
import '../../../../../models/1_domain/shared/value_objects/price.dart';
import '../../../../../models/1_domain/domain_orchestrator.dart';

// Import utils
import '../../../../../utils/price_formatter.dart';

/// Price Bubble Marker Widget
///
/// Displays listing price in colored bubble with pointer tail for map markers.
/// Red for venta, purple for alquiler.
class PriceBubbleMarker extends StatelessWidget {
  final Price price;
  final OperationType operationType;

  const PriceBubbleMarker({
    super.key,
    required this.price,
    required this.operationType,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = _getBubbleColor();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 60, maxWidth: 100),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            PriceFormatter.formatForMapBubble(price),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Positioned(
          bottom: -6,
          left: 0,
          right: 0,
          child: Center(
            child: CustomPaint(
              size: const Size(12, 7),
              painter: TrianglePainter(bubbleColor),
            ),
          ),
        ),
      ],
    );
  }

  Color _getBubbleColor() {
    switch (operationType) {
      case OperationType.venta:
        return const Color(0xFFD32F2F); // Red
      case OperationType.alquiler:
        return const Color(0xFF7B1FA2); // Purple
    }
  }
}

/// Custom painter for downward-pointing triangle tail
class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height) // Bottom point
      ..lineTo(0, 0) // Top left
      ..lineTo(size.width, 0) // Top right
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(TrianglePainter oldDelegate) => oldDelegate.color != color;
}
