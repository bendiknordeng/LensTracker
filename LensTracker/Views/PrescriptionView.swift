import SwiftUI

struct PrescriptionView: View {
    @Environment(LensViewModel.self) private var viewModel
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.allPrescriptions().isEmpty {
                    ContentUnavailableView(
                        "No Prescriptions",
                        systemImage: "doc.text",
                        description: Text("Add your contact lens prescription so it's always on hand for your eye doctor.")
                    )
                } else {
                    List {
                        ForEach(viewModel.allPrescriptions(), id: \.id) { rx in
                            NavigationLink {
                                PrescriptionDetailView(prescription: rx)
                            } label: {
                                PrescriptionRow(prescription: rx)
                            }
                        }
                        .onDelete { offsets in
                            let prescriptions = viewModel.allPrescriptions()
                            for i in offsets {
                                viewModel.deletePrescription(prescriptions[i])
                            }
                        }
                    }
                }
            }
            .navigationTitle("Prescriptions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddPrescriptionSheet()
            }
        }
    }
}

private struct PrescriptionRow: View {
    let prescription: Prescription

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Contact Lens Prescription")
                    .font(.headline)
                Spacer()
            }
            if let doctor = prescription.doctorName, !doctor.isEmpty {
                Text("Dr. \(doctor)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                Text("OD: \(Prescription.formatSphere(prescription.odSphere))")
                Text("OS: \(Prescription.formatSphere(prescription.osSphere))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Prescription Sheet

private struct AddPrescriptionSheet: View {
    @Environment(LensViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var doctorName = ""
    @State private var clinicName = ""
    @State private var notes = ""

    // OD
    @State private var odSphere = "+0.00"
    @State private var odCylinder = "+0.00"
    @State private var odAxis = "90"
    @State private var odBC = ""
    @State private var odDIA = ""
    @State private var odAdd = ""
    @State private var odBrand = ""

    // OS
    @State private var osSphere = "+0.00"
    @State private var osCylinder = "+0.00"
    @State private var osAxis = "90"
    @State private var osBC = ""
    @State private var osDIA = ""
    @State private var osAdd = ""
    @State private var osBrand = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Doctor") {
                    TextField("Doctor name", text: $doctorName)
                    TextField("Clinic name", text: $clinicName)
                }

                Section("Right Eye (OD)") {
                    EyeFields(
                        sphere: $odSphere, cylinder: $odCylinder, axis: $odAxis,
                        bc: $odBC, dia: $odDIA, add: $odAdd, brand: $odBrand
                    )
                }

                Section("Left Eye (OS)") {
                    EyeFields(
                        sphere: $osSphere, cylinder: $osCylinder, axis: $osAxis,
                        bc: $osBC, dia: $osDIA, add: $osAdd, brand: $osBrand
                    )
                }

                Section("Notes") {
                    TextField("Additional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button("Save Prescription") {
                        save()
                        dismiss()
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Add Prescription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let rx = Prescription()
        rx.doctorName = doctorName.isEmpty ? nil : doctorName
        rx.clinicName = clinicName.isEmpty ? nil : clinicName
        rx.notes = notes.isEmpty ? nil : notes

        rx.odSphere = Double(odSphere)
        rx.odCylinder = Double(odCylinder)
        rx.odAxis = Int(odAxis)
        rx.odBaseCurve = Double(odBC)
        rx.odDiameter = Double(odDIA)
        rx.odAdd = Double(odAdd)
        rx.odBrand = odBrand.isEmpty ? nil : odBrand

        rx.osSphere = Double(osSphere)
        rx.osCylinder = Double(osCylinder)
        rx.osAxis = Int(osAxis)
        rx.osBaseCurve = Double(osBC)
        rx.osDiameter = Double(osDIA)
        rx.osAdd = Double(osAdd)
        rx.osBrand = osBrand.isEmpty ? nil : osBrand

        viewModel.addPrescription(rx)
    }
}

private struct EyeFields: View {
    @Binding var sphere: String
    @Binding var cylinder: String
    @Binding var axis: String
    @Binding var bc: String
    @Binding var dia: String
    @Binding var add: String
    @Binding var brand: String

    var body: some View {
        VStack(spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    DialPicker(title: "SPH", selection: $sphere, options: PrescriptionDialOptions.sphereValues)
                    DialPicker(title: "CYL", selection: $cylinder, options: PrescriptionDialOptions.cylinderValues)
                    DialPicker(title: "AXIS", selection: $axis, options: PrescriptionDialOptions.axisValues)
                }
                .padding(.vertical, 4)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    DialPicker(title: "BC", selection: $bc, options: PrescriptionDialOptions.baseCurveValues)
                    DialPicker(title: "DIA", selection: $dia, options: PrescriptionDialOptions.diameterValues)
                    DialPicker(title: "ADD", selection: $add, options: PrescriptionDialOptions.addValues)
                }
                .padding(.vertical, 4)
            }

            TextField("Brand / Product name", text: $brand)
        }
    }
}

private struct DialPicker: View {
    let title: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 96, height: 110)
            .clipped()
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .frame(width: 96)
    }
}

private enum PrescriptionDialOptions {
    static let sphereValues = ["--"] + formattedValues(from: -12.0, through: 8.0, step: 0.25, format: "%+.2f")
    static let cylinderValues = ["--"] + formattedValues(from: -6.0, through: 0.0, step: 0.25, format: "%+.2f")
    static let axisValues = ["--"] + (0...180).map { "\($0)" }
    static let baseCurveValues = ["--"] + formattedValues(from: 8.0, through: 9.5, step: 0.1, format: "%.1f")
    static let diameterValues = ["--"] + formattedValues(from: 13.0, through: 15.5, step: 0.1, format: "%.1f")
    static let addValues = ["--"] + formattedValues(from: 0.75, through: 3.0, step: 0.25, format: "+%.2f")

    private static func formattedValues(from start: Double, through end: Double, step: Double, format: String) -> [String] {
        var values: [String] = []
        var current = start

        while current <= end + 0.0001 {
            values.append(String(format: format, current))
            current += step
        }

        return values
    }
}
