import UIKit
import MapKit

protocol SearchSheetViewControllerDelegate: AnyObject {
    func searchSheetDidSelectLocation(placemark: MKPlacemark)
}

class SearchSheetViewController: UIViewController {
    weak var delegate: SearchSheetViewControllerDelegate?
    
    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchResults: [MKLocalSearchCompletion] = []
    private var recentSearches: [String] = []
    private var searchDebounceWorkItem: DispatchWorkItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // thin material color as background
        view.backgroundColor = .clear
        let effect = UIBlurEffect(style: .systemMaterial)
        let effectView = UIVisualEffectView(effect: effect)
        effectView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(effectView)
        
        NSLayoutConstraint.activate([
            effectView.topAnchor.constraint(equalTo: view.topAnchor),
            effectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            effectView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        setupSearchBar()
        setupTableView()
        
        searchCompleter.delegate = self
        var resultTypes: MKLocalSearchCompleter.ResultType = [.address, .pointOfInterest]
        if #available(iOS 18.0, *) {
            resultTypes.insert(.physicalFeature)
        }
        searchCompleter.resultTypes = resultTypes
        
        // Load recent searches
        recentSearches = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []
    }
    
    private func setupSearchBar() {
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = "Search for a destination"
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        
        view.addSubview(searchBar)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8)
        ])
    }
    
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "searchCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "recentCell")
        tableView.backgroundColor = .clear
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func saveRecentSearch(_ searchText: String) {
        if let index = recentSearches.firstIndex(of: searchText) {
            recentSearches.remove(at: index)
        }
        
        recentSearches.insert(searchText, at: 0)
        
        if recentSearches.count > 10 {
            recentSearches = Array(recentSearches.prefix(10))
        }
        
        UserDefaults.standard.set(recentSearches, forKey: "recentSearches")
    }
}

extension SearchSheetViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchDebounceWorkItem?.cancel()
        
        if searchText.isEmpty {
            searchResults = []
            tableView.reloadData()
            return
        }
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.searchCompleter.queryFragment = searchText
        }
        
        searchDebounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension SearchSheetViewController: UISheetPresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        false
    }
}

extension SearchSheetViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        tableView.reloadData()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error:")
        print(error)
        // show alert
        let alert = UIAlertController(
            title: "Error",
            message: "No routes found or \(error.localizedDescription)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension SearchSheetViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return searchBar.text?.isEmpty == false ? 1 : 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchBar.text?.isEmpty == false {
            return searchResults.count
        } else {
            return section == 0 ? 0 : recentSearches.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchBar.text?.isEmpty == false {
            return "Search Results"
        } else {
            return section == 0 ? nil : "Recent Searches"
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if searchBar.text?.isEmpty == false {
            let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath)
            cell.backgroundColor = .clear
            var content = UIListContentConfiguration.subtitleCell()
            
            let result = searchResults[indexPath.row]
            content.text = result.title
            content.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
            content.textProperties.color = .label
            
            content.secondaryText = result.subtitle
            content.secondaryTextProperties.font = .systemFont(ofSize: 14)
            content.secondaryTextProperties.color = .secondaryLabel

            content.image = UIImage(systemName: "mappin.circle.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
            
            cell.contentConfiguration = content
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "recentCell", for: indexPath)
            var content = UIListContentConfiguration.subtitleCell()
            
            content.text = recentSearches[indexPath.row]
            content.textProperties.font = .systemFont(ofSize: 16, weight: .medium)
            content.textProperties.color = .label

            content.secondaryTextProperties.font = .systemFont(ofSize: 14)
            content.secondaryTextProperties.color = .secondaryLabel

            content.image = UIImage(systemName: "clock")?.withTintColor(.systemGray, renderingMode: .alwaysOriginal)
            
            cell.contentConfiguration = content
            cell.backgroundColor = .clear
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if searchBar.text?.isEmpty == false {
            let selectedResult = searchResults[indexPath.row]
            
            // Save this search
            saveRecentSearch("\(selectedResult.title), \(selectedResult.subtitle)")
            
            // Perform the search and get the placemark
            let searchRequest = MKLocalSearch.Request(completion: selectedResult)
            let search = MKLocalSearch(request: searchRequest)
            
            search.start { [weak self] (response, error) in
                guard let self = self, let placemark = response?.mapItems.first?.placemark else {
                    return
                }
                
                self.searchBar.text = "\(selectedResult.title), \(selectedResult.subtitle)"
                self.searchBar.resignFirstResponder()
                self.sheetPresentationController?.selectedDetentIdentifier = .small
                self.delegate?.searchSheetDidSelectLocation(placemark: placemark)
            }
        } else {
            // Handle recent search selection
            let selectedSearch = recentSearches[indexPath.row]
            searchBar.text = selectedSearch
            searchBar.resignFirstResponder()

            searchDebounceWorkItem?.cancel()

            searchCompleter.queryFragment = selectedSearch

            // let activityIndicator = UIActivityIndicatorView(style: .medium)
            // activityIndicator.startAnimating()
            // tableView.tableFooterView = activityIndicator

            guard let index = selectedSearch.range(of: ",")?.lowerBound else {
                return
            }
            // This might be a full address, try to geocode it
            let titlePart = String(selectedSearch[..<index])
            let searchRequest = MKLocalSearch.Request()
            searchRequest.naturalLanguageQuery = titlePart
            
            let search = MKLocalSearch(request: searchRequest)
            search.start { [weak self] response, error in
                guard let self = self,
                      let response = response,
                      let firstItem = response.mapItems.first else {
                    // If geocode fails, fall back to completions
                    return
                }
                
                self.tableView.tableHeaderView = nil
                self.saveRecentSearch(selectedSearch)
                self.delegate?.searchSheetDidSelectLocation(placemark: firstItem.placemark)
                self.sheetPresentationController?.selectedDetentIdentifier = .small
            }
        }
    }
}

fileprivate class Preview: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mapView = MKMapView()
        mapView.frame = view.bounds
        view.addSubview(mapView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let searchSheetVC = SearchSheetViewController()
        searchSheetVC.modalPresentationStyle = .pageSheet
        
        if let sheet = searchSheetVC.sheetPresentationController {
            sheet.detents = [.small(), .medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 12
            sheet.delegate = searchSheetVC
            sheet.selectedDetentIdentifier = .small
        }
        
        present(searchSheetVC, animated: true, completion: nil)
    }
}

@available(iOS 17.0, *)
#Preview {
    Preview()
}
