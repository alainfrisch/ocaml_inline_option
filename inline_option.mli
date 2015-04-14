type 'a t

val some: 'a -> 'a t
val unsome: 'a t -> 'a
val none: 'a t
val is_none: 'a t -> bool


val id: 'a -> 'a
