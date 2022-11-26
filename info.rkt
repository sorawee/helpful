#lang info
(define collection "helpful")
(define deps '(["base" #:version "8.6.0.6"]
               "levenshtein"))
(define build-deps '("scribble-lib" "racket-doc" "rackunit-lib"))
(define scribblings '(("scribblings/helpful.scrbl" ())))
(define pkg-desc "Helpfully provide suggestions on unbound identifier error")
(define version "2.0")
(define pkg-authors '(sorawee))
(define license '(Apache-2.0 OR MIT))
(define raco-commands
  '(("helpful"
     helpful/raco
     "helpfully provide suggestions"
     42)))
