import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vault_os/src/constants/app_sizes.dart';

class FAQSection extends StatefulWidget {
  final String searchQuery;
  const FAQSection({super.key, this.searchQuery = ''});

  @override
  State<FAQSection> createState() => _FAQSectionState();
}

class _FAQSectionState extends State<FAQSection> {
  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I reset my security PIN?',
      'answer': 'You can reset your PIN in Settings > Security Center > Change PIN. You will need to verify the change via an OTP sent to your registered email address.'
    },
    {
      'question': 'What are the transaction limits?',
      'answer': 'Standard accounts have a daily limit of \$5,000. Verified merchants can increase this up to \$50,000. Contact support for higher volume requirements.'
    },
    {
      'question': 'Is Vault OS available internationally?',
      'answer': 'Yes, Vault OS supports multi-currency accounts and international P2P transfers. However, some merchant features may be restricted by region.'
    },
    {
      'question': 'How do I enable Merchant Mode?',
      'answer': 'Go to Settings > Business Profile and toggle the "Enable Merchant Mode" switch. You will be asked to provide basic business details and a description.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredFaqs = _faqs.where((faq) {
      final query = widget.searchQuery.toLowerCase();
      return faq['question']!.toLowerCase().contains(query) ||
             faq['answer']!.toLowerCase().contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FREQUENTLY ASKED QUESTIONS',
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSizes.p16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredFaqs.length,
          separatorBuilder: (context, index) => Divider(
            color: theme.dividerTheme.color ?? (theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
            height: 1,
          ),
          itemBuilder: (context, index) {
            return _FAQItem(
              question: filteredFaqs[index]['question']!,
              answer: filteredFaqs[index]['answer']!,
            );
          },
        ),
      ],
    );
  }
}

class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FAQItem({required this.question, required this.answer});

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: 8),
            title: Text(
              widget.question,
              style: TextStyle(
                color: theme.textTheme.titleMedium?.color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            trailing: AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                LucideIcons.chevronDown,
                color: _isExpanded ? colorScheme.primary : theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
                size: 20,
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: AppSizes.p16, right: AppSizes.p16, bottom: AppSizes.p20),
              child: Text(
                widget.answer,
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                  fontSize: 14,
                  height: 1.6,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
