type expression =
  | Number of float
  | String of string
  | Null
  | Array of expression list
  | Map of (string * expression) list
  | Bool of bool

exception Parse_error of string

let rec kvp_to_s tuple =
  let key, value = tuple in
  let value_s = to_s value in
  Printf.sprintf "\"%s\": %s" key value_s

and to_s = function
  | Number n -> Float.to_string n
  | String s -> Printf.sprintf "\"%s\"" s
  | Null -> "null"
  | Array elements ->
      let element_strings = List.map to_s elements in
      let inner_string =
        List.fold_left (fun acc s -> acc ^ s ^ ", ") "" element_strings
      in
      Printf.sprintf "[%s]" inner_string
  | Map l ->
      let kvp_strings = List.map kvp_to_s l in
      let inner_string =
        List.fold_left (fun acc s -> acc ^ s ^ ", ") "" kvp_strings
      in
      Printf.sprintf "{%s}" inner_string
  | Bool b -> if b then "true" else "false"

let fail tokens msg =
  let tokens_str =
    List.fold_left (fun acc cur -> acc ^ "\n" ^ Token.to_s cur) "" tokens
  in
  let msg' = Printf.sprintf "%s\n\n%s" msg tokens_str in
  raise (Parse_error msg')

let rec parse_object_inner tokens kvps =
  let key, value, tokens' = parse_kvp tokens in
  let tail = List.tl tokens' in
  let kvps' = (key, value) :: kvps in
  match List.hd tokens' with
  | Token.COMMA -> (parse_object_inner [@tailcall]) tail kvps'
  | Token.CLOSE_CURLY -> (kvps', tail)
  | token ->
      failwith
        (Printf.sprintf "unexpected token %s while parsing object"
           (Token.to_s token))

and parse_object tokens =
  assert (List.hd tokens == Token.OPEN_CURLY);
  let tail = List.tl tokens in
  match tail with
  | Token.CLOSE_CURLY :: tl -> (Map [], tl)
  | _ ->
      let kvps, tokens' = parse_object_inner tail [] in
      (Map (List.rev kvps), tokens')

and parse_array_inner tokens elements =
  let expr, tokens' = parse_expr tokens in
  let elements' = expr :: elements in
  let next_token = List.hd tokens' in
  match next_token with
  | Token.CLOSE_BRACKET -> (elements', List.tl tokens')
  | Token.EOF -> fail tokens' "unexpected EOF while parsing array"
  | Token.COMMA -> (parse_array_inner [@tailcall]) (List.tl tokens') elements'
  | _ -> fail tokens' "unexpected token while parsing array"

and parse_array tokens =
  assert (List.hd tokens == Token.OPEN_BRACKET);
  let tail = List.tl tokens in
  match tail with
  | Token.CLOSE_BRACKET :: tail' -> (Array [], tail')
  | _ ->
      let expressions, tokens = parse_array_inner tail [] in
      (Array (List.rev expressions), tokens)

and parse_string tokens =
  let hd = List.hd tokens in
  match hd with Token.STRING s -> Some (String s, List.tl tokens) | _ -> None

and parse_kvp tokens =
  let key_opt = parse_string tokens in
  match key_opt with
  | Some (String key, tokens') -> (
      match List.hd tokens' with
      | Token.COLON ->
          let tokens'' = List.tl tokens' in
          let value, tokens''' = parse_expr tokens'' in
          (key, value, tokens''')
      | _ -> failwith "Expected a colon after an object key")
  | _ -> fail tokens "Expected a string key in object"

and parse_expr tokens =
  match List.hd tokens with
  | Token.OPEN_CURLY -> parse_object tokens
  | Token.NUMBER n -> (Number n, List.tl tokens)
  | Token.OPEN_BRACKET -> parse_array tokens
  | Token.TRUE -> (Bool true, List.tl tokens)
  | Token.FALSE -> (Bool false, List.tl tokens)
  | _ -> fail tokens "TODO"

let parse tokens =
  let root, tokens = parse_object tokens in
  assert (tokens = [ Token.EOF ]);
  root

let print tree = to_s tree |> print_endline
