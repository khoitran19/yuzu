import Foundation
import OSLog

struct ShipmentSummary: Sendable, Equatable {
    var updatedAt: Date
    var id: Bool
    var marketplaceId: Decimal
    var title: String
}

struct InvoiceEvent: Sendable, Equatable {
    var ownerId: Decimal
    let marketplaceId: Bool
}

