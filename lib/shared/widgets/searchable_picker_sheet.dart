import 'package:flutter/material.dart';
import 'package:invoice_kit/core/constants/invoice_constants.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_radius.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/theme/app_tokens.dart';
import 'package:invoice_kit/core/widgets/app_bottom_sheet.dart';
import 'package:invoice_kit/core/widgets/empty_state.dart';
import 'package:invoice_kit/core/widgets/search_field.dart';
import 'package:invoice_kit/shared/widgets/currency_picker_row.dart'
    show CurrencyPickerRow;
// import 'package:invoice_kit/shared/widgets/widgets.dart' show CurrencyPickerRow; // Unused import removed

/// Searchable option item used by [SearchablePickerSheet].
class SearchableOption<T> {
  const SearchableOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.searchTerms,
  });

  final T value;
  final String label;
  final String? subtitle;

  /// Extra tokens used to match search queries. Defaults to
  /// [label] + [subtitle] when not provided.
  final List<String>? searchTerms;

  bool matches(String query) {
    if (query.isEmpty) return true;
    final haystack = [
      label,
      if (subtitle != null) subtitle,
      ...?searchTerms,
    ].join(' ').toLowerCase();
    return haystack.contains(query.toLowerCase());
  }
}

/// Reusable searchable bottom sheet. Use for any list that may grow
/// long (currencies, clients, templates, etc.).
class SearchablePickerSheet<T> extends StatefulWidget {
  const SearchablePickerSheet({
    required this.title,
    required this.options,
    required this.onSelected,
    super.key,
    this.subtitle,
    this.hint = 'Search',
    this.emptyTitle = 'No matches',
    this.emptySubtitle = 'Try a different search term.',
    this.leadingBuilder,
  });

  // Removed erroneous named constructor that conflicted with static show method.

  final String title;
  final String? subtitle;
  final String hint;
  final String emptyTitle;
  final String emptySubtitle;
  final List<SearchableOption<T>> options;
  final ValueChanged<T> onSelected;
  final Widget Function(SearchableOption<T> option)? leadingBuilder;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<SearchableOption<T>> options,
    String? subtitle,
    String hint = 'Search',
    String emptyTitle = 'No matches',
    String emptySubtitle = 'Try a different search term.',
    Widget Function(SearchableOption<T> option)? leadingBuilder,
  }) {
    return AppBottomSheet.show<T>(
      context: context,
      title: title,
      subtitle: subtitle,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: _SearchablePickerSheet<T>(
            title: title,
            subtitle: subtitle,
            hint: hint,
            emptyTitle: emptyTitle,
            emptySubtitle: emptySubtitle,
            options: options,
            leadingBuilder: leadingBuilder,
            autoConsumeSelection: true,
          ),
        ),
      ],
    );
  }

  @override
  _SearchablePickerSheetState<T> createState() =>
      _SearchablePickerSheetState<T>();
}

class _SearchablePickerSheet<T> extends StatefulWidget {
  const _SearchablePickerSheet({
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.options,
    required this.autoConsumeSelection,
    this.leadingBuilder,
  });

  final String title;
  final String? subtitle;
  final String hint;
  final String emptyTitle;
  final String emptySubtitle;
  final List<SearchableOption<T>> options;
  final bool autoConsumeSelection;
  final Widget Function(SearchableOption<T> option)? leadingBuilder;

  @override
  State<_SearchablePickerSheet<T>> createState() =>
      _SearchablePickerSheetState<T>();
}

class _SearchablePickerSheetState<T> extends State<_SearchablePickerSheet<T>> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.options
        : widget.options.where((o) => o.matches(_query)).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchField(
          controller: _ctrl,
          hint: widget.hint,
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
        const SizedBox(height: AppSpacing.sm),
        Flexible(
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: EmptyState(
                    icon: Icons.search_off_rounded,
                    title: widget.emptyTitle,
                    subtitle: widget.emptySubtitle,
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final option = filtered[i];
                    return ListTile(
                      leading: widget.leadingBuilder?.call(option),
                      title: Text(option.label),
                      subtitle:
                          option.subtitle == null || option.subtitle!.isEmpty
                          ? null
                          : Text(option.subtitle!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      onTap: () {
                        if (widget.autoConsumeSelection) {
                          Navigator.of(context).pop(option.value);
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Drop-in replacement for [CurrencyPickerRow] that opens a searchable
/// bottom sheet instead of a plain list.
class SearchableCurrencyPickerRow extends StatelessWidget {
  const SearchableCurrencyPickerRow({
    required this.selected,
    required this.options,
    required this.onSelected,
    super.key,
  });

  final String selected;
  final List<String> options;
  final ValueChanged<String> onSelected;

  Future<void> _open(BuildContext context) async {
    final code = await SearchablePickerSheet.show<String>(
      context: context,
      title: 'Pick a currency',
      hint: 'Search currencies',
      options: options
          .map(
            (c) => SearchableOption<String>(
              value: c,
              label: c,
              subtitle: CurrencyCodes.symbolOf(c),
            ),
          )
          .toList(),
      leadingBuilder: (o) => CircleAvatar(
        radius: 14,
        backgroundColor: context.tokens.brandSubtle,
        child: Text(
          CurrencyCodes.symbolOf(o.value).characters.first,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
    if (code != null) {
      onSelected(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: context.tokens.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.attach_money,
              color: context.colors.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Currency',
                style: context.textTheme.bodyMedium,
              ),
            ),
            Text(
              selected,
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.chevron_right,
              color: context.colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
