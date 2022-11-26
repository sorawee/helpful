#lang scribble/manual
@require[scribble/example
         scribble/bnf
         @for-label[helpful
                    helpful/suggest
                    (only-in racket/contract none/c)
                    (except-in racket/base #%top)]]

@title{helpful: providing suggestions on unbound identifier error.}
@author[@author+email["Sorawee Porncharoenwase" "sorawee.pwase@gmail.com"]]

@defmodule[helpful]

This package provides suggestions on unbound identifier error.
It requires Racket 8.7 at minimum.

@section{How to use it?}

There are two ways to activate the suggestions.

@itemlist[
  @item{Using @exec{raco helpful} as a replacement of @exec{racket}}
  @item{Adding @racket[(require helpful)] in a module that you want to get suggestions and running @exec{racket} normally}
]

@section{Suggestions}

Currently, the package provides two kinds of suggestions.

One suggestion is hinting a ``closest'' identifier name,
which could be helpful when the error is caused by a typo mistake.
The definition of ``closest'' is according to the @link["https://en.wikipedia.org/wiki/Levenshtein_distance"]{Levenshtein distance}.
It breaks a tie by the alphabetical order,
with module and lexical bindings being prioritized over imported identifiers.

Another suggestion is hinting modules that could be imported to make the identifier bound,
which could be helpful when you forgot to import the desired module.
This feature consults Scribble and the Racket documentation index and thus is only available
if they are installed.

@section{Examples}

@examples[
  #:label #f
  (code:comment @#,elem{Suggestion for a @tech[#:doc '(lib "scribblings/reference/reference.scrbl")]{module binding}})
  (eval:error
    (module test racket
      (require helpful)
      (define (fact x)
        (cond
          [(zero? x) 1]
          [else (* x (fac (sub1 x)))]))))
  (code:comment @#,elem{Suggestion for a @tech[#:doc '(lib "scribblings/reference/reference.scrbl")]{local binding}})
  (eval:error
    (module test racket
      (require helpful)
      (define (fact x)
        (cond
          [(zero? x) 1]
          [else (* x (fact (sub1 y)))]))))
  (code:comment @#,elem{Suggestion for an imported identifier})
  (eval:error
    (module test racket
      (require helpful)
      (defun (fact) 1)))
  (code:comment @#,elem{Suggestion for a module to import})
  (code:comment @#,elem{(only when Scribble and the Racket documentation index are installed)})
  (eval:error
    (module test racket/base
      (require helpful)
      ->))
]

@section{Limitations}

The feature only affects code in a @racket[module] or a @hash-lang[].
Because @link["http://calculist.blogspot.com/2009/01/fexprs-in-scheme.html"]{top level is hopeless},
the feature is disabled for the REPL.

The feature only works reliably for code at @tech[#:doc '(lib "scribblings/reference/reference.scrbl")]{phase level} 0.

@section{API}

@defform[(#%top . x)]{
  A replacement of Racket's @racket[#%top] that provides suggestions.
  A @hash-lang[] that wishes to provide the suggestions by default
  can simply reprovide @racket[#%top].
}

@subsection{Internals}

@defmodule[helpful/suggest]

@defproc[(suggest [x identifier?]) none/c]{
  Given an unbound identifier @racket[x], this function raises the unbound id error with the suggestions.
}

@section{More examples}

@examples[
  #:label #f
  (code:comment @#,elem{No suggestion outside a @racket[module] or @hash-lang[]})
  (require helpful)
  (eval:error (let ([x 1]) y))
  (code:comment @#,elem{No suggestion for use-before-definition errors})
  (module test racket
    (require helpful)
    an-id
    (define an-id #f))
  (eval:error (require 'test))
  (code:comment @#,elem{Prioritization of module/lexical bindings})
  (eval:error
    (module test racket
      (require helpful)
      (define add2 #f)
      (define add3 #f)
      add4))
  (code:comment @#,elem{Alphabetical order})
  (eval:error
    (module test racket
      (require helpful)
      (define add3 #f)
      (define add2 #f)
      add4))
  (code:comment @#,elem{Consistent with Racket})
  (eval:error
    (module test racket
      (require helpful)
      add2
      ()))
  (code:comment @#,elem{Also consistent with Racket})
  (eval:error
    (module test racket
      (require helpful)
      add2
      (let () ())))
 (code:comment @#,elem{Another module recommendation})
  (eval:error
    (module test racket
      (require helpful)
      format-id))
]
