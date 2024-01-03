import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voters/screens/signin_screen.dart';
import 'package:voters/utils/colors_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        dataTableTheme: DataTableThemeData(
          headingRowColor: MaterialStateColor.resolveWith((states) =>
              appColor), // Set the background color of the header row
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Builder(
        builder: (BuildContext context) {
          final Size screenSize = MediaQuery.of(context).size;
          deviceWidth = screenSize.width;
          deviceHeight = screenSize.height;

          return SignInScreen(
            username: '',
          );
        },
      ),
    );
  }
}
