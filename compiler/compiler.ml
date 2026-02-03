(* compiler.ml
 * A reference Scheme compiler for the Compiler-Construction Course
 *
 * Programmer: Mayer Goldberg, 2025
 *)

(* Extensions:
 * (1) Paired comments: { ... }
 * (2) Interpolated strings: ~{<sexpr>}
 * (3) Support for entering the literal void-object: #void
 *)

#use "pc.ml";;

exception X_not_yet_implemented of string;;

let list_and_last =
  let rec run a = function
    | [] -> ([], a)
    | b :: s ->
       let (s, last) = run b s in
       (a :: s, last)
  in function
  | [] -> None
  | a :: s -> Some (run a s);;

let split_to_sublists n = 
  let rec run = function
    | ([], _, f) -> [f []]
    | (s, 0, f) -> (f []) :: (run (s, n, (fun s -> s)))
    | (a :: s, i, f) ->
       (run (s, i - 1, (fun s -> f (a :: s))))
  in function
  | [] -> []
  | s -> run (s, n, (fun s -> s));;

let rec gcd a b =
  match (a, b) with
  | (0, b) -> b
  | (a, 0) -> a
  | (a, b) -> gcd b (a mod b);;

type scm_number =
  | ScmInteger of int
  | ScmFraction of (int * int)
  | ScmReal of float;;

type sexpr =
  | ScmVoid
  | ScmNil
  | ScmBoolean of bool
  | ScmChar of char
  | ScmString of string
  | ScmSymbol of string
  | ScmNumber of scm_number
  | ScmVector of (sexpr list)
  | ScmPair of (sexpr * sexpr);;

module type READER = sig
  val nt_sexpr : sexpr PC.parser
end;; (* end of READER signature *)

