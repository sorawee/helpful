#lang racket/base

(provide #%top)

(require syntax/parse/define
         (only-in racket/base [#%top racket:#%top])
         (for-syntax racket/base
                     racket/list
                     racket/match
                     levenshtein))

(begin-for-syntax
  (define SCORE-THRESHOLD 5)

  (define (id->string x)
    (symbol->string (syntax-e x)))

  (define (closest id xs)
    (match (sort (map (λ (x) (cons (string-levenshtein id x) x)) xs) < #:key car)
      [(cons (cons score y) _) #:when (< score SCORE-THRESHOLD) y]
      [_ #f]))

  (define (get-locals x)
    (for/hash ([v (in-list (syntax-bound-symbols x))]
               #:do [(define local?
                       (match (identifier-binding (datum->syntax x v))
                         ['lexical #t]
                         [(list from-mod _ _ _ _ _ _)
                          (define-values (mp _base)
                            (module-path-index-split from-mod))
                          (not mp)]
                         [_ #f]))]
               #:when local?)
      (values v #t)))

  (define (get-all-vars x)
    (define locals (get-locals x))
    (define-values (pre post)
      (partition (λ (x) (hash-ref locals x #f)) (syntax-bound-symbols x)))
    ;; prioritize non-required identifiers
    (append pre post))

  (define (process x)
    (define all-vars (get-all-vars x))
    (match (closest (id->string x) (map symbol->string all-vars))
      [#f (raise-syntax-error #f "unbound identifier" x
                              #:exn exn:fail:syntax:unbound)]
      [y (raise-syntax-error #f "unbound identifier" x #f null
                             (format "\n  suggestion: do you mean `~a'?" y)
                             #:exn exn:fail:syntax:unbound)])))

(define-syntax-parser #%top
  [(_ . x:id)
   #:when (syntax-transforming-module-expression?)
   (process #'x)
   #'(void)]
  [(_ . x) #'(racket:#%top . x)])
