/// Splits one line of the TfL CSV files into fields.
///
/// Fields may be wrapped in double quotes so they can contain commas (e.g.
/// the stop name "Guy, Earl of Warwick"); a doubled quote inside a quoted
/// field is a literal quote. Fields are trimmed.
List<String> parseCsvLine(String line) {
  final List<String> fields = [];
  final StringBuffer current = StringBuffer();
  bool inQuotes = false;

  for (int i = 0; i < line.length; i++) {
    final String char = line[i];
    if (char == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        current.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char == ',' && !inQuotes) {
      fields.add(current.toString().trim());
      current.clear();
    } else {
      current.write(char);
    }
  }
  fields.add(current.toString().trim());
  return fields;
}

/// Splits a whole CSV file into rows of fields, like [parseCsvLine] but also
/// allowing line breaks inside quoted fields (a few TfL stop names have one,
/// e.g. "Sidcup / Carlton Road" followed by a line break). Blank rows are
/// dropped. Includes the header row.
List<List<String>> parseCsv(String text) {
  final List<List<String>> rows = [];
  List<String> row = [];
  final StringBuffer current = StringBuffer();
  bool inQuotes = false;

  void endField() {
    row.add(current.toString().trim());
    current.clear();
  }

  void endRow() {
    endField();
    if (row.length > 1 || row.first.isNotEmpty) rows.add(row);
    row = [];
  }

  for (int i = 0; i < text.length; i++) {
    final String char = text[i];
    if (char == '"') {
      if (inQuotes && i + 1 < text.length && text[i + 1] == '"') {
        current.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char == ',' && !inQuotes) {
      endField();
    } else if ((char == '\n' || char == '\r') && !inQuotes) {
      // Treat \r\n as one line break.
      if (char == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      endRow();
    } else {
      current.write(char);
    }
  }
  if (current.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}
