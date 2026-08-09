import 'package:airsentine1/core/design_tokens.dart';
import 'package:airsentine1/models/station.dart';
import 'package:airsentine1/providers/app_state.dart';
import 'package:airsentine1/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    await Future.delayed(const Duration(milliseconds: 1400));

    String aiResponse = 'Based on CPCB data for ${station.name} (${station.area}), the current AQI is ${station.aqi} (${station.aqiMeta.label}). ';
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
              // Semi-transparent backdrop overlay (dismissible on tap outside if desired)
              if (_sizeMode == WindowSizeMode.fullscreen)
                GestureDetector(
                  onTap: () {},
                  child: Container(color: Colors.black45),
                ),

              // Floating Window Container
              Positioned(
                left: _isMinimized
                    ? (screenSize.width - 300).clamp(16.0, screenSize.width - 316.0)
                    : _sizeMode == WindowSizeMode.fullscreen
                        ? 0
                        : (screenSize.width / 2 - _getWindowWidth() / 2 + _windowOffset.dx)
                            .clamp(10.0, screenSize.width - _getWindowWidth() - 10.0),
                top: _isMinimized
                    ? (screenSize.height - 70).clamp(16.0, screenSize.height - 86.0)
                    : _sizeMode == WindowSizeMode.fullscreen
                        ? 0
                        : (screenSize.height / 2 - _getWindowHeight() / 2 + _windowOffset.dy)
                            .clamp(10.0, screenSize.height - _getWindowHeight() - 10.0),
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

  double _getWindowWidth() {
    switch (_sizeMode) {
      case WindowSizeMode.compact:
        return 440.0;
      case WindowSizeMode.expanded:
        return 720.0;
      case WindowSizeMode.fullscreen:
        return double.infinity;
    }
  }

  double _getWindowHeight() {
    switch (_sizeMode) {
      case WindowSizeMode.compact:
        return 560.0;
      case WindowSizeMode.expanded:
        return 720.0;
      case WindowSizeMode.fullscreen:
        return double.infinity;
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
          width: 290,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: AppGradients.darkAccent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, 6)),
            ],
            border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.6), width: 1.5),
          ),
          child: Row(
            children: [
              const PulsingDot(color: Colors.amberAccent, size: 8),
              const SizedBox(width: 8),
              const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 16),
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

  /// Main Window Content with Draggable Header Bar, Controls, Chat List, Quick Prompts & Input Row
  Widget _buildWindowContent(MonitoringStation station, bool isDark, Color primaryColor, Size screenSize) {
    final scaffoldBg = isDark ? const Color(0xFF141210) : const Color(0xFFFAF7F2);
    final isFullscreen = _sizeMode == WindowSizeMode.fullscreen;
    final winWidth = isFullscreen ? screenSize.width : _getWindowWidth().clamp(300.0, screenSize.width - 20.0);
    final winHeight = isFullscreen ? screenSize.height : _getWindowHeight().clamp(400.0, screenSize.height - 20.0);

    return Container(
      width: winWidth,
      height: winHeight,
      decoration: BoxDecoration(
        color: scaffoldBg,
        borderRadius: isFullscreen ? BorderRadius.zero : BorderRadius.circular(20),
        boxShadow: isFullscreen
            ? null
            : const [
                BoxShadow(color: Colors.black45, blurRadius: 24, spreadRadius: 4, offset: Offset(0, 10)),
              ],
        border: isFullscreen ? null : Border.all(color: isDark ? const Color(0xFF38322B) : const Color(0xFFCBD5E1), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: isFullscreen ? BorderRadius.zero : BorderRadius.circular(20),
        child: Scaffold(
          backgroundColor: scaffoldBg,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60.0),
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
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.drag_indicator, color: Colors.white54, size: 18),
                    const SizedBox(width: 6),
                    const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'AIRSENTINEL AI COPILOT',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8),
                          ),
                          Text(
                            'CONTEXT: ${station.name.toUpperCase()} • AQI ${station.aqi}',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Window Action Buttons: Size Switchers, Minimize, Close
                    Semantics(
                      button: true,
                      label: 'Switch to Compact Window Size',
                      child: IconButton(
                        icon: Icon(Icons.crop_3_2, color: _sizeMode == WindowSizeMode.compact ? Colors.amberAccent : Colors.white70, size: 16),
                        tooltip: 'Compact Size (440x560)',
                        onPressed: () {
                          setState(() {
                            _sizeMode = WindowSizeMode.compact;
                          });
                        },
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Switch to Expanded Window Size',
                      child: IconButton(
                        icon: Icon(Icons.open_in_full, color: _sizeMode == WindowSizeMode.expanded ? Colors.amberAccent : Colors.white70, size: 16),
                        tooltip: 'Expanded Size (720x720)',
                        onPressed: () {
                          setState(() {
                            _sizeMode = WindowSizeMode.expanded;
                          });
                        },
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Minimize AI Copilot Window',
                      child: IconButton(
                        icon: const Icon(Icons.remove, color: Colors.white70, size: 18),
                        tooltip: 'Minimize Window',
                        onPressed: () {
                          setState(() {
                            _isMinimized = true;
                          });
                        },
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Close AI Copilot Window',
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 18),
                        tooltip: 'Close Window',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              // Chat Messages Stream
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(14),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isUser = msg.sender == 'user';
                    return _buildChatBubble(msg, isUser, isDark, primaryColor);
                  },
                ),
              ),

              // Loading Indicator
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SpinningLoader(color: primaryColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'ANALYZING CPCB TELEMETRY...',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.6, color: primaryColor),
                      ),
                    ],
                  ),
                ),

              // Quick Prompts
              _buildQuickPrompts(station, isDark),

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

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: const BoxConstraints(maxWidth: 540),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: AppShadows.card,
          border: isUser ? null : Border.all(color: isDark ? const Color(0xFF2E2924) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')} IST',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isUser ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPrompts(MonitoringStation station, bool isDark) {
    final prompts = [
      'Is it safe to run outdoors in ${station.area}?',
      'CPCB health tips for ${station.aqiMeta.label} AQI',
      'Should I wear an N95 mask today?',
      'What is PM2.5 sub-index?',
    ];

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: prompts.length,
        itemBuilder: (context, index) {
          final p = prompts[index];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Semantics(
              button: true,
              label: 'Quick prompt: $p',
              child: ActionChip(
                backgroundColor: isDark ? const Color(0xFF1E3A2B) : const Color(0xFFE8F5E9),
                side: BorderSide(color: isDark ? const Color(0xFF10B981) : const Color(0xFFA5D6A7)),
                avatar: Icon(Icons.lightbulb_outline, size: 14, color: isDark ? const Color(0xFF10B981) : const Color(0xFF1B5E20)),
                label: Text(p, style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF10B981) : const Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
                onPressed: () => _handleSendMessage(p, station),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputRow(MonitoringStation station, bool isDark, Color primaryColor) {
    final rowBg = isDark ? const Color(0xFF1E1B18) : Colors.white;
    final borderTopColor = isDark ? const Color(0xFF2E2924) : const Color(0xFFE2E8F0);
    final fieldBg = isDark ? const Color(0xFF28231E) : const Color(0xFFF1F5F9);

    return Container(
      padding: const EdgeInsets.all(10),
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
                  decoration: InputDecoration(
                    hintText: 'Ask AirSentinel Copilot about AQI health guidance...',
                    labelText: 'ASK AI COPILOT',
                    filled: true,
                    fillColor: fieldBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Semantics(
              button: true,
              label: 'Send message to AI Copilot',
              child: FloatingActionButton.small(
                elevation: 0,
                backgroundColor: primaryColor,
                onPressed: () => _handleSendMessage(_inputController.text, station),
                child: const Icon(Icons.send, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
