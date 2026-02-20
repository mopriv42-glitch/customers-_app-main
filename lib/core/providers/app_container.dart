import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:private_4t_app/app_config/api_providers.dart';
import 'package:private_4t_app/core/providers/matrix_chat_provider.dart';

@pragma("vm:entry-point")
final providerAppContainer = ProviderContainer();

/// Helper function to dispose the container when needed (e.g., app shutdown)
@pragma("vm:entry-point")
void disposeAppContainer() {
  providerAppContainer.dispose();
}

@pragma("vm:entry-point")
const platform = MethodChannel('app_channel');

@pragma("vm:entry-point")
Future<MatrixChatProvider> getMatrix() async {
  var loginProvider = providerAppContainer.read(ApiProviders.loginProvider);
  var matrix = providerAppContainer.read(ApiProviders.matrixChatProvider);
  var loggedUser = loginProvider.loggedUser;
  await matrix.init();

  if (!matrix.isInitialized) {
    if (!matrix.isLoggedIn) {
      if (loginProvider.loggedUser == null) {
        await loginProvider.getLoggedUser();
      }
      loggedUser = loginProvider.loggedUser;
    }
    // Auto-provision user if they're logged into the app but not Matrix
    if (!matrix.isLoggedIn && loggedUser != null) {
      try {
        // Check if user can be auto-provisioned
        if (matrix.canAutoProvision(loggedUser)) {
          try {
            // Perform auto-provisioning
            var result = await matrix.autoProvisionUser(appUser: loggedUser);

            if (result.success) {
              debugPrint('Auto-provisioning successful: ${result.message}');
            } else {
              debugPrint('Auto-provisioning failed: ${result.message}');
            }
          } catch (e, s) {
            debugPrintStack(
              label: 'Error during auto-provisioning: ${e.toString()}',
              stackTrace: s,
            );
          }
        } else {
          debugPrint('User cannot be auto-provisioned (missing phone number)');
        }
      } catch (e, s) {
        debugPrintStack(
          stackTrace: s,
          label: 'Error during auto-provisioning: ${e.toString()}',
        );
      }
    }
  }
  await matrix.init();
  return matrix;
}
