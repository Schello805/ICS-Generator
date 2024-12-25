import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

struct EventEditorView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
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
    
    private let event: ICSEvent?
    
    init(event: ICSEvent? = nil) {
        self.event = event
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TitleSection(title: $title)
                
                LocationSection(
                    location: $location,
                    url: $url,
                    travelTime: $travelTime
                )
                
                DateTimeSection(startDate: $startDate, endDate: $endDate, isAllDay: $isAllDay)
                
                NotesSection(notes: $notes)
                
                AlertSection(alert: $alert)
                
                RecurrenceSection(
                    recurrence: $recurrence,
                    customRecurrence: $customRecurrence
                )
                
                AttachmentsSection(
                    attachments: $attachments,
                    showingImagePicker: $showingImagePicker,
                    showingFilePicker: $showingFilePicker,
                    selectedItem: $selectedItem
                )
            }
            .navigationTitle(event == nil ? String(localized: "Neuer Termin") : String(localized: "Termin bearbeiten"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Abbrechen")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Speichern")) {
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
            }
        }
        .onChange(of: title) { _, newValue in
            isValid = !newValue.isEmpty
        }
    }
    
    private func saveEvent() {
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
        
        if event != nil {
            viewModel.updateEvent(newEvent)
        } else {
            viewModel.addEvent(newEvent)
        }
        
        dismiss()
    }
}

struct TitleSection: View {
    @Binding var title: String
    
    var body: some View {
        Section {
            TextField(String(localized: "Titel"), text: $title)
                .textInputAutocapitalization(.words)
        }
    }
}

struct LocationSection: View {
    @Binding var location: String
    @Binding var url: String
    @Binding var travelTime: Int
    @State private var showingCustomTravelTime = false
    @State private var customTravelTime = ""
    @State private var selectedTravelTimeOption = -1 // -1 für benutzerdefiniert
    
    var body: some View {
        Section {
            TextField(String(localized: "Ort"), text: $location)
                .textInputAutocapitalization(.words)
            
            if !location.isEmpty {
                Picker(String(localized: "Reisezeit"), selection: $selectedTravelTimeOption) {
                    Text(String(localized: "Keine")).tag(0)
                    Text(String(localized: "5 Minuten")).tag(5)
                    Text(String(localized: "15 Minuten")).tag(15)
                    Text(String(localized: "30 Minuten")).tag(30)
                    Text(String(localized: "1 Stunde")).tag(60)
                    Text(String(localized: "2 Stunden")).tag(120)
                    Text(String(localized: "Benutzerdefiniert")).tag(-1)
                }
                .onChange(of: selectedTravelTimeOption) { _, newValue in
                    if newValue == -1 {
                        showingCustomTravelTime = true
                    } else {
                        travelTime = newValue
                        customTravelTime = ""
                    }
                }
                
                if showingCustomTravelTime {
                    HStack {
                        TextField(String(localized: "Minuten"), text: $customTravelTime)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: customTravelTime) { _, newValue in
                                if let minutes = Int(newValue), minutes >= 0 {
                                    travelTime = minutes
                                }
                            }
                        Text(String(localized: "Minuten"))
                    }
                }
            }
            
            TextField(String(localized: "URL"), text: $url)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
        }
    }
    
    init(location: Binding<String>, url: Binding<String>, travelTime: Binding<Int>) {
        self._location = location
        self._url = url
        self._travelTime = travelTime
        
        // Initialisiere selectedTravelTimeOption basierend auf travelTime
        let time = travelTime.wrappedValue
        if [0, 5, 15, 30, 60, 120].contains(time) {
            _selectedTravelTimeOption = State(initialValue: time)
        } else {
            _selectedTravelTimeOption = State(initialValue: -1)
            _showingCustomTravelTime = State(initialValue: true)
            _customTravelTime = State(initialValue: String(time))
        }
    }
}

struct NotesSection: View {
    @Binding var notes: String
    
