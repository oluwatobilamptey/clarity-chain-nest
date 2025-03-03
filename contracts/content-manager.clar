;; Constants
(define-constant err-not-member (err u200))
(define-constant err-not-moderator (err u201))
(define-constant err-not-author (err u202))
(define-constant err-post-not-found (err u203))
(define-constant err-invalid-content (err u204))
(define-constant err-no-changes (err u205))

;; Data vars
(define-map posts
  { id: uint }
  {
    community-id: uint,
    author: principal,
    content: (string-utf8 280),
    created-at: uint,
    last-edited-at: (optional uint),
    visible: bool
  }
)

(define-map post-history
  { post-id: uint, edit-number: uint }
  {
    content: (string-utf8 280),
    edited-at: uint
  }
)

(define-data-var next-post-id uint u1)

;; Private functions
(define-private (is-community-member (community-id uint) (user principal))
  (contract-call? .community-manager is-community-member community-id user)
)

(define-private (validate-content (content (string-utf8 280)))
  (if (> (len content) u0)
    (ok true)
    (err err-invalid-content))
)

;; Public functions
(define-read-only (get-post (post-id uint))
  (ok (map-get? posts { id: post-id }))
)

(define-read-only (get-community-posts (community-id uint) (start uint) (end uint))
  (ok (filter map-get? posts
    (map unwrap-panic
      (list { id: start } { id: end }))))
)

(define-public (create-post (community-id uint) (content (string-utf8 280)))
  (begin
    (try! (validate-content content))
    (if (is-community-member community-id tx-sender)
      (let ((post-id (var-get next-post-id)))
        (map-insert posts
          { id: post-id }
          {
            community-id: community-id,
            author: tx-sender,
            content: content,
            created-at: block-height,
            last-edited-at: none,
            visible: true
          }
        )
        (var-set next-post-id (+ post-id u1))
        (ok post-id))
      (err err-not-member)))
)

(define-public (edit-post (post-id uint) (new-content (string-utf8 280)))
  (match (map-get? posts { id: post-id })
    post
      (begin
        (try! (validate-content new-content))
        (if (is-eq tx-sender (get author post))
          (let ((current-height block-height))
            (map-set post-history
              { post-id: post-id, edit-number: (default-to u0 (get last-edited-at post)) }
              {
                content: (get content post),
                edited-at: current-height
              }
            )
            (map-set posts
              { id: post-id }
              (merge post {
                content: new-content,
                last-edited-at: (some current-height)
              })
            )
            (ok true))
          (err err-not-author)))
    (err err-post-not-found))
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
