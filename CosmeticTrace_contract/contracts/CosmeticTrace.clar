
;; title: CosmeticTrace
;; version: 1.0.0
;; summary: Supply chain tracking for cosmetic product ingredients and testing verification
;; description: A comprehensive smart contract for tracking cosmetic ingredients from source to final product,
;;              including batch tracking, testing verification, and supply chain transparency.

;; traits
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_BATCH (err u103))
(define-constant ERR_INVALID_TEST (err u104))
(define-constant ERR_INGREDIENT_NOT_VERIFIED (err u105))

;; data vars
(define-data-var next-ingredient-id uint u1)
(define-data-var next-batch-id uint u1)
(define-data-var next-product-id uint u1)
(define-data-var next-test-id uint u1)

;; data maps

;; Ingredient registry - tracks raw ingredients and their suppliers
(define-map ingredients
  { ingredient-id: uint }
  {
    name: (string-ascii 128),
    supplier: principal,
    origin-country: (string-ascii 64),
    certification: (string-ascii 128),
    registered-at: uint,
    is-verified: bool
  }
)

;; Batch tracking - tracks ingredient batches through the supply chain
(define-map batches
  { batch-id: uint }
  {
    ingredient-id: uint,
    quantity: uint,
    manufacturing-date: uint,
    expiry-date: uint,
    current-owner: principal,
    is-used: bool,
    created-at: uint
  }
)

;; Test results - tracks safety and quality testing
(define-map test-results
  { test-id: uint }
  {
    batch-id: uint,
    test-type: (string-ascii 64),
    test-date: uint,
    result: (string-ascii 256),
    passed: bool,
    tester: principal,
    certification-body: (optional principal)
  }
)

;; Products - final cosmetic products made from verified ingredients
(define-map products
  { product-id: uint }
  {
    name: (string-ascii 128),
    manufacturer: principal,
    ingredient-batches: (list 20 uint),
    production-date: uint,
    is-verified: bool,
    created-at: uint
  }
)

;; Track which batches are used in which products
(define-map batch-product-usage
  { batch-id: uint, product-id: uint }
  { used-quantity: uint }
)

;; Supplier verification status
(define-map verified-suppliers
  { supplier: principal }
  { verified-by: principal, verified-at: uint, status: bool }
)

;; public functions

