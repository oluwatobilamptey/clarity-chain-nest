;; Constants
(define-constant err-not-member (err u200))
(define-constant err-not-moderator (err u201))
(define-constant err-not-author (err u202))
(define-constant err-post-not-found (err u203))

;; Data vars
(define-map posts
  { id: uint }
  {
    community-id: uint,
    author: principal,
    content: (string-utf8 280),
    created-at: uint,
    visible: bool
  }
)

(define-data-var next-post-id uint u1)

;; Private functions
(define-private (is-community-member (community-id uint) (user principal))
  (contract-call? .community-manager is-community-member community-id user)
)

;; Public functions
(define-public (create-post (community-id uint) (content (string-utf8 280)))
  (if (is-community-member community-id tx-sender)
    (let ((post-id (var-get next-post-id)))
      (map-insert posts
        { id: post-id }
        {
          community-id: community-id,
          author: tx-sender,
          content: content,
          created-at: block-height,
          visible: true
        }
      )
      (var-set next-post-id (+ post-id u1))
      (ok post-id))
    (err err-not-member))
)

(define-public (delete-post (post-id uint))
  (match (map-get? posts { id: post-id })
    post
      (if (is-eq tx-sender (get author post))
        (begin
          (map-delete posts { id: post-id })
          (ok true))
        (err err-not-author))
    (err err-post-not-found))
)

(define-public (moderate-post (post-id uint) (visible bool))
  (match (map-get? posts { id: post-id })
    post
      (match (contract-call? .community-manager get-community-owner (get community-id post))
        owner
          (if (is-eq tx-sender owner)
            (begin
              (map-set posts
                { id: post-id }
                (merge post { visible: visible })
              )
              (ok true))
            (err err-not-moderator))
        (err err-not-found))
    (err err-post-not-found))
)
