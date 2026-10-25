# Vuza — a small Scheme for sound

Vuza is a tiny Scheme dialect for working with sound, written as a single C++17 header ([`src/vuza.h`](src/vuza.h)) plus a prelude in Vuza itself ([`src/prelude.scm`](src/prelude.scm)). Every number is an array of doubles; a scalar is an array of size one, so `3` and `[3]` are the same value. Arithmetic broadcasts, comparisons return masks, and the whole signal-processing vocabulary is built on a handful of array operations that run at C++ speed.

Vuza is the spiritual successor to the language described in Carmine-Emanuele Cella, *Vuza: a functional language for creative applications*, Proceedings of the 40th International Computer Music Conference joint with the 11th Sound and Music Computing Conference (ICMC/SMC 2014), Athens, 2014 ([pdf](https://www.carminecella.com/research/icmc2014_vuza.pdf)). It keeps the idea — a small Scheme whose values are signals — and starts the implementation again from scratch. It is **not** backward compatible: the syntax, the data model and the primitives are new.

## Design philosophy

**Few concepts, pushed all the way.**

- *Numbers are arrays.* There is no scalar type. `(+ [1 2 3] 1)` is `[2 3 4]`, `(- 10 [1 2 3])` is `[9 8 7]`, `(< [1 5 3] 3)` is the mask `[1 0 0]`, and masks multiply: `(* x (< x 3))` keeps what is below 3.
- *Values are immutable.* There is no way to change an element: every operation returns a new array, so sharing is always safe and a literal is the same value every time it is evaluated. Per-element computation is `build` with a function of the index, and a recurrence is `build` with state kept in a closure.
- *Three sequences, five operations.* Arrays, lists and strings all support `ref`, `len`, `slice`, `cat` and `build`, with negative indices counting from the end. There are no pairs, no `car`/`cdr`/`cons`: a list is a vector of any values, and `map`, `fold`, `filter` are one-liners in the prelude. `build` returns an array when every result is a scalar, so numbers always end up in arrays.
- *A small evaluator.* Tail calls run in constant stack through every form (`if`, `do`, `and`, `or`, `apply`, `catch`); recursion depth, allocation failure and deeply nested values are all turned into ordinary errors. An error carries the expression it happened in, and `file:line` when loaded from a file; `catch` turns one into the value `(error "message")`.
- *Introspection is data.* `(help)` returns three lists of call templates — the special forms, the primitives, your definitions — and `(help 'f)` returns a primitive's template or a procedure's source.
- *A few pieces of sugar.* `{e1 e2 ...}` reads as `(do e1 e2 ...)`, `[1 2 3]` is an array literal, `(define (f x) body)` is `(define f (lambda (x) body))`. There is no `let`: a lambda applied at once does the same.

**A minimal core, libraries on top.** The core is the language — reader, evaluator, the primitives on values — and nothing else. Everyday functions (`map`, `fold`, windows, oscillators, envelopes, framing) live in `prelude.scm`, written in Vuza. Anything else goes in a separate library header that registers its primitives.

## A taste

```scheme
(load "prelude.scm")
(define sr 44100)
(define t (time sr sr))                                  ; one second of time
(define x (+ (sine 440 t) (* 0.5 (sine 880 t))))          ; two partials
(define y (envelope x 2000))                             ; 2000-sample fades in and out
(display "rms" (rms y) "peak" (peak y))
(define fs (frames y 1024 512))                          ; a list of windowed frames
(display (len fs) "frames of" (len (first fs)))
(save "y.scm" y)                                         ; printed form, exact round trip
```

```scheme
(define (onepole x a) {   ; a recurrence: y[i] = a y[i-1] + (1-a) x[i]
    (define y 0)
    (build (len x) (lambda (i) {
        (set! y (+ (* a y) (* (- 1 a) (ref x i))))
        y
    }))
})
```
