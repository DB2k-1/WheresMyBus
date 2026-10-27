import 'package:wheres_my_bus/models/bus_stop.dart';

/// App Store screenshots. Build with one of:
///   --dart-define=SCREENSHOT_MODE=list    (stop list, nothing open)
///   --dart-define=SCREENSHOT_MODE=buses   (first bus stop open)
///   --dart-define=SCREENSHOT_MODE=cycles  (Cycles tab, nearest station open)
/// Ads and the rating prompt are hidden, and a few central London stops are
/// saved if there are none yet.
const String screenshotView = String.fromEnvironment('SCREENSHOT_MODE');
const bool screenshotMode = screenshotView != '';

final List<BusStop> screenshotBusStops = [
  BusStop(
    stopCodeLbsl: '143',
    busStopCode: '55677',
    naptanAtco: '490013767D',
    stopName: 'Trafalgar Square / Charing Cross Stn <>#',
    locationEasting: 530076,
    locationNorthing: 180468,
    heading: 176,
    stopArea: '0C16',
    virtualBusStop: false,
  ),
  BusStop(
    stopCodeLbsl: '996',
    busStopCode: '50906',
    naptanAtco: '490015048A',
    stopName: 'Westminster Stn <> / Parliament Square',
    locationEasting: 530144,
    locationNorthing: 179768,
    heading: 9,
    stopArea: '0K08',
    virtualBusStop: false,
  ),
  BusStop(
    stopCodeLbsl: '150',
    busStopCode: '73476',
    naptanAtco: '490000179F',
    stopName: 'Piccadilly Circus',
    locationEasting: 529391,
    locationNorthing: 180649,
    heading: 86,
    stopArea: '0C05',
    virtualBusStop: false,
  ),
  BusStop(
    stopCodeLbsl: '16575',
    busStopCode: '52972',
    naptanAtco: '490000173RG',
    stopName: 'Oxford Circus Station <>',
    locationEasting: 529046,
    locationNorthing: 181155,
    heading: 173,
    stopArea: '0804',
    virtualBusStop: false,
  ),
];
