(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_DOCUMENT (err u103))
(define-constant ERR_EXPIRED (err u104))
(define-constant ERR_NOT_REGULATOR (err u105))
(define-constant ERR_INVALID_STATUS (err u106))

(define-data-var contract-owner principal CONTRACT_OWNER)
(define-data-var document-id-nonce uint u0)

(define-map authorized-regulators
  { regulator: principal }
  { authorized: bool, added-at: uint }
)

(define-map compliance-documents
  { document-id: uint }
  {
    company: principal,
    industry: (string-ascii 50),
    document-type: (string-ascii 100),
    document-hash: (buff 32),
    issued-at: uint,
    expires-at: uint,
    status: (string-ascii 20),
    regulator: principal,
    metadata: (string-ascii 500)
  }
)

(define-map company-compliance-status
  { company: principal, industry: (string-ascii 50) }
  {
    status: (string-ascii 20),
    last-updated: uint,
    active-documents: uint,
    expired-documents: uint
  }
)

(define-map document-verifications
  { document-id: uint, verifier: principal }
  { verified-at: uint, verification-note: (string-ascii 200) }
)

(define-map company-profiles
  { company: principal }
  {
    name: (string-ascii 100),
    industry: (string-ascii 50),
    registration-number: (string-ascii 50),
    registered-at: uint,
    is-active: bool
  }
)

