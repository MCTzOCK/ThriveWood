//
//  ExerciseDetailsSheet.swift
//  ThriveWood
//
//  Created by Ben Siebert on 07.05.26.
//

import SwiftUI


struct ExerciseDetailsSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedImageIndex = 0
    var exercise: Exercise
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if !exercise.images.isEmpty {
                        imageCarousel
                            .frame(height: 200)
                    } else {
                        placeholderImage
                            .frame(height: 200)
                    }
                    
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        
                        infoPillsSection
                        
                        if !exercise.instructions.isEmpty {
                            instructionsSection
                        }
                        
                        if !exercise.details.isEmpty {
                            detailsSection
                        }
                        
                        muscleGroupsSection
                        
                        if exercise.isBuiltIn {
                            metadataSection
                        }
                    }
                    .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Schließen")
                    }
                }
            }
        }
    }
    private var imageCarousel: some View {
        TabView(selection: $selectedImageIndex) {
            ForEach(Array(exercise.images.enumerated()), id: \.offset) { index, imageName in
                Image("Exercises/\(imageName.replacingOccurrences(of: ".png", with: "").replacingOccurrences(of: ".jpg", with: "").replacingOccurrences(of: ".jpeg", with: ""))")
                    .resizable()
                    .scaledToFill()
                    .clipped()
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        // 1. Add the gradient as an overlay that ignores touches
        .overlay {
            LinearGradient(
                colors: [.clear, .clear, .black.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        }
        // 2. Add the custom pagination dots aligned to the bottom
        .overlay(alignment: .bottom) {
            if exercise.images.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<exercise.images.count, id: \.self) { index in
                        Circle()
                            .fill(selectedImageIndex == index ? .white : .white.opacity(0.5))
                            .frame(width: 8, height: 8)
                            .onTapGesture {
                                // Tapping a dot still animates nicely
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedImageIndex = index
                                }
                            }
                    }
                }
                .padding(.bottom, 20)
            }
        }
        // 3. Add the icon aligned to the top leading corner
        .overlay(alignment: .topLeading) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                
                Image(systemName: exercise.iconSystemName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .shadow(color: .black.opacity(0.1), radius: 4)
            .padding(.top, 16)
            .padding(.leading, 16)
        }
    }
    
    
    private var placeholderImage: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.3),
                            Color.accentColor.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            VStack(spacing: 12) {
                Image(systemName: exercise.iconSystemName)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.tint)
                
                Text("Keine Bilder verfügbar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.name)
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)
            
            if exercise.isBuiltIn {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(.tint)
                    Text("Vorgefertigte Übung")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var infoPillsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                InfoPill(
                    text: exercise.category.id,
                    color: .accentColor
                )
                
                InfoPill(
                    text: exercise.trackingType.label,
                    color: .blue
                )
                
                if !exercise.primaryMuscleGroups.isEmpty {
                    InfoPill(
                        text: "\(exercise.primaryMuscleGroups.count) Muskeln",
                        color: .orange
                    )
                }
                
                if exercise.isBuiltIn && !exercise.instructions.isEmpty {
                    InfoPill(
                        text: "\(exercise.instructions.count) Schritte",
                        color: .purple
                    )
                }
            }
            .padding(.horizontal, 1) // Für Shadow
        }
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Ausführung", systemImage: "list.number")
                .font(.title2.bold())
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, instruction in
                    InstructionStep(
                        number: index + 1,
                        text: instruction,
                        isLast: index == exercise.instructions.count - 1
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGroupedBackground))
        )
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Details", systemImage: "info.circle")
                .font(.title2.bold())
                .foregroundStyle(.primary)
            
            Text(exercise.details)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGroupedBackground))
        )
    }
    
    private var muscleGroupsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Muskelgruppen", systemImage: "figure.strengthtraining.traditional")
                .font(.title2.bold())
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 16) {
                // Primary Muscles
                if !exercise.primaryMuscleGroups.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                            Text("Primäre Muskeln")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                        }
                        
                        FlowLayout(spacing: 8) {
                            ForEach(exercise.primaryMuscleGroups, id: \.self) { muscle in
                                MuscleTag(muscle: muscle, isPrimary: true)
                            }
                        }
                    }
                }
                
                // Secondary Muscles
                if !exercise.secondaryMuscleGroups.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(.orange)
                                .frame(width: 8, height: 8)
                            Text("Sekundäre Muskeln")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                        }
                        
                        FlowLayout(spacing: 8) {
                            ForEach(exercise.secondaryMuscleGroups, id: \.self) { muscle in
                                MuscleTag(muscle: muscle, isPrimary: false)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGroupedBackground))
        )
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Informationen", systemImage: "tag")
                .font(.title2.bold())
                .foregroundStyle(.primary)
            
            VStack(spacing: 8) {
                MetadataRow(
                    icon: "calendar.badge.plus",
                    label: "Hinzugefügt",
                    value: exercise.createdAt.formatted(date: .abbreviated, time: .omitted)
                )
                
                MetadataRow(
                    icon: "building.2",
                    label: "Quelle",
                    value: "Vorgefertigte Übung"
                )
                
                if !exercise.images.isEmpty {
                    MetadataRow(
                        icon: "photo.stack",
                        label: "Bilder",
                        value: "\(exercise.images.count)"
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGroupedBackground))
        )
    }
    
    
    private struct InfoPill: View {
        let text: String
        let color: Color
        
        var body: some View {
            HStack(spacing: 6) {
                Text(text)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
            .foregroundStyle(color)
            .shadow(color: color.opacity(0.2), radius: 2, x: 0, y: 1)
        }
    }
    
    private struct InstructionStep: View {
        let number: Int
        let text: String
        let isLast: Bool
        
        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                // Step Number
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.accentColor, .accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Text("\(number)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }
                
                // Instruction Text
                VStack(alignment: .leading, spacing: 8) {
                    Text(text)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineSpacing(2)
                    
                    if !isLast {
                        Divider()
                            .padding(.top, 4)
                    }
                }
            }
        }
    }
    
    private struct MuscleTag: View {
        let muscle: MuscleGroup
        let isPrimary: Bool
        
        var body: some View {
            HStack(spacing: 6) {
                Image(systemName: muscle.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(muscle.label)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isPrimary ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
            )
            .foregroundStyle(isPrimary ? .green : .orange)
        }
    }
    
    
    private struct MetadataRow: View {
        let icon: String
        let label: String
        let value: String
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(.tint)
                    .frame(width: 20)
                
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
            }
        }
    }
    
    private struct FlowLayout: Layout {
        var spacing: CGFloat = 8
        
        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let result = FlowResult(
                in: proposal.replacingUnspecifiedDimensions().width,
                subviews: subviews,
                spacing: spacing
            )
            return result.size
        }
        
        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            let result = FlowResult(
                in: bounds.width,
                subviews: subviews,
                spacing: spacing
            )
            for (index, subview) in subviews.enumerated() {
                subview.place(
                    at: CGPoint(
                        x: bounds.minX + result.frames[index].minX,
                        y: bounds.minY + result.frames[index].minY
                    ),
                    proposal: .unspecified
                )
            }
        }
        
        struct FlowResult {
            var size: CGSize = .zero
            var frames: [CGRect] = []
            
            init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
                var x: CGFloat = 0
                var y: CGFloat = 0
                var lineHeight: CGFloat = 0
                
                for subview in subviews {
                    let size = subview.sizeThatFits(.unspecified)
                    
                    if x + size.width > maxWidth && x > 0 {
                        x = 0
                        y += lineHeight + spacing
                        lineHeight = 0
                    }
                    
                    frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
                    lineHeight = max(lineHeight, size.height)
                    x += size.width + spacing
                }
                
                self.size = CGSize(width: maxWidth, height: y + lineHeight)
            }
        }
    }
    
}
