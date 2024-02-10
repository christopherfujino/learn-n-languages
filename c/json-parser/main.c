#include <assert.h>
#include <signal.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/errno.h>
#include <sys/types.h>
#include <unistd.h>

#include "json_parser.h"

const char *programSource = "\
{\
  \"K1\": {\
    \"nested\": null\
  },\
  \"k2\": \"value\",\
  \"bool\": [\
    true, false, 1\
  ]\
}";

int main() {
  ssize_t i;
  TokenNode *listHead = NULL;
  TokenNode *listCurrent = NULL;

  FILE *program =
      fmemopen((void *)programSource, (size_t)strlen(programSource), "r");

  // scan
  while (true) {
    OptionalToken optToken = scanToken(program);
    if (!optToken.some) {
      // end of file
      break;
    }
    TokenNode *nextNode = (TokenNode *)malloc(sizeof(TokenNode));
    if (listHead == NULL) {
      listHead = nextNode;
    } else {
      listCurrent->next = nextNode;
    }
    listCurrent = nextNode;
    listCurrent->token = optToken.value.some;
    listCurrent->next = NULL;
  }

  // parse
  listCurrent = listHead;

  ParserValue *doc = parseObject(&listCurrent);

  printValue(doc);

  return 0;
}

OptionalToken scanToken(FILE *input) {
  struct FgetcResult result;
  char current;
  while (true) {
    result = wrappedFgetc(input);
    switch (result.type) {
    case FGETC_EOF:
      return (OptionalToken){
          .some = false,
          .value.none = 0,
      };
    case FGETC_ERROR:
      fprintf(stderr, "Received error %s\n", result.value.error);
      exit(1);
    case FGETC_CHAR:
      current = result.value.char_val;
    }

    if (current == '{')
      return (OptionalToken){
          .some = true,
          .value.some = OPEN_CURLY,
      };
    else if (current == '}')
      return (OptionalToken){
          .some = true,
          .value.some = CLOSE_CURLY,
      };
    else if (current == '[')
      return (OptionalToken){
          .some = true,
          .value.some = OPEN_BRACKET,
      };
    else if (current == ']')
      return (OptionalToken){
          .some = true,
          .value.some = CLOSE_BRACKET,
      };
    else if (current == ':')
      return (OptionalToken){
          .some = true,
          .value.some = COLON,
      };
    else if (current == ',')
      return (OptionalToken){
          .some = true,
          .value.some = COMMA,
      };
    else if (current >= '0' && current <= '9') {
      // push current back to the front of input
      ungetc(current, input);
      return scanNumber(input);
    } else if (current == 't') {
      if (!assertString(input, "rue")) {
        fprintf(stderr, "Expected \"true\", but got else\n");
        raise(SIGABRT);
      }
      return (OptionalToken){
          .some = true,
          .value.some = TRUE_TYPE,
      };
    } else if (current == 'f') {
      if (!assertString(input, "alse")) {
        fprintf(stderr, "Expected \"false\", but got else\n");
        raise(SIGABRT);
      }
      return (OptionalToken){
          .some = true,
          .value.some = FALSE_TYPE,
      };
    } else if (current == 'n') {
      if (!assertString(input, "ull")) {
        fprintf(stderr, "Expected \"null\" but got else\n");
        raise(SIGABRT);
      }
      return (OptionalToken){
          .some = true,
          .value.some = NULL_TYPE,
      };
    } else if (current == '"')
      return scanString(input);
    else if (current == ' ' || current == '\t' || current == '\n') {
      continue;
    }
    fprintf(stderr, "UNIMPLEMENTED ASCII %d\n", current);
    exit(1);
  }
}

OptionalToken scanNumber(FILE *input) {
  char current;
  struct FgetcResult result;
  double val = 0;
  while (true) {
    result = wrappedFgetc(input);
    switch (result.type) {
    case FGETC_EOF:
      return (OptionalToken){
          .some = false,
          .value.none = 0,
      };
    case FGETC_ERROR:
      fprintf(stderr, "Received error %s\n", result.value.error);
      exit(1);
    case FGETC_CHAR:
      current = result.value.char_val;
    }

    if (current < '0' || current > '9') {
      ungetc(current, input);
      return (OptionalToken){
          .some = true,
          .value.some =
              (Token){
                  .type = NUMBER,
                  .value.numVal = val,
              },
      };
    }

    val = (val * 10) + current - '0';
  }
}

