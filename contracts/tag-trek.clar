;; TagTrek Main Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-event (err u101))
(define-constant err-invalid-coordinates (err u102))
(define-constant err-already-claimed (err u103))

;; Data structures
(define-map events 
  { event-id: uint }
  {
    creator: principal,
    name: (string-ascii 50),
    active: bool,
    start-time: uint,
    end-time: uint
  }
)

(define-map tags
  { event-id: uint, tag-id: uint }
  {
    latitude: int,
    longitude: int,
    points: uint,
    description: (string-ascii 200),
    claimed-by: (optional principal)
  }
)

(define-map participant-scores
  { event-id: uint, participant: principal }
  { score: uint }
)

;; Event management
(define-public (create-event (name (string-ascii 50)) (start-time uint) (end-time uint))
  (let ((event-id (get-next-event-id)))
    (if (is-eq tx-sender contract-owner)
      (begin
        (map-set events
          { event-id: event-id }
          {
            creator: tx-sender,
            name: name,
            active: true,
            start-time: start-time,
            end-time: end-time
          }
        )
        (ok event-id))
      err-owner-only)))

;; Tag management
(define-public (place-tag 
  (event-id uint)
  (tag-id uint)
  (latitude int)
  (longitude int)
  (points uint)
  (description (string-ascii 200)))
  (if (is-eq tx-sender contract-owner)
    (begin
      (map-set tags
        { event-id: event-id, tag-id: tag-id }
        {
          latitude: latitude,
          longitude: longitude,
          points: points,
          description: description,
          claimed-by: none
        }
      )
      (ok true))
    err-owner-only))

;; Tag discovery
(define-public (claim-tag (event-id uint) (tag-id uint))
  (let (
    (tag (unwrap! (map-get? tags { event-id: event-id, tag-id: tag-id }) (err u104)))
    (current-score (default-to { score: u0 } (map-get? participant-scores { event-id: event-id, participant: tx-sender })))
  )
    (asserts! (is-none (get claimed-by tag)) err-already-claimed)
    (map-set tags
      { event-id: event-id, tag-id: tag-id }
      (merge tag { claimed-by: (some tx-sender) })
    )
    (map-set participant-scores
      { event-id: event-id, participant: tx-sender }
      { score: (+ (get score current-score) (get points tag)) }
    )
    (ok true)))

;; Read-only functions
(define-read-only (get-event (event-id uint))
  (map-get? events { event-id: event-id }))

(define-read-only (get-tag (event-id uint) (tag-id uint))
  (map-get? tags { event-id: event-id, tag-id: tag-id }))

(define-read-only (get-score (event-id uint) (participant principal))
  (default-to { score: u0 } (map-get? participant-scores { event-id: event-id, participant: participant })))
