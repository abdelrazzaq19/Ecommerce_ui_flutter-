import 'package:ecommerce_ui/utils/app_textstyles.dart';
import 'package:flutter/material.dart';

class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(context, "Subtotal", "\$699.99"),
          SizedBox(height: 8),
          _buildSummaryRow(context, "Shipping", "\$10.00"),
          SizedBox(height: 8),
          _buildSummaryRow(context, "Tax", "\$53.00"),
          Padding(
            padding: EdgeInsetsGeometry.symmetric(vertical: 12),
            child: Divider(),
          ),
          _buildSummaryRow(context, "Total", "\$762.10", isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isTotal = false,
  }) {
    final textStyle = isTotal ? AppTextstyles.h3 : AppTextstyles.bodyLarge;
    final color = isTotal
        ? Theme.of(context).primaryColor
        : Theme.of(context).textTheme.bodyLarge!.color!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextstyles.withColor(textStyle, color)),
        Text(value, style: AppTextstyles.withColor(textStyle, color)),
      ],
    );
  }
}
