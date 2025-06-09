;; Admin control constants
(define-constant ERR_NOT_ADMIN u102)
(define-constant ERR_ADMIN_ALREADY_EXISTS u103)
(define-constant ERR_INVALID_ADMIN_ACTION u104)
(define-constant ERR_ACTION_TIMEOUT u105)
(define-constant ERR_INVALID_ACTION_TYPE u106)
(define-constant ERR_INVALID_TARGET u107)

;; Valid action types
(define-constant ACTION_TYPE_ASSIGN_ROLE "assign-role")

;; Define admin data maps
(define-map admins
    principal
    { active: bool }
)

(define-map pending-admins
    principal
    { proposer: principal, expires: uint }
)

(define-map admin-actions
    uint
    {
        proposer: principal,
        action-type: (string-ascii 20),
        target: principal,
        expires: uint,
        executed: bool

    }
)

;; Initialize contract deployer as first admin
(map-set admins tx-sender { active: true })

;; Read-only function to check if an address is admin
(define-read-only (is-admin (address principal))
    (default-to false (get active (map-get? admins address)))
)

;; Read-only function to validate action type
(define-read-only (is-valid-action-type (action-type (string-ascii 20)))
    (is-eq action-type ACTION_TYPE_ASSIGN_ROLE)
)

;; Propose a new admin
(define-public (propose-admin (new-admin principal))
    (begin
        (asserts! (is-admin tx-sender) (err ERR_NOT_ADMIN))
        (asserts! (is-none (map-get? admins new-admin)) (err ERR_ADMIN_ALREADY_EXISTS))
        
        (map-set pending-admins
            new-admin
            { 
                proposer: tx-sender,
                expires: (+ block-height u144) ;; 24 hour window (assuming 10 min blocks)
            }
        )
        (ok true)
    )
)

;; Accept admin role (must be called by proposed admin)
(define-public (accept-admin)
    (let (
        (pending-info (unwrap! (map-get? pending-admins tx-sender) (err ERR_NOT_ADMIN)))
    )
        (asserts! (< block-height (get expires pending-info)) (err ERR_ACTION_TIMEOUT))
        (map-set admins tx-sender { active: true })
        (map-delete pending-admins tx-sender)
        (ok true)
    )
)

;; Propose an admin action (like assigning roles)
(define-public (propose-admin-action (action-type (string-ascii 20)) (target principal))
    (begin
        ;; Validate inputs
        (asserts! (is-valid-action-type action-type) (err ERR_INVALID_ACTION_TYPE))
        (asserts! (not (is-eq target tx-sender)) (err ERR_INVALID_TARGET))
        
        ;; Check admin status
        (asserts! (is-admin tx-sender) (err ERR_NOT_ADMIN))
        
        ;; Create action
        (let (
            (action-id block-height)
        )
            (map-set admin-actions
                action-id
    {
                    proposer: tx-sender,
                    action-type: action-type,
                    target: target,
                    expires: (+ block-height u144),
                    executed: false
                }
            )
            (ok action-id)
        )
    )
)

;; Execute an admin action (requires different admin than proposer)
(define-public (execute-admin-action (action-id uint))
    (let (
        (action (unwrap! (map-get? admin-actions action-id) 
                        (err ERR_INVALID_ADMIN_ACTION)))
    )
        (asserts! (is-admin tx-sender) (err ERR_NOT_ADMIN))
        (asserts! (not (is-eq tx-sender (get proposer action))) (err ERR_NOT_ADMIN))
        (asserts! (< block-height (get expires action)) (err ERR_ACTION_TIMEOUT))
        (asserts! (not (get executed action)) (err ERR_INVALID_ADMIN_ACTION))
        
        (if (is-eq (get action-type action) ACTION_TYPE_ASSIGN_ROLE)
            (assign-role-internal (get target action))
            (err ERR_INVALID_ADMIN_ACTION))
    )
)
  ;; Internal function to assign roles (called by execute-admin-action)
(define-private (assign-role-internal (target principal))
    (begin
        ;; Your role assignment logic here
        (ok true)
    )
)