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
    r := some i :: !r  (* Replace (some i) with (Some i) or (id (Some i)) *)
  done;
  Printf.printf "%i\n%!" (List.length !r)
