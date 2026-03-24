import SwiftUI

struct PrescriptionDetailView: View {
    let prescription: Prescription

    var body: some View {
        List {
            // Header
            Section {
                if prescription.isExpired {
                    Label("This prescription has expired", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }

            // Standard Rx table format that eye doctors use
            Section("Contact Lens Prescription") {
                // Header row
                HStack {
                    Text("").frame(width: 30)
                    Group {
                        Text("SPH")
                        Text("CYL")
                        Text("AXIS")
                        Text("BC")
                        Text("DIA")
                    }
                    .font(.caption.weight(.bold))
                    .frame(maxWidth: .infinity)
                }
                .foregroundStyle(.secondary)

                // OD Row
                HStack {
                    Text("OD")
                        .font(.caption.weight(.bold))
                        .frame(width: 30)
                    Group {
                        Text(Prescription.formatSphere(prescription.odSphere))
                        Text(Prescription.formatCylinder(prescription.odCylinder))
                        Text(Prescription.formatAxis(prescription.odAxis))
                        Text(Prescription.formatBC(prescription.odBaseCurve))
                        Text(Prescription.formatDIA(prescription.odDiameter))
                    }
                    .font(.subheadline.monospacedDigit())
                    .frame(maxWidth: .infinity)
                }

                // OS Row
                HStack {
                    Text("OS")
                        .font(.caption.weight(.bold))
                        .frame(width: 30)
                    Group {
                        Text(Prescription.formatSphere(prescription.osSphere))
                        Text(Prescription.formatCylinder(prescription.osCylinder))
                        Text(Prescription.formatAxis(prescription.osAxis))
                        Text(Prescription.formatBC(prescription.osBaseCurve))
                        Text(Prescription.formatDIA(prescription.osDiameter))
                    }
                    .font(.subheadline.monospacedDigit())
                    .frame(maxWidth: .infinity)
                }

                // ADD power if present
                if prescription.odAdd != nil || prescription.osAdd != nil {
                    HStack {
                        Text("ADD").font(.caption.weight(.bold)).frame(width: 30)
                        Text("OD: \(Prescription.formatAdd(prescription.odAdd))")
                            .frame(maxWidth: .infinity)
                        Text("OS: \(Prescription.formatAdd(prescription.osAdd))")
                            .frame(maxWidth: .infinity)
                    }
                    .font(.subheadline.monospacedDigit())
                }
            }

            // Brand info
            if prescription.odBrand != nil || prescription.osBrand != nil {
                Section("Brand / Product") {
                    if let brand = prescription.odBrand, !brand.isEmpty {
                        HStack {
                            Text("OD")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(brand)
                        }
                    }
                    if let brand = prescription.osBrand, !brand.isEmpty {
                        HStack {
                            Text("OS")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(brand)
                        }
                    }
                }
            }

            // Doctor & clinic
            Section("Provider") {
                if let doctor = prescription.doctorName, !doctor.isEmpty {
                    LabeledContent("Doctor", value: "Dr. \(doctor)")
                }
                if let clinic = prescription.clinicName, !clinic.isEmpty {
                    LabeledContent("Clinic", value: clinic)
                }
                LabeledContent("Prescribed", value: prescription.date.formatted(.dateTime.year().month(.abbreviated).day()))
                if let exp = prescription.expirationDate {
                    LabeledContent("Expires", value: exp.formatted(.dateTime.year().month(.abbreviated).day()))
                }
            }

            // Notes
            if let notes = prescription.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                }
            }
        }
        .navigationTitle("Prescription")
        .navigationBarTitleDisplayMode(.inline)
    }
}
