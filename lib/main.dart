import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:xnmxplorer/model_theme.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'stats_tab.dart';
import 'blocks_tab.dart';
import 'search_tab.dart';

final myDarkTheme = ThemeData(
  colorScheme: const ColorScheme.dark().copyWith(
    primary: Colors.grey,
    secondary: Colors.lightGreenAccent,
  ),
  indicatorColor: Colors.lightGreenAccent,
);
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final modelTheme = ModelTheme();
  await modelTheme.getPreferences();
  await dotenv.load();
  runApp(ChangeNotifierProvider(
    create: (context) => modelTheme,
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xenium Xplorer',
      home: AnimatedSplashScreen(
          duration: 2000,
          splash: 'assets/images/logo_circle.png',
          nextScreen: const XenXplorer(),
          splashTransition: SplashTransition.slideTransition,
          pageTransitionType: PageTransitionType.bottomToTop,
          backgroundColor: Colors.black),
      debugShowCheckedModeBanner: false,
    );
  }
}

class XenXplorer extends StatefulWidget {
  const XenXplorer({Key? key}) : super(key: key);

  @override
  State<XenXplorer> createState() => _XenXplorerState();
}

class _XenXplorerState extends State<XenXplorer> {
  @override
  Widget build(BuildContext context) {
    final modelTheme = Provider.of<ModelTheme>(context);
    final apiURL = dotenv.env['API_URL'];
    return MaterialApp(
      title: 'Xenium Xplorer',
      theme: modelTheme.isDark ? ThemeData.light() : myDarkTheme,
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.bar_chart)),
                Tab(icon: Icon(Icons.apps)),
                Tab(icon: Icon(Icons.search)),
              ],
            ),
            title: const Text('Xenium Xplorer v0.1'),
            actions: [
              IconButton(
                onPressed: () {
                  modelTheme.isDark = !modelTheme.isDark;
                },
                icon: Icon(
                  modelTheme.isDark ? Icons.brightness_4 : Icons.brightness_7,
                ),
              ),
              IconButton(
                onPressed: () {
                  // Show the popup message
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return PopupMessage();
                    },
                  );
                },
                icon: const Icon(
                  Icons.star,
                ),
              )
            ],
          ),
          body: TabBarView(
            children: [
              StatsTab(apiURL!),
              BlocksTab(apiURL),
              SearchTab(apiURL),
            ],
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PopupMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Theme(
        data: myDarkTheme,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              SelectableText.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text:
                          'Please note that this app is a work in progress, and I welcome your suggestions and feedback to make it even better!\n\n'
                          'If you find the app valuable and enjoyable, you can consider sending Xen as a token of appreciation. '
                          'Even a small contribution brings a smile to my face! 😊\n\n'
                          'Your support helps improve and maintain the app.\n\n'
                          'My address: ',
                      style: TextStyle(fontSize: 12.0, color: Colors.grey),
                    ),
                    WidgetSpan(
                      child: IconButton(
                        icon: const Icon(
                          Icons.content_copy,
                          size: 20,
                        ),
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(
                              text:
                                  '0xda923d9c6db9fc8cc4340f2c6cb39ca543ee333e'));
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    const TextSpan(
                      text: '0xda923d9c6db9fc8cc4340f2c6cb39ca543ee333e',
                      style: TextStyle(fontSize: 12.0, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
