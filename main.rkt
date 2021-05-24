#lang racket
(require web-server/servlet
         web-server/servlet-env
         json)

(define port (if (getenv "PORT")
                 (string->number (getenv "PORT"))
                 8080))

;; DATABASE

(define db (make-hasheq))

;; BUSINESS LAYER

(struct todo (title url completed) #:transparent)

(define (todo->dict t)
  (hash 'title (todo-title t)
        'url (todo-url t)
        'completed (todo-completed t))
  )

(define (get-all-todos)
  (list))

(define (add-new-todo t)
  t
  )

(define (delete-all-todos)
  (list)
  )
;; SERVER METHODS


(define (make-response s code)
  (response/jsexpr s
                   #:code code
                   #:headers
                   (list (header #"access-control-allow-origin" #"*")
                         (header #"access-control-allow-headers" #"Content-Type")
                         (header #"Access-Control-Allow-Methods" #"*"))))

(define (not-found r)
  (make-response r 404)
  )

(define (default-response r)
  (make-response "OK:)" 200)
  )

(define (get-root r)
  (println r)
  (make-response (get-all-todos) 200))

(define (post-root r)
  (println r)
  (let* ([post-data (request-post-data/raw r)]
         [parsed-json (bytes->jsexpr post-data)]
         [result (add-new-todo (todo "a todo" "" #f))])
         (make-response (todo->dict result) 200))
  )

(define (delete-root r)
  (println r)
  (make-response (delete-all-todos) 200)
  )

(define-values (dispatcher dispatcher-url)
  (dispatch-rules
   [("") #:method "get" get-root]
   [("") #:method "post" post-root]
   [("") #:method "delete" delete-root]
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

