#include <caml/mlvalues.h>
#include <assert.h>
#include <stdio.h>

#define MAX_NESTING 256

value some_nones[MAX_NESTING];

value ml_id(value x) {
  return x;
}

value ml_inline_some(value x) {
  if (Is_block(x)) {
    if (some_nones <= (value*)x && (value*)x < some_nones + MAX_NESTING) {
      if ((value*)x == some_nones + MAX_NESTING - 1)
        assert(0);
      else
        return (value)((value*)x + 1);
    }
  } else
    if (x == Val_int(0)) return (value) some_nones;

  return x;
}


value ml_inline_unsome(value x) {
  assert(x != Val_int(0));
  if (Is_block(x) &&
      some_nones <= (value*)x && (value*)x < some_nones + MAX_NESTING) {
    if ((value*)x == some_nones)
      return Val_int(0);
    else
      return (value)((value*)x - 1);
  }
  return x;
}