module Reader : READER = struct
  open PC;;

  type string_part =
    | Static of string
    | Dynamic of sexpr;;

  let unitify nt = pack nt (fun _ -> ());;

  let make_maybe nt none_value =
    pack (maybe nt)
      (function
       | None -> none_value
       | Some(x) -> x);;  

  let rec nt_whitespace str =
    const (fun ch -> ch <= ' ') str
  and nt_end_of_line_or_file str = 
    let nt1 = unitify (char '\n') in
    let nt2 = unitify nt_end_of_input in
    let nt1 = disj nt1 nt2 in
    nt1 str
  and nt_line_comment str =
    let nt1 = char ';' in
    let nt2 = diff nt_any nt_end_of_line_or_file in
    let nt2 = star nt2 in
    let nt1 = caten nt1 nt2 in
    let nt1 = caten nt1 nt_end_of_line_or_file in
    let nt1 = unitify nt1 in
    nt1 str
  and nt_paired_comment str =
    let nt1 = diff (diff nt_any (one_of "{}")) nt_char in
    let nt1 = diff (diff nt1 nt_string) nt_paired_comment in
    let nt1 = unitify nt1 in
    let nt1 = disj nt1 (disj (unitify nt_char) (unitify nt_string)) in
    let nt1 = star (disj nt1 nt_paired_comment) in
    let nt1 = caten (char '{') (caten nt1 (char '}')) in
    let nt1 = unitify nt1 in
    nt1 str
  and nt_sexpr_comment str =
    let nt1 = word "#;" in
    let nt1 = caten nt1 nt_sexpr in
    let nt1 = unitify nt1 in
    nt1 str
  and nt_comment str =
    disj_list
      [nt_line_comment;
       nt_paired_comment;
       nt_sexpr_comment] str
  and nt_void str =
    let nt1 = word_ci "#void" in
    let nt1 = not_followed_by nt1 nt_symbol_char in
    let nt1 = pack nt1 (fun _ -> ScmVoid) in
    nt1 str
  and nt_skip_star str =
    let nt1 = disj (unitify nt_whitespace) nt_comment in
    let nt1 = unitify (star nt1) in
    nt1 str
  and make_skipped_star (nt : 'a parser) =
    let nt1 = caten nt_skip_star (caten nt nt_skip_star) in
    let nt1 = pack nt1 (fun (_, (e, _)) -> e) in
    nt1
  and nt_digit str =
    let nt1 = range '0' '9' in
    let nt1 = pack nt1 (let delta = int_of_char '0' in
                        fun ch -> (int_of_char ch) - delta) in
    nt1 str
  and nt_hex_digit str =
    let nt1 = range_ci 'a' 'f' in
    let nt1 = pack nt1 Char.lowercase_ascii in
    let nt1 = pack nt1 (let delta = int_of_char 'a' - 10 in
                        fun ch -> (int_of_char ch) - delta) in
    let nt1 = disj nt_digit nt1 in
    nt1 str
  and nt_nat str =
    let nt1 = plus nt_digit in
    let nt1 = pack nt1
                (fun digits ->
                  List.fold_left
                    (fun num digit -> 10 * num + digit)
                    0
                    digits) in
    nt1 str
  and nt_hex_nat str =
    let nt1 = plus nt_hex_digit in
    let nt1 = pack nt1
                (fun digits ->
                  List.fold_left
                    (fun num digit ->
                      16 * num + digit)
                    0
                    digits) in
    nt1 str
  and nt_optional_sign str =
    let nt1 = char '+' in
    let nt1 = pack nt1 (fun _ -> true) in
    let nt2 = char '-' in
    let nt2 = pack nt2 (fun _ -> false) in
    let nt1 = disj nt1 nt2 in
    let nt1 = make_maybe nt1 true in
    nt1 str
  and nt_int str =
    let nt1 = caten nt_optional_sign nt_nat in
    let nt1 = pack nt1
                (fun (is_positive, n) ->
                  if is_positive then n else -n) in
    nt1 str
  and nt_frac str =
    let nt1 = caten nt_int (char '/') in
    let nt1 = pack nt1 (fun (num, _) -> num) in
    let nt2 = only_if nt_nat (fun n -> n != 0) in
    let nt1 = caten nt1 nt2 in
    let nt1 = pack nt1
                (fun (num, den) ->
                  let d = gcd (abs num) (abs den) in
                  let num = num / d
                  and den = den / d in
                  (match num, den with
                   | 0, _ -> ScmInteger 0
                   | num, 1 -> ScmInteger num
                   | num, den -> ScmFraction(num, den))) in
    nt1 str
  and nt_integer_part str =
    let nt1 = plus nt_digit in
    let nt1 = pack nt1
                (fun digits ->
                  List.fold_left
                    (fun num digit -> 10.0 *. num +. (float_of_int digit))
                    0.0
                    digits) in
    nt1 str
  and nt_mantissa str =
    let nt1 = plus nt_digit in
    let nt1 = pack nt1
                (fun digits ->
                  List.fold_right
                    (fun digit num ->
                      ((float_of_int digit) +. num) /. 10.0)
                    digits
                    0.0) in
    nt1 str
  and nt_exponent str =
    let nt1 = unitify (char_ci 'e') in
    let nt2 = word "*10" in
    let nt3 = unitify (word "**") in
    let nt4 = unitify (char '^') in
    let nt3 = disj nt3 nt4 in
    let nt2 = caten nt2 nt3 in
    let nt2 = unitify nt2 in
    let nt1 = disj nt1 nt2 in
    let nt1 = caten nt1 nt_int in
    let nt1 = pack nt1 (fun (_, n) -> Float.pow 10. (float_of_int n)) in
    nt1 str
  and nt_float str =
    let nt1 = nt_optional_sign in

    (* form-1: 23.{34}{e+4} *)
    let nt2 = nt_integer_part in
    let nt3 = char '.' in
    let nt4 = make_maybe nt_mantissa 0.0 in
    let nt5 = make_maybe nt_exponent 1.0 in
    let nt2 = caten nt2 (caten nt3 (caten nt4 nt5)) in
    let nt2 = pack nt2
                (fun (ip, (_, (mant, expo))) ->
                  (ip +. mant) *. expo) in

    (* form-2: .34{e+4} *)
    let nt3 = char '.' in
    let nt4 = nt_mantissa in
    let nt5 = make_maybe nt_exponent 1.0 in
    let nt3 = caten nt3 (caten nt4 nt5) in
    let nt3 = pack nt3
                (fun (_, (mant, expo)) ->
                  mant *. expo) in

    (* form-3: 12e-4 *)
    let nt4 = caten nt_integer_part nt_exponent in
    let nt4 = pack nt4
                (fun (ip, expo) ->
                  ip *. expo) in
    let nt2 = disj nt2 (disj nt3 nt4) in
    let nt1 = caten nt1 nt2 in
    let nt1 = pack nt1 (function
                  | (false, x) -> (-. x)
                  | (true, x) -> x) in
    let nt1 = pack nt1 (fun x -> ScmReal x) in
    nt1 str
  and nt_number str =
    let nt1 = nt_float in
    let nt2 = nt_frac in
    let nt3 = pack nt_int (fun n -> ScmInteger n) in
    let nt1 = disj nt1 (disj nt2 nt3) in
    let nt1 = pack nt1 (fun r -> ScmNumber r) in
    let nt1 = not_followed_by nt1 nt_symbol_char in
    nt1 str  
  and nt_boolean str =
    let nt1 = char '#' in
    let nt2 = char_ci 'f' in
    let nt2 = pack nt2 (fun _ -> ScmBoolean false) in
    let nt3 = char_ci 't' in
    let nt3 = pack nt3 (fun _ -> ScmBoolean true) in
    let nt2 = disj nt2 nt3 in
    let nt1 = caten nt1 nt2 in
    let nt1 = pack nt1 (fun (_, value) -> value) in
    let nt2 = nt_symbol_char in
    let nt1 = not_followed_by nt1 nt2 in
    nt1 str
  and nt_char_simple str =
    let nt1 = const(fun ch -> ' ' < ch) in
    let nt1 = not_followed_by nt1 nt_symbol_char in
    nt1 str
  and make_named_char char_name ch =
    pack (word_ci char_name) (fun _ -> ch)
  and nt_char_named str =
    let nt1 =
      disj_list [(make_named_char "nul" '\000');
                 (make_named_char "alarm" '\007');
                 (make_named_char "backspace" '\008');
                 (make_named_char "page" '\012');
                 (make_named_char "space" ' ');
                 (make_named_char "newline" '\n');
                 (make_named_char "return" '\r');
                 (make_named_char "tab" '\t')] in
    nt1 str
  and nt_char_hex str =
    let nt1 = caten (char_ci 'x') nt_hex_nat in
    let nt1 = pack nt1 (fun (_, n) -> n) in
    let nt1 = only_if nt1 (fun n -> n < 256) in
    let nt1 = pack nt1 (fun n -> char_of_int n) in
    nt1 str  
  and nt_char str =
    let nt1 = word "#\\" in
    let nt2 = disj nt_char_simple (disj nt_char_named nt_char_hex) in
    let nt1 = caten nt1 nt2 in
    let nt1 = pack nt1 (fun (_, ch) -> ScmChar ch) in
    nt1 str
  and nt_symbol_char str =
    let nt1 = range_ci 'a' 'z' in
    let nt1 = pack nt1 Char.lowercase_ascii in
    let nt2 = range '0' '9' in
    let nt3 = one_of "!$^*_-+=<>?/" in
    let nt1 = disj nt1 (disj nt2 nt3) in
    nt1 str
  and nt_symbol str =
    let nt1 = plus nt_symbol_char in
    let nt1 = pack nt1 string_of_list in
    let nt1 = pack nt1 (fun name -> ScmSymbol name) in
    let nt1 = diff nt1 nt_number in
    nt1 str
  and nt_string_part_simple str =
    let nt1 =
      disj_list [unitify (char '"'); unitify (char '\\'); unitify (word "~~");
                 unitify nt_string_part_dynamic] in
    let nt1 = diff nt_any nt1 in
    nt1 str
  and nt_string_part_meta str =
    let nt1 =
      disj_list [pack (word "\\\\") (fun _ -> '\\');
                 pack (word "\\\"") (fun _ -> '"');
                 pack (word "\\n") (fun _ -> '\n');
                 pack (word "\\r") (fun _ -> '\r');
                 pack (word "\\f") (fun _ -> '\012');
                 pack (word "\\t") (fun _ -> '\t');
                 pack (word "~~") (fun _ -> '~')] in
    nt1 str
  and nt_string_part_hex str =
    let nt1 = word_ci "\\x" in
    let nt2 = nt_hex_nat in
    let nt2 = only_if nt2 (fun n -> n < 256) in
    let nt3 = char ';' in
    let nt1 = caten nt1 (caten nt2 nt3) in
    let nt1 = pack nt1 (fun (_, (n, _)) -> n) in
    let nt1 = pack nt1 char_of_int in
    nt1 str
  and nt_string_part_dynamic str =
    let nt1 = word "~{" in
    let nt2 = nt_sexpr in
    let nt3 = char '}' in
    let nt1 = caten nt1 (caten nt2 nt3) in
    let nt1 = pack nt1 (fun (_, (sexpr, _)) -> sexpr) in
    let nt1 = pack nt1 (fun sexpr ->
                  ScmPair(ScmSymbol "format",
                          ScmPair(ScmString "~a",
                                  ScmPair(sexpr, ScmNil)))) in
    let nt1 = pack nt1 (fun sexpr -> Dynamic sexpr) in
    nt1 str
  and nt_string_part_static str =
    let nt1 = disj_list [nt_string_part_simple;
                         nt_string_part_meta;
                         nt_string_part_hex] in
    let nt1 = plus nt1 in
    let nt1 = pack nt1 string_of_list in
    let nt1 = pack nt1 (fun str -> Static str) in
    nt1 str
  and nt_string_part str =
    disj nt_string_part_static nt_string_part_dynamic str
  and nt_string str =
    let nt1 = char '"' in
    let nt2 = star nt_string_part in
    let nt1 = caten nt1 (caten nt2 nt1) in
    let nt1 = pack nt1 (fun (_, (parts, _)) -> parts) in
    let nt1 = pack nt1
                (function
                 | [] -> ScmString ""
                 | [Static(str)] -> ScmString str
                 | [Dynamic(sexpr)] -> sexpr
                 | parts ->
                    let argl =
                      List.fold_right
                        (fun car cdr ->
                          ScmPair((match car with
                                   | Static(str) -> ScmString(str)
                                   | Dynamic(sexpr) -> sexpr),
                                  cdr))
                        parts
                        ScmNil in
                    ScmPair(ScmSymbol "string-append", argl)) in
    nt1 str
  and nt_vector str =
    let nt1 = word "#(" in
    let nt2 = caten nt_skip_star (char ')') in
    let nt2 = pack nt2 (fun _ -> ScmVector []) in
    let nt3 = plus nt_sexpr in
    let nt4 = char ')' in
    let nt3 = caten nt3 nt4 in
    let nt3 = pack nt3 (fun (sexprs, _) -> ScmVector sexprs) in
    let nt2 = disj nt2 nt3 in
    let nt1 = caten nt1 nt2 in
    let nt1 = pack nt1 (fun (_, sexpr) -> sexpr) in
    nt1 str
  and nt_list str =
    let nt1 = char '(' in

    (* () *)
    let nt2 = caten nt_skip_star (char ')') in
    let nt2 = pack nt2 (fun _ -> ScmNil) in

    let nt3 = plus nt_sexpr in

    (* (sexpr ... sexpr . sexpr) *)
    let nt4 = char '.' in
    let nt5 = nt_sexpr in
    let nt6 = char ')' in
    let nt4 = caten nt4 (caten nt5 nt6) in
    let nt4 = pack nt4 (fun (_, (sexpr, _)) -> sexpr) in

    (* (sexpr ... sexpr) *)
    let nt5 = char ')' in
    let nt5 = pack nt5 (fun _ -> ScmNil) in
    let nt4 = disj nt4 nt5 in
    let nt3 = caten nt3 nt4 in
    let nt3 = pack nt3
                (fun (sexprs, sexpr) ->
                  List.fold_right
                    (fun car cdr -> ScmPair(car, cdr))
                    sexprs
                    sexpr) in
    let nt2 = disj nt2 nt3 in
    let nt1 = caten nt1 nt2 in
    let nt1 = pack nt1 (fun (_, sexpr) -> sexpr) in
    nt1 str
  and make_quoted_form nt_qf qf_name =
    let nt1 = caten nt_qf nt_sexpr in
    let nt1 = pack nt1
                (fun (_, sexpr) ->
                  ScmPair(ScmSymbol qf_name,
                          ScmPair(sexpr, ScmNil))) in
    nt1
  and nt_quoted_forms str =
    let nt1 =
      disj_list [(make_quoted_form (unitify (char '\'')) "quote");
                 (make_quoted_form (unitify (char '`')) "quasiquote");
                 (make_quoted_form
                    (unitify (not_followed_by (char ',') (char '@')))
                    "unquote");
                 (make_quoted_form (unitify (word ",@"))
                    "unquote-splicing")] in
    nt1 str
  and nt_sexpr str = 
    let nt1 =
      disj_list [nt_void; nt_number; nt_boolean; nt_char; nt_symbol;
                 nt_string; nt_vector; nt_list; nt_quoted_forms] in
    let nt1 = make_skipped_star nt1 in
    nt1 str;;

end;; (* end of struct Reader *)

let read str = (Reader.nt_sexpr str 0).found;;

let rec string_of_sexpr = function
  | ScmVoid -> "#<void>"
  | ScmNil -> "()"
  | ScmBoolean(false) -> "#f"
  | ScmBoolean(true) -> "#t"
  | ScmChar('\000') -> "#\\nul"
  | ScmChar('\n') -> "#\\newline"
  | ScmChar('\r') -> "#\\return"
  | ScmChar('\012') -> "#\\page"
  | ScmChar('\t') -> "#\\tab"
  | ScmChar(' ') -> "#\\space"
  | ScmChar('\007') -> "#\\alarm"
  | ScmChar('\008') -> "#\\backspace"
  | ScmChar(ch) ->
     if (ch < ' ')
     then let n = int_of_char ch in
          Printf.sprintf "#\\x%x" n
     else Printf.sprintf "#\\%c" ch
  | ScmString(str) ->
     Printf.sprintf "\"%s\""
       (String.concat ""
          (List.map
             (function
              | '\n' -> "\\n"
              | '\012' -> "\\f"
              | '\r' -> "\\r"
              | '\t' -> "\\t"
              | '\"' -> "\\\""
              | ch ->
                 if (ch < ' ')
                 then Printf.sprintf "\\x%x;" (int_of_char ch)
                 else Printf.sprintf "%c" ch)
             (list_of_string str)))
  | ScmSymbol(sym) -> sym
  | ScmNumber(ScmInteger n) -> Printf.sprintf "%d" n
  | ScmNumber(ScmFraction(0, _)) -> "0"
  | ScmNumber(ScmFraction(num, 1)) -> Printf.sprintf "%d" num
  | ScmNumber(ScmFraction(num, -1)) -> Printf.sprintf "%d" (- num)
  | ScmNumber(ScmFraction(num, den)) -> Printf.sprintf "%d/%d" num den
  | ScmNumber(ScmReal(x)) -> Printf.sprintf "%f" x
  | ScmVector(sexprs) ->
     let strings = List.map string_of_sexpr sexprs in
     let inner_string = String.concat " " strings in
     Printf.sprintf "#(%s)" inner_string
  | ScmPair(ScmSymbol "quote",
            ScmPair(sexpr, ScmNil)) ->
     Printf.sprintf "'%s" (string_of_sexpr sexpr)
  | ScmPair(ScmSymbol "quasiquote",
            ScmPair(sexpr, ScmNil)) ->
     Printf.sprintf "`%s" (string_of_sexpr sexpr)
  | ScmPair(ScmSymbol "unquote",
            ScmPair(sexpr, ScmNil)) ->
     Printf.sprintf ",%s" (string_of_sexpr sexpr)
  | ScmPair(ScmSymbol "unquote-splicing",
            ScmPair(sexpr, ScmNil)) ->
     Printf.sprintf ",@%s" (string_of_sexpr sexpr)
  | ScmPair(car, cdr) ->
     string_of_sexpr' (string_of_sexpr car) cdr
and string_of_sexpr' car_string = function
  | ScmNil -> Printf.sprintf "(%s)" car_string
  | ScmPair(cadr, cddr) ->
     let new_car_string =
       Printf.sprintf "%s %s" car_string (string_of_sexpr cadr) in
     string_of_sexpr' new_car_string cddr
  | cdr ->
     let cdr_string = (string_of_sexpr cdr) in
     Printf.sprintf "(%s . %s)" car_string cdr_string;;

let print_sexpr chan sexpr = output_string chan (string_of_sexpr sexpr);;

let print_sexprs chan sexprs =
  output_string chan
    (Printf.sprintf "[%s]"
       (String.concat "; "
          (List.map string_of_sexpr sexprs)));;

let sprint_sexpr _ sexpr = string_of_sexpr sexpr;;

let sprint_sexprs chan sexprs =
  Printf.sprintf "[%s]"
    (String.concat "; "
       (List.map string_of_sexpr sexprs));;

let scheme_list_of_ocaml_list sexprs sexpr =
  List.fold_right (fun car cdr -> ScmPair (car, cdr)) sexprs sexpr;;

(* the tag-parser *)

exception X_syntax of string;;

type var = Var of string;;

type lambda_kind =
  | Simple
  | Opt of string;;

type expr =
  | ScmConst of sexpr
  | ScmVarGet of var
  | ScmIf of expr * expr * expr
  | ScmSeq of expr list
  | ScmOr of expr list
  | ScmVarSet of var * expr
  | ScmVarDef of var * expr
  | ScmLambda of string list * lambda_kind * expr
  | ScmApplic of expr * expr list;;

module type TAG_PARSER = sig
  val tag_parse : sexpr -> expr
end;;

let rec scheme_list_to_ocaml = function
  | ScmPair(car, cdr) ->
     ((fun (rdc, last) -> (car :: rdc, last))
        (scheme_list_to_ocaml cdr))  
  | rac -> ([], rac);;

module Tag_Parser : TAG_PARSER = struct
  open Reader;;

  let config_should_expand_begin = false;;
  let config_should_expand_or = false;;

  let scm_improper_list =
    let rec run = function
      | ScmNil -> false
      | ScmPair (_, rest) -> run rest
      | _ -> true
    in fun sexpr -> run sexpr;;
  
  let reserved_word_list =
    ["and"; "begin"; "cond"; "define"; "do"; "else"; "if";
     "lambda"; "let"; "let*"; "letrec"; "or"; "quasiquote";
     "quote"; "set!"; "unquote"; "unquote-splicing"];;

  let is_reserved_word name = List.mem name reserved_word_list;;

  let unsymbolify_var = function
    | ScmSymbol var -> var
    | e ->
       raise (X_syntax
                (Printf.sprintf
                   "Expecting a symbol, but found this: %a"
                   sprint_sexpr
                   e));;

  let unsymbolify_vars = List.map unsymbolify_var;;

  let rec names_values = function
    | [] -> ([], [])
    | (ScmPair (name, ScmPair (value, ScmNil))) :: ribs ->
       let (names, values) = names_values ribs in
       (name :: names, value :: values)
    | _ -> raise (X_syntax "Improper let-ribs");;

  let unique_strings_of_list =
    let rec run seen = function 
      | [] -> seen
      | str :: rest when List.mem str seen ->
         run seen rest
      | str :: rest -> run (str :: seen) rest
    in fun s -> run [] s;;  

  let list_contains_unquote_splicing =
    ormap (function
        | ScmPair (ScmSymbol "unquote-splicing",
                   ScmPair (_, ScmNil)) -> true
        | _ -> false);;

  let rec expand_or = function
    | [] -> ScmBoolean false
    | [sexpr] -> sexpr
    | a :: rest ->
       let b = expand_or rest in
       ScmPair
         (ScmSymbol "let",
          ScmPair
            (ScmPair
               (ScmPair (ScmSymbol "x", ScmPair (a, ScmNil)),
                ScmPair
                  (ScmPair
                     (ScmSymbol "y",
                      ScmPair
                        (ScmPair
                           (ScmSymbol "lambda",
                            ScmPair (ScmNil, ScmPair (b, ScmNil))),
                         ScmNil)),
                   ScmNil)),
             ScmPair
               (ScmPair
                  (ScmSymbol "if",
                   ScmPair
                     (ScmSymbol "x",
                      ScmPair
                        (ScmSymbol "x",
                         ScmPair (ScmPair (ScmSymbol "y", ScmNil),
                                  ScmNil)))),
                ScmNil)));;

  let rec expand_begin = function
    | [] -> ScmVoid
    | [sexpr] -> sexpr
    | a :: rest ->
       let b = expand_begin rest in
       ScmPair
         (ScmSymbol "let",
          ScmPair
            (ScmPair
               (ScmPair (ScmSymbol "x", ScmPair (a, ScmNil)),
                ScmPair
                  (ScmPair
                     (ScmSymbol "y",
                      ScmPair
                        (ScmPair
                           (ScmSymbol "lambda",
                            ScmPair (ScmNil, ScmPair (b, ScmNil))),
                         ScmNil)),
                   ScmNil)),
             ScmPair (ScmPair (ScmSymbol "y", ScmNil), ScmNil)));;

  (* helper: (quote x) *)
  let quote sexpr =
    ScmPair (ScmSymbol "quote", ScmPair (sexpr, ScmNil));;

  let rec macro_expand_qq_depth depth = function
    | ScmVoid | ScmBoolean _ | ScmChar _ | ScmString _ | ScmNumber _ | ScmSymbol _ as sexpr ->
        quote sexpr
    | ScmNil ->
        quote ScmNil
    | ScmVector sexprs ->
        (* Expand vector by building a list expression and converting to vector *)
        let rec expand_vector_elements depth = function
          | [] -> quote ScmNil
          | ScmPair (ScmSymbol "unquote-splicing", ScmPair (expr, ScmNil)) :: [] ->
             if depth = 1 then expr
             else quote (ScmPair (ScmSymbol "unquote-splicing", ScmPair (expr, ScmNil)))
          | ScmPair (ScmSymbol "unquote-splicing", ScmPair (expr, ScmNil)) :: rest ->
             if depth = 1 then
               let rest_expr = expand_vector_elements depth rest in
               ScmPair (ScmSymbol "append",
                        ScmPair (expr,
                                 ScmPair (rest_expr, ScmNil)))
             else
               (* At depth > 1, preserve unquote-splicing as data *)
               let preserved = quote (ScmPair (ScmSymbol "unquote-splicing", ScmPair (expr, ScmNil))) in
               let rest_expr = expand_vector_elements depth rest in
               ScmPair (ScmSymbol "cons",
                        ScmPair (preserved,
                                 ScmPair (rest_expr, ScmNil)))
          | elem :: rest ->
             let expanded_elem = macro_expand_qq_depth depth elem in
             let rest_expr = expand_vector_elements depth rest in
             ScmPair (ScmSymbol "cons",
                      ScmPair (expanded_elem,
                               ScmPair (rest_expr, ScmNil)))
        in
        let list_expr = expand_vector_elements depth sexprs in
        ScmPair (ScmSymbol "list->vector",
                 ScmPair (list_expr, ScmNil))

    (* Handle nested quasiquote: (quasiquote x) *)
    | ScmPair (ScmSymbol "quasiquote", ScmPair (x, ScmNil)) ->
        (* Expand x at depth+1, then build cons structure *)
        let x' = macro_expand_qq_depth (depth + 1) x in
        ScmPair (ScmSymbol "cons",
                 ScmPair (quote (ScmSymbol "quasiquote"),
                          ScmPair (ScmPair (ScmSymbol "cons",
                                            ScmPair (x',
                                                     ScmPair (quote ScmNil, ScmNil))),
                                   ScmNil)))

    (* ,x  => x (at depth 1), or preserved as data (at depth > 1) *)
    | ScmPair (ScmSymbol "unquote", ScmPair (expr, ScmNil)) ->
        if depth = 1 then expr
        else quote (ScmPair (ScmSymbol "unquote", ScmPair (expr, ScmNil)))

    (* ,@x is only valid in list position at depth 1 *)
    | ScmPair (ScmSymbol "unquote-splicing", ScmPair (expr, ScmNil)) ->
        if depth = 1 then
          raise (X_syntax "unquote-splicing must appear inside a list")
        else
          quote (ScmPair (ScmSymbol "unquote-splicing", ScmPair (expr, ScmNil)))

    (* (,@x . ())  => x   (avoid (append x '())) *)
    | ScmPair (ScmPair (ScmSymbol "unquote-splicing", ScmPair (x, ScmNil)), ScmNil) ->
        if depth = 1 then x
        else quote (ScmPair (ScmPair (ScmSymbol "unquote-splicing", ScmPair (x, ScmNil)), ScmNil))

    (* (,@x . d)  => (append x (qq d)) *)
    | ScmPair (ScmPair (ScmSymbol "unquote-splicing", ScmPair (x, ScmNil)), d) ->
        if depth = 1 then
          ScmPair (ScmSymbol "append",
                   ScmPair (x,
                            ScmPair (macro_expand_qq_depth depth d, ScmNil)))
        else
          (* At depth > 1, preserve as data *)
          quote (ScmPair (ScmPair (ScmSymbol "unquote-splicing", ScmPair (x, ScmNil)), d))

    (* (a . ,@d)  => (cons (qq a) d)  -- handle unquote-splicing in cdr, similar to dotted-unquote *)
    | ScmPair (a, ScmPair (ScmSymbol "unquote-splicing", ScmPair (d, ScmNil))) ->
        if depth = 1 then
          ScmPair (ScmSymbol "cons",
                   ScmPair (macro_expand_qq_depth depth a,
                            ScmPair (d, ScmNil)))
        else
          (* At depth > 1, preserve as data *)
          quote (ScmPair (a, ScmPair (ScmSymbol "unquote-splicing", ScmPair (d, ScmNil))))

    (* (a . ,d)  => (cons (qq a) d)  -- IMPORTANT dotted-unquote rule *)
    | ScmPair (a, ScmPair (ScmSymbol "unquote", ScmPair (d, ScmNil))) ->
        if depth = 1 then
          ScmPair (ScmSymbol "cons",
                   ScmPair (macro_expand_qq_depth depth a,
                            ScmPair (d, ScmNil)))
        else
          (* At depth > 1, preserve as data *)
          quote (ScmPair (a, ScmPair (ScmSymbol "unquote", ScmPair (d, ScmNil))))

    (* (a . d) => (cons (qq a) (qq d)) *)
    | ScmPair (a, d) ->
        ScmPair (ScmSymbol "cons",
                 ScmPair (macro_expand_qq_depth depth a,
                          ScmPair (macro_expand_qq_depth depth d, ScmNil)));;

  (* Wrapper function that calls with depth 1 *)
  let macro_expand_qq sexpr = macro_expand_qq_depth 1 sexpr;;

  let rec macro_expand_and_clauses expr = function
    | [] -> expr
    | expr' :: exprs ->
       let dit = macro_expand_and_clauses expr' exprs in
       ScmPair (ScmSymbol "if",
                ScmPair (expr,
                         ScmPair (dit,
                                  ScmPair (ScmBoolean false,
                                           ScmNil))));;
  (* need to implement this function *)
  let rec macro_expand_cond_ribs ribs =
    (* Convert ribs from sexpr to OCaml list *)
    match (scheme_list_to_ocaml ribs) with
    | ([], _) -> ScmVoid  (* Empty cond *)
    | (ribs_list, ScmNil) ->
       (* Process ribs recursively to build nested if *)
       let rec process = function
         | [] -> ScmVoid
         | ScmPair (ScmSymbol "else", body) :: [] ->
            (* Last rib with else - body can be multiple expressions, wrap in begin if needed *)
            (match (scheme_list_to_ocaml body) with
             | ([], _) -> raise (X_syntax "else clause must have at least one expression")
             | ([single_expr], ScmNil) -> single_expr
             | (exprs, ScmNil) ->
                ScmPair (ScmSymbol "begin",
                         scheme_list_of_ocaml_list exprs ScmNil)
             | _ -> raise (X_syntax "Malformed else clause"))
         | ScmPair (ScmSymbol "else", _) :: rest ->
            (* else is not last - error *)
            raise (X_syntax "else must be the last clause in cond")
         | ScmPair (test, body) :: rest ->
            (* Check for arrow syntax: (test => proc) *)
            (match (scheme_list_to_ocaml body) with
             | ([ScmSymbol "=>"; proc], ScmNil) ->
                (* Arrow syntax: (test => proc) *)
                (* Canonical expansion: (lambda (value f rest) (if value ((f) value) (rest))) *)
                let rest_expr = process rest in
                let value_sym = ScmSymbol "value" in
                let f_sym = ScmSymbol "f" in
                let rest_sym = ScmSymbol "rest" in
                let f_thunk =
                  ScmPair (ScmSymbol "lambda",
                           ScmPair (ScmNil, ScmPair (proc, ScmNil))) in
                let rest_thunk =
                  ScmPair (ScmSymbol "lambda",
                           ScmPair (ScmNil, ScmPair (rest_expr, ScmNil))) in
                let body =
                  ScmPair (ScmSymbol "if",
                           ScmPair (value_sym,
                                    ScmPair (ScmPair (ScmPair (f_sym, ScmNil),
                                                      ScmPair (value_sym, ScmNil)),
                                             ScmPair (ScmPair (rest_sym, ScmNil),
                                                      ScmNil)))) in
                let lambda_expr =
                  ScmPair (ScmSymbol "lambda",
                           ScmPair (scheme_list_of_ocaml_list [value_sym; f_sym; rest_sym] ScmNil,
                                    ScmPair (body, ScmNil))) in
                ScmPair (lambda_expr,
                         ScmPair (test,
                                  ScmPair (f_thunk,
                                           ScmPair (rest_thunk, ScmNil))))
             | ([], _) ->
                (* No body - return test itself if true *)
                let rest_expr = process rest in
                ScmPair (ScmSymbol "if",
                         ScmPair (test,
                                  ScmPair (test,
                                           ScmPair (rest_expr, ScmNil))))
             | ([single_expr], ScmNil) ->
                (* Single expression body *)
                let rest_expr = process rest in
                ScmPair (ScmSymbol "if",
                         ScmPair (test,
                                  ScmPair (single_expr,
                                           ScmPair (rest_expr, ScmNil))))
             | (exprs, ScmNil) ->
                (* Multiple expressions - wrap in begin *)
                let body_expr = 
                  ScmPair (ScmSymbol "begin",
                           scheme_list_of_ocaml_list exprs ScmNil)
                in
                let rest_expr = process rest in
                ScmPair (ScmSymbol "if",
                         ScmPair (test,
                                  ScmPair (body_expr,
                                           ScmPair (rest_expr, ScmNil))))
             | _ -> raise (X_syntax "Malformed cond rib body"))
         | _ -> raise (X_syntax "Malformed cond rib")
       in
       process ribs_list
    | _ -> raise (X_syntax "Malformed cond - improper list");;

  let is_list_of_unique_names =
    let rec run = function
      | [] -> true
      | (name : string) :: rest when not (List.mem name rest) -> run rest
      | _ -> false
    in run;;
  let sexpr_quote x =
      ScmPair (ScmSymbol "quote", ScmPair (x, ScmNil))
    
  let sexpr_list lst =
      List.fold_right (fun a b -> ScmPair (a, b)) lst ScmNil
    
  let rec sexpr_to_list = function
      | ScmNil -> []
      | ScmPair (a, d) -> a :: sexpr_to_list d
      | _ -> raise (X_syntax "expected a proper list")
    
  let rec tag_parse sexpr =
    match sexpr with
    | ScmVoid | ScmBoolean _ | ScmChar _ | ScmString _ | ScmNumber _ ->
       ScmConst sexpr
    | ScmPair (ScmSymbol "quote", ScmPair (sexpr, ScmNil)) ->
       ScmConst sexpr
    | ScmPair (ScmSymbol "quasiquote", ScmPair (sexpr, ScmNil)) ->
       tag_parse (macro_expand_qq sexpr)
    | ScmSymbol var ->
       if (is_reserved_word var)
       then raise (X_syntax "Variable cannot be a reserved word")
       else ScmVarGet(Var var)
    | ScmPair (ScmSymbol "if",
               ScmPair (test, ScmPair (dit, ScmNil))) ->
       ScmIf(tag_parse test,
             tag_parse dit,
             tag_parse ScmVoid)
    | ScmPair (ScmSymbol "if",
               ScmPair (test, ScmPair (dit, ScmPair (dif, ScmNil)))) ->
       ScmIf(tag_parse test,
             tag_parse dit,
             tag_parse dif)
    | ScmPair (ScmSymbol "if", _) ->
       raise (X_syntax "Malformed if-expression!")
    | ScmPair (ScmSymbol "or", sexprs) when config_should_expand_or ->
       (match scheme_list_to_ocaml sexprs with
        | sexprs, ScmNil -> tag_parse (expand_or sexprs)
        | _ -> raise (X_syntax "malformed or: Not a proper list"))
    | ScmPair (ScmSymbol "or", ScmNil) -> tag_parse (ScmBoolean false)
    | ScmPair (ScmSymbol "or", ScmPair (sexpr, ScmNil)) -> tag_parse sexpr
    | ScmPair (ScmSymbol "or", sexprs) ->
       (match (scheme_list_to_ocaml sexprs) with
        | (sexprs', ScmNil) -> ScmOr (List.map tag_parse sexprs')
        | _ -> raise (X_syntax "Malformed or-expression!"))
    | ScmPair (ScmSymbol "begin", sexprs) when config_should_expand_begin ->
       (match scheme_list_to_ocaml sexprs with
        | sexprs, ScmNil -> tag_parse (expand_begin sexprs)
        | _ -> raise (X_syntax "malformed begin: Not a proper list"))
    | ScmPair (ScmSymbol "begin", ScmNil) -> ScmConst(ScmVoid)
    | ScmPair (ScmSymbol "begin", ScmPair (sexpr, ScmNil)) ->
       tag_parse sexpr
    | ScmPair (ScmSymbol "begin", sexprs) ->
       (match (scheme_list_to_ocaml sexprs) with
        | (sexprs', ScmNil) -> ScmSeq(List.map tag_parse sexprs')
        | _ -> raise (X_syntax "Improper sequence"))
    | ScmPair (ScmSymbol "set!",
               ScmPair (ScmSymbol var,
                        ScmPair (expr, ScmNil))) ->
       if (is_reserved_word var)
       then raise (X_syntax "cannot assign a reserved word")
       else ScmVarSet(Var var, tag_parse expr)
    | ScmPair (ScmSymbol "set!", _) ->
       raise (X_syntax "Malformed set!-expression!")
    | ScmPair (ScmSymbol "define",
               ScmPair (ScmPair (var, params),
                        exprs)) ->
       tag_parse
         (ScmPair (ScmSymbol "define",
                   ScmPair (var,
                            ScmPair (ScmPair (ScmSymbol "lambda",
                                              ScmPair (params, exprs)),
                                     ScmNil))))
    | ScmPair (ScmSymbol "define",
               ScmPair (ScmSymbol var,
                        ScmPair (expr, ScmNil))) ->
       if (is_reserved_word var)
       then raise (X_syntax "cannot define a reserved word")
       else ScmVarDef(Var var, tag_parse expr)
    | ScmPair (ScmSymbol "define", _) ->
       raise (X_syntax "Malformed define-expression!")
    | ScmPair (ScmSymbol "lambda", rest)
         when scm_improper_list rest ->
       raise (X_syntax "Malformed lambda-expression!")
    | ScmPair (ScmSymbol "lambda", ScmPair (params, exprs)) ->
       let expr = tag_parse (ScmPair(ScmSymbol "begin", exprs)) in
       (match (scheme_list_to_ocaml params) with
        | params, ScmNil ->
           let params = unsymbolify_vars params in
           if is_list_of_unique_names params
           then ScmLambda(params, Simple, expr)
           else raise (X_syntax "duplicate function parameters")
        | params, ScmSymbol opt ->
           let params = unsymbolify_vars params in
           if is_list_of_unique_names (params @ [opt])
           then ScmLambda(params, Opt opt, expr)
           else raise (X_syntax "duplicate function parameters")
        | _ -> raise (X_syntax "invalid parameter list"))
    | ScmPair (ScmSymbol "let", ScmPair (ribs, exprs)) ->
       let ribs = (match (scheme_list_to_ocaml ribs) with
                   | ribs, ScmNil -> ribs
                   | _ -> raise (X_syntax "invalid lambda-ribs")) in
       let params =
         scheme_list_of_ocaml_list
           (List.map (function
                | ScmPair (var, ScmPair (_, ScmNil)) -> var
                | _ -> raise (X_syntax "invalid lambda-rib structure"))
              ribs) ScmNil in
       let args =
         scheme_list_of_ocaml_list
           (List.map (function
                | ScmPair (_, ScmPair (arg, ScmNil)) -> arg
                | _ -> raise (X_syntax "invalid lambda-rib structure"))
              ribs) ScmNil in
       tag_parse
         (ScmPair (ScmPair (ScmSymbol "lambda",
                            ScmPair (params, exprs)),
                   args))
    | ScmPair (ScmSymbol "let*", ScmPair (ribs, exprs)) -> 
       (match (scheme_list_to_ocaml ribs) with
        | ([], ScmNil) ->
           (* (let* () body...) == (let () body...) *)
           tag_parse (ScmPair (ScmSymbol "let", ScmPair (ScmNil, exprs)))
        | ([rib], ScmNil) ->
           (* (let* (rib) body...) == (let (rib) body...) *)
           tag_parse (ScmPair (ScmSymbol "let",
                               ScmPair (ScmPair (rib, ScmNil), exprs)))
        | (rib :: rest, ScmNil) ->
           (* (let* (r1 r2 ...) body) == (let (r1) (let* (r2 ...) body)) *)
           let rest_ribs = scheme_list_of_ocaml_list rest ScmNil in
           let inner = ScmPair (ScmSymbol "let*",
                                ScmPair (rest_ribs, exprs)) in
           tag_parse (ScmPair (ScmSymbol "let",
                               ScmPair (ScmPair (rib, ScmNil),
                                        ScmPair (inner, ScmNil))))
        | _ -> raise (X_syntax "Malformed let*-ribs"))
    | ScmPair (ScmSymbol "letrec", ScmPair (ribs, exprs)) ->
          let ribs_list, ribs_tail = scheme_list_to_ocaml ribs in
          if ribs_tail <> ScmNil then raise (X_syntax "Invalid letrec ribs");
        
          let exprs_list, exprs_tail = scheme_list_to_ocaml exprs in
          if exprs_tail <> ScmNil then raise (X_syntax "Invalid letrec body");
        
          (* parse each rib: (name value) *)
          let binds =
            List.map
              (fun rib ->
                let rib_list, rib_tail = scheme_list_to_ocaml rib in
                if rib_tail <> ScmNil then raise (X_syntax "Invalid rib");
                match rib_list with
                | [ScmSymbol _ as name; value] -> (name, value)
                | _ -> raise (X_syntax "Invalid rib"))
              ribs_list
          in
        
          let names = List.map fst binds in
          let values = List.map snd binds in
        
          (* ( (f 'whatever) (g 'whatever) ... ) *)
          let dummy_ribs =
            scheme_list_of_ocaml_list
              (List.map
                 (fun name ->
                   ScmPair (name,
                     ScmPair (
                       ScmPair (ScmSymbol "quote",
                         ScmPair (ScmSymbol "whatever", ScmNil)),
                       ScmNil)))
                 names)
              ScmNil
          in
        
          (* (set! f Ef) ... *)
          let set_exprs =
            List.map2
              (fun name value ->
                ScmPair (ScmSymbol "set!",
                  ScmPair (name, ScmPair (value, ScmNil))))
              names
              values
          in
        
          (* (begin (set! f Ef) (set! g Eg) ... body...) *)
          let begin_expr =
            ScmPair (ScmSymbol "begin",
              scheme_list_of_ocaml_list (set_exprs @ exprs_list) ScmNil)
          in
        
          (* (let ((f 'whatever) (g 'whatever) ...) (begin ...)) *)
          tag_parse
            (ScmPair (ScmSymbol "let",
              ScmPair (dummy_ribs, ScmPair (begin_expr, ScmNil))))
        
    | ScmPair (ScmSymbol "and", ScmNil) -> tag_parse (ScmBoolean true)
    | ScmPair (ScmSymbol "and", exprs) ->
       (match (scheme_list_to_ocaml exprs) with
        | expr :: exprs, ScmNil ->
           tag_parse (macro_expand_and_clauses expr exprs)
        | _ -> raise (X_syntax "malformed and-expression"))
    | ScmPair (ScmSymbol "cond", ribs) ->
       tag_parse (macro_expand_cond_ribs ribs)
    | ScmPair (proc, args) ->
       let proc =
         (match proc with
          | ScmSymbol var ->
             if (is_reserved_word var)
             then raise (X_syntax
                           (Printf.sprintf
                              "reserved word %s in proc position"
                              var))
             else proc
          | proc -> proc) in
       (match (scheme_list_to_ocaml args) with
        | args, ScmNil ->
           ScmApplic (tag_parse proc, List.map tag_parse args)
        | _ -> raise (X_syntax "malformed application"))
    | sexpr -> raise (X_syntax
                       (Printf.sprintf
                          "Unknown form: \n%a\n"
                          sprint_sexpr sexpr));;
end;; (* end of struct Tag_Parser *)

let parse str = Tag_Parser.tag_parse (read str);;

let rec sexpr_of_expr = function
  | ScmConst((ScmSymbol _) as sexpr)
    | ScmConst(ScmNil as sexpr)
    | ScmConst(ScmPair _ as sexpr)
    | ScmConst((ScmVector _) as sexpr) ->
     ScmPair (ScmSymbol "quote", ScmPair (sexpr, ScmNil))
  | ScmConst(sexpr) -> sexpr
  | ScmVarGet(Var var) -> ScmSymbol var
  | ScmIf(test, dit, ScmConst ScmVoid) ->
     let test = sexpr_of_expr test in
     let dit = sexpr_of_expr dit in
     ScmPair (ScmSymbol "if", ScmPair (test, ScmPair (dit, ScmNil)))
  | ScmIf(e1, e2, ScmConst (ScmBoolean false)) ->
     let e1 = sexpr_of_expr e1 in
     (match (sexpr_of_expr e2) with
      | ScmPair (ScmSymbol "and", exprs) ->
         ScmPair (ScmSymbol "and", ScmPair(e1, exprs))
      | e2 -> ScmPair (ScmSymbol "and", ScmPair (e1, ScmPair (e2, ScmNil))))
  | ScmIf(test, dit, dif) ->
     let test = sexpr_of_expr test in
     let dit = sexpr_of_expr dit in
     let dif = sexpr_of_expr dif in
     ScmPair
       (ScmSymbol "if", ScmPair (test, ScmPair (dit, ScmPair (dif, ScmNil))))
  | ScmOr([]) -> ScmBoolean false
  | ScmOr([expr]) -> sexpr_of_expr expr
  | ScmOr(exprs) ->
     ScmPair (ScmSymbol "or",
              scheme_list_of_ocaml_list
                (List.map sexpr_of_expr exprs) ScmNil)
  | ScmSeq([]) -> ScmVoid
  | ScmSeq([expr]) -> sexpr_of_expr expr
  | ScmSeq(exprs) ->
     ScmPair(ScmSymbol "begin", 
             scheme_list_of_ocaml_list
               (List.map sexpr_of_expr exprs) ScmNil)
  | ScmVarSet(Var var, expr) ->
     let var = ScmSymbol var in
     let expr = sexpr_of_expr expr in
     ScmPair (ScmSymbol "set!", ScmPair (var, ScmPair (expr, ScmNil)))
  | ScmVarDef(Var var, expr) ->
     let var = ScmSymbol var in
     let expr = sexpr_of_expr expr in
     ScmPair (ScmSymbol "define", ScmPair (var, ScmPair (expr, ScmNil)))
  | ScmLambda(params, Simple, expr) ->
     let params = scheme_list_of_ocaml_list
                    (List.map (fun str -> ScmSymbol str) params) ScmNil in
     let expr = sexpr_of_expr expr in
     ScmPair (ScmSymbol "lambda",
              ScmPair (params,
                       ScmPair (expr, ScmNil)))
  | ScmLambda([], Opt opt, expr) ->
     let expr = sexpr_of_expr expr in
     let opt = ScmSymbol opt in
     ScmPair
       (ScmSymbol "lambda",
        ScmPair (opt, ScmPair (expr, ScmNil)))
  | ScmLambda(params, Opt opt, expr) ->
     let expr = sexpr_of_expr expr in
     let opt = ScmSymbol opt in
     let params = List.fold_right
                    (fun param sexpr -> ScmPair(ScmSymbol param, sexpr))
                    params
                    opt in
     ScmPair
       (ScmSymbol "lambda", ScmPair (params, ScmPair (expr, ScmNil)))
  | ScmApplic (ScmLambda (params, Simple, expr), args) ->
     if List.length params = List.length args then
     let ribs =
       scheme_list_of_ocaml_list
         (List.map2
              (fun param arg ->
                 ScmPair (ScmSymbol param, ScmPair (sexpr_of_expr arg, ScmNil)))
            params
              args)
           ScmNil in
     let expr = sexpr_of_expr expr in
       ScmPair (ScmSymbol "let",
                ScmPair (ribs, ScmPair (expr, ScmNil)))
     else
       (* fall back: print it as a regular application *)
       let proc = sexpr_of_expr (ScmLambda (params, Simple, expr)) in
       let args = scheme_list_of_ocaml_list (List.map sexpr_of_expr args) ScmNil in
       ScmPair (proc, args)
  | ScmApplic (proc, args) ->
     let proc = sexpr_of_expr proc in
     let args =
       scheme_list_of_ocaml_list
         (List.map sexpr_of_expr args) ScmNil in
     ScmPair (proc, args);;

let string_of_expr expr =
  Printf.sprintf "%a" sprint_sexpr (sexpr_of_expr expr);;

let print_expr chan expr =
  output_string chan
    (string_of_expr expr);;

let print_exprs chan exprs =
  output_string chan
    (Printf.sprintf "[%s]"
       (String.concat "; "
          (List.map string_of_expr exprs)));;

let sprint_expr _ expr = string_of_expr expr;;

let sprint_exprs chan exprs =
  Printf.sprintf "[%s]"
    (String.concat "; "
       (List.map string_of_expr exprs));;

(* semantic analysis *)

type app_kind = Tail_Call | Non_Tail_Call;;

type lexical_address =
  | Free
  | Param of int
  | Bound of int * int;;

type var' = Var' of string * lexical_address;;

type expr' =
  | ScmConst' of sexpr
  | ScmVarGet' of var'
  | ScmIf' of expr' * expr' * expr'
  | ScmSeq' of expr' list
  | ScmOr' of expr' list
  | ScmVarSet' of var' * expr'
  | ScmVarDef' of var' * expr'
  | ScmBox' of var'
  | ScmBoxGet' of var'
  | ScmBoxSet' of var' * expr'
  | ScmLambda' of string list * lambda_kind * expr'
  | ScmApplic' of expr' * expr' list * app_kind;;

module type SEMANTIC_ANALYSIS = sig
  val annotate_lexical_address : expr -> expr'
  val annotate_tail_calls : expr' -> expr'
  val auto_box : expr' -> expr'
  val semantics : expr -> expr'  
end;; (* end of signature SEMANTIC_ANALYSIS *)

module Semantic_Analysis : SEMANTIC_ANALYSIS = struct

  let rec lookup_in_rib name = function
    | [] -> None
    | name' :: rib ->
       if name = name'
       then Some(0)
       else (match (lookup_in_rib name rib) with
             | None -> None
             | Some minor -> Some (minor + 1));;

  let rec lookup_in_env name = function
    | [] -> None
    | rib :: env ->
       (match (lookup_in_rib name rib) with
        | None ->
           (match (lookup_in_env name env) with
            | None -> None
            | Some(major, minor) -> Some(major + 1, minor))
        | Some minor -> Some(0, minor));;

  let tag_lexical_address_for_var name params env = 
    match (lookup_in_rib name params) with
    | None ->
       (match (lookup_in_env name env) with
        | None -> Var' (name, Free)
        | Some(major, minor) -> Var' (name, Bound (major, minor)))
    | Some minor -> Var' (name, Param minor);;

  (* run this first *)
  let annotate_lexical_address =
    let rec run expr params env =
      match expr with
      | ScmConst sexpr -> ScmConst' sexpr
      | ScmVarGet (Var str) ->
         ScmVarGet' (tag_lexical_address_for_var str params env)
      | ScmIf (test, dit, dif) ->
         ScmIf'(run test params env,
                run dit params env,
                run dif params env)
      | ScmSeq exprs ->
         ScmSeq' (List.map (fun expr -> run expr params env) exprs)
      | ScmOr exprs ->
         ScmOr' (List.map (fun expr -> run expr params env) exprs)
      | ScmVarSet(Var v, expr) ->
         ScmVarSet' ((tag_lexical_address_for_var v params env),
                     run expr params env)
      (* this code does not [yet?] support nested define-expressions *)
      | ScmVarDef(Var v, expr) ->
         ScmVarDef' (Var' (v, Free), run expr params env)
      | ScmLambda (params', Simple, expr) ->
         (* Add current params to env, use params' as new params for body *)
         let new_env = params :: env in
         let new_body = run expr params' new_env in
         ScmLambda' (params', Simple, new_body)
      | ScmLambda (params', Opt opt, expr) ->
         (* Append opt to params' to get full parameter list *)
         let full_params' = params' @ [opt] in
         (* Add current params to env, use full_params' as new params for body *)
         let new_env = params :: env in
         let new_body = run expr full_params' new_env in
         ScmLambda' (params', Opt opt, new_body)
      | ScmApplic (proc, args) ->
         (* Process proc and all args, create ScmApplic' with Non_Tail_Call *)
         (* (app_kind will be corrected by annotate_tail_calls later) *)
         let proc' = run proc params env in
         let args' = List.map (fun arg -> run arg params env) args in
         ScmApplic' (proc', args', Non_Tail_Call)
    in
    fun expr -> run expr [] [];;

  (* run this second *)
  let annotate_tail_calls = 
    let rec run in_tail = function
      | (ScmConst' _) as orig -> orig
      | (ScmVarGet' _) as orig -> orig
      | ScmIf' (test, dit, dif) ->
         ScmIf'(run false test,
                run in_tail dit,
                run in_tail dif)
      | ScmSeq' [] -> ScmConst' ScmVoid
      | ScmSeq' (expr :: exprs) -> ScmSeq' (runl in_tail expr exprs)
      | ScmOr' [] -> ScmConst' (ScmBoolean false)
      | ScmOr' (expr :: exprs) -> ScmOr' (runl in_tail expr exprs)
      | ScmVarSet' (var', expr') -> ScmVarSet' (var', run false expr')
      | ScmVarDef' (var', expr') -> ScmVarDef' (var', run false expr')
      | (ScmBox' _) as expr' -> expr'
      | (ScmBoxGet' _) as expr' -> expr'
      | ScmBoxSet' (var', expr') -> ScmBoxSet' (var', run false expr')
      | ScmLambda' (params, kind, expr) ->
         (* Lambda body is in tail position *)
         ScmLambda' (params, kind, run true expr)
      | ScmApplic' (proc, args, app_kind) ->
         (* Determine app_kind based on in_tail *)
         let app_kind' = if in_tail then Tail_Call else Non_Tail_Call in
         (* Process proc and args in non-tail context *)
         let proc' = run false proc in
         let args' = List.map (fun arg -> run false arg) args in
         ScmApplic' (proc', args', app_kind')
    and runl in_tail expr = function
      | [] -> [run in_tail expr]
      | expr' :: exprs -> (run false expr) :: (runl in_tail expr' exprs)
    in fun expr' -> run false expr';;

  (* auto_box *)

  let copy_list = List.map (fun si -> si);;

  let combine_pairs =
    List.fold_left
      (fun (rs1, ws1) (rs2, ws2) -> (rs1 @ rs2, ws1 @ ws2))
      ([], []);;

  let find_reads_and_writes =
    let rec run name expr params env =
      match expr with
      | ScmConst' _ -> ([], [])
      | ScmVarGet' (Var' (_, Free)) -> ([], [])
      | ScmVarGet' (Var' (name', _) as v) when name = name' -> ([(v, env)], [])
      | ScmVarGet' (Var' (name', _)) -> ([], [])
      | ScmBox' _ -> ([], [])
      | ScmBoxGet' _ -> ([], [])
      | ScmBoxSet' (_, expr) -> run name expr params env
      | ScmIf' (test, dit, dif) ->
         let (rs1, ws1) = (run name test params env) in
         let (rs2, ws2) = (run name dit params env) in
         let (rs3, ws3) = (run name dif params env) in
         (rs1 @ rs2 @ rs3, ws1 @ ws2 @ ws3)
      | ScmSeq' exprs ->
         combine_pairs
           (List.map
              (fun expr -> run name expr params env)
              exprs)
      | ScmVarSet' (Var' (_, Free), expr) -> run name expr params env
      | ScmVarSet' ((Var' (name', _) as v), expr) ->
         let (rs1, ws1) =
           if name = name'
           then ([], [(v, env)])
           else ([], []) in
         let (rs2, ws2) = run name expr params env in
         (rs1 @ rs2, ws1 @ ws2)
      | ScmVarDef' (_, expr) -> run name expr params env
      | ScmOr' exprs ->
         combine_pairs
           (List.map
              (fun expr -> run name expr params env)
              exprs)
      | ScmLambda' (params', Simple, expr) ->
         if (List.mem name params')
         then ([], [])
         else run name expr params' ((copy_list params) :: env)
      | ScmLambda' (params', Opt opt, expr) ->
         let params' = params' @ [opt] in
         if (List.mem name params')
         then ([], [])
         else run name expr params' ((copy_list params) :: env)
      | ScmApplic' (proc, args, app_kind) ->
         let (rs1, ws1) = run name proc params env in
         let (rs2, ws2) = 
           combine_pairs
             (List.map
                (fun arg -> run name arg params env)
                args) in
         (rs1 @ rs2, ws1 @ ws2)
    in
    fun name expr params ->
    run name expr params [];;
  
  let cross_product as' bs' =
    List.concat (List.map (fun ai ->
                     List.map (fun bj -> (ai, bj)) bs')
                   as');;

  let should_box_var name expr params =
    let (reads, writes) = find_reads_and_writes name expr params in
    let rsXws = cross_product reads writes in
    let rec run = function
      | [] -> false
      | ((Var' (n1, Param _), _),
         (Var' (n2, Param _), _)) :: rest -> run rest
      | ((Var' (n1, Param _), _),
         (Var' (n2, Bound _), _)) :: _
        | ((Var' (n1, Bound _), _),
           (Var' (n2, Param _), _)) :: _ -> true
      | ((Var' (n1, Bound _), env1),
         (Var' (n2, Bound _), env2)) :: _
           when (not ((find_var_rib name env1) ==
                        (find_var_rib name env2))) -> true
      | _ :: rest -> run rest
    and find_var_rib name = function
      | [] -> assert false
      | rib :: _ when (List.mem name rib) -> (rib : string list)
      | _ :: env -> find_var_rib name env
    in run rsXws;;  

  let box_sets_and_gets name body =
    let rec run expr =
      match expr with
      | ScmConst' _ -> expr
      | ScmVarGet' (Var' (_, Free)) -> expr
      | ScmVarGet' (Var' (name', _) as v) ->
         if name = name'
         then ScmBoxGet' v
         else expr
      | ScmBox' _ -> expr
      | ScmBoxGet' _ -> expr
      | ScmBoxSet' (v, expr) -> ScmBoxSet' (v, run expr)
      | ScmIf' (test, dit, dif) ->
         ScmIf' (run test, run dit, run dif)
      | ScmSeq' exprs -> ScmSeq' (List.map run exprs)
      | ScmVarSet' (Var' (_, Free) as v, expr') ->
         ScmVarSet'(v, run expr')
      | ScmVarSet' (Var' (name', _) as v, expr') ->
         if name = name'
         then ScmBoxSet' (v, run expr')
         else ScmVarSet' (v, run expr')
      | ScmVarDef' (v, expr) -> ScmVarDef' (v, run expr)
      | ScmOr' exprs -> ScmOr' (List.map run exprs)
      | (ScmLambda' (params, Simple, expr)) as expr' ->
         if List.mem name params
         then expr'
         else ScmLambda' (params, Simple, run expr)
      | (ScmLambda' (params, Opt opt, expr)) as expr' ->
         if List.mem name (params @ [opt])
         then expr'
         else ScmLambda' (params, Opt opt, run expr)
      | ScmApplic' (proc, args, app_kind) ->
         ScmApplic' (run proc, List.map run args, app_kind)
    in
    run body;;

  let make_sets =
    let rec run minor box_these params =
      match params with
      | [] -> []
      | param :: params' ->
         if List.mem param box_these
         then let v = Var' (param, Param minor) in
              (ScmVarSet' (v, ScmBox' v)) :: (run (minor + 1) box_these params')
         else run (minor + 1) box_these params'
    in
    fun box_these params -> run 0 box_these params;;

  let rec auto_box expr =
    match expr with
    | ScmConst' _ -> expr
    | ScmVarGet' _ -> expr
    | ScmBox' _ -> expr
    | ScmBoxGet' _ -> expr
    | ScmBoxSet' (v, expr) ->
       ScmBoxSet' (v, auto_box expr)
    | ScmIf' (test, dit, dif) ->
       ScmIf' (auto_box test, auto_box dit, auto_box dif)
    | ScmSeq' exprs -> ScmSeq' (List.map auto_box exprs)
    | ScmVarSet' (v, expr) -> ScmVarSet' (v, auto_box expr)
    | ScmVarDef' (v, expr) -> ScmVarDef' (v, auto_box expr)
    | ScmOr' exprs -> ScmOr' (List.map auto_box exprs)
    | ScmLambda' (params, Simple, expr') ->
       let box_these =
         List.filter
           (fun param -> should_box_var param expr' params)
           params in
       let new_body = 
         List.fold_left
           (fun body name -> box_sets_and_gets name body)
           (auto_box expr')
           box_these in
       let new_sets = make_sets box_these params in
       let new_body = 
         match box_these, new_body with
         | [], _ -> new_body
         | _, ScmSeq' exprs -> ScmSeq' (new_sets @ exprs)
         | _, _ -> ScmSeq'(new_sets @ [new_body]) in
       ScmLambda' (params, Simple, new_body)
    | ScmLambda' (params, Opt opt, expr') ->
       let params' = params @ [opt] in
       let box_these =
         List.filter
           (fun param -> should_box_var param expr' params')
           params' in
       let new_body = 
         List.fold_left
           (fun body name -> box_sets_and_gets name body)
           (auto_box expr')
           box_these in
       let new_sets = make_sets box_these params' in
       let new_body = 
         match box_these, new_body with
         | [], _ -> new_body
         | _, ScmSeq' exprs -> ScmSeq' (new_sets @ exprs)
         | _, _ -> ScmSeq' (new_sets @ [new_body]) in
       ScmLambda' (params, Opt opt, new_body)
    | ScmApplic' (proc, args, app_kind) ->
       ScmApplic' (auto_box proc, List.map auto_box args, app_kind);;

  let semantics expr =
    auto_box
      (annotate_tail_calls
         (annotate_lexical_address expr));;

end;; (* end of module Semantic_Analysis *)

let sem str = Semantic_Analysis.semantics (parse str);;

let sexpr_of_var' (Var' (name, _)) = ScmSymbol name;;

let rec sexpr_of_expr' = function
  | ScmConst' (ScmVoid) -> ScmVoid
  | ScmConst' ((ScmBoolean _) as sexpr) -> sexpr
  | ScmConst' ((ScmChar _) as sexpr) -> sexpr
  | ScmConst' ((ScmString _) as sexpr) -> sexpr
  | ScmConst' ((ScmNumber _) as sexpr) -> sexpr
  | ScmConst' ((ScmSymbol _) as sexpr) ->
     ScmPair (ScmSymbol "quote", ScmPair (sexpr, ScmNil))
  | ScmConst'(ScmNil as sexpr) ->
     ScmPair (ScmSymbol "quote", ScmPair (sexpr, ScmNil))
  | ScmConst' ((ScmVector _) as sexpr) ->
     ScmPair (ScmSymbol "quote", ScmPair (sexpr, ScmNil))      
  | ScmVarGet' var -> sexpr_of_var' var
  | ScmIf' (test, dit, ScmConst' ScmVoid) ->
     let test = sexpr_of_expr' test in
     let dit = sexpr_of_expr' dit in
     ScmPair (ScmSymbol "if", ScmPair (test, ScmPair (dit, ScmNil)))
  | ScmIf' (e1, e2, ScmConst' (ScmBoolean false)) ->
     let e1 = sexpr_of_expr' e1 in
     (match (sexpr_of_expr' e2) with
      | ScmPair (ScmSymbol "and", exprs) ->
         ScmPair (ScmSymbol "and", ScmPair(e1, exprs))
      | e2 -> ScmPair (ScmSymbol "and", ScmPair (e1, ScmPair (e2, ScmNil))))
  | ScmIf' (test, dit, dif) ->
     let test = sexpr_of_expr' test in
     let dit = sexpr_of_expr' dit in
     let dif = sexpr_of_expr' dif in
     ScmPair
       (ScmSymbol "if", ScmPair (test, ScmPair (dit, ScmPair (dif, ScmNil))))
  | ScmOr'([]) -> ScmBoolean false
  | ScmOr'([expr']) -> sexpr_of_expr' expr'
  | ScmOr'(exprs) ->
     ScmPair (ScmSymbol "or",
              scheme_list_of_ocaml_list
                (List.map sexpr_of_expr' exprs) ScmNil)
  | ScmSeq' ([]) -> ScmVoid
  | ScmSeq' ([expr]) -> sexpr_of_expr' expr
  | ScmSeq' (exprs) ->
     ScmPair (ScmSymbol "begin", 
              scheme_list_of_ocaml_list
                (List.map sexpr_of_expr' exprs) ScmNil)
  | ScmVarSet' (var, expr) ->
     let var = sexpr_of_var' var in
     let expr = sexpr_of_expr' expr in
     ScmPair (ScmSymbol "set!", ScmPair (var, ScmPair (expr, ScmNil)))
  | ScmVarDef' (var, expr) ->
     let var = sexpr_of_var' var in
     let expr = sexpr_of_expr' expr in
     ScmPair (ScmSymbol "define", ScmPair (var, ScmPair (expr, ScmNil)))
  | ScmLambda' (params, Simple, expr) ->
     let expr = sexpr_of_expr' expr in
     let params = scheme_list_of_ocaml_list
                    (List.map (fun str -> ScmSymbol str) params) ScmNil in
     ScmPair (ScmSymbol "lambda",
              ScmPair (params,
                       ScmPair (expr, ScmNil)))
  | ScmLambda' ([], Opt opt, expr) ->
     let expr = sexpr_of_expr' expr in
     let opt = ScmSymbol opt in
     ScmPair
       (ScmSymbol "lambda",
        ScmPair (opt, ScmPair (expr, ScmNil)))
  | ScmLambda' (params, Opt opt, expr) ->
     let expr = sexpr_of_expr' expr in
     let opt = ScmSymbol opt in
     let params = List.fold_right
                    (fun param sexpr -> ScmPair(ScmSymbol param, sexpr))
                    params
                    opt in
     ScmPair
       (ScmSymbol "lambda", ScmPair (params, ScmPair (expr, ScmNil)))
  | ScmApplic' (ScmLambda' (params, Simple, expr), args, app_kind) ->
     if List.length params = List.length args then
     let ribs =
       scheme_list_of_ocaml_list
         (List.map2
              (fun param arg ->
                 ScmPair (ScmSymbol param, ScmPair (sexpr_of_expr' arg, ScmNil)))
            params
              args)
           ScmNil in
     let expr = sexpr_of_expr' expr in
       ScmPair (ScmSymbol "let",
                ScmPair (ribs, ScmPair (expr, ScmNil)))
     else
       let proc = sexpr_of_expr' (ScmLambda' (params, Simple, expr)) in
       let args = scheme_list_of_ocaml_list (List.map sexpr_of_expr' args) ScmNil in
       ScmPair (proc, args)
  | ScmApplic' (proc, args, app_kind) ->
     let proc = sexpr_of_expr' proc in
     let args =
       scheme_list_of_ocaml_list
         (List.map sexpr_of_expr' args) ScmNil in
     ScmPair (proc, args)
  | ScmBox' v ->
     let v = sexpr_of_var' v in
     ScmPair (ScmSymbol "make-box", ScmPair (v, ScmNil))
  | ScmBoxGet' v ->
     let v = sexpr_of_var' v in
     ScmPair (ScmSymbol "box-value", ScmPair (v, ScmNil))
  | ScmBoxSet' (v, e) ->
     let v = sexpr_of_var' v 
     and e = sexpr_of_expr' e in
     ScmPair (ScmSymbol "box-set!", ScmPair (v, ScmPair (e, ScmNil)))
  (* for reversing macro-expanded forms... *)
  | _ -> ScmVoid;;

let string_of_expr' expr =
  Printf.sprintf "%a" sprint_sexpr (sexpr_of_expr' expr);;

let print_expr' chan expr =
  output_string chan
    (string_of_expr' expr);;

let print_exprs' chan exprs =
  output_string chan
    (Printf.sprintf "[%s]"
       (String.concat "; "
          (List.map string_of_expr' exprs)));;

let sprint_expr' _ expr = string_of_expr' expr;;

let sprint_exprs' chan exprs =
  Printf.sprintf "[%s]"
    (String.concat "; "
       (List.map string_of_expr' exprs));;

(* append this file to the end of your compiler.ml *)

let file_to_string input_file =
  let in_channel = open_in input_file in
  let rec run () =
    try 
      let ch = input_char in_channel in ch :: (run ())
    with End_of_file ->
      ( close_in in_channel;
	[] )
  in string_of_list (run ());;

let string_to_file output_file out_string =
  let out_channel = open_out output_file in
  ( output_string out_channel out_string;
    close_out out_channel );;

let remove_duplicates =
  let rec run singles = function
    | [] -> singles
    | sexpr :: sexprs when List.mem sexpr singles -> run singles sexprs
    | sexpr :: sexprs -> run (singles @ [sexpr]) sexprs
  in fun sexprs -> run [] sexprs;;

module type CODE_GENERATION =
  sig
    val use_init_file : unit -> unit
    val do_not_use_init_file : unit -> unit
    val compile_scheme_string : string -> string -> unit
    val compile_scheme_file : string -> string -> unit
    val compile_and_run_scheme_string : string -> string -> unit
  end;;

module Code_Generation : CODE_GENERATION = struct
  let init_file_name = "init.scm";;
  let init_file = ref true;;

  let use_init_file () = init_file := true;;

  let do_not_use_init_file () = init_file := false;;

  let get_source_code user = 
    if !init_file
    then let init = file_to_string init_file_name in
         init ^ "\n" ^ user
    else user;;

  let word_size = 8;;
  let label_start_of_constants_table = "L_constants";;
  let comment_length = 20;;

  let global_bindings_table =
    [ (* 1-10 *)
      ("null?", "L_code_ptr_is_null");
      ("pair?", "L_code_ptr_is_pair");
      ("void?", "L_code_ptr_is_void");
      ("char?", "L_code_ptr_is_char");
      ("string?", "L_code_ptr_is_string");
      ("interned-symbol?", "L_code_ptr_is_symbol");
      ("vector?", "L_code_ptr_is_vector");
      ("procedure?", "L_code_ptr_is_closure");
      ("real?", "L_code_ptr_is_real");
      ("fraction?", "L_code_ptr_is_fraction");
      (* 11-20 *)
      ("boolean?", "L_code_ptr_is_boolean");
      ("number?", "L_code_ptr_is_number");
      ("collection?", "L_code_ptr_is_collection");
      ("cons", "L_code_ptr_cons");
      ("display-sexpr", "L_code_ptr_display_sexpr");
      ("write-char", "L_code_ptr_write_char");
      ("car", "L_code_ptr_car");
      ("cdr", "L_code_ptr_cdr");
      ("string-length", "L_code_ptr_string_length");
      ("vector-length", "L_code_ptr_vector_length");
      (* 21-30*)
      ("real->integer", "L_code_ptr_real_to_integer");
      ("exit", "L_code_ptr_exit");
      ("integer->real", "L_code_ptr_integer_to_real");
      ("fraction->real", "L_code_ptr_fraction_to_real");
      ("char->integer", "L_code_ptr_char_to_integer");
      ("integer->char", "L_code_ptr_integer_to_char");
      ("trng", "L_code_ptr_trng");
      ("zero?", "L_code_ptr_is_zero");
      ("integer?", "L_code_ptr_is_integer");
      ("__bin-apply", "L_code_ptr_bin_apply");
      (* 31-40*)
      ("__bin-add-rr", "L_code_ptr_raw_bin_add_rr");
      ("__bin-sub-rr", "L_code_ptr_raw_bin_sub_rr");
      ("__bin-mul-rr", "L_code_ptr_raw_bin_mul_rr");
      ("__bin-div-rr", "L_code_ptr_raw_bin_div_rr");
      ("__bin-add-qq", "L_code_ptr_raw_bin_add_qq");
      ("__bin-sub-qq", "L_code_ptr_raw_bin_sub_qq");
      ("__bin-mul-qq", "L_code_ptr_raw_bin_mul_qq");
      ("__bin-div-qq", "L_code_ptr_raw_bin_div_qq");
      ("__bin-add-zz", "L_code_ptr_raw_bin_add_zz");
      ("__bin-sub-zz", "L_code_ptr_raw_bin_sub_zz");
      (* 41-50 *)      
      ("__bin-mul-zz", "L_code_ptr_raw_bin_mul_zz");
      ("__bin-div-zz", "L_code_ptr_raw_bin_div_zz");
      ("error", "L_code_ptr_error");
      ("__bin-less-than-rr", "L_code_ptr_raw_less_than_rr");
      ("__bin-less-than-qq", "L_code_ptr_raw_less_than_qq");
      ("__bin-less-than-zz", "L_code_ptr_raw_less_than_zz");
      ("__bin-equal-rr", "L_code_ptr_raw_equal_rr");
      ("__bin-equal-qq", "L_code_ptr_raw_equal_qq");
      ("__bin-equal-zz", "L_code_ptr_raw_equal_zz");
      ("quotient", "L_code_ptr_quotient");
      (* 51-60 *)
      ("remainder", "L_code_ptr_remainder");
      ("set-car!", "L_code_ptr_set_car");
      ("set-cdr!", "L_code_ptr_set_cdr");
      ("string-ref", "L_code_ptr_string_ref");
      ("vector-ref", "L_code_ptr_vector_ref");
      ("vector-set!", "L_code_ptr_vector_set");
      ("string-set!", "L_code_ptr_string_set");
      ("make-vector", "L_code_ptr_make_vector");
      ("make-string", "L_code_ptr_make_string");
      ("numerator", "L_code_ptr_numerator");
      (* 61-70 *)
      ("denominator", "L_code_ptr_denominator");
      ("eq?", "L_code_ptr_is_eq");
      ("__integer-to-fraction", "L_code_ptr_integer_to_fraction");
      ("logand", "L_code_ptr_logand");
      ("logor", "L_code_ptr_logor");
      ("logxor", "L_code_ptr_logxor");
      ("lognot", "L_code_ptr_lognot");
      ("ash", "L_code_ptr_ash");
      ("symbol?", "L_code_ptr_is_symbol");
      ("uninterned-symbol?", "L_code_ptr_is_uninterned_symbol");
      (* 71-80 *)
      ("gensym?", "L_code_ptr_is_uninterned_symbol");
      ("interned-symbol?", "L_code_ptr_is_interned_symbol");
      ("gensym", "L_code_ptr_gensym");
      ("frame", "L_code_ptr_frame");
      ("break", "L_code_ptr_break");
      ("boolean-false?", "L_code_ptr_is_boolean_false");
      ("boolean-true?", "L_code_ptr_is_boolean_true");
      ("primitive?", "L_code_ptr_is_primitive");
      ("length", "L_code_ptr_length");
      ("make-list", "L_code_ptr_make_list");
      ("return", "L_code_ptr_return");
    ];;  

  let collect_constants =
    let rec run = function
      | ScmVarGet' (Var' (v, Free)) -> [ScmString v]
      | ScmVarGet' _ | ScmBox' _ | ScmBoxGet' _ -> []
      | ScmConst' sexpr -> [sexpr]
      | ScmIf' (test, dit, dif) ->
         (run test) @ (run dit) @ (run dif)
      | ScmSeq' exprs' -> runs exprs'
      | ScmOr' exprs' -> runs exprs'
      | ScmVarDef' (Var' (v, Free), expr') 
        | ScmVarSet' (Var' (v, Free), expr') ->
         (ScmString v) :: (run expr')
      | ScmVarSet' (_, expr') 
        | ScmVarDef' (_, expr') 
        | ScmBoxSet' (_, expr') 
        | ScmLambda' (_, _, expr') -> run expr'
      | ScmApplic' (expr', exprs', _) -> (run expr') @ (runs exprs')
    and runs exprs' =
      List.fold_left (fun consts expr' -> consts @ (run expr')) [] exprs'
    in
    fun exprs' ->
    (List.map
       (fun (scm_name, _) -> ScmString scm_name)
       global_bindings_table)
    @ (runs exprs');;

  let add_sub_constants =
    let rec run sexpr = match sexpr with
      | ScmVoid | ScmNil | ScmBoolean _ -> []
      | ScmChar _ | ScmString _ | ScmNumber _ -> [sexpr]
      | ScmSymbol sym -> [ScmString sym; ScmSymbol sym]
      | ScmPair (car, cdr) -> (run car) @ (run cdr) @ [sexpr]
      | ScmVector sexprs -> (runs sexprs) @ [sexpr]
    and runs sexprs =
      List.fold_left (fun full sexpr -> full @ (run sexpr)) [] sexprs
    in fun exprs' ->
       [ScmVoid; ScmNil; ScmBoolean false; ScmBoolean true; ScmChar '\000']
       @ (runs exprs');;

  type initialized_data =
    | RTTI of string
    | Byte of int
    | ASCII of string
    | Quad of int
    | QuadFloat of float
    | ConstPtr of int;;

  let search_constant_address =
    let rec run sexpr = function
      | [] -> assert false
      | (sexpr', loc, _repr) :: sexprs when sexpr = sexpr' -> loc
      | _ :: sexprs -> run sexpr sexprs
    in run;;

  let const_repr sexpr table = match sexpr with
    | ScmVoid -> ([RTTI "T_void"], 1)
    | ScmNil -> ([RTTI "T_nil"], 1)
    | ScmBoolean false ->
       ([RTTI "T_boolean_false"], 1)
    | ScmBoolean true ->
       ([RTTI "T_boolean_true"], 1)
    | ScmChar ch ->
       ([RTTI "T_char"; Byte (int_of_char ch)], 2)
    | ScmString str ->
       let count = String.length str in
       ([RTTI "T_string"; Quad count; ASCII str],
        1 + word_size + count)
    | ScmSymbol sym ->
       let addr = search_constant_address (ScmString sym) table in
       ([RTTI "T_interned_symbol"; ConstPtr addr], 1 + word_size)
    | ScmNumber (ScmInteger n) ->
       ([RTTI "T_integer"; Quad n], 1 + word_size)
    | ScmNumber (ScmFraction (numerator, denominator)) ->
       ([RTTI "T_fraction"; Quad numerator; Quad denominator],
        1 + 2 * word_size)
    | ScmNumber (ScmReal x) ->
       ([RTTI "T_real"; QuadFloat x], 1 + word_size)
    | ScmVector s ->
       let addrs =
         List.map
           (fun si -> ConstPtr (search_constant_address si table)) s in
       let count = List.length s in
       ((RTTI "T_vector") :: (Quad count) :: addrs,
        1 + (count + 1) * word_size)
    | ScmPair (car, cdr) ->
       let (addr_car, addr_cdr) =
         (search_constant_address car table,
          search_constant_address cdr table) in
       ([RTTI "T_pair"; ConstPtr addr_car; ConstPtr addr_cdr],
        1 + 2 * word_size);;

  let make_constants_table =
    let rec run table loc = function
      | [] -> table
      | sexpr :: sexprs ->
         let (repr, len) = const_repr sexpr table in
         run (table @ [(sexpr, loc, repr)]) (loc + len) sexprs
    in
    fun exprs' ->
    run [] 0
      (remove_duplicates
         (add_sub_constants
            (remove_duplicates
               (collect_constants exprs'))));;    

  let asm_comment_of_sexpr sexpr =
    let str = string_of_sexpr sexpr in
    let str =
      if (String.length str) <= comment_length
      then str
      else (String.sub str 0 comment_length) ^ "..." in
    "; " ^ str;;

  let asm_of_representation sexpr =
    let str = asm_comment_of_sexpr sexpr in
    let run = function
      | [RTTI str] -> Printf.sprintf "\tdb %s" str
      | [RTTI "T_char"; Byte byte] ->
         Printf.sprintf "\tdb T_char, 0x%02X\t%s" byte str
      | [RTTI "T_string"; Quad length; ASCII const_str] ->
         Printf.sprintf "\tdb T_string\t%s\n\tdq %d%s"
           str length
           (let s = list_of_string const_str in
            let s = List.map
                      (fun ch -> Printf.sprintf "0x%02X" (int_of_char ch))
                      s in
            let s = split_to_sublists 8 s in
            let s = List.map (fun si -> "\n\tdb " ^ (String.concat ", " si)) s in
            String.concat "" s)
      | [RTTI "T_interned_symbol"; ConstPtr addr] ->
         Printf.sprintf "\tdb T_interned_symbol\t%s\n\tdq %s + %d"
           str label_start_of_constants_table addr
      | [RTTI "T_integer"; Quad n] ->
         Printf.sprintf "\tdb T_integer\t%s\n\tdq %d" str n
      | [RTTI "T_fraction"; Quad numerator; Quad denominator] ->
         Printf.sprintf "\tdb T_fraction\t%s\n\tdq %d, %d"
           str
           numerator denominator
      | [RTTI "T_real"; QuadFloat x] ->
         Printf.sprintf "\tdb T_real\t%s\n\tdq %f" str x
      | (RTTI "T_vector") :: (Quad length) :: addrs ->
         Printf.sprintf "\tdb T_vector\t%s\n\tdq %d%s"
           str length
           (let s = List.map
                      (function
                       | ConstPtr ptr ->
                          Printf.sprintf "%s + %d"
                            label_start_of_constants_table ptr
                       | _ -> assert false)
                      addrs in
            let s = split_to_sublists 3 s in
            let s = List.map (fun si -> "\n\tdq " ^ (String.concat ", " si)) s in
            String.concat "" s)
      | [RTTI "T_pair"; ConstPtr car; ConstPtr cdr] ->
         Printf.sprintf "\tdb T_pair\t%s\n\tdq %s + %d, %s + %d"
           str
           label_start_of_constants_table car
           label_start_of_constants_table cdr
      | _ -> assert false
    in run;;

  let asm_of_constants_table =
    let rec run = function
      | [] -> ""
      | (sexpr, loc, repr) :: rest ->
         (Printf.sprintf "\t; %s + %d:\n" label_start_of_constants_table loc)
         ^ (asm_of_representation sexpr repr) ^ "\n" ^ (run rest)
    in
    fun table ->
    Printf.sprintf "%s:\n%s"
      label_start_of_constants_table (run table);;

  let collect_free_vars =
    let rec run = function
      | ScmConst' _ -> []
      | ScmVarGet' (Var' (v, Free)) -> [v]
      | ScmVarGet' _ -> []
      | ScmIf' (test, dit, dif) -> (run test) @ (run dit) @ (run dif)
      | ScmSeq' exprs' -> runs exprs'
      | ScmOr' exprs' -> runs exprs'
      | ScmVarSet' (Var' (v, Free), expr') -> v :: (run expr')
      | ScmVarSet' (_, expr') -> run expr'
      | ScmVarDef' (Var' (v, Free), expr') -> v :: (run expr')
      | ScmVarDef' (_, expr') -> run expr'
      | ScmBox' _ -> []
      | ScmBoxGet' _ -> []
      | ScmBoxSet' (_, expr') -> run expr'
      | ScmLambda' (_, _, expr') -> run expr'
      | ScmApplic' (expr', exprs', _) -> (run expr') @ (runs exprs')
    and runs exprs' =
      List.fold_left
        (fun vars expr' -> vars @ (run expr'))
        []
        exprs'
    in fun exprs' -> remove_duplicates (runs exprs');;

  let make_free_vars_table =
    let rec run index = function
      | [] -> []
      | v :: vars ->
         let x86_label = Printf.sprintf "free_var_%d" index in
         (v, x86_label) :: (run (index + 1) vars)
    in fun exprs' ->
       run 0 (List.sort String.compare (collect_free_vars exprs'));;

  let search_free_var_table =
    let rec run v = function
      | [] -> assert false
      | (v', x86_label) :: _ when v = v' -> x86_label
      | _ :: table -> run v table
    in run;;

  let asm_of_global_bindings global_bindings_table free_var_table =
    String.concat "\n"
      (List.map
         (fun (scheme_name, asm_code_ptr) ->
           let free_var_label =
             search_free_var_table scheme_name free_var_table in
           (Printf.sprintf "\t; building closure for %s\n" scheme_name)
           ^ (Printf.sprintf "\tmov rdi, %s\n" free_var_label)
           ^ (Printf.sprintf "\tmov rsi, %s\n" asm_code_ptr)
           ^ "\tcall bind_primitive\n")
         (List.filter
            (fun (scheme_name, _asm_code_ptr) ->
              match (List.assoc_opt scheme_name free_var_table) with
              | None -> false
              | Some _ -> true)
            global_bindings_table));;
  
  let asm_of_free_vars_table fvars_table consts_table=
    let tmp = 
      List.map
        (fun (scm_var, asm_label) ->
          let addr =
            search_constant_address (ScmString scm_var) consts_table in
          (Printf.sprintf "%s:\t; location of %s\n" 
             asm_label scm_var)
          ^ "\tdq .undefined_object\n"
          ^ ".undefined_object:\n"
          ^ "\tdb T_undefined\n"
          ^ (Printf.sprintf "\tdq L_constants + %d\n"
               addr))
        fvars_table in
    String.concat "\n" tmp;;

  let make_make_label prefix =
    let index = ref 0 in
    fun () ->
    (index := !index + 1;
     Printf.sprintf "%s_%04x" prefix !index);;

  let make_if_else = make_make_label ".L_if_else";;
  let make_if_end = make_make_label ".L_if_end";;
  let make_or_end = make_make_label ".L_or_end";;
  let make_lambda_simple_loop_env =
    make_make_label ".L_lambda_simple_env_loop";;
  let make_lambda_simple_loop_env_end =
    make_make_label ".L_lambda_simple_env_end";;
  let make_lambda_simple_loop_params =
    make_make_label ".L_lambda_simple_params_loop";;
  let make_lambda_simple_loop_params_end =
    make_make_label ".L_lambda_simple_params_end";;
  let make_lambda_simple_code = make_make_label ".L_lambda_simple_code";;
  let make_lambda_simple_end = make_make_label ".L_lambda_simple_end";;
  let make_lambda_simple_arity_ok =
    make_make_label ".L_lambda_simple_arity_check_ok";;

  let make_lambda_opt_loop_env =
    make_make_label ".L_lambda_opt_env_loop";;
  let make_lambda_opt_loop_env_end =
    make_make_label ".L_lambda_opt_env_end";;
  let make_lambda_opt_loop_params =
    make_make_label ".L_lambda_opt_params_loop";;
  let make_lambda_opt_loop_params_end =
    make_make_label ".L_lambda_opt_params_end";;
  let make_lambda_opt_code = make_make_label ".L_lambda_opt_code";;
  let make_lambda_opt_end = make_make_label ".L_lambda_opt_end";;
  let make_lambda_opt_arity_exact =
    make_make_label ".L_lambda_opt_arity_check_exact";;
  let make_lambda_opt_arity_more =
    make_make_label ".L_lambda_opt_arity_check_more";;
  let make_lambda_opt_stack_ok =
    make_make_label ".L_lambda_opt_stack_adjusted";;
  let make_lambda_opt_loop =
    make_make_label ".L_lambda_opt_stack_shrink_loop";;
  let make_lambda_opt_loop_exit =
    make_make_label ".L_lambda_opt_stack_shrink_loop_exit";;
  let make_tc_applic_recycle_frame_loop =
    make_make_label ".L_tc_recycle_frame_loop";;
  let make_tc_applic_recycle_frame_done =
    make_make_label ".L_tc_recycle_frame_done";;

  let code_gen exprs' =
    let consts = make_constants_table exprs' in
    let free_vars = make_free_vars_table exprs' in
    let rec run params env = function
      | ScmConst' sexpr ->
         let addr = search_constant_address sexpr consts in
         Printf.sprintf "\tmov rax, L_constants + %d\n" addr
      | ScmVarGet' (Var' (v, Free)) ->
         let label = search_free_var_table v free_vars in
         (Printf.sprintf
            "\tmov rax, qword [%s]\t; free var %s\n"
            label v)
         ^ "\tcmp byte [rax], T_undefined\n"
         ^ "\tje L_error_fvar_undefined\n"
      | ScmVarGet' (Var' (v, Param minor)) ->
         Printf.sprintf "\tmov rax, PARAM(%d)\t; param %s\n"
           minor v
      | ScmVarGet' (Var' (v, Bound (major, minor))) ->
         "\tmov rax, ENV\n"
         ^ (Printf.sprintf "\tmov rax, qword [rax + 8 * %d]\n" major)
         ^ (Printf.sprintf
              "\tmov rax, qword [rax + 8 * %d]\t; bound var %s\n" minor v)
      | ScmIf' (test, dit, dif) ->
         let test_code = run params env test
         and dit_code = run params env dit
         and dif_code = run params env dif
         and label_else = make_if_else ()
         and label_end = make_if_end () in
         test_code
         ^ "\tcmp rax, sob_boolean_false\n"
         ^ (Printf.sprintf "\tje %s\n" label_else)
         ^ dit_code
         ^ (Printf.sprintf "\tjmp %s\n" label_end)
         ^ (Printf.sprintf "%s:\n" label_else)
         ^ dif_code
         ^ (Printf.sprintf "%s:\n" label_end)
      | ScmSeq' exprs' ->
         String.concat "\n"
           (List.map (run params env) exprs')
      | ScmOr' exprs' ->
         let label_end = make_or_end () in
         let asm_code = 
           (match (list_and_last exprs') with
            | Some (exprs', last_expr') ->
               let exprs_code =
                 String.concat ""
                   (List.map
                      (fun expr' ->
                        let expr_code = run params env expr' in
                        expr_code
                        ^ "\tcmp rax, sob_boolean_false\n"
                        ^ (Printf.sprintf "\tjne %s\n" label_end))
                      exprs') in
               let last_expr_code = run params env last_expr' in
               exprs_code
               ^ last_expr_code
               ^ (Printf.sprintf "%s:\n" label_end)
            (* and just in case someone messed up the tag-parser: *)
            | None -> run params env (ScmConst' (ScmBoolean false)))
         in asm_code
      | ScmVarSet' (Var' (v, Free), expr') ->
         let label = search_free_var_table v free_vars in
         (run params env expr')
         ^ (Printf.sprintf "\tmov qword [%s], rax\n" label)
         ^ "\tmov rax, sob_void\n"
      | ScmVarSet' (Var' (v, Param minor), ScmBox' _) ->
         "\tmov rdi, 8 * 1\n"
         ^ "\tcall malloc\n"
         ^ (Printf.sprintf "\tmov rbx, PARAM(%d)\t; boxing %s\n" minor v)
         ^ "\tmov qword [rax], rbx\n"
         ^ (Printf.sprintf "\tmov PARAM(%d), rax\n" minor)
         ^ "\tmov rax, sob_void\n"
      | ScmVarSet' (Var' (v, Param minor), expr') ->
         (run params env expr')
         ^ (Printf.sprintf
              "\tmov PARAM(%d), rax\t; param (set! %s ... )\n" minor v)
         ^ "\tmov rax, sob_void\n"
      | ScmVarSet' (Var' (v, Bound (major, minor)), expr') ->
         (run params env expr')
         ^ "\tmov rbx, ENV\n"
         ^ (Printf.sprintf "\tmov rbx, qword [rbx + 8 * %d]\n" major)
         ^ (Printf.sprintf
              "\tmov qword [rbx + 8 * %d], rax\t; bound var (set! %s ...)\n"
              minor v)
      | ScmVarDef' (Var' (v, Free), expr') ->
         let label = search_free_var_table v free_vars in
         (run params env expr')
         ^ (Printf.sprintf "\tmov qword [%s], rax\n" label)
         ^ "\tmov rax, sob_void\n"
      | ScmVarDef' (Var' (v, Param minor), expr') ->
        (run params env expr')
        ^ (Printf.sprintf "\tmov PARAM(%d), rax\t; (define %s ...) as assignment\n" minor v)
        ^ "\tmov rax, sob_void\n"
      | ScmVarDef' (Var' (v, Bound (major, minor)), expr') ->
        (run params env expr')
        ^ "\tmov rbx, ENV\n"
        ^ (Printf.sprintf "\tmov rbx, qword [rbx + 8 * %d]\n" major)
        ^ (Printf.sprintf "\tmov qword [rbx + 8 * %d], rax\t; (define %s ...) as assignment\n" minor v)
        ^ "\tmov rax, sob_void\n"
      | ScmBox' _ ->
         assert false
      | ScmBoxGet' var' ->
         (run params env (ScmVarGet' var'))
         ^ "\tmov rax, qword [rax]\n"
      | ScmBoxSet' (var', expr') ->
         (run params env expr')
         ^ "\tpush rax\n"
         ^ (run params env (ScmVarGet' var'))
         ^ "\tpop qword [rax]\n"
         ^ "\tmov rax, sob_void\n"
      | ScmLambda' (params', Simple, body) ->
         let label_arity_ok = make_lambda_simple_arity_ok ()
         and label_code = make_lambda_simple_code () 
         and label_end = make_lambda_simple_end ()
         and param_count = List.length params' in
         (Printf.sprintf "\tmov r8, %d\n" params)
         ^ (Printf.sprintf "mov r9, %d\n" env)
         ^ "\tcall extend_lexical_environment\n"
         ^ "\tmov r9, rax\n"
         ^ "\tmov rdi, 1 + 8 + 8\n"
         ^ "\tcall malloc\n"
         ^ "\tmov byte [rax], T_closure\n"
         ^ "\tmov qword [rax + 1], r9\n"
         ^ (Printf.sprintf "\tmov qword [rax + 1 + 8], %s\n" label_code)
         ^ (Printf.sprintf "\tjmp %s\n" label_end)
         ^ (Printf.sprintf "%s:\t\n" label_code)
         ^ (Printf.sprintf "\tcmp qword [rsp + 8 * 2], %d\n"
              param_count)
         ^ (Printf.sprintf "\tje %s\n" label_arity_ok)
         ^ "\tpush qword [rsp + 8 * 2]\n"
         ^ (Printf.sprintf "\tpush %d\n" param_count)
         ^ "\tjmp L_error_incorrect_arity_simple\n"
         ^ (Printf.sprintf "%s:\n" label_arity_ok)
         ^ "\tenter 0, 0\n"
         ^ (run param_count (env + 1) body)
         ^ "\tleave\n"
         ^ (Printf.sprintf "\tret AND_KILL_FRAME(%d)\n" param_count)
         ^ (Printf.sprintf "%s:\t; new closure is in rax\n" label_end)
      | ScmLambda' (params', Opt opt, body) ->
         let label_end = make_lambda_opt_end ()
         and label_code = make_lambda_opt_code ()
         and param_count = List.length params' in
         (Printf.sprintf "\tmov r8, %d\n" params)
         ^ (Printf.sprintf "mov r9, %d\n" env)
         ^ "\tcall extend_lexical_environment\n"
         ^ "\tmov r9, rax\n"
         ^ "\tmov rdi, 1 + 8 + 8\n"
         ^ "\tcall malloc\n"
         ^ "\tmov byte [rax], T_closure\n"
         ^ "\tmov qword [rax + 1], r9\n"
         ^ (Printf.sprintf "\tmov qword [rax + 1 + 8], %s\n" label_code)
         ^ (Printf.sprintf "\tjmp %s\n" label_end)
         ^ (Printf.sprintf "%s:\t\n" label_code)
         ^ (Printf.sprintf "\tmov r9, %d\n"
              param_count)
         ^ "\tcall opt_fix_stack\n"
         ^ "\tenter 0, 0\n"
         ^ (run (1 + param_count) (1 + env) body)
         ^ "\tleave\n"
         ^ (Printf.sprintf "\tret AND_KILL_FRAME(%d)\n"
              (1 + param_count))
         ^ (Printf.sprintf "%s:\t; new closure is in rax\n" label_end)
      | ScmApplic' (proc, args, Non_Tail_Call) ->
          let n = List.length args in
          let push_args =
            List.fold_left
              (fun acc arg ->
                 acc ^ (run params env arg) ^ "\tpush rax\n")
              ""
              (List.rev args) in
          push_args
          ^ (Printf.sprintf "\tpush %d\t\t; arg count\n" n)
          ^ (run params env proc)
          ^ "\tassert_closure(rax)\n"
          ^ "\tpush SOB_CLOSURE_ENV(rax)\n"
          ^ "\tcall SOB_CLOSURE_CODE(rax)\n"
      
      | ScmApplic' (proc, args, Tail_Call) ->
            let n = List.length args in
            let label_loop = make_tc_applic_recycle_frame_loop () in
            let label_done = make_tc_applic_recycle_frame_done () in
            let push_args_code =
              String.concat ""
                (List.map
                   (fun arg -> (run params env arg) ^ "\tpush rax\n")
                   (List.rev args)) in
            let proc_code = run params env proc in
            push_args_code
            ^ (Printf.sprintf "\tpush %d\n" n)          (* new COUNT *)
            ^ proc_code
            ^ "\tassert_closure(rax)\n"
            ^ "\tpush SOB_CLOSURE_ENV(rax)\n"
            ^ "\tpush qword [rbp + 8*1]\n"             (* old RET *)
            (* stack now: [RET][ENV][COUNT][arg0]..[argN-1] (top -> bottom order was arranged by pushes) *)
            ^ "\tpop rbx\n"                             (* rbx = RET *)
            ^ "\tpop rcx\n"                             (* rcx = new ENV *)
            ^ "\tpop rdx\n"                             (* rdx = new COUNT *)
            ^ "\tmov r8, qword [rbp]\n"                 (* r8 = old saved RBP *)
            ^ "\tmov r9, qword [rbp + 8*3]\n"           (* r9 = old COUNT *)
            ^ "\tlea rdi, [rbp + 8*4 + r9*8]\n"         (* rdi = (one past) last old arg slot *)
            ^ (Printf.sprintf "\tsub rdi, %d\n" (n * 8))(* make room for n new args *)
            ^ "\tmov r12, rdi\n"                        (* r12 = base where new frame will be built *)
            ^ (Printf.sprintf "\tlea rdi, [r12 + %d]\t; Dest_High\n" ((n - 1) * 8))
            ^ (Printf.sprintf "\tlea rsi, [rsp + %d]\t; Source_High\n" ((n - 1) * 8))
            ^ (Printf.sprintf "\tmov r10, %d\n" n)      (* loop counter *)
        
            ^ (Printf.sprintf "%s:\n" label_loop)
            ^ "\tcmp r10, 0\n"
            ^ (Printf.sprintf "\tje %s\n" label_done)
            ^ "\tmov r11, qword [rsi]\n"
            ^ "\tmov qword [rdi], r11\n"
            ^ "\tsub rsi, 8\n"
            ^ "\tsub rdi, 8\n"
            ^ "\tdec r10\n"
            ^ (Printf.sprintf "\tjmp %s\n" label_loop)
        
            ^ (Printf.sprintf "%s:\n" label_done)
            ^ "\tmov qword [r12 - 8],  rdx\t; New COUNT\n"
            ^ "\tmov qword [r12 - 16], rcx\t; New ENV\n"
            ^ "\tmov qword [r12 - 24], rbx\t; RET\n"
            ^ "\tlea rsp, [r12 - 24]\t; Update RSP\n"
            ^ "\tmov rbp, r8\n"                         (* restore old saved rbp *)
            ^ "\tjmp SOB_CLOSURE_CODE(rax)\n"
      

    and runs params env exprs' =
      List.map (fun expr' -> run params env expr') exprs' in
    let codes = runs 0 0 exprs' in
    let code =
      String.concat "\n\tmov rdi, rax\n\tcall print_sexpr_if_not_void\n"
        codes in
    let code =
      (file_to_string "prologue-1.asm")
      ^ (asm_of_constants_table consts)
      ^ (asm_of_free_vars_table free_vars consts)
      ^ (file_to_string "prologue-2.asm")
      ^ (asm_of_global_bindings global_bindings_table free_vars)
      ^ "\n"
      ^ code
      ^ "Lend:\n"
      ^ "\tmov rdi, rax\n"
      ^ "\tcall print_sexpr_if_not_void\n"
      ^ (file_to_string "epilogue.asm") in
    code;;

  let compile_scheme_string file_out user =
    let source_code = get_source_code user in
    let sexprs = (PC.star Reader.nt_sexpr source_code 0).found in
    let exprs = List.map Tag_Parser.tag_parse sexprs in
    let exprs' = List.map Semantic_Analysis.semantics exprs in
    let asm_code = code_gen exprs' in
    (string_to_file file_out asm_code;
     Printf.printf "!!! Compilation finished. Time to assemble!\n");;  

  let compile_scheme_file file_in file_out =
    compile_scheme_string file_out (file_to_string file_in);;

  let compile_and_run_scheme_string file_out_base user =
    let source_code = get_source_code user in
    let sexprs = (PC.star Reader.nt_sexpr source_code 0).found in
    let exprs = List.map Tag_Parser.tag_parse sexprs in
    let exprs' = List.map Semantic_Analysis.semantics exprs in
    let asm_code = code_gen exprs' in
    ( string_to_file (Printf.sprintf "%s.asm" file_out_base) asm_code;
      match (Sys.command
               (Printf.sprintf
                  "make -f testing/makefile %s" file_out_base)) with
      | 0 -> let _ = Sys.command (Printf.sprintf "./%s" file_out_base) in ()
      | n -> (Printf.printf "!!! Failed with code %d\n" n; ()));;

end;; (* end of Code_Generation struct *)

(* end-of-input *)

let test = Code_Generation.compile_and_run_scheme_string "testing/goo";;
