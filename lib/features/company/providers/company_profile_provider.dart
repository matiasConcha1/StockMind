import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:stockmind/core/services/storage_service.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/company/data/services/company_profile_service.dart';
import 'package:stockmind/features/company/models/company_profile.dart';
import 'package:stockmind/features/company/providers/current_company_provider.dart';

class CompanyProfileProvider extends ChangeNotifier {
  CompanyProfileProvider({
    required AuthProvider authProvider,
    required CurrentCompanyProvider currentCompanyProvider,
    required CompanyProfileService service,
    required StorageService storageService,
  })  : _authProvider = authProvider,
        _currentCompanyProvider = currentCompanyProvider,
        _service = service,
        _storageService = storageService {
    _authProvider.addListener(_handleAuthChanged);
    _currentCompanyProvider.addListener(_handleAuthChanged);
    _handleAuthChanged();
  }

  final AuthProvider _authProvider;
  final CurrentCompanyProvider _currentCompanyProvider;
  final CompanyProfileService _service;
  final StorageService _storageService;

  StreamSubscription<CompanyProfile?>? _subscription;
  CompanyProfile? _profile;
  bool _loading = false;
  String? _error;

  CompanyProfile? get profile => _profile;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get hasProfile => _profile != null;
  bool get isComplete => _profile?.isComplete ?? false;
  bool get requiresCompanyProfile =>
      _authProvider.user?.requiresCompanyProfile ?? false;
  String get companyName =>
      _profile?.name.trim().isNotEmpty == true ? _profile!.name.trim() : 'StockMind';

  Future<void> saveProfile(
    CompanyProfile profile, {
    PickedImageFile? logoFile,
    bool removeLogo = false,
  }) async {
    final userId = _authProvider.user?.id;
    final companyId = _currentCompanyProvider.companyId;
    if (userId == null || companyId == null) {
      _error = 'Debes iniciar sesión para guardar datos de empresa.';
      notifyListeners();
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      String? logoUrl = removeLogo ? null : profile.logoUrl;
      if (removeLogo) {
        await _storageService.deleteImageByUrl(_profile?.logoUrl);
      }
      if (logoFile != null) {
        logoUrl = await _storageService.uploadCompanyLogo(
          uid: userId,
          file: logoFile,
        );
      }
      final nextProfile = profile.copyWith(
        id: 'company_profile',
        logoUrl: logoUrl,
        createdBy: profile.createdBy.isEmpty ? userId : profile.createdBy,
        isActive: true,
      );
      await _service.saveProfile(companyId, nextProfile);
      _profile = (_profile ?? const CompanyProfile.empty()).copyWith(
        id: nextProfile.id,
        name: nextProfile.name,
        industry: nextProfile.industry,
        phone: nextProfile.phone,
        email: nextProfile.email,
        address: nextProfile.address,
        website: nextProfile.website,
        logoUrl: nextProfile.logoUrl,
        createdBy: nextProfile.createdBy,
        isActive: nextProfile.isActive,
      );
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'CompanyProfileProvider.saveProfile FirebaseException: ${error.code} ${error.message}',
      );
      debugPrint('$stackTrace');
      _error = error.message?.trim().isNotEmpty == true
          ? error.message!.trim()
          : 'No fue posible guardar los datos de empresa.';
    } on StorageServiceException catch (error, stackTrace) {
      debugPrint('CompanyProfileProvider.saveProfile storage: ${error.message}');
      debugPrint('$stackTrace');
      _error = error.message;
    } catch (error, stackTrace) {
      debugPrint('CompanyProfileProvider.saveProfile error: $error');
      debugPrint('$stackTrace');
      _error = 'No fue posible guardar los datos de empresa.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _handleAuthChanged() {
    _subscription?.cancel();
    _profile = null;
    _error = null;
    if (!_authProvider.isAuthenticated) {
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    final userId = _authProvider.user?.id;
    final companyId = _currentCompanyProvider.companyId;
    if (userId == null || companyId == null) {
      _loading = false;
      notifyListeners();
      return;
    }
    _subscription = _service.watchProfile(companyId).listen(
      (profile) {
        _profile = profile;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('CompanyProfileProvider.watchProfile error: $error');
        debugPrint('$stackTrace');
        _loading = false;
        _error = 'No fue posible cargar el perfil de empresa.';
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChanged);
    _currentCompanyProvider.removeListener(_handleAuthChanged);
    _subscription?.cancel();
    super.dispose();
  }
}
