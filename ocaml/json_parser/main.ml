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

  let build_num src num_val idx =
    let cur_char = String.get src idx in
    match cur_char with
    | '0' .. '9' ->
        let digit = int_of_char cur_char - int_of_char '0' in
        (num_val * 10) + digit
    | _ -> num_val

  let scan_num src idx num_val len = (Some (Number num_val), len + 1)

  let[@tail_mod_cons] rec scan src idx =
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

let tokens = Scanner.scan program 0

let () =
  List.iter (fun token -> token |> Scanner.to_string |> print_endline) tokens
