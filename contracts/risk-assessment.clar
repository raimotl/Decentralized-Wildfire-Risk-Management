;; Risk Assessment Contract
;; Calculates vulnerability based on multiple factors

(define-map risk-assessments
  { property-id: uint }
  {
    risk-score: uint,
    assessment-date: uint,
    factors: {
      vegetation-density: uint,
      slope: uint,
      weather-risk: uint,
      distance-to-water: uint
    }
  }
)

(define-map regional-risk-factors
  { region-code: (string-utf8 10) }
  {
    base-risk: uint,
    seasonal-multiplier: uint
  }
)

;; Add or update regional risk factors
(define-public (set-regional-risk
                (region-code (string-utf8 10))
                (base-risk uint)
                (seasonal-multiplier uint))
  (begin
    ;; Only contract owner or authorized entity should be able to set this
    ;; For simplicity, we're not implementing complex authorization here
    (map-set regional-risk-factors
      { region-code: region-code }
      {
        base-risk: base-risk,
        seasonal-multiplier: seasonal-multiplier
      }
    )
    (ok true)
  )
)

;; Calculate and record risk assessment for a property
(define-public (assess-property-risk
                (property-id uint)
                (vegetation-density uint)
                (slope uint)
                (weather-risk uint)
                (distance-to-water uint)
                (region-code (string-utf8 10)))
  (let
    (
      (regional-factors (default-to { base-risk: u50, seasonal-multiplier: u10 }
                         (map-get? regional-risk-factors { region-code: region-code })))
      (base-risk (get base-risk regional-factors))
      (seasonal-mult (get seasonal-multiplier regional-factors))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))

      ;; Calculate risk score (simplified algorithm)
      (vegetation-factor (* vegetation-density u2))
      (slope-factor (* slope u1))
      (weather-factor (* weather-risk u3))
      (water-factor (if (> distance-to-water u0) (/ u100 distance-to-water) u0))
      (raw-score (+ base-risk vegetation-factor slope-factor weather-factor water-factor))
      (final-score (/ (* raw-score seasonal-mult) u100))
    )
    (map-set risk-assessments
      { property-id: property-id }
      {
        risk-score: final-score,
        assessment-date: current-time,
        factors: {
          vegetation-density: vegetation-density,
          slope: slope,
          weather-risk: weather-risk,
          distance-to-water: distance-to-water
        }
      }
    )
    (ok final-score)
  )
)

;; Get the current risk assessment for a property
(define-read-only (get-property-risk (property-id uint))
  (map-get? risk-assessments { property-id: property-id })
)

;; Check if a property is in high risk (score > 70)
(define-read-only (is-high-risk (property-id uint))
  (let
    (
      (assessment (map-get? risk-assessments { property-id: property-id }))
    )
    (if (is-some assessment)
      (> (get risk-score (unwrap-panic assessment)) u70)
      false
    )
  )
)

