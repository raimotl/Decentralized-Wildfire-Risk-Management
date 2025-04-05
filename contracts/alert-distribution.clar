;; Alert Distribution Contract
;; Manages emergency notifications to residents

(define-map alert-contacts
  { property-id: uint }
  {
    primary-contact: (string-utf8 100),
    secondary-contact: (string-utf8 100),
    notification-methods: (list 5 (string-utf8 20)),
    last-updated: uint
  }
)

(define-map alerts
  { alert-id: uint }
  {
    alert-type: (string-utf8 50),
    severity: uint,
    message: (string-utf8 500),
    affected-regions: (list 10 (string-utf8 10)),
    timestamp: uint,
    expiration: uint
  }
)

(define-map alert-receipts
  { alert-id: uint, property-id: uint }
  {
    delivered: bool,
    delivery-timestamp: uint,
    acknowledged: bool,
    acknowledgment-timestamp: uint
  }
)

(define-data-var last-alert-id uint u0)

;; Register or update alert contacts for a property
(define-public (set-alert-contacts
                (property-id uint)
                (primary-contact (string-utf8 100))
                (secondary-contact (string-utf8 100))
                (notification-methods (list 5 (string-utf8 20))))
  (let
    (
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (map-set alert-contacts
      { property-id: property-id }
      {
        primary-contact: primary-contact,
        secondary-contact: secondary-contact,
        notification-methods: notification-methods,
        last-updated: current-time
      }
    )
    (ok true)
  )
)

;; Create a new alert
(define-public (create-alert
                (alert-type (string-utf8 50))
                (severity uint)
                (message (string-utf8 500))
                (affected-regions (list 10 (string-utf8 10)))
                (duration uint))
  (let
    (
      (new-id (+ (var-get last-alert-id) u1))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (expiration-time (+ current-time duration))
    )
    (var-set last-alert-id new-id)
    (map-set alerts
      { alert-id: new-id }
      {
        alert-type: alert-type,
        severity: severity,
        message: message,
        affected-regions: affected-regions,
        timestamp: current-time,
        expiration: expiration-time
      }
    )
    (ok new-id)
  )
)

;; Record alert delivery to a property
(define-public (record-alert-delivery
                (alert-id uint)
                (property-id uint))
  (let
    (
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (is-some (map-get? alerts { alert-id: alert-id })) (err u1))
    (map-set alert-receipts
      { alert-id: alert-id, property-id: property-id }
      {
        delivered: true,
        delivery-timestamp: current-time,
        acknowledged: false,
        acknowledgment-timestamp: u0
      }
    )
    (ok true)
  )
)

;; Acknowledge receipt of an alert
(define-public (acknowledge-alert
                (alert-id uint)
                (property-id uint))
  (let
    (
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (receipt (unwrap! (map-get? alert-receipts { alert-id: alert-id, property-id: property-id }) (err u1)))
    )
    (asserts! (get delivered receipt) (err u2))
    (map-set alert-receipts
      { alert-id: alert-id, property-id: property-id }
      (merge receipt {
        acknowledged: true,
        acknowledgment-timestamp: current-time
      })
    )
    (ok true)
  )
)

;; Get active alerts for a region
(define-read-only (get-active-alerts-for-region (region-code (string-utf8 10)))
  (filter (map-keys alerts)
    (lambda (key)
      (let
        (
          (alert (unwrap-panic (map-get? alerts key)))
          (regions (get affected-regions alert))
          (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
          (expiration (get expiration alert))
        )
        (and
          (< current-time expiration)
          (is-some (index-of regions region-code))
        )
      )
    )
  )
)

;; Get alert contacts for a property
(define-read-only (get-alert-contacts-for-property (property-id uint))
  (map-get? alert-contacts { property-id: property-id })
)

;; Get alert details
(define-read-only (get-alert-details (alert-id uint))
  (map-get? alerts { alert-id: alert-id })
)

