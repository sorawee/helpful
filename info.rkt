#lang info
(define collection "helpful")
(define deps '("base"))
(define build-deps '("scribble-lib" "racket-doc" "rackunit-lib"))
(define scribblings '(("scribblings/helpful.scrbl" ())))
(define pkg-desc "Helpfully suggest a closest variable name on unbound identifier error.")
(define version "0.0")
(define pkg-authors '(sorawee))
(define license '(Apache-2.0 OR MIT))
