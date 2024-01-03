import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_excel/excel.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:voters/screens/signin_screen.dart';
import 'package:voters/screens/view_details.dart';

import '../utils/colors_utils.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key, required String username}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isUploading = false;
  Future<List<Map<String, dynamic>>> readExcelToJSON(String filePath) async {
    final dateFormat = DateFormat('dd MMMM yyyy');
    final excel = Excel.decodeBytes(await File(filePath).readAsBytes());

    final table = excel.tables[excel.tables.keys.first];
    final jsonData = <Map<String, dynamic>>[];

    for (var row in table!.rows) {
      final jsonRow = <String, dynamic>{};

      for (var i = 0; i < table.maxCols; i++) {
        final cell = row[i];
        final cellValue = cell != null ? cell.value : 'none';
        final headerValue = table.rows.first[i]?.value;

        if (headerValue != null) {
          final key = headerValue.toString();
          var value = cellValue.toString();

          double? parsedValue = double.tryParse(value);
          if (parsedValue != null) {
            value = removeDecimal(value);
          } else {
            value = value;
          }

          if (key == 'date_of_birth') {
            print(value);
            if (value.contains('T')) {
              var L = value.split("T");
              value = L[0];
              value = convertDateFormat(value);
            } else {
              value = value;
            }
          }

          jsonRow[key] = value;
        }
      }
      //jsonRow.remove('sno');
      jsonData.add(jsonRow);
    }

    jsonData.removeAt(0);

    return jsonData;
  }

  Future<void> _pickAndReadExcelFile() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    late PermissionStatus permissionStatus;
    if (androidInfo.version.sdkInt >= 33) {
      permissionStatus = await Permission.videos.request();
    } else {
      permissionStatus = await Permission.storage.request();
    }

    if (permissionStatus.isGranted) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _isUploading = true;
        });
        PlatformFile file = result.files.first;

        List<List<dynamic>> excelData = [];

        final jsonList = await readExcelToJSON(file.path.toString());

        final responseCode = await sendJsonDataToAPI(jsonList);
        print('API response status code: $responseCode');
        setState(() {
          _isUploading = false;
        });
        if (responseCode == 200) {
          showMySnackBar(context, "Data uploaded successfully", Colors.green);
        } else {
          showMySnackBar(context, "Server Unavailable", Colors.red);
        }
      }
    } else if (permissionStatus.isPermanentlyDenied ||
        permissionStatus.isDenied) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Permission Required'),
            content: Text(
                'The app needs storage permission to pick and read Excel files. Please manually grant the permission through the device settings.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: Text('Open Settings'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<int> sendJsonDataToAPI(List<Map<String, dynamic>> jsonData) async {
    print("sending....");
    const apiUrl = '$apiMainUrl/voters/add'; // Replace with your API URL

    var data = {"voters": jsonData};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      return response.statusCode;
    } catch (e) {
      print('Error sending JSON data to API: $e');
      showMySnackBar(context, "$e", Colors.black);

      return 500; // Return 500 in case of an error
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: _isUploading,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Confirmation'),
                      content: const Text('Are you sure you want to exit?'),
                      actions: [
                        TextButton(
                          child: const Text('No'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text('Yes'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SignInScreen(username: ''),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
          title: const Text(
            'Dashboard',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                appColor, Color.fromARGB(255, 255, 255, 255), // End color
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.33, 0.33],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: deviceHeight * 0.16,
                left: 30,
                right: 30,
                child: Align(
                  alignment: Alignment.center,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Image.asset(
                              'assets/man.png',
                              width: 100,
                            ),
                            radius: 60,
                          ),
                          SizedBox(width: 28),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Company Name',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'Company Tagline',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 30),
                      Padding(
                        padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height * 0.07),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: _buildCircularButton(
                                      icon: Icons.person,
                                      label: 'View Details',
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => TableApp()),
                                        );
                                      },
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFdd576f), // Start color
                                          Color.fromARGB(
                                              255, 158, 43, 74), // End color
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        stops: [0.3, 0.8],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildCircularButton(
                                      icon: Icons.poll,
                                      label: 'Survey',
                                      onTap: () {
                                        // Handle button click
                                      },
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFa8a69a), // Start color
                                          Color.fromARGB(
                                              255, 109, 100, 100), // End color
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        stops: [0.3, 0.8],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: _buildCircularButton(
                                      icon: Icons.flag,
                                      label: 'Party Control',
                                      onTap: () {
                                        // Handle button click
                                      },
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF6d52f0), // Start color
                                          Color.fromARGB(
                                              255, 127, 99, 209), // End color
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        stops: [0.3, 0.8],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildCircularButton(
                                      icon: Icons.account_balance,
                                      label: 'Admin',
                                      onTap: () {
                                        // Handle button click
                                      },
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFf1aa1a), // Start color
                                          Color.fromARGB(
                                              255, 241, 164, 91), // End color
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        stops: [0.33, 0.8],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: _buildCircularButton(
                                      icon: Icons.person_2_outlined,
                                      label: 'Poll Control',
                                      onTap: () {
                                        // Handle button click
                                      },
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF25b8e5), // Start color
                                          Color.fromARGB(
                                              255, 54, 152, 185), // End color
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        stops: [0.3, 0.8],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildCircularButton(
                                      icon: Icons.file_upload,
                                      label: 'File Upload',
                                      onTap: _pickAndReadExcelFile,
                                      gradient: LinearGradient(
                                        colors: [
                                          Color.fromARGB(
                                              255, 22, 143, 111), // Start color
                                          Color.fromARGB(
                                              255, 98, 235, 164), // End color
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        stops: [0.3, 0.8],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required LinearGradient gradient,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Container(
              width: 150,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
                gradient: gradient,
              ),
              child: Icon(
                icon,
                size: 32,
                color: const Color.fromARGB(255, 255, 255, 255),
              ),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