(define-public (add-regulator (regulator principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    (ok (map-set authorized-regulators
      { regulator: regulator }
      { authorized: true, added-at: stacks-block-height }
    ))
  )
)

(define-public (remove-regulator (regulator principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    (ok (map-delete authorized-regulators { regulator: regulator }))
  )
)

(define-public (register-company (name (string-ascii 100)) (industry (string-ascii 50)) (registration-number (string-ascii 50)))
  (let
    (
      (existing-profile (map-get? company-profiles { company: tx-sender }))
    )
    (asserts! (is-none existing-profile) ERR_ALREADY_EXISTS)
    (ok (map-set company-profiles
      { company: tx-sender }
      {
        name: name,
        industry: industry,
        registration-number: registration-number,
        registered-at: stacks-block-height,
        is-active: true
      }
    ))
  )
)

(define-public (submit-compliance-document
  (industry (string-ascii 50))
  (document-type (string-ascii 100))
  (document-hash (buff 32))
  (expires-at uint)
  (metadata (string-ascii 500))
)
  (let
    (
      (document-id (+ (var-get document-id-nonce) u1))
      (company-profile (unwrap! (map-get? company-profiles { company: tx-sender }) ERR_NOT_FOUND))
    )
    (asserts! (get is-active company-profile) ERR_UNAUTHORIZED)
    (asserts! (> expires-at stacks-block-height) ERR_INVALID_DOCUMENT)
    (var-set document-id-nonce document-id)
    (map-set compliance-documents
      { document-id: document-id }
      {
        company: tx-sender,
        industry: industry,
        document-type: document-type,
        document-hash: document-hash,
        issued-at: stacks-block-height,
        expires-at: expires-at,
        status: "pending",
        regulator: CONTRACT_OWNER,
        metadata: metadata
      }
    )
    (update-company-compliance-status tx-sender industry)
    (ok document-id)
  )
)

(define-public (verify-document (document-id uint) (verification-note (string-ascii 200)))
  (let
    (
      (document (unwrap! (map-get? compliance-documents { document-id: document-id }) ERR_NOT_FOUND))
      (regulator-auth (unwrap! (map-get? authorized-regulators { regulator: tx-sender }) ERR_NOT_REGULATOR))
    )
    (asserts! (get authorized regulator-auth) ERR_NOT_REGULATOR)
    (map-set document-verifications
      { document-id: document-id, verifier: tx-sender }
      { verified-at: stacks-block-height, verification-note: verification-note }
    )
    (map-set compliance-documents
      { document-id: document-id }
      (merge document { status: "verified", regulator: tx-sender })
    )
    (update-company-compliance-status (get company document) (get industry document))
    (ok true)
  )
)

(define-public (reject-document (document-id uint) (rejection-note (string-ascii 200)))
  (let
    (
      (document (unwrap! (map-get? compliance-documents { document-id: document-id }) ERR_NOT_FOUND))
      (regulator-auth (unwrap! (map-get? authorized-regulators { regulator: tx-sender }) ERR_NOT_REGULATOR))
    )
    (asserts! (get authorized regulator-auth) ERR_NOT_REGULATOR)
    (map-set document-verifications
      { document-id: document-id, verifier: tx-sender }
      { verified-at: stacks-block-height, verification-note: rejection-note }
    )
    (map-set compliance-documents
      { document-id: document-id }
      (merge document { status: "rejected", regulator: tx-sender })
    )
    (update-company-compliance-status (get company document) (get industry document))
    (ok true)
  )
)

(define-public (update-document-status (document-id uint) (new-status (string-ascii 20)))
  (let
    (
      (document (unwrap! (map-get? compliance-documents { document-id: document-id }) ERR_NOT_FOUND))
      (regulator-auth (unwrap! (map-get? authorized-regulators { regulator: tx-sender }) ERR_NOT_REGULATOR))
    )
    (asserts! (get authorized regulator-auth) ERR_NOT_REGULATOR)
    (asserts! (or (is-eq new-status "active") (is-eq new-status "suspended") (is-eq new-status "revoked")) ERR_INVALID_STATUS)
    (map-set compliance-documents
      { document-id: document-id }
      (merge document { status: new-status, regulator: tx-sender })
    )
    (update-company-compliance-status (get company document) (get industry document))
    (ok true)
  )
)

(define-private (update-company-compliance-status (company principal) (industry (string-ascii 50)))
  (let
    (
      (current-status (default-to
        { status: "non-compliant", last-updated: u0, active-documents: u0, expired-documents: u0 }
        (map-get? company-compliance-status { company: company, industry: industry })
      ))
      (active-docs (count-documents-by-status company industry "verified"))
      (expired-docs (count-documents-by-status company industry "expired"))
      (new-status (if (> active-docs u0) "compliant" "non-compliant"))
    )
    (map-set company-compliance-status
      { company: company, industry: industry }
      {
        status: new-status,
        last-updated: stacks-block-height,
        active-documents: active-docs,
        expired-documents: expired-docs
      }
    )
  )
)

(define-private (count-documents-by-status (company principal) (industry (string-ascii 50)) (target-status (string-ascii 20)))
  u1
)

(define-read-only (get-document (document-id uint))
  (map-get? compliance-documents { document-id: document-id })
)

(define-read-only (get-company-profile (company principal))
  (map-get? company-profiles { company: company })
)

(define-read-only (get-company-compliance-status (company principal) (industry (string-ascii 50)))
  (map-get? company-compliance-status { company: company, industry: industry })
)

(define-read-only (get-document-verification (document-id uint) (verifier principal))
  (map-get? document-verifications { document-id: document-id, verifier: verifier })
)

(define-read-only (is-regulator (regulator principal))
  (match (map-get? authorized-regulators { regulator: regulator })
    auth (get authorized auth)
    false
  )
)

(define-read-only (is-document-valid (document-id uint))
  (match (map-get? compliance-documents { document-id: document-id })
    document (and 
      (or (is-eq (get status document) "verified") (is-eq (get status document) "active"))
      (> (get expires-at document) stacks-block-height)
    )
    false
  )
)

(define-read-only (is-company-compliant (company principal) (industry (string-ascii 50)))
  (match (map-get? company-compliance-status { company: company, industry: industry })
    status (is-eq (get status status) "compliant")
    false
  )
)

(define-read-only (get-contract-info)
  {
    owner: (var-get contract-owner),
    total-documents: (var-get document-id-nonce),
    current-block: stacks-block-height
  }
)

(define-read-only (verify-document-hash (document-id uint) (provided-hash (buff 32)))
  (match (map-get? compliance-documents { document-id: document-id })
    document (is-eq (get document-hash document) provided-hash)
    false
  )
)
