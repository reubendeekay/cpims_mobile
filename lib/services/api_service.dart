import 'dart:convert';

import 'package:cpims_mobile/constants.dart';
import 'package:cpims_mobile/constants_prod.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String _url = cpimsProdApiUrl;

  get getAccess => null;

  //without authentication....
  postData(data, apiUrl) async {
    var fullUrl = _url + apiUrl;
    // + await _getToken();
    return await http.post(Uri.parse(fullUrl),
        body: jsonEncode(data), headers: _setHeaders());
  }

  postSecData(data, apiUrl) async {
    var fullUrl = _url + apiUrl;
    final getToken = await _getToken();
    return await http.post(Uri.parse(fullUrl),
        body: jsonEncode(data), headers: _setAuthHeaders(getToken));
  }

  getData(apiUrl) async {
    var fullUrl = _url + apiUrl + await _getToken();

    return await http.get(Uri.parse(fullUrl), headers: _setHeaders());
  }

  getSecureData(apiUrl, access) async {
    var fullUrl = _url + apiUrl;
    return await http.get(Uri.parse(fullUrl), headers: _setAuthHeaders(access));
  }

  getUnapprovedData(apiUrl, access) async {
    var fullUrl = _url + apiUrl;
    return await http.get(Uri.parse(fullUrl), headers: _setAuthHeaders(access));
  }

  _setHeaders() => {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      };

  _setAuthHeaders(token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      };

  _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('access');
    print(token);
    return token;
  }

  refreshToken() async {
    try {
      String apiUrl = "auth/refresh";
      SharedPreferences pref = await SharedPreferences.getInstance();
      var access = pref.getString('access');
      var refresh = pref.getString('refresh');
      String url = _url + apiUrl;

      http.Response response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $refresh',
      });
      var res = json.decode(response.body);

      pref.setString("access", res['access'].toString());
      pref.setString("refresh", res['refresh'].toString());

      debugPrint(access);
      debugPrint(refresh);

      debugPrint(access);
      debugPrint(response.body);
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }
}

final apiServiceConstructor = ApiService();
