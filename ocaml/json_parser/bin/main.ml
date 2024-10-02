open Json_from_scratch

module TestScanner = Scanner.Make (struct
  let input = "{\"str\":101,\"another string\":[1,2,3], \"bools\": [true, false]}"
end)

let () =
  let tokens = TestScanner.scan () in
  let tree = Parser.parse tokens in
  Parser.print tree
