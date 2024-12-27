;; Title: Community Fundraiser
;; Version: 1.0
;; Description: A community-driven fundraising platform with campaign management, donor tracking, and collaboration features

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
(define-constant ERR-CAMPAIGN-INACTIVE (err u101))
(define-constant ERR-GOAL-REACHED (err u102))
(define-constant ERR-DEADLINE-PASSED (err u103))
(define-constant ERR-UNAUTHORIZED (err u104))
(define-constant ERR-EXTENSION-LIMIT (err u105))
(define-constant ERR-INVALID-EXTENSION (err u106))
(define-constant ERR-ALREADY-COLLABORATOR (err u107))
(define-constant ERR-NOT-COLLABORATOR (err u108))
(define-constant ERR-INSUFFICIENT-PERMISSIONS (err u109))

;; Public functions
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
        
        (try! (as-contract (stx-transfer? current-amount tx-sender owner)))
        
        (map-set campaigns
            { campaign-id: campaign-id }
            (merge campaign { is-active: false })
        )
        
        (ok true)
    )
)

(define-public (extend-deadline (campaign-id uint) (extension-blocks uint) (reason (string-ascii 200)))
    (let
        (
            (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) (err u404)))
            (deadline-info (default-to 
                { 
                    extension-count: u0,
                    original-end-block: (get end-block campaign),
                    reason: ""
                }
                (map-get? campaign-deadlines { campaign-id: campaign-id })
            ))
        )
        (asserts! (is-eq tx-sender (get owner campaign)) ERR-NOT-OWNER)
        (asserts! (< (get extension-count deadline-info) u2) ERR-EXTENSION-LIMIT)
        (asserts! (>= (get end-block campaign) block-height) ERR-DEADLINE-PASSED)
        
        (map-set campaigns
            { campaign-id: campaign-id }
            (merge campaign { end-block: (+ (get end-block campaign) extension-blocks) })
        )
        
        (map-set campaign-deadlines
            { campaign-id: campaign-id }
            {
                extension-count: (+ (get extension-count deadline-info) u1),
                original-end-block: (get original-end-block deadline-info),
                reason: reason
            }
        )
        
        (ok true)
    )
)

(define-public (set-campaign-tags 
    (campaign-id uint) 
    (new-tags (list 5 (string-ascii 20))) 
    (category (string-ascii 20)))
    (let
        (
            (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) (err u404)))
        )
        (asserts! (is-eq tx-sender (get owner campaign)) ERR-NOT-OWNER)
        
        (map-set campaign-tags
            { campaign-id: campaign-id }
            {
                tags: new-tags,
                category: category
            }
        )
        
        (ok true)
    )
)

(define-public (add-collaborator 
    (campaign-id uint) 
    (collaborator principal) 
    (role (string-ascii 20))
    (permissions (list 3 (string-ascii 20))))
    (let
        (
            (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) (err u404)))
        )
        (asserts! (is-eq tx-sender (get owner campaign)) ERR-NOT-OWNER)
        (asserts! (is-none (map-get? campaign-collaborators { campaign-id: campaign-id, collaborator: collaborator })) ERR-ALREADY-COLLABORATOR)
        
        (map-set campaign-collaborators
            { campaign-id: campaign-id, collaborator: collaborator }
            {
                role: role,
                permissions: permissions,
                added-by: tx-sender,
                added-block: block-height
            }
        )
        
        (ok true)
    )
)

(define-public (update-campaign-as-collaborator 
    (campaign-id uint) 
    (new-title (string-ascii 50)) 
    (new-description (string-ascii 500)))
    (let
        (
            (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) (err u404)))
            (collaborator-info (unwrap! (map-get? campaign-collaborators { campaign-id: campaign-id, collaborator: tx-sender }) ERR-NOT-COLLABORATOR))
        )
        (asserts! (is-some (index-of (get permissions collaborator-info) "update")) ERR-INSUFFICIENT-PERMISSIONS)
        
        (map-set campaigns
            { campaign-id: campaign-id }
            (merge campaign {
                title: new-title,
                description: new-description
            })
        )
        
        (ok true)
    )
)

;; Read-only functions
(define-read-only (get-campaign (campaign-id uint))
    (map-get? campaigns { campaign-id: campaign-id })
)

(define-read-only (get-donation (campaign-id uint) (donor principal))
    (map-get? donations { campaign-id: campaign-id, donor: donor })
)

(define-read-only (get-deadline-info (campaign-id uint))
    (map-get? campaign-deadlines { campaign-id: campaign-id })
)

(define-read-only (get-campaign-tags (campaign-id uint))
    (map-get? campaign-tags { campaign-id: campaign-id })
)

(define-read-only (get-donor-history (campaign-id uint) (donor principal))
    (map-get? donor-history { campaign-id: campaign-id, donor: donor })
)

(define-read-only (get-collaborator-info (campaign-id uint) (collaborator principal))
    (map-get? campaign-collaborators { campaign-id: campaign-id, collaborator: collaborator })
)

(define-read-only (is-goal-reached (campaign-id uint))
    (let
        (
            (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) (err u404)))
            (current-amount (get current-amount campaign))
            (goal (get goal campaign))
        )
        (ok (>= current-amount goal))
    )
)

;; Private functions
(define-private (has-permission (campaign-id uint) (required-permission (string-ascii 20)))
    (match (map-get? campaign-collaborators { campaign-id: campaign-id, collaborator: tx-sender })
        collaborator-info (is-some (index-of (get permissions collaborator-info) required-permission))
        false
    )
)

