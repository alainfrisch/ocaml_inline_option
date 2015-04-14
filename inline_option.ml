type 'a t = Obj.t

external some: 'a -> 'a t = "ml_inline_some" "noalloc"
external unsome: 'a t -> 'a = "ml_inline_unsome" "noalloc"

let none : 'a t = Obj.magic 0

let is_none x = x == none

external id: 'a -> 'a = "ml_id" "noalloc"
