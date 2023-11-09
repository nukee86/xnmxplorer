import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BlocksTab extends StatefulWidget {
  final String apiURL;
  const BlocksTab(this.apiURL, {super.key});

  @override
  State<BlocksTab> createState() => _BlocksTabState();
}

class _BlocksTabState extends State<BlocksTab>
    with AutomaticKeepAliveClientMixin<BlocksTab> {
  String? selectedBlockType;
  List<List<dynamic>> latestBlocks = [];

  Future<void> fetchLatestBlocks(String blockType) async {
    String? apiURL = widget.apiURL;

    final response =
        await http.get(Uri.parse('$apiURL/blocks/latest?type=$blockType'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data.containsKey('latest_blocks') && data['latest_blocks'] is List) {
        final blocksData = data['latest_blocks'];

        setState(() {
          latestBlocks = List<List<dynamic>>.from(blocksData);
        });
      } else {
        debugPrint('Invalid data format');
      }
    } else {
      debugPrint('Request failed with status: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceEvenly, // Align buttons evenly in the row
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text(
                  'Blocks',
                  style: TextStyle(fontSize: 14.0),
                ),
                value: 'regular',
                groupValue: selectedBlockType,
                onChanged: (value) {
                  setState(() {
                    selectedBlockType = value!;
                  });
                  fetchLatestBlocks(value!);
                },
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text(
                  'Xuni',
                  style: TextStyle(fontSize: 14.0),
                ),
                value: 'xuni',
                groupValue: selectedBlockType,
                onChanged: (value) {
                  setState(() {
                    selectedBlockType = value!;
                  });
                  fetchLatestBlocks(value!);
                },
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text(
                  'Super',
                  style: TextStyle(fontSize: 14.0),
                ),
                value: 'super',
                groupValue: selectedBlockType,
                onChanged: (value) {
                  setState(() {
                    selectedBlockType = value!;
                  });
                  fetchLatestBlocks(value!);
                },
              ),
            ),
          ],
        ),
        // Display the latest blocks here
        latestBlocks.isNotEmpty
            ? Expanded(
                child: ListView.builder(
                  itemCount: latestBlocks.length,
                  itemBuilder: (context, index) {
                    final blockData =
                        latestBlocks[index]; // Access the list for each block
                    return ListTile(
                      title: Text('Block ID: ${blockData[0]}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hash to Verify: ${blockData[1]}'),
                          Text('Key: ${blockData[2]}'),
                          Text('Account: ${blockData[3]}'),
                          Text('Created At: ${blockData[4]}'),
                        ],
                      ),
                    );
                  },
                ),
              )
            : const Text('No data available.'),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
