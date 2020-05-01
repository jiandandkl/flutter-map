import 'dart:io';
import 'package:flutter/material.dart';
import 'package:amap_all_fluttify/amap_all_fluttify.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with AmapSearchDisposeMixin {
  AmapController _controller;
  LatLng _latLngNew;
  String _cityCode, _cityName;
  List _poiTitleList = [];
  int _tapIndex;
  bool isAndroid = false;

  @override
  void initState() {
    super.initState();
    if(Platform.isAndroid) {
      isAndroid = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Flexible(
            flex: 3,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
              AmapView(
                zoomLevel: 16.0,
                rotateGestureEnabled: false,
                onMapCreated: (controller) async {
                  _controller = controller;
                  // 等待用户授权
                  if (await requestPermission()) {
                    // 初始位置周边信息
                    await controller.showMyLocation(MyLocationOption(show: true));
                    // 当前坐标
                    LatLng _myLocation = await controller?.getLocation();
                    setState(() {
                      _latLngNew = _myLocation;
                    });
                    var location = await AmapLocation.fetchLocation();
                    String cityCode = location.cityCode;
                    _cityName = location.city;
                    _cityCode = cityCode ?? '010';
                    // 搜索附近
                    var myPoiList = await AmapSearch.searchAround(_myLocation, city: _cityCode);
                    await Future.forEach(myPoiList, (item) async {
                      String title = await item.title;
                      String address = await item.address;
                      LatLng location = await item.latLng;
                      setState(() {
                        _poiTitleList.add([title, address, location]);
                      });
                    });
                  }
                },
              ),
              isAndroid
              ? Positioned(
                  child: Icon(Icons.my_location, color: Colors.green,)
                )
              : Container()
            ],
          ),
          ),
          Flexible(
            flex: 2,
            child: Container(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  children: <Widget>[
                    // 输入地点搜索周边
                    TextField(
                      decoration: InputDecoration(
                        hintText: '搜索地点',
                        prefixIcon: Icon(Icons.search, color: Colors.green,),
                      ),
                      onSubmitted: (value) async {
                        _poiTitleList = [];
                        final poiList = await AmapSearch.searchKeyword(value, city: _cityName);
                        await Future.forEach(poiList, (item) async {
                          String title = await item.title;
                          String address = await item.address;
                          LatLng location = await item.latLng;
                          // String codeCity = await item.cityCode;
                          setState(() {
                            _poiTitleList.add([title, address, location]);
                          });
                        });
                      }
                    ),
                    Expanded(
                      // 列表展示周边信息
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(_poiTitleList?.length, (int index) {
                            return InkWell(
                              onTap: () {
                                // 第二次点击即选取此坐标
                                if (_tapIndex == index) {
                                  Navigator.pop(context, '{"cityCode": "$_cityCode", "location": "$_latLngNew"}');
                                } else {
                                  setState(() {
                                    _tapIndex = index;
                                    _latLngNew = _poiTitleList[index][2];
                                  });
                                  // 设置中心点为选中的坐标
                                  _controller.setCenterCoordinate(_poiTitleList[index][2].latitude, _poiTitleList[index][2].longitude);
                                  _controller.clearMarkers();
                                  _controller.addMarker(MarkerOption(
                                    latLng: _poiTitleList[index][2],
                                    iconUri: Uri.parse('images/marker.png'),
                                    imageConfig: createLocalImageConfiguration(context),
                                  ));
                                }
                              },
                              child: Padding(
                                padding: EdgeInsets.only(top: 8, left: 4, right: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                _poiTitleList[index][0],
                                                softWrap: false,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontWeight: FontWeight.w500),),
                                              Padding(
                                                padding: EdgeInsets.only(top: 4),
                                                child: Text(
                                                  _poiTitleList[index][1],
                                                  softWrap: false,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(fontSize: 13),),
                                              ),
                                            ],
                                          ),
                                        ),
                                        _tapIndex == index ? Icon(Icons.done, color: Colors.green,) : Container()
                                      ],
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Container(
                                        height: 1,
                                        color: Colors.grey,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          })
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),)       
        ],
      ),
    );
  }
}

