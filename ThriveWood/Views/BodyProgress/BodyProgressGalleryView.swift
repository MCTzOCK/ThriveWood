//
//  BodyProgressGalleryView.swift
//  ThriveWood
//
//  Created by Ben Siebert on 11.06.26.
//

import SwiftUI

struct BodyProgressGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    let entries: [BodyProgressEntry]

    @State private var selectedPhoto: PhotoLocation?

    private var entriesWithPhotos: [BodyProgressEntry] {
        entries.filter { !$0.photoPaths.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.xl) {
                    ForEach(entriesWithPhotos, id: \.id) { entry in
                        dateSection(for: entry)
                    }
                }
                .padding(.vertical, Theme.Spacing.l)
            }
            .background(Color.black)
            .navigationTitle("Fotogalerie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .fullScreenCover(item: $selectedPhoto) { loc in
                PhotoViewer(entries: entriesWithPhotos, initialEntry: loc.entryIndex, initialPhoto: loc.photoIndex)
            }
        }
    }

    private func dateSection(for entry: BodyProgressEntry) -> some View {
        VStack(spacing: Theme.Spacing.s) {
            Text("— \(entry.date.formatted(.dateTime.day().month(.wide).year())) —")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))

            let columns = [GridItem(.adaptive(minimum: (UIScreen.main.bounds.width - Theme.Spacing.l * 2 - Theme.Spacing.s) / 3), spacing: Theme.Spacing.s)]

            LazyVGrid(columns: columns, spacing: Theme.Spacing.s) {
                ForEach(Array(entry.photoPaths.enumerated()), id: \.offset) { index, path in
                    if let image = loadImage(path) {
                        Button {
                            if let entryIndex = entriesWithPhotos.firstIndex(where: { $0.id == entry.id }) {
                                selectedPhoto = PhotoLocation(entryIndex: entryIndex, photoIndex: index)
                            }
                        } label: {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: (UIScreen.main.bounds.width - Theme.Spacing.l * 2 - Theme.Spacing.s * 2) / 3,
                                       height: (UIScreen.main.bounds.width - Theme.Spacing.l * 2 - Theme.Spacing.s * 2) / 3)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
        }
    }

    private func loadImage(_ path: String) -> UIImage? {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = dir.appendingPathComponent(path)
        return UIImage(contentsOfFile: url.path)
    }
}

// MARK: - Photo Viewer (swipe through all photos)

struct PhotoViewer: View {
    @Environment(\.dismiss) private var dismiss
    let entries: [BodyProgressEntry]
    let initialEntry: Int
    let initialPhoto: Int

    @State private var currentEntryIndex: Int
    @State private var currentPhotoIndex: Int

    init(entries: [BodyProgressEntry], initialEntry: Int, initialPhoto: Int) {
        self.entries = entries
        self.initialEntry = initialEntry
        self.initialPhoto = initialPhoto
        self._currentEntryIndex = State(initialValue: initialEntry)
        self._currentPhotoIndex = State(initialValue: initialPhoto)
    }

    private var currentEntry: BodyProgressEntry {
        entries[currentEntryIndex]
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                photoPager
                footer
            }
        }
        .gesture(DragGesture(minimumDistance: 30)
            .onEnded { value in
                if value.translation.width < -50 { goNext() }
                else if value.translation.width > 50 { goPrevious() }
            }
        )
        .onAppear { updateIndices() }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.8))
            }
            Spacer()
            Text(currentEntry.date.formatted(.dateTime.day().month(.abbreviated).year()))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
            Text("\(photoNumber) / \(totalPhotos)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.top, Theme.Spacing.s)
    }

    private var photoPager: some View {
        TabView(selection: $currentPhotoIndex) {
            ForEach(Array(currentEntry.photoPaths.enumerated()), id: \.offset) { index, path in
                if let image = loadImage(path) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .tag(index)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }

    private var footer: some View {
        VStack(spacing: Theme.Spacing.xs) {
            if totalPhotos > 1 {
                Text("\(currentEntryIndex + 1) von \(entries.count) Einträgen")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(.bottom, Theme.Spacing.l)
    }

    private var photoNumber: Int {
        var count = 0
        for i in 0..<currentEntryIndex {
            count += entries[i].photoPaths.count
        }
        return count + currentPhotoIndex + 1
    }

    private var totalPhotos: Int {
        entries.reduce(0) { $0 + $1.photoPaths.count }
    }

    private func goNext() {
        if currentPhotoIndex < currentEntry.photoPaths.count - 1 {
            currentPhotoIndex += 1
        } else if currentEntryIndex < entries.count - 1 {
            currentEntryIndex += 1
            currentPhotoIndex = 0
        }
    }

    private func goPrevious() {
        if currentPhotoIndex > 0 {
            currentPhotoIndex -= 1
        } else if currentEntryIndex > 0 {
            currentEntryIndex -= 1
            currentEntryIndex = max(0, currentEntryIndex)
            currentPhotoIndex = entries[currentEntryIndex].photoPaths.count - 1
        }
    }

    private func updateIndices() {
        if currentEntryIndex >= entries.count { currentEntryIndex = max(0, entries.count - 1) }
        if currentPhotoIndex >= currentEntry.photoPaths.count { currentPhotoIndex = max(0, currentEntry.photoPaths.count - 1) }
    }

    private func loadImage(_ path: String) -> UIImage? {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = dir.appendingPathComponent(path)
        return UIImage(contentsOfFile: url.path)
    }
}

struct PhotoLocation: Identifiable {
    let id = UUID()
    let entryIndex: Int
    let photoIndex: Int
}