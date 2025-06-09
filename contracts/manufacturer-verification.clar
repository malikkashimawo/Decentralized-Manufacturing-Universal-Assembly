;; Manufacturer Verification Contract
;; Validates universal assembly systems and manufacturer credentials

(define-map manufacturers
  { manufacturer-id: uint }
  {
    address: principal,
    verified: bool,
    certification-level: uint,
    registration-block: uint
  }
)

(define-map manufacturer-capabilities
  { manufacturer-id: uint }
  {
    assembly-types: (list 10 (string-ascii 50)),
    max-capacity: uint,
    quality-rating: uint
  }
)

(define-data-var next-manufacturer-id uint u1)
(define-data-var contract-owner principal tx-sender)

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-MANUFACTURER-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-VERIFIED (err u102))

;; Register a new manufacturer
(define-public (register-manufacturer (assembly-types (list 10 (string-ascii 50))) (max-capacity uint))
  (let ((manufacturer-id (var-get next-manufacturer-id)))
    (map-set manufacturers
      { manufacturer-id: manufacturer-id }
      {
        address: tx-sender,
        verified: false,
        certification-level: u0,
        registration-block: block-height
      }
    )
    (map-set manufacturer-capabilities
      { manufacturer-id: manufacturer-id }
      {
        assembly-types: assembly-types,
        max-capacity: max-capacity,
        quality-rating: u0
      }
    )
    (var-set next-manufacturer-id (+ manufacturer-id u1))
    (ok manufacturer-id)
  )
)

;; Verify a manufacturer (only contract owner)
(define-public (verify-manufacturer (manufacturer-id uint) (certification-level uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (match (map-get? manufacturers { manufacturer-id: manufacturer-id })
      manufacturer-data
      (begin
        (map-set manufacturers
          { manufacturer-id: manufacturer-id }
          (merge manufacturer-data { verified: true, certification-level: certification-level })
        )
        (ok true)
      )
      ERR-MANUFACTURER-NOT-FOUND
    )
  )
)

;; Get manufacturer info
(define-read-only (get-manufacturer (manufacturer-id uint))
  (map-get? manufacturers { manufacturer-id: manufacturer-id })
)

;; Get manufacturer capabilities
(define-read-only (get-manufacturer-capabilities (manufacturer-id uint))
  (map-get? manufacturer-capabilities { manufacturer-id: manufacturer-id })
)

;; Check if manufacturer is verified
(define-read-only (is-manufacturer-verified (manufacturer-id uint))
  (match (map-get? manufacturers { manufacturer-id: manufacturer-id })
    manufacturer-data (get verified manufacturer-data)
    false
  )
)
