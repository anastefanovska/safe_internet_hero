import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

// AdminColors — delegates to AppColors.
class AdminColors {
  static const teal = AppColors.blue;
  static const darkTeal = AppColors.blueDark;
  static const red = AppColors.hero;
  static const yellow = AppColors.gold;
  static const yellowDark = AppColors.goldDark;
  static const cream = AppColors.background;
}

// ─── AdminHeader ──────────────────────────────────────────────────────────────
// Reusable screen header that matches the main app's style.

class AdminHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final TabController? tabController;
  final List<String>? tabs;

  /// Optional per-tab count badges (parallel to [tabs]). A red pill is shown on
  /// a tab when its count is greater than zero.
  final List<int>? tabBadges;

  const AdminHeader({
    super.key,
    required this.title,
    this.trailing,
    this.tabController,
    this.tabs,
    this.tabBadges,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  trailing != null
                      ? trailing!
                      : const SizedBox(width: 48),
                ],
              ),
            ),
          ),
          if (tabController != null && tabs != null)
            TabBar(
              controller: tabController,
              labelStyle: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800, fontSize: 14),
              unselectedLabelStyle: GoogleFonts.nunito(
                  fontWeight: FontWeight.w600, fontSize: 14),
              labelColor: AppColors.blue,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.blue,
              indicatorWeight: 2.5,
              dividerColor: Colors.transparent,
              tabs: [
                for (var i = 0; i < tabs!.length; i++)
                  Tab(
                    child: _AdminTabLabel(
                      text: tabs![i],
                      badge: (tabBadges != null && i < tabBadges!.length)
                          ? tabBadges![i]
                          : 0,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// A tab label that inherits the TabBar's animated colour and optionally shows
/// a red count pill (e.g. number of pending items in that tab).
class _AdminTabLabel extends StatelessWidget {
  final String text;
  final int badge;
  const _AdminTabLabel({required this.text, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(text),
      if (badge > 0) ...[
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          constraints: const BoxConstraints(minWidth: 18),
          decoration: BoxDecoration(
            color: AppColors.red,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            badge > 99 ? '99+' : '$badge',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10),
          ),
        ),
      ],
    ]);
  }
}

// ─── AdminCard ────────────────────────────────────────────────────────────────

class AdminCard extends StatelessWidget {
  final String title;
  final Widget child;
  const AdminCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          child,
        ]),
      );
}

// ─── AdminEditBanner ──────────────────────────────────────────────────────────

class AdminEditBanner extends StatelessWidget {
  final String title;
  final VoidCallback onClear;
  const AdminEditBanner(
      {super.key, required this.title, required this.onClear});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
        ),
        child: Row(children: [
          const Icon(Icons.edit_rounded, color: AppColors.goldDark, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text('Editing: $title',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                      color: AppColors.goldDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 13))),
          GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close_rounded,
                  color: AppColors.goldDark, size: 18)),
        ]),
      );
}

// ─── AdminLabel ───────────────────────────────────────────────────────────────

class AdminLabel extends StatelessWidget {
  final String text;
  const AdminLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.nunito(
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          fontSize: 12,
          letterSpacing: 0.3));
}

// ─── AdminField ───────────────────────────────────────────────────────────────

class AdminField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  const AdminField({
    super.key,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textPrimary),
        decoration: _dec(hint),
      );

  static InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.nunito(
            color: AppColors.textLight, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.border, width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.border, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.blue, width: 2)),
      );

  static InputDecoration decoration(String hint) => _dec(hint);
}

// ─── AdminDropdown ────────────────────────────────────────────────────────────

class AdminDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final String hint;
  final ValueChanged<T?> onChanged;
  const AdminDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
        initialValue: value,
        items: items,
        onChanged: onChanged,
        style: GoogleFonts.nunito(
            fontSize: 14, color: AppColors.textPrimary),
        decoration: AdminField._dec(hint),
      );
}

// ─── AdminSearchField ─────────────────────────────────────────────────────────
// Rounded search box with a leading magnifier and a clear (×) button.

class AdminSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;
  const AdminSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'Search...',
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.nunito(color: AppColors.textLight, fontSize: 14),
        prefixIcon:
            const Icon(Icons.search_rounded, color: AppColors.textLight),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.textLight, size: 20),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.blue, width: 2)),
      ),
    );
  }
}

// ─── AdminFilterDropdown ──────────────────────────────────────────────────────
// Compact filter control (e.g. category / topic). Built on MenuAnchor so the
// menu drops *below* the trigger and the hover/press highlight is rounded to
// match the box. Controlled via [value] so it always shows the current pick.

class AdminFilterDropdown extends StatelessWidget {
  final String value;
  final List<({String value, String label})> options;
  final ValueChanged<String> onChanged;
  final IconData icon;
  const AdminFilterDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final current = options.firstWhere((o) => o.value == value,
        orElse: () => options.first);

    return MenuAnchor(
      alignmentOffset: const Offset(0, 6),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(3),
        padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 4)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        )),
      ),
      menuChildren: [
        for (final o in options)
          MenuItemButton(
            onPressed: () => onChanged(o.value),
            leadingIcon: Icon(Icons.check_rounded,
                size: 18,
                color:
                    o.value == value ? AppColors.blue : Colors.transparent),
            child: Text(o.label,
                style: GoogleFonts.nunito(
                    fontSize: 13.5,
                    fontWeight:
                        o.value == value ? FontWeight.w800 : FontWeight.w600,
                    color: o.value == value
                        ? AppColors.blue
                        : AppColors.textPrimary)),
          ),
      ],
      builder: (context, controller, _) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(children: [
            Icon(icon, size: 18, color: AppColors.textLight),
            const SizedBox(width: 8),
            Expanded(
              child: Text(current.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textLight),
          ]),
        ),
      ),
    );
  }
}

