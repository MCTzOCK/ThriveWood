//
//  BodyProgressEntryEditor.swift
//  ThriveWood
//
//  Created by Ben Siebert on 10.06.26.
//

import SwiftUI
import PhotosUI

struct BodyProgressEntryEditor: View {
    @Environment(\.dismiss) private var dismiss
    let env: AppEnvironment
    let existingEntry: BodyProgressEntry?
    let onSave: () -> Void

    @State private var date: Date = .now
    @State private var weightKg: Double = 70
    @State private var hasWeight = true
    @State private var bodyFatPercentage: Double = 15
    @State private var hasBodyFat = false
    @State private var muscleMassKg: Double = 0
    @State private var hasMuscleMass = false
    @State private var waterPercentage: Double = 0
    @State private var hasWater = false

    @State private var heightCm: Double = 175
    @State private var hasHeight = true
    @State private var chestCm: Double = 0
    @State private var hasChest = false
    @State private var waistCm: Double = 0
    @State private var hasWaist = false
    @State private var hipCm: Double = 0
    @State private var hasHip = false
    @State private var shoulderCm: Double = 0
    @State private var hasShoulder = false
    @State private var neckCm: Double = 0
    @State private var hasNeck = false
    @State private var leftBicepCm: Double = 0
    @State private var hasLeftBicep = false
    @State private var rightBicepCm: Double = 0
    @State private var hasRightBicep = false
    @State private var leftForearmCm: Double = 0
    @State private var hasLeftForearm = false
    @State private var rightForearmCm: Double = 0
    @State private var hasRightForearm = false
    @State private var leftThighCm: Double = 0
    @State private var hasLeftThigh = false
    @State private var rightThighCm: Double = 0
    @State private var hasRightThigh = false
    @State private var leftCalfCm: Double = 0
    @State private var hasLeftCalf = false
    @State private var rightCalfCm: Double = 0
    @State private var hasRightCalf = false

    @State private var notes: String = ""
    @State private var energyLevel: Int = 3
    @State private var onPump: Bool = false

    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var savedPhotoPaths: [String] = []
    @State private var loadedNewImages: [PlatformImage] = []

    @State private var isMale: Bool = true
    @State private var autoCalculateBF: Bool = false

    @State private var weightUnit: WeightUnit = .kilograms

    @State private var errors = ErrorState()
    @State private var didHydrate = false
    @State private var guideFor: String?

    private var isEditing: Bool { existingEntry != nil }
    private var mUnit: String { "cm" }