OptionalToken scanString(FILE *input) {
  size_t bufferSize = 64;
  char *buffer = (char *)malloc(bufferSize);
  int buffer_index = 0;
  struct FgetcResult result;
  char current;

  while (true) {
    result = wrappedFgetc(input);
    switch (result.type) {
    case FGETC_EOF:
      return (OptionalToken){
          .some = false,
          .value.none = 0,
      };
    case FGETC_ERROR:
      fprintf(stderr, "Received error %s\n", result.value.error);
      exit(1);
    case FGETC_CHAR:
      current = result.value.char_val;
    }
    if (current == '"') {
      // add 1 for trailing \0
      char *output = (char *)malloc(buffer_index + 2);
      memcpy(output, buffer, buffer_index + 2);
      output[buffer_index + 1] = '\0'; // is this math right?
      free(buffer);

      return (OptionalToken){
          .some = true,
          .value.some =
              (Token){
                  .type = STRING,
                  .value.stringVal = output,
              },
      };
    }
    buffer[buffer_index] = current;
    buffer_index += 1;
    if (buffer_index >= bufferSize) {
      size_t nextBufferSize = bufferSize * 2;
      printf("Re-sizing buffer from %ld -> %ld\n", bufferSize, nextBufferSize);
      char *nextBuffer = (char *)malloc(nextBufferSize);
      memcpy(nextBuffer, buffer, bufferSize);
      bufferSize = nextBufferSize;
      free(buffer);
      buffer = nextBuffer;
    }
  }
}

FgetcResult wrappedFgetc(FILE *input) {
  ssize_t i = fgetc(input);
  if (i == EOF) {
    int isEof = feof(input);
    if (isEof) {
      return (FgetcResult){
          .type = FGETC_EOF,
          .value.eof = EOF,
      };
    }
    return (FgetcResult){
        .type = FGETC_ERROR,
        .value.error = "Foo Bar",
    };
  }
  assert(i >= 0);
  assert(i <= 255);
  return (FgetcResult){
      .type = FGETC_CHAR,
      .value.char_val = i,
  };
}

bool assertString(FILE *input, const char *pattern) {
  // add 1 for trailing null
  size_t bufferLen = strlen(pattern) + 1;
  char *buffer = (char *)malloc(bufferLen);
  fgets(buffer, bufferLen, input);
  int cmp = strcmp(buffer, pattern);
  free(buffer);
  return cmp == 0;
}

void printToken(Token token) {
  // TODO leverage tokenTypeToString
  switch (token.type) {
  case OPEN_CURLY:
    printf("OPEN_CURLY\n");
    break;
  case CLOSE_CURLY:
    printf("CLOSE_CURLY\n");
    break;
  case OPEN_BRACKET:
    printf("OPEN_BRACKET\n");
    break;
  case CLOSE_BRACKET:
    printf("CLOSE_BRACKET\n");
    break;
  case STRING:
    printf("STRING (\"%s\")\n", token.value.stringVal);
    break;
  case COLON:
    printf("COLON\n");
    break;
  case NUMBER:
    printf("NUMBER (%f)\n", token.value.numVal);
    break;
  case COMMA:
    printf("COMMA\n");
    break;
  case NULL_TYPE:
    printf("NULL_TYPE\n");
    break;
  case TRUE_TYPE:
    printf("TRUE_TYPE\n");
    break;
  case FALSE_TYPE:
    printf("FALSE_TYPE\n");
    break;
  }
}

/** Singleton for null. */
ParserValue nullValue = {
    .type = NULL_P,
    .value.none = 0,
};

/** Singleton for true. */
ParserValue trueValue = {
    .type = TRUE_P,
    .value.none = 0,
};

/** Singleton for false. */
ParserValue falseValue = {
    .type = FALSE_P,
    .value.none = 0,
};

ParserValue *parseValue(TokenNode **nodePtrPtr) {
  TokenNode node = **nodePtrPtr;
  TokenValue value;
  ParserValue *retValue = NULL;

  switch (node.token.type) {
  case OPEN_CURLY:
    return parseObject(nodePtrPtr);
  case OPEN_BRACKET:
    return parseArray(nodePtrPtr);
  case STRING:
    value = consumeToken(nodePtrPtr, STRING);
    retValue = (ParserValue *)malloc(sizeof(ParserValue));
    *retValue = (ParserValue){
        .type = STRING_P,
        .value.stringVal = value.stringVal,
    };
    return retValue;
  case NULL_TYPE:
    consumeToken(nodePtrPtr, NULL_TYPE);
    return &nullValue;
  case TRUE_TYPE:
    consumeToken(nodePtrPtr, TRUE_TYPE);
    return &trueValue;
  case FALSE_TYPE:
    consumeToken(nodePtrPtr, FALSE_TYPE);
    return &falseValue;
  case NUMBER:
    value = consumeToken(nodePtrPtr, NUMBER);
    retValue = (ParserValue *)malloc(sizeof(ParserValue));
    *retValue = (ParserValue){
        .type = NUMBER_P,
        .value.numVal = value.numVal,
    };
    return retValue;
  default:
    fprintf(stderr, "Unexpected token %s\n",
            tokenTypeToString(node.token.type));
    raise(SIGABRT);
    exit(42);
  }
}

