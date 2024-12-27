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

