//
//  MainView.swift
//  Network
//
//  Created by Salah Khaled on 28/02/2026.
//

import SwiftUI

struct MainView: View {
    
    @StateObject private var viewModel = LoginViewModel()
    
    var body: some View {
        NavigationView {
            content
                .navigationTitle(String(localized: "users"))
                .task {
                    viewModel.fetchUsers()
                }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        
        if viewModel.isLoading && viewModel.breeds.isEmpty {
            ProgressView(String(localized: "loading"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        
        else if let error = viewModel.error, viewModel.breeds.isEmpty {
            VStack(spacing: 12) {
                
                Text(error.localize())
                    .foregroundColor(.red)
                
                Button(String(localized: "retry")) {
                    Task {
                        viewModel.fetchUsers()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        
        else {
            List(viewModel.breeds) { breed in
                VStack(alignment: .leading) {
                    if let title = breed.attributes.name {
                        Text(title)
                            .font(.headline)
                    }
//                    if let description = breed.attributes.descriptionss {
                        Text(breed.attributes.descriptionss)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(3)
//                    }
                }
            }
            .refreshable {
                viewModel.fetchUsers()
            }
        }
    }
}

#Preview {
    MainView()
}
