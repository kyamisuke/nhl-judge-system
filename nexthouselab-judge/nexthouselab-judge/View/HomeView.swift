//
//  HomeView.swift
//  nexthouselab-judge
//
//  Created by 村上航輔 on 2024/05/06.
//

import SwiftUI

struct HomeView: View {
    @State var name: String = ""
    let demo = [
        EntryName(number: 0, name: "kyami"),
        EntryName(number: 1, name: "Kenshu"),
        EntryName(number: 2, name: "Amazon"),
        EntryName(number: 3, name: "Occhi"),
        EntryName(number: 4, name: "Tosai"),
        EntryName(number: 5, name: "Rinki")]
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("What's your name?")
                    .font(.title)
                HStack {
                    TextField(text: $name, label: {
                        Text("Judge Name")
                    })
                    NavigationLink("決定") {
                        MainView(judgeName: name, entryNames: demo)
                    }
                }
                .frame(width: 480)
            }
        }
    }
}

#Preview {
    HomeView()
}
