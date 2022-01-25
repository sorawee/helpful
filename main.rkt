#lang racket/base

(provide #%top)

(require syntax/parse/define
         (only-in racket/base [#%top racket:#%top])
         (for-syntax racket/base
                     racket/list
                     racket/match
                     racket/syntax-srcloc
                     levenshtein))

(begin-for-syntax
  ;; Adapted from https://github.com/AlexKnauth/debug/blob/master/debug/repl.rkt

  ;; syntax-find-local-variables : Syntax -> (Listof Id)
  (define (syntax-find-local-variables stx)
    (define debug-info (syntax-debug-info stx (syntax-local-phase-level) #t))
    (define context (hash-ref debug-info 'context))
    (define bindings (hash-ref debug-info 'bindings '()))
    (remove-duplicates
     (for/list ([binding (in-list bindings)]
                #:when (or (hash-has-key? binding 'local)
                           (hash-has-key? binding 'module))
                #:when (context-subset? (hash-ref binding 'context) context))
       (datum->syntax stx (hash-ref binding 'name) stx))
     bound-identifier=?))

  ;; context-subset? : Context Context -> Boolean
  (define (context-subset? a b)
    ;; TODO: use an actual set-of-scopes subset function
    (list-prefix? a b))

  (define (id->string x)
    (symbol->string (syntax-e x)))

  (define (closest id xs)
    (match (sort (map (λ (x) (cons (string-levenshtein id x) x)) xs) < #:key car)
      ['() #f]
      [(cons (cons _ y) _) y]))

  ;; Taken from  racket/src/expander/syntax/error.rkt

  (define (syntax->string v)
    (define str ((error-syntax->string-handler) v (error-print-width)))
    (if (regexp-match? #rx"\n" str)
        (string-append "\n   "
                       (regexp-replace* #rx"\n" str "\n   "))
        (string-append " " str)))

  (define (extract-source-location s)
    (and (syntax? s)
         (syntax-srcloc s)
         (let ([str (srcloc->string (syntax-srcloc s))])
           (and str
                (string-append str ": ")))))

  (define (extract-form-name s)
    (cond
      [(syntax? s)
       (define e (syntax-e s))
       (cond
         [(symbol? e) e]
         [(and (pair? e)
               (identifier? (car e)))
          (syntax-e (car e))]
         [else #f])]
      [else #f]))

  (define (raise-unbound-error message expr message-suffix)
    (define name
      (format "~a" (or (extract-form-name expr)
                       '?)))
    (define in-message
      (or (and (error-print-source-location)
               (string-append "\n  in:" (syntax->string expr)))
          ""))
    (define src-loc-str
      (or (and (error-print-source-location)
               (extract-source-location expr))
          ""))
    (raise (exn:fail:syntax:unbound
            (string-append src-loc-str
                           name ": "
                           message
                           in-message
                           message-suffix)
            (current-continuation-marks)
            (with-handlers ([exn:fail:contract? (lambda (exn) '())])
              (list (syntax-taint (datum->syntax #f expr))))))))

(define-syntax (process stx)
  (define/syntax-parse (_ x) stx)
  (define all-vars
    (append
     (syntax-find-local-variables #'x)
     (match (assoc (syntax-local-phase-level) (syntax-local-module-required-identifiers #f #t))
       [#f '()]
       [(cons _ xs) xs])))
  (match (closest (id->string #'x) (map id->string all-vars))
    [#f (raise-unbound-error "unbound identifier" #'x "")]
    [y (raise-unbound-error "unbound identifier" #'x (format "\n  suggestion: do you mean `~a'?" y))]))

(define-syntax-parser #%top
  [(_ . x:id)
   #:when (syntax-transforming-module-expression?)
   (syntax-local-lift-provide #'(expand (process x)))
   #'(void)]
  [(_ . x) #'(racket:#%top . x)])