    var body: some View {
        Section {
            TextField(String(localized: "Notizen"), text: $notes, axis: .vertical)
                .textInputAutocapitalization(.sentences)
                .lineLimit(5...10)
        }
    }
}

struct AlertSection: View {
    @Binding var alert: ICSEvent.AlertTime
    
    var body: some View {
        Section {
            Picker(String(localized: "Erinnerung"), selection: $alert) {
                Text(String(localized: "Keine")).tag(ICSEvent.AlertTime.none)
                Text(String(localized: "5 Minuten")).tag(ICSEvent.AlertTime.fiveMinutes)
                Text(String(localized: "15 Minuten")).tag(ICSEvent.AlertTime.fifteenMinutes)
                Text(String(localized: "30 Minuten")).tag(ICSEvent.AlertTime.thirtyMinutes)
                Text(String(localized: "1 Stunde")).tag(ICSEvent.AlertTime.oneHour)
                Text(String(localized: "2 Stunden")).tag(ICSEvent.AlertTime.twoHours)
                Text(String(localized: "1 Tag")).tag(ICSEvent.AlertTime.oneDay)
                Text(String(localized: "2 Tage")).tag(ICSEvent.AlertTime.twoDays)
                Text(String(localized: "1 Woche")).tag(ICSEvent.AlertTime.oneWeek)
            }
        }
    }
}

struct RecurrenceSection: View {
    @Binding var recurrence: ICSEvent.RecurrenceRule
    @Binding var customRecurrence: ICSEvent.CustomRecurrence?
    @State private var showingCustomOptions = false
    @State private var interval = 1
    @State private var endDate: Date? = nil
    
    var body: some View {
        Section {
            Picker(String(localized: "Wiederholung"), selection: $recurrence) {
                Text(String(localized: "Keine")).tag(ICSEvent.RecurrenceRule.none)
                Text(String(localized: "Täglich")).tag(ICSEvent.RecurrenceRule.daily)
                Text(String(localized: "Wöchentlich")).tag(ICSEvent.RecurrenceRule.weekly)
                Text(String(localized: "Monatlich")).tag(ICSEvent.RecurrenceRule.monthly)
                Text(String(localized: "Jährlich")).tag(ICSEvent.RecurrenceRule.yearly)
                Text(String(localized: "Benutzerdefiniert")).tag(ICSEvent.RecurrenceRule.custom)
            }
            
            if recurrence != .none {
                Stepper("\(String(localized: "Alle")) \(interval) \(intervalLabel)", value: $interval, in: 1...99)
                
                Picker(String(localized: "Endet"), selection: Binding<Bool>(
                    get: { endDate != nil },
                    set: { if !$0 { endDate = nil } }
                )) {
                    Text(String(localized: "Nie")).tag(false)
                    Text(String(localized: "Am")).tag(true)
                }
                
                if endDate != nil {
                    DatePicker("", selection: .init(
                        get: { endDate ?? Date() },
                        set: { endDate = $0 }
                    ), displayedComponents: [.date])
                }
            }
            
            if recurrence == .custom {
                NavigationLink(String(localized: "Benutzerdefinierte Wiederholung")) {
                    CustomRecurrenceView(recurrence: $recurrence, customRecurrence: $customRecurrence)
                }
            }
        }
    }
    
    private var intervalLabel: String {
        switch recurrence {
        case .daily: return interval == 1 ? String(localized: "Tag") : String(localized: "Tage")
        case .weekly: return interval == 1 ? String(localized: "Woche") : String(localized: "Wochen")
        case .monthly: return interval == 1 ? String(localized: "Monat") : String(localized: "Monate")
        case .yearly: return interval == 1 ? String(localized: "Jahr") : String(localized: "Jahre")
        default: return ""
        }
    }
}

struct AttachmentsSection: View {
    @Binding var attachments: [ICSEvent.Attachment]
    @Binding var showingImagePicker: Bool
    @Binding var showingFilePicker: Bool
    @Binding var selectedItem: PhotosPickerItem?
    
