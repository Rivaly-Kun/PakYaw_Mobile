import 'dart:convert';

import 'package:http/http.dart' as http;

class RequestAssistant{
  static Future<dynamic> getRequest(String url) async {
    var response = await http.get(Uri.parse(url));

    try{
      if(response.statusCode == 200){
        String data = response.body;
        var decodeData = jsonDecode(data);
        return decodeData;
      }else{
        return "Failed";
      }
    }catch(e){
      return "Failed";
    }
  }

  static Future<dynamic> postRequest(String url, Map<String, String> headers, Map<String, dynamic> body) async {
    try{
      var response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      if(response.statusCode == 200){
        String data = response.body;
        var decodeData = jsonDecode(data);
        return decodeData;
      }else{
        return "Failed: ${response.statusCode}";
      }
    } catch (e){
      return "Failed";
    }
  }
}