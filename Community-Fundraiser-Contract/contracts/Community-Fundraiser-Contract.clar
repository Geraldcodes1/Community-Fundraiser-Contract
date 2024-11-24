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
