import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class SearchTab extends StatefulWidget {
  final String apiURL;
  const SearchTab(this.apiURL, {super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab>
    with AutomaticKeepAliveClientMixin<SearchTab> {
  TextEditingController searchController = TextEditingController();
  bool isFetchingSearch = false;
  Map<String, dynamic>? searchResults;

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
      history = prefs.getStringList('search_history') ?? [];
    });
  }

  void _saveHistory() {
    prefs.setStringList('search_history', history);
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

  Future<void> searchHashes(String searchQuery) async {
    String? apiURL = widget.apiURL;
    if (isFetchingSearch) {
      return;
    }
    addToHistory(searchQuery);
    setState(() {
      isFetchingSearch = true;
    });
    final response = await http
        .get(Uri.parse('$apiURL/blocks/search?search_string=$searchQuery'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        searchResults = data;
      });
    } else {
      debugPrint('Request failed with status: ${response.statusCode}');
    }
    setState(() {
      isFetchingSearch = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        TypeAheadField(
          key: UniqueKey(),
          textFieldConfiguration: TextFieldConfiguration(
            controller: searchController,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: 'Enter search query',
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
            if (searchController.text == '') {
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
            searchController.text = suggestion;
          },
        ),
        ElevatedButton(
          onPressed: isFetchingSearch
              ? null
              : () {
                  final searchQuery = searchController.text;
                  if (searchQuery.isNotEmpty) {
                    searchHashes(searchQuery);
                  }
                },
          child: Text(isFetchingSearch ? 'Fetching...' : 'Get'),
        ),
        if (searchResults != null)
          ListTile(
            title: Text('Search String: ${searchResults!['search_string']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('Regular Count: ${searchResults!['regular_count']}'),
                const SizedBox(height: 5),
                Text(
                    'Latest Regular Hash: ${searchResults!['latest_regular_hash']}'),
                const SizedBox(height: 8),
                Text('Xuni Count: ${searchResults!['xuni_count']}'),
                const SizedBox(height: 5),
                Text('Latest Xuni Hash: ${searchResults!['latest_xuni_hash']}'),
              ],
            ),
          ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
