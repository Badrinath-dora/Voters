import 'package:flutter/material.dart';
import 'package:voters/screens/signup_screen.dart';

import '../utils/colors_utils.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key, required String username}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _passwordTextController = TextEditingController();
  final TextEditingController _emailTextController = TextEditingController();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _scrollController.addListener(_scrollToVisibleContent);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollToVisibleContent);
    super.dispose();
  }

  void _scrollToVisibleContent() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (MediaQuery.of(context).viewInsets.bottom > 0) {
          // Scroll to the bottom of the form
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent - 150,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          // Scroll to the top of the form
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: <Widget>[
            Container(
              width: deviceWidth,
              height: deviceHeight,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    appColor, // Start color
                    Color.fromARGB(255, 255, 255, 255), // End color
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.5, 0.5],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  deviceHeight * 0.2,
                  20,
                  0,
                ),
                child: Column(
                  children: <Widget>[
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 100,
                      child: Image.asset(
                        "assets/man.png",
                        width: 170,
                        height: 170,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const Text(
                      'Company Name',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: deviceHeight * 0.03),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: boldText("Admin", 16, appColor),
                            ),
                            Container(
                              width: deviceWidth * 0.8,
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              child: TextFormField(
                                controller: _emailTextController,
                                style: const TextStyle(color: appColor),
                                decoration: ifDecoration("Enter username"),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a username';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            Container(
                              width: deviceWidth * 0.8,
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              child: TextFormField(
                                controller: _passwordTextController,
                                style: const TextStyle(color: appColor),
                                obscureText: true,
                                decoration: ifDecoration("Enter password"),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a password';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(
                              height: 15,
                            ),
                            ElevatedButton(
                              onPressed: _performSignIn,
                              style: buttonStyle,
                              child: const Text('LogIn'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
    );
  }

  void _performSignIn() {
    if (_formKey.currentState!.validate()) {
      // Validate the form
      String username = _emailTextController.text;
      String password = _passwordTextController.text;

      if (username == 'admin' && password == 'admin') {
        // Username and password match admin credentials
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SignUpScreen(username: username),
          ),
        );
      } else {
        // Incorrect credentials
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Incorrect Credentials'),
              content:
                  const Text('Please enter the correct username and password.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }
}
