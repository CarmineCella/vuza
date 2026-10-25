; prelude.scm -- everyday definitions for vuza
;
; install:  cp prelude.scm ~/.vuza/
; use:      (load "prelude.scm")  at the top of a script, or vuza prelude.scm script.scm
;
; Sequences -- arrays, lists and strings -- share ref, len, slice, cat and build, so the
; functions in "sequences" work on all three.  Whatever is vectorized runs at C++ speed; the
; functions marked "loops" call a procedure per element and are fine for prototypes.
; build returns an array when every element is a scalar, so numbers always end up in arrays.

; ---------------------------------------------------------------- constants
(define pi 3.141592653589793)
(define tau (* 2 pi))

; ---------------------------------------------------------------- logic
; comparisons are elementwise and give masks; logic is about truth: and, or are special forms of
; the core (short-circuit), not gives 0 or 1 for a whole value, any and all look inside an array
(define (not x) (if x 0 1))
(define (any x) (> (sum (!= x 0)) 0))              ; some element non-zero
(define (all x) (= (sum (!= x 0)) (len x)))        ; every element non-zero

; ---------------------------------------------------------------- sequences: arrays, lists, strings
(define (empty? x) (= (len x) 0))
(define (first x) (ref x 0))
(define (last x) (ref x (- (len x) 1)))
(define (rest x) (slice x 1 (len x)))
(define (head x n) (slice x 0 n))
(define (tail x n) (slice x (- (len x) n) (len x)))
(define (map f x) (build (len x) (lambda (i) (f (ref x i)))))          ; loops
(define (for-each f x) {
    (define (go i) (if (< i (len x)) {
        (f (ref x i))
        (go (+ i 1))
    } '()))
    (go 0)
})
(define (fold f acc x) {
    (define (go i acc) (if (= i (len x)) acc (go (+ i 1) (f acc (ref x i)))))
    (go 0 acc)
})
(define (filter p x) {   ; keeps the kind of x: (slice x i (+ i 1)) is a one-element x
    (define (go i acc) (if (= i (len x)) acc (go (+ i 1) (if (p (ref x i)) (cat acc (slice x i (+ i 1))) acc))))
    (go 0 (slice x 0 0))
})
(define (reverse x) (build (len x) (lambda (i) (ref x (- (len x) 1 i)))))   ; loops; a string comes back as a list
(define (zip a b) (build (len a) (lambda (i) (list (ref a i) (ref b i)))))
(define (count p x) (fold (lambda (n v) (if (p v) (+ n 1) n)) 0 x))
(define (index-of v x) {   ; first index of v, or -1
    (define (go i) (if (= i (len x)) -1 (if (equal? (ref x i) v) i (go (+ i 1)))))
    (go 0)
})

; ---------------------------------------------------------------- numbers
(define (mod x y) (- x (* y (floor (/ x y)))))       ; sign of y, like Python
(define (round x) (floor (+ x 0.5)))
(define (ceil x) (- (floor (- x))))
(define (sign x) (- (> x 0) (< x 0)))
(define (square x) (* x x))
(define (log10 x) (/ (log x) (log 10)))
(define (log2 x) (/ (log x) (log 2)))
(define (clip x lo hi) (+ (* x (and-mask (>= x lo) (<= x hi))) (* lo (< x lo)) (* hi (> x hi))))
(define (and-mask a b) (* a b))                      ; masks multiply
(define (min x) (- (max (- x))))
(define (minimum a b) (+ (* a (<= a b)) (* b (< b a))))   ; elementwise min of two arrays
(define (maximum a b) (+ (* a (>= a b)) (* b (> b a))))

; ---------------------------------------------------------------- arrays
(define (make n v) (build n (lambda (i) v)))
(define (zeros n) (make n 0))
(define (ones n) (make n 1))
(define (linspace a b n) (+ a (* (range n) (/ (- b a) (- n 1)))))
(define (diff x) (- (rest x) (head x (- (len x) 1))))
(define (cumsum x) {   ; running sum: state in the closure; loops
    (define acc 0)
    (build (len x) (lambda (i) {
        (set! acc (+ acc (ref x i)))
        acc
    }))
})
(define (argmax x) {   ; index of the first maximum; loops
    (define m (max x))
    (define (go i) (if (= (ref x i) m) i (go (+ i 1))))
    (go 0)
})
(define (argmin x) (argmax (- x)))
(define (dot a b) (sum (* a b)))
(define (norm x) (sqrt (dot x x)))
(define (mean x) (/ (sum x) (len x)))
(define (var x) (mean (square (- x (mean x)))))
(define (std x) (sqrt (var x)))
(define (rms x) (sqrt (mean (square x))))
(define (normalize x) (/ x (max (abs x))))
(define (pad x n) (cat x (make n 0)))                ; n zeros at the end
(define (repeat x n) (if (= n 0) [] (cat x (repeat x (- n 1)))))
(define (cshift x k) (if (= (len x) 0) x {
    (define j (mod k (len x)))
    (cat (slice x j (len x)) (slice x 0 j))
}))   ; circular shift left by k, k may be negative

; ---------------------------------------------------------------- signals
(define (time n sr) (/ (range n) sr))                ; n samples at rate sr, in seconds
(define (sine f t) (sin (* tau f t)))
(define (cosine f t) (cos (* tau f t)))
(define (phasor f n sr) (mod (* f (time n sr)) 1))   ; 0 .. 1 ramp at f Hz
(define (saw f n sr) (- (* 2 (phasor f n sr)) 1))
(define (pulse f n sr duty) (< (phasor f n sr) duty))
(define (noise n seed) {   ; Park-Miller generator, deterministic, seed > 0; loops
    (define s seed)
    (build n (lambda (i) {
        (set! s (mod (* 16807 s) 2147483647))
        (- (/ s 1073741823.5) 1)
    }))
})
(define (db x) (* 20 (log10 x)))
(define (undb x) (pow 10 (/ x 20)))
(define (mtof m) (* 440 (pow 2 (/ (- m 69) 12))))    ; MIDI note to Hz
(define (ftom f) (+ 69 (* 12 (log2 (/ f 440)))))
(define (hann n) (* 0.5 (- 1 (cos (/ (* tau (range n)) n)))))
(define (hamming n) (- 0.54 (* 0.46 (cos (/ (* tau (range n)) n)))))
(define (blackman n) {
    (define k (/ (* tau (range n)) n))
    (+ (- 0.42 (* 0.5 (cos k))) (* 0.08 (cos (* 2 k))))
})
(define (ramp n) (linspace 0 1 n))
(define (fade-in x n) (* x (cat (ramp n) (ones (- (len x) n)))))
(define (fade-out x n) (* x (cat (ones (- (len x) n)) (reverse (ramp n)))))
(define (envelope x n) (fade-out (fade-in x n) n))
(define (delay x n) (cat (make n 0) (head x (- (len x) n))))   ; shift right by n samples
(define (moving-average x n) {   ; vectorized: a sum of shifted copies
    (define (go k acc) (if (= k n) (/ acc n) (go (+ k 1) (+ acc (cshift x (- k))))))
    (go 0 (zeros (len x)))
})
(define (convolve x h) {   ; direct convolution; loops over h only
    (define m (- (len h) 1))
    (define (go k acc) (if (= k (len h)) acc (go (+ k 1) (+ acc (* (ref h k) (cat (zeros k) (pad x (- m k))))))))
    (go 0 (zeros (+ (len x) m)))
})
(define (frames x n hop)                             ; list of windowed frames, first frame first
  (if (< (len x) n) (list)
      (build (+ 1 (floor (/ (- (len x) n) hop))) (lambda (k) (* (hann n) (slice x (* k hop) (+ (* k hop) n)))))))
(define (overlap-add fs n hop) {   ; inverse of frames (up to the window): each frame padded into place
    (define total (+ (* hop (- (len fs) 1)) n))
    (define (go k acc) (if (= k (len fs)) acc (go (+ k 1) (+ acc (cat (zeros (* k hop)) (cat (ref fs k) (zeros (- total (* k hop) n))))))))
    (go 0 (zeros total))
})
(define (energy x) (dot x x))
(define (zero-crossings x) (sum (< (* (head x (- (len x) 1)) (rest x)) 0)))
(define (peak x) (max (abs x)))

; ---------------------------------------------------------------- misc
(define (error? x) (and (equal? (type x) "list") (= (len x) 2) (equal? (first x) 'error)))   ; what catch returns for an error
(define (assert c msg) (if c '() (error "assertion failed: " msg)))
(define (show name x) {
    (display name "=" x)
    x
})
(define (compose f g) (lambda (x) (f (g x))))
(define (apropos s) {                                ; the help templates whose name starts with the string s
    (define (starts? t) {
        (define n (str (ref t 0)))
        (if (< (len n) (len s)) 0 (equal? (slice n 0 (len s)) s))
    })
    (filter starts? (cat (ref (help) 1) (ref (help) 2)))
})
