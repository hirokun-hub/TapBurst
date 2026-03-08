import Foundation

struct CPSTierFilter {
    private(set) var confirmedTier: CPSTier = .t0
    private var pendingTier: CPSTier?
    private var pendingSince: TimeInterval = 0.0

    static let upDelay: TimeInterval = 0.15
    static let downDelay: TimeInterval = 0.30

    mutating func update(rawTier: CPSTier, now: TimeInterval) -> Bool {
        if rawTier == confirmedTier {
            pendingTier = nil
            return false
        }

        if pendingTier == rawTier {
            let delay = rawTier > confirmedTier ? Self.upDelay : Self.downDelay
            if now - pendingSince >= delay {
                confirmedTier = rawTier
                pendingTier = nil
                return true
            }
        } else {
            pendingTier = rawTier
            pendingSince = now
        }

        return false
    }

    mutating func reset() {
        confirmedTier = .t0
        pendingTier = nil
    }
}
