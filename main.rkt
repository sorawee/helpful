#lang racket/base

(provide #%top)

(require syntax/parse/define
         (only-in racket/base [#%top racket:#%top])
         (for-syntax racket/base
                     racket/list
                     racket/match
                     racket/string
                     levenshtein
                     "doc.rkt"))

(begin-for-syntax

  ;; find-closest :: string? (listof string?) -> (or/c string? #f)
  (define (find-closest id xs)
    (match xs
      ;; in a #lang that has empty namespace, empty xs might be possible
      ['() #f]
      [_ (argmin (λ (x) (string-levenshtein id x)) xs)]))

  ;; get-locals :: identifier? -> (hash/c symbol? #t)
  (define (get-locals x)
    (for/hasheq ([v (in-list (syntax-bound-symbols x))]
                 #:do [(define local?
                         (match (identifier-binding (datum->syntax x v))
                           ['lexical #t]
                           [(list (app module-path-index-split mp _) _ _ _ _ _ _)
                            (not mp)]
                           [_ #f]))]
                 #:when local?)
      (values v #t)))

  ;; get-all-vars :: identifier? -> (listof symbol?)
  (define (get-all-vars x)
    (define locals (get-locals x))
    (define-values (pre post)
      (partition (λ (x) (hash-ref locals x #f)) (syntax-bound-symbols x)))
    ;; prioritize non-required identifiers
    (append (sort pre symbol<?) (sort post symbol<?)))

  (define (import->string import #:before-first [before-first ""])
    (string-join (for/list ([x (in-list import)])
                   (format "`~a'" x))
                 " or "
                 #:before-first before-first))

  (define (imports->string imports)
    (string-join
     (for/list ([import (in-list imports)])
       (import->string import #:before-first "   "))
     "\n")))

(define-syntax-parser my-top
  [(_ . x:id)
   #:when (not (identifier-binding #'x))
   (define all-vars (get-all-vars #'x))
   (define closest
     (find-closest (symbol->string (syntax-e #'x))
                   (map symbol->string all-vars)))
   (define imports (find-entry (syntax-e #'x)))

   (cond
     [(or closest imports)
      (raise-syntax-error
       #f "unbound identifier" #'x #f null
       (format
        "\n  ~a~a~a"
        (cond
          [closest (format "suggestion: do you mean `~a'?" closest)]
          [else ""])
        (cond
          [(and closest imports) "\n  alternative suggestion: "]
          [imports "suggestion: "]
          [else ""])
        (match imports
          [#f ""]
          [(list import)
           (format "do you want to import ~a, which provides the identifier?"
                   (import->string import))]
          [_
           (format
            "do you want to import ~a, which provides the identifier?\n~a"
            "one of the following modules"
            (imports->string imports))]))
       #:exn exn:fail:syntax:unbound)]
     [else
      (raise-syntax-error
       #f "unbound identifier" #'x
       #:exn exn:fail:syntax:unbound)])]
  [(_ . x) #'(racket:#%top . x)])

(define-syntax-parser #%top
  [(_ . x:id)
   #:when (syntax-transforming-module-expression?)
   #'(#%expression (my-top . x))]
  [(_ . x) #'(racket:#%top . x)])
