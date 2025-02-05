import 'dart:math';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:patchwork/utilities/constants.dart';
import 'package:provider/provider.dart';
import 'package:patchwork/logic/gamestate.dart';
import 'package:flutter_colorpicker/block_picker.dart';
import 'package:flutter_colorpicker/utils.dart';
import 'package:patchwork/models/player.dart';
import 'package:emoji_picker/emoji_picker.dart';

class Setup extends StatefulWidget {
  final GameMode gameMode;
  Setup({this.gameMode});
  @override
  SetupState createState() {
    return SetupState();
  }
}

class SetupState extends State<Setup> {
  Random rng = new Random();
  Color _pickerColor;
  String _pickedEmoji;
  TextEditingController nameController = TextEditingController();
  bool _isAi = false;
  bool _playTutorial;
  int _playerId = 0;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_playTutorial == null) {
        bool firstGame = await gameState.isFirstGame();
        setState(() {
          _playTutorial = firstGame;
        });
      }
    });
    List<Player> players = gameState.getPlayers();
    List<Color> usedColors = players.map((p) => p.color).toList();
    List<Color> availableColors =
        playerColors.where((color) => !usedColors.contains(color)).toList();
    if (_pickerColor == null) {
      Random rng = new Random();
      _pickerColor = availableColors[rng.nextInt(availableColors.length)];
    }

    List<String> usedEmojis = players.map((p) => p.emoji).toList();
    List<String> availableEmojis = 
        playerEmojis.where((pickedEmoji) => !usedEmojis.contains(pickedEmoji)).toList();
    if (_pickedEmoji == null) {
      Random rng = new Random();
      _pickedEmoji = availableEmojis[rng.nextInt(availableEmojis.length)];
    }

    return Scaffold(
        body: Builder(
            builder: (context) => Center(
                  child: Stack(
                    children: <Widget>[
                      Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height * 0.15,
                          child: ShaderMask(
                            shaderCallback: (rect) {
                              return LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.black, Colors.transparent],
                              ).createShader(
                                  Rect.fromLTRB(0, 0, rect.width, rect.height));
                            },
                            blendMode: BlendMode.dstIn,
                            child: Image.asset(
                              'assets/classic_screenshot.gif',
                              fit: BoxFit.fitWidth,
                            ),
                          )),
                      SafeArea(
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: 16, right: 16, top: 0, bottom: 4),
                          child: Column(
                            children: <Widget>[
                              Stack(
                                children: <Widget>[
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: IconButton(
                                      icon: BackButtonIcon(),
                                      color: Colors.white,
                                      highlightColor: Colors.transparent,
                                      iconSize: 28,
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    heightFactor: 2,
                                    child: Text(
                                      "New ${gameModeName[widget.gameMode]} game",
                                      style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                          shadows: <Shadow>[
                                            Shadow(
                                              offset: Offset(1.0, 1.0),
                                              blurRadius: 2.0,
                                              color:
                                                  Color.fromARGB(255, 0, 0, 0),
                                            ),
                                            Shadow(
                                              offset: Offset(1.0, 1.0),
                                              blurRadius: 2.0,
                                              color: Color.fromARGB(
                                                  125, 0, 0, 255),
                                            ),
                                          ],
                                          color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 30,
                              ),
                              Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        "Add players",
                                        style: TextStyle(fontSize: 30),
                                      ),
                                    ),
                                    Expanded(
                                      child: SwitchListTile(
                                        title: const Text("Show Tutorial"),
                                        activeColor: Colors.green.shade700,
                                        onChanged: _onSwitchChanged,
                                        value: _playTutorial ?? false,
                                      ),
                                    ),
                                  ]),
                              Row(mainAxisSize: MainAxisSize.min, children: <
                                  Widget>[
                                Expanded(
                                  child: TextField(
                                    controller: nameController,
                                    maxLength: 12,
                                    decoration:
                                        InputDecoration(labelText: 'Name'),
                                  ),
                                ),
                                Container(
                                  child: new Padding(
                                    padding: const EdgeInsets.only(left: 2),
                                    child: ButtonTheme.bar(
                                        child: ButtonBar(children: <Widget>[
                                      Container(
                                        width: 50,
                                        height: 50,
                                        child: OutlineButton(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(25.0)),
                                          onPressed: () {
                                            showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return BackdropFilter(
                                                    filter: ImageFilter.blur(
                                                        sigmaX: 4, sigmaY: 4),
                                                    child: AlertDialog(
                                                      contentPadding:
                                                          EdgeInsets.all(0),
                                                      title: Text(
                                                          'Select your emoji'),
                                                      content:
                                                          SingleChildScrollView(
                                                        dragStartBehavior:
                                                            DragStartBehavior
                                                                .start,
                                                        scrollDirection:
                                                            Axis.horizontal,
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: <Widget>[
                                                            EmojiPicker(
                                                                rows: 4,
                                                                columns: 8,
                                                                bgColor: Colors
                                                                    .transparent,
                                                                onEmojiSelected:
                                                                    changeEmoji),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                });
                                          },
                                          textColor: Colors.blue,
                                          borderSide:
                                              BorderSide(color: Colors.blue),
                                          child: Text(_pickedEmoji),
                                        ),
                                      ),
                                      RaisedButton(
                                        elevation: 3.0,
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return BackdropFilter(
                                                filter: ImageFilter.blur(
                                                    sigmaX: 4, sigmaY: 4),
                                                child: AlertDialog(
                                                  title: Text('Select a color'),
                                                  content:
                                                      SingleChildScrollView(
                                                    child: BlockPicker(
                                                      pickerColor: _pickerColor,
                                                      onColorChanged:
                                                          changeColor,
                                                      availableColors:
                                                          availableColors,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                        child: const Text('Color'),
                                        color: _pickerColor,
                                        textColor:
                                            useWhiteForeground(_pickerColor)
                                                ? const Color(0xffffffff)
                                                : const Color(0xff000000),
                                      ),
                                      OutlineButton(
                                        onPressed: () {
                                          if (players.length >=
                                              maximumPlayers) {
                                            Scaffold.of(context)
                                                .hideCurrentSnackBar();
                                            Scaffold.of(context).showSnackBar(
                                                SnackBar(
                                                    content: Text(
                                                        "Can not add more players")));
                                          } else {
                                            gameState.addPlayer(
                                                _playerId,
                                                _pickedEmoji,
                                                nameController.text,
                                                _pickerColor,
                                                _isAi);
                                            setState(() {
                                              _playerId += 1;
                                            });
                                            FocusScope.of(context)
                                                .requestFocus(new FocusNode());

                                            nameController.clear();
                                            _pickerColor = null;
                                            _pickedEmoji = null;
                                            _listKey.currentState.insertItem(0);
                                          }
                                        },
                                        textColor: Colors.blue,
                                        borderSide:
                                            BorderSide(color: Colors.blue),
                                        child: Text("Add"),
                                      )
                                    ])),
                                  ),
                                ),
                              ]),
                              Expanded(
                                  child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    5.0, 15.0, 5.0, 15.0),
                                child: players != null
                                    ? AnimatedList(
                                        key: _listKey,
                                        initialItemCount: players.length,
                                        itemBuilder:
                                            (context, index, animation) {
                                          final player = players[index];
                                          return _buildItem(animation, player,
                                              index, gameState.removePlayer);
                                        },
                                      )
                                    : Text("No players",
                                        style: TextStyle(
                                            fontSize: 16,
                                            height: 8,
                                            color: Colors.grey)),
                              )),
                              RaisedButton(
                                color: buttonColor,
                                onPressed: () {
                                  FocusScope.of(context)
                                      .requestFocus(new FocusNode());
                                  Scaffold.of(context).hideCurrentSnackBar();
                                  if (players.length < minimumPlayers) {
                                    Scaffold.of(context).showSnackBar(SnackBar(
                                        content: Text("Needs at least " +
                                            minimumPlayers.toString() +
                                            " players to start")));
                                  } else {
                                    gameState.startGame(
                                        widget.gameMode, _playTutorial);
                                    Navigator.pop(context, null);
                                  }
                                },
                                child: Text(
                                  "Start",
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )));
  }

  Widget _buildItem(Animation<double> animation, Player player, int index,
      Function removePlayerCallback) {
    return SizeTransition(
      sizeFactor: animation,
      child: Dismissible(
        key: Key(player.id.toString()),
        onDismissed: (direction) {
          removePlayerCallback(player);
          //fungerar tills jag tar bort lite flera eller någon mitt i? är nog index variabeln som är fel.
          _listKey.currentState.removeItem(
              index,
              (BuildContext context, Animation<double> animation) =>
                  Container(),
              duration: const Duration(milliseconds: 250));
        },
        background: Container(color: Colors.deepOrange.shade300),
        child: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: [0, 0.25, 0.5, 0.75, 1],
            colors: [
              player.color.withOpacity(0),
              player.color.withOpacity(0.4),
              player.color.withOpacity(0.5),
              player.color.withOpacity(0.4),
              player.color.withOpacity(0)
            ],
          )),
          child: ListTile(
            title: Text(player.name),
            leading: Text(player.emoji),
          ),
        ),
      ),
    );
  }

  void _onSwitchChanged(bool value) {
    setState(() => _playTutorial = value);
  }

  void changeColor(Color value) {
    setState(() => _pickerColor = value);
    Navigator.pop(context, null);
  }

  void changeEmoji(Emoji value, var category) {
    setState(() => _pickedEmoji = value.emoji);
    Navigator.pop(context, null);
  }

  void _aiChanged(bool value) => setState(() => _isAi = value);
}
