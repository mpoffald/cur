#lang racket/base
(require
 (for-syntax
  racket/base
  syntax/parse
  racket/syntax)
 syntax/parse
 racket/syntax
 syntax/parse/experimental/reflect)

(provide (all-defined-out))

(define (local-expand-expr x) (local-expand x 'expression null))

(define (reified-syntax-class->pred stxclass)
  (lambda (expr)
    (syntax-parse expr
      [(~reflect _ (stxclass)) #t]
      [_ #f])))

(define-syntax-rule (syntax-class->pred id)
  (reified-syntax-class->pred (reify-syntax-class id)))

(define-syntax (define-syntax-class/pred stx)
  (syntax-parse stx
    [(_ name:id expr ...)
     #:with pred? (format-id #'name "~a?" #'name)
     #`(begin
         (define-syntax-class name expr ...)
         (define pred? (syntax-class->pred name)))]))

(define (subst v x syn)
  (syntax-parse syn
    [y:id
     #:when (free-identifier=? syn x)
     v]
    [(e ...)
     (datum->syntax syn (map (lambda (e) (subst v x e)) (attribute e)))]
    [_ syn]))

;; takes a list of values and a list of identifiers, in dependency order, and substitutes them into syn.
;; TODO PERF: reverse
(define (subst* v-ls x-ls syn)
  (for/fold ([syn syn])
            ([v (reverse v-ls)]
             [x (reverse x-ls)])
    (subst v x syn)))

(define-syntax-class top-level-id #:attributes ()
  (pattern x:id
           #:fail-unless (case (syntax-local-context)
                           [(module top-level module-begin) #t]
                           [else #f])
           (raise-syntax-error
            (syntax->datum #'x)
            (format "Can only use ~a at the top-level."
                    (syntax->datum #'x))
            this-syntax)))