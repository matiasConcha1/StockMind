import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

class PwaService extends ChangeNotifier {
  PwaService() {
    _initialize();
  }

  bool _initialized = false;
  bool _isInstalled = false;
  bool _canInstall = false;
  bool _updateAvailable = false;
  bool _isIosSafari = false;

  bool get isSupported => kIsWeb;
  bool get isInstalled => _isInstalled;
  bool get canInstall => _canInstall && !_isInstalled;
  bool get updateAvailable => _updateAvailable;
  bool get showIosInstallHint => _isIosSafari && !_isInstalled && !_canInstall;

  String get installHelpText => showIosInstallHint
      ? 'En iPhone, usa Compartir > Agregar a pantalla de inicio.'
      : _isInstalled
          ? 'La app ya está instalada en este dispositivo.'
          : 'Instala StockMind para usarlo como app independiente.';

  Future<void> promptInstall() async {
    if (!isSupported || _isInstalled) return;
    html.window.dispatchEvent(html.Event('stockmind-request-install'));
  }

  Future<void> applyUpdate() async {
    if (!isSupported || !_updateAvailable) return;
    _updateAvailable = false;
    notifyListeners();
    html.window.dispatchEvent(html.Event('stockmind-request-update'));
  }

  void _initialize() {
    if (_initialized || !kIsWeb) return;
    _initialized = true;
    _isInstalled = _detectInstalled();
    _isIosSafari = _detectIosSafari();

    html.window.addEventListener(
      'stockmind-pwa-installable',
      (_) {
        _canInstall = true;
        notifyListeners();
      },
    );
    html.window.addEventListener(
      'stockmind-pwa-installed',
      (_) {
        _isInstalled = true;
        _canInstall = false;
        notifyListeners();
      },
    );
    html.window.addEventListener(
      'stockmind-pwa-update-available',
      (_) {
        _updateAvailable = true;
        notifyListeners();
      },
    );
    html.window.addEventListener(
      'stockmind-pwa-state',
      (_) {
        _isInstalled = _detectInstalled();
        notifyListeners();
      },
    );

    html.window.dispatchEvent(html.Event('stockmind-pwa-state-request'));
  }

  bool _detectInstalled() {
    try {
      return html.window.matchMedia('(display-mode: standalone)').matches;
    } catch (_) {
      return false;
    }
  }

  bool _detectIosSafari() {
    try {
      final ua = html.window.navigator.userAgent.toLowerCase();
      final isIos = ua.contains('iphone') || ua.contains('ipad');
      final isSafari = ua.contains('safari') && !ua.contains('crios');
      return isIos && isSafari;
    } catch (_) {
      return false;
    }
  }
}
