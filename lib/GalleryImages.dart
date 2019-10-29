import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:intl/intl.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:uri/uri.dart';
import 'package:http/http.dart' as http;
import 'AccountImages.dart';
import 'main.dart' as global;

class GalleryImages extends StatefulWidget {
  @override
  _GalleryImages createState() => _GalleryImages();
}

class _GalleryImages extends State<GalleryImages> {
  GetGalleryImages images;
  int page = 0;

  _GalleryImages() {
    galleryImages();
  }

  galleryImages() {
    http.get(
      'https://api.imgur.com/3/gallery/hot/${page.toString()}',
      headers: {
        HttpHeaders.authorizationHeader:
            "Bearer " + global.urlParams['access_token']
      },
    ).then((response) {
      setState(() {
        images = GetGalleryImages.fromJson(json.decode(response.body));
        _refreshController.loadComplete();
      });
    });
  }

  albumImageVote(String id, String vote) {
    http.post(
      'https://api.imgur.com/3/gallery/$id/vote/$vote',
      headers: {
        HttpHeaders.authorizationHeader:
            "Bearer " + global.urlParams['access_token']
      },
    ).then((response) {
      print(response.body);
      setState(() {});
    });
  }

  favoriteImage(String hash) {
    http.post(
      'https://api.imgur.com/3/image/$hash/favorite',
      headers: {
        HttpHeaders.authorizationHeader:
            "Bearer " + global.urlParams['access_token']
      },
    ).then((response) {
      print(response.body);
      setState(() {});
    });
  }

  IconButton favButtonState(int index) {
    Color isFav;

    if (images.data[index].favorite)
      isFav = Colors.amber;
    else
      isFav = Color.fromRGBO(226, 228, 233, 100);
    return IconButton(
        icon: Icon(Icons.star),
        color: isFav,
        onPressed: () {
          favoriteImage(images.data[index].cover);
          if (images.data[index].favorite)
            images.data[index].favorite = false;
          else
            images.data[index].favorite = true;
          setState(() {});
        });
  }

  IconButton upButtonState(int index) {
    Color isUp;

    if (images.data[index].vote == 'up')
      isUp = Colors.green[500];
    else
      isUp = Color.fromRGBO(226, 228, 233, 100);
    return IconButton(
      icon: Icon(Icons.thumb_up),
      color: isUp,
      onPressed: () {
        print("liked");
        print(images.data[index].link);
        if (images.data[index].vote == 'up') {
          albumImageVote(images.data[index].id, 'veto');
          images.data[index].vote = null;
          images.data[index].ups--;
        } else {
          albumImageVote(images.data[index].id, 'up');
          if (images.data[index].vote == 'down') images.data[index].downs--;
          images.data[index].vote = 'up';
          images.data[index].ups++;
        }
        setState(() {});
      },
    );
  }

  IconButton downButtonState(int index) {
    Color isDown;

    if (images.data[index].vote == 'down')
      isDown = Colors.red[500];
    else
      isDown = Color.fromRGBO(226, 228, 233, 100);
    return IconButton(
      icon: Icon(Icons.thumb_down),
      color: isDown,
      onPressed: () {
        print("disliked");
        print(images.data[index].link);
        if (images.data[index].vote == 'down') {
          albumImageVote(images.data[index].id, 'veto');
          images.data[index].vote = null;
          images.data[index].downs--;
        } else {
          albumImageVote(images.data[index].id, 'down');
          if (images.data[index].vote == 'up') images.data[index].ups--;
          images.data[index].vote = 'down';
          images.data[index].downs++;
        }
        setState(() {});
      },
    );
  }

