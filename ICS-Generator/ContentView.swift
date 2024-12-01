//
//  ContentView.swift
//  ICS-Generator
//
//  Created by Michael Schellenberger on 01.12.24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = EventViewModel()
    @State private var showingEventEditor = false
    @State private var showingSettings = false
    @State private var showingExportOptions = false
    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.events.isEmpty {
                    Section {
                        EmptyStateView(showingEventEditor: $showingEventEditor)
                    }
                } else {
                    ForEach(viewModel.events) { event in
                        EventRow(
                            event: event,
                            onDelete: { viewModel.deleteEvent(event) },
                            onExport: { viewModel.exportEvent(event) }
                        )
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Termine")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 16) {
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gear")
                                .font(.system(size: 20))
                        }
                        
                        if !viewModel.events.isEmpty {
                            Button {
                                showingExportOptions = true
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 20))
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingEventEditor = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20))
                    }
                }
            }
            .sheet(isPresented: $showingEventEditor) {
                EventEditorView(event: nil, viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: viewModel)
            }
            .actionSheet(isPresented: $showingExportOptions) {
                ActionSheet(
                    title: Text("Termine exportieren"),
                    message: Text("Wählen Sie eine Option"),
                    buttons: [
                        .default(Text("Alle Termine exportieren")) {
                            if let fileURL = viewModel.generateICS(for: viewModel.events) {
                                let activityVC = UIActivityViewController(
                                    activityItems: [fileURL],
                                    applicationActivities: nil
                                )
                                
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let window = windowScene.windows.first,
                                   let rootViewController = window.rootViewController {
                                    
                                    if let popoverController = activityVC.popoverPresentationController {
                                        popoverController.sourceView = window
                                        popoverController.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                                        popoverController.permittedArrowDirections = []
                                    }
                                    
                                    rootViewController.present(activityVC, animated: true)
                                }
                            }
                        },
                        .cancel()
                    ]
                )
            }
        }
    }
}

struct EmptyStateView: View {
    @Binding var showingEventEditor: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            // App Icon und Titel
            VStack(spacing: 16) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                    .symbolEffect(.bounce, options: .repeating)
                
                Text("Willkommen bei ICS Generator")
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            // Hauptfunktionen
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(icon: "calendar.badge.plus", title: "Termine erstellen", description: "Erstellen Sie Termine mit Wiederholungen und Erinnerungen")
                FeatureRow(icon: "arrow.up.doc.fill", title: "ICS Export", description: "Exportieren Sie Ihre Termine im ICS-Format")
                FeatureRow(icon: "repeat", title: "Wiederholungen", description: "Erstellen Sie wiederkehrende Termine nach Ihren Wünschen")
            }
            .padding(.horizontal)
            
            // Aktions-Button
            Button(action: {
                showingEventEditor = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("Ersten Termin erstellen")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(15)
                .shadow(radius: 5)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct EventRow: View {
    let event: ICSEvent
    let onDelete: () -> Void
    let onExport: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title)
                .font(.headline)
            
            Text(event.formattedDate)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let location = event.location, !location.isEmpty {
                Text(location)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button(action: onExport) {
                Label("Exportieren", systemImage: "square.and.arrow.up")
            }
            Button(role: .destructive, action: onDelete) {
                Label("Löschen", systemImage: "trash")
            }
        }
        .swipeActions(allowsFullSwipe: false) {
            Button(action: onExport) {
                Label("Exportieren", systemImage: "square.and.arrow.up")
            }
            .tint(.blue)
            
            Button(role: .destructive, action: onDelete) {
                Label("Löschen", systemImage: "trash")
            }
        }
    }
}

#Preview {
    ContentView()
}
