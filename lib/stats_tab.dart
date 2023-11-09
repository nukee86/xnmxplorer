import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class StatsTab extends StatefulWidget {
  final String apiURL;
  const StatsTab(this.apiURL, {super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab>
    with AutomaticKeepAliveClientMixin<StatsTab> {
  TextEditingController accountController = TextEditingController();
  String account = '';
  String accountBlocks = '';
  String accountXuniBlocks = '';
  String accountSuperBlocks = '';
  String totalBlocks = '';
  String totalXuniBlocks = '';
  String totalSuperBlocks = '';
  bool isFetchingStats = false;

  List<String> history = [];
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  _loadHistory() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      history = prefs.getStringList('account_history') ?? [];
    });
  }

  void _saveHistory() {
    prefs.setStringList('account_history', history);
  }

  void addToHistory(String text) {
    if (!history.contains(text)) {
      setState(() {
        history.insert(0, text); // Insert at the beginning.
        if (history.length > 5) {
          history.removeLast(); // Keep only the 5 most recent searches.
        }
        _saveHistory();
      });
    }
  }

  void removeFromHistory(String text) {
    setState(() {
      history.remove(text);
      _saveHistory();
    });
  }

  Future<void> fetchStatsData(String account) async {
    String? apiURL = widget.apiURL;

    if (isFetchingStats) {
      return;
    }
    if (account != '') {
      addToHistory(account);
    }
    setState(() {
      isFetchingStats = true;
    });
    if (account != '') {
      final response =
          await http.get(Uri.parse('$apiURL/blocks/count/$account'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          accountBlocks = 'Account Blocks: ${data['regular_count']}';
          accountXuniBlocks = 'Account Xuni Blocks: ${data['xuni_count']}';
          accountSuperBlocks =
              'Account Super Blocks: ${data['superblock_count']}';
        });
      } else {
        debugPrint('Request failed with status: ${response.statusCode}');
      }
    } else {
      accountBlocks = 'Account Blocks:';
      accountXuniBlocks = 'Account Xuni Blocks:';
      accountSuperBlocks = 'Account Super Blocks:';
    }
    // Fetch total statistics
    final totalResponse = await http.get(Uri.parse('$apiURL/blocks/count'));
    if (totalResponse.statusCode == 200) {
      final totalData = json.decode(totalResponse.body);
      setState(() {
        totalBlocks = 'Total Blocks: ${totalData['regular_count']}';
        totalXuniBlocks = 'Total Xuni Blocks: ${totalData['xuni_count']}';
        totalSuperBlocks =
            'Total Super Blocks: ${totalData['superblock_count']}';
      });
    } else {
      debugPrint('Request failed with status: ${totalResponse.statusCode}');
    }
    setState(() {
      isFetchingStats = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          TypeAheadField(
            key: UniqueKey(),
            textFieldConfiguration: TextFieldConfiguration(
              controller: accountController,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: 'Enter Account',
              ),
              onTapOutside: (event) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ),
            hideOnLoading: true,
            hideOnEmpty: true,
            animationStart: 1,
            suggestionsCallback: (pattern) {
              return history.where((item) => item.startsWith(pattern));
            },
            itemBuilder: (context, suggestion) {
              if (accountController.text == '') {
                return ListTile(
                  title: Text(suggestion),
                  trailing: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: (() => removeFromHistory(suggestion)),
                  ),
                );
              } else {
                return Container();
              }
            },
            onSuggestionSelected: (suggestion) {
              accountController.text = suggestion;
            },
          ),
          ElevatedButton(
            onPressed: isFetchingStats
                ? null
                : () {
                    account = accountController.text;
                    fetchStatsData(account);
                  },
            child: Text(isFetchingStats ? 'Fetching...' : 'Get'),
          ),
          if (account != '')
            Column(
              children: [
                ListTile(
                  visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                  title: Text(accountBlocks),
                ),
                ListTile(
                  visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                  title: Text(accountXuniBlocks),
                ),
                ListTile(
                  visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                  title: Text(accountSuperBlocks),
                ),
              ],
            ),
          ListTile(
            visualDensity: VisualDensity(horizontal: 0, vertical: -4),
            title: Text(totalBlocks),
          ),
          ListTile(
            visualDensity: VisualDensity(horizontal: 0, vertical: -4),
            title: Text(totalXuniBlocks),
          ),
          ListTile(
            visualDensity: VisualDensity(horizontal: 0, vertical: -4),
            title: Text(totalSuperBlocks),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
