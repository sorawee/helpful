#lang racket/base

(provide find-entry)

(require racket/splicing
         syntax/parse/define
         (for-syntax racket/base))

(define-syntax-parse-rule (import m x)
  (with-handlers ([exn:fail:filesystem:missing-module? (λ (e) #f)])
    (dynamic-require 'm 'x)))

(define-syntax-parse-rule (with-import ([mod x:id ...+] ...) body ...+)
  #:with [[module ...] ...]
  (for/list ([x (in-list (attribute x))] [mod (in-list (attribute mod))])
    (for/list ([x (in-list x)])
      mod))

  (splicing-let ({~@ . ([x (import module x)] ...)} ...)
    body ...))

(define database #f)

(define (find-entry x)
  (with-import ([scribble/xref xref-index
                               entry-desc]
                [setup/xref load-collections-xref]
                [scribble/manual-struct exported-index-desc?
                                        exported-index-desc-name
                                        exported-index-desc-from-libs])
    ;; precondition: variables are all defined
    (define (build-database!)
      (set! database (make-hash))
      (for ([e (in-list (xref-index (load-collections-xref)))]
            #:do [(define desc (entry-desc e))]
            #:when (exported-index-desc? desc)
            #:do [(define name (exported-index-desc-name desc))
                  (define from-libs (exported-index-desc-from-libs desc))])
        (hash-update! database name (λ (old) (cons from-libs old)) '())))

    (cond
      [(and xref-index load-collections-xref exported-index-desc?)
       (set! find-entry
             (λ (x)
               (unless database
                 (build-database!))
               (hash-ref database x #f)))]
      [else (set! find-entry (λ (x) #f))])

    (find-entry x)))
