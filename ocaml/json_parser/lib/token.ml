type t =
  | TRUE
  | FALSE
  | NULL
  | STRING of string
  | NUMBER of float
  | OPEN_CURLY
  | CLOSE_CURLY
  | OPEN_BRACKET
  | CLOSE_BRACKET
  | COMMA
  | COLON
  | EOF

let to_s = function
  | TRUE -> "true"
  | FALSE -> "false"
  | NULL -> "null"
  | STRING s -> Printf.sprintf "String(%s)" s
  | NUMBER f -> Printf.sprintf "Number(%f)" f
  | OPEN_CURLY -> "{"
  | CLOSE_CURLY -> "}"
  | OPEN_BRACKET -> "["
  | CLOSE_BRACKET -> "]"
  | COMMA -> ","
  | COLON -> ":"
  | EOF -> "EOF"

