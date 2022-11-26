#lang racket/base

(provide #%top)

(require syntax/parse/define
         (only-in racket/base [#%top racket:#%top])
         (for-syntax racket/base
                     "suggest.rkt"))

(define-syntax-parser my-top
  [(_ . x:id)
   #:when (not (identifier-binding #'x))
   (suggest #'x)]
  [(_ . x) #'(racket:#%top . x)])

(define-syntax-parser #%top
  [(_ . x:id)
   #:when (syntax-transforming-module-expression?)
   #'(#%expression (my-top . x))]
  [(_ . x) #'(racket:#%top . x)])
