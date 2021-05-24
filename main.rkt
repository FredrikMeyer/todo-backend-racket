#lang racket
(require web-server/servlet
         web-server/servlet-env)

(define port (if (getenv "PORT") (string->number (getenv "PORT"))
                 8080))

(define (start req)
  (response/xexpr
   '(html (head (title "Racket Heroku App"))
          (body (h1 "It works!")))))

(serve/servlet start #:servlet-path "/")(define (start req)
  (response/xexpr
   '(html (head (title "Racket Heroku App"))
          (body (h1 "It works!")))))

(serve/servlet start
               #:servlet-path "/"
               #:listen-ip #f
               #:command-line? #t
               #:port port)
