#lang racket
(require web-server/servlet
         web-server/servlet-env
         json)

(define port (if (getenv "PORT")
                 (string->number (getenv "PORT"))
                 8080))

(define (make-response s code)
  (response/jsexpr s
                   #:code code
                   #:headers
                   (list (header #"access-control-allow-origin" #"*")
                         (header #"access-control-allow-headers" #"Content-Type"))))

(define (not-found r)
  (make-response r 404)
  )

(define (default-response r)
  (make-response 200)
  )

(define (get-root r)
  (println r)
  (make-response "Hei" 200))

(define (post-root r)
  (println r)
  (make-response #hasheq((title . "a todo")) 200))

(define-values (dispatcher dispatcher-url)
  (dispatch-rules
   [("") #:method "get" get-root]
   [("") #:method "post" post-root]
   [else default-response]
   )
  )

(define (echo-resp r)
  (println r)
  (make-response "Hei" 200))

(serve/servlet dispatcher
               #:servlet-path "/"
               #:listen-ip #f
               #:command-line? #t
               #:servlet-regexp #rx""
               #:port port)

