import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_alice/core/alice_core.dart';
import 'package:flutter_alice/helper/alice_save_helper.dart';
import 'package:flutter_alice/model/alice_http_call.dart';
import 'package:flutter_alice/ui/utils/alice_constants.dart';
import 'package:flutter_alice/ui/widget/alice_call_error_widget.dart';
import 'package:flutter_alice/ui/widget/alice_call_overview_widget.dart';
import 'package:flutter_alice/ui/widget/alice_call_request_widget.dart';
import 'package:flutter_alice/ui/widget/alice_call_response_widget.dart';
import 'package:share_plus/share_plus.dart';

class AliceCallDetailsScreen extends StatefulWidget {
  final AliceHttpCall call;
  final AliceCore core;

  AliceCallDetailsScreen(this.call, this.core);

  @override
  _AliceCallDetailsScreenState createState() => _AliceCallDetailsScreenState();
}

class _AliceCallDetailsScreenState extends State<AliceCallDetailsScreen> with SingleTickerProviderStateMixin {
  AliceHttpCall get call => widget.call;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: widget.core.brightness,
        primarySwatch: Colors.green,
      ),
      child: StreamBuilder<List<AliceHttpCall>>(
        stream: widget.core.callsSubject,
        initialData: [widget.call],
        builder: (context, callsSnapshot) {
          if (callsSnapshot.hasData) {
            AliceHttpCall? call = callsSnapshot.data?.firstWhere(
              (snapshotCall) => snapshotCall.id == widget.call.id,
              orElse: null,
            );
            if (call != null) {
              return _buildMainWidget();
            } else {
              return _buildErrorWidget();
            }
          } else {
            return _buildErrorWidget();
          }
        },
      ),
    );
  }

  Widget _buildMainWidget() {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: AliceConstants.lightRed,
          key: Key('share_key'),
          onPressed: () async {
            showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return Container(
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          height: 20,
                        ),
                        _ItemShared(
                          title: 'Curl',
                          onShare: () {
                            Share.share(call.getCurlCommand(), subject: 'Curl command');
                          },
                          onCopy: () {
                            Clipboard.setData(ClipboardData(text: call.getCurlCommand()));
                          },
                        ),
                        _ItemShared(
                          title: 'Response body',
                          onShare: () async {
                            AliceSaveHelper.getResponseBody(call).then((value) {
                              Share.share(value!, subject: 'Response body');
                            });
                          },
                          onCopy: () {
                            AliceSaveHelper.getResponseBody(call).then((value) {
                              Clipboard.setData(ClipboardData(text: value ?? ''));
                            });
                          },
                        ),
                        _ItemShared(
                          title: 'Response headers',
                          onShare: () async {
                            AliceSaveHelper.getHeaderRequest(call).then((value) {
                              Share.share(value!, subject: 'Response headers');
                            });
                          },
                          onCopy: () {
                            AliceSaveHelper.getHeaderRequest(call).then((value) {
                              Clipboard.setData(ClipboardData(text: value ?? ''));
                            });
                          },
                        ),
                        _ItemShared(
                          title: 'Full log',
                          onShare: () async {
                            Share.share(await _getSharableResponseString(), subject: 'Full log');
                          },
                          onCopy: () {
                            Clipboard.setData(ClipboardData(text: call.getCurlCommand()));
                          },
                        ),
                      ],
                    ),
                  );
                });
          },
          child: Icon(Icons.share),
        ),
        appBar: AppBar(
          bottom: TabBar(
            indicatorColor: AliceConstants.lightRed,
            tabs: _getTabBars(),
          ),
          title: Text('Alice - HTTP Call Details'),
        ),
        body: TabBarView(
          children: _getTabBarViewList(),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(child: Text("Failed to load data"));
  }

  Future<String> _getSharableResponseString() async {
    return AliceSaveHelper.buildCallLog(widget.call);
  }

  List<Widget> _getTabBars() {
    List<Widget> widgets = [];
    widgets.add(Tab(icon: Icon(Icons.info_outline), text: "Overview"));
    widgets.add(Tab(icon: Icon(Icons.arrow_upward), text: "Request"));
    widgets.add(Tab(icon: Icon(Icons.arrow_downward), text: "Response"));
    widgets.add(Tab(icon: Icon(Icons.warning), text: "Error"));
    return widgets;
  }

  List<Widget> _getTabBarViewList() {
    List<Widget> widgets = [];
    widgets.add(AliceCallOverviewWidget(widget.call));
    widgets.add(AliceCallRequestWidget(widget.call));
    widgets.add(AliceCallResponseWidget(widget.call));
    widgets.add(AliceCallErrorWidget(widget.call));
    return widgets;
  }
}

class _ItemShared extends StatelessWidget {
  const _ItemShared({
    Key? key,
    required this.title,
    required this.onShare,
    required this.onCopy,
  }) : super(key: key);

  final String title;
  final Function() onShare;
  final Function() onCopy;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Colors.green.shade300,
        ),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: ListTile(
        title: Text(title),
        trailing: Wrap(
          spacing: 0, // space between two icons
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.copy),
              onPressed: onCopy,
            ), // icon-1
            IconButton(
              icon: Icon(Icons.share),
              onPressed: onShare,
            ), //
          ],
        ),
      ),
    );
  }
}
