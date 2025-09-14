import 'package:ecommerce_ui/utils/app_textstyles.dart';
import 'package:ecommerce_ui/view/checkout/widgets/address_card.dart';
import 'package:ecommerce_ui/view/checkout/widgets/checkout_bottom_bar.dart';
import 'package:ecommerce_ui/view/checkout/widgets/order_summary_card.dart';
import 'package:ecommerce_ui/view/checkout/widgets/payment_method_card.dart';
import 'package:ecommerce_ui/view/order%20confirmation/screens/order_confirmation_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/utils.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        title: Text(
          "Checkout",
          style: AppTextstyles.withColor(
            AppTextstyles.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, "Shipping address"),
            SizedBox(height: 16),
            AddressCard(),
            SizedBox(height: 24),
            _buildSectionTitle(context, "Payment Method"),
            SizedBox(height: 16),
            PaymentMethodCard(),
            SizedBox(height: 24),
            _buildSectionTitle(context, "Order Summary"),
            SizedBox(height: 16),
            OrderSummaryCard(),
          ],
        ),
      ),
      bottomNavigationBar: CheckoutBottomBar(
        totalAmount: 762.10,
        onPlaceOrder: () {
          // generate a random order number (in real app, this would come from backend)
          final orderNumber =
              "ORD${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

          Get.to(() => OrderConfirmationScreen(
            orderNumber: orderNumber,
            totalAmount: 762.10,
          ));
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: AppTextstyles.withColor(
        AppTextstyles.h3,
        Theme.of(context).textTheme.bodyLarge!.color!,
      ),
    );
  }
}
