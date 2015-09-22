#lang scribble/manual

@(require
   "defs.rkt"
   (for-label (only-in racket local-expand)))

@title{Reflection}
To support the addition of new user-defined language features, @racketmodname[cur] provides access to
various parts of the language implementation as Racket forms at @gtech{phase} 1.
The reflection features are @emph{unstable} and may change without warning.
Many of these features are extremely hacky.

@(require racket/sandbox scribble/eval)
@(define curnel-eval
   (parameterize ([sandbox-output 'string]
                  [sandbox-error-output 'string]
                  [sandbox-eval-limits #f]
                  [sandbox-memory-limit #f])
     (make-module-evaluator "#lang cur (require cur/stdlib/bool) (require cur/stdlib/nat)")))

@defproc[(cur-expand [syn syntax?] [id identifier?] ...)
         syntax?]{
Expands the Cur term @racket[syn] until the expansion reaches a either @tech{Curnel form} or one of
the identifiers @racket[id]. See also @racket[local-expand].

@todo{Figure out how to get evaluator to pretend to be at phase 1 so these examples work properly.}

@margin-note{The examples in this file do not currently run in the REPL, but should work if used at
phase 1 in Cur.}

@examples[
(eval:alts (define-syntax-rule (computed-type _) Type) (void))
(eval:alts (cur-expand #'(lambda (x : (computed-type bla)) x))
           (eval:result @racket[#'(lambda (x : Type) x)] "" ""))
]
}

@defproc[(type-infer/syn [syn syntax?])
         (or/c syntax? #f)]{
Returns the type of the Cur term @racket[syn], or @racket[#f] if no type could be inferred.

@examples[
(eval:alts (type-infer/syn #'(lambda (x : Type) x))
           (eval:result @racket[#'(Π (x : (Unv 0)) (Unv 0))] "" ""))
(eval:alts (type-infer/syn #'Type)
           (eval:result @racket[#'(Unv 1)] "" ""))
]
}

@defproc[(type-check/syn? [syn syntax?])
         boolean?]{
Returns @racket[#t] if the Cur term @racket[syn] is well-typed, or @racket[#f] otherwise.

@examples[
(eval:alts (type-infer/syn #'(lambda (x : Type) x))
           (eval:result @racket[#'(Π (x : (Unv 0)) (Unv 0))] "" ""))
(eval:alts (type-infer/syn #'Type)
           (eval:result @racket[#'(Unv 1)] "" ""))
]
}

@defproc[(normalize/syn [syn syntax?])
         syntax?]{
Runs the Cur term @racket[syn] to a value.

@examples[
(eval:alts (normalize/syn #'((lambda (x : Type) x) Bool))
           (eval:result @racket[#'Bool] "" ""))
(eval:alts (normalize/syn #'(sub1 (s (s z))))
           (eval:result @racket[#'(s z)] "" ""))
]
}


@defform[(run syn)]{
Like @racket[normalize/syn], but is a syntactic form which allows a Cur term to be written by
computing part of the term from another Cur term.

@margin-note{This one is a real working example, assuming the @racketmodname[cur/stdlib/bool] and
@racketmodname[cur/stdlib/nat] are loaded. Also, could be moved outside the privileged code.}

@examples[#:eval curnel-eval
          (lambda (x : (run (if btrue bool nat))) x)]

}

@defproc[(cur-equal? [e1 syntax?] [e2 syntax?])
         boolean?]{
Returns @racket[#t] if the Cur terms @racket[e1] and @racket[e2] and equivalent according to
equal modulo α and β-equivalence.
@examples[


(eval:alts (cur-equal? #'(lambda (a : Type) a) #'(lambda (b : Type) b))
           (eval:result @racket[#t] "" ""))
(eval:alts (cur-equal? #'((lambda (a : Type) a) Bool) #'Bool)
           (eval:result @racket[#t] "" ""))
(eval:alts (cur-equal? #'(lambda (a : Type) (sub1 (s z))) #'(lambda (a : Type) z))
           (eval:result @racket[#f] "" ""))
]
}

