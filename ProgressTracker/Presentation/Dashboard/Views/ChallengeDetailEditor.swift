import PhotosUI
import SwiftUI

struct ChallengeDetailEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draftDetail: ChallengeDetail
    @State private var draftMood: Mood
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var isSavingPhotos = false

    let challenge: Challenge
    let onSave: (ChallengeDetail, Mood) -> Void
    let onCancel: (() -> Void)?
    private let photoHelper: PhotoStorageHelper

    init(
        challenge: Challenge,
        detail: ChallengeDetail,
        mood: Mood,
        photoHelper: PhotoStorageHelper = PhotoStorageHelper(),
        onSave: @escaping (ChallengeDetail, Mood) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.challenge = challenge
        _draftDetail = State(initialValue: detail)
        _draftMood = State(initialValue: mood)
        self.onSave = onSave
        self.onCancel = onCancel
        self.photoHelper = photoHelper
    }

    var body: some View {
        NavigationStack {
            Form {
                if challenge.trackingStyle == .trackTime {
                    Section(header: Text("Logged Time")) {
                        Text("\(draftDetail.loggedMinutes) minutes logged today")
                            .font(.headline)
                        if let target = challenge.dailyTargetMinutes {
                            Text("Target: \(target) minutes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: Text("Notes")) {
                    TextEditor(text: Binding(
                        get: { draftDetail.notes ?? "" },
                        set: { draftDetail.notes = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minHeight: 120)
                }

                Section(header: Text("Mood")) {
                    MoodSelectorView(selectedMood: Binding(
                        get: { draftMood },
                        set: { draftMood = $0 }
                    ))
                }

                Section(header: Text("Photos")) {
                    if draftDetail.photoURLs.isEmpty {
                        Text("No photos yet")
                            .foregroundColor(.secondary)
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                            ForEach(Array(draftDetail.photoURLs.enumerated()), id: \.element) { index, url in
                                ZStack(alignment: .topTrailing) {
                                    ChallengePhotoThumbnail(url: url)
                                        .frame(height: 90)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    Button {
                                        draftDetail.photoURLs.remove(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white)
                                            .padding(4)
                                            .background(Color.black.opacity(0.6))
                                            .clipShape(Circle())
                                    }
                                    .offset(x: -4, y: 4)
                                    .accessibilityLabel("Remove photo")
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    PhotosPicker(selection: $pickerItems, maxSelectionCount: 4, matching: .images) {
                        Label("Add Photos", systemImage: "camera.fill")
                    }
                    .disabled(isSavingPhotos)
                    .onChange(of: pickerItems) { newItems in
                        Task { await handlePickedItems(newItems) }
                    }
                }
            }
            .navigationTitle(challenge.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel?()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draftDetail, draftMood)
                        dismiss()
                    }
                    .disabled(isSavingPhotos)
                }
            }
            .overlay(alignment: .bottom) {
                if isSavingPhotos {
                    ProgressView("Processing photos...")
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding()
                }
            }
        }
    }

    private func handlePickedItems(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        isSavingPhotos = true
        defer { isSavingPhotos = false }
        for item in items {
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    let url = try photoHelper.persist(imageData: data)
                    draftDetail.photoURLs.append(url)
                }
            } catch {
                print("Photo import error: \(error.localizedDescription)")
            }
        }
        pickerItems.removeAll()
    }
}
