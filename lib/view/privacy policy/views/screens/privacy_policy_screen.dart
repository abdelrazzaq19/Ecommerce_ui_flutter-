import 'package:ecommerce_ui/utils/app_textstyles.dart';
import 'package:ecommerce_ui/view/privacy%20policy/views/widgets/info_section.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        title: Text(
          "Privacy Policy",
          style: AppTextstyles.withColor(
            AppTextstyles.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(screenSize.width * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoSection(
                title: "Information we collect",
                content:
                    "We collect information that you provide directly to us, including name, email address, and shipping information.",
              ),
              InfoSection(
                title: "How we use your information",
                content:
                    "We use the information we collect to provide, maintain, and improve our services, process your transaction, and send you updates",
              ),
              InfoSection(
                title: "Information sharing",
                content:
                    "We collect information that you provide directly to us, including name, email address, and shipping information.",
              ),
              InfoSection(
                title: "Data security",
                content:
                    "We collect information that you provide directly to us, including name, email address, and shipping information.",
              ),
              InfoSection(
                title: "Your rights",
                content:
                    "We collect information that you provide directly to us, including name, email address, and shipping information.",
              ),
              InfoSection(
                title: "Cookie policy",
                content:
                    "We collect information that you provide directly to us, including name, email address, and shipping information.",
              ),
              SizedBox(height: 24),
              Text(
                "Last updated: March 2024",
                style: AppTextstyles.withColor(
                  AppTextstyles.bodySmall,
                  isDark ? Colors.grey[400]! : Colors.grey[600]!,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
