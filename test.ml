open Inline_option

(*
let some x = Some x
let none = None
let unsome = function None -> assert false | Some x -> x
let is_none = function None -> true | Some _ -> false
*)


let () =
  let r = ref [] in
  for i = 1 to 10000000 do
    r := id (id (Some i)) :: !r
  done;
  Printf.printf "%i\n%!" (List.length !r)
(*
let show f x =
  if is_none x then "None"
  else Printf.sprintf "Some(%s)" (f (unsome x))

  let x = some (some (some (some (some (some 0))))) in
  assert(unsome x == some (some (some (some (some 0)))));
  print_endline (show (show string_of_int) (some (some 42)))

*)
