//
//  WatchRecordings.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 29/10/24.
//

import OrderedCollections
import QuickLook
import SwiftUI

struct WatchRecordings: View {
    @EnvironmentObject<NavigationModel> var navigationModel
    
    @StateObject private var vm = ViewModel()
    
    @Environment(\.editMode) private var editMode
    
    var isEditing: Bool {
        editMode?.wrappedValue.isEditing ?? false
    }
    
    var body: some View {
        ZStack {
            switch vm.currentMediaType {
            case .movies:
                moviesList
            case .photos:
                photosList
            }
        }
        .quickLookPreview($vm.selectedURL, in: vm.urls)
        .fullScreenCover(item: $vm.editVideo) { movieMedia in
            TrimmingVideoView(fileURL: movieMedia.mediaFile) { result in
                editingControllerCompletion(result, movieMedia: movieMedia)
            }
        }
        .overlay(alignment: .center) {
            if (vm.currentMediaType == .movies && vm.groupedMovies.isEmpty) || (vm.currentMediaType == .photos && vm.groupedPhotos.isEmpty) {
                VStack(spacing: 20) {
                    Image(systemName: "square.stack.3d.up.slash.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.gray)
                    
                    Text("No Recordings yet")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
            }
            progressView
        }
        .interactiveToasts($navigationModel.toasts)
        // MARK: - Error Alert
        .alert(isPresented: $vm.showError, error: vm.error) { }
        // MARK: - Rename Alert
        .alert("Rename Item", isPresented: $vm.showRename, presenting: vm.itemToRename) { (itemToRename: any MediaProtocol) in
            AlertTextFieldView(itemToRename.displayName, initialText: itemToRename.displayName) { oldName, newName in
                if vm.itemToRename == nil { return }
                
                vm.showRename = false
                if vm.renameMedia(itemToRename, to: newName) {
                    self.navigationModel.showToast(withText: "Rename successful", icon: .success, shouldRemoveAfter: 3)
                }
            }
        } message: { (itemToRename: any MediaProtocol) in
            Text("Renaming: \(itemToRename.displayName)")
        }
        .confirmationDialog(
            "Are you sure you want to delete this item?",
            isPresented: $vm.showConfirmation,
            presenting: vm.itemToDelete
        ) { (m: (any MediaProtocol)) in
            Button("Yes Delete", systemImage: "trash.fill", role: .destructive) {
                let didDelete = self.vm.deleteMedia(m)
                if didDelete {
                    let msg = AttributedString("Deleted \(m.displayName) Successfully")
                    self.navigationModel.showToast(
                        withText: msg,
                        icon: .success,
                        shouldRemoveAfter: 1.5
                    )
                }
            }
        } message: { (m: any MediaProtocol) in
            Text(m.displayName)
        }
        .toolbar {
            ToolbarItem(placement: .principal, content: mediaTypeSwitcher)
            ToolbarItem(placement: .automatic) {
                if isEditing {
                    deleteSelectionButton()
                }
            }
            ToolbarItem(placement: .automatic, content: EditButton.init)
        }
        .task {
            vm.fetchAllMedia()
            await vm.generateThumbnails()
        }
    }
    
    var formatStyle: Date.FormatStyle {
        Date.FormatStyle()
        // DD MM YYYY
            .day()
            .month()
            .year()
        // HH MM SS
            .hour(.twoDigits(amPM: .abbreviated))
            .minute(.twoDigits)
            .second(.twoDigits)
    }
    
    var moviesList: some View {
        List(vm.groupedMovies.keys, selection: $vm.selectedMovies) { (date: Date) in
            let movies = vm.groupedMovies[date]!
            DisclosureGroup {
                combineButton(movies)
                
                ForEach(movies) { (m: MovieMedia) in
                    Button {
                        vm.selectedURL = m.mediaFile
                    } label: {
                        ThumnbnailView(uiImage: m.uiImage, name: m.displayName)
                    }
                    .contextMenu {
                        self.contextMenu(for: m)
                        Button("Trim", systemImage: "timeline.selection") {
                            self.vm.editVideo = m
                        }
                    }
                }
            } label: {
                Text(date, format: formatStyle)
            }
        }
    }
    
    var photosList: some View {
        List(vm.groupedPhotos.keys, selection: $vm.selectedPhotos) { (date: Date) in
            let photos = vm.groupedPhotos[date]!
            DisclosureGroup {
                ForEach(photos) { (p: PhotoMedia) in
                    Button {
                        vm.selectedURL = p.mediaFile
                    } label: {
                        ThumnbnailView(thumbnail: p.mediaImage, name: p.displayName)
                    }
                    .contextMenu {
                        self.contextMenu(for: p)
                    }
                }
            } label: {
                Text(date, format: formatStyle)
            }
        }
    }
    
    @ViewBuilder
    func contextMenu<Media: MediaProtocol>(for media: Media) -> some View {
        ControlGroup {
            ShareLink(item: media, preview: media.sharePreview) {
                Label("Share Item", systemImage: "square.and.arrow.up.fill")
            }
            .tint(.orange)
            
            Button("Delete Item", systemImage: "trash.fill", role: .destructive) {
                self.vm.itemToDelete = media
            }
        }
        RenameButton()
            .renameAction {
                vm.itemToRename = media
            }
    }
    
    @ViewBuilder
    func combineButton(_ movies: [MovieMedia]) -> some View {
        let hasPiP = movies.contains(where: { $0.displayName.localizedCaseInsensitiveContains("PiP") })
        
        let front = movies.first(where: { $0.displayName.localizedStandardContains("Front") })
        let back = movies.first(where: { $0.displayName.localizedStandardContains("Back") })
        
        if hasPiP {
            EmptyView()
        } else if let front, let back {
            Button("Make PiP", systemImage: "film.stack") {
                Task {
                    var outputURL = URL.newPiPMoviewDirectory(back.creationDate)
                    do {
                        try await PiPVideoMaker.makePiPVideo(
                            from: back.mediaFile,
                            and: front.mediaFile,
                            to: outputURL,
                            with: $vm.pipVideoProgress
                        )
                        var values = try outputURL.resourceValues(forKeys: [.creationDateKey])
                        values.creationDate = back.creationDate
                        try outputURL.setResourceValues(values)
                        var newMovie = MovieMedia(
                            displayName: outputURL.deletingPathExtension().lastPathComponent,
                            mediaFile: outputURL,
                            creationDate: back.creationDate
                        )
                        let (_, thumbnail) = try await AVFrameGrabber.grabFrame(for: newMovie)
                        newMovie.setThumbnail(thumbnail)
                        var currentMovies = vm.groupedMovies[back.creationDate.truncatedToSecond()] ?? []
                        currentMovies.append(newMovie)
                        vm.groupedMovies.updateValue(currentMovies, forKey: back.creationDate.truncatedToSecond())
                        
                    } catch (let err as PiPVideoMakerError) {
                        vm.error = .custom(message: err.description)
                    } catch (let error as CustomError) {
                        vm.error = error
                    } catch (let avE as AVFrameGrabberError) {
                        vm.error = .custom(message: avE.description)
                    } catch {
                        let errorDescription = (error as NSError).localizedDescription
                        vm.error = .custom(message: errorDescription)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func mediaTypeSwitcher() -> some View {
        if isEditing {
            EmptyView()
        } else {
            Picker("Media Type", selection: $vm.currentMediaType) {
                ForEach(MediaType.allCases) { (media: MediaType) in
                    Text(media.rawValue)
                        .tag(media)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    func editingControllerCompletion(_ result: TrimmingVideoView.Result, movieMedia: MovieMedia) {
        if self.vm.editVideo == nil { return }
        
        self.vm.editVideo = nil
        switch result {
        case .success(let url):
            Task {
                do {
                    let newName = movieMedia.displayName.appending(" trimmed \(Date().ISO8601Format(.iso8601WithTimeZone()))")
                    let newURL = URL
                        .documentsDirectory
                        .appending(components: newName)
                        .appendingPathExtension("mov")
                    
                    try FileManager.default.copyItem(at: url, to: newURL)
                    try FileManager.default.setAttributes([.creationDate: movieMedia.creationDate], ofItemAtPath: newURL.path(percentEncoded: false))
                    let newMovieMedia = MovieMedia(
                        displayName: newName,
                        mediaFile: newURL,
                        creationDate: movieMedia.creationDate
                    )
                    
                    var movies = vm.groupedMovies[movieMedia.creationDate.truncatedToSecond()] ?? []
                    movies.append(newMovieMedia)
                    vm.groupedMovies.updateValue(movies, forKey: movieMedia.creationDate.truncatedToSecond())
                    
                    let (id, uiImage) = try await AVFrameGrabber.grabFrame(for: newMovieMedia)
                    guard let indexToUpdate = vm.groupedMovies[movieMedia.creationDate.truncatedToSecond()]!.firstIndex(where: { $0.id == id }) else {
                        return
                    }
                    vm.groupedMovies[movieMedia.creationDate.truncatedToSecond()]![indexToUpdate].uiImage = uiImage
                } catch {
                    let nsError = error as NSError
                    vm.error = .custom(message: "Failed to trim movie: \(nsError.localizedDescription)")
                }
            }
        case .failure(let customError):
            vm.error = customError
        case .cancelled:
            vm.error = .custom(message: "Operation cancelled")
        }
    }
    
    @ViewBuilder
    var progressView: some View {
        switch vm.pipVideoProgress {
        case .inProgress(let p):
            ZStack(alignment: .center) {
                Color.black
                    .opacity(0.75)
                ProgressView(p)
                    .font(.headline)
            }
            .padding(.horizontal)
        default:
            EmptyView()
        }
    }
    
    func deleteSelectionButton() -> some View {
        Button("Delete Select", systemImage: "trash.fill", role: .destructive) {
            for movieID in vm.selectedMovies {
                guard let movie = vm.groupedMovies.values.flatMap(\.self).first(where: { $0.id == movieID }) else { continue }
                vm.deleteMedia(movie)
            }
            vm.selectedMovies.removeAll()
            
            for photoID in vm.selectedPhotos {
                guard let photo = vm.groupedPhotos.values.flatMap(\.self).first(where: { $0.id == photoID }) else { continue }
                vm.deleteMedia(photo)
            }
            vm.selectedPhotos.removeAll()
            
            self.editMode?.wrappedValue = .inactive
        }
    }
}

extension WatchRecordings {
    struct ThumnbnailView: View {
        let thumbnail: Image?
        let name: String
        
        init(thumbnail: Image?, name: String) {
            self.thumbnail = thumbnail
            self.name = name
        }
        
        init(uiImage: UIImage?, name: String) {
            self.name = name
            if let uiImage {
                self.thumbnail = Image(uiImage: uiImage)
            } else {
                self.thumbnail = nil
            }
        }
        
        var body: some View {
            HStack(alignment: .center) {
                if let thumbnail {
                    thumbnail
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                } else {
                    ZStack(alignment: .center) {
                        Image(systemName: "photo")
                            .font(.title)
                        ProgressView()
                    }
                }
                
                Text(name)
                    .font(.headline)
            }
        }
    }
}

extension WatchRecordings {
    enum MediaType: String, Identifiable, CaseIterable {
        case movies = "Movies"
        case photos = "Photos"
        
        var id: Self { self }
    }
    
    @MainActor
    final class ViewModel: ObservableObject {
        @Published var currentMediaType = MediaType.movies
        
        @Published var groupedMovies: OrderedDictionary<Date, [MovieMedia]> = [:]
        @Published var groupedPhotos: OrderedDictionary<Date, [PhotoMedia]> = [:]
        
        @Published var selectedMovies: Set<UUID> = []
        @Published var selectedPhotos: Set<UUID> = []
        
        @Published var selectedURL: URL?
        @Published var editVideo: MovieMedia?
        
        @Published var error: CustomError?
        
        @Published var itemToDelete: (any MediaProtocol)?
        @Published var itemToRename: (any MediaProtocol)?
        
        @Published var pipVideoProgress: PiPVideoMaker.ProgressStatus = .completed
        
        private let fm: FileManager = .default
        
        var urls: [URL] {
            currentMediaType == .movies
            ? groupedMovies.values.flatMap { $0.map(\.mediaFile) }
            : groupedPhotos.values.flatMap { $0.map(\.mediaFile) }
        }
        
        var showConfirmation: Bool {
            get { itemToDelete != nil }
            set { itemToDelete = nil }
        }
        
        var showRename: Bool {
            get { self.itemToRename != nil }
            set { self.itemToRename = nil }
        }
        
        var showError: Bool {
            get { error != nil }
            set { error = nil }
        }
        
        func fetchAllMedia() {
            do {
                let items = try fm.contentsOfDirectory(
                    at: URL.documentsDirectory,
                    includingPropertiesForKeys: [.creationDateKey],
                    options: [.skipsHiddenFiles]
                )
                
                let movies = items
                    .filter { $0.pathExtension.lowercased() == "mov" }
                    .map { (url: URL) -> MovieMedia in
                        let values: URLResourceValues? = try? url.resourceValues(forKeys: [.creationDateKey])
                        let creationDate: Date = values?.creationDate ?? .now
                        return MovieMedia(
                            displayName: url.deletingPathExtension().lastPathComponent,
                            mediaFile: url,
                            creationDate: creationDate
                        )
                    }
                self.groupedMovies = OrderedDictionary(grouping: movies) { (m: MovieMedia) in
                    m.creationDate.truncatedToSecond()
                }
                self.groupedMovies.sort(by: { $0.key > $1.key })
                
                let photos = items
                    .filter {
                        $0.pathExtension.lowercased() == "png" ||
                        $0.pathExtension.lowercased() == "jpg" ||
                        $0.pathExtension.lowercased() == "jpeg"
                    }
                    .map { (url: URL) -> PhotoMedia in
                        let values: URLResourceValues? = try? url.resourceValues(forKeys: [.creationDateKey])
                        let creationDate: Date = values?.creationDate ?? .now
                        return PhotoMedia(
                            displayName: url.deletingPathExtension().lastPathComponent,
                            mediaFile: url,
                            creationDate: creationDate
                        )
                    }
                
                self.groupedPhotos = OrderedDictionary(grouping: photos) { (p: PhotoMedia) in
                    p.creationDate.truncatedToSecond()
                }
                self.groupedPhotos.sort(by: { $0.key > $1.key })
            } catch {
                self.catchError(error, prefix: "Error fetching medias")
            }
        }
        
        func generateThumbnails() async {
            for (date, movies) in groupedMovies {
                for movie in movies {
                    guard let (id, thumbnail) = await AVFrameGrabber.grabFrameIgnoreError(for: movie) else {
                        continue
                    }
                    
                    guard let index = groupedMovies[date]?.firstIndex(where: { $0.id == id }) else {
                        continue
                    }
                    groupedMovies[date]?[index].setThumbnail(thumbnail)
                }
            }
        }
        
        @discardableResult
        func renameMedia<Media: MediaProtocol>(_ media: Media, to newName: String) -> Bool {
            do {
                guard self.fm.fileExists(atPath: media.mediaFile.path) else { throw CustomError.custom(message: "No such file") }
                let newUrl = URL.documentsDirectory
                    .appending(path: newName)
                    .appendingPathExtension(media is MovieMedia ? "mov" : "png")
                try self.fm.moveItem(at: media.mediaFile, to: newUrl)
                
                if let movie = media as? MovieMedia {
                    var movies: [MovieMedia] = groupedMovies[media.creationDate.truncatedToSecond()] ?? []
                    if let index = movies.firstIndex(where: { $0.displayName == media.displayName }) {
                        movies[index] = MovieMedia(
                            displayName: newName,
                            mediaFile: newUrl,
                            creationDate: media.creationDate,
                            uiImage: movie.uiImage
                        )
                    }
                    groupedMovies[media.creationDate.truncatedToSecond()] = movies
                    return true
                }
                if media is PhotoMedia {
                    var photos: [PhotoMedia] = groupedPhotos[media.creationDate.truncatedToSecond()] ?? []
                    if let index = photos.firstIndex(where: { $0.displayName == media.displayName }) {
                        photos[index] = PhotoMedia(displayName: newName, mediaFile: newUrl, creationDate: media.creationDate)
                    }
                    groupedPhotos[media.creationDate.truncatedToSecond()] = photos
                    return true
                }
                return false
            } catch {
                catchError(error)
                return false
            }
        }
        
        @discardableResult
        func deleteMedia<Media: MediaProtocol>(_ media: Media) -> Bool {
            do {
                guard self.fm.fileExists(atPath: media.mediaFile.path) else { return false }
                try self.fm.removeItem(at: media.mediaFile)
                if media is MovieMedia {
                    if var movies = groupedMovies[media.creationDate.truncatedToSecond()] {
                        movies.removeAll(where: { $0.id == media.id })
                        if movies.isEmpty {
                            groupedMovies.removeValue(forKey: media.creationDate.truncatedToSecond())
                        } else {
                            groupedMovies.updateValue(movies, forKey: media.creationDate.truncatedToSecond())
                        }
                    }
                }
                if media is PhotoMedia {
                    if var photos = self.groupedPhotos[media.creationDate.truncatedToSecond()] {
                        photos.removeAll(where: { $0.id == media.id })
                        if photos.isEmpty {
                            self.groupedPhotos.removeValue(forKey: media.creationDate.truncatedToSecond())
                        } else {
                            self.groupedPhotos.updateValue(photos, forKey: media.creationDate.truncatedToSecond())
                        }
                    }
                }
                return true
            } catch {
                self.catchError(error)
                return false
            }
        }
        
        private func catchError(_ error: Error, prefix: String = "") {
            var message = prefix
            if let locError = error as? LocalizedError {
                message += locError.errorDescription ?? locError.localizedDescription
            } else {
                let nsError = error as NSError
                message += nsError.localizedDescription
            }
            self.error = .custom(message: message)
        }
    }
}

#Preview {
    NavigationStack {
        WatchRecordings()
            .navigationTitle("Recordings")
            .environmentObject(NavigationModel())
    }
}
