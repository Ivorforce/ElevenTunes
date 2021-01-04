//
//  NavigationBarView.swift
//  ElevenTunes
//
//  Created by Lukas Tenbrink on 02.01.21.
//

import SwiftUI

struct NavigationBarView: View {
    var addFolderViews: some View {
        HStack {
            Button {
                // TODO Add playlist
            } label: {
                Image(systemName: "music.note.list")
            }
            .disabled(true)

            Button {
                // TODO Add folder
            } label: {
                Image(systemName: "folder")
            }
            .disabled(true)

            Button {
                // TODO Add hybrid folder
            } label: {
                Image(systemName: "questionmark.folder")
            }
            .disabled(true)
        }
    }
    
    var body: some View {
        HStack {
            Button {
                // TODO Change view
            } label: {
                Image(systemName: "sidebar.left")
            }
            .disabled(true)
            .padding(.leading, 8)
            
            Spacer()
                .frame(width: 20)
                    
            Button {
                // TODO Library View
            } label: {
                Image(systemName: "house")
            }
            .disabled(true)

            Spacer()
                .frame(width: 20)

            Button {
                // TODO Navigator: Back
            } label: {
                Image(systemName: "chevron.backward")
            }
            .disabled(true)

            Spacer()
                .frame(width: 15)

            Button {
                // TODO Navigator: Forward
            } label: {
                Image(systemName: "chevron.forward")
            }
            .disabled(true)

            Spacer()
            
            addFolderViews
                .padding(.trailing, 8)
        }
            .buttonStyle(BorderlessButtonStyle())
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .visualEffectBackground(material: .sidebar)
    }
}

struct NavigationBarView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationBarView()
    }
}
