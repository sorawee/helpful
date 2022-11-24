#lang racket/base

(provide #%top)

(require syntax/parse/define
         (only-in racket/base [#%top racket:#%top])
         (for-syntax racket/base
                     racket/list
                     racket/match
                     levenshtein))

(begin-for-syntax
  (define (closest id xs)
    (match xs
      ;; in a #lang that has empty namespace, empty xs might be possible
      ['() #f]
      [_ (argmin (λ (x) (string-levenshtein id x)) xs)]))

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

  (define (get-all-vars x)
    (define locals (get-locals x))
    (define-values (pre post)
      (partition (λ (x) (hash-ref locals x #f)) (syntax-bound-symbols x)))
    ;; prioritize non-required identifiers
    (append (sort pre symbol<?) (sort post symbol<?))))

(define-syntax-parser my-top
  [(_ . x)
   #:when (not (identifier-binding #'x))
   (define all-vars (get-all-vars #'x))
   (match (closest (symbol->string (syntax-e #'x)) (map symbol->string all-vars))
     [#f (raise-syntax-error #f "unbound identifier" #'x
                             #:exn exn:fail:syntax:unbound)]
     [y (raise-syntax-error #f "unbound identifier" #'x #f null
                            (format "\n  suggestion: do you mean `~a'?" y)
                            #:exn exn:fail:syntax:unbound)])]
  [(_ . x) #'(racket:#%top . x)])

(define-syntax-parser #%top
  [(_ . x:id)
   #:when (syntax-transforming-module-expression?)
   #'(#%expression (my-top . x))]
  [(_ . x) #'(racket:#%top . x)])