// ─── AdminToggle ──────────────────────────────────────────────────────────────

class AdminToggle extends StatelessWidget {
  final String label;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;
  const AdminToggle({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: value
                ? color.withValues(alpha: 0.1)
                : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: value ? color : AppColors.border,
                width: value ? 2 : 1.5),
          ),
          child: Row(children: [
            Icon(
                value
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: value ? color : AppColors.textLight,
                size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color:
                        value ? color : AppColors.textSecondary)),
          ]),
        ),
      );
}

// ─── AdminSelectTile ──────────────────────────────────────────────────────────

class AdminSelectTile extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const AdminSelectTile({
    super.key,
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.blue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? c.withValues(alpha: 0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? c : AppColors.border,
              width: selected ? 2 : 1.5),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                color: selected ? c : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
      ),
    );
  }
}

// ─── AdminDifficultyTile ──────────────────────────────────────────────────────

class AdminDifficultyTile extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const AdminDifficultyTile({
    super.key,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.1)
                : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? color : AppColors.border,
                width: selected ? 2 : 1.5),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                  color: selected ? color : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
        ),
      );
}

// ─── AdminTypeButton ──────────────────────────────────────────────────────────

class AdminTypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const AdminTypeButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.blue.withValues(alpha: 0.1)
                : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AppColors.blue : AppColors.border,
                width: selected ? 2 : 1.5),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                color: selected
                    ? AppColors.blue
                    : AppColors.textLight,
                size: 20),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    color: selected
                        ? AppColors.blueDark
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ]),
        ),
      );
}

// ─── AdminOptionField ─────────────────────────────────────────────────────────

class AdminOptionField extends StatelessWidget {
  final TextEditingController controller;
  final String letter;
  final int index;
  final int correctIndex;
  final VoidCallback onTap;
  const AdminOptionField({
    super.key,
    required this.controller,
    required this.letter,
    required this.index,
    required this.correctIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = correctIndex == index;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isCorrect ? AppColors.green : AppColors.border,
              width: isCorrect ? 2 : 1.5),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 50,
            decoration: BoxDecoration(
              color: isCorrect
                  ? AppColors.greenLight
                  : AppColors.background,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10)),
            ),
            child: Center(
                child: Text(isCorrect ? '✓' : letter,
                    style: TextStyle(
                        color: isCorrect
                            ? AppColors.greenDark
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13))),
          ),
          Expanded(
              child: TextField(
            controller: controller,
            style: GoogleFonts.nunito(
                fontSize: 13, color: AppColors.textPrimary),
            decoration: InputDecoration(
                hintText: 'Option $letter',
                hintStyle: GoogleFonts.nunito(
                    color: AppColors.textLight, fontSize: 13),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12)),
          )),
        ]),
      ),
    );
  }
}

// ─── Buttons ──────────────────────────────────────────────────────────────────

class AdminPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const AdminPrimaryButton(
      {super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.blue,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                  color: AppColors.blueDark,
                  offset: Offset(0, 4),
                  blurRadius: 0)
            ],
          ),
          child: Center(
              child: Text(label,
                  style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15))),
        ),
      );
}

class AdminSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const AdminSecondaryButton(
      {super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderDark, width: 1.5),
          ),
          child: Center(
              child: Text(label,
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary))),
        ),
      );
}

// ─── AdminBottomSheet ─────────────────────────────────────────────────────────

class AdminBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  const AdminBottomSheet(
      {super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4))
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(20)))),
              const SizedBox(height: 16),
              Text(title,
                  style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              child,
              const SizedBox(height: 8),
            ]),
          ),
        ),
      );
}

// ─── AdminBadge ───────────────────────────────────────────────────────────────

class AdminBadge extends StatelessWidget {
  final String text;
  final Color color;
  const AdminBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6)),
        child: Text(text,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 9,
                letterSpacing: 0.3)),
      );
}

// ─── AdminEmptyState ──────────────────────────────────────────────────────────

class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(icon, color: AppColors.textLight, size: 36),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    color: AppColors.textLight, fontSize: 13)),
          ]),
        ),
      );
}

// ─── AdminDashboardCard ───────────────────────────────────────────────────────

class AdminDashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  /// Optional workload badge (e.g. number of items needing attention). When
  /// greater than zero, a red count pill is shown next to the title.
  final int badgeCount;

  const AdminDashboardCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.blue, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Flexible(
                    child: Text(title,
                        style: GoogleFonts.nunito(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                  ),
                  if (badgeCount > 0) ...[
                    const SizedBox(width: 8),
                    AdminCountBadge(count: badgeCount),
                  ],
                ]),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: GoogleFonts.nunito(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4)),
              ])),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textLight, size: 22),
        ]),
      ),
    );
  }
}

// ─── AdminCountBadge ──────────────────────────────────────────────────────────
// Small red pill showing a workload count (pending reviews, etc.).

class AdminCountBadge extends StatelessWidget {
  final int count;
  const AdminCountBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        constraints: const BoxConstraints(minWidth: 20),
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          count > 99 ? '99+' : '$count',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
        ),
      );
}
