DateTime parseDate(String raw) => DateTime.parse(raw);

DateTime? parseDateOrNull(String? raw) =>
    (raw == null || raw.isEmpty) ? null : DateTime.parse(raw);
