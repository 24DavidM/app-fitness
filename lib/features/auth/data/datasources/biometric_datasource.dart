import 'package:local_auth/local_auth.dart';
import '../../domain/entities/auth_result.dart';


abstract class BiometricDataSource {
  Future<bool> canAuthenticate();
  Future<AuthResult> authenticate({String reason});
}

class BiometricDataSourceImpl implements BiometricDataSource {
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  Future<bool> canAuthenticate() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return (canCheck == true) && (isSupported == true);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<AuthResult> authenticate({String reason = 'Autentíquese'}) async {
    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return AuthResult(
        success: didAuthenticate,
        message:
            didAuthenticate ? 'Autenticación exitosa' : 'Autenticación fallida',
      );
    } catch (e) {
      return AuthResult(success: false, message: 'Error: ${e.toString()}');
    }
  }
}
