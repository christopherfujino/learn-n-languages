#ifndef _JSON_PARSER_H
#define _JSON_PARSER_H

#include <stdio.h>
#include <sys/types.h>

/** A scanner token. */
enum TokenType {
  OPEN_CURLY,
  CLOSE_CURLY,
  OPEN_BRACKET,
  CLOSE_BRACKET,
  STRING,
  COLON,
  NUMBER,
  COMMA,
  NULL_TYPE,
  TRUE_TYPE,
  FALSE_TYPE,
};

const char *tokenTypeToString(enum TokenType type);

typedef union TokenValue {
  uint8_t none;
  char *stringVal;
  double numVal;
} TokenValue;

typedef struct Token {
  enum TokenType type;
  TokenValue value;
} Token;

enum FgetcResultType {
  FGETC_CHAR,
  FGETC_EOF,
  FGETC_ERROR,
};

typedef union FgetcResultValue {
  char char_val;
  char eof;
  char *error;
} FgetcResultValue;

typedef struct FgetcResult {
  enum FgetcResultType type;
  FgetcResultValue value;
} FgetcResult;

FgetcResult wrappedFgetc(FILE *input);

/** Linked list of Tokens */
typedef struct TokenNode {
  Token token;
  struct TokenNode *next;
} TokenNode;

union OptionalTokenValue {
  Token some;
  uint8_t none;
};

typedef struct OptionalToken {
  bool some;
  union OptionalTokenValue value;
} OptionalToken;

OptionalToken scanToken(FILE *input);

OptionalToken scanNumber(FILE *input);

OptionalToken scanString(FILE *input);

bool assertString(FILE *input, const char *pattern);

void printToken(Token type);

enum ParserType {
  STRING_P,
  NUMBER_P,
  NULL_P,
  OBJECT_P,
  ARRAY_P,
  TRUE_P,
  FALSE_P,
};

// Forward declaration
typedef struct ParserValue ParserValue;

typedef struct KeyValuePair_p {
  char *key;
  ParserValue *value;
} KeyValuePair_p;

typedef struct KeyValuePairNode_p {
  KeyValuePair_p value;
  struct KeyValuePairNode_p *next;
} KeyValuePairNode_p;

typedef struct ParserValueNode_p ParserValueNode_p;

/** Node in a linked list of ParserValues--or a JSON array. */
struct ParserValueNode_p {
  ParserValue *value;
  struct ParserValueNode_p *next;
};

struct ParserValue {
  enum ParserType type;
  union {
    char *stringVal;
    double numVal;
    uint8_t none;
    KeyValuePairNode_p *keyValuePairs;
    ParserValueNode_p *array;
  } value;
};

ParserValue *parseValue(TokenNode **nodePtrPtr);

ParserValue *parseObject(TokenNode **nodePtrPtr);

ParserValue *parseArray(TokenNode **nodePtrPtr);

TokenValue consumeToken(TokenNode **nodePtrPtr, enum TokenType type);

void printValue(ParserValue *value);

#endif // _JSON_PARSER_H
