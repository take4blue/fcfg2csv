import 'dart:typed_data';

class Convert {
  // FlashPrintのパラメータ形式をCSV形式に変換する
  static String convert(String value) {
    // 数値の後方0を取り除くもの
    RegExp trailingZeroSuppress = RegExp(r'([.]*0+)(?!.*\d)');

    // 変換処理本体
    var lines = value.split('\n');
    var result = "";
    for (var line in lines) {
      // 1行分の処理
      // =がない場合はそのまま出力。=がある場合は=を,に置き換えて@Variant内のエスケープ文字を32ビット浮動小数点に変換して出力する
      var equalPos = line.indexOf('=');
      if (equalPos == -1) {
        result += line + '\n';
      } else {
        var words = <String>[];
        words.add(line.substring(0, equalPos));
        words.add(line.substring(equalPos + 1));
        result += words[0] + ',';
        if (words[1].contains("@Variant")) {
          // ()内のエスケープ文字を取り出して32ビット浮動小数点に変換し出力
          var start = words[1].indexOf('(') + 1;
          var end = words[1].indexOf(')');
          var view = escapeStringToDouble(words[1].substring(start, end));
          result +=
              view.toStringAsFixed(3).replaceAll(trailingZeroSuppress, '');
        } else if (words[1].contains('[')) {
          result += '"' + words[1] + '"';
        } else {
          result += words[1];
        }
        result += '\n';
      }
    }
    return result;
  }

  // 文字が16進数の文字かどうか判断し、もしそうなら数値化して返す
  static int toHexDigit(String s) {
    var ch = s.codeUnitAt(0);
    if ((ch ^ 0x30) <= 9) {
      return ch ^ 0x30;
    } else if ((ch ^ 0x40) <= 6 && (ch ^ 0x40) > 0) {
      return (ch ^ 0x40) + 9;
    } else if ((ch ^ 0x60) <= 6 && (ch ^ 0x60) > 0) {
      return (ch ^ 0x60) + 9;
    } else {
      return -1;
    }
  }

  // エスケープされた文字列とASCII文字列をUint8List形式に変換する
  static Uint8List unescapeString(String string) {
    var stringLength = string.length;
    var result = <int>[];
    for (var i = 0; i < stringLength; i++) {
      if (string[i] == r'\') {
        i++;
        if (i >= stringLength) {
          break;
        }
        if (string[i] == '0') {
          result.add(0x00);
        } else if (string[i] == 'f') {
          result.add(0x0C);
        } else if (string[i] == 'a') {
          result.add(0x07);
        } else if (string[i] == 'r') {
          result.add(0x0D);
        } else if (string[i] == 'x') {
          i++;
          if (i >= stringLength) {
            break;
          }
          var val = toHexDigit(string[i]);
          if (i + 1 < stringLength) {
            var nextnext = toHexDigit(string[i + 1]);
            if (nextnext >= 0) {
              i++;
              val = val * 16 + nextnext;
            }
          }
          result.add(val);
        }
      } else {
        result.add(string.codeUnitAt(i));
      }
    }
    return Uint8List.fromList(result);
  }

  // エスケープされたASCII文字列を32ビット浮動小数点として変換する
  static double escapeStringToDouble(String str) {
    var bytes = unescapeString(str);
    if (bytes.length == 8) {
      return ByteData.sublistView(bytes).getFloat32(4);
    } else {
      return double.nan;
    }
  }
}
