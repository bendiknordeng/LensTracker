import Foundation
import SwiftData
import SwiftUI
import WidgetKit

@MainActor
@Observable
final class LensViewModel {
    var modelContext: ModelContext?

    var selectedLensType: LensType = .monthly
    var customDays: Int = 30

    // MARK: - Active Record

    func activeRecord() -> LensRecord? {
        guard let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<LensRecord>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return try? context.fetch(descriptor).first
    }

    func allRecords() -> [LensRecord] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<LensRecord>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Actions

    func startNewPair() {
        guard let context = modelContext else { return }

        // Deactivate current pair
        if let current = activeRecord() {
            current.isActive = false
            current.endDate = .now
        }

        let days = selectedLensType == .monthly || selectedLensType == .biweekly || selectedLensType == .daily
            ? selectedLensType.defaultDays : customDays
        let record = LensRecord(
            startDate: .now,
            lensTypeName: selectedLensType.rawValue,
            replacementDays: days,
            isActive: true
        )
        context.insert(record)
        try? context.save()

        // Update widget & schedule notifications
        syncWidget()
        Task {
            await NotificationManager.shared.scheduleLensReminder(dueDate: record.dueDate)
        }
    }

    func resetTimer() {
        guard let context = modelContext, let current = activeRecord() else { return }
        current.isActive = false
        current.endDate = .now

        let record = LensRecord(
            startDate: .now,
            lensTypeName: current.lensTypeName,
            replacementDays: current.replacementDays,
            isActive: true
        )
        context.insert(record)
        try? context.save()

        syncWidget()
        Task {
            await NotificationManager.shared.scheduleLensReminder(dueDate: record.dueDate)
        }
    }

    func deleteRecord(_ record: LensRecord) {
        guard let context = modelContext else { return }
        context.delete(record)
        try? context.save()
        syncWidget()
    }

    // MARK: - Stats

    func totalPairsUsed() -> Int {
        allRecords().count
    }

    func averageWearDays() -> Double {
        let completed = allRecords().filter { !$0.isActive && $0.endDate != nil }
        guard !completed.isEmpty else { return 0 }
        let totalDays = completed.reduce(0) { sum, record in
            let days = Calendar.current.dateComponents([.day], from: record.startDate, to: record.endDate!).day ?? 0
            return sum + days
        }
        return Double(totalDays) / Double(completed.count)
    }

    func complianceRate() -> Double {
        let completed = allRecords().filter { !$0.isActive && $0.endDate != nil }
        guard !completed.isEmpty else { return 1.0 }
        let onTime = completed.filter { record in
            let days = Calendar.current.dateComponents([.day], from: record.startDate, to: record.endDate!).day ?? 0
            return days <= record.replacementDays + 1 // 1 day grace
        }
        return Double(onTime.count) / Double(completed.count)
    }

    func longestStreak() -> Int {
        let completed = allRecords()
            .filter { !$0.isActive && $0.endDate != nil }
            .sorted { $0.startDate < $1.startDate }
        var streak = 0
        var maxStreak = 0
        for record in completed {
            let days = Calendar.current.dateComponents([.day], from: record.startDate, to: record.endDate!).day ?? 0
            if days <= record.replacementDays + 1 {
                streak += 1
                maxStreak = max(maxStreak, streak)
            } else {
                streak = 0
            }
        }
        return maxStreak
    }

    // MARK: - Prescriptions

    func allPrescriptions() -> [Prescription] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<Prescription>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func latestPrescription() -> Prescription? {
        allPrescriptions().first
    }

    func addPrescription(_ prescription: Prescription) {
        guard let context = modelContext else { return }
        context.insert(prescription)
        try? context.save()
    }

    func deletePrescription(_ prescription: Prescription) {
        guard let context = modelContext else { return }
        context.delete(prescription)
        try? context.save()
    }

    // MARK: - Widget Sync

    func syncWidget() {
        if let active = activeRecord() {
            SharedDataManager.updateWidget(
                startDate: active.startDate,
                replacementDays: active.replacementDays,
                lensType: active.lensTypeName,
                isActive: true
            )
        } else {
            SharedDataManager.clearWidget()
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