  ListView imageList() {
    for (int i = 0; i < images.data.length; i++) {
      if (images.data[i].images == null ||
          (images.data[i].images.first.type != 'image/jpeg' &&
              images.data[i].images.first.type != 'image/png')) {
        images.data.removeAt(i);
        i--;
      }
    }
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.all(8),
      itemCount: images.data.length,
      itemBuilder: (context, index) {
        return new Column(
          children: <Widget>[
            new ClipRRect(
                borderRadius: new BorderRadius.circular(10.0),
                child: Container(
                  child: Wrap(
                    children: <Widget>[
                      Center(
                        child: FadeInImage.memoryNetwork(
                          placeholder: kTransparentImage,
                          image: images.data[index].images.first.link
                              .replaceFirst('.png', 'l.png')
                              .replaceFirst('.jpeg', 'l.jpeg')
                              .replaceFirst('.jpg', 'l.jpg'),
                          fadeInDuration: new Duration(milliseconds: 200),
                          fadeInCurve: Curves.linear,
                          fit: BoxFit.contain,
                        ),
                      ),
                      new Container(
                        width: double.infinity,
                        child: new Text(images.data[index].title,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            )),
                        padding: EdgeInsets.all(10.0),
                      ),
                      new Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          new Row(
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
                                child: new Row(children: <Widget>[
                                  upButtonState(index),
                                  new Text(images.data[index].ups.toString()),
                                ]),
                              ),
                              new Row(children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(top: 3),
                                  child: downButtonState(index),
                                ),
                                new Text(images.data[index].downs.toString()),
                              ]),
                            ],
                          ),
                          new Row(children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(left: 8, right: 0),
                              child: favButtonState(index),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: new Icon(
                                Icons.visibility,
                                color: Color.fromRGBO(226, 228, 233, 100),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 0, 30, 0),
                              child: new Text(NumberFormat.compact()
                                  .format(images.data[index].views)),
                            ),
                          ]),
                        ],
                      ),
                    ],
                  ),
                  color: Color.fromRGBO(51, 53, 58, 100),
                )),
          ],
        );
      },
      separatorBuilder: (BuildContext context, int index) => Container(height: 10),
    );
  }

  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  void _onLoading() async {
    page++;
    galleryImages();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: Text(
          "Home",
          style: TextStyle(
            fontSize: 24,
          ),
        ),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).pushNamed('/search');
            },
          ),
          // action button
          Padding(
              child: IconButton(
                icon: Icon(Icons.account_box),
                onPressed: () {
                  Navigator.of(context).pushNamed('/account');
                },
              ),
              padding: EdgeInsets.only(right: 15))
          // action button
        ],
      ),
      body: new Center(child: new Builder(builder: (context) {
        if (images == null) {
          return CircularProgressIndicator();
        } else {
          return SmartRefresher(
            enablePullUp: true,
            enablePullDown: false,
            controller: _refreshController,
            child: imageList(),
            onLoading: _onLoading,
          );
        }
      })),
    );
  }
}

class GetGalleryImages {
  List<Data> data;
  bool success;
  int status;

  GetGalleryImages({this.data, this.success, this.status});

  GetGalleryImages.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = new List<Data>();
      json['data'].forEach((v) {
        data.add(new Data.fromJson(v));
      });
    }
    success = json['success'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data.map((v) => v.toJson()).toList();
    }
    data['success'] = this.success;
    data['status'] = this.status;
    return data;
  }
}

class Data {
  String id;
  String title;
  String cover;
  int views;
  String link;
  String vote;
  bool favorite;
  int ups;
  int downs;
  List<Images> images;

  Data(
      {this.id,
      this.title,
      this.cover,
      this.views,
      this.link,
      this.vote,
      this.favorite,
      this.ups,
      this.downs,
      this.images});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    cover = json['cover'];
    views = json['views'];
    link = json['link'];
    vote = json['vote'];
    favorite = json['favorite'];
    ups = json['ups'];
    downs = json['downs'];
    if (json['images'] != null) {
      images = new List<Images>();
      json['images'].forEach((v) {
        images.add(new Images.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['cover'] = this.cover;
    data['views'] = this.views;
    data['link'] = this.link;
    data['vote'] = this.vote;
    data['favorite'] = this.favorite;
    data['ups'] = this.ups;
    data['downs'] = this.downs;
    if (this.images != null) {
      data['images'] = this.images.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Images {
  String type;
  String link;

  Images({this.type, this.link});

  Images.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    link = json['link'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['link'] = this.link;
    return data;
  }
}
