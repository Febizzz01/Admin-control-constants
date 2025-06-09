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
