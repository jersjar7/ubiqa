// lib/ui/2_presentation/features/listings/widgets/operation_type_toggle.dart

import 'package:flutter/material.dart';

// Import domain
import '../../../../../models/1_domain/domain_orchestrator.dart';

/// Operation Type Toggle Widget
///
/// Floating toggle button for switching between venta/alquiler.
/// Positioned top-right of map view.
class OperationTypeToggle extends StatelessWidget {
  final OperationType currentType;
  final Function(OperationType) onToggle;

  const OperationTypeToggle({
    super.key,
    required this.currentType,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            label: 'Venta',
            type: OperationType.venta,
            isActive: currentType == OperationType.venta,
          ),
          Container(width: 1, height: 30, color: Colors.grey.shade300),
          _buildToggleButton(
            label: 'Alquiler',
            type: OperationType.alquiler,
            isActive: currentType == OperationType.alquiler,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required OperationType type,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => onToggle(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _getActiveColor(type) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade700,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Color _getActiveColor(OperationType type) {
    switch (type) {
      case OperationType.venta:
        return const Color(0xFFD32F2F); // Red
      case OperationType.alquiler:
        return const Color(0xFF7B1FA2); // Purple
    }
  }
}
