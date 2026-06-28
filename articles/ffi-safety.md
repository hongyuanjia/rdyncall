# FFI safety boundaries

`rdyncall` is deliberately low level. It is useful when you need dynamic
library loading, exploratory calls, generated bindings, or a binding
layer that cannot be written as a fixed compiled wrapper. That power
also means R cannot protect you from every C-level mistake.

Use this article before calling APIs that allocate memory, store
pointers, start event loops, create threads, hold callbacks, or transfer
ownership.

## When rdyncall is a good fit

`rdyncall` is strongest when the binding is dynamic and the C API
boundary is small, explicit, and easy to test.

| Situation                                  | Good fit?  | Why                                     |
|:-------------------------------------------|:-----------|:----------------------------------------|
| Probe one scalar function                  | Yes        | simple signature, easy validation       |
| Explore a library before writing a package | Yes        | no compiled wrapper needed              |
| Generate wrappers from DynPort metadata    | Yes        | metadata can be regenerated             |
| Bind a stable high-level package API       | Maybe      | `.Call` may be easier to test and debug |
| Manage complex ownership or threads        | Usually no | compiled code can enforce invariants    |
| Drive a GUI or event loop from callbacks   | Carefully  | lifetime and error boundaries matter    |

For long-lived package APIs, use rdyncall to prototype the boundary,
then move critical paths into compiled code when the interface
stabilizes.

## Crash classes to avoid

Most serious problems fall into a few groups.

| Risk                    | What causes it                                                  | Safer habit                                 |
|:------------------------|:----------------------------------------------------------------|:--------------------------------------------|
| Wrong signature         | type width, return type, calling convention, or vararg mismatch | keep the C prototype beside the R signature |
| Invalid pointer         | reading borrowed memory after the owner frees it                | document ownership before reading           |
| Bad layout              | struct packing, alignment, arrays, or bitfields differ          | inspect `size`, `align`, and field offsets  |
| Dangling callback       | C stores a pointer after R drops the callback object            | keep an R owner object until unregister     |
| Error across C boundary | callback throws under foreign control                           | catch errors inside the callback            |
| Wrong deallocator       | freeing memory with the wrong library or allocator              | call the matching C destroy/free function   |

The absence of an R error does not prove a binding is correct. A wrong
FFI call can corrupt state and fail later.

## Ownership questions

Before using a pointer returned by C, answer these questions from the C
API documentation:

- Who owns the pointed-to memory?
- How long is the pointer valid?
- Is the memory immutable, mutable, or an output buffer?
- Which function releases it, if any?
- Can R store the pointer for later, or is it valid only during the
  call?
- Is the pointer thread-local or tied to a library context?

If the documentation does not answer these questions, treat the pointer
as borrowed and short-lived.

## Safer development loop

1.  Start with a scalar function such as a version or platform query.
2.  Add one pointer argument at a time.
3.  Inspect struct layouts before passing aggregates to C.
4.  Keep callback owner objects explicit.
5.  Use tiny inputs and deterministic calls before file, network, GUI,
    or event APIs.
6.  Move stable, high-risk code to `.Call` or another compiled wrapper.

## When to prefer `.Call`

A compiled wrapper is often better when the interface needs validation,
resource management, or a stable R-facing contract. Prefer `.Call` when
you need to:

- validate complex R inputs before touching C memory;
- allocate and free C resources reliably;
- expose a high-level API to many users;
- integrate with R’s protection stack and error handling;
- use C macros or inline functions that are not exported as dynamic
  symbols;
- debug under sanitizers or platform-specific tooling.

This does not make rdyncall a throwaway tool. It is a productive way to
learn the C boundary, test signatures, and generate repeatable bindings
before deciding which parts deserve compiled wrappers.

## Next steps

- Use [getting
  started](https://hongyuanjia.github.io/rdyncall/articles/rdyncall.md)
  for a small safe direct call.
- Use
  [signatures](https://hongyuanjia.github.io/rdyncall/articles/signatures.md)
  before changing a type or callback shape.
- Use [structs, unions, and
  memory](https://hongyuanjia.github.io/rdyncall/articles/structs-unions-memory.md)
  before passing layout-sensitive data.
- Use
  [callbacks](https://hongyuanjia.github.io/rdyncall/articles/callbacks.md)
  before registering a function pointer with C.
- Use
  [troubleshooting](https://hongyuanjia.github.io/rdyncall/articles/troubleshooting.md)
  when a call works only on some platforms or fails after a lifetime
  boundary.
