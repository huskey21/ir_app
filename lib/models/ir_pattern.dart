abstract class IrPattern
{
  List<int> getPattern(String code);
}

abstract class LengthPattern extends IrPattern
{
  late int length;

  void _checkLength(String code)
  {
    if (length != code.length)
    {
      throw const FormatException("Wrong length of code");
    }
  }
}

class Sirc20 extends LengthPattern
{

  Sirc20()
  {
    length = 20;
  }

  @override
  List<int> getPattern(String code) {
    _checkLength(code);
    List<int> pattern = [];
    List<String> symbols = code.split('');
    for (String symbol in symbols)
    {
      if (symbol == "1")
      {
        pattern.addAll([1200,600]);
      }
      else if(symbol == "0")
      {
        pattern.addAll([600,600]);
      }
      else
      {
        return [-1];
      }
    }
    pattern = pattern.reversed.toList();
    pattern.insertAll(0, [2400,600]);
    return pattern;
  }
}

class Sirc15 extends Sirc20
{
  Sirc15()
  {
    length = 15;
  }
}

class Sirc12 extends Sirc20
{
  Sirc12()
  {
    length = 12;
  }
}

class Nec extends LengthPattern
{
  Nec()
  {
    length = 16;
  }

  @override
  List<int> getPattern(String code) {
    _checkLength(code);
    List<int> pattern = [9000,4500], head = [], body = [];
    List<String> symbols = code.split('');
    for (int i = 7; i >= 0; i--){
      List<int> result = _getCode(symbols[i]);
      if (result == [-1])
      {
        return result;
      }
      head.addAll(result);
    }
    for (int i = 15; i > 7; i--){
      List<int> result = _getCode(symbols[i]);
      if (result == [-1])
      {
        return result;
      }
      body.addAll(result);
    }

    pattern.addAll(head);
    pattern.addAll(_reversePattern(head));
    pattern.addAll(body);
    pattern.addAll(_reversePattern(body));
    pattern.add(560);
    return pattern;
  }

  List<int> _getCode(String code){
    if (code == "1")
    {
      return [560,1960];
    }
    else if(code == "0")
    {
      return [560,560];
    }
    else
    {
      return [-1];
    }
  }

  List<int> _reversePattern(List<int> pattern)
  {
    List<int> result = [];
    for (int i = 1; i < pattern.length; i+=2)
    {
      if (pattern[i] == 560)
      {
        result.addAll([560,1960]);
      }
      else
      {
        result.addAll([560,560]);
      }
    }
    return result;
  }
}

class ExtendedNec extends Nec
{
  ExtendedNec()
  {
    length = 24;
  }

  @override
  List<int> getPattern(String code) {
    _checkLength(code);
    _checkLength(code);
    List<int> pattern = [9000,4500], head = [], body = [];
    List<String> symbols = code.split('');
    for (int i = 15; i >= 0; i--){
      List<int> result = _getCode(symbols[i]);
      if (result == [-1])
      {
        return result;
      }
      head.addAll(result);
    }
    for (int i = 23; i > 15; i--){
      List<int> result = _getCode(symbols[i]);
      if (result == [-1])
      {
        return result;
      }
      body.addAll(result);
    }

    pattern.addAll(head);
    pattern.addAll(body);
    pattern.addAll(_reversePattern(body));
    pattern.add(560);
    return pattern;
  }
}
