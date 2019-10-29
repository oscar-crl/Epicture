import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:uri/uri.dart';
import 'package:http/http.dart' as http;
import 'GalleryImages.dart';
import 'main.dart' as global;

class SearchGalleryImages extends StatefulWidget {
  @override
  _SearchGalleryImages createState() => _SearchGalleryImages();
}

class _SearchGalleryImages extends State<SearchGalleryImages> {
  GetGalleryImages images;
  String searched;
  String searchGallery = 'https://api.imgur.com/3/gallery/search/';
  int page = 0;

  void searchImages(String sort, String window, String search, String type) {
    String searchRequest;
    if (type == null)
      searchRequest =
          searchGallery + '$sort/$window/${page.toString()}?q_all=$search';
    else
      searchRequest = searchGallery +
          '$sort/$window/${page.toString()}?q_all=$search&q_type=${type.toLowerCase()}';
    http.get(
      searchRequest,
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
    searchImages(selectedSort.toLowerCase(), selectedWindow.toLowerCase(),
        searched, selectedType);
  }

  bool onSearch = false;

  Widget buildBar(BuildContext context) {
    return new AppBar(
      title: new TextField(
        style: new TextStyle(
          fontSize: 18,
          color: Colors.white,
        ),
        decoration: new InputDecoration(
            prefixIcon: new Icon(
              Icons.search,
              color: Colors.white,
            ),
            hintText: "Search...",
            hintStyle: new TextStyle(color: Colors.white70, fontSize: 18)),
        autofocus: true,
        textInputAction: TextInputAction.done,
        onTap: () {
          setState(() {
            onSearch = true;
          });
        },
        onSubmitted: (inputText) {
          if (inputText != null && inputText != "")
            setState(() {
              onSearch = false;
              page = 0;
              searchImages(
                  selectedSort.toLowerCase(),
                  selectedWindow.toLowerCase(),
                  inputText,
                  selectedType);
              searched = inputText;
            });
        },
      ),
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.home),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        Padding(
            child: IconButton(
              icon: Icon(Icons.account_box),
              onPressed: () {
                Navigator.of(context).pushNamed('/account');
              },
            ),
            padding: EdgeInsets.only(right: 15))
      ],
    );
  }

  List<String> sortFilter = ["Time", "Viral", "Top"];
  List<String> windowFilter = ["Day", "Week", "Month", "Year", "All"];
  List<String> typeFilter = ["PNG", "JPG"];

  String selectedSort = 'Top';
  String selectedWindow = 'All';
  String selectedType;

  _buildSortFilter() {
    List<Widget> sortFilterList = List();

    sortFilter.forEach((item) {
      sortFilterList.add(Container(
        padding: const EdgeInsets.all(2.0),
        child: ChoiceChip(
          label: Text(item),
          selected: selectedSort == item,
          onSelected: (selected) {
            setState(() {
              selectedSort = item;
            });
          },
        ),
      ));
    });
    return sortFilterList;
  }

  _buildWindowFilter() {
    List<Widget> windowFilterList = List();

    windowFilter.forEach((item) {
      windowFilterList.add(Container(
        padding: const EdgeInsets.all(2.0),
        child: ChoiceChip(
          label: Text(item),
          selected: selectedWindow == item,
          onSelected: (selected) {
            setState(() {
              selectedWindow = item;
            });
          },
        ),
      ));
    });
    return windowFilterList;
  }

  _buildTypeFilter() {
    List<Widget> typeFilterList = List();

    typeFilter.forEach((item) {
      typeFilterList.add(Container(
        padding: const EdgeInsets.all(2.0),
        child: ChoiceChip(
          label: Text(item),
          selected: selectedType == item,
          onSelected: (selected) {
            setState(() {
              if (selectedType == item)
                selectedType = null;
              else
                selectedType = item;
            });
          },
        ),
      ));
    });
    return typeFilterList;
  }

  Widget onSearchFilters() {
    if (onSearch)
      return Wrap(
        children: <Widget>[
          Column(children: <Widget>[
            Wrap(children: _buildSortFilter()),
            Wrap(children: _buildWindowFilter()),
            Wrap(children: _buildTypeFilter()),
          ])
        ],
        alignment: WrapAlignment.center,
      );
    else
      return Container(height: 10);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: buildBar(context),
      body: new Center(child: new Builder(builder: (context) {
        if (images != null)
          return Column(
            children: <Widget>[
              onSearchFilters(),
              Expanded(
                child: SmartRefresher(
                  enablePullUp: true,
                  enablePullDown: false,
                  controller: _refreshController,
                  child: imageList(),
                  onLoading: _onLoading,
                ),
              ),
            ],
          );
        else
          return Column(
            children: <Widget>[
              Wrap(
                children: <Widget>[
                  Column(children: <Widget>[
                    Wrap(children: _buildSortFilter()),
                    Wrap(children: _buildWindowFilter()),
                    Wrap(children: _buildTypeFilter()),
                  ])
                ],
                alignment: WrapAlignment.center,
              )
            ],
          );
      })),
    );
  }
}
