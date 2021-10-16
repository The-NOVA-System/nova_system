import 'dart:math';
import 'package:nova_system/util/const.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:statusbarz/statusbarz.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}

void main() => runApp(const Wallet());

void updateCharts() {}

enum mode { graphUniform, uniform, rainbow }

var uniformColour = "011469";
var iconApiUrl = "https://cryptoicons.org";

class PointModel {
  final num pointX;
  final num pointY;

  PointModel({required this.pointX, required this.pointY});
}

class Config {
  static final List<PointModel> _chartDataList = [];
  static bool _loaded = false;
  static var colourMode = mode.rainbow;

  static isLoaded() {
    return _loaded;
  }

  static getMode() {
    return colourMode;
  }

  static chartRefresh() {
    _loaded = false;
    Statusbarz.instance.refresh();
  }

  static loadChartDataList() async {
    // fetch data from web ...
    await loadFromWeb();
    _loaded = true;
  }

  static loadFromWeb() {
    // but here i will add test data
    _chartDataList.clear();
  }

  static getChartDataList() {
    if (!_loaded) loadChartDataList();
    return _chartDataList;
  }
}

class Wallet extends StatefulWidget {
  final String? name;
  final String? icon;
  final String? rate;
  final String? alt;
  final String? colorHex;
  final double? priceChange;
  final charts.Color? color;
  final List<PointModel>? data;
  const Wallet(
      {Key? key,
      this.name,
      this.icon,
      this.rate,
      this.color,
      this.alt,
      this.colorHex,
      this.priceChange,
      this.data})
      : super(key: key);

  @override
  _WalletState createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  final List<charts.Series<PointModel, num>> _chartDataSeries = [];
  List<PointModel> chartDataList = [];
  Widget lineChart = const Text("");
  final List color =
      Constants.matColors[Random().nextInt(Constants.matColors.length)];

  @override
  Widget build(BuildContext context) {
    // this is where i use Config class to perform my asynchronous load data
    // and check if it's loaded so this section will occur only once
    if (!Config.isLoaded()) {
      Config.loadChartDataList().then((value) =>
          // call the setState() to tell flutter that it should re-evaluate the widget tree based
          // on this code changing the state of the class (the vars i.e. lineChart) and decide if
          // it wants to redraw, this is the reason to put lineChart as a var of the class
          // so when it changes - it changes the class state
          setState(() {
            chartDataList = widget.data!;
            print(widget.priceChange);
            _chartDataSeries.clear();
            bool setIconColour = false;
            bool setGraphColour = false;

            if (Config.getMode() == mode.uniform) {
              setIconColour = true;
              setGraphColour = true;
            } else if (Config.getMode() == mode.graphUniform) {
              setGraphColour = true;
              color[1] = "";
            }

            if (setGraphColour == true) {
              color[0] = charts.ColorUtil.fromDartColor(
                  HexColor.fromHex(uniformColour));
            }

            if (setIconColour == true) {
              color[1] = uniformColour;
            }

            // construct you're chart data series
            _chartDataSeries.add(
              charts.Series<PointModel, num>(
                colorFn: (_, __) => color[0]!,
                id: '${widget.name}',
                data: chartDataList,
                domainFn: (PointModel pointModel, _) => pointModel.pointX,
                measureFn: (PointModel pointModel, _) => pointModel.pointY,
              ),
            );

            // now change the 'Loading...' widget with the real chart widget
            lineChart = charts.LineChart(
              _chartDataSeries,
              defaultRenderer:
                  charts.LineRendererConfig(includeArea: true, stacked: true),
              animate: true,
              animationDuration: const Duration(milliseconds: 500),
              primaryMeasureAxis: const charts.NumericAxisSpec(
                renderSpec: charts.NoneRenderSpec(),
              ),
              domainAxis: const charts.NumericAxisSpec(
//                showAxisLine: true,
                renderSpec: charts.NoneRenderSpec(),
              ),
            );
          }));
    }

    // here return your widget where the chart is drawn
    return Card(
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(10),
        ),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    SizedBox(
                        child: CachedNetworkImage(
                          imageUrl:
                              "$iconApiUrl/api/icon/${widget.alt!.toLowerCase()}/100/${color[1]!.toLowerCase()}",
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              CachedNetworkImage(
                            imageUrl: "${widget.icon}",
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => (() {
                              try {
                                return SvgPicture.network(
                                  "${widget.icon}",
                                  semanticsLabel: 'crypto logo',
                                  placeholderBuilder: (BuildContext context) =>
                                  const CircularProgressIndicator(),
                                );
                              } catch(error) {
                                return const Icon(Icons.error);
                              }

                            }()),
                          ),
                        ),
                        height: 25.0,
                        width: 25.0),
                    /*FadeInImage(
                      image: NetworkImage("https://cryptoicons.org/api/icon/${widget.alt!.toLowerCase()}/100/${color[1]!.toLowerCase()}", scale: 4),
                      placeholder: const AssetImage('assets/placeholder.png'),
                    )*/
                    const SizedBox(width: 10),
                    Text(
                      "${widget.name}",
                      style: const TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                Text(
                  "${widget.rate}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(" "),
                Text(
                  "(${(widget.priceChange! * 100).toString()}%) ${(widget.priceChange! * double.parse(widget.rate!)).toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[400],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 150,
            child: lineChart,
          ),
        ],
      ),
    );
  }
}
