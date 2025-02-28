;; Constants
(define-constant err-not-authorized (err u100))
(define-constant err-already-exists (err u101))
(define-constant err-not-found (err u102))
(define-constant err-already-member (err u103))

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

;; Private functions
(define-private (is-community-member (community-id uint) (member principal))
  (is-some (map-get? community-members { community-id: community-id, member: member }))
)

(define-private (update-member-count (community-id uint) (delta int))
  (match (map-get? communities { id: community-id })
    community (map-set communities
      { id: community-id }
      (merge community { member-count: (to-uint (+ delta (get member-count community))) }))
    false
  )
)

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
    (map-insert community-members
      { community-id: community-id, member: tx-sender }
      { joined-at: block-height }
    )
    (var-set next-community-id (+ community-id u1))
    (ok community-id))
)

(define-public (join-community (community-id uint))
  (match (map-get? communities { id: community-id })
    community
      (if (is-community-member community-id tx-sender)
        (err err-already-member)
        (begin
          (map-insert community-members
            { community-id: community-id, member: tx-sender }
            { joined-at: block-height }
          )
          (update-member-count community-id 1)
          (ok true)))
    (err err-not-found))
)

(define-public (update-community-name (community-id uint) (new-name (string-utf8 50)))
  (match (map-get? communities { id: community-id })
    community
      (if (is-eq tx-sender (get owner community))
        (begin
          (map-set communities
            { id: community-id }
            (merge community { name: new-name })
          )
          (ok true))
        (err err-not-authorized))
    (err err-not-found))
)
