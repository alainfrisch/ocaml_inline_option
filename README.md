ocaml_inline_option: experiment with optimized representation of option in OCaml
===============================================================================

In OCaml, optional values are represented with the `'a option`, which
is a normal sum type defined as:

````
  type 'a option = None | Some of 'a
````

The concrete runtime representation of optional value follows the
normal strategy for a sum type: the `None` constructor is represented
as the integer `0` and the `Some` constructor wraps its argument in an
allocated block of size 1 (and tag 0).  This means that any call to
`Some` allocates and that a value such as `Some []` takes some space
on the heap.

This repository is to experiment with an alternative ad hoc
representation of optional values.  The basic idea is to represent
`Some x` as the value `x` itself.  Of course, this cannot work when
`x` is `None`, because `None` and `Some None` need to be distinguised
if people use a type of the form `'a option option` in their code. And
the same applies when `x` shares the same representation as `None`.
For instance, as long as `None` is represented as `0`, `Some 0`
cannot share the same representation as `0`.


What is currently implemented here is the following representation:

 - `None` keeps its representation as the `0` integer.

 - In general, `Some x` is represented as `x`, except in some cases
   (see below).

 - There is a statically allocated (aligned) area of N*sizeof(value)
   bytes.  This is to guarantee that a value which is a pointer into
   this area cannot be mistaken for another valid value.  Let's call
   `X0` the value pointing to this area, `X1`, ..., `X(N-1)` the
   remaining values pointing to other values in this area (i.e.
   `Xi = X0 + i * sizeof(value)`).

 - When `x` is represented as `None` (i.e. as `0`, currently),
   `Some x` is represented as `X0`.

 - When `x` is one of the `Xi`, `Some x` is represented as `Xi+1`.

 - When `x` is `X(n-1)`, `Some` cannot be applied to it (this raises
   a runtime error).


The last case is not so nice.  One could design other schemes without
this corner case, but this would complexify the code generated for the
`Some` constructor. Even with `n = 3`, one should be safe for most
programs, so the current code takes `n = 256` to be on the safe side.

When `-rectypes` is enabled, it's possible to define a type `type t =
t option` and thus reach the limit programmatically.  But it would be
easy to reject this definition, and a similar definition `type t = t
foo` is actually rejected when `foo` is abstract.  Without
`-rectypes`, I don't think it's possible to reach this limit without
creating a huge type definitions with `n` nested `option` or `lazy`
constructors.


The current repository defines an abstract type `'a Inlined_option.t`
with associated operations implemented in C through the OCaml FFI.
This means that benchmarks pay some overhead associated to this FFI
(not so much related the cost of actually calling a function, but
rather its impact on the registrer allocator).  The idea, of course,
is that this optimized representation could be supported by the
compiler itself, inlining at least the most common code paths, and
also avoiding checks e.g. when the parameter of `Some` is known
statically to be an allocated block (for instance `Some x` could be an
absolute no-op when the type of `x` is a record type).


Micro-benchmarks
----------------

Consider the following micro-benchmark:

````
let () =
  let r = ref [] in
  for i = 1 to 10000000 do
    r := some i :: !r  (* some i -> Some i or id (Some i) *)
  done;
  Printf.printf "%i\n%!" (List.length !r)
````

and the variant with `Some` instead of `some`.  I get the following timings:

````
   some  :  0.60s
   Some  :  2.02s
````

If the reference `r` is emptied say every 100 iterations, both versions
take around 0.06s.  This shows that what we gain is not so much
related to actually avoiding the allocation (not suprising how fast it
is in OCaml), nor to the rate of minor collections, but rather to the fact
that the major GC needs to scan fewer blocks.  This can be confirmed by
adding manual calls to `Gc.full_major()` after the loop.  In the
`some` version, each such full GC takes around 0.25s, while in the
`Some` case, each one takes around 1.20s (I'm not sure exactly why the
difference is so big, since list cells are present in both cases, and
they should account for more than half the job of the GC in the `Some`
case).

It is also worth adding a call to an identity function `id`
implemented in C around the call to `Some i`.  This gives an
indication of what could be gained if we avoided the C call in the
`some` version.  My observation is that adding this call to `id` adds
about 0.1s to the `Some` case.


Caveats
-------

The current implementation is a toy proof-of-concept.  It shouldn't be
used as is, for at least the following reasons:

 - There is no support in the generic functions such as hashing and
   comparison, and more importantly in the generic marshaling routine.
   It wouldn't be difficult to add support (if the proposal goes
   upstream).

 - The new representation breaks an assumption currently made by the
   runtime system, namely that a type cannot have values represented
   as floats (i.e. allocated blocks with tag 253) and others.  This is
   because of the special representation of float arrays:

     - See http://www.lexifi.com/blog/about-unboxed-float-arrays for
       some advocacy around the removal of this special representation
       (in particular to allow such hacks with options, and similar
       ones);

     - and https://github.com/ocaml/ocaml/pull/163 for a pull request
       by Leo White implementing the removal of that special
       representation.


   If the special representation for unboxed float arrays remains in
   OCaml, one would need to work around it and have code paths to do
   something special (i.e. allocate) for `Some x` when `x` is a float
   (and also to deconstruct options).  My guess is that this would
   make the `Some` deconstructor very expensive (in many cases, one
   doesn't know statically that a type is not float), perhaps even
   offsetting completely the benefits of the more compact
   representation.
