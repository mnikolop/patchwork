import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:patchwork/logic/bingoGameMechanics.dart';
import 'package:patchwork/utilities/constants.dart';
import 'package:patchwork/logic/defaultGameMechanics.dart';
import 'package:patchwork/logic/patchworkRuleEngine.dart';
import 'package:patchwork/models/announcement.dart';
import 'package:patchwork/models/board.dart';
import 'package:patchwork/models/lootBox.dart';
import 'package:patchwork/models/lootPrice.dart';
import 'package:patchwork/models/piece.dart';
import 'package:patchwork/models/player.dart';
import 'package:patchwork/models/square.dart';
import 'package:patchwork/models/timeBoard.dart';
import 'package:patchwork/utilities/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameState with ChangeNotifier {
  PatchworkRuleEngine _ruleEngine;
  double _boardTileSize;
  Player _currentPlayer;
  Board _currentBoard;
  Piece _draggedPiece;
  bool _extraPieceCollected;
  int _pieceMarkerIndex;
  List<Player> _players = [];
  TimeBoard _timeBoard;
  List<Piece> _gamePieces;
  List<Piece> _nextPieceList;
  String _view;
  bool _didPass;
  double _bottomHeight;
  Announcement _announcement;
  Player _previousPlayer;
  int _turnCounter;
  bool _recieveButtonsAnimation = false;
  Piece _stopedOnPiece;
  bool _bingoAnimation = false;
  LootBox _lootBox;
  GameMode _gameMode;
  GameState();

  getView() => _view;
  getTimeBoard() => _timeBoard;
  getCurrentPlayer() => _currentPlayer;
  getGamePieces() => _gamePieces;
  getPlayers() => _players;
  getBoardTileSize() => _boardTileSize;
  getExtraPieceCollected() => _extraPieceCollected;
  getDraggedPiece() => _draggedPiece;
  getCurrentBoard() => _currentBoard;
  getBottomHeight() => _bottomHeight;
  getAnnouncement() => _announcement;
  getPreviousPlayer() => _previousPlayer;
  getTurnCounter() => _turnCounter;
  getPieceMarkerIndex() => _pieceMarkerIndex;
  getButtonsAnimation() => _recieveButtonsAnimation;
  getBingoAnimation() => _bingoAnimation;
  getLootBox() => _lootBox;
  getGameMode() => _gameMode;
  double getPatchSelectorHeight() {
    return _bottomHeight - (_boardTileSize * 1.8);
  }

  void setBingoAnimation(bool bingoAnimation) {
    _bingoAnimation = bingoAnimation;
  }

  void setView(String view) {
    _view = view;
    notifyListeners();
  }

  List<Square> getShadow(Square boardTile) {
    List<Square> shadow = Utils.getBoardShadow(_draggedPiece, boardTile);
    return shadow;
  }

  void setDraggedPiece(Piece p) {
    _draggedPiece = p;
    notifyListeners();
  }

  void dropDraggedPiece() {
    _draggedPiece = null;
    notifyListeners();
  }

  void addPlayer(String name, Color color, bool isAi) {
    Player player = new Player(_players.length, name, color, isAi);
    _players.add(player);
    notifyListeners();
  }

  void removePlayer(Player player) {
    _players.removeWhere((p) => p.id == player.id);
    notifyListeners();
  }

  void restartApp() {
    _view = null;
    _players.clear();
    notifyListeners();
  }

  void setConstraints(double screenWidth, double screenHeight) {
    double maxSize = min(screenHeight * 0.6, screenWidth);

    double boardTileSpace = maxSize - (gameBoardInset * 2);
    _boardTileSize = boardTileSpace / defaultGameBoardCols;

    _bottomHeight = screenHeight -
        (maxSize + (gameBoardInset * 1)) -
        (_boardTileSize * 1.8);
  }

  void startQuickPlay() {
    Random rng = new Random();
    addPlayer(
        "Player 1", playerColors[rng.nextInt(playerColors.length)], false);
    List<Color> availablieColors =
        playerColors.where((c) => c != _players[0].color).toList();
    addPlayer("Player 2",
        availablieColors[rng.nextInt(availablieColors.length)], false);
    startGame(GameMode.DEFAULT);
  }

  void startGame(GameMode mode) {
    switch (mode) {
      case GameMode.DEFAULT:
        _ruleEngine = new DefaultGameMechanics();
        break;
      case GameMode.BINGO:
        _ruleEngine = new BingoGameMechanics();
        break;
      default:
        break;
    }
    _gameMode = mode;
    _view = "gameplay";
    _gamePieces = _ruleEngine.generatePieces(_players.length);
    _nextPieceList = _gamePieces;
    _timeBoard = _ruleEngine.initTimeBoard();
    _players = _ruleEngine.initPlayers(_players);
    _pieceMarkerIndex = 0;
    _turnCounter = 0;
    _currentPlayer = _players[0];
    _previousPlayer = _currentPlayer;
    _currentBoard = _currentPlayer.board;
    _extraPieceCollected = false;
    nextTurn();
    notifyListeners();
  }

  void setAnnouncement(Announcement announcement) {
    _announcement = announcement;
    notifyListeners();
  }

  void makeAnnouncement(String title, String text, AnnouncementType type) {
    setAnnouncement(new Announcement(title, Text(text), type));
  }

  void clearAnnouncement() {
    _announcement = null;
    //notifyListeners();
  }

  bool isValidPlacement(List<Square> placement) {
    bool isValid = _ruleEngine.validatePlacement(placement, _currentBoard);
    return isValid;
  }

  void rotatePiece(Piece piece) {
    Utils.rotatePiece(piece);
    notifyListeners();
  }

  void flipPiece(Piece piece) {
    Utils.flipPiece(piece);
    notifyListeners();
  }

  void putPiece(Piece piece, int x, int y) {
    for (int i = 0; i < piece.shape.length; i++) {
      Square square = piece.shape[i];
      square.x += x;
      square.y += y;
    }

    _draggedPiece = null;
    _currentBoard.addPiece(piece);
    _currentPlayer.buttons -= piece.cost;
    _pieceMarkerIndex = _gamePieces.indexWhere((p) => p.id == piece.id);

    _gamePieces.removeAt(_pieceMarkerIndex);
    _didPass = false;
    bool stop = _ruleEngine.piecePlaced(this);
    if (stop) {
      _currentPlayer.buttons += piece.cost;
      _stopedOnPiece = piece;
    } else {
      movePlayerPosition(piece.time);
    }
  }

  void handleBingo(List<int> bingos) {
    _bingoAnimation = true;
    LootBox lootBox = Utils.getLootBox(bingos.length);
    _currentPlayer.bingos.addAll(bingos);
    _lootBox = lootBox;
    notifyListeners();
  }

  void handleBingoAnimationEnd() {
    int moves = _stopedOnPiece.time;
    _bingoAnimation = false;
    LootPrice win =
        _lootBox.prices.firstWhere((p) => p.id == _lootBox.winningLootId);
    switch (win.type) {
      case LootType.CASH:
        _currentPlayer.buttons += win.amount * _lootBox.valueFactor;
        break;
      case LootType.TIME:
        moves -= win.amount * _lootBox.valueFactor;
        // _currentPlayer.position -= win.amount;
        break;
      default:
    }
    _currentPlayer.buttons -= _stopedOnPiece.cost;
    _lootBox = null;
    _stopedOnPiece = null;
    movePlayerPosition(moves);
  }

  void extraPiecePlaced(Piece piece, int x, int y) {
    for (int i = 0; i < piece.shape.length; i++) {
      Square square = piece.shape[i];
      square.x += x;
      square.y += y;
    }
    _extraPieceCollected = false;
    _draggedPiece = null;
    _didPass = false;
    _currentBoard.addPiece(piece);
    nextTurn();
    cleaPieceMarkerIndex(false);
  }

  void _finishGame() {
    _view = "finished";
    _players
        .forEach((player) => player.score = _ruleEngine.calculateScore(player));
    _announcement = null;
    notifyListeners();
  }

  void nextTurn() {
    _ruleEngine.endOfTurn(this);

    bool gameFinished = _ruleEngine.isGameFinished(_players);
    if (gameFinished) {
      _finishGame();
    }
    Player newPlayer = _ruleEngine.getNextPlayer(_players, _currentPlayer);

    if (newPlayer.id != _currentPlayer.id) {
      _turnCounter += 1;
      _previousPlayer = _currentPlayer;
    }
    _didPass = false;
    _currentPlayer = newPlayer;
    _currentBoard = _currentPlayer.board;

    //bryt ut ifsatsen nedan till en metod, finns på 3 ställen
    //
    placePieceMarker();
    notifyListeners();
  }

  void placePieceMarker() {
    if (_pieceMarkerIndex > -1) {
      List<Piece> cut = _gamePieces.sublist(0, _pieceMarkerIndex);
      List<Piece> newStart = _gamePieces.sublist(_pieceMarkerIndex);
      newStart.addAll(cut);
      _nextPieceList = newStart;
    }
    for (int i = 0; i < 3; i++) {
      Piece p = _nextPieceList[i];
      p.selectable = _ruleEngine.canSelectPiece(p, _currentPlayer);
    }
  }

  void clearAnimationButtons(bool goSleep) async {
    _recieveButtonsAnimation = false;
    _currentPlayer.buttons += _currentBoard.buttons;
    if (_extraPieceCollected) {
      notifyListeners();
    } else {
      nextTurn();
    }
  }

  void cleaPieceMarkerIndex(bool goSleep) async {
    if (goSleep) {
      await sleep(500);
    }
    _pieceMarkerIndex = -1;
    _gamePieces = _nextPieceList;
    notifyListeners();
  }

  Future sleep(int ms) async {
    return new Future.delayed(Duration(milliseconds: ms));
  }

  void movePlayerPosition(int moves) {
    int before = _currentPlayer.position;
    _currentPlayer.position += moves;
    int after = _currentPlayer.position;
    bool passedButton =
        _timeBoard.buttonIndexes.any((b) => b <= after && b > before);
    int passedPieceIndex = _timeBoard.pieceIndexes
        .firstWhere((b) => b <= after && b > before, orElse: () => -1);

    if (passedButton) {
      _recieveButtonsAnimation = true;
    }
    if (passedPieceIndex > 0) {
      _extraPieceCollected = true;
      _timeBoard.pieceIndexes.removeWhere((p) => p == passedPieceIndex);
    }

    if (after >= _timeBoard.goalIndex) {
      _currentPlayer.state = "finished";
      _currentPlayer.position = _timeBoard.goalIndex;
      setAnnouncement(new Announcement(
          "",
          Text(_currentPlayer.name + " crossed the goal line"),
          AnnouncementType.simpleDialog));
    }
    if (_extraPieceCollected) {
      placePieceMarker();
      cleaPieceMarkerIndex(false);
    } else if (_recieveButtonsAnimation) {
      placePieceMarker();
      notifyListeners();
    } else {
      nextTurn();
    }
  }

  void pass() {
    int nextPlayersPosition = _players
        .where((p) => p.id != _currentPlayer.id)
        .reduce((a, b) => a.position > b.position ? a : b)
        .position;
    int moves = (nextPlayersPosition - _currentPlayer.position) + 1;
    _currentPlayer.buttons += moves;
    _pieceMarkerIndex = -1;

    _didPass = true;

    movePlayerPosition(moves);
  }

  void _saveToPrefs(String key, String value) async {
    //https://pusher.com/tutorials/local-data-flutter
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
    print('saved $value');
  }

  void _readFromPrefs(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(key) ?? null;
    // _playerKey = value;

    //det är async så kan inte bara returnera rakt av. antingen sättar jag state här när det är klart
  }
}