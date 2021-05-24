#lang racket
(require web-server/servlet
         web-server/servlet-env
         json)

(define port (if (getenv "PORT")
                 (string->number (getenv "PORT"))
                 8080))


(define (start req)
  (response/xexpr
   '(html (head (title "Racket Heroku App!!"))
          (body (h1 "It works!")))))

(define (make-response code)
  (lambda (r)
    (response/jsexpr "some reponse"
                     #:code code
                     #:headers
                     (list (header #"access-control-allow-origin" #"*")
                           (header #"access-control-allow-headers" #"Content-Type"))))
  )

(define (not-found r)
  (make-response r 404)
  )

(define (default-response)
  (make-response 200)
  )

(define-values (go _)
  (dispatch-rules
   [("catalog") #:method "get" (make-response 200)]
   [else (default-response)]
   )
  )

(serve/servlet go
               #:servlet-path "/"
               #:listen-ip #f
               #:command-line? #t
               #:servlet-regexp #rx""
               #:port port)

