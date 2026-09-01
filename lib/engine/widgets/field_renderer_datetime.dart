// lib/engine/widgets/field_renderer_datetime.dart
//
// The date/time-family field widgets used by FieldRenderer: date, time,
// datetime, duration. Split out of field_renderer.dart (which had grown
// to 780 lines) — these were private classes, now public so
// field_renderer.dart's dispatch switch can still reach them from this
// new file.
//
// FIX — mounted checks after every async picker call (carried over from
// the original file):
//   DateField._pick()     — added `if (!mounted) return;` after showDatePicker
//   TimeField._pick()     — added `if (!mounted) return;` after showTimePicker
//   DateTimeField._pick() — was already correctly guarded (checked)
//
//   Without these checks, if the user navigates away while a picker is
//   open (possible on slow devices or during a Riverpod invalidation),
//   calling widget.onChanged or setState on a disposed widget throws a
//   FlutterError that crashes the current route.
//
// See field_renderer.dart for FieldRenderer itself and the full list of
// supported field types.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personal_wellness_trainer/core/theme/app_spacing.dart';
import 'package:personal_wellness_trainer/core/theme/app_text_styles.dart';
import 'package:personal_wellness_trainer/core/widgets/app_text_field.dart';
import 'package:personal_wellness_trainer/engine/config/industry_config.dart';
import 'package:personal_wellness_trainer/engine/widgets/field_renderer_validators.dart';

class DateField extends StatefulWidget {
  const DateField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final ActivityField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  State<DateField> createState() => DateFieldState();
}

class DateFieldState extends State<DateField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _formatDate(widget.value),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDate(dynamic v) {
    if (v == null) return '';
    if (v is String && v.isNotEmpty) {
      try {
        return DateTime.parse(v).toLocal().toString().substring(0, 10);
      } catch (_) {
        return v;
      }
    }
    if (v is DateTime) {
      return v.toLocal().toString().substring(0, 10);
    }
    return '';
  }

  Future<void> _pick() async {
    final initial = DateTime.tryParse(
          widget.value?.toString() ?? '',
        ) ??
        DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    // FIX: guard against widget being disposed while the picker was open.
    // Without this check, calling _controller.text= or widget.onChanged()
    // on a disposed State throws a FlutterError and crashes the current route.
    if (!mounted) return;

    if (picked != null) {
      _controller.text = picked.toLocal().toString().substring(0, 10);
      widget.onChanged(picked.toIso8601String());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      hint: 'Select date',
      label: widget.field.label,
      controller: _controller,
      readOnly: true,
      prefixIcon: Icons.calendar_today_outlined,
      onTap: _pick,
      validator: (v) => requiredFieldValidator(widget.field, v),
    );
  }
}

class TimeField extends StatefulWidget {
  const TimeField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final ActivityField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  State<TimeField> createState() => TimeFieldState();
}

class TimeFieldState extends State<TimeField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatTime(widget.value));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTime(dynamic v) {
    if (v == null || v.toString().isEmpty) return '';
    if (v is String && v.contains(':')) return v;
    return '';
  }

  Future<void> _pick() async {
    final parts = (widget.value?.toString() ?? '').split(':');
    final initial = parts.length >= 2
        ? TimeOfDay(
            hour: int.tryParse(parts[0]) ?? TimeOfDay.now().hour,
            minute: int.tryParse(parts[1]) ?? 0,
          )
        : TimeOfDay.now();

    final picked = await showTimePicker(context: context, initialTime: initial);

    // FIX: same as DateField — guard against disposal during picker open.
    if (!mounted) return;

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      _controller.text = formatted;
      widget.onChanged(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      hint: 'Select time',
      label: widget.field.label,
      controller: _controller,
      readOnly: true,
      prefixIcon: Icons.access_time_outlined,
      onTap: _pick,
      validator: (v) => requiredFieldValidator(widget.field, v),
    );
  }
}

class DateTimeField extends StatefulWidget {
  const DateTimeField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final ActivityField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  State<DateTimeField> createState() => DateTimeFieldState();
}

class DateTimeFieldState extends State<DateTimeField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(dynamic v) {
    if (v == null || v.toString().isEmpty) return '';
    try {
      final dt = DateTime.parse(v.toString()).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return v.toString();
    }
  }

  Future<void> _pick() async {
    DateTime initial;
    try {
      initial = DateTime.parse(widget.value?.toString() ?? '');
    } catch (_) {
      initial = DateTime.now();
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    // Already guarded — existing code was correct here ✓
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    // FIX: also guard after the second await (time picker).
    // The original code only checked mounted after the date picker, not after
    // the time picker. A disposal between the two pickers would still crash.
    if (time == null || !mounted) return;

    final combined = DateTime(
      date.year, date.month, date.day, time.hour, time.minute,
    );
    _controller.text = _format(combined.toIso8601String());
    widget.onChanged(combined.toIso8601String());
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      hint: 'Select date & time',
      label: widget.field.label,
      controller: _controller,
      readOnly: true,
      prefixIcon: Icons.event_outlined,
      onTap: _pick,
      validator: (v) => requiredFieldValidator(widget.field, v),
    );
  }
}

class DurationField extends StatefulWidget {
  const DurationField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final ActivityField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  State<DurationField> createState() => DurationFieldState();
}

class DurationFieldState extends State<DurationField> {
  late final TextEditingController _hoursCtrl;
  late final TextEditingController _minutesCtrl;

  @override
  void initState() {
    super.initState();
    int totalMinutes = 0;
    if (widget.value is int) totalMinutes = widget.value as int;
    if (widget.value is String) {
      totalMinutes = int.tryParse(widget.value.toString()) ?? 0;
    }
    _hoursCtrl = TextEditingController(
      text: (totalMinutes ~/ 60).toString(),
    );
    _minutesCtrl = TextEditingController(
      text: (totalMinutes % 60).toString(),
    );
  }

  @override
  void dispose() {
    _hoursCtrl.dispose();
    _minutesCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    final h = int.tryParse(_hoursCtrl.text) ?? 0;
    final m = int.tryParse(_minutesCtrl.text) ?? 0;
    widget.onChanged(h * 60 + m);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.field.label, style: AppTextStyles.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _hoursCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Hours'),
                onChanged: (_) => _notify(),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextFormField(
                controller: _minutesCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Minutes'),
                onChanged: (_) => _notify(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

