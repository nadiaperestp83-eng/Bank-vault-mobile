import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';
import 'package:vault_os/src/features/help/presentation/bloc/ai_advisor_bloc.dart';
import 'package:vault_os/src/features/help/presentation/bloc/ai_advisor_event.dart';
import 'package:vault_os/src/features/help/presentation/bloc/ai_advisor_state.dart';
import 'package:vault_os/src/models/ai_advisor_model.dart';

class AiAdvisorScreen extends StatefulWidget {
  const AiAdvisorScreen({super.key});

  @override
  State<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends State<AiAdvisorScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<AiAdvisorBloc>().add(FetchChatRequested());
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.sparkles, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vault AI Advisor',
                  style: GoogleFonts.outfit(
                    color: theme.colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Always active',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2, size: 20, color: Colors.grey),
            onPressed: () {
              HapticFeedback.selectionClick();
              context.read<AiAdvisorBloc>().add(ClearChatRequested());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<AiAdvisorBloc, AiAdvisorState>(
              listener: (context, state) {
                if (state is AiAdvisorLoaded) {
                  _scrollToBottom();
                }
              },
              builder: (context, state) {
                if (state is AiAdvisorLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is AiAdvisorError) {
                  return Center(child: Text(state.message));
                }

                if (state is AiAdvisorLoaded) {
                  final messages = state.messages;
                  if (messages.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSizes.p20),
                    itemCount: messages.length + (state.isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return _buildTypingIndicator();
                      }
                      final message = messages[index];
                      return _buildChatBubble(message);
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.sparkles, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          Text(
            'How can I help you today?',
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ask me about your balance, savings goals,\nor financial tips.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 40),
          _buildSuggestionChips(['What is my balance?', 'Show my savings', 'Give me a tip']),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSuggestionChips(List<String> suggestions) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: suggestions.map((s) => ActionChip(
        label: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        onPressed: () {
          HapticFeedback.selectionClick();
          context.read<AiAdvisorBloc>().add(SendMessageRequested(s));
        },
        backgroundColor: AppColors.primary.withValues(alpha: 0.05),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.1)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      )).toList(),
    );
  }

  Widget _buildChatBubble(AiChatMessage message) {
    final isUser = message.sender == 'user';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isUser ? AppColors.primary : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(24),
                topRight: const Radius.circular(24),
                bottomLeft: Radius.circular(isUser ? 24 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: !isUser ? Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.lightBorder) : null,
            ),
            child: _buildRichText(message.text, isUser),
          ),
          // Extract suggestions from AI text if present
          if (!isUser && message.text.contains('[') && message.text.contains(']'))
            Padding(
              padding: const EdgeInsets.only(bottom: 24, left: 4),
              child: _buildSuggestionChips(_extractSuggestions(message.text)),
            ),
        ],
      ).animate().fadeIn(duration: 300.ms).slideX(begin: isUser ? 0.05 : -0.05, end: 0),
    );
  }

  Widget _buildRichText(String text, bool isUser) {
    // Custom parser for markdown-like syntax
    final String cleanText = text.replaceAll(RegExp(r'\[.*?\]'), '').trim();
    
    return Text(
      cleanText,
      style: TextStyle(
        color: isUser ? Colors.white : Theme.of(context).colorScheme.onSurface,
        fontSize: 15,
        height: 1.5,
        fontWeight: isUser ? FontWeight.w500 : FontWeight.normal,
      ),
    );
  }

  List<String> _extractSuggestions(String text) {
    final regExp = RegExp(r'\[(.*?)\]');
    final matches = regExp.allMatches(text);
    return matches.map((m) => m.group(1)!).toList();
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
            ),
            SizedBox(width: 12),
            Text('Thinking...', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.mic, color: Colors.grey, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Type your message...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (val) => _sendMessage(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.send, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      context.read<AiAdvisorBloc>().add(SendMessageRequested(text));
      _messageController.clear();
      _scrollToBottom();
    }
  }
}
