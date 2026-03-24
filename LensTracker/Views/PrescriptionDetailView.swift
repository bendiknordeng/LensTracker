import SwiftUI

struct PrescriptionDetailView: View {
    @State private var showEditSheet = false
    let prescription: Prescription

    var body: some View {
        ZStack {
            LensScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    LensSectionTitle(eyebrow: "Prescription", title: "Your current lens parameters")
                        .padding(.horizontal)
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 14) {
                        PrescriptionMetricGrid(
                            eyeLabel: "OD",
                            sphere: Prescription.formatSphere(prescription.odSphere),
                            cylinder: Prescription.formatCylinder(prescription.odCylinder),
                            axis: Prescription.formatAxis(prescription.odAxis),
                            baseCurve: Prescription.formatBC(prescription.odBaseCurve),
                            diameter: Prescription.formatDIA(prescription.odDiameter)
                        )

                        PrescriptionMetricGrid(
                            eyeLabel: "OS",
                            sphere: Prescription.formatSphere(prescription.osSphere),
                            cylinder: Prescription.formatCylinder(prescription.osCylinder),
                            axis: Prescription.formatAxis(prescription.osAxis),
                            baseCurve: Prescription.formatBC(prescription.osBaseCurve),
                            diameter: Prescription.formatDIA(prescription.osDiameter)
                        )

                        if prescription.odAdd != nil || prescription.osAdd != nil {
                            HStack(spacing: 12) {
                                DetailRxValueBadge(label: "OD ADD", value: Prescription.formatAdd(prescription.odAdd))
                                DetailRxValueBadge(label: "OS ADD", value: Prescription.formatAdd(prescription.osAdd))
                            }
                        }
                    }
                    .padding(20)
                    .lensCardStyle()
                    .padding(.horizontal)

                    if prescription.odBrand != nil || prescription.osBrand != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            LensSectionTitle(eyebrow: "Brand", title: "Recommended products")
                            if let brand = prescription.odBrand, !brand.isEmpty {
                                InfoLine(label: "OD", value: brand)
                            }
                            if let brand = prescription.osBrand, !brand.isEmpty {
                                InfoLine(label: "OS", value: brand)
                            }
                        }
                        .padding(20)
                        .lensCardStyle()
                        .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        LensSectionTitle(eyebrow: "Provider", title: "Clinic details")
                        if let doctor = prescription.doctorName, !doctor.isEmpty {
                            InfoLine(label: "Doctor", value: "Dr. \(doctor)")
                        }
                        if let clinic = prescription.clinicName, !clinic.isEmpty {
                            InfoLine(label: "Clinic", value: clinic)
                        }
                    }
                    .padding(20)
                    .lensCardStyle()
                    .padding(.horizontal)

                    if let notes = prescription.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            LensSectionTitle(eyebrow: "Notes", title: "Additional details")
                            Text(notes)
                                .font(.subheadline)
                                .foregroundStyle(LensPalette.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(20)
                        .lensCardStyle()
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Prescription")
        .navigationBarTitleDisplayMode(.inline)
        .lensNavigationChrome()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            PrescriptionEditorSheet(prescription: prescription, title: "Edit Prescription")
        }
    }
}

private struct PrescriptionMetricGrid: View {
    let eyeLabel: String
    let sphere: String
    let cylinder: String
    let axis: String
    let baseCurve: String
    let diameter: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                EyeInfoButton(eyeLabel: eyeLabel)
            }

            LazyVGrid(columns: [.init(), .init(), .init(), .init(), .init()], spacing: 10) {
                MetricTile(label: "SPH", value: sphere, message: "Sphere power. This is the main lens strength.")
                MetricTile(label: "CYL", value: cylinder, message: "Cylinder power. Used to correct astigmatism.")
                MetricTile(label: "AXIS", value: axis, message: "Axis angle for astigmatism correction, from 0 to 180 degrees.")
                MetricTile(label: "BC", value: baseCurve, message: "Base curve. It describes the curve of the lens.")
                MetricTile(label: "DIA", value: diameter, message: "Diameter. This is the width of the contact lens.")
            }
        }
    }
}

private struct MetricTile: View {
    let label: String
    let value: String
    let message: String

    @State private var showInfo = false

    var body: some View {
        Button {
            showInfo = true
        } label: {
            VStack(spacing: 6) {
                Text(label)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(LensPalette.slate)

                Text(value)
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(LensPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.78),
                        Color.white.opacity(0.60)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.white.opacity(0.85), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showInfo, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(label)
                    .font(.headline)
                    .foregroundStyle(LensPalette.ink)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(LensPalette.slate)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(width: 260, alignment: .leading)
            .presentationCompactAdaptation(.popover)
        }
    }
}

private struct InfoLine: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(LensPalette.slate)
                .frame(width: 56, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .foregroundStyle(LensPalette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(.white.opacity(0.56))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct DetailRxValueBadge: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(LensPalette.slate)
            Text(value)
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(LensPalette.teal)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct InfoPopoverButton: View {
    let title: String
    let message: String

    @State private var showInfo = false

    var body: some View {
        Button {
            showInfo = true
        } label: {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(LensPalette.teal.opacity(0.9))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showInfo, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(LensPalette.ink)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(LensPalette.slate)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(width: 260, alignment: .leading)
            .presentationCompactAdaptation(.popover)
        }
    }
}

private struct EyeInfoButton: View {
    let eyeLabel: String

    @State private var showInfo = false

    private var message: String {
        if eyeLabel == "OD" {
            return "OD means right eye. It comes from oculus dexter."
        }
        return "OS means left eye. It comes from oculus sinister."
    }

    var body: some View {
        Button {
            showInfo = true
        } label: {
            HStack(spacing: 6) {
                Text(eyeLabel)
                    .font(.caption.weight(.bold))
                    .tracking(1.0)
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 12))
            }
            .foregroundStyle(LensPalette.teal)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showInfo, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(eyeLabel)
                    .font(.headline)
                    .foregroundStyle(LensPalette.ink)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(LensPalette.slate)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(width: 260, alignment: .leading)
            .presentationCompactAdaptation(.popover)
        }
    }
}
