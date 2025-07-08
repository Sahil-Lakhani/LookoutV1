import MapKit
import SwiftUI
import UIKit

// MARK: - Error Definitions

enum MapLocationError: LocalizedError, CustomStringConvertible {
    case locationServicesDisabled
    case permissionDenied
    case custom(String)
    
    var errorDescription: String? { description }
    
    var description: String {
        switch self {
        case .locationServicesDisabled:
            return "Location Services Disabled"
        case .permissionDenied:
            return "Location Permission Denied"
        case .custom(let message):
            return message
        }
    }
}

// MARK: - SwiftUI Wrapper

struct MapView: View {
    let overlayMode: Binding<RecordingView.OverlayMode>
    
    var body: some View {
        MapViewControllerRepresentable(overlayMode: overlayMode)
            .ignoresSafeArea()
    }
}

fileprivate struct MapViewControllerRepresentable: UIViewControllerRepresentable {
    let overlayMode: Binding<RecordingView.OverlayMode>
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let mapVC = MapViewController(overlayMode: overlayMode)
        return UINavigationController(rootViewController: mapVC)
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // No updates needed for now.
    }
}

// MARK: - Main Map View Controller

fileprivate final class MapViewController: UIViewController {
    
    // MARK: Properties
    
    private let overlayMode: Binding<RecordingView.OverlayMode>
    private let mapView = MKMapView()
    private let locationManager = CLLocationManager()
    private let stackView = UIStackView()
    
    // Explicit reference to the map type button (the only remaining overlay control).
    private var mapTypeButton: UIButton?
    
    // MARK: Initialization
    
    init(overlayMode: Binding<RecordingView.OverlayMode>) {
        self.overlayMode = overlayMode
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable, message: "Use init(overlayMode:) instead")
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        setupMapView()
        setupLocationManager()
//        setupSearchBar()
        setupMapControls()
        setupCloseButton()
    }
    
    // MARK: Orientation Support
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    override var shouldAutorotate: Bool {
        return true
    }
    
    // MARK: Setup Methods
    
    private func setupMapView() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.delegate = self
        
        // Always show the user’s location and force follow mode.
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        // Set an initial region (this is just a default view; user location will update it).
        mapView.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20.5937, longitude: 78.9629),
            span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
        )
        
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.isZoomEnabled = true // Allow zooming if needed.
        
        // Note: The pan gesture recognizer has been removed so that the user can’t disable following.
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            // If location permission is restricted or denied, you might choose to present an alert.
            presentErrorAlert(.permissionDenied)
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        @unknown default:
            presentErrorAlert(.custom("Unknown location authorization status"))
        }
    }
    
    private func setupNavigationItems() {
        // Create only the map type button.
        let mapTypeBtn = createNavigationButton(
            image: UIImage(systemName: "map.fill"),
            action: #selector(changeMapType)
        )
        mapTypeBtn.accessibilityLabel = "Map Type"
        mapTypeBtn.accessibilityHint = "Double tap to change the map display style."
        self.mapTypeButton = mapTypeBtn
        
        // Add the map type button to the stack view.
        stackView.addArrangedSubview(mapTypeBtn)
        
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .trailing
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        // Ensure default settings on the map.
        mapView.setUserTrackingMode(.follow, animated: true)
        mapView.mapType = .standard
        updateMapTypeButton(to: .standard)
    }
    
