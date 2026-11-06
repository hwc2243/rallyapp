
import 'package:flutter/foundation.dart';

/// Holds the tenant selected by the application at runtime.
///
/// Generated entity providers listen to this object and notify their
/// consumers when the active tenant changes.
class TenantDiscriminatorProvider extends ChangeNotifier {
  int? _organizationId;

  int? get organizationId => _organizationId;

  void setOrganizationId(int? value) {
    if (_organizationId == value) {
      return;
    }
    _organizationId = value;
    notifyListeners();
  }

  void clear() => setOrganizationId(null);
}