    var body: some View {
        Section {
            ForEach(attachments) { attachment in
                HStack {
                    Image(systemName: attachment.type.iconName)
                    Text(attachment.fileName)
                    Spacer()
                }
            }
            .onDelete { indexSet in
                attachments.remove(atOffsets: indexSet)
            }
            
            Menu {
                Button {
                    showingImagePicker = true
                } label: {
                    Label(String(localized: "Fotos"), systemImage: "photo")
                }
                
                Button {
                    showingFilePicker = true
                } label: {
                    Label(String(localized: "Dokumente"), systemImage: "doc")
                }
            } label: {
                HStack {
                    Text(String(localized: "Anhang hinzufügen"))
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .imageScale(.small)
                        .foregroundColor(.gray)
                }
            }
        }
        .photosPicker(
            isPresented: $showingImagePicker,
            selection: $selectedItem,
            matching: .images
        )
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            handleDocumentSelection(result)
        }
    }
    
    private func handleDocumentSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first,
                  let data = try? Data(contentsOf: url) else { return }
            let attachment = ICSEvent.Attachment(
                fileName: url.lastPathComponent,
                data: data,
                type: .pdf
            )
            attachments.append(attachment)
        case .failure(let error):
            print("Error importing file: \(error.localizedDescription)")
        }
    }
}

struct DateTimeSection: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isAllDay: Bool
    @State private var hasInitialized = false
    
    var body: some View {
        Section(header: Text(String(localized: "Datum & Zeit"))) {
            DatePicker(
                String(localized: "Start"),
                selection: $startDate,
                displayedComponents: isAllDay ? .date : [.date, .hourAndMinute]
            )
            .onChange(of: startDate) { _, newStartDate in
                Task { @MainActor in
                    // Ensure end date is not before start date
                    if endDate < newStartDate {
                        endDate = newStartDate
                    }
                    
                    // If all-day event, set times to midnight
                    if isAllDay {
                        let calendar = Calendar.current
                        startDate = calendar.startOfDay(for: newStartDate)
                        endDate = calendar.startOfDay(for: endDate)
                    }
                }
            }
            
            if !isAllDay {
                DatePicker(
                    String(localized: "Ende"),
                    selection: $endDate,
                    in: startDate...,
                    displayedComponents: [.date, .hourAndMinute]
                )
            }
            
            Toggle(String(localized: "Ganztägig"), isOn: $isAllDay)
                .onChange(of: isAllDay) { _, newValue in
                    Task { @MainActor in
                        let calendar = Calendar.current
                        if newValue {
                            // For all-day events, set times to midnight
                            startDate = calendar.startOfDay(for: startDate)
                            endDate = calendar.startOfDay(for: endDate)
                        } else {
                            // For non-all-day events, set end time to one hour after start
                            if calendar.isDate(startDate, inSameDayAs: endDate) {
                                endDate = calendar.date(byAdding: .hour, value: 1, to: startDate) ?? endDate
                            }
                        }
                    }
                }
        }
        .onAppear {
            if !hasInitialized {
                initializeDates()
                hasInitialized = true
            }
        }
    }
    
    init(startDate: Binding<Date>, endDate: Binding<Date>, isAllDay: Binding<Bool>) {
        self._startDate = startDate
        self._endDate = endDate
        self._isAllDay = isAllDay
    }
    
    private func initializeDates() {
        let calendar = Calendar.current
        if calendar.isDate(startDate, inSameDayAs: endDate) &&
           calendar.compare(startDate, to: endDate, toGranularity: .minute) == .orderedSame {
            endDate = calendar.date(byAdding: .hour, value: 1, to: startDate) ?? endDate
        }
    }
}

#Preview {
    NavigationView {
        EventEditorView(event: nil)
            .environmentObject(EventViewModel())
    }
}
