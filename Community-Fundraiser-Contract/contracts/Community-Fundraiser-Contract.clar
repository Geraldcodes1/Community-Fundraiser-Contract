;; Storage
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

(define-map campaign-deadlines
    { campaign-id: uint }
    {
        extension-count: uint,
        original-end-block: uint,
        reason: (string-ascii 200)
    }
)

(define-map campaign-tags
    { campaign-id: uint }
    {
        tags: (list 5 (string-ascii 20)),
        category: (string-ascii 20)
    }
)

(define-map donor-history
    { campaign-id: uint, donor: principal }
    {
        donations: (list 10 {
            amount: uint,
            block: uint,
            message: (optional (string-ascii 100))
        }),
        total-amount: uint,
        last-donation: uint
    }
)

(define-map campaign-collaborators
    { campaign-id: uint, collaborator: principal }
    {
        role: (string-ascii 20),
        permissions: (list 3 (string-ascii 20)),
        added-by: principal,
        added-block: uint
    }
)

;; Variables
(define-data-var next-campaign-id uint u1)

;; Error constants
(define-constant ERR-NOT-OWNER (err u100))
(define-constant ERR-CAMPAI
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

(define-public (donate-with-message (campaign-id uint) (amount uint) (message (optional (string-ascii 100))))
    (let
        (
            (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) (err u404)))
            (current-history (default-to
                {
                    donations: (list ),
                    total-amount: u0,
                    last-donation: u0
                }
                (map-get? donor-history { campaign-id: campaign-id, donor: tx-sender })
            ))
            (new-donation {
                amount: amount,
                block: block-height,
                message: message
            })
        )
        (try! (donate campaign-id amount))
        
        (map-set donor-history
            { campaign-id: campaign-id, donor: tx-sender }
            {
                donations: (unwrap! (as-max-len? (append (get donations current-history) new-donation) u10) (err u404)),
                total-amount: (+ (get total-amount current-history) amount),
                last-donation: block-height
            }
        )
        
        (ok true)
    )
)

