(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-registered (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-invalid-status (err u103))
(define-constant err-not-reviewer (err u104))
(define-constant err-already-reviewed (err u105))
(define-constant err-invalid-score (err u106))
(define-constant err-collaboration-not-found (err u107))
(define-constant err-not-collaboration-member (err u108))
(define-constant err-collaboration-full (err u109))
(define-constant err-citation-not-found (err u110))
(define-constant err-self-citation (err u111))
(define-constant err-milestone-not-found (err u112))
(define-constant err-milestone-completed (err u113))
(define-constant err-invalid-milestone-status (err u114))
(define-constant err-impact-not-calculated (err u115))
(define-constant err-invalid-impact-score (err u116))
(define-constant err-insufficient-data (err u117))
(define-constant err-reviewer-below-min (err u118))

(define-data-var min-reviewer-score uint u70)
(define-data-var review-reward uint u100)
(define-data-var collaboration-counter uint u0)
(define-data-var milestone-counter uint u0)
(define-data-var impact-weight-citations uint u40)
(define-data-var impact-weight-reviews uint u35)
(define-data-var impact-weight-collaborations uint u25)

(define-map Scientists
    principal
    {
        name: (string-ascii 50),
        institution: (string-ascii 100),
        reputation-score: uint,
        total-submissions: uint,
        citations-received: uint,
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

(define-map ReviewerRewards
    principal
    {
        pending-rewards: uint,
        total-earned: uint,
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
        collaboration-id: (optional uint),
        citation-count: uint,
        milestone-count: uint,
        completed-milestones: uint,
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

(define-map Collaborations
    uint
    {
        lead-scientist: principal,
        research-focus: (string-ascii 100),
        member-count: uint,
        creation-height: uint,
        active: bool,
    }
)

(define-map CollaborationMembers
    {
        collaboration-id: uint,
        member: principal,
    }
    {
        joined-height: uint,
        contribution-score: uint,
    }
)

(define-map Citations
    {
        citing-research-id: uint,
        cited-research-id: uint,
    }
    {
        citation-height: uint,
        context: (string-ascii 200),
    }
)

(define-map Milestones
    uint
    {
        research-id: uint,
        title: (string-ascii 100),
        description: (string-ascii 300),
        target-completion: uint,
        status: (string-ascii 20),
        completion-height: (optional uint),
        progress-percentage: uint,
    }
)

(define-map ResearchImpactScores
    uint
    {
        overall-score: uint,
        citation-score: uint,
        review-score: uint,
        collaboration-score: uint,
        calculation-height: uint,
        last-updated: uint,
        trending-factor: uint,
    }
)

(define-map ImpactHistory
    {
        research-id: uint,
        period: uint,
    }
    {
        score: uint,
        citations-period: uint,
        reviews-period: uint,
        recorded-height: uint,
    }
)

(define-data-var research-counter uint u0)

(define-read-only (get-scientist (scientist-id principal))
    (map-get? Scientists scientist-id)
)

(define-read-only (get-reviewer (reviewer-id principal))
    (map-get? Reviewers reviewer-id)
)

(define-read-only (get-reviewer-rewards (reviewer-id principal))
    (map-get? ReviewerRewards reviewer-id)
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

(define-read-only (get-collaboration (collaboration-id uint))
    (map-get? Collaborations collaboration-id)
)

(define-read-only (get-collaboration-member
        (collaboration-id uint)
        (member principal)
    )
    (map-get? CollaborationMembers {
        collaboration-id: collaboration-id,
        member: member,
    })
)

(define-read-only (get-citation
        (citing-research-id uint)
        (cited-research-id uint)
    )
    (map-get? Citations {
        citing-research-id: citing-research-id,
        cited-research-id: cited-research-id,
    })
)

(define-read-only (get-milestone (milestone-id uint))
    (map-get? Milestones milestone-id)
)

(define-read-only (get-research-impact-score (research-id uint))
    (map-get? ResearchImpactScores research-id)
)

(define-read-only (get-impact-history
        (research-id uint)
        (period uint)
    )
    (map-get? ImpactHistory {
        research-id: research-id,
        period: period,
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
            citations-received: u0,
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

(define-public (create-collaboration (research-focus (string-ascii 100)))
    (let (
            (lead-scientist tx-sender)
            (collaboration-id (+ (var-get collaboration-counter) u1))
            (current-height burn-block-height)
        )
        (asserts! (is-some (get-scientist lead-scientist)) err-not-registered)
        (var-set collaboration-counter collaboration-id)
        (map-set Collaborations collaboration-id {
            lead-scientist: lead-scientist,
            research-focus: research-focus,
            member-count: u1,
            creation-height: current-height,
            active: true,
        })
        (map-set CollaborationMembers {
            collaboration-id: collaboration-id,
            member: lead-scientist,
        } {
            joined-height: current-height,
            contribution-score: u0,
        })
        (ok collaboration-id)
    )
)

(define-public (join-collaboration (collaboration-id uint))
    (let (
            (member tx-sender)
            (collaboration (unwrap! (get-collaboration collaboration-id)
                err-collaboration-not-found
            ))
            (current-height burn-block-height)
        )
        (asserts! (is-some (get-scientist member)) err-not-registered)
        (asserts! (get active collaboration) err-invalid-status)
        (asserts! (< (get member-count collaboration) u5) err-collaboration-full)
        (asserts! (is-none (get-collaboration-member collaboration-id member))
            err-already-registered
        )
        (map-set CollaborationMembers {
            collaboration-id: collaboration-id,
            member: member,
        } {
            joined-height: current-height,
            contribution-score: u0,
        })
        (map-set Collaborations collaboration-id
            (merge collaboration { member-count: (+ (get member-count collaboration) u1) })
        )
        (ok true)
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
            collaboration-id: none,
            citation-count: u0,
            milestone-count: u0,
            completed-milestones: u0,
        })
        (ok research-id)
    )
)

(define-public (submit-collaborative-research
        (title (string-ascii 100))
        (abstract (string-ascii 500))
        (ipfs-hash (string-ascii 64))
        (collaboration-id uint)
    )
    (let (
            (scientist tx-sender)
            (research-id (+ (var-get research-counter) u1))
            (current-height burn-block-height)
            (collaboration (unwrap! (get-collaboration collaboration-id)
                err-collaboration-not-found
            ))
        )
        (asserts! (is-some (get-scientist scientist)) err-not-registered)
        (asserts! (is-some (get-collaboration-member collaboration-id scientist))
            err-not-collaboration-member
        )
        (asserts! (get active collaboration) err-invalid-status)
        (var-set research-counter research-id)
        (map-set Research research-id {
            scientist: scientist,
            title: title,
            abstract: abstract,
            ipfs-hash: ipfs-hash,
            status: "pending",
            submission-height: current-height,
            review-count: u0,
            collaboration-id: (some collaboration-id),
            citation-count: u0,
            milestone-count: u0,
            completed-milestones: u0,
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
            (reviewer-data (unwrap! (get-reviewer reviewer) err-not-reviewer))
            (min-score (var-get min-reviewer-score))
            (reward-amount (var-get review-reward))
        )
        (asserts! (>= (get qualification-score reviewer-data) min-score)
            err-reviewer-below-min
        )
        (asserts! (is-none (get-review research-id reviewer))
            err-already-reviewed
        )
        (asserts! (<= score u100) err-invalid-score)
        (let (
                (existing-rewards (default-to {
                        pending-rewards: u0,
                        total-earned: u0,
                    } (map-get? ReviewerRewards reviewer)))
            )
            (begin
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
                (map-set ReviewerRewards reviewer {
                    pending-rewards: (+ (get pending-rewards existing-rewards) reward-amount),
                    total-earned: (+ (get total-earned existing-rewards) reward-amount),
                })
                (ok true)
            )
        )
    )
)

(define-public (claim-review-rewards)
    (let (
            (reviewer tx-sender)
            (existing-rewards (default-to {
                    pending-rewards: u0,
                    total-earned: u0,
                } (map-get? ReviewerRewards reviewer)))
        )
        (map-set ReviewerRewards reviewer {
            pending-rewards: u0,
            total-earned: (get total-earned existing-rewards),
        })
        (ok (get pending-rewards existing-rewards))
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

(define-public (cite-research
        (citing-research-id uint)
        (cited-research-id uint)
        (context (string-ascii 200))
    )
    (let (
            (citing-research (unwrap! (get-research citing-research-id) err-invalid-status))
            (cited-research (unwrap! (get-research cited-research-id) err-citation-not-found))
            (cited-scientist (get scientist cited-research))
            (cited-scientist-data (unwrap! (get-scientist cited-scientist) err-not-registered))
            (current-height burn-block-height)
        )
        (asserts! (not (is-eq citing-research-id cited-research-id))
            err-self-citation
        )
        (asserts! (is-eq (get scientist citing-research) tx-sender)
            err-owner-only
        )
        (asserts! (is-none (get-citation citing-research-id cited-research-id))
            err-already-registered
        )
        (map-set Citations {
            citing-research-id: citing-research-id,
            cited-research-id: cited-research-id,
        } {
            citation-height: current-height,
            context: context,
        })
        (map-set Research cited-research-id
            (merge cited-research { citation-count: (+ (get citation-count cited-research) u1) })
        )
        (map-set Scientists cited-scientist
            (merge cited-scientist-data { citations-received: (+ (get citations-received cited-scientist-data) u1) })
        )
        (ok true)
    )
)

(define-public (create-milestone
        (research-id uint)
        (title (string-ascii 100))
        (description (string-ascii 300))
        (target-completion uint)
    )
    (let (
            (research (unwrap! (get-research research-id) err-invalid-status))
            (milestone-id (+ (var-get milestone-counter) u1))
        )
        (asserts! (is-eq (get scientist research) tx-sender) err-owner-only)
        (var-set milestone-counter milestone-id)
        (map-set Milestones milestone-id {
            research-id: research-id,
            title: title,
            description: description,
            target-completion: target-completion,
            status: "pending",
            completion-height: none,
            progress-percentage: u0,
        })
        (map-set Research research-id
            (merge research { milestone-count: (+ (get milestone-count research) u1) })
        )
        (ok milestone-id)
    )
)

(define-public (update-milestone-progress
        (milestone-id uint)
        (progress-percentage uint)
    )
    (let (
            (milestone (unwrap! (get-milestone milestone-id) err-milestone-not-found))
            (research (unwrap! (get-research (get research-id milestone))
                err-invalid-status
            ))
        )
        (asserts! (is-eq (get scientist research) tx-sender) err-owner-only)
        (asserts! (not (is-eq (get status milestone) "completed"))
            err-milestone-completed
        )
        (asserts! (<= progress-percentage u100) err-invalid-milestone-status)
        (ok (map-set Milestones milestone-id
            (merge milestone { progress-percentage: progress-percentage })
        ))
    )
)

(define-public (complete-milestone (milestone-id uint))
    (let (
            (milestone (unwrap! (get-milestone milestone-id) err-milestone-not-found))
            (research (unwrap! (get-research (get research-id milestone))
                err-invalid-status
            ))
            (current-height burn-block-height)
        )
        (asserts! (is-eq (get scientist research) tx-sender) err-owner-only)
        (asserts! (not (is-eq (get status milestone) "completed"))
            err-milestone-completed
        )
        (map-set Milestones milestone-id
            (merge milestone {
                status: "completed",
                completion-height: (some current-height),
                progress-percentage: u100,
            })
        )
        (map-set Research (get research-id milestone)
            (merge research { completed-milestones: (+ (get completed-milestones research) u1) })
        )
        (ok true)
    )
)

(define-public (calculate-impact-score (research-id uint))
    (let (
            (research (unwrap! (get-research research-id) err-invalid-status))
            (citation-count (get citation-count research))
            (review-count (get review-count research))
            (collaboration-bonus (if (is-some (get collaboration-id research)) u20 u0))
            (citation-weight (var-get impact-weight-citations))
            (review-weight (var-get impact-weight-reviews))
            (collab-weight (var-get impact-weight-collaborations))
            (current-height burn-block-height)
            (age-factor (if (> current-height (get submission-height research))
                        (/ u100 (+ u1 (/ (- current-height (get submission-height research)) u1000)))
                        u100
                    )
            )
            (citation-score (* citation-count citation-weight))
            (review-score (* review-count review-weight))
            (collab-score (* collaboration-bonus collab-weight))
            (base-score (+ citation-score (+ review-score collab-score)))
            (trending-factor (if (> age-factor u50) (/ age-factor u10) u5))
            (overall-score (/ (* base-score trending-factor) u10))
        )
        (asserts! (is-some (get-research research-id)) err-invalid-status)
        (map-set ResearchImpactScores research-id {
            overall-score: overall-score,
            citation-score: citation-score,
            review-score: review-score,
            collaboration-score: collab-score,
            calculation-height: current-height,
            last-updated: current-height,
            trending-factor: trending-factor,
        })
        (ok overall-score)
    )
)

(define-public (update-impact-scores-batch (research-ids (list 10 uint)))
    (let (
            (current-height burn-block-height)
        )
        (ok (fold update-single-impact research-ids u0))
    )
)

(define-private (update-single-impact (research-id uint) (acc uint))
    (match (calculate-impact-score research-id)
        success (+ acc u1)
        error acc
    )
)

(define-public (record-impact-history (research-id uint))
    (let (
            (impact-score (unwrap! (get-research-impact-score research-id)
                err-impact-not-calculated
            ))
            (current-height burn-block-height)
            (period (/ current-height u1000))
            (research (unwrap! (get-research research-id) err-invalid-status))
        )
        (map-set ImpactHistory {
            research-id: research-id,
            period: period,
        } {
            score: (get overall-score impact-score),
            citations-period: (get citation-count research),
            reviews-period: (get review-count research),
            recorded-height: current-height,
        })
        (ok true)
    )
)

(define-public (apply-reputation-boost (scientist principal))
    (let (
            (scientist-data (unwrap! (get-scientist scientist) err-not-registered))
            (current-score (get reputation-score scientist-data))
            (citations-received (get citations-received scientist-data))
            (boost-amount (if (> citations-received u10)
                         (if (> citations-received u50) u20 u10)
                         u5
                      )
            )
            (new-score (+ current-score boost-amount))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set Scientists scientist
            (merge scientist-data { reputation-score: new-score })
        )
        (ok new-score)
    )
)

(define-read-only (get-top-impact-research (limit uint))
    (if (<= limit u10)
        (ok "Top impact research calculation would require iteration")
        err-invalid-impact-score
    )
)

(define-public (set-impact-weights
        (citations-weight uint)
        (reviews-weight uint)
        (collaborations-weight uint)
    )
    (let (
            (total-weight (+ citations-weight (+ reviews-weight collaborations-weight)))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-eq total-weight u100) err-invalid-impact-score)
        (var-set impact-weight-citations citations-weight)
        (var-set impact-weight-reviews reviews-weight)
        (var-set impact-weight-collaborations collaborations-weight)
        (ok true)
    )
)
