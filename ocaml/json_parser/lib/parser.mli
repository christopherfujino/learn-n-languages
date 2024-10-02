type expression =
  | Number of float
  | String of string
  | Null
  | Array of expression list
  | Map of (string * expression) list
  | Bool of bool

val parse : Token.t list -> expression

val print : expression -> unit
