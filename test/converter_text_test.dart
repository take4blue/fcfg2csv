import 'package:fcfg2csv/data/Converter.dart';
import 'package:test/test.dart';

void main() {
  var epsilon = 0.0001;
  test('toHexDigit', () {
    expect(Convert.toHexDigit("0"), 0);
    expect(Convert.toHexDigit("9"), 9);
    expect(Convert.toHexDigit("A"), 10);
    expect(Convert.toHexDigit("F"), 15);
    expect(Convert.toHexDigit("a"), 10);
    expect(Convert.toHexDigit("f"), 15);
    expect(Convert.toHexDigit("@"), -1);
    expect(Convert.toHexDigit("G"), -1);
    expect(Convert.toHexDigit("/"), -1);
    expect(Convert.toHexDigit(":"), -1);
    expect(Convert.toHexDigit("`"), -1);
    expect(Convert.toHexDigit("g"), -1);
  });

  test('unescapeString', () {
    expect(Convert.unescapeString("a"), equals(<int>[0x61]));
    expect(Convert.unescapeString(r"\"), equals(<int>[]));
    expect(Convert.unescapeString(r"\0"), equals(<int>[0x00]));
    expect(Convert.unescapeString(r"\f"), equals(<int>[0x0C]));
    expect(Convert.unescapeString(r"\a"), equals(<int>[0x07]));
    expect(Convert.unescapeString(r"\r"), equals(<int>[0x0D]));
    expect(Convert.unescapeString(r"\x1"), equals(<int>[0x01]));
    expect(Convert.unescapeString(r"\x01"), equals(<int>[0x01]));
    expect(Convert.unescapeString(r"\x10"), equals(<int>[0x10]));
    expect(Convert.unescapeString(r"\x00"), equals(<int>[0x00]));
    expect(Convert.unescapeString(r"\xFF"), equals(<int>[0xff]));
    expect(Convert.unescapeString(r"\xff"), equals(<int>[0xff]));
    expect(Convert.unescapeString(r"\x1\xFF"), equals(<int>[0x01, 0xff]));
    expect(Convert.unescapeString(r"\x1\0"), equals(<int>[0x01, 0x00]));
    expect(Convert.unescapeString(r"\x1u"), equals(<int>[0x01, 0x75]));
  });

  test('escapeStringToDouble', () {
    expect(Convert.escapeStringToDouble('').isNaN, isTrue);
    expect(Convert.escapeStringToDouble('0000000').isNaN, isTrue);
    expect(Convert.escapeStringToDouble('000000000').isNaN, isTrue);
    expect(Convert.escapeStringToDouble(r'\0\0\0\0\0\0\0\0'), equals(0.0));
    expect(Convert.escapeStringToDouble(r'\0\0\0\x87?\xe0\0\0'),
        closeTo(1.75, epsilon));
    expect(Convert.escapeStringToDouble(r'\0\0\0\x87>\xcc\xcc\xcd'),
        closeTo(0.4, epsilon));
    expect(Convert.escapeStringToDouble(r'\0\0\0\x87\x43\x66\0\0'),
        closeTo(230.0, epsilon));
    expect(Convert.escapeStringToDouble(r'\0\0\0\x87>\xcc\xcc\xcd'),
        closeTo(0.4, epsilon));
    expect(Convert.escapeStringToDouble(r'\0\0\0\x87>\x5\x1e\xb8'),
        closeTo(0.13, epsilon));
  });

  test('convert', () {
    expect(Convert.convert(r"""[Custom]
machineId=9
nozzleSize=@Variant(\0\0\0\x87>\xcc\xcc\xcd)
[General]
extruderTemp0=@Variant(\0\0\0\x87\x43R\0\0)
baseSpeed="@Variant(\0\0\0\x87\x42p\0\0)"
fillLayerDensitys=[]
layerPauses=[]"""), equals('''[Custom]
machineId,9
nozzleSize,0.4
[General]
extruderTemp0,210
baseSpeed,60
fillLayerDensitys,"[]"
layerPauses,"[]"
'''));
  });
}
