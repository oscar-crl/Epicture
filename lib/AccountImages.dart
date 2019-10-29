import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:image_picker/image_picker.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:intl/intl.dart';
import 'package:uri/uri.dart';
import 'package:http/http.dart' as http;
import 'main.dart' as global;

class AccountImages extends StatefulWidget {
  @override
  _AccountImages createState() => _AccountImages();
}

class _AccountImages extends State<AccountImages> {
  var accAvatar;
  var accImages;
  var accFavs;
  File _image;

  final inputDesc = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    inputDesc.dispose();
    super.dispose();
  }

  Future getImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);

    if (image != null)
      setState(() {
        _image = image;
        showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
                  title: Text('Upload to Imgur'),
                  titlePadding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0))),
                  contentPadding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                  backgroundColor: Theme.of(context).canvasColor,
                  content: Image.file(_image),
                  actions: <Widget>[
                    Container(
                        child: new TextField(
                          style: new TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                          controller: inputDesc,
                          decoration: new InputDecoration(
                              hintText: "Description...",
                              hintStyle: new TextStyle(
                                  color: Colors.white70, fontSize: 18)),
                          textInputAction: TextInputAction.done,
                        ),
                        width: 235),
                    FlatButton(
                      onPressed: () {
                        uploadImage(_image, inputDesc.text);
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Post',
                        style: TextStyle(color: Colors.white),
                      ),
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ));
      });
  }

  _AccountImages() {
    http.get(
      'https://api.imgur.com/3/account/${global.urlParams['account_username']}/avatar',
      headers: {
        HttpHeaders.authorizationHeader:
            "Bearer " + global.urlParams['access_token']
      },
    ).then((response) {
      setState(() {
        accAvatar = json.decode(response.body)["data"]["avatar"];
      });
    });
    getAccountImages();
    getAccountFavs();
  }

  getAccountImages() {
    http.get(
      'https://api.imgur.com/3/account/me/images',
      headers: {
        HttpHeaders.authorizationHeader:
            "Bearer " + global.urlParams['access_token']
      },
    ).then((response) {
      setState(() {
        accImages = json.decode(response.body)['data'];
      });
    });
  }

  getAccountFavs() {
    http.get(
      'https://api.imgur.com/3/account/${global.urlParams['account_username']}/favorites/0/',
      headers: {
        HttpHeaders.authorizationHeader:
            "Bearer " + global.urlParams['access_token']
      },
    ).then((response) {
      setState(() {
        accFavs = json.decode(response.body)['data'];
      });
    });
  }

  unfavoriteImage(String hash) {
    http.post(
      'https://api.imgur.com/3/image/$hash/favorite',
      headers: {
        HttpHeaders.authorizationHeader:
            "Bearer " + global.urlParams['access_token']
      },
    ).then((response) {
      setState(() {
        getAccountFavs();
      });
    });
  }

  uploadImage(File image, String description) {
    List<int> imageBytes = image.readAsBytesSync();
    String base64Image = base64Encode(imageBytes);
    http.post('https://api.imgur.com/3/upload', headers: {
      HttpHeaders.authorizationHeader:
          "Bearer " + global.urlParams['access_token']
    }, body: {
      'image': base64Image,
      'type': 'base64',
      'description': description
    }).then((response) {
      setState(() {
        getAccountImages();
      });
    });
  }

  Container favGrid(int index) {
    return Container(
        padding: EdgeInsets.all(2),
        child: GestureDetector(
          child: FadeInImage.memoryNetwork(
            placeholder: kTransparentImage,
            image: accFavs[index]['link']
                .toString()
                .replaceFirst('.png', 'm.png')
                .replaceFirst('.jpeg', 'm.jpeg')
                .replaceFirst('.jpg', 'm.jpg'),
            fadeInDuration: new Duration(milliseconds: 200),
            fadeInCurve: Curves.linear,
            fit: BoxFit.cover,
          ),
          onTap: () {
            showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                      title: Text(accFavs[index]['title'].toString()),
                      titlePadding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(10.0))),
                      contentPadding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                      backgroundColor: Theme.of(context).canvasColor,
                      content: FadeInImage.memoryNetwork(
                        placeholder: kTransparentImage,
                        image: accFavs[index]['link']
                            .toString()
                            .replaceFirst('.png', 'l.png')
                            .replaceFirst('.jpeg', 'l.jpeg')
                            .replaceFirst('.jpg', 'l.jpg'),
                      ),
                      actions: <Widget>[
                        FlatButton.icon(
                          onPressed: () {
                            unfavoriteImage(accFavs[index]['cover']);
                            Navigator.of(context).pop();
                          },
                          icon:
                              Icon(Icons.delete, size: 22, color: Colors.white),
                          label: Text(
                            'Remove from Favorites',
                            style: TextStyle(color: Colors.white),
                          ),
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ));
          },
        ));
  }

  Container imagesGrid(int index) {
    return Container(
        padding: EdgeInsets.all(2),
        child: GestureDetector(
          child: FadeInImage.memoryNetwork(
            placeholder: kTransparentImage,
            image: accImages[index]['link']
                .toString()
                .replaceFirst('.png', 'm.png')
                .replaceFirst('.jpeg', 'm.jpeg')
                .replaceFirst('.jpg', 'm.jpg'),
            fadeInDuration: new Duration(milliseconds: 200),
            fadeInCurve: Curves.linear,
            fit: BoxFit.cover,
          ),
          onTap: () {
            showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                      title: Text(accImages[index]['description'].toString()),
                      titlePadding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(10.0))),
                      contentPadding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                      backgroundColor: Color.fromRGBO(51, 53, 58, 1),
                      content: FadeInImage.memoryNetwork(
                        placeholder: kTransparentImage,
                        image: accImages[index]['link']
                            .toString()
                            .replaceFirst('.png', 'l.png')
                            .replaceFirst('.jpeg', 'l.jpeg')
                            .replaceFirst('.jpg', 'l.jpg'),
                      ),
                      actions: <Widget>[
                        Row(
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: new Icon(
                                Icons.remove_red_eye,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(NumberFormat.compact()
                                .format(accImages[index]['views']))
                          ],
                        )
                      ],
                    ));
          },
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: const Text('Your Account', style: TextStyle(fontSize: 24)),
        elevation: 0,
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: new Center(child: new Builder(builder: (context) {
        if (accAvatar == null || accImages == null || accFavs == null) {
          return CircularProgressIndicator();
        } else {
          return Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                      margin: const EdgeInsets.all(15),
                      width: MediaQuery.of(context).size.width / 5,
                      height: MediaQuery.of(context).size.width / 5,
                      decoration: new BoxDecoration(
                          shape: BoxShape.circle,
                          image: new DecorationImage(
                              fit: BoxFit.fill,
                              image: new NetworkImage(accAvatar)))),
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                    child: Center(
                      child: Text(global.urlParams['account_username'],
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          )),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  child: DefaultTabController(
                    length: 2,
                    child: Scaffold(
                      appBar: TabBar(
                        tabs: [
                          Tab(icon: Icon(Icons.photo, size: 26), text: 'Posts'),
                          Tab(icon: Icon(Icons.star, size: 26), text: 'Favorites'),
                        ],
                      ),
                      body: TabBarView(
                        children: [
                          Container(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
                              child: GridView.builder(
                                  itemCount: accImages.length,
                                  shrinkWrap: true,
                                  gridDelegate:
                                      new SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3),
                                  itemBuilder: (context, index) {
                                    return imagesGrid(index);
                                  }),
                            ),
                          ),
                          Container(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
                              child: GridView.builder(
                                  itemCount: accFavs.length,
                                  shrinkWrap: true,
                                  gridDelegate:
                                      new SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3),
                                  itemBuilder: (context, index) {
                                    return favGrid(index);
                                  }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          );
        }
      })),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          getImage();
        },
        backgroundColor: Theme.of(context).primaryColor,
        label: Text('Upload', style: TextStyle(color: Colors.white)),
        icon: Icon(Icons.photo_camera, size: 20, color: Colors.white),
      ),
    );
  }
}
