(define-map campaigns
    { campaign-id: uint }
    {
        owner: principal,
        goal: uint,
        current-amount: uint,
        title: (string-ascii 50),
        description: (string-ascii 500),
        end-block: uint,
        is-active: bool
    }
)

(define-map donations
    { campaign-id: uint, donor: principal }
    { amount: uint }
)

(define-data-var next-campaign-id uint u1)

;; Error constants
(define-constant ERR-NOT-OWNER (err u100))
(define-constant ERR-CAMPAIGN-INACTIVE (err u101))
(define-constant ERR-GOAL-REACHED (err u102))
(define-constant ERR-DEADLINE-PASSED (err u103))
(define-constant ERR-UNAUTHORIZED (err u104))

(define-public (create-campaign (goal uint) (title (string-ascii 50)) (description (string-ascii 500)) (duration uint))
    (let
        (
            (campaign-id (var-get next-campaign-id))
            (end-block (+ block-height duration))
        )
        (map-set campaigns
            { campaign-id: campaign-id }
            {
                owner: tx-sender,
                goal: goal,
                current-amount: u0,
                title: title,
                description: description,
                end-block: end-block,
                is-active: true
            }
        )
        (var-set next-campaign-id (+ campaign-id u1))
        (ok campaign-id)
    )
)
(define-public (donate (campaign-id uint) (amount uint))
    (let
        (
            (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) (err u404)))
            (current-amount (get current-amount campaign))
            (goal (get goal campaign))
            (is-active (get is-active campaign))
            (end-block (get end-block campaign))
        )
        (asserts! is-active ERR-CAMPAIGN-INACTIVE)
        (asserts! (<= block-height end-block) ERR-DEADLINE-PASSED)
        (asserts! (< current-amount goal) ERR-GOAL-REACHED)
        
        ;; Transfer STX from sender to contract
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        
        ;; Update campaign amount
        (map-set campaigns
            { campaign-id: campaign-id }
            (merge campaign { current-amount: (+ current-amount amount) })
        )
        
        ;; Record donation
        (map-set donations
            { campaign-id: campaign-id, donor: tx-sender }
            { amount: (default-to u0 (get amount (map-get? donations { campaign-id: campaign-id, donor: tx-sender }))) }
        )
        
        (ok true)
    )
)
(define-public (withdraw-funds (campaign-id uint))
    (let
        (
            (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) (err u404)))
            (owner (get owner campaign))
            (current-amount (get current-amount campaign))
            (goal (get goal campaign))
        )
        (asserts! (is-eq tx-sender owner) ERR-NOT-OWNER)
        (asserts! (>= current-amount goal) ERR-GOAL-REACHED)
        
        ;; Transfer all funds to campaign owner
        (try! (as-contract (stx-transfer? current-amount tx-sender owner)))
        
        ;; Deactivate campaign
        (map-set campaigns
            { campaign-id: campaign-id }
            (merge campaign { is-active: false })
        )
        
        (ok true)
    )
)
;; Get campaign details
(define-read-only (get-campaign (campaign-id uint))
    (map-get? campaigns { campaign-id: campaign-id })
)

;; Get donation amount for a specific donor
(define-read-only (get-donation (campaign-id uint) (donor principal))
    (map-get? donations { campaign-id: campaign-id, donor: donor })
)

;; Check if campaign goal is reached
(define-read-only (is-goal-reached (campaign-id uint))
    (let
        (
            (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) (err u404)))
        )
        (>= (get current-amount campaign) (get goal campaign))
    )
)
;; Enhanced with comments for better understanding
;; Simplified error handling and clarified error messages for unwrap! calls.
;; No new code added—improved documentation and refactored error handling consistency.
