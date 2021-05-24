#lang racket
(require web-server/servlet
         web-server/servlet-env
         json)

(define port (if (getenv "PORT") (string->number (getenv "PORT"))
                 8080))

(define (start req)
  (response/xexpr
   '(html (head (title "Racket Heroku App!!"))
          (body (h1 "It works!")))))

(define (not-found r)
  (response/jsexpr #hasheq((x . 85)) #:code 404)
  )

(define-values (go _)
  (dispatch-rules
   [("catalog") #:method "get" (lambda (r) (response/jsexpr "{}"))]
   [else not-found]
   )
  )

(serve/servlet go
               #:servlet-path "/"
               #:listen-ip #f
               #:command-line? #t
               #:servlet-regexp #rx""
               #:port port)

