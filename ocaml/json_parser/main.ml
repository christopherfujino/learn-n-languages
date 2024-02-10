let program =
  {|{
  "K1": {
    "nested": null
  },
  "k2": "value",
  "bool": [
    true, false, 1
  ]
}|}

module Scanner = struct
  exception Error of string

  type t =
    | OpenCurly
    | CloseCurly
    | OpenBracket
    | CloseBracket
    | String of string
    | Number of int
    | Colon
    | Null
    | Comma
    | True
    | False

  let to_string t =
    match t with
    | OpenCurly -> "OpenCurly"
    | CloseCurly -> "CloseCurly"
    | OpenBracket -> "OpenBracket"
    | CloseBracket -> "CloseBracket"
    | String s -> Printf.sprintf "String %s" s
    | Number i -> Printf.sprintf "Number %d" i
    | Colon -> "Colon"
    | Null -> "Null"
    | Comma -> "Comma"
    | True -> "True"
    | False -> "False"

  let rec build_string_buffer src buf idx =
    let cur_char = String.get src idx in
    if cur_char = '"' then buf
    else (
      Buffer.add_char buf cur_char;
      build_string_buffer src buf (idx + 1))

  let scan_string src idx =
    let buf = build_string_buffer src (Buffer.create 20) idx in
    (Some (String (Buffer.contents buf)), Buffer.length buf + 2)

  let rec scan_num src idx num_val len =
    let cur_char = String.get src idx in
    match cur_char with
    | '0' .. '9' ->
        let digit = int_of_char cur_char - int_of_char '0' in
        let num_val = (num_val * 10) + digit in
        scan_num src (idx + 1) num_val (len + 1)
    | _ -> (Some (Number num_val), len)

  let rec scan src idx =
    if idx >= String.length src then []
    else
      let character = String.get src idx in
      let validate_keyword word token =
        let word_len = String.length word in
        let maybe_word = String.sub src idx word_len in
        if maybe_word = word then (Some token, word_len)
        else raise (Error (Printf.sprintf "Unknown token \"%s\"\n" maybe_word))
      in
      let token_opt, len =
        match character with
        | '{' -> (Some OpenCurly, 1)
        | '}' -> (Some CloseCurly, 1)
        | '[' -> (Some OpenBracket, 1)
        | ']' -> (Some CloseBracket, 1)
        | '\n' -> (None, 1)
        | ' ' -> (None, 1)
        | '"' -> scan_string src (idx + 1)
        | '0' .. '9' -> scan_num src idx 0 0
        | ':' -> (Some Colon, 1)
        | ',' -> (Some Comma, 1)
        | 'n' -> validate_keyword "null" Null
        | 't' -> validate_keyword "true" True
        | 'f' -> validate_keyword "false" False
        | _ -> raise (Error (Printf.sprintf "%c at %d" character idx))
      in
      match token_opt with
      | None -> scan src (idx + len)
      | Some token -> token :: scan src (idx + len)
end

module Parser = struct
  exception Error of string

  type t =
    | String of string
    | Number of int
    | Null
    | True
    | False
    | Array of t list
    | Object of (string, t) Hashtbl.t

  let rec parse_kvp tokens table =
    match tokens with
    | Scanner.String key :: Scanner.Colon :: t -> (
        let value, t = parse_value t in
        Hashtbl.add table key value;
        match t with
        | Scanner.CloseCurly :: t -> t
        | Scanner.Comma :: t -> parse_kvp t table
        | _ -> raise (Error "foo bar baz"))
    | Scanner.String key :: t -> raise (Error "fuzzah")
    | [] -> raise (Error "reached end of tokens when object key expected")
    | a :: _ ->
        let a_str = Scanner.to_string a in
        let message =
          Printf.sprintf "Expected an object key but received %s" a_str
        in
        raise (Error message)

  and parse_object tokens table =
    match tokens with
    | [] -> raise (Error "reached end of tokens while parsing object")
    | h :: t -> (
        match h with
        | Scanner.CloseCurly -> (Object table, t)
        | _ ->
            let tail = parse_kvp tokens table in
            (Object table, tail))

  and parse_array_elements tokens (elements : t list) =
    match tokens with
    | [] -> raise (Error "reached end of tokens while parsing array")
    | _ -> (
        let value, t = parse_value tokens in
        let elements = elements @ (value :: []) in
        match t with
        | [] -> raise (Error "foo")
        | Scanner.Comma :: t -> parse_array_elements t elements
        | Scanner.CloseBracket :: t -> (elements, t)
        | h :: _ -> raise (Error "unexpected token while parsing array"))

  and parse_array tokens =
    match tokens with
    | [] -> raise (Error "reached end of tokens while parsing array")
    | h :: t -> (
        match h with
        | Scanner.CloseBracket -> (Array [], t)
        | Scanner.Comma -> raise (Error "An array cannot start with a comma")
        | token ->
            let elements, tail = parse_array_elements tokens [] in
            (Array elements, tail))

  and parse_value (tokens : Scanner.t list) =
    match tokens with
    | [] -> raise (Error "reached end of tokens while parsing value")
    | head :: tail -> (
        match head with
        | Scanner.OpenCurly -> parse_object tail (Hashtbl.create 3)
        | Scanner.OpenBracket -> parse_array tail
        | Scanner.String s -> (String s, tail)
        | Scanner.Number n -> (Number n, tail)
        | Scanner.Null -> (Null, tail)
        | Scanner.True -> (True, tail)
        | Scanner.False -> (False, tail)
        | token ->
            let token_s = Scanner.to_string token in
            let message =
              Printf.sprintf "Can't parse a %s to start a value" token_s
            in
            raise (Error message))

  and to_string = function
    | String s -> "\"" ^ s ^ "\""
    | Number i -> Printf.sprintf "%d" i
    | Null -> "null"
    | True -> "true"
    | False -> "false"
    | Array l -> (
        let strings = List.map to_string l in
        match strings with
        | [] -> "[]"
        | h :: t ->
            let builder acc cur = acc ^ ", " ^ cur in
            (* Fold from left to right, tail-recursive *)
            "[" ^ List.fold_left builder h t ^ "]")
    | Object obj -> (
        let builder acc tup =
          let k, v = tup in
          acc ^ ",\"" ^ k ^ "\":" ^ to_string v
        in
        let entry_seq = Hashtbl.to_seq obj in
        match entry_seq () with
        | Nil -> "{}"
        | Seq.Cons (h, t) ->
            let k, v = h in
            let first_string = Printf.sprintf "%s:%s" k (to_string v) in
            "{" ^ Seq.fold_left builder first_string t ^ "}")
end

let tokens = Scanner.scan program 0

let () =
  let obj, _ = Parser.parse_value tokens in
  Parser.to_string obj |> print_endline
