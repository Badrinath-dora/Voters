import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const String apiMainUrl = 'https://letzadd.doctorsreferralnetwork.com/api';

//const String apiMainUrl = 'https://4db2-219-91-202-208.ngrok-free.app/api';

const Color appColor = Color(0xFF315985);
double deviceWidth = 1080;
double deviceHeight = 1920;

String convertDateFormat(String inputDate) {
  // Parse the input string as a DateTime object
  DateTime date = DateTime.parse(inputDate);

  // Format the DateTime object to the desired string format
  String formattedDate = DateFormat('dd-MM-yyyy').format(date);

  return formattedDate;
}

String convertDateFormat2(String inputDate) {
  // Parse the input date using the current format
  final date = DateFormat('d-M-yyyy').parseStrict(inputDate);

  // Format the date using the desired format
  final formattedDate = DateFormat('dd-MM-yyyy').format(date);

  return formattedDate;
}

String removeDecimal(String input) {
  return input.replaceAll(RegExp(r'\.\d+'), '');
}

Text boldText(String text, double size, Color color) {
  return Text(text,
      style:
          TextStyle(fontSize: size, fontWeight: FontWeight.bold, color: color));
}

void showMySnackBar(BuildContext context, String message, Color color) {
  final snackBar = SnackBar(
    content: Text(message),
    backgroundColor: color,
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

ButtonStyle buttonStyle = ElevatedButton.styleFrom(
  primary: appColor,
  onPrimary: Colors.white,
  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 60),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(30),
  ),
);

InputDecoration ifDecoration(String labelText) {
  return InputDecoration(
    labelText: labelText,
    labelStyle: TextStyle(color: appColor),
    alignLabelWithHint: false,
    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: appColor, width: 2.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: appColor, width: 2.0),
    ),
  );
}

hexStringToColor(String hexColor) {
  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF" + hexColor;
  }
  return Color(int.parse(hexColor, radix: 16));
}
