//
//  MainView.swift
//  Network
//
//  Created by Salah Khaled on 28/02/2026.
//

import SwiftUI

struct MainView: View {
    
    @StateObject private var viewModel: LoginViewModel
    
    init(network: Network) {
        _viewModel = StateObject(
            wrappedValue: LoginViewModel(network: network)
        )
    }
    
    var body: some View {
        NavigationView {
            content
                .navigationTitle("Users")
                .task {
                    await viewModel.fetchUsers()
                }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        
        if viewModel.isLoading {
            ProgressView("Loading...")
        }
        
        else if let error = viewModel.errorMessage {
            VStack(spacing: 12) {
                Text(error)
                    .foregroundColor(.red)
                
                Button("Retry") {
                    Task {
                        await viewModel.fetchUsers()
                    }
                }
            }
        }
        
        else {
            List(viewModel.breeds) { breed in
                VStack(alignment: .leading) {
                    Text(breed.attributes.name ?? "-")
                        .font(.headline)
                    
                    Text(breed.attributes.description ?? "-")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

#Preview {
    MainView(network: Network())
}