    var body: some View {
        NavigationStack {
            Form {
                dateSection
                weightSection
                bodyFatSection
                measurementsSection
                photosSection
                extrasSection
            }
            .navigationTitle(isEditing ? "Eintrag bearbeiten" : "Neuer Eintrag")
            #if os(iOS)
.navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { save() }
                        .fontWeight(.semibold)
                }
            }
            .onChange(of: selectedPhotos) { _, _ in loadSelectedPhotos() }
            .onAppear { hydrate() }
            .sheet(isPresented: Binding(
                get: { guideFor != nil },
                set: { if !$0 { guideFor = nil } }
            )) {
                if let key = guideFor, let guide = measurementGuides[key] {
                    NavigationStack {
                        ScrollView {
                            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                                Text(guide.instructions)
                                    .font(.body)
                                    .padding(.horizontal, Theme.Spacing.l)
                            }
                            .padding(.vertical, Theme.Spacing.l)
                        }
                        .navigationTitle(guide.title)
                        #if os(iOS)
.navigationBarTitleDisplayMode(.inline)
#endif
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("OK") { guideFor = nil }
                            }
                        }
                    }
                    .presentationDetents([.medium])
                }
            }
            .errorAlert(errors)
        }
    }

    // MARK: - Measurement Guides

    private struct MeasurementGuide {
        let title: String
        let instructions: String
    }

    private let measurementGuides: [String: MeasurementGuide] = [
        "weight": MeasurementGuide(
            title: "Gewicht messen",
            instructions: "Wiege dich morgens nach dem Aufstehen, vor dem Essen und nach dem Toilettengang. Verwende immer die gleiche Waage und wiege dich ohne Kleidung. Stelle die Waage auf einen harten, ebenen Untergrund — nicht auf Teppich. Wiege dich am besten immer zur gleichen Tageszeit, idealerweise 2–3 Mal pro Woche und bilde den Durchschnitt."
        ),
        "height": MeasurementGuide(
            title: "Körpergröße messen",
            instructions: "Stelle dich barfuß auf einen ebenen Untergrund, Rücken und Fersen an einer Wand. Halte den Kopf gerade (Frankfurter Horizontale: Blick geradeaus, Unterkante der Augenhöhle und oberer Ohransatz auf einer Linie). Lass jemanden einen Stift waagerecht an den höchsten Punkt deines Kopfes an die Wand halten. Miss von dort bis zum Boden."
        ),
        "waist": MeasurementGuide(
            title: "Taille messen",
            instructions: "Stelle dich aufrecht hin, entspanne den Bauch (nicht einatmen oder anspannen). Lege das Maßband auf Höhe des Bauchnabels horizontal um den Körper. Es sollte eng anliegen, aber nicht in die Haut einschneiden. Miss nach dem Ausatmen, bevor du wieder einatmest. Achte darauf, dass das Band überall gleichmäßig anliegt und nicht verdreht ist."
        ),
        "chest": MeasurementGuide(
            title: "Brustumfang messen",
            instructions: "Stelle dich aufrecht hin. Lege das Maßband horizontal um den breitesten Teil der Brust, meist auf Höhe der Brustwarzen. Halte die Arme leicht vom Körper ab. Atme normal aus und miss den Umfang. Das Band sollte eng anliegen, aber nicht einschneiden."
        ),
        "hip": MeasurementGuide(
            title: "Hüftumfang messen",
            instructions: "Stelle dich aufrecht hin, Füße zusammen. Lege das Maßband horizontal um den breitesten Teil der Hüfte und Gesäßbacken. Das Band sollte parallel zum Boden verlaufen und eng anliegen, ohne in die Haut einzuschneiden. Miss nach dem Ausatmen."
        ),
        "shoulder": MeasurementGuide(
            title: "Schulterumfang messen",
            instructions: "Stelle dich aufrecht hin, Arme hängen lassen. Lege das Maßband um beide Schultern, von der Spitze der einen Schulter über den Rücken zur Spitze der anderen Schulter und vorne wieder zurück. Das Band sollte an der breitesten Stelle der Schultern anliegen, etwa auf Höhe der Schultergelenke."
        ),
        "neck": MeasurementGuide(
            title: "Nackenumfang messen",
            instructions: "Lege das Maßband horizontal um den Hals, direkt unter dem Kehlkopf (Adamsapfel). Das Band sollte eng anliegen, aber du sollst noch ein oder zwei Finger zwischen Band und Hals passen. Schau geradeaus und miss bei entspanntem Hals. Wichtig für die KFA-Berechnung nach der US-Navy-Methode."
        ),
        "bicep": MeasurementGuide(
            title: "Oberarmumfang messen",
            instructions: "Miss den Oberarm im angespannten Zustand: Beuge den Arm auf 90° und spanne den Bizeps an. Lege das Maßband um den dicksten Teil des Oberarms. Für den ungespannten Umfang: Lass den Arm locker hängen und miss den dicksten Teil. Trage immer denselben Arm ein (links/rechts) für Konsistenz."
        ),
        "forearm": MeasurementGuide(
            title: "Unterarmumfang messen",
            instructions: "Lass den Arm locker hängen. Lege das Maßband um den breitesten Teil des Unterarms, etwa auf Höhe des proximalen Drittels (nahe dem Ellbogen). Das Band sollte eng anliegen, aber nicht einschneiden. Miss bei entspanntem Arm."
        ),
        "thigh": MeasurementGuide(
            title: "Oberschenkelumfang messen",
            instructions: "Stelle dich aufrecht hin, Gewicht gleichmäßig auf beide Beine verteilt. Lege das Maßband horizontal um den breitesten Teil des Oberschenkels, etwa in der Mitte zwischen Hüfte und Knie. Das Band sollte eng anliegen, ohne in die Haut einzuschneiden. Miss immer am selben Bein für Konsistenz."
        ),
        "calf": MeasurementGuide(
            title: "Wadenumfang messen",
            instructions: "Stelle dich aufrecht hin. Lege das Maßband um den breitesten Teil der Wade. Bei angespannter Wade (auf den Zehen stehen) erhältst du den maximalen Umfang. Alternativ bei entspannter Wade messen. Verwende immer dieselbe Methode für Vergleiche."
        ),
        "bodyFat": MeasurementGuide(
            title: "Körperfettanteil",
            instructions: "Der Körperfettanteil (KFA) kann auf verschiedene Arten ermittelt werden:\n\n• Automatisch berechnen: Verwendet die US-Navy-Methode basierend auf Taille, Nacken und Körpergröße (bzw. plus Hüfte bei Frauen). Nicht ganz so genau wie eine Kaliper-Messung, aber gut für Verlaufskontrollen.\n\n• Manuell eingeben: Wenn du einen Kaliper, eine Waage mit KFA-Messung oder ein DEXA-Ergebnis hast, gib den Wert hier ein.\n\nTipp: Miss immer unter denselben Bedingungen (z. B. morgens, nüchtern) für vergleichbare Ergebnisse."
        ),
        "muscleMass": MeasurementGuide(
            title: "Muskelmasse",
            instructions: "Die Muskelmasse wird meist von Körperwaagen mit Bioimpedanzanalyse (BIA) angezeigt. Diese Werte sind mit Schwankungen behaftet, eignen sich aber für Verlaufskontrollen, solange du immer unter denselben Bedingungen misst (z. B. morgens, nüchtern, gleiches Hydratations-Level). Alternativ kann eine DEXA-Scan-Praxis genauere Werte liefern."
        ),
        "water": MeasurementGuide(
            title: "Wasseranteil",
            instructions: "Der Körperwasseranteil wird von vielen BIA-Waagen angezeigt. Er schwankt stark je nach Hydratationszustand, Salzkonsum und Trainingszeitpunkt. Miss am besten immer morgens nach dem Aufstehen, vor dem Trinken. Ein normaler Wert liegt zwischen 45–65%. Höhere Werte bedeuten nicht automatisch bessere Hydratation — der Wert korreliert invers mit dem Körperfettanteil."
        ),
    ]

    // MARK: - Date

    private var dateSection: some View {
        Section("Datum") {
            DatePicker("", selection: $date, displayedComponents: .date)
                .labelsHidden()
        }
    }

    // MARK: - Weight

    private var weightSection: some View {
        Section {
            HStack {
                Text("Gewicht")
                    .font(.subheadline)
                Spacer()
                TextField("0", value: $weightKg, format: .number.precision(.fractionLength(1...1)))
                    #if os(iOS)
.keyboardType(.decimalPad)
#endif
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text(weightUnit.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button { guideFor = "weight" } label: {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Gewicht")
        }
    }

    // MARK: - Body Fat

    private var bodyFatSection: some View {
        Section {
            Toggle("KFA automatisch berechnen", isOn: $autoCalculateBF)
            Button { guideFor = "bodyFat" } label: {
                Label("So wird der KFA berechnet", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            if autoCalculateBF {
                Picker("Geschlecht", selection: $isMale) {
                    Text("Männlich").tag(true)
                    Text("Weiblich").tag(false)
                }
                .pickerStyle(.segmented)

                if hasHeight && hasWaist && hasNeck && (isMale || hasHip) {
                    let calculated = calculateBodyFat()
                    if calculated > 0 {
                        HStack {
                            Text("Berechneter KFA")
                                .font(.subheadline)
                            Spacer()
                            Text(String(format: "%.1f%%", calculated))
                                .font(.title3.bold().monospacedDigit())
                                .foregroundStyle(.orange)
                        }
                    }
                } else {
                    let missing: [String] = {
                        var m: [String] = []
                        if !hasHeight { m.append("Körpergröße") }
                        if !hasWaist { m.append("Taille") }
                        if !hasNeck { m.append("Nacken") }
                        if !isMale && !hasHip { m.append("Hüfte") }
                        return m
                    }()
                    Text("Erforderlich: \(missing.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Toggle("Körperfett manuell eingeben", isOn: $hasBodyFat)
                if hasBodyFat {
                    HStack {
                        TextField("0", value: $bodyFatPercentage, format: .number.precision(.fractionLength(1...1)))
                            #if os(iOS)
.keyboardType(.decimalPad)
#endif
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("%")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button { guideFor = "bodyFat" } label: {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Toggle("Muskelmasse", isOn: $hasMuscleMass)
            if hasMuscleMass {
                HStack {
                    TextField("0", value: $muscleMassKg, format: .number.precision(.fractionLength(1...1)))
                        #if os(iOS)
.keyboardType(.decimalPad)
#endif
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text(weightUnit.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button { guideFor = "muscleMass" } label: {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            Toggle("Wasseranteil", isOn: $hasWater)
            if hasWater {
                HStack {
                    TextField("0", value: $waterPercentage, format: .number.precision(.fractionLength(1...1)))
                        #if os(iOS)
.keyboardType(.decimalPad)
#endif
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("%")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button { guideFor = "water" } label: {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            Text("Körperzusammensetzung")
        }
    }

    // MARK: - Measurements

    private var measurementsSection: some View {
        Section {
            measurementToggle("Körpergröße", isOn: $hasHeight, value: $heightCm, guideKey: "height")
            measurementToggle("Taille", isOn: $hasWaist, value: $waistCm, guideKey: "waist")
            measurementToggle("Brust", isOn: $hasChest, value: $chestCm, guideKey: "chest")
            measurementToggle("Hüfte", isOn: $hasHip, value: $hipCm, guideKey: "hip")
            measurementToggle("Schultern", isOn: $hasShoulder, value: $shoulderCm, guideKey: "shoulder")
            measurementToggle("Nacken", isOn: $hasNeck, value: $neckCm, guideKey: "neck")
            measurementToggle("Oberarm L", isOn: $hasLeftBicep, value: $leftBicepCm, guideKey: "bicep")
            measurementToggle("Oberarm R", isOn: $hasRightBicep, value: $rightBicepCm, guideKey: "bicep")
            measurementToggle("Unterarm L", isOn: $hasLeftForearm, value: $leftForearmCm, guideKey: "forearm")
            measurementToggle("Unterarm R", isOn: $hasRightForearm, value: $rightForearmCm, guideKey: "forearm")
            measurementToggle("Oberschenkel L", isOn: $hasLeftThigh, value: $leftThighCm, guideKey: "thigh")
            measurementToggle("Oberschenkel R", isOn: $hasRightThigh, value: $rightThighCm, guideKey: "thigh")
            measurementToggle("Wade L", isOn: $hasLeftCalf, value: $leftCalfCm, guideKey: "calf")
            measurementToggle("Wade R", isOn: $hasRightCalf, value: $rightCalfCm, guideKey: "calf")
        } header: {
            Text("Körpermaße (\(mUnit))")
        }
    }

    private func measurementToggle(_ label: String, isOn: Binding<Bool>, value: Binding<Double>, guideKey: String? = nil) -> some View {
        VStack(alignment: .leading) {
            HStack(spacing: 4) {
                Toggle(label, isOn: isOn)
                if let key = guideKey, measurementGuides[key] != nil {
                    Button { guideFor = key } label: {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            if isOn.wrappedValue {
                HStack {
                    Spacer()
                    TextField("0", value: value, format: .number.precision(.fractionLength(1...1)))
                        #if os(iOS)
.keyboardType(.decimalPad)
#endif
                        .multilineTextAlignment(.center)
                        .frame(width: 80)
                    Text(mUnit).font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.leading, Theme.Spacing.xl)
            }
        }
    }

    // MARK: - Photos

    private var photosSection: some View {
        Section {
            PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 20, matching: .images) {
                Label("Fotos hinzufügen", systemImage: "photo.on.rectangle.angled")
            }

            if !savedPhotoPaths.isEmpty || !loadedNewImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.s) {
                        ForEach(savedPhotoPaths, id: \.self) { path in
                            if let image = loadImage(path) {
                                Image(platformImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        ForEach(loadedNewImages, id: \.self) { image in
                            Image(platformImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
        } header: {
            Text("Fotos")
        }
    }

    // MARK: - Extras

    private var extrasSection: some View {
        Section("Extras") {
            HStack {
                Text("Energie-Level")
                Spacer()
                Picker("", selection: $energyLevel) {
                    ForEach(1...5, id: \.self) { level in
                        Text("\(level)").tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
            }
            Toggle("Pump", isOn: $onPump)
            TextField("Notizen...", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    // MARK: - Body Fat Calculation (US Navy Method)

    private func calculateBodyFat() -> Double {
        let waistVal = waistCm
        let neckVal = neckCm
        let heightVal = heightCm

        guard waistVal > 0, neckVal > 0, heightVal > 0 else { return 0 }

        if isMale {
            guard waistVal > neckVal else { return 0 }
            let logWaistNeck = log10(waistVal - neckVal)
            let logHeight = log10(heightVal)
            return 495.0 / (1.0324 - 0.19077 * logWaistNeck + 0.15456 * logHeight) - 450.0
        } else {
            let hipVal = hipCm
            guard hipVal > 0 else { return 0 }
            let waistHipNeck = waistVal + hipVal - neckVal
            guard waistHipNeck > 0 else { return 0 }
            let logWHN = log10(waistHipNeck)
            let logHeight = log10(heightVal)
            return 495.0 / (1.29579 - 0.35004 * logWHN + 0.22100 * logHeight) - 450.0
        }
    }

    // MARK: - Hydrate

    private func hydrate() {
        guard !didHydrate else { return }
        didHydrate = true
        guard let entry = existingEntry else { return }
        date = entry.date
        weightKg = entry.weightKg ?? 70
        hasWeight = entry.weightKg != nil
        bodyFatPercentage = entry.bodyFatPercentage ?? 15
        hasBodyFat = entry.bodyFatPercentage != nil
        muscleMassKg = entry.muscleMassKg ?? 0
        hasMuscleMass = entry.muscleMassKg != nil
        waterPercentage = entry.waterPercentage ?? 0
        hasWater = entry.waterPercentage != nil
        heightCm = entry.heightCm ?? 175; hasHeight = entry.heightCm != nil
        chestCm = entry.chestCm ?? 0; hasChest = entry.chestCm != nil
        waistCm = entry.waistCm ?? 0; hasWaist = entry.waistCm != nil
        hipCm = entry.hipCm ?? 0; hasHip = entry.hipCm != nil
        shoulderCm = entry.shoulderCm ?? 0; hasShoulder = entry.shoulderCm != nil
        neckCm = entry.neckCm ?? 0; hasNeck = entry.neckCm != nil
        leftBicepCm = entry.leftBicepCm ?? 0; hasLeftBicep = entry.leftBicepCm != nil
        rightBicepCm = entry.rightBicepCm ?? 0; hasRightBicep = entry.rightBicepCm != nil
        leftForearmCm = entry.leftForearmCm ?? 0; hasLeftForearm = entry.leftForearmCm != nil
        rightForearmCm = entry.rightForearmCm ?? 0; hasRightForearm = entry.rightForearmCm != nil
        leftThighCm = entry.leftThighCm ?? 0; hasLeftThigh = entry.leftThighCm != nil
        rightThighCm = entry.rightThighCm ?? 0; hasRightThigh = entry.rightThighCm != nil
        leftCalfCm = entry.leftCalfCm ?? 0; hasLeftCalf = entry.leftCalfCm != nil
        rightCalfCm = entry.rightCalfCm ?? 0; hasRightCalf = entry.rightCalfCm != nil
        notes = entry.notes
        energyLevel = entry.energyLevel ?? 3
        onPump = entry.onPump
        savedPhotoPaths = entry.photoPaths
        weightUnit = entry.weightUnitRaw == "lbs" ? .pounds : .kilograms
    }

    // MARK: - Photo Loading

    private func loadSelectedPhotos() {
        Task {
            var images: [PlatformImage] = []
            for item in selectedPhotos {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = PlatformImage(data: data) {
                    images.append(image)
                }
            }
            await MainActor.run {
                loadedNewImages = images
            }
        }
    }

    // MARK: - Save

    private func save() {
        let entry: BodyProgressEntry
        if let existing = existingEntry {
            entry = existing
        } else {
            entry = BodyProgressEntry()
        }

        entry.date = date
        entry.weightKg = hasWeight ? weightKg : nil
        entry.heightCm = hasHeight ? heightCm : nil
        entry.bodyFatPercentage = autoCalculateBF && hasWaist && hasNeck && hasHeight ? calculateBodyFat() : (hasBodyFat ? bodyFatPercentage : nil)
        entry.muscleMassKg = hasMuscleMass ? muscleMassKg : nil
        entry.waterPercentage = hasWater ? waterPercentage : nil
        entry.chestCm = hasChest ? chestCm : nil
        entry.waistCm = hasWaist ? waistCm : nil
        entry.hipCm = hasHip ? hipCm : nil
        entry.shoulderCm = hasShoulder ? shoulderCm : nil
        entry.neckCm = hasNeck ? neckCm : nil
        entry.leftBicepCm = hasLeftBicep ? leftBicepCm : nil
        entry.rightBicepCm = hasRightBicep ? rightBicepCm : nil
        entry.leftForearmCm = hasLeftForearm ? leftForearmCm : nil
        entry.rightForearmCm = hasRightForearm ? rightForearmCm : nil
        entry.leftThighCm = hasLeftThigh ? leftThighCm : nil
        entry.rightThighCm = hasRightThigh ? rightThighCm : nil
        entry.leftCalfCm = hasLeftCalf ? leftCalfCm : nil
        entry.rightCalfCm = hasRightCalf ? rightCalfCm : nil
        entry.notes = notes
        entry.energyLevel = energyLevel
        entry.onPump = onPump
        entry.weightUnitRaw = weightUnit.rawValue
        entry.measurementUnitRaw = "cm"

        var paths = savedPhotoPaths
        for image in loadedNewImages {
            if let data = image.jpegData(compressionQuality: 0.7),
               let url = try? env.bodyProgressService.saveImage(data) {
                paths.append(url.lastPathComponent)
            }
        }
        entry.photoPaths = paths

        if isEditing {
            env.bodyProgressService.updateEntry(entry)
        } else {
            env.bodyProgressService.addEntry(entry)
        }

        Haptics.success()
        onSave()
    }

    private func loadImage(_ path: String) -> PlatformImage? {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = dir.appendingPathComponent(path)
        return PlatformImage.fromFile(at: url.path)
    }
}
