import 'dart:ui';
import 'package:airsentine1/core/design_tokens.dart';
import 'package:airsentine1/models/station.dart';
import 'package:airsentine1/providers/app_state.dart';
import 'package:airsentine1/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global helper to show the AI Copilot modal popover directly over any pre-existing window
Future<void> showAiAssistantModal(BuildContext context) async {
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'AirSentinel AI Health Copilot',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (ctx, anim1, anim2) {
      return const AiAssistantPage();
    },
    transitionBuilder: (ctx, anim1, anim2, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(
            CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  );
}

class ChatMessage {
  final String sender; // 'user' or 'assistant'
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
  });
}

enum WindowSizeMode { compact, expanded, fullscreen }

class AiAssistantPage extends ConsumerStatefulWidget {
  const AiAssistantPage({super.key});

  @override
  ConsumerState<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends ConsumerState<AiAssistantPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isMinimized = false;
  WindowSizeMode _sizeMode = WindowSizeMode.compact;
  Offset _windowOffset = const Offset(0, 0);

  final List<ChatMessage> _messages = [
    ChatMessage(
      sender: 'assistant',
      text:
          'Namaste! I am your AirSentinel AI Health Copilot. I analyze live CPCB air quality telemetry, PM2.5 sub-indices, and weather data across Indian stations to provide personalized health guidance.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inputFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
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

  Future<void> _handleSendMessage(String text, MonitoringStation station) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userText = text.trim();
    _inputController.clear();

    setState(() {
      _messages.add(ChatMessage(
        sender: 'user',
        text: userText,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 1200));

    String aiResponse = 'Based on CPCB data for ${station.name} (${station.area}), current AQI is ${station.aqi} (${station.aqiMeta.label}). ';
    final lower = userText.toLowerCase();

    if (lower.contains('run') || lower.contains('outdoor') || lower.contains('exercise')) {
      if (station.aqi > 200) {
        aiResponse += 'Outdoor exercise is NOT recommended today due to high ${station.primaryPollutant} levels. Exercise indoors with an N95 mask or air purifier.';
      } else {
        aiResponse += 'Outdoor exercise is acceptable during early morning hours. Keep workouts light if you have respiratory sensitivities.';
      }
    } else if (lower.contains('mask') || lower.contains('n95')) {
      aiResponse += 'CPCB guidelines recommend wearing a fitted N95/FFP2 respirator when stepping outside whenever AQI exceeds 200 (Poor/Very Poor/Severe).';
    } else if (lower.contains('pm2.5') || lower.contains('pollutant')) {
      aiResponse += 'PM2.5 particles are fine respirable matter < 2.5 micrometers. Current PM2.5 at ${station.name} is trappable with HEPA indoor air purifiers.';
    } else if (lower.contains('asthma') || lower.contains('respiratory')) {
      aiResponse += 'Keep inhalers accessible. Limit outdoor exposure during peak traffic hours (8-11 AM & 6-9 PM) when ground-level pollutants spike.';
    } else {
      aiResponse += station.aqiMeta.healthAdvisory;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(
          sender: 'assistant',
          text: aiResponse,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final station = ref.watch(selectedStationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF10B981) : const Color(0xFF0F9D58);
    final screenSize = MediaQuery.of(context).size;

    return PopScope(
      canPop: true,
      child: Semantics(
        container: true,
        scopesRoute: true,
        explicitChildNodes: true,
        label: 'AirSentinel AI Health Copilot Window Popup',
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              // Backdrop Blur & Dim Overlay
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ),

              // Floating Window Container
              Positioned(
                left: _isMinimized
                    ? (screenSize.width - 320).clamp(16.0, screenSize.width - 336.0)
                    : _sizeMode == WindowSizeMode.fullscreen
                        ? 0
                        : (screenSize.width / 2 - _getWindowWidth(screenSize) / 2 + _windowOffset.dx)
                            .clamp(10.0, (screenSize.width - _getWindowWidth(screenSize) - 10.0).clamp(10.0, screenSize.width)),
                top: _isMinimized
                    ? (screenSize.height - 70).clamp(16.0, screenSize.height - 86.0)
                    : _sizeMode == WindowSizeMode.fullscreen
                        ? 0
                        : (screenSize.height / 2 - _getWindowHeight(screenSize) / 2 + _windowOffset.dy)
                            .clamp(10.0, (screenSize.height - _getWindowHeight(screenSize) - 10.0).clamp(10.0, screenSize.height)),
                child: _isMinimized
                    ? _buildMinimizedPill(station, isDark, primaryColor)
                    : _buildWindowContent(station, isDark, primaryColor, screenSize),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getWindowWidth(Size screenSize) {
    switch (_sizeMode) {
      case WindowSizeMode.compact:
        return (screenSize.width * 0.90).clamp(340.0, 680.0);
      case WindowSizeMode.expanded:
        return (screenSize.width * 0.94).clamp(400.0, 840.0);
      case WindowSizeMode.fullscreen:
        return screenSize.width;
    }
  }

  double _getWindowHeight(Size screenSize) {
    switch (_sizeMode) {
      case WindowSizeMode.compact:
        return (screenSize.height * 0.82).clamp(480.0, 700.0);
      case WindowSizeMode.expanded:
        return (screenSize.height * 0.90).clamp(520.0, 820.0);
      case WindowSizeMode.fullscreen:
        return screenSize.height;
    }
  }

  /// Collapsed Minimized Pill Button
  Widget _buildMinimizedPill(MonitoringStation station, bool isDark, Color primaryColor) {
    return Semantics(
      button: true,
      label: 'Expand AI Copilot Window Popup',
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isMinimized = false;
          });
        },
        child: Container(
          width: 300,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: AppGradients.darkAccent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 6)),
            ],
            border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.6), width: 1.5),
          ),
          child: Row(
            children: [
              const PulsingDot(color: Color(0xFF34D399), size: 8),
              const SizedBox(width: 8),
              const Icon(Icons.auto_awesome, color: Color(0xFF34D399), size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'AIRSENTINEL AI COPILOT',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.8),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.open_in_full, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Main Window Content
  Widget _buildWindowContent(MonitoringStation station, bool isDark, Color primaryColor, Size screenSize) {
    final scaffoldBg = isDark ? const Color(0xFF141210) : const Color(0xFFFAF7F2);
    final isFullscreen = _sizeMode == WindowSizeMode.fullscreen;
    final winWidth = isFullscreen ? screenSize.width : _getWindowWidth(screenSize);
    final winHeight = isFullscreen ? screenSize.height : _getWindowHeight(screenSize);

    return Container(
      width: winWidth,
      height: winHeight,
      decoration: BoxDecoration(
        color: scaffoldBg,
        borderRadius: isFullscreen ? BorderRadius.zero : BorderRadius.circular(24),
        boxShadow: isFullscreen
            ? null
            : [
                BoxShadow(color: Colors.black.withValues(alpha: 0.40), blurRadius: 28, spreadRadius: 2, offset: const Offset(0, 12)),
              ],
        border: isFullscreen ? null : Border.all(color: primaryColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: isFullscreen ? BorderRadius.zero : BorderRadius.circular(24),
        child: Scaffold(
          backgroundColor: scaffoldBg,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(66.0),
            child: GestureDetector(
              onPanUpdate: isFullscreen
                  ? null
                  : (details) {
                      setState(() {
                        _windowOffset += details.delta;
                      });
                    },
              child: Container(
                decoration: const BoxDecoration(gradient: AppGradients.darkAccent),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.drag_indicator, color: Colors.white38, size: 18),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, color: Color(0xFF34D399), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'AIRSENTINEL AI COPILOT',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              PulsingDot(color: station.aqiMeta.dotColor, size: 6),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${station.name.toUpperCase()} • AQI ${station.aqi} (${station.aqiMeta.label.toUpperCase()})',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.4),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Size controls & Close button
                    IconButton(
                      icon: Icon(Icons.crop_3_2, color: _sizeMode == WindowSizeMode.compact ? const Color(0xFF34D399) : Colors.white70, size: 18),
                      tooltip: 'Compact Window Size',
                      onPressed: () {
                        setState(() {
                          _sizeMode = WindowSizeMode.compact;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.open_in_full, color: _sizeMode == WindowSizeMode.expanded ? const Color(0xFF34D399) : Colors.white70, size: 18),
                      tooltip: 'Expanded Window Size',
                      onPressed: () {
                        setState(() {
                          _sizeMode = WindowSizeMode.expanded;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove, color: Colors.white70, size: 18),
                      tooltip: 'Minimize Window',
                      onPressed: () {
                        setState(() {
                          _isMinimized = true;
                        });
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                      tooltip: 'Close Copilot',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              // Messages area
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isUser = msg.sender == 'user';
                    return _buildChatBubble(msg, isUser, isDark, primaryColor);
                  },
                ),
              ),

              // Loading indicator
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SpinningLoader(color: primaryColor, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'ANALYZING CPCB TELEMETRY...',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: primaryColor),
                      ),
                    ],
                  ),
                ),

              // Quick Prompts
              _buildQuickPrompts(station, isDark, primaryColor),

              // Bottom Input Control Row
              _buildInputRow(station, isDark, primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg, bool isUser, bool isDark, Color primaryColor) {
    final bubbleBg = isUser
        ? primaryColor
        : (isDark ? const Color(0xFF1E1B18) : Colors.white);
    final textColor = isUser
        ? Colors.white
        : (isDark ? const Color(0xFFF5F2EB) : const Color(0xFF0F172A));

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor.withValues(alpha: 0.4), width: 1),
              ),
              child: Icon(Icons.auto_awesome, color: primaryColor, size: 16),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 580),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: isUser
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                border: isUser ? null : Border.all(color: isDark ? const Color(0xFF2E2924) : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13.5,
                      height: 1.45,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')} IST',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isUser ? Colors.white.withValues(alpha: 0.75) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickPrompts(MonitoringStation station, bool isDark, Color primaryColor) {
    final prompts = [
      {'text': 'Is it safe for outdoor running today?', 'icon': Icons.directions_run_rounded},
      {'text': 'Do I need an N95 mask outside?', 'icon': Icons.masks_rounded},
      {'text': 'Health tips for asthma & respiratory care', 'icon': Icons.health_and_safety_rounded},
      {'text': 'Recommended HEPA air purifier settings', 'icon': Icons.air_rounded},
      {'text': 'Explain PM2.5 & primary pollutants', 'icon': Icons.science_rounded},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191715) : const Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF2E2924) : const Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, size: 13, color: primaryColor),
                const SizedBox(width: 6),
                Text(
                  'SUGGESTED COPILOT PROMPTS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: isDark ? const Color(0xFFA8A29E) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: prompts.length,
              itemBuilder: (context, index) {
                final p = prompts[index];
                final text = p['text'] as String;
                final icon = p['icon'] as IconData;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Semantics(
                    button: true,
                    label: 'Quick prompt: $text',
                    child: InkWell(
                      onTap: () => _handleSendMessage(text, station),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF24211D) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(icon, size: 14, color: primaryColor),
                            const SizedBox(width: 6),
                            Text(
                              text,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFFE7E5E4) : const Color(0xFF1E293B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(MonitoringStation station, bool isDark, Color primaryColor) {
    final rowBg = isDark ? const Color(0xFF1E1B18) : Colors.white;
    final borderTopColor = isDark ? const Color(0xFF2E2924) : const Color(0xFFE2E8F0);
    final fieldBg = isDark ? const Color(0xFF28231E) : const Color(0xFFF1F5F9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: rowBg,
        border: Border(top: BorderSide(color: borderTopColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                label: 'Type your health question for AI Copilot',
                child: TextField(
                  controller: _inputController,
                  focusNode: _inputFocusNode,
                  autofocus: true,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (val) => _handleSendMessage(val, station),
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask AirSentinel Copilot about AQI, PM2.5, health tips...',
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? const Color(0xFF78716C) : const Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: fieldBg,
                    prefixIcon: Icon(Icons.mic_none_rounded, color: primaryColor, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF38322B) : const Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: 'Send message to AI Copilot',
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withValues(alpha: 0.85)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  onPressed: () => _handleSendMessage(_inputController.text, station),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
