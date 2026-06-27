import 'dart:ui';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../providers/theme_provider.dart';
// ─────────────────────────────────────────────────────────────────────────────
// Entry-point helper
// ─────────────────────────────────────────────────────────────────────────────

void showModernSettingsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (_) => const _ModernSettingsSheet(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom-sheet body
// ─────────────────────────────────────────────────────────────────────────────

class _ModernSettingsSheet extends StatelessWidget {
  const _ModernSettingsSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final isAr = context.locale.languageCode == 'ar';

    final Color bgColor = isDark
        ? const Color(0xFF140C36).withOpacity(0.92)
        : Colors.white.withOpacity(0.92);
    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.08);
    final Color labelColor = isDark ? Colors.white70 : Colors.black54;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border(
                top: BorderSide(color: borderColor, width: 1.2),
                left: BorderSide(color: borderColor, width: 0.6),
                right: BorderSide(color: borderColor, width: 0.6),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── drag handle ──
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.22)
                        : Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // ── section label ──
                Align(
                  alignment: isAr
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Text(
                    'language'.tr(),
                    style: GoogleFonts.cairo(
                      color: labelColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── language toggle ──
                ModernLanguageToggle(
                  currentLocale: context.locale,
                  onLocaleChanged: (locale) async {
                    await context.setLocale(locale);
                  },
                  isDark: isDark,
                ),

                const SizedBox(height: 24),

                // ── theme label ──
                Align(
                  alignment: isAr
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Text(
                    'app_theme'.tr(),
                    style: GoogleFonts.cairo(
                      color: labelColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── theme toggle ──
                ModernThemeToggle(isDark: isDark),

                const SizedBox(height: 28),

                // ── divider ──
                Divider(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.06),
                  height: 1,
                ),
                const SizedBox(height: 28),

                // ── logout button ──
                _LogoutButton(isDark: isDark),

                // bottom safe-area padding
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ModernLanguageToggle (public — can be reused elsewhere)
// ─────────────────────────────────────────────────────────────────────────────

class ModernLanguageToggle extends StatefulWidget {
  final Locale currentLocale;
  final ValueChanged<Locale> onLocaleChanged;
  final bool isDark;

  const ModernLanguageToggle({
    super.key,
    required this.currentLocale,
    required this.onLocaleChanged,
    required this.isDark,
  });

  @override
  State<ModernLanguageToggle> createState() => _ModernLanguageToggleState();
}

class _ModernLanguageToggleState extends State<ModernLanguageToggle>
    with SingleTickerProviderStateMixin {
  // true  → Arabic (index 0, visually on the right for RTL)
  // false → English (index 1)
  late bool _isArabic;

  // Glow / accent colour
  static const Color _accent = Color(0xFF0F55E8);

  @override
  void initState() {
    super.initState();
    _isArabic = widget.currentLocale.languageCode == 'ar';
  }

  void _toggle(bool toArabic) {
    if (_isArabic == toArabic) return;
    setState(() => _isArabic = toArabic);
    widget.onLocaleChanged(Locale(toArabic ? 'ar' : 'en'));
  }

  @override
  Widget build(BuildContext context) {
    final trackBg = widget.isDark
        ? const Color(0xFF1E1A34).withOpacity(0.80)
        : Colors.black.withOpacity(0.06);
    final trackBorder = widget.isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.black.withOpacity(0.08);

    // Pill dimensions
    const double height = 52;
    const double radius = 26;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: trackBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: trackBorder, width: 1),
      ),
      child: Stack(
        children: [
          // ── animated sliding pill ──
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            alignment: _isArabic
                ? AlignmentDirectional.centerStart
                : AlignmentDirectional.centerEnd,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1.0,
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F55E8), Color(0xFF5D12D2)],
                  ),
                  borderRadius: BorderRadius.circular(radius - 3),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withOpacity(0.45),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── labels row ──
          Row(
            children: [
              // Arabic
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _toggle(true),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 260),
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: _isArabic
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: _isArabic
                            ? Colors.white
                            : (widget.isDark
                                ? Colors.white38
                                : Colors.black38),
                        shadows: _isArabic
                            ? [
                                Shadow(
                                  color: Colors.white.withOpacity(0.6),
                                  blurRadius: 8,
                                ),
                              ]
                            : [],
                      ),
                      child: const Text('العربية'),
                    ),
                  ),
                ),
              ),

              // English
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _toggle(false),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 260),
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: !_isArabic
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: !_isArabic
                            ? Colors.white
                            : (widget.isDark
                                ? Colors.white38
                                : Colors.black38),
                        shadows: !_isArabic
                            ? [
                                Shadow(
                                  color: Colors.white.withOpacity(0.6),
                                  blurRadius: 8,
                                ),
                              ]
                            : [],
                      ),
                      child: const Text('English'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logout button
// ─────────────────────────────────────────────────────────────────────────────

class _LogoutButton extends StatefulWidget {
  final bool isDark;
  const _LogoutButton({required this.isDark});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final redGlass = widget.isDark
        ? const Color(0xFFFF3B30).withOpacity(0.12)
        : const Color(0xFFD32F2F).withOpacity(0.08);
    final redBorder = widget.isDark
        ? const Color(0xFFFF3B30).withOpacity(0.35)
        : const Color(0xFFD32F2F).withOpacity(0.25);
    final redText = widget.isDark
        ? const Color(0xFFFF5A5A)
        : const Color(0xFFD32F2F);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        Navigator.pop(context);
        context.read<AuthBloc>().add(LogoutRequested());
        context.go('/login');
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            color: redGlass,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: redBorder, width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: redText, size: 22),
              const SizedBox(width: 10),
              Text(
                'logout'.tr(),
                style: GoogleFonts.cairo(
                  color: redText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ModernThemeToggle (public — can be reused elsewhere)
// ─────────────────────────────────────────────────────────────────────────────

class ModernThemeToggle extends StatelessWidget {
  final bool isDark;

  const ModernThemeToggle({
    super.key,
    required this.isDark,
  });

  void _toggle(BuildContext context, bool toDark) {
    if (isDark == toDark) return;
    context.read<ThemeProvider>().toggleTheme(toDark);
  }

  @override
  Widget build(BuildContext context) {
    final trackBg = isDark
        ? const Color(0xFF1E1A34).withOpacity(0.80)
        : Colors.black.withOpacity(0.06);
    final trackBorder = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.black.withOpacity(0.08);

    // Pill dimensions
    const double height = 52;
    const double radius = 26;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: trackBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: trackBorder, width: 1),
      ),
      child: Stack(
        children: [
          // ── animated sliding pill ──
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            // If isDark is false (Light mode, which is the 1st option), align start.
            alignment: !isDark
                ? AlignmentDirectional.centerStart
                : AlignmentDirectional.centerEnd,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1.0,
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0F55E8), const Color(0xFF5D12D2)] // neon blue/purple
                        : [const Color(0xFFFFB75E), const Color(0xFFED8F03)], // warm gold/orange
                  ),
                  borderRadius: BorderRadius.circular(radius - 3),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? const Color(0xFF0F55E8) : const Color(0xFFED8F03)).withOpacity(0.45),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── labels row ──
          Row(
            children: [
              // Light Mode
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _toggle(context, false),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wb_sunny_rounded,
                          size: 18,
                          color: !isDark ? Colors.white : (isDark ? Colors.white38 : Colors.black38),
                        ),
                        const SizedBox(width: 8),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 260),
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: !isDark ? FontWeight.bold : FontWeight.w500,
                            color: !isDark
                                ? Colors.white
                                : (isDark ? Colors.white38 : Colors.black38),
                            shadows: !isDark
                                ? [Shadow(color: Colors.white.withOpacity(0.6), blurRadius: 8)]
                                : [],
                          ),
                          child: Text('light_mode'.tr()),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Dark Mode
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _toggle(context, true),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.dark_mode_rounded,
                          size: 18,
                          color: isDark ? Colors.white : (isDark ? Colors.white38 : Colors.black38),
                        ),
                        const SizedBox(width: 8),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 260),
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: isDark ? FontWeight.bold : FontWeight.w500,
                            color: isDark
                                ? Colors.white
                                : (isDark ? Colors.white38 : Colors.black38),
                            shadows: isDark
                                ? [Shadow(color: Colors.white.withOpacity(0.6), blurRadius: 8)]
                                : [],
                          ),
                          child: Text('dark_mode'.tr()),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
