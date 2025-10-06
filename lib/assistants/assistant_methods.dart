
import 'package:geolocator/geolocator.dart';
import 'package:pakyaw/assistants/request_assistant.dart';
import 'package:pakyaw/shared/global_var.dart';

class AssistantMethods{

  static Future<String> searchCoordinates(Position position) async {
    String placedAddress = '';
    String url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$googleMapKey";

    var response = await RequestAssistant.getRequest(url);

    if(response != 'Failed'){
      placedAddress = response["results"][0]["formatted_address"];
    }

    return placedAddress;

  }

}