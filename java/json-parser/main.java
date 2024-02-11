import java.util.ArrayList;

class Main {
  public static final String program = "{\"key\": null}";
  public static void main(String[] args) {
    System.out.printf("Scanning %s\n", program);
    final Scanner scanner = new Scanner(program);
    final ArrayList<Token> tokens = scanner.scan();
    for (Token token : tokens) {
      System.out.printf("%s\n", token.toString());
    }
    System.out.println("Done");
  }
}

class EofException extends Exception {}

class Scanner {
  Scanner(String src) {
    source = src;
  }

  final String source;
  int index = 0;

  void incrementIndex(int i) throws EofException {
    index += i;
    if (index >= source.length()) {
      throw new EofException();
    }
  }

  char getCurrentChar() {
    return source.charAt(index);
  }

  StringToken scanString() throws EofException {
    final StringBuilder builder = new StringBuilder();
    // increment past double-quote
    incrementIndex(1);

    while (getCurrentChar() != '"') {
      builder.append(getCurrentChar());
      incrementIndex(1);
    }

    // increment past double-quote
    incrementIndex(1);

    return new StringToken(builder.toString());
  }

  ArrayList<Token> scan() {
    ArrayList<Token> tokens = new ArrayList<Token>();

    // TODO handle empty string
    char currentChar = getCurrentChar();

    while(true) {
      try {
        if (currentChar == '{') {
          // TODO use singleton pattern
          tokens.add(new OpenCurly());
        } else if (currentChar == '}') {
          tokens.add(new CloseCurly());
        } else if (currentChar == '"') {
          tokens.add(scanString());
        } else if (currentChar == 'n') {
          final String maybeNull = source.substring(index, index + 4);
          if (!maybeNull.equals("null")) {
            throw new Error("Expected \"null\" but got \"" + maybeNull + "\"");
          }
          tokens.add(new NullToken());
          incrementIndex(3);
        } else if (currentChar == ' ' || currentChar == '\n' || currentChar == '\t') {
          // skip whitespace
        } else {
          throw new Error("TODO implement scanning \"" + currentChar + "\"");
        }

        incrementIndex(1);
        if (index >= source.length()) {
          break;
        }
        currentChar = getCurrentChar();
      } catch (EofException e) {
        //e.printStackTrace(System.out);
        return tokens;
      }
    }

    throw new Error("Unreachable");
  }
}

interface Token {}

class OpenCurly implements Token {
  public String toString() {
    return "OpenCurly";
  }
}

class CloseCurly implements Token {
  public String toString() {
    return "CloseCurly";
  }
}

class StringToken implements Token {
  StringToken(String val) {
    value = val;
  }

  final String value;
  @Override

  public String toString() {
    return "StringToken (" + value + ")";
  }
}

class NullToken implements Token {
  public String toString() {
    return "NullToken";
  }
}