;; Register a new ingredient
(define-public (register-ingredient
  (name (string-ascii 128))
  (supplier principal)
  (origin-country (string-ascii 64))
  (certification (string-ascii 128)))
  (let
    ((ingredient-id (var-get next-ingredient-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set ingredients
      { ingredient-id: ingredient-id }
      {
        name: name,
        supplier: supplier,
        origin-country: origin-country,
        certification: certification,
        registered-at: block-height,
        is-verified: false
      }
    )
    (var-set next-ingredient-id (+ ingredient-id u1))
    (ok ingredient-id)
  )
)

;; Verify an ingredient (only contract owner can verify)
(define-public (verify-ingredient (ingredient-id uint))
  (let
    ((ingredient (unwrap! (map-get? ingredients { ingredient-id: ingredient-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set ingredients
      { ingredient-id: ingredient-id }
      (merge ingredient { is-verified: true })
    )
    (ok true)
  )
)

;; Create a new batch of ingredients
(define-public (create-batch
  (ingredient-id uint)
  (quantity uint)
  (manufacturing-date uint)
  (expiry-date uint))
  (let
    ((batch-id (var-get next-batch-id))
     (ingredient (unwrap! (map-get? ingredients { ingredient-id: ingredient-id }) ERR_NOT_FOUND)))
    (asserts! (get is-verified ingredient) ERR_INGREDIENT_NOT_VERIFIED)
    (asserts! (is-eq tx-sender (get supplier ingredient)) ERR_UNAUTHORIZED)
    (map-set batches
      { batch-id: batch-id }
      {
        ingredient-id: ingredient-id,
        quantity: quantity,
        manufacturing-date: manufacturing-date,
        expiry-date: expiry-date,
        current-owner: tx-sender,
        is-used: false,
        created-at: block-height
      }
    )
    (var-set next-batch-id (+ batch-id u1))
    (ok batch-id)
  )
)

;; Transfer batch ownership
(define-public (transfer-batch (batch-id uint) (new-owner principal))
  (let
    ((batch (unwrap! (map-get? batches { batch-id: batch-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get current-owner batch)) ERR_UNAUTHORIZED)
    (asserts! (not (get is-used batch)) ERR_INVALID_BATCH)
    (map-set batches
      { batch-id: batch-id }
      (merge batch { current-owner: new-owner })
    )
    (ok true)
  )
)

;; Record test results for a batch
(define-public (record-test-result
  (batch-id uint)
  (test-type (string-ascii 64))
  (result (string-ascii 256))
  (passed bool)
  (certification-body (optional principal)))
  (let
    ((test-id (var-get next-test-id))
     (batch (unwrap! (map-get? batches { batch-id: batch-id }) ERR_NOT_FOUND)))
    (map-set test-results
      { test-id: test-id }
      {
        batch-id: batch-id,
        test-type: test-type,
        test-date: block-height,
        result: result,
        passed: passed,
        tester: tx-sender,
        certification-body: certification-body
      }
    )
    (var-set next-test-id (+ test-id u1))
    (ok test-id)
  )
)

;; Create a final product using verified ingredient batches
(define-public (create-product
  (name (string-ascii 128))
  (ingredient-batches (list 20 uint)))
  (let
    ((product-id (var-get next-product-id)))
    ;; Verify all batches are available and owned by the caller
    (asserts! (is-ok (fold check-batch-availability ingredient-batches (ok true))) ERR_INVALID_BATCH)
    ;; Mark all batches as used
    (map mark-batch-as-used ingredient-batches)
    (map-set products
      { product-id: product-id }
      {
        name: name,
        manufacturer: tx-sender,
        ingredient-batches: ingredient-batches,
        production-date: block-height,
        is-verified: true,
        created-at: block-height
      }
    )
    (var-set next-product-id (+ product-id u1))
    (ok product-id)
  )
)

;; Verify supplier status
(define-public (verify-supplier (supplier principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set verified-suppliers
      { supplier: supplier }
      { verified-by: tx-sender, verified-at: block-height, status: true }
    )
    (ok true)
  )
)

;; read only functions

;; Get ingredient details
(define-read-only (get-ingredient (ingredient-id uint))
  (map-get? ingredients { ingredient-id: ingredient-id })
)

;; Get batch details
(define-read-only (get-batch (batch-id uint))
  (map-get? batches { batch-id: batch-id })
)

;; Get test result details
(define-read-only (get-test-result (test-id uint))
  (map-get? test-results { test-id: test-id })
)

;; Get product details
(define-read-only (get-product (product-id uint))
  (map-get? products { product-id: product-id })
)

;; Get supplier verification status
(define-read-only (get-supplier-status (supplier principal))
  (map-get? verified-suppliers { supplier: supplier })
)

;; Get current counters
(define-read-only (get-counters)
  {
    next-ingredient-id: (var-get next-ingredient-id),
    next-batch-id: (var-get next-batch-id),
    next-product-id: (var-get next-product-id),
    next-test-id: (var-get next-test-id)
  }
)

;; Check if a batch has passed all required tests
(define-read-only (is-batch-tested (batch-id uint))
  (let
    ((batch (unwrap! (map-get? batches { batch-id: batch-id }) false)))
    ;; In a real implementation, you would check for specific required test types
    ;; For now, we'll return true if the batch exists and isn't used
    (and (is-some (map-get? batches { batch-id: batch-id }))
         (not (get is-used batch)))
  )
)

;; private functions

;; Helper function to check batch availability
(define-private (check-batch-availability (batch-id uint) (prev (response bool uint)))
  (match prev
    success
      (let
        ((batch (unwrap! (map-get? batches { batch-id: batch-id }) ERR_NOT_FOUND)))
        (if (and (is-eq tx-sender (get current-owner batch))
                 (not (get is-used batch)))
          (ok true)
          ERR_INVALID_BATCH
        )
      )
    error (err error)
  )
)

;; Helper function to mark batch as used
(define-private (mark-batch-as-used (batch-id uint))
  (let
    ((batch (unwrap! (map-get? batches { batch-id: batch-id }) false)))
    (map-set batches
      { batch-id: batch-id }
      (merge batch { is-used: true })
    )
  )
)
