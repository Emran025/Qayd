import 'package:flutter/material.dart';
import 'package:qayd/domain/value_objects/message_template_kind.dart';

class TemplateVariable {
  final String key;
  final String label;
  final String charCode;
  final MessageTemplateKind? kindRestricted; // if null, available for all

  const TemplateVariable(this.key, this.label, this.charCode, {this.kindRestricted});
}

// Private Use Area Unicode Characters
final List<TemplateVariable> kTemplateVariables = [
  const TemplateVariable('{{customer}}', 'الطرف الآخر', '\uE000'),
  const TemplateVariable('{{counterparty}}', 'الطرف الآخر', '\uE001'),
  const TemplateVariable('{{amount}}', 'المبلغ', '\uE002'),
  const TemplateVariable('{{currency}}', 'العملة', '\uE003'),
  const TemplateVariable('{{date}}', 'التاريخ', '\uE004'),
  const TemplateVariable('{{affected_account}}', 'الحساب', '\uE005'),
  const TemplateVariable('{{reference}}', 'الرقم المرجعي', '\uE006'),
  const TemplateVariable('{{description}}', 'البيان', '\uE007'),
  const TemplateVariable('{{notes}}', 'الملاحظات', '\uE008'),
  const TemplateVariable('{{voucher_id}}', 'رقم السند', '\uE009'),
  const TemplateVariable('{{type}}', 'النوع', '\uE00A'),
  const TemplateVariable('{{signature}}', 'التوقيع الإلكتروني', '\uE00B'),
  // Account Specific
  const TemplateVariable('{{account_name}}', 'اسم الحساب', '\uE00C', kindRestricted: MessageTemplateKind.accountBalance),
  const TemplateVariable('{{balance}}', 'الرصيد', '\uE00D', kindRestricted: MessageTemplateKind.accountBalance),
  const TemplateVariable('{{nature}}', 'النوع (مدين/دائن)', '\uE00E', kindRestricted: MessageTemplateKind.accountBalance),
  const TemplateVariable('{{account_id}}', 'معرّف الحساب', '\uE00F'),
];

class TemplateTextController extends TextEditingController {
  TemplateTextController({String? initialDbText}) {
    text = _dbToUi(initialDbText ?? '');
  }

  /// Converts DB format e.g. "عزيزي {{customer}}" -> "عزيزي \uE000"
  static String _dbToUi(String dbText) {
    String ui = dbText;
    for (final v in kTemplateVariables) {
      ui = ui.replaceAll(v.key, v.charCode);
    }
    return ui;
  }

  /// Converts UI format e.g. "عزيزي \uE000" -> "عزيزي {{customer}}"
  String get dbText {
    String db = text;
    for (final v in kTemplateVariables) {
      db = db.replaceAll(v.charCode, v.key);
    }
    return db;
  }

  void insertVariable(TemplateVariable v) {
    final int start = selection.baseOffset;
    final int end = selection.extentOffset;
    
    // Safely fallback to cursor at the end
    if (start < 0 || end < 0) {
      text = text + v.charCode;
      selection = TextSelection.collapsed(offset: text.length);
      return;
    }

    final int minPos = start < end ? start : end;
    final int maxPos = start > end ? start : end;

    final String prefix = text.substring(0, minPos);
    final String suffix = text.substring(maxPos);
    
    text = prefix + v.charCode + suffix;
    selection = TextSelection.collapsed(offset: minPos + 1);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<InlineSpan> children = [];
    final textStr = value.text;
    
    // Fast path: find occurrences of characters
    final validChars = kTemplateVariables.map((e) => e.charCode).toSet();

    for (int i = 0; i < textStr.length; i++) {
        final char = textStr[i];
        if (validChars.contains(char)) {
            final templateVar = kTemplateVariables.firstWhere((e) => e.charCode == char);
            children.add(
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Text(
                    templateVar.label,
                    style: (style ?? const TextStyle()).copyWith(
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: (style?.fontSize ?? 14) * 0.9,
                    ),
                  ),
                ),
              ),
            );
        } else {
            // Buffer consecutive regular chars for better performance
            int j = i;
            while(j < textStr.length && !validChars.contains(textStr[j])) {
               j++;
            }
            children.add(TextSpan(text: textStr.substring(i, j), style: style));
            i = j - 1; // i will increment to j on loop continue
        }
    }
    
    return TextSpan(children: children, style: style);
  }
}
