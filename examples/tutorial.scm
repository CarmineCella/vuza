; tutorial.scm -- a tour of vuza
;
; vuza is a small Scheme in which every number is an array of doubles.
; A scalar is an array of size one, so 3 and [3] are the same value.
;

(display "--- 1. values")

; numbers, arrays, strings, symbols, lists
(display 3 -2.5 1e3)                 ; scalars
(display [1 2 3] [] [0.5 -1])        ; array literals: scalars only, no commas
(display "a string")                 ; display prints strings without quotes
(display 'symbol)                    ; a quoted symbol
(display '(1 "two" three (4)))       ; a quoted list can hold anything
(display (list 1 2 3))               ; list builds a list from evaluated arguments
(display (type [1]) (type '()) (type "s") (type 'a) (type +) (type (lambda (x) x)))

(display "--- 2. arithmetic broadcasts")

; operators work element by element; a scalar stretches to the array's size
(display (+ [1 2 3] 1))              ; [2 3 4]
(display (* [1 2 3] [10 20 30]))     ; [10 40 90]
(display (- 10 [1 2 3]))             ; [9 8 7]
(display (+ 1 2 3 4))                ; + - * / take any number of arguments
(display (- 5) (/ 4))                ; and are unary negation and reciprocal with one
(display (pow [2 3] 2) (sqrt [4 9]) (abs [-1 2]) (floor [1.7 -1.2]))
(display (sin 0) (cos 0) (exp 1) (log 1) (tan 0) (atan 1))
(display (sum [1 2 3]) (max [3 1 2]) (len [1 2 3]))

; comparisons return masks of 0 and 1
(display (< [1 5 3] 3))              ; [1 0 0]
(display (= [1 2] [1 3]))            ; [1 0]
(display (* [1 5 3] (< [1 5 3] 3)))  ; masks multiply: keep what is below 3

(display "--- 3. making arrays")

(display (build 4 (lambda (i) (* i i))))   ; (build n f): the array whose i-th element is (f i)
(display (range 5))                  ; 0 .. n-1
(display (range 2 5))                ; start .. end-1
(display (range 0 1 0.25))           ; start, end excluded, step
(display (range 5 0 -1))             ; steps can be negative
(display (slice (range 10) 2 5))     ; (slice x start end), end excluded
(display (slice (range 10) 0 10 3))  ; optional step
(display (cat [1 2] [3 4]))          ; concatenation
(display (ref [10 20 30] 1))         ; element access, 0-based
(display (ref [10 20 30] -1) (slice (range 10) 0 -1))   ; negative indices count from the end

(display "--- 4. arrays are values")

; there is no way to change an element: every operation returns a new array,
; so sharing is always safe and a literal is the same value every time it is evaluated
(define a [1 2 3])
(define b a)
(display (equal? a b) (equal? (+ a 0) a))
; per-element computation is build with a function of the index; the function may keep
; state in a closure, which is how recurrences are written
(define (cumsum x) {
    (define acc 0)
    (build (len x) (lambda (i) {
        (set! acc (+ acc (ref x i)))
        acc
    }))
})
(display (cumsum [1 2 3 4]))         ; [1 3 6 10]

(display "--- 5. definitions and functions")

(define sr 100)                                    ; a variable
(define square (lambda (x) (* x x)))               ; a procedure
(define (cube x) (* x x x))                        ; the same, shorter
(display (square [1 2 3]) (cube 2))
(define (stats x) {   ; a body is one expression: {} sequences several, the last is the value
    (define m (/ (sum x) (len x)))
    (define v (/ (sum (pow (- x m) 2)) (len x)))
    (list m (sqrt v))
})
(display (stats [2 4 4 4 5 5 7 9]))                ; mean and standard deviation
(set! sr 200)                                      ; set! changes an existing binding
(display sr)
(display square)                                   ; procedures print as their source

; closures capture their environment
(define (make-counter) {
    (define n 0)
    (lambda () {
        (set! n (+ n 1))
        n
    })
})
(define tick (make-counter))
(tick) (tick)
(display (tick))                                   ; 3

; there is no let: a lambda applied at once does the same
(display ((lambda (p q) (+ (* p p) (* q q))) 3 4))

(display "--- 6. control")

(display (if (> 2 1) "yes" "no"))
(display (if 0 "yes"))               ; no else branch: ()
; an array is true when it is non-empty and all its elements are non-zero; a list or a string when non-empty
(display (if [1 2] "all" "some") (if [1 0] "all" "some") (if [] "non-empty" "empty") (if "" "non-empty" "empty"))
; and, or stop at the first deciding value and return it, so the rest is not evaluated
(display (and 1 2 3) (and 1 0 undefined) (or 0 [] 5) (or 0 []))   ; 3 0 5 []
(define v [4 5 6])
(display (and (> (len v) 2) (ref v 2)))   ; a guarded access: 6, or 0 when v is too short
(display (do (display "first") (display "second") "last"))
(display {
    (display "braces")
    "are do"
})           ; {e1 e2 ...} reads as (do e1 e2 ...)
(display (if (> 3 2) {
    (display "then")
    1
} {
    (display "else")
    2
}))

; recursion; tail calls run in constant stack
(define (fact n) (if (< n 2) 1 (* n (fact (- n 1)))))
(display (fact 10))
(define (count-up i acc) (if (= i 0) acc (count-up (- i 1) (+ acc 1))))
(display (count-up 100000 0))

; there is no loop statement: iterate with tail recursion, or with build when the result is an array
(define (count-down n) (if (= n 0) "done" (count-down (- n 1))))
(display (count-down 1000))

(display "--- 7. sequences: arrays, lists and strings")

; there are no pairs, no car/cdr/cons: a list is a sequence of any values, a string a sequence
; of characters, an array a sequence of numbers, and the same five operations work on all three
(define l '(a "b" [1 2]))
(display (ref l 0) (ref "hello" 1) (len l) (len "hello"))
(display (slice l 1 3) (slice "hello" 1 4) (slice '(a b c d) 0 4 2))
(display (cat '(a) '(b c)) (cat "ab" "cd") (cat (list 0) '(1 2)))   ; cat prepends too
; build makes a list whenever a result is not a scalar
(display (build 3 (lambda (i) (list i (* i i)))))
; so map and fold are one-liners over ref and build; numbers always come back as an array
(define (map f x) (build (len x) (lambda (i) (f (ref x i)))))
(define (fold f acc x) {
    (define (go i acc) (if (= i (len x)) acc (go (+ i 1) (f acc (ref x i)))))
    (go 0 acc)
})
(display (map square '(1 2 3)) (map len (list [1 2] [3 4 5])) (fold cat "" (list "a" "b" "c")))
(display (apply + '(1 2 3)))                       ; apply spreads a list as arguments
(display (array->list [1 2]) (list->array '(3 4)))
(display (list [1 2 3] [4 5]))                     ; a list of arrays: frames, channels, ...
; lists are stored as vectors: ref is O(1), slice and cat copy, build is the linear-time constructor

(display "--- 8. equality")

(display (equal? [1 2] [1 2]) (equal? [1 2] [1 2 3]) (equal? 'a 'a) (equal? "a" 'a))
(display (equal? '(1 (2 [3])) '(1 (2 [3]))) (equal? square square) (equal? square cube))

(display "--- 9. files")

; save writes values in printed form, one per line, exactly; read gives them back as a list
(define signal (sin (* 2 3.141592653589793 5 (/ (range 8) 100))))
(save "tutorial_tmp.scm" signal '(1 "two" three) square)
(define back (read "tutorial_tmp.scm"))
(display (len back) (equal? (ref back 0) signal))
; load evaluates a file and returns its last value; a saved definition loads back as a definition
(save "tutorial_tmp.scm" (list 'define 'twice (lambda (x) (* 2 x))) '(twice 21))
(display (load "tutorial_tmp.scm") (twice 4))
; load looks next to the file being loaded, then in the current folder, then in ~/.vuza/ -- the place for your own libraries
; a file of bare numbers, as written by other tools, reads as a list of scalars:
(save "tutorial_tmp.scm" 1 2 3)
(display (list->array (read "tutorial_tmp.scm")))

(display "--- 10. a little signal processing")

; the functions here are simplified versions of the prelude's: load it for the real ones

(define sr 1000)
(define t (/ (range sr) sr))                             ; one second of time
(define (sine f) (sin (* 2 3.141592653589793 f t)))
(define x (+ (sine 5) (* 0.5 (sine 12))))                ; two partials
(define (rms x) (sqrt (/ (sum (* x x)) (len x))))
(display "rms" (rms x))
(define (hann n) (* 0.5 (- 1 (cos (* 2 3.141592653589793 (/ (range n) n))))))
(display "window" (slice (hann 8) 0 8))
(define (cshift x k) (cat (slice x k (len x)) (slice x 0 k)))   ; circular shift left by k, 0 <= k < (len x)
(define (moving-average x n) {   ; vectorized: a sum of shifted copies
    (define (go k acc) (if (= k n) (/ acc n) (go (+ k 1) (+ acc (cshift x k)))))
    (go 0 (* 0 x))
})
(display "smoothed" (slice (moving-average x 10) 0 4))
(define (frames x n hop)                                  ; a list of windowed frames, built in one go
  (build (+ 1 (floor (/ (- (len x) n) hop))) (lambda (k) (* (hann n) (slice x (* k hop) (+ (* k hop) n))))))
(display "frames" (len (frames x 256 128)))
(define (onepole x a) {   ; a recurrence: y[i] = a y[i-1] + (1-a) x[i]
    (define y 0)
    (build (len x) (lambda (i) {
        (set! y (+ (* a y) (* (- 1 a) (ref x i))))
        y
    }))
})
(display "onepole" (onepole [1 0 0 0 0] 0.5))
(save "tutorial_tmp.scm" x)                               ; keep the result

(display "--- 11. introspection, errors and strings")

; help returns data: three lists of call templates -- the forms, the primitives, your definitions
(define h (help))
(display (ref h 0))                   ; the special forms
(display (len (ref h 1)) 'primitives)
(display (ref h 2))                   ; what you defined: (name arg ...) for procedures, (name type) for values
(display (help 'slice))               ; one primitive: its template
(display (help 'twice))               ; one procedure: its source
; errors stop the file and print the expression where they happened, with file:line when loaded:
;   error: tutorial.scm:NN: undefined variable
;       in undefined-thing
; catch turns an error into the list (error "message"), so a script can test for one; error raises your own
(display (catch (ref [1 2] 5)) (catch (undefined-thing)) (catch (+ 1 "a")) (catch (+ 1 1)))
(display (ref (catch (sqrt 1 2)) 1))     ; the message
(display (catch (error "sample rate must be positive, got " -1)))
; str joins the printed forms of its arguments: the way to build file names
(define (frame-name k) (str "frame-" k ".scm"))
(display (frame-name 3))
; long values print truncated at the REPL and in display; save always writes everything
(display (range 1000))
; args is the list of strings after "--" on the command line:  vuza tutorial.scm -- 440 1.5
(display "args" args)
(display "done")

; eof
