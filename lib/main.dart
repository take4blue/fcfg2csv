import 'package:fcfg2csv/data/Converter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'dart:io';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 以下の4行の定義はinternationalizationなもの
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

/// ファイルのメニュー操作
enum _FileMenu { importFile, exportFile }

class _MyHomePageState extends State<MyHomePage> {
  final _inputText = TextEditingController();
  final _outputText = TextEditingController();
  late DropzoneViewController controller;

  @override
  void dispose() {
    _inputText.dispose();
    _outputText.dispose();
    super.dispose();
  }

  /// FCFGパラメータからCSV形式に変換する。その処理を呼び出す。
  void _convert() {
    setState(() {
      _outputText.text = Convert.convert(_inputText.text);
    });
  }

  /// 入出力フィールドを初期化する
  void _clearInputText() {
    setState(() {
      _inputText.text = "";
      _outputText.text = "";
    });
  }

  /// 変換結果をクリップボードに入れる
  void _toClipboard() {
    if (_outputText.text.isNotEmpty) {
      final snack = SnackBar(content: Text(AppLocalizations.of(context)!.copy));
      final data = ClipboardData(text: _outputText.text);
      Clipboard.setData(data);
      ScaffoldMessenger.of(context).showSnackBar(snack);
    }
  }

  /// ファイルを読み込み、入力欄にデータを表示する。
  Future<void> _readFileFromDialog() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['fcfg'],
    );
    if (result != null) {
      final input = await File(result.files.single.path!).readAsString();
      setState(() {
        _inputText.text = input;
      });
    }
  }

  Future<void> _readFileFromDrop(dynamic ev) async {
    final bytes = await controller.getFileData(ev);
    final str = String.fromCharCodes(bytes);
    setState(() {
      _inputText.text = str;
    });
  }

  /// ファイルにデータを保存する
  Future<void> _writeFile() async {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: AppLocalizations.of(context)?.saveFileTitile,
      allowedExtensions: ['csv'],
      fileName: 'output-file.csv',
    );

    if (outputFile != null) {
      await File(outputFile).writeAsString(_outputText.text);
    }
  }

  /// アクションエリアの表示内容を作る
  /// Windows Nativeのみファイル入出力メニュー作る
  List<Widget> action(AppLocalizations message) {
    List<Widget> act = [
      IconButton(
        onPressed: () {
          _convert();
        },
        icon: const Icon(CupertinoIcons.square_arrow_right),
        tooltip: message.convert,
      ),
      IconButton(
        onPressed: () {
          _clearInputText();
        },
        icon: const Icon(CupertinoIcons.delete),
        tooltip: message.clear,
      ),
    ];
    if (!kIsWeb && Platform.isWindows) {
      // kIsWebでWEBアプリかどうか判断してからPlatformの呼び出しをしないとWEBの場合例外が出る
      act.add(PopupMenuButton<_FileMenu>(
          onSelected: (value) {
            switch (value) {
              case _FileMenu.importFile:
                _readFileFromDialog();
                break;
              case _FileMenu.exportFile:
                _writeFile();
                break;
            }
          },
          itemBuilder: (context) => <PopupMenuEntry<_FileMenu>>[
                PopupMenuItem<_FileMenu>(
                  value: _FileMenu.importFile,
                  child: Text(message.importFile),
                ),
                PopupMenuItem<_FileMenu>(
                  enabled: _outputText.text.isNotEmpty,
                  value: _FileMenu.exportFile,
                  child: Text(message.exportFile),
                ),
              ]));
    }
    return act;
  }

  /// body部分の作成
  Widget body(AppLocalizations message) {
    var col =
        Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
      const SizedBox(
        height: 5,
      ),
      Flexible(
        child: TextField(
          key: const Key('input'),
          expands: true,
          minLines: null,
          maxLines: null,
          controller: _inputText,
          decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: const UnderlineInputBorder(),
              hintText: (!kIsWeb) ? message.inTextHint : message.inTextHintWeb),
          keyboardType: TextInputType.multiline,
        ),
      ),
      const SizedBox(
        height: 5,
      ),
      Flexible(
        child: GestureDetector(
          key: const Key("longTapArea"),
          onLongPress: () => _toClipboard(),
          child: TextField(
            key: const Key('output'),
            expands: true,
            minLines: null,
            maxLines: null,
            readOnly: true,
            controller: _outputText,
            decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: message.outTextHint),
            keyboardType: TextInputType.multiline,
          ),
        ),
      ),
    ]);
    if (kIsWeb) {
      return Center(
          child: Stack(children: [
        DropzoneView(
          operation: DragOperation.copy,
          cursor: CursorType.grab,
          onCreated: (DropzoneViewController ctrl) => controller = ctrl,
          onDrop: (dynamic ev) => _readFileFromDrop(ev),
        ),
        col,
      ]));
    } else {
      return Center(
        child: col,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(message!.title), actions: action(message)),
      body: body(message),
    );
  }
}
