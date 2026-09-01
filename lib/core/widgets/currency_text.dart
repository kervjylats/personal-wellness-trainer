// lib/core/widgets/currency_text.dart
//
// Displays a currency amount formatted consistently throughout the app.
// Always requires [currencySymbol] — this comes from industry_config.json
// at runtime (provided by the calling screen, not imported here).
//
// Core files cannot import from engine/ — the caller provides the symbol.
//
// Usage:
//   CurrencyText(
//     amount: 1234.50,
//     currencySymbol: config.payment.currencyDefault, // '$'
//     style: AppTextStyles.currencyLarge,
//   )

import 'package:flutter/material.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/utils/formatters.dart';

class CurrencyText extends StatelessWidget {
  const CurrencyText({
    super.key,
    required this.amount,
    required this.currencySymbol,
    this.style,
    this.textAlign,
    this.showSign = false,
    this.compact = false,
  });

  final double amount;
  final String currencySymbol;

  /// Text style. Defaults to [AppTextStyles.currencyMedium].
  final TextStyle? style;
  final TextAlign? textAlign;

  /// If true, prepends '+' for positive amounts.
  /// Negative amounts always show '-'.
  final bool showSign;

  /// If true, uses compact notation (e.g. \$1.2K, \$3.5M) for large amounts.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final String formatted = compact
        ? AppFormatters.currencyCompact(amount.abs(), currencySymbol)
        : AppFormatters.currency(amount.abs(), currencySymbol);

    String display;
    if (amount < 0) {
      display = '-$formatted';
    } else if (showSign && amount > 0) {
      display = '+$formatted';
    } else {
      display = formatted;
    }

    return Text(
      display,
      style: style ?? AppTextStyles.currencyMedium,
      textAlign: textAlign,
    );
  }
}