//    private func setupCloseButton() {
//        let closeButton = UIBarButtonItem(
//            barButtonSystemItem: .close,
//            target: self,
//            action: #selector(closeView)
//        )
//        closeButton.accessibilityLabel = "Close"
//        navigationItem.leftBarButtonItem = closeButton
//    }
    
    // 1) Search bar just like Apple Maps
        private func setupSearchBar() {
            let searchResultsVC = SearchSheetViewController()
            searchResultsVC.delegate = self

            let search = UISearchController(searchResultsController: searchResultsVC)
//            search.searchResultsUpdater = searchResultsVC
            search.obscuresBackgroundDuringPresentation = false
            search.searchBar.placeholder = "Search for a place"
            navigationItem.searchController = search
            navigationItem.hidesSearchBarWhenScrolling = false
            navigationItem.title = "Maps"
            navigationController?.navigationBar.prefersLargeTitles = true
            navigationController?.navigationBar.sizeToFit()
        }

        // 2) Native MapKit buttons for recenter (user tracking) & compass
        private func setupMapControls() {
            // user-tracking button (blue “locate me” pill)
            let tracking = MKUserTrackingButton(mapView: mapView)
            tracking.backgroundColor = .systemBackground.withAlphaComponent(0.8)
            tracking.layer.cornerRadius = 8
            tracking.translatesAutoresizingMaskIntoConstraints = false

            // compass button
//            let compass = MKCompassButton(mapView: mapView)
//            compass.compassVisibility = .visible
//            compass.backgroundColor = .systemBackground.withAlphaComponent(0.8)
//            compass.layer.cornerRadius = 8
//            compass.translatesAutoresizingMaskIntoConstraints = false

//            view.addSubview(compass)
            view.addSubview(tracking)

            NSLayoutConstraint.activate([
                // bottom-right for the “locate me” button
                tracking.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                tracking.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -90),

                // just above it, the compass
//                compass.trailingAnchor.constraint(equalTo: tracking.trailingAnchor),
//                compass.bottomAnchor.constraint(equalTo: tracking.topAnchor, constant: -16),
            ])
        }
    
    private func setupCloseButton() {
        let close = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeView))
            navigationItem.leftBarButtonItem = close
    }
    
    // MARK: UI Helpers
    
    private func createNavigationButton(image: UIImage?, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.configuration = .plain()
        button.backgroundColor = .secondarySystemBackground
        button.tintColor = .systemBlue
        button.layer.cornerRadius = 10
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: action, for: .touchUpInside)
        button.setImage(image, for: .normal)
        return button
    }
    
    private func updateMapTypeButton(to mapType: MKMapType) {
        guard let mapTypeButton = self.mapTypeButton else { return }
        let symbolName: String
        switch mapType {
        case .standard:
            symbolName = "map"
        case .satellite:
            symbolName = "globe"
        case .hybrid, .hybridFlyover:
            symbolName = "map.fill"
        default:
            symbolName = "map"
        }
        mapTypeButton.setImage(UIImage(systemName: symbolName), for: .normal)
    }
    
    // MARK: Action Methods
    
    @objc private func closeView() {
        // Provide haptic feedback.
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        presentedViewController?.dismiss(animated: true)
        presentingViewController?.dismiss(animated: true)
        overlayMode.wrappedValue = .none
    }
    
    @objc private func changeMapType() {
        // Provide haptic feedback.
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        let actionSheet = UIAlertController(
            title: "Map Type",
            message: "Select a map style",
            preferredStyle: .actionSheet
        )
        
        actionSheet.addAction(UIAlertAction(title: "Explore", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.mapView.mapType = .standard
            self.updateMapTypeButton(to: .standard)
            self.dismiss(animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Satellite", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.mapView.mapType = .hybridFlyover
            self.updateMapTypeButton(to: .hybridFlyover)
            self.dismiss(animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
            guard let self = self else { return }
            self.updateMapTypeButton(to: self.mapView.mapType)
            self.dismiss(animated: true)
        }))
        
        if presentedViewController is SearchSheetViewController {
            dismiss(animated: true) {
                self.present(actionSheet, animated: true)
            }
        } else {
            present(actionSheet, animated: true)
        }
    }
    
    private func presentErrorAlert(_ error: MapLocationError) {
        let alert = UIAlertController(title: "Error",
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: Async Directions Request
    
    /// Fetches directions using async/await.
    private func fetchRoute(to destination: MKMapItem) async throws -> MKRoute {
        guard let userCoordinate = locationManager.location?.coordinate else {
            throw MapLocationError.custom("User location not available.")
        }
        
        let source = MKMapItem(placemark: MKPlacemark(coordinate: userCoordinate))
        let request = MKDirections.Request()
        request.source = source
        request.destination = destination
        request.transportType = .automobile
        
        return try await withCheckedThrowingContinuation { continuation in
            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let route = response?.routes.first {
                    continuation.resume(returning: route)
                } else {
                    continuation.resume(throwing: MapLocationError.custom("No routes found."))
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            break  // Waiting for permission.
        case .restricted, .denied:
            presentErrorAlert(.permissionDenied)
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        @unknown default:
            presentErrorAlert(.custom("Unknown location authorization status"))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let latestLocation = locations.last else { return }
//        // Always update the region to the latest user location.
//        let region = MKCoordinateRegion(
//            center: latestLocation.coordinate,
//            latitudinalMeters: 1000,
//            longitudinalMeters: 1000
//        )
//        mapView.setRegion(region, animated: true)
    }
}

// MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {
    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        guard fullyRendered, !(presentedViewController is SearchSheetViewController) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showSearchSheet()
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = .systemBlue
        renderer.lineWidth = 4
        return renderer
    }
}

// MARK: - SearchSheetViewControllerDelegate

extension MapViewController: SearchSheetViewControllerDelegate {
    func searchSheetDidSelectLocation(placemark: MKPlacemark) {
        // Add an annotation at the destination.
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        annotation.subtitle = placemark.title
        
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(annotation)
        
        // Zoom to show both the user and destination.
        guard let userCoordinate = locationManager.location?.coordinate else { return }
        let centerCoordinate = CLLocationCoordinate2D(
            latitude: (userCoordinate.latitude + placemark.coordinate.latitude) / 2,
            longitude: (userCoordinate.longitude + placemark.coordinate.longitude) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: abs(userCoordinate.latitude - placemark.coordinate.latitude) * 2.5,
            longitudeDelta: abs(userCoordinate.longitude - placemark.coordinate.longitude) * 2.5
        )
        let region = MKCoordinateRegion(center: centerCoordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        // Request and display directions asynchronously.
        let destinationItem = MKMapItem(placemark: placemark)
        Task {
            do {
                let route = try await fetchRoute(to: destinationItem)
                DispatchQueue.main.async {
                    self.mapView.removeOverlays(self.mapView.overlays)
                    self.mapView.addOverlay(route.polyline)
                    self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                    // Since the map must always follow, explicitly set follow mode.
                    self.mapView.setUserTrackingMode(.follow, animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    let errorMsg = error.localizedDescription
                    let alert = UIAlertController(title: "Error", message: errorMsg, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    private func showSearchSheet() {
        let searchVC = SearchSheetViewController()
        searchVC.delegate = self
        searchVC.modalPresentationStyle = .pageSheet
        if let sheet = searchVC.sheetPresentationController {
            sheet.detents = [.small(), .medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 12
            sheet.largestUndimmedDetentIdentifier = .small
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.delegate = searchVC
            sheet.selectedDetentIdentifier = .small
        }
        present(searchVC, animated: true)
    }
}


#Preview {
    NavigationStack {
        MapView(overlayMode: .constant(.none))
            .preferredColorScheme(.dark)
    }
}