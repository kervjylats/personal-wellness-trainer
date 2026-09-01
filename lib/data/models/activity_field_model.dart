// lib/data/models/activity_field_model.dart
//
// ActivityField is the Dart model for one entry in the activity_fields array
// from industry_config.json. It describes a form field — its name, label,
// type, required flag, and dropdown options.
//
// IMPORTANT: ActivityField is defined in lib/engine/config/industry_config.dart
// because it is part of the configuration schema. It lives there and is
// re-exported here for convenience so other data-layer files can import from
// data/models/ without reaching into engine/config/.
//
// FieldRenderer (Phase 3, P3-07) reads ActivityField to decide which input
// widget to render. ActivityModel.fields stores the values keyed by
// ActivityField.name.
//
// Supported field types:
//   text         → single-line text input
//   textarea     → multi-line text input
//   number       → numeric keyboard, integer or decimal
//   currency     → numeric with currency symbol prefix
//   dropdown     → DropdownButtonFormField, options from ActivityField.options
//   date         → date picker
//   time         → time picker
//   datetime     → date + time picker
//   duration     → hours + minutes row
//   boolean      → toggle switch
//   staff_picker → dropdown populated from the business's staff list
//   client_picker → dropdown populated from the business's client list
//   location     → text input (map integration in a future phase)
//   image_upload → placeholder (media upload wired in Phase 6)

export 'package:personal_wellness_trainer/engine/config/industry_config.dart' show ActivityField;