ParserValue *parseObject(TokenNode **nodePtrPtr) {
  KeyValuePairNode_p *headKVP = NULL;
  KeyValuePairNode_p *currentKVP = NULL;
  consumeToken(nodePtrPtr, OPEN_CURLY);
  while ((*nodePtrPtr)->token.type != CLOSE_CURLY) {
    KeyValuePairNode_p *nextKVP =
        (KeyValuePairNode_p *)malloc(sizeof(KeyValuePairNode_p));
    if (headKVP == NULL) {
      headKVP = nextKVP;
    } else {
      currentKVP->next = nextKVP;
    }
    currentKVP = nextKVP;
    currentKVP->value.key = consumeToken(nodePtrPtr, STRING).stringVal;
    consumeToken(nodePtrPtr, COLON);
    currentKVP->value.value = parseValue(nodePtrPtr);
    currentKVP->next = NULL;
    if ((*nodePtrPtr)->token.type == COMMA) {
      consumeToken(nodePtrPtr, COMMA);
      if ((*nodePtrPtr)->token.type == CLOSE_CURLY) {
        fprintf(stderr, "Expected another key after a comma in an object\n");
        raise(SIGABRT);
      }
    } else {
      break;
    }
  }
  consumeToken(nodePtrPtr, CLOSE_CURLY);

  ParserValue *retValue = (ParserValue *)malloc(sizeof(ParserValue));
  *retValue = (ParserValue){
      .type = OBJECT_P,
      .value.keyValuePairs = headKVP,
  };
  return retValue;
}

ParserValue *parseArray(TokenNode **nodePtrPtr) {
  ParserValueNode_p *headValue = NULL;
  ParserValueNode_p *currentValue = NULL;
  consumeToken(nodePtrPtr, OPEN_BRACKET);
  while ((*nodePtrPtr)->token.type != CLOSE_BRACKET) {
    ParserValueNode_p *nextValue =
        (ParserValueNode_p *)malloc(sizeof(ParserValueNode_p));
    if (headValue == NULL) {
      headValue = nextValue;
    } else {
      currentValue->next = nextValue;
    }
    currentValue = nextValue;
    currentValue->value = parseValue(nodePtrPtr);
    currentValue->next = NULL;
    if ((*nodePtrPtr)->token.type == COMMA) {
      consumeToken(nodePtrPtr, COMMA);
      if ((*nodePtrPtr)->token.type == CLOSE_CURLY) {
        fprintf(stderr, "Expected another key after a comma in an object\n");
        raise(SIGABRT);
      }
    } else {
      break;
    }
  }
  consumeToken(nodePtrPtr, CLOSE_BRACKET);

  ParserValue *retValue = (ParserValue *)malloc(sizeof(ParserValue));
  assert(headValue != NULL);
  *retValue = (ParserValue){
      .type = ARRAY_P,
      .value.array = headValue,
  };
  return retValue;
}

TokenValue consumeToken(TokenNode **nodePtrPtr, enum TokenType type) {
  TokenNode node = **nodePtrPtr;
  if (node.token.type != type) {
    fprintf(stderr, "Expected a %s but got a %s\n", tokenTypeToString(type),
            tokenTypeToString(node.token.type));
    raise(SIGABRT);
  }
  *nodePtrPtr = (*nodePtrPtr)->next;

  return node.token.value;
}

const char *tokenTypeToString(enum TokenType type) {
  switch (type) {
  case OPEN_CURLY:
    return "OPEN_CURLY";
  case CLOSE_CURLY:
    return "CLOSE_CURLY";
  case OPEN_BRACKET:
    return "OPEN_BRACKET";
  case CLOSE_BRACKET:
    return "CLOSE_BRACKET";
  case STRING:
    return "STRING";
  case COLON:
    return "COLON";
  case NUMBER:
    return "NUMBER";
  case COMMA:
    return "COMMA";
  case NULL_TYPE:
    return "NULL_TYPE";
  case TRUE_TYPE:
    return "TRUE_TYPE";
  case FALSE_TYPE:
    return "FALSE_TYPE";
  }
}

void printValue(ParserValue *value) {
  ParserValueNode_p *arrayElement = NULL;
  KeyValuePairNode_p *keyValuePairs = NULL;
  switch (value->type) {
  case STRING_P:
    printf("\"%s\"", value->value.stringVal);
    break;
  case NUMBER_P:
    printf("%f", value->value.numVal);
    break;
  case NULL_P:
    printf("null");
    break;
  case TRUE_P:
    printf("true");
    break;
  case FALSE_P:
    printf("false");
    break;
  case ARRAY_P:
    printf("[");
    arrayElement = value->value.array;
    if (arrayElement != NULL) {
      printValue(arrayElement->value);
      arrayElement = arrayElement->next;
      while (arrayElement) {
        printf(",");
        printValue(arrayElement->value);
        arrayElement = arrayElement->next;
      }
    }
    printf("]");
    break;
  case OBJECT_P:
    printf("{");
    keyValuePairs = value->value.keyValuePairs;
    if (keyValuePairs != NULL) {
      printf("\"%s\":", keyValuePairs->value.key);
      printValue(keyValuePairs->value.value);

      keyValuePairs = keyValuePairs->next;
      while (keyValuePairs) {
        printf(",");
        printf("\"%s\":", keyValuePairs->value.key);
        printValue(keyValuePairs->value.value);

        keyValuePairs = keyValuePairs->next;
      }
    }
    printf("}");
    break;
  default:
    fprintf(stderr, "yikes\n");
    raise(SIGABRT);
  }
}
