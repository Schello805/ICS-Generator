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
            .navigationTitle(event == nil ? NSLocalizedString("Neuer Termin", comment: "New event title") : NSLocalizedString("Termin bearbeiten", comment: "Edit event title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("Abbrechen", comment: "Cancel button")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("Speichern", comment: "Save button")) {
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
            TextField(NSLocalizedString("Titel", comment: "Event title field"), text: $title)
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
            TextField(NSLocalizedString("Ort", comment: "Event location field"), text: $location)
                .textInputAutocapitalization(.words)
            
            if !location.isEmpty {
                Picker(NSLocalizedString("Reisezeit", comment: "Travel time picker"), selection: $selectedTravelTimeOption) {
                    Text(NSLocalizedString("Keine", comment: "No travel time")).tag(0)
                    Text(NSLocalizedString("5 Minuten", comment: "5 minutes travel time")).tag(5)
                    Text(NSLocalizedString("15 Minuten", comment: "15 minutes travel time")).tag(15)
                    Text(NSLocalizedString("30 Minuten", comment: "30 minutes travel time")).tag(30)
                    Text(NSLocalizedString("1 Stunde", comment: "1 hour travel time")).tag(60)
                    Text(NSLocalizedString("2 Stunden", comment: "2 hours travel time")).tag(120)
                    Text(NSLocalizedString("Benutzerdefiniert", comment: "Custom travel time")).tag(-1)
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
                        TextField(NSLocalizedString("Minuten", comment: "Custom travel time in minutes"), text: $customTravelTime)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: customTravelTime) { _, newValue in
                                if let minutes = Int(newValue), minutes >= 0 {
                                    travelTime = minutes
                                }
                            }
                        Text(NSLocalizedString("Minuten", comment: "Minutes"))
                    }
                }
            }
            
            TextField(NSLocalizedString("URL", comment: "Event URL field"), text: $url)
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
            TextField(NSLocalizedString("Notizen", comment: "Event notes field"), text: $notes, axis: .vertical)
                .textInputAutocapitalization(.sentences)
                .lineLimit(5...10)
        }
    }
}

struct AlertSection: View {
    @Binding var alert: ICSEvent.AlertTime
    
    var body: some View {
        Section {
            Picker(NSLocalizedString("Erinnerung", comment: "Alert time picker"), selection: $alert) {
                Text(NSLocalizedString("Keine", comment: "No alert")).tag(ICSEvent.AlertTime.none)
                Text(NSLocalizedString("5 Minuten", comment: "5 minutes alert")).tag(ICSEvent.AlertTime.fiveMinutes)
                Text(NSLocalizedString("15 Minuten", comment: "15 minutes alert")).tag(ICSEvent.AlertTime.fifteenMinutes)
                Text(NSLocalizedString("30 Minuten", comment: "30 minutes alert")).tag(ICSEvent.AlertTime.thirtyMinutes)
                Text(NSLocalizedString("1 Stunde", comment: "1 hour alert")).tag(ICSEvent.AlertTime.oneHour)
                Text(NSLocalizedString("2 Stunden", comment: "2 hours alert")).tag(ICSEvent.AlertTime.twoHours)
                Text(NSLocalizedString("1 Tag", comment: "1 day alert")).tag(ICSEvent.AlertTime.oneDay)
                Text(NSLocalizedString("2 Tage", comment: "2 days alert")).tag(ICSEvent.AlertTime.twoDays)
                Text(NSLocalizedString("1 Woche", comment: "1 week alert")).tag(ICSEvent.AlertTime.oneWeek)
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
            Picker(NSLocalizedString("Wiederholung", comment: "Recurrence rule picker"), selection: $recurrence) {
                Text(NSLocalizedString("Keine", comment: "No recurrence")).tag(ICSEvent.RecurrenceRule.none)
                Text(NSLocalizedString("Täglich", comment: "Daily recurrence")).tag(ICSEvent.RecurrenceRule.daily)
                Text(NSLocalizedString("Wöchentlich", comment: "Weekly recurrence")).tag(ICSEvent.RecurrenceRule.weekly)
                Text(NSLocalizedString("Monatlich", comment: "Monthly recurrence")).tag(ICSEvent.RecurrenceRule.monthly)
                Text(NSLocalizedString("Jährlich", comment: "Yearly recurrence")).tag(ICSEvent.RecurrenceRule.yearly)
                Text(NSLocalizedString("Benutzerdefiniert", comment: "Custom recurrence")).tag(ICSEvent.RecurrenceRule.custom)
            }
            
            if recurrence != .none {
                Stepper(NSLocalizedString("Alle \(interval) \(intervalLabel)", comment: "Recurrence interval stepper"), value: $interval, in: 1...99)
                
                Picker(NSLocalizedString("Endet", comment: "Recurrence end picker"), selection: .init(
                    get: { endDate == nil ? false : true },
                    set: { if !$0 { endDate = nil } }
                )) {
                    Text(NSLocalizedString("Nie", comment: "No end date")).tag(false)
                    Text(NSLocalizedString("Am", comment: "End date")).tag(true)
                }
                
                if endDate != nil {
                    DatePicker(NSLocalizedString("", comment: ""), selection: .init(
                        get: { endDate ?? Date() },
                        set: { endDate = $0 }
                    ), displayedComponents: [.date])
                }
            }
            
            if recurrence == .custom {
                NavigationLink(NSLocalizedString("Benutzerdefinierte Wiederholung", comment: "Custom recurrence link")) {
                    CustomRecurrenceView(recurrence: $recurrence, customRecurrence: $customRecurrence)
                }
            }
        }
    }
    
    private var intervalLabel: String {
        switch recurrence {
        case .daily: return interval == 1 ? NSLocalizedString("Tag", comment: "Day") : NSLocalizedString("Tage", comment: "Days")
        case .weekly: return interval == 1 ? NSLocalizedString("Woche", comment: "Week") : NSLocalizedString("Wochen", comment: "Weeks")
        case .monthly: return interval == 1 ? NSLocalizedString("Monat", comment: "Month") : NSLocalizedString("Monate", comment: "Months")
        case .yearly: return interval == 1 ? NSLocalizedString("Jahr", comment: "Year") : NSLocalizedString("Jahre", comment: "Years")
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
                    Label(NSLocalizedString("Fotos", comment: "Photos"), systemImage: "photo")
                }
                
                Button {
                    showingFilePicker = true
                } label: {
                    Label(NSLocalizedString("Dokumente", comment: "Documents"), systemImage: "doc")
                }
            } label: {
                HStack {
                    Text(NSLocalizedString("Anhang hinzufügen", comment: "Add attachment"))
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
        Section(header: Text(NSLocalizedString("Datum & Zeit", comment: "Date & Time section"))) {
            DatePicker(
                NSLocalizedString("Start", comment: "Start date"),
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
                    NSLocalizedString("Ende", comment: "End date"),
                    selection: $endDate,
                    in: startDate...,
                    displayedComponents: [.date, .hourAndMinute]
                )
            }
            
            Toggle(NSLocalizedString("Ganztägig", comment: "All day toggle"), isOn: $isAllDay)
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
