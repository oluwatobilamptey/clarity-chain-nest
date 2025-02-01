;; Constants
(define-constant err-not-authorized (err u100))
(define-constant err-already-exists (err u101))
(define-constant err-not-found (err u102))

;; Data vars
(define-map communities
  { id: uint }
  {
    name: (string-utf8 50),
    owner: principal,
    created-at: uint,
    member-count: uint
  }
)

(define-map community-members
  { community-id: uint, member: principal }
  { joined-at: uint }
)

(define-data-var next-community-id uint u1)

;; Public functions
(define-public (create-community (name (string-utf8 50)))
  (let ((community-id (var-get next-community-id)))
    (map-insert communities
      { id: community-id }
      {
        name: name,
        owner: tx-sender,
        created-at: block-height,
        member-count: u1
      }
    )
    (var-set next-community-id (+ community-id u1))
    (ok community-id))
)

(define-public (join-community (community-id uint))
  (if (map-get? communities { id: community-id })
    (begin
      (map-insert community-members
        { community-id: community-id, member: tx-sender }
        { joined-at: block-height }
      )
      (ok true))
    (err err-not-found))
)
