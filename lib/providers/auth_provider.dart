import 'dart:convert';
import 'package:cpims_mobile/constants_prod.dart';
import 'package:cpims_mobile/providers/db_provider.dart';
import 'package:cpims_mobile/screens/initial_loader.dart';
import 'package:cpims_mobile/screens/locked_screen.dart';
import 'package:cpims_mobile/services/caseload_service.dart';
import 'package:cpims_mobile/widgets/logout_dialog.dart';
import 'package:http/http.dart' as http;

import 'package:cpims_mobile/Models/user_model.dart';
import 'package:cpims_mobile/constants.dart' as consts;
import 'package:cpims_mobile/providers/http_response_handler.dart';
import 'package:cpims_mobile/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  static const String _lockAppPrefKey = '_lockAppPrefKey';
  static const String _authRefreshTokenTimeStampKey =
      'authRefreshTokenTimeStampKey';
  static const String authTokenTimeStampKey = 'authTokenTimestampKey';
  static const int _refreshTokenExpiryDurationMilli = 1000 * 3600 * 24 * 12;
  static const int authTokenMaxOfflineLoginTimeLimit = 1000 * 3600 * 24 * 30;

  UserModel _user = UserModel(
    username: '',
    accessToken: '',
    refreshToken: '',
  );

  UserModel? get user => _user;

  setAccessToken(String accessToken) {
    if (user != null) {
      _user = _user.copyWith(accessToken: accessToken);
    }
    notifyListeners();
  }

  void setUser(UserModel userModel) {
    _user = userModel;
    notifyListeners();
  }

  void clearUser() {
    _user = UserModel(
      username: '',
      accessToken: '',
      refreshToken: '',
    );

    notifyListeners();
  }

  static Future<void> setAppLock(bool lockApp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockAppPrefKey, lockApp);
  }

  static Future<bool> getAppLock() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lockAppPrefKey) ?? false;
  }

  Future<void> login({
    required BuildContext context,
    required String password,
    required String username,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final AuthProvider authProvider = AuthProvider();

    final http.Response response = await http.post(
      Uri.parse(
        '${cpimsProdApiUrl}api/token/',
      ),
      body: {
        'username': username,
        'password': password,
      },
    );

    if (response.statusCode >= 250 && response.statusCode <= 260) {
      if (context.mounted) {
        errorSnackBar(context, 'Not authorized to view this resource');
        await LocalDb.instance.deleteDb();
        AuthProvider.setAppLock(true);
        Get.off(() => const LockedScreen());
      }
      return;
    }

    if (context.mounted) {
      httpReponseHandler(
        response: response,
        context: context,
        onSuccess: () async {
          final responseData = json.decode(response.body);

          await prefs.setString('access', responseData['access']);
          await prefs.setString('refresh', responseData['refresh']);
          // await prefs.setBool("hasUserSetup", true);

          await prefs.setInt(
            authTokenTimeStampKey,
            DateTime.now().millisecondsSinceEpoch,
          );

          await prefs.setInt(
            _authRefreshTokenTimeStampKey,
            DateTime.now().millisecondsSinceEpoch,
          );

          authProvider.setAccessToken(responseData['access']);

          UserModel userModel = UserModel(
            username: username,
            accessToken: responseData['access'],
            refreshToken: responseData['refresh'],
          );
          if (context.mounted) {
            setUser(userModel);
          }

          prefs.setString('username', username);
          prefs.setString('password', password);

          Get.off(() => const InitialLoadingScreen(isFromAuth: true),
              transition: Transition.fadeIn,
              duration: const Duration(microseconds: 300));
        },
        onFailure: () {
          // clearUser();
        },
      );
    }
  }

  // logout
  Future<void> logOut(BuildContext context) async {
    showDialog(
        context: context,
        builder: (context) => LogOutDialog(
              onLogout: () async {
                SharedPreferences sharedPreferences =
                    await SharedPreferences.getInstance();

                await sharedPreferences.remove('access');
                await sharedPreferences.remove('refresh');

                clearUser();

                Get.off(
                  () => const LoginScreen(),
                  transition: Transition.fadeIn,
                  duration: const Duration(microseconds: 300),
                );
              },
              onDeleteDb: () async {
                CaseLoadService.saveCaseLoadLastSave(0);
                await LocalDb.instance.deleteDb();
              },
            ));
  }

  Future<bool> verifyToken({
    required BuildContext context,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? refreshToken = prefs.getString('refresh');
      int? authTokenTimestamp = prefs.getInt(authTokenTimeStampKey);
      int? authRefreshTokenTimestamp =
          prefs.getInt(_authRefreshTokenTimeStampKey);
      if (refreshToken != null &&
          authTokenTimestamp != null &&
          authRefreshTokenTimestamp != null) {
        int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
        int tokenExpiryDuration =
            1800 * 1000; // Token expires after 30 minutes (in milliseconds)
        if (currentTimestamp - authRefreshTokenTimestamp >
            _refreshTokenExpiryDurationMilli) {
          clearUser();
          return false;
        }

        if (currentTimestamp - authTokenTimestamp > tokenExpiryDuration) {
          // Token has expired -- refresh token
          // get new token
          final http.Response response = await http.post(
            Uri.parse(
              '${cpimsProdApiUrl}api/token/refresh/',
            ),
            body: {
              'refresh': refreshToken,
            },
          );
          if (context.mounted) {
            httpReponseHandler(
              response: response,
              context: context,
              onSuccess: () async {
                final responseData = json.decode(response.body);
                await prefs.remove('access');
                await prefs.setString('access', responseData['access']);

                if (context.mounted) {
                  setUser(UserModel(
                    username: user!.username,
                    accessToken: responseData['access'],
                    refreshToken: refreshToken,
                  ));
                }
              },
              onFailure: () async {
                await logOut(context);
              },
            );
          }
          return true;
        } else {
          setAccessToken(refreshToken);
          return true;
        }
      }
    } catch (e) {
      if (context.mounted) {
        errorSnackBar(context, e.toString());
      }

      return false;
    }
    return false;
  }
}
