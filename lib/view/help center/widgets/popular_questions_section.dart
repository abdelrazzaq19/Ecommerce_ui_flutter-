import 'package:ecommerce_ui/utils/app_textstyles.dart';
import 'package:ecommerce_ui/view/help%20center/widgets/question_card.dart';
import 'package:flutter/material.dart';

class PopularQuestionsSection extends StatelessWidget {
  const PopularQuestionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Popular Questions",
            style: AppTextstyles.withColor(
              AppTextstyles.h3,
              Theme.of(context).textTheme.bodyLarge!.color!,
            ),
          ),
          const SizedBox(height: 16),
          QuestionCard(
            title: "How to track my order?",
            icon: Icons.local_shipping_outlined,
          ),
          const SizedBox(height: 12),
          QuestionCard(
            title: "How to return an item?",
            icon: Icons.local_shipping_outlined,
          ),
        ],
      ),
    );
  }
}
