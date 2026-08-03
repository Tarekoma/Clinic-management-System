// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/assistant/assistant_shared_widgets.dart
//
// CHANGE: every widget that previously read a static _T.bgInput / _T.textH /
// _T.textS / _T.textM / _T.divider / _T.card() constant now reads the
// equivalent value from Theme.of(context).extension<AssistantThemeData>()!
// so dark mode actually changes these surfaces. Public constructors/props
// are UNCHANGED — every call site in every other file compiles unmodified.
//
// Brand/status colors (green, urgent, success, warning, info, etc.) are
// untouched — they're identity colors, not theme-neutral surfaces.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:Hakim/utils/arabic_digits.dart';
import 'package:Hakim/utils/assistant_theme.dart';
import 'package:Hakim/l10n/generated/app_localizations.dart';

typedef _T = AssistantTheme;

// ══════════════════════════════════════════════════════════════════════════════
// AVATAR  — circular widget showing name initials
// ══════════════════════════════════════════════════════════════════════════════

class AssistantAvatar extends StatelessWidget {
  final String name;
  final double size;
  const AssistantAvatar({required this.name, this.size = 44, Key? key})
    : super(key: key);

  String get _init {
    final p = name.trim().split(' ');
    if (p.isEmpty) return '?';
    if (p.length == 1) return p[0].isEmpty ? '?' : p[0][0].toUpperCase();
    return '${p[0][0]}${p.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: _T.avatarBg(name), shape: BoxShape.circle),
    child: Center(
      child: Text(
        _init,
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// BADGE  — coloured label pill (already context-free; fg/bg always passed in)
// ══════════════════════════════════════════════════════════════════════════════

class AssistantBadge extends StatelessWidget {
  final String label;
  final Color fg, bg;
  const AssistantBadge({
    required this.label,
    required this.fg,
    required this.bg,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: fg,
        letterSpacing: 0.3,
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ══════════════════════════════════════════════════════════════════════════════

class AssistantEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? sub;
  const AssistantEmpty({
    required this.icon,
    required this.title,
    this.sub,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: at.bgInput,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: at.textM),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: at.textS,
              ),
            ),
            if (sub != null) ...[
              const SizedBox(height: 6),
              Text(
                sub!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: at.textM),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SECTION HEAD
// ══════════════════════════════════════════════════════════════════════════════

class AssistantSectionHead extends StatelessWidget {
  final String title;
  const AssistantSectionHead({required this.title, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: at.textH,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// INFO ROW  (profile / detail pages)
// ══════════════════════════════════════════════════════════════════════════════

class AssistantIRow extends StatelessWidget {
  final String label, value;
  const AssistantIRow(this.label, this.value, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: at.textS,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: at.textH,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STAT CARD  (profile page quick stats)
// ══════════════════════════════════════════════════════════════════════════════

class AssistantStatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color, bg;
  const AssistantStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AssistantTheme.cardOf(context),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(label, style: TextStyle(fontSize: 11, color: at.textS)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FINANCE CHIP  (payments page hero card — sits on a gradient, untouched)
// ══════════════════════════════════════════════════════════════════════════════

class AssistantFinChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const AssistantFinChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.10),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// COUNT CHIP  (appointments page summary row — color/bg always passed in)
// ══════════════════════════════════════════════════════════════════════════════

class AssistantCountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color, bg;
  const AssistantCountChip({
    required this.label,
    required this.count,
    required this.color,
    required this.bg,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lc = Localizations.localeOf(context).languageCode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              arDigits('$count', lc),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BOTTOM SHEET TILE  (appointment options sheet — color always passed in)
// ══════════════════════════════════════════════════════════════════════════════

class AssistantBottomSheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const AssistantBottomSheetTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    ),
    title: Text(
      label,
      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: color),
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    onTap: onTap,
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// TOGGLE ROW  (appointment form paid/urgent switches)
// ══════════════════════════════════════════════════════════════════════════════

class AssistantToggleRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final Color color, bg;
  final ValueChanged<bool> onChanged;
  const AssistantToggleRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.color,
    required this.bg,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: value ? bg : at.bgInput,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? color.withOpacity(0.4) : at.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: value ? color : at.textM, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: value ? color : at.textS,
              ),
            ),
            const Spacer(),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// INFO CARD  (patient detail page sections)
// ══════════════════════════════════════════════════════════════════════════════

class AssistantInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<Widget> rows;
  const AssistantInfoCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.rows,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AssistantTheme.cardOf(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: at.divider),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// GENDER BUTTON  (patient form)
// ══════════════════════════════════════════════════════════════════════════════

class AssistantGenderButton extends StatelessWidget {
  final String label, val;
  final bool sel;
  final VoidCallback onTap;
  const AssistantGenderButton({
    required this.label,
    required this.val,
    required this.sel,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AssistantTheme.green : at.bgInput,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? AssistantTheme.green : at.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: sel ? Colors.white : at.textS,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ERROR WIDGET  — shared retry UI for both appointments and patients pages
// ══════════════════════════════════════════════════════════════════════════════

class AssistantErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const AssistantErrorWidget({
    required this.message,
    required this.onRetry,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final at = Theme.of(context).extension<AssistantThemeData>()!;
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: _T.urgentBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: _T.urgent,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: at.textS),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(loc.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
