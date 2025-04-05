;; Property Registration Contract
;; Records details of structures in fire-prone areas

(define-data-var last-property-id uint u0)

(define-map properties
  { property-id: uint }
  {
    owner: principal,
    location: (string-utf8 100),
    size: uint,
    structure-type: (string-utf8 50),
    registration-date: uint
  }
)

(define-map owner-properties
  { owner: principal }
  { property-ids: (list 20 uint) }
)

;; Register a new property
(define-public (register-property
                (location (string-utf8 100))
                (size uint)
                (structure-type (string-utf8 50)))
  (let
    (
      (new-id (+ (var-get last-property-id) u1))
      (owner tx-sender)
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (owner-props (default-to { property-ids: (list) } (map-get? owner-properties { owner: owner })))
    )
    (var-set last-property-id new-id)
    (map-set properties
      { property-id: new-id }
      {
        owner: owner,
        location: location,
        size: size,
        structure-type: structure-type,
        registration-date: current-time
      }
    )
    (map-set owner-properties
      { owner: owner }
      { property-ids: (unwrap-panic (as-max-len? (append (get property-ids owner-props) new-id) u20)) }
    )
    (ok new-id)
  )
)

;; Update property details
(define-public (update-property
                (property-id uint)
                (location (string-utf8 100))
                (size uint)
                (structure-type (string-utf8 50)))
  (let
    (
      (property (unwrap! (map-get? properties { property-id: property-id }) (err u1)))
      (owner (get owner property))
    )
    (asserts! (is-eq tx-sender owner) (err u2))
    (map-set properties
      { property-id: property-id }
      (merge property {
        location: location,
        size: size,
        structure-type: structure-type
      })
    )
    (ok true)
  )
)

;; Get property details
(define-read-only (get-property (property-id uint))
  (map-get? properties { property-id: property-id })
)

;; Get properties owned by a principal
(define-read-only (get-owner-properties (owner principal))
  (map-get? owner-properties { owner: owner })
)

