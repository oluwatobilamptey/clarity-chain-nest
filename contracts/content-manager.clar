;; Constants
(define-constant err-not-member (err u200))
(define-constant err-not-moderator (err u201))

;; Data vars
(define-map posts
  { id: uint }
  {
    community-id: uint,
    author: principal,
    content: (string-utf8 280),
    created-at: uint
  }
)

(define-data-var next-post-id uint u1)

;; Public functions
(define-public (create-post (community-id uint) (content (string-utf8 280)))
  (let ((post-id (var-get next-post-id)))
    (map-insert posts
      { id: post-id }
      {
        community-id: community-id,
        author: tx-sender,
        content: content,
        created-at: block-height
      }
    )
    (var-set next-post-id (+ post-id u1))
    (ok post-id))
)
