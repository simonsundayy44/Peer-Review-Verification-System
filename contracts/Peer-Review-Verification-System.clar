(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-registered (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-invalid-status (err u103))
(define-constant err-not-reviewer (err u104))
(define-constant err-already-reviewed (err u105))
(define-constant err-invalid-score (err u106))

(define-data-var min-reviewer-score uint u70)
(define-data-var review-reward uint u100)

(define-map Scientists
    principal
    {
        name: (string-ascii 50),
        institution: (string-ascii 100),
        reputation-score: uint,
        total-submissions: uint,
    }
)

(define-map Reviewers
    principal
    {
        name: (string-ascii 50),
        expertise: (string-ascii 100),
        reviews-completed: uint,
        qualification-score: uint,
    }
)

(define-map Research
    uint
    {
        scientist: principal,
        title: (string-ascii 100),
        abstract: (string-ascii 500),
        ipfs-hash: (string-ascii 64),
        status: (string-ascii 20),
        submission-height: uint,
        review-count: uint,
    }
)

(define-map Reviews
    {
        research-id: uint,
        reviewer: principal,
    }
    {
        score: uint,
        feedback: (string-ascii 500),
        review-height: uint,
        verified: bool,
    }
)

(define-data-var research-counter uint u0)

(define-read-only (get-scientist (scientist-id principal))
    (map-get? Scientists scientist-id)
)

(define-read-only (get-reviewer (reviewer-id principal))
    (map-get? Reviewers reviewer-id)
)

(define-read-only (get-research (research-id uint))
    (map-get? Research research-id)
)

(define-read-only (get-review
        (research-id uint)
        (reviewer principal)
    )
    (map-get? Reviews {
        research-id: research-id,
        reviewer: reviewer,
    })
)

(define-public (register-scientist
        (name (string-ascii 50))
        (institution (string-ascii 100))
    )
    (let ((scientist tx-sender))
        (asserts! (is-none (get-scientist scientist)) err-already-registered)
        (ok (map-set Scientists scientist {
            name: name,
            institution: institution,
            reputation-score: u100,
            total-submissions: u0,
        }))
    )
)

(define-public (register-reviewer
        (name (string-ascii 50))
        (expertise (string-ascii 100))
    )
    (let ((reviewer tx-sender))
        (asserts! (is-none (get-reviewer reviewer)) err-already-registered)
        (ok (map-set Reviewers reviewer {
            name: name,
            expertise: expertise,
            reviews-completed: u0,
            qualification-score: u100,
        }))
    )
)

(define-public (submit-research
        (title (string-ascii 100))
        (abstract (string-ascii 500))
        (ipfs-hash (string-ascii 64))
    )
    (let (
            (scientist tx-sender)
            (research-id (+ (var-get research-counter) u1))
            (current-height burn-block-height)
        )
        (asserts! (is-some (get-scientist scientist)) err-not-registered)
        (var-set research-counter research-id)
        (map-set Research research-id {
            scientist: scientist,
            title: title,
            abstract: abstract,
            ipfs-hash: ipfs-hash,
            status: "pending",
            submission-height: current-height,
            review-count: u0,
        })
        (ok research-id)
    )
)

(define-public (submit-review
        (research-id uint)
        (score uint)
        (feedback (string-ascii 500))
    )
    (let (
            (reviewer tx-sender)
            (research (unwrap! (get-research research-id) err-invalid-status))
            (current-height burn-block-height)
        )
        (asserts! (is-some (get-reviewer reviewer)) err-not-reviewer)
        (asserts! (is-none (get-review research-id reviewer))
            err-already-reviewed
        )
        (asserts! (<= score u100) err-invalid-score)
        (map-set Reviews {
            research-id: research-id,
            reviewer: reviewer,
        } {
            score: score,
            feedback: feedback,
            review-height: current-height,
            verified: false,
        })
        (map-set Research research-id
            (merge research { review-count: (+ (get review-count research) u1) })
        )
        (ok true)
    )
)

(define-public (verify-review
        (research-id uint)
        (reviewer principal)
    )
    (let (
            (review (unwrap! (get-review research-id reviewer) err-invalid-status))
            (reviewer-data (unwrap! (get-reviewer reviewer) err-not-reviewer))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set Reviews {
            research-id: research-id,
            reviewer: reviewer,
        }
            (merge review { verified: true })
        )
        (map-set Reviewers reviewer
            (merge reviewer-data {
                reviews-completed: (+ (get reviews-completed reviewer-data) u1),
                qualification-score: (+ (get qualification-score reviewer-data) u1),
            })
        )
        (ok true)
    )
)

(define-public (update-research-status
        (research-id uint)
        (new-status (string-ascii 20))
    )
    (let ((research (unwrap! (get-research research-id) err-invalid-status)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set Research research-id (merge research { status: new-status })))
    )
)
