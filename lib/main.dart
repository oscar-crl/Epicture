import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:uri/uri.dart';
import 'package:http/http.dart' as http;
import 'AccountImages.dart';
import 'GalleryImages.dart';
import 'SearchGalleryImages.dart';

var urlParams = <String, String>{};

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final url = Uri.https('api.imgur.com', '/oauth2/authorize', {
    'client_id': 'YOUR_CLIENT_ID',
    'response_type': 'token',
  });

  @override
  Widget build(BuildContext context) {
    var title = 'Epicture';
    return new MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Define the default brightness and colors.
        brightness: Brightness.dark,
        primaryColor: Colors.green[500],
        accentColor: Colors.green[600],
        canvasColor: Color.fromRGBO(33, 33, 36, 1),
        appBarTheme: AppBarTheme(color: Color.fromRGBO(33, 33, 36, 1)),
      ),
      routes: {
        '/webview': (_) => new WebviewScaffold(
              url: url.toString(),
              appBar: new AppBar(
                title: const Text('Authentication with Imgur'),
                automaticallyImplyLeading: false,
              ),
              withZoom: false,
              withLocalStorage: true,
            ),
        '/home': (_) => new GalleryImages(),
        '/search': (_) => new SearchGalleryImages(),
        '/account': (_) => new AccountImages(),
      },
      home: new MyAppHomePage(),
    );
  }
}

class MyAppHomePage extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyAppHomePage> {
  final flutterWebviewPlugin = new FlutterWebviewPlugin();
  StreamSubscription<String> _onUrlChanged;
  String urlChanged;

  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => imgurLogin(context));
  }

  void imgurLogin(BuildContext context) {
    Navigator.of(context).pushNamed('/webview');
    _onUrlChanged = flutterWebviewPlugin.onUrlChanged.listen((urlChanged) {
      if (urlChanged
          .startsWith('https://app.getpostman.com/oauth2/callback#')) {
        flutterWebviewPlugin.hide();
        Navigator.pop(context);
        Navigator.pushReplacementNamed(context, '/home');
        setState(() {
          var uri = Uri.parse(urlChanged.replaceFirst('#', '?'));
          uri.queryParameters.forEach((key, value) {
            urlParams[key] = value;
          });
          print(urlParams);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold();
  }
}
