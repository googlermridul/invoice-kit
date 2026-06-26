import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/core/widgets/app_card.dart';
import 'package:invoice_kit/features/invoices/domain/entities/document_item.dart';
import 'package:invoice_kit/shared/widgets/app_text_field.dart';

/// Editable line item card. Reused by both invoice and quote edit forms.
class LineItemEditor extends StatefulWidget {
  const LineItemEditor({
    required this.item,
    required this.onChanged,
    super.key,
    this.onRemove,
    this.showTax = false,
    this.validatorDescription,
    this.validatorQuantity,
    this.validatorUnitPrice,
    this.validatorTaxRate,
  });

  final DocumentItem item;
  final ValueChanged<DocumentItem> onChanged;
  final VoidCallback? onRemove;
  final bool showTax;

  /// Optional per-field validators. When supplied, the parent
  /// `Form.validate()` will invoke them. Keep them `null` for
  /// line items that should not be validated.
  final FormFieldValidator<String>? validatorDescription;
  final FormFieldValidator<String>? validatorQuantity;
  final FormFieldValidator<String>? validatorUnitPrice;
  final FormFieldValidator<String>? validatorTaxRate;

  @override
  State<LineItemEditor> createState() => _LineItemEditorState();
}

class _LineItemEditorState extends State<LineItemEditor> {
  late final _descCtrl = TextEditingController(text: widget.item.description);
  late final _qtyCtrl = TextEditingController(
    text: _formatQty(widget.item.quantity),
  );
  late final _priceCtrl = TextEditingController(
    text: widget.item.unitPrice == 0
        ? ''
        : widget.item.unitPrice.toStringAsFixed(2),
  );
  late final _taxCtrl = TextEditingController(
    text: widget.item.taxRate == 0
        ? ''
        : widget.item.taxRate.toStringAsFixed(0),
  );

  String _formatQty(double q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toString();

  @override
  void dispose() {
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _taxCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      widget.item.copyWith(
        description: _descCtrl.text,
        quantity: double.tryParse(_qtyCtrl.text) ?? 1,
        unitPrice: double.tryParse(_priceCtrl.text) ?? 0,
        taxRate: double.tryParse(_taxCtrl.text) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _descCtrl,
            label: 'Description',
            hint: 'Service or product',
            dense: true,
            validator: widget.validatorDescription,
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  controller: _qtyCtrl,
                  label: 'Qty',
                  dense: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: widget.validatorQuantity,
                  onChanged: (_) => _emit(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: AppTextField(
                  controller: _priceCtrl,
                  label: 'Unit price',
                  dense: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: widget.validatorUnitPrice,
                  onChanged: (_) => _emit(),
                ),
              ),
              if (widget.showTax) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppTextField(
                    controller: _taxCtrl,
                    label: 'Tax %',
                    dense: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: widget.validatorTaxRate,
                    onChanged: (_) => _emit(),
                  ),
                ),
              ],
            ],
          ),
          if (widget.onRemove != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.onRemove,
                icon: const Icon(HugeIconsStroke.delete01, size: 18),
                label: const Text('Remove'),
              ),
            ),
        ],
      ),
    );
  }
}
