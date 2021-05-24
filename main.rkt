#lang racket
(require web-server/servlet
         web-server/servlet-env
         json
         uuid
         racket/hash)

(define port (if (getenv "PORT")
                 (string->number (getenv "PORT"))
                 8080))

;; DATABASE

(define db (make-hash))

;; BUSINESS LAYER

(struct todo (title [id #:mutable] completed order) #:transparent)

(define (todo->dict t)
  (hash 'title (todo-title t)
        'id (todo-id t)
        'url (string-append "https://todo-backend-racket.herokuapp.com/" "todo/" (todo-id t))
        'order (todo-order t)
        'completed (todo-completed t))
  )

(define (dict->todo d)
  (let ([title (hash-ref d 'title)]
        [id (hash-ref d 'id)]
        [order (hash-ref d 'order)]
        [completed (hash-ref d 'completed)])
    (todo title id completed)))

(define (get-all-todos)
  (hash-values db))

(define (add-new-todo t)
  (let ([uid (uuid-string)])
    (set-todo-id! t uid)
    (hash-set! db uid t)
    uid
    ))

(define (delete-all-todos)
  (hash-clear! db)
  (list))

(define (delete-todo id)
  (hash-remove! db id))


(define (get-todo id)
  (hash-ref db id #f))

(define (update-todo id new-val)
  (hash-set! db id new-val)
  new-val
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
  (let* ([all-todos (get-all-todos)]
         [as-dict (map todo->dict all-todos)])
    (println as-dict)
    (make-response as-dict 200)))

(define (post-root r)
  (println r)
  (let* ([post-data (request-post-data/raw r)]
         [parsed-json (bytes->jsexpr post-data)]
         [title (hash-ref parsed-json 'title)]
         [id-of-created (add-new-todo (todo title "" #f 0))]
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

(define (api/update-todo r id)
  (let* ([old-todo (get-todo id)]
         [old-todo-hash (todo->dict old-todo)]
         [post-data (request-post-data/raw r)]
         [parsed-json (bytes->jsexpr post-data)]
         [new-raw-todo (hash-union old-todo-hash parsed-json #:combine (lambda (a b) b))])
    (println r)
    (update-todo id (dict->todo new-raw-todo))
    (make-response (todo->dict (get-todo id)) 200)
    ))

(define (api/delete-todo r id)
  (delete-todo id)
  (make-response "OK" 200))

(define-values (dispatcher dispatcher-url)
  (dispatch-rules
   [("") #:method "get" get-root]
   [("") #:method "post" post-root]
   [("") #:method "delete" delete-root]
   [("todo" (string-arg)) #:method "get" get-todo-api]
   [("todo" (string-arg)) #:method "patch" api/update-todo]
   [("todo" (string-arg)) #:method "delete" api/delete-todo]
   [else default-response]
   )
  )

(serve/servlet dispatcher
               #:servlet-path "/"
               #:listen-ip #f
               #:command-line? #t
               #:servlet-regexp #rx""
               #:port port)

