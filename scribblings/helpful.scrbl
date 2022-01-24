#lang scribble/manual
@require[scribble/example
         @for-label[helpful
                    (except-in racket/base #%top)]]

@title{helpful: suggests a closest variable name on unbound identifier error.}
@author{sorawee}

@defmodule[helpful]

This module provides an ability to suggest a closest variable name on unbound identifier error.
Simply use @racket[(require helpful)] where you want this feature.

Note that this only affects code in a @racket[module] or a @hash-lang[].
Due to how the @link["http://calculist.blogspot.com/2009/01/fexprs-in-scheme.html"]{top level is hopeless},
the feature is disabled for the REPL.

The definition of ``closest'' is according to the @link["https://en.wikipedia.org/wiki/Levenshtein_distance"]{Levenshtein distance}.

@section{Examples}

@examples[
  #:label #f
  (eval:error
    (module test racket
      (require helpful)
      (define (fact x)
        (cond
          [(zero? x) 1]
          [else (* x (fac (sub1 x)))]))))
  (eval:error
    (module test racket
      (require helpful)
      (define (fact x)
        (cond
          [(zero? x) 1]
          [else (* x (fact (sub1 y)))]))))
  (code:comment @#,elem{No suggestion})
  (eval:error
    (module test racket
      (require helpful)
      x))
  (code:comment @#,elem{No suggestion outside a @racket[module] or @hash-lang[]})
  (require helpful)
  (eval:error (let ([x 1]) y))
]

@section{API}

@defform[(#%top . x)]{
  Does what's described above.
}
