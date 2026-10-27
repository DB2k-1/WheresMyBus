/// Stations and piers you can change to at a bus stop.
enum Interchange { tube, overground, rail, dlr, tram, river }

/// TfL marks interchanges in stop names with symbols, e.g.
/// "Trafalgar Square / Charing Cross Stn <>#":
///   <>     London Underground
///   >lol<  London Overground
///   #      National Rail
///   [dlr]  DLR
///   >t<    Tram
///   >r<    River boat pier
/// This splits a name into the plain name to show and the interchanges to
/// show as badges.
class StopName {
  final String name;
  final Set<Interchange> interchanges;

  const StopName._(this.name, this.interchanges);

  // The letter markers go first so their ">" and "<" aren't mistaken for
  // part of the Underground's "<>".
  static final List<(RegExp, Interchange)> _markers = [
    (RegExp(r'>\s*lol\s*<', caseSensitive: false), Interchange.overground),
    (RegExp(r'>\s*t\s*<', caseSensitive: false), Interchange.tram),
    (RegExp(r'>\s*r\s*<', caseSensitive: false), Interchange.river),
    (RegExp(r'\[\s*dlr\s*\]', caseSensitive: false), Interchange.dlr),
    (RegExp(r'<>'), Interchange.tube),
    (RegExp(r'#'), Interchange.rail),
  ];

  factory StopName.parse(String raw) {
    String name = raw;
    final Set<Interchange> interchanges = {};
    for (final (pattern, interchange) in _markers) {
      if (pattern.hasMatch(name)) {
        interchanges.add(interchange);
        name = name.replaceAll(pattern, ' ');
      }
    }
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    return StopName._(name.isEmpty ? raw.trim() : name, interchanges);
  }

  /// Just the plain name.
  static String clean(String raw) => StopName.parse(raw).name;
}
