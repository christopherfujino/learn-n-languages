exception Scanner_error of string

let zero_code = Char.code '0'

module type Scanner_type = sig
  val input : string
end

module Make (T : Scanner_type) = struct
  let input_len = String.length T.input

  let fail tokens idx msg =
    let tokens_str =
      let reverse_tokens = List.rev tokens in
      List.fold_left
        (fun acc cur -> acc ^ Token.to_s cur ^ " ")
        "" reverse_tokens
    in
    let msg' =
      Printf.sprintf "%s at idx = %d with remaining %s after scanning %s" msg
        idx
        (String.sub T.input idx (input_len - idx))
        tokens_str
    in
    raise (Scanner_error msg')

  let scan_whitespace idx =
    let first_char = String.get T.input idx in
    match first_char with ' ' | '\t' | '\n' -> Some (idx + 1) | _ -> None

  let scan_pattern pattern token idx =
    let pattern_len = String.length pattern in
    if pattern_len > String.length T.input - idx then None
    else
      let maybe_match =
        try String.sub T.input idx pattern_len
        with Invalid_argument _ ->
          failwith
            (Printf.sprintf "%s -> %s -> %d -> %d" T.input pattern pattern_len
               idx)
      in
      if maybe_match = pattern then Some (token, idx + pattern_len) else None

  let scan_true = scan_pattern "true" Token.TRUE
  let scan_false = scan_pattern "false" Token.FALSE
  let scan_null = scan_pattern "null" Token.NULL
  let scan_open_curly = scan_pattern "{" Token.OPEN_CURLY
  let scan_close_curly = scan_pattern "}" Token.CLOSE_CURLY
  let scan_open_bracket = scan_pattern "[" Token.OPEN_BRACKET
  let scan_close_bracket = scan_pattern "]" Token.CLOSE_BRACKET
  let scan_comma = scan_pattern "," Token.COMMA
  let scan_colon = scan_pattern ":" Token.COLON

  let scan_digit idx =
    if idx >= input_len then None
    else
      let first_char = String.get T.input idx in
      if first_char >= '0' && first_char <= '9' then
        let first_char_code = Char.code first_char in
        Some (first_char_code - zero_code)
      else None

  let rec scan_number_inner idx previous =
    let digit_opt = scan_digit idx in
    match digit_opt with
    | None -> previous
    | Some d ->
        let current_int =
          match previous with None -> d | Some (p, _) -> (p * 10) + d
        in
        let current_tuple = Some (current_int, idx + 1) in
        (scan_number_inner [@tailcall]) (idx + 1) current_tuple

  (* TODO support floats, scientific *)
  let scan_number idx =
    let value_opt = scan_number_inner idx None in
    match value_opt with
    | None -> None
    | Some (value, idx) -> Some (Token.NUMBER (Float.of_int value), idx)

  (* TODO support escape codes *)
  let rec scan_char buf idx =
    if idx >= input_len then failwith "reached EOF while parsing a String"
    else
      let cur_char = String.get T.input idx in
      if cur_char = '"' then (Token.STRING (Buffer.contents buf), idx + 1)
      else (
        Buffer.add_char buf cur_char;
        (scan_char [@tailcall]) buf (idx + 1))

  let scan_string idx =
    if String.get T.input idx == '"' then
      let buf = Buffer.create 16 in
      Some (scan_char buf (idx + 1))
    else None

  let rec scan_inner idx tokens =
    if input_len = idx then Token.EOF :: tokens
    else
      match scan_whitespace idx with
      | Some idx' -> (scan_inner [@tailcall]) idx' tokens
      | _ -> (
          (* Note, the first character here determines associativity, we want left
             association *)
          let ( >|| ) first fallback =
            match first with Some _ as v -> v | None -> fallback idx
          in
          let res =
            scan_true idx >|| scan_false >|| scan_null >|| scan_open_curly
            >|| scan_close_curly >|| scan_open_bracket >|| scan_close_bracket
            >|| scan_comma >|| scan_colon >|| scan_number >|| scan_string
          in
          match res with
          | Some (t, i) -> (scan_inner [@tailcall]) i (t :: tokens)
          | None -> fail tokens idx "failed to scan a token")

  (* Reverse to pay a one-time O(n) cost *)
  let scan () = scan_inner 0 [] |> List.rev
end
