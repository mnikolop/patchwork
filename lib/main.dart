import 'package:flutter/material.dart';
import 'package:patchwork/endScreen.dart';
import 'package:patchwork/mainMenu.dart';
import 'package:patchwork/gameplay.dart';
import 'package:patchwork/setup.dart';
import 'package:provider/provider.dart';
import 'package:patchwork/gamestate.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());
// TODO Animations. coola animeringar övergångar osv. snyggt vore om när man gör put piece så läggs den ner.
// och knapparna räknas bort i en animation, sen flippas det automatiskt till timeboard-vyn där spelarens piece rör sig steg framåt
//när den stannat och antingen fått en extra piece eller är nästa spelares tur så swapar den tillbaka till game-vyn
//pieceSelectorn ska också animeras så att den snyggt plockar bort pieces och glider till vänster

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChangeNotifierProvider<GameState>(
        builder: (_) => GameState(),
        child: HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    final view = gameState.getView();
    Widget child;
    bool showAppBar = true;
    if (view == null) {
      child = MainMenu();
    } else if (view == "setup") {
      child = Setup();
    } else if (view == "gameplay") {
      child = Gameplay();
      showAppBar = false;
    } else if (view == "finished") {
      child = EndScreen();
      showAppBar = false;
    }
    return new WillPopScope(
        onWillPop: () {
          return new Future(() => false);
        },
        child: Scaffold(
          appBar: showAppBar
              ? AppBar(
                  title: Text("Patchwork"),
                )
              : null,
          body: child,
        ));
    ;
  }
}
