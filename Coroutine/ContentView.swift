//
//  ContentView.swift
//  Coroutine
//
//  Created by ACI on 06/07/22.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var viewModel: ViewModel = .init()
    
    var body: some View {
        Text("Hello, world!")
            .padding()
            .onAppear {
                Task {
                    await viewModel.test()
                }
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class ViewModel: ObservableObject {
    
    @MainActor
    func test() async {
        let response = await ARepository.shared.test()
    }
    
}
