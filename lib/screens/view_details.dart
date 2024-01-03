import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:voters/screens/signup_screen.dart';
import 'package:voters/utils/colors_utils.dart';

void main() {
  runApp(TableApp());
}

class TableApp extends StatefulWidget {
  @override
  _TableAppState createState() => _TableAppState();
}

class _TableAppState extends State<TableApp> {
  DateTime? selectedDataTime = null;

  List<String> selectedFilterColumns = [];

  Map<String, bool> checkboxData = {
    "all": true,
    "date_of_birth": false,
    "constituency": true,
    "phone_no": true,
    "hamlet": true,
    "polling_id": true,
    "voter_id": true,
    "village": true,
    "mandal": true,
    "name": true,
    "party": true,
    "booth_number": true,
    "voter_serial_number": true,
    "district": true,
    "relation_name": true,
  };
  bool _isLoding = false;

  List<Map<String, dynamic>> filteredData = [];
  List<Map<String, dynamic>> finalPageData = [];

  int currentPage = 1;
  final int rowsPerPage = 1000;
  final TextEditingController searchController = TextEditingController();
  Map<String, dynamic> selectedUser = {};
  //String selectedField = 'All Fields';

  Future<List<dynamic>> getFilteredDataFromAPI(String searchText) async {
    print("sending....");
    const apiUrl = '$apiMainUrl/voters/search'; // Replace with your API URL

    var data = {
      "columnNames": selectedFilterColumns,
      "searchString": searchText
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        showMySnackBar(context, "Search done", Colors.green);
        return responseData;
      } else {
        showMySnackBar(context, "No Voter found", Colors.orange);

        return [];
      }
    } catch (e) {
      print('Error: $e');
      showMySnackBar(context, "Search Failed", Colors.red);

      return []; // Return 500 in case of an error
    }
  }

  Future<void> savePartyFromAPI(int id, String party) async {
    print("sending....$id , $party");
    setState(() {
      _isLoding = true;
    });
    const apiUrl = '$apiMainUrl/voters/saveparty'; // Replace with your API URL

    var data = {"id": id, "party": party};
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 200) {
        print("party saved");
        setState(() {
          finalPageData = getPageData();
          _isLoding = false;
        });
        showMySnackBar(context, "Party updated", Colors.green);
      } else {
        showMySnackBar(context, "Unable to save party", Colors.red);
      }
    } catch (e) {
      print('Error: $e');
      showMySnackBar(context, "Server unavailable", Colors.red);
    }
  }

  Future<void> _selectYear(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState2) {
          return AlertDialog(
            title: Text("Select Year"),
            content: Container(
              width: 300,
              height: 300,
              child: YearPicker(
                firstDate: DateTime(DateTime.now().year - 150, 1),
                lastDate: DateTime(DateTime.now().year + 0, 1),
                initialDate: DateTime.now(),
                selectedDate: selectedDataTime == null
                    ? DateTime.now()
                    : selectedDataTime!,
                onChanged: (DateTime dateTime) {
                  setState2(() {
                    selectedDataTime = dateTime;
                  });
                },
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  setState2(() {
                    selectedDataTime = null;
                    checkboxData['date_of_birth'] = false;
                  });

                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    searchController.text = selectedDataTime!.year.toString();
                    checkboxData['date_of_birth'] = true;
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Confirm'),
              )
            ],
          );
        });
      },
    );
  }

  void showUserDetails(BuildContext context, Map<String, dynamic> user) {
    user.remove("timestamp");
    List<Widget> userDetailWidgets = user.entries.map((entry) {
      return Row(
        children: [
          boldText('${entry.key}: ', 16, appColor),
          Text('${entry.value}'),
        ],
      );
    }).toList();

    Map<String, dynamic> updatedUser = Map<String, dynamic>.from(user);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState1) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            title: const Text('Voter Details'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ...userDetailWidgets,
                const SizedBox(height: 16),
                boldText('Party:', 18, appColor),
                DropdownButtonFormField<String>(
                  value: user['party'] != null &&
                          _party.any((item) => item.value == user['party'])
                      ? user['party']
                      : null,
                  items: _party,
                  onChanged: (value) {
                    updatedUser['party'] = value;
                  },
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  try {
                    final index = filteredData.indexOf(user);
                    if (index != -1) {
                      setState1(() {
                        filteredData[index] = updatedUser;
                        filteredData =
                            List<Map<String, dynamic>>.from(filteredData);
                        if (selectedUser == user) {
                          selectedUser = updatedUser;
                        }
                      });
                    }

                    if (updatedUser['party'] == null) {
                      Navigator.of(context).pop();
                    } else {
                      savePartyFromAPI(updatedUser['id'], updatedUser['party']);
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  void initState() {
    super.initState();

    //with no data
    filteredData = [];
  }

  Future<void> fetchDataFromAPI() async {
    checkboxData.forEach((key, value) {
      if (key != 'all') {
        if (value == true) {
          selectedFilterColumns.add(key);
        }
      }
    });
    if (selectedFilterColumns.isNotEmpty) {
      if (searchController.text.isNotEmpty) {
        Future<List<dynamic>> filteredDataFromAPI_;

        try {
          setState(() {
            _isLoding = true;
          });
          filteredData = [];
          finalPageData = [];
          filteredDataFromAPI_ =
              Future.value(getFilteredDataFromAPI(searchController.text));
          filteredDataFromAPI_.then((data) {
            List<Map<String, dynamic>> x = [];

            for (var item in data) {
              x.add(item);
            }

            print(x.length);
            setState(() {
              filteredData = x;
              finalPageData = getPageData();
              //searchController.text = "";
              selectedFilterColumns = [];
              _isLoding = false;
            });
          });
        } catch (error) {
          setState(() {
            filteredDataFromAPI_ = Future.value([]);
            filteredData = [];
            finalPageData = [];
            _isLoding = false;
          });
          showMySnackBar(
              context, "No data found with this filtters", Colors.red);
        }
      } else {
        showMySnackBar(context, "Please enter data to search", Colors.red);
      }
    } else {
      showMySnackBar(context, "Please select atleast one filter", Colors.red);
    }
  }

  List<Map<String, dynamic>> getPageData() {
    if (filteredData.isNotEmpty) {
      final int startIndex = (currentPage - 1) * rowsPerPage;
      final int endIndex = startIndex + rowsPerPage > filteredData.length
          ? filteredData.length
          : startIndex + rowsPerPage;
      return filteredData.sublist(startIndex, endIndex);
    } else {
      return [];
    }
  }

  void goToPreviousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
    }
  }

  void goToNextPage() {
    final int totalPages = (filteredData.length / rowsPerPage).ceil();
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
      });
    }
  }

  final List<DropdownMenuItem<String>> _party = [
    const DropdownMenuItem<String>(
      value: 'YSRCP',
      child: Text('YSRCP'),
    ),
    const DropdownMenuItem<String>(
      value: 'TDP',
      child: Text('TDP'),
    ),
    const DropdownMenuItem<String>(
      value: 'JANASENA',
      child: Text('JANASENA'),
    ),
    const DropdownMenuItem<String>(
      value: 'CONGRESS',
      child: Text('CONGRESS'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: _isLoding,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: appColor,
          title: boldText("Voters Data", 22, Colors.white),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SignUpScreen(
                          username: '',
                        )),
              );
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: TextField(
                  style: const TextStyle(color: appColor),
                  controller: searchController,
                  onChanged: (value) {},
                  decoration: InputDecoration(
                    labelText: 'Search',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.search,
                        color: appColor,
                      ),
                      onPressed: () {},
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(8.0), // Specify the desired padding
                child: Text(
                  'Filters',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          value: checkboxData['all'],
                          onChanged: (value) {
                            setState(() {
                              checkboxData['all'] = value!;
                              if (value == true) {
                                checkboxData['date_of_birth'] = value;
                              } else {
                                selectedDataTime = null;
                                checkboxData['date_of_birth'] = value;
                              }

                              checkboxData["constituency"] = value;
                              checkboxData["phone_no"] = value;
                              checkboxData["hamlet"] = value;
                              checkboxData["polling_id"] = value;
                              checkboxData["voter_id"] = value;
                              checkboxData["village"] = value;
                              checkboxData["mandal"] = value;
                              checkboxData["name"] = value;
                              checkboxData["party"] = value;
                              checkboxData["booth_number"] = value;
                              checkboxData["voter_serial_number"] = value;
                              checkboxData["district"] = value;
                              checkboxData["relation_name"] = value;
                            });
                          },
                          activeColor: appColor,
                        ),
                        Text("All")
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          activeColor: appColor,
                          value: selectedDataTime == null ? false : true,
                          onChanged: (value) {
                            setState(() {
                              checkboxData['date_of_birth'] = value!;

                              if (value) {
                                _selectYear(context);
                              } else {
                                selectedDataTime = null;
                              }
                            });
                          },
                        ),
                        Text("DOB ")
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          activeColor: appColor,
                          value: checkboxData['constituency'],
                          onChanged: (value) {
                            setState(() {
                              checkboxData['constituency'] = value!;
                            });
                          },
                        ),
                        Text("Constituency")
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          activeColor: appColor,
                          value: checkboxData['phone_no'],
                          onChanged: (value) {
                            setState(() {
                              checkboxData['phone_no'] = value!;
                            });
                          },
                        ),
                        const Text("Phno")
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          activeColor: appColor,
                          value: checkboxData['hamlet'],
                          onChanged: (value) {
                            setState(() {
                              checkboxData['hamlet'] = value!;
                            });
                          },
                        ),
                        Text("Hamlet")
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          activeColor: appColor,
                          value: checkboxData['polling_id'],
                          onChanged: (value) {
                            setState(() {
                              checkboxData['polling_id'] = value!;
                            });
                          },
                        ),
                        Text("Polling id")
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          activeColor: appColor,
                          value: checkboxData['voter_id'],
                          onChanged: (value) {
                            setState(() {
                              checkboxData['voter_id'] = value!;
                            });
                          },
                        ),
                        Text("Voter id")
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          activeColor: appColor,
                          value: checkboxData['village'],
                          onChanged: (value) {
                            setState(() {
                              checkboxData['village'] = value!;
                            });
                          },
                        ),
                        Text("Village")
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          activeColor: appColor,
                          value: checkboxData['mandal'],
                          onChanged: (value) {
                            setState(() {
                              checkboxData['mandal'] = value!;
                            });
                          },
                        ),
                        Text("Mandal")
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          activeColor: appColor,
                          value: checkboxData['name'],
                          onChanged: (value) {
                            setState(() {
                              checkboxData['name'] = value!;
                            });
                          },
                        ),
                        Text("Name")
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          activeColor: appColor,
                          value: checkboxData['party'],
                          onChanged: (value) {
                            setState(() {
                              checkboxData['party'] = value!;
                            });
                          },
                        ),
                        Text("Party")
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          activeColor: appColor,
                          value: checkboxData['booth_number'],
                          onChanged: (value) {
                            setState(() {
                              checkboxData['booth_number'] = value!;
                            });
                          },
                        ),
                        Text("Booth no")
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          activeColor: appColor,
                          value: checkboxData['voter_serial_number'],
                          onChanged: (value) {
                            setState(() {
                              checkboxData['voter_serial_number'] = value!;
                            });
                          },
                        ),
                        Text("Voter sno")
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          activeColor: appColor,
                          value: checkboxData['district'],
                          onChanged: (value) {
                            setState(() {
                              checkboxData['district'] = value!;
                            });
                          },
                        ),
                        Text("District")
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          activeColor: appColor,
                          value: checkboxData['relation_name'],
                          onChanged: (value) {
                            setState(() {
                              checkboxData['relation_name'] = value!;
                            });
                          },
                        ),
                        Text("Relation")
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(
                thickness: 2,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        filteredData = [];
                        finalPageData = [];
                        selectedFilterColumns = [];

                        checkboxData['all'] = false;

                        selectedDataTime = null;
                        searchController.text = "";
                        checkboxData['date_of_birth'] = false;

                        checkboxData["constituency"] = false;
                        checkboxData["phone_no"] = false;
                        checkboxData["hamlet"] = false;
                        checkboxData["polling_id"] = false;
                        checkboxData["voter_id"] = false;
                        checkboxData["village"] = false;
                        checkboxData["mandal"] = false;
                        checkboxData["name"] = false;
                        checkboxData["party"] = false;
                        checkboxData["booth_number"] = false;
                        checkboxData["voter_serial_number"] = false;
                        checkboxData["district"] = false;
                        checkboxData["relation_name"] = false;
                      });
                    },
                    style: buttonStyle,
                    child: const Text('Clear'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      fetchDataFromAPI();
                    },
                    style: buttonStyle,
                    child: const Text('Apply'),
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      dividerThickness:
                          2, // Adjust the thickness of the row borders

                      columns: const [
                        DataColumn(
                          label: Text(
                            'DB ID',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Name',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Party',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Booth no',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Polling ID',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Hamlet',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Village',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Mandal',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Constituency',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'District',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Voter sno',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Voter ID',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Relation',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Gender',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'DOB',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Phone no',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                      rows: finalPageData.map((rowData) {
                        return DataRow(
                          color: MaterialStateColor.resolveWith((states) => Colors
                              .grey
                              .shade100), // Set the background color of the row

                          cells: [
                            DataCell(
                              Text(rowData['id'].toString()),
                              onTap: () => showUserDetails(context, rowData),
                            ),
                            DataCell(
                              Text(rowData['name'].toString()),
                              onTap: () => showUserDetails(context, rowData),
                            ),
                            DataCell(
                              Text(rowData['party'].toString()),
                              onTap: () => showUserDetails(context, rowData),
                            ),
                            DataCell(
                              Text(rowData['booth_number'].toString()),
                              onTap: () => showUserDetails(context, rowData),
                            ),
                            DataCell(
                              Text(rowData['polling_id'].toString()),
                              onTap: () => showUserDetails(context, rowData),
                            ),
                            DataCell(
                              Text(rowData['hamlet'].toString()),
                              onTap: () => showUserDetails(context, rowData),
                            ),
                            DataCell(
                              Text(rowData['village'].toString()),
                              onTap: () => showUserDetails(context, rowData),
                            ),
                            DataCell(
                              Text(rowData['mandal'].toString()),
                              onTap: () => showUserDetails(context, rowData),
                            ),
                            DataCell(
                              Text(rowData['constituency'].toString()),
                              onTap: () => showUserDetails(context, rowData),
                            ),
                            DataCell(
                              Text(rowData['district'].toString()),
                              onTap: () => showUserDetails(context, rowData),
                            ),
                            DataCell(
                              Text(rowData['voter_serial_number'].toString()),
                              onTap: () => showUserDetails(context, rowData),
                            ),
                            DataCell(
                              Text(rowData['voter_id'].toString()),
                              onTap: () => showUserDetails(context, rowData),
                            ),
                            DataCell(
                              Text(rowData['relation_name'].toString()),
                              onTap: () => showUserDetails(context, rowData),
                            ),
                            DataCell(
                              Text(rowData['gender'].toString()),
                              onTap: () => showUserDetails(context, rowData),
                            ),
                            DataCell(
                              Text(rowData['date_of_birth'].toString()),
                              onTap: () => showUserDetails(context, rowData),
                            ),
                            DataCell(
                              Text(rowData['phone_no'].toString()),
                              onTap: () => showUserDetails(context, rowData),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              /*Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: goToPreviousPage,
                    disabledColor: Colors.grey,
                  ),
                  Text('Page $currentPage'),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: goToNextPage,
                    disabledColor: Colors.grey,
                  ),
                ],
              ),*/
            ],
          ),
        ),
      ),
    );
  }
}
