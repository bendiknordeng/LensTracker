import Foundation
import SwiftData

@Model
final class Prescription {
    var id: UUID
    var date: Date

    // Right Eye (OD - Oculus Dexter)
    var odSphere: Double?
    var odCylinder: Double?
    var odAxis: Int?
    var odBaseCurve: Double?
    var odDiameter: Double?
    var odAdd: Double?
    var odBrand: String?

    // Left Eye (OS - Oculus Sinister)
    var osSphere: Double?
    var osCylinder: Double?
    var osAxis: Int?
    var osBaseCurve: Double?
    var osDiameter: Double?
    var osAdd: Double?
    var osBrand: String?

    var doctorName: String?
    var clinicName: String?
    var expirationDate: Date?
    var notes: String?

    init(date: Date = .now) {
        self.id = UUID()
        self.date = date
    }

    var isExpired: Bool {
        guard let exp = expirationDate else { return false }
        return exp < .now
    }

    // Format sphere value with sign: +1.25 / -2.50
    static func formatSphere(_ value: Double?) -> String {
        guard let v = value else { return "—" }
        return String(format: "%+.2f", v)
    }

    static func formatCylinder(_ value: Double?) -> String {
        guard let v = value else { return "—" }
        return String(format: "%+.2f", v)
    }

    static func formatAxis(_ value: Int?) -> String {
        guard let v = value else { return "—" }
        return "\(v)°"
    }

    static func formatBC(_ value: Double?) -> String {
        guard let v = value else { return "—" }
        return String(format: "%.1f", v)
    }

    static func formatDIA(_ value: Double?) -> String {
        guard let v = value else { return "—" }
        return String(format: "%.1f", v)
    }

    static func formatAdd(_ value: Double?) -> String {
        guard let v = value else { return "—" }
        return String(format: "+%.2f", v)
    }
}
