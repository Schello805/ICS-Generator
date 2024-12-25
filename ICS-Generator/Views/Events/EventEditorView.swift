import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
import os.log

struct EventEditorView: View {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ICS-Generator", category: "EventEditorView")
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: EventViewModel
    
    // Event State
    private let event: ICSEvent?
    private var bindingEvent: Binding<ICSEvent>?
    @State private var title: String = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var isAllDay = false
    @State private var location: String = ""
    @State private var notes: String = ""
    @State private var url: String = ""
    @State private var travelTime: Int = 0
    @State private var recurrence: ICSEvent.RecurrenceRule = .none
    @State private var customRecurrence: ICSEvent.CustomRecurrence? = nil
    @State private var attachments: [ICSEvent.Attachment] = []
    @State private var alert: ICSEvent.AlertTime = .none
    @State private var isValid = false
    
    // UI State
    @State private var showingImagePicker = false
    @State private var showingFilePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedItem: PhotosPickerItem? = nil
    
    init(event: ICSEvent? = nil) {
        self.event = event
        self.bindingEvent = nil
    }
    
    init(event: Binding<ICSEvent>) {
        self.event = nil
        self.bindingEvent = event
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Details Section
                Section(header: Text("Details")) {
                    TextField("Titel", text: $title)
                    
                    TextField("Ort", text: $location)
                    
                    TextField("URL", text: $url)
                    
                    Picker("Reisezeit", selection: $travelTime) {
                        Text("Keine").tag(0)
                        Text("5 Minuten").tag(5)
                        Text("10 Minuten").tag(10)
                        Text("15 Minuten").tag(15)
                        Text("30 Minuten").tag(30)
                        Text("1 Stunde").tag(60)
                    }
                }
                
                // Datum Section
                Section(header: Text("Datum")) {
                    DatePicker(
                        "Start",
                        selection: $startDate,
                        displayedComponents: isAllDay ? .date : [.date, .hourAndMinute]
                    )
                    
                    DatePicker(
                        "Ende",
                        selection: $endDate,
                        in: startDate...,
                        displayedComponents: isAllDay ? .date : [.date, .hourAndMinute]
                    )
                    
                    Toggle("Ganztägig", isOn: $isAllDay)
                }
                
                // Erinnerung Section
                Section(header: Text("Erinnerung")) {
                    Picker("Erinnerung", selection: $alert) {
                        ForEach(ICSEvent.AlertTime.allCases, id: \.self) { alert in
                            Text(alertTimeString(alert)).tag(alert)
                        }
                    }
                }
                
                // Wiederholung Section
                Section(header: Text("Wiederholung")) {
                    Picker("Wiederholung", selection: $recurrence) {
                        ForEach(ICSEvent.RecurrenceRule.allCases, id: \.self) { rule in
                            Text(recurrenceString(rule)).tag(rule)
                        }
                    }
                }
                
                // Notizen Section
                Section(header: Text("Notizen")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(event == nil && bindingEvent == nil ? String(localized: "Neuer Termin") : String(localized: "Termin bearbeiten"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        saveEvent()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .onAppear {
            if let event = event {
                title = event.title
                startDate = event.startDate
                endDate = event.endDate
                isAllDay = event.isAllDay
                location = event.location ?? ""
                notes = event.notes ?? ""
                url = event.url ?? ""
                travelTime = event.travelTime
                recurrence = event.recurrence
                customRecurrence = event.customRecurrence
                attachments = event.attachments
                alert = event.alert
            } else if let bindingEvent = bindingEvent {
                title = bindingEvent.wrappedValue.title
                startDate = bindingEvent.wrappedValue.startDate
                endDate = bindingEvent.wrappedValue.endDate
                isAllDay = bindingEvent.wrappedValue.isAllDay
                location = bindingEvent.wrappedValue.location ?? ""
                notes = bindingEvent.wrappedValue.notes ?? ""
                url = bindingEvent.wrappedValue.url ?? ""
                travelTime = bindingEvent.wrappedValue.travelTime
                recurrence = bindingEvent.wrappedValue.recurrence
                customRecurrence = bindingEvent.wrappedValue.customRecurrence
                attachments = bindingEvent.wrappedValue.attachments
                alert = bindingEvent.wrappedValue.alert
            }
            isValid = !title.isEmpty
        }
        .onChange(of: title) { _, newValue in
            isValid = !newValue.isEmpty
        }
        .onChange(of: startDate) { _, newDate in
            if endDate < newDate {
                endDate = newDate.addingTimeInterval(3600)
            }
        }
    }
    
    private func saveEvent() {
        logger.info("Saving event with title: \(title)")
        
        let newEvent = ICSEvent(
            id: event?.id ?? UUID(),
            title: title,
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            location: location.isEmpty ? nil : location,
            notes: notes.isEmpty ? nil : notes,
            url: url.isEmpty ? nil : url,
            travelTime: travelTime,
            alert: alert,
            recurrence: recurrence,
            customRecurrence: customRecurrence,
            attachments: attachments
        )
        
        if let existingEvent = event {
            logger.info("Updating existing event with id: \(existingEvent.id)")
            viewModel.updateEvent(newEvent)
        } else if let bindingEvent = bindingEvent {
            logger.info("Updating binding event")
            bindingEvent.wrappedValue = newEvent
            viewModel.updateEvent(newEvent)
        } else {
            logger.info("Adding new event")
            viewModel.addEvent(newEvent)
        }
        
        dismiss()
    }
    
    private func alertTimeString(_ alert: ICSEvent.AlertTime) -> String {
        switch alert {
        case .none:
            return "Keine"
        case .atTime:
            return "Zum Zeitpunkt"
        case .fiveMinutes:
            return "5 Minuten vorher"
        case .tenMinutes:
            return "10 Minuten vorher"
        case .fifteenMinutes:
            return "15 Minuten vorher"
        case .thirtyMinutes:
            return "30 Minuten vorher"
        case .oneHour:
            return "1 Stunde vorher"
        case .twoHours:
            return "2 Stunden vorher"
        case .oneDay:
            return "1 Tag vorher"
        case .twoDays:
            return "2 Tage vorher"
        case .oneWeek:
            return "1 Woche vorher"
        @unknown default:
            return "Unbekannt"
        }
    }
    
    private func recurrenceString(_ rule: ICSEvent.RecurrenceRule) -> String {
        switch rule {
        case .none:
            return "Keine"
        case .daily:
            return "Täglich"
        case .weekly:
            return "Wöchentlich"
        case .monthly:
            return "Monatlich"
        case .yearly:
            return "Jährlich"
        case .custom:
            return "Benutzerdefiniert"
        @unknown default:
            return "Unbekannt"
        }
    }
}
