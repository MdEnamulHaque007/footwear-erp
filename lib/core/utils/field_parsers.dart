/// Typed parsing helpers for form fields.
///
/// These centralize the "tryParse with a safe fallback" pattern so numeric
/// form fields never leak raw parse failures into the domain layer.
library;

/// Parses [text] as an int, returning 0 when null, empty or malformed.
int parseInt(String? text) => int.tryParse(text?.trim() ?? '') ?? 0;

/// Parses [text] as a double, returning 0 when null, empty or malformed.
double parseDouble(String? text) => double.tryParse(text?.trim() ?? '') ?? 0;
