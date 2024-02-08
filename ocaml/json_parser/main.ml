type token =
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

exception Foo of string

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

let rec build_string_buffer src buf idx =
  let cur_char = String.get src idx in
  (*
  Printf.printf "build_string_buffer scanned char %c\n" cur_char;
  *)
  if cur_char = '"' then buf
  else (
    Buffer.add_char buf cur_char;
    build_string_buffer src buf (idx + 1))

let scan_string src idx =
  let buf = build_string_buffer src (Buffer.create 20) idx in
  (*
  Printf.printf "scan_string scanned a \"%s\"\n" (Buffer.contents buf);
  *)
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
      | 'n' ->
          let maybe_null = String.sub src idx 4 in
          if maybe_null = "null" then (Some Null, 4)
          else raise (Foo (Printf.sprintf "Unknown token \"%s\"\n" maybe_null))
      | 't' ->
          let maybe_true = String.sub src idx 4 in
          if maybe_true = "true" then (Some True, 4)
          else raise (Foo (Printf.sprintf "Unknown token \"%s\"\n" maybe_true))
      | 'f' ->
          let maybe_false = String.sub src idx 5 in
          if maybe_false = "false" then (Some False, 5)
          else raise (Foo (Printf.sprintf "Unknown token \"%s\"\n" maybe_false))
      | _ -> raise (Foo (Printf.sprintf "%c at %d" character idx))
    in
    match token_opt with
    | None -> scan src (idx + len)
    | Some token -> token :: scan src (idx + len)

let tokens = scan program 0

let token_to_s = function
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

let rec print_tokens = function
  | [] -> ()
  | h :: t ->
      print_endline (token_to_s h);
      (print_tokens [@tailcall]) t

let () = print_tokens tokens
