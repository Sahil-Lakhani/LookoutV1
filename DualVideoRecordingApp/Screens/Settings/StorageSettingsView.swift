//
//  StorageSettingsView.swift
//  DualVideoRecordingApp
//
//  Created by Sharan Thakur on 15/01/25.
//

import OSLog
import StorageSenseKit
import SwiftUI

fileprivate let logger = Logger(subsystem: "com.kidastudios.DualVideoRecordingApp", category: "StorageSettingsView")

struct StorageSettingsView: View {
    @State private var storageStatus: StorageStatus?
    
    var body: some View {
        List {
            LabelledListItemCard(title: "Storage Status") {
                if let storageStatus = storageStatus {
                    ProgressView(value: storageStatus.usedFraction) {
                        Text("Space Available")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)
                    }
                    .progressViewStyle(.linear)

                    Text("\(storageStatus.description)")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                        .frame(height: 75)
                    
                    ProgressView(storageStatus.description, value: storageStatus.usedFraction)
                        .labelsHidden()
                        .progressViewStyle(.linear)
                    
                    Text("\(storageStatus.formattedFreeSpace) Available")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.primary)
                        .padding(.top, 10)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Text("Loading...")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.white)
        }
        .navigationTitle("Storage")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.sidebar)
        .listRowSpacing(15)
        .listSectionSeparator(.hidden, edges: .all)
        .onAppear {
            do {
                storageStatus = try .create()
                logger.info("Storage status: \(storageStatus!.description)")
            } catch {
                logger.error("Failed to get storage status: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    NavigationStack {
        StorageSettingsView()
            .preferredColorScheme(.dark)
    }
}
