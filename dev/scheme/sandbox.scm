(define (add a b)
  (+ a b))

(display "Hello, World!")

(+ 1 2)
(add 10 20)

(define (print-hi-and-return x)
  (begin
    (display "Hi")
    (newline))
  x)

(print-hi-and-return 123)

(define (return-values)
  (values 123 "Hi"))

(return-values)

(comment Test the ConjureSchemeInput command.
  (read))
