import 'package:ecommerce_ui/utils/app_textstyles.dart';
import 'package:flutter/material.dart';

class ShippingAddressScreen extends StatelessWidget {
  const ShippingAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Shipping Address",
          style: AppTextstyles.withColor(
          AppTextstyles.h3, 
          Colors.black
          ),
        ),
      ),
    );
  }
}
