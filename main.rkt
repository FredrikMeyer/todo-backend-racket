#lang racket
(require web-server/servlet
         web-server/servlet-env
         json
         uuid)

(define port (if (getenv "PORT")
                 (string->number (getenv "PORT"))
                 8080))

;; DATABASE

(define db (make-hash))

;; BUSINESS LAYER

(struct todo (title id completed) #:transparent)

(define (todo->dict t)
  (hash 'title (todo-title t)
        'url (string-append "https://todo-backend-racket.herokuapp.com/" "todo" (todo-id t))
        'completed (todo-completed t))
  )

(define (get-all-todos)
  (hash-values db))

(define (add-new-todo t)
  (let ([uid (uuid-string)])
    (hash-set! db uid t)
    uid
    ))

(define (delete-all-todos)
  (hash-clear! db)
  (list)
  )


(define (get-todo id)
  (hash-ref db id #f))

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
  (let* ([all-todos (get-all-todos)]
         [as-dict (map todo->dict all-todos)])
    (println as-dict)
    (make-response as-dict 200)))

(define (post-root r)
  (println r)
  (let* ([post-data (request-post-data/raw r)]
         [parsed-json (bytes->jsexpr post-data)]
         [title (hash-ref parsed-json 'title)]
         [id-of-created (add-new-todo (todo title "" #f))]
         [created (get-todo id-of-created)])
         (make-response (todo->dict created) 200))
  )

(define (delete-root r)
  (println r)
  (make-response (delete-all-todos) 200)
  )

(define (get-todo-api r id)
  (println r)
  (let ([result (get-todo id)])
    (if result
        (make-response (todo->dict result) 200)
        (make-response ":/" 404))))

(define-values (dispatcher dispatcher-url)
  (dispatch-rules
   [("") #:method "get" get-root]
   [("") #:method "post" post-root]
   [("") #:method "delete" delete-root]
   [("todo" (string-arg)) #:method "get" get-todo-api]
   [else default-response]
   )
  )

(serve/servlet dispatcher
               #:servlet-path "/"
               #:listen-ip #f
               #:command-line? #t
               #:servlet-regexp #rx""
               #:port port)

