#lang racket/base

(require racket/cmdline
         racket/match
         "suggest.rkt")

(define (do-it e)
  (match (exn:fail:syntax-exprs e)
    ['() (raise e)]
    [(cons x _) (suggest x)]))

(command-line
 #:args (path . prog-option)
 (current-command-line-arguments (list->vector prog-option))
 (with-handlers* ([exn:fail:syntax:unbound? do-it])
   (dynamic-require `(file ,path) #f)))
