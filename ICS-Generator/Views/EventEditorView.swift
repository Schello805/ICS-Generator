import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

struct EventEditorView: View {
    @EnvironmentObject private var viewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss
    
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
    
    // UI State
    @State private var alert: ICSEvent.AlertTime = .fifteenMinutes
    @State private var showingImagePicker = false
    @State private var showingFilePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingStartDatePicker = false
    @State private var showingEndDatePicker = false
    @State private var selectedItem: PhotosPickerItem? = nil
    
    private let event: ICSEvent?
    
    init(event: ICSEvent? = nil) {
        self.event = event
        
        if let event = event {
            _title = State(initialValue: event.title)
            _startDate = State(initialValue: event.startDate)
            _endDate = State(initialValue: event.endDate)
            _isAllDay = State(initialValue: event.isAllDay)
            _location = State(initialValue: event.location ?? "")
            _notes = State(initialValue: event.notes ?? "")
            _url = State(initialValue: event.url ?? "")
            _travelTime = State(initialValue: event.travelTime)
            _recurrence = State(initialValue: event.recurrence)
            _customRecurrence = State(initialValue: event.customRecurrence)
            _attachments = State(initialValue: event.attachments)
            _alert = State(initialValue: event.alert)
        }
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
                
                DateSection(
                    startDate: $startDate,
                    endDate: $endDate,
                    isAllDay: $isAllDay,
                    showingStartDatePicker: $showingStartDatePicker,
                    showingEndDatePicker: $showingEndDatePicker
                )
                
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
            .navigationTitle(event == nil ? "Neuer Termin" : "Termin bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        saveEvent()
                    }
                    .disabled(title.isEmpty)
                }
            }
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
            TextField("Titel", text: $title)
                .textInputAutocapitalization(.words)
        }
    }
}

struct DateSection: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isAllDay: Bool
    @Binding var showingStartDatePicker: Bool
    @Binding var showingEndDatePicker: Bool
    
    var body: some View {
        Section {
            Toggle("Ganztägig", isOn: $isAllDay)
            
            DateTimeSection(
                startDate: $startDate,
                endDate: $endDate,
                isAllDay: $isAllDay,
                showingStartDatePicker: $showingStartDatePicker,
                showingEndDatePicker: $showingEndDatePicker
            )
        }
    }
}

struct LocationSection: View {
    @Binding var location: String
    @Binding var url: String
    @Binding var travelTime: Int
    
    var body: some View {
        Section {
            TextField("Ort", text: $location)
                .textInputAutocapitalization(.words)
            
            if !location.isEmpty {
                Picker("Reisezeit", selection: $travelTime) {
                    Text("Keine").tag(0)
                    Text("5 Minuten").tag(5)
                    Text("15 Minuten").tag(15)
                    Text("30 Minuten").tag(30)
                    Text("1 Stunde").tag(60)
                    Text("2 Stunden").tag(120)
                }
            }
            
            TextField("URL", text: $url)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
        }
    }
}

struct NotesSection: View {
    @Binding var notes: String
    
    var body: some View {
        Section {
            TextField("Notizen", text: $notes, axis: .vertical)
                .textInputAutocapitalization(.sentences)
                .lineLimit(5...10)
        }
    }
}

struct AlertSection: View {
    @Binding var alert: ICSEvent.AlertTime
    
    var body: some View {
        Section {
            Picker("Erinnerung", selection: $alert) {
                Text("Keine").tag(ICSEvent.AlertTime.none)
                Text("5 Minuten").tag(ICSEvent.AlertTime.fiveMinutes)
                Text("15 Minuten").tag(ICSEvent.AlertTime.fifteenMinutes)
                Text("30 Minuten").tag(ICSEvent.AlertTime.thirtyMinutes)
                Text("1 Stunde").tag(ICSEvent.AlertTime.oneHour)
                Text("2 Stunden").tag(ICSEvent.AlertTime.twoHours)
                Text("1 Tag").tag(ICSEvent.AlertTime.oneDay)
                Text("2 Tage").tag(ICSEvent.AlertTime.twoDays)
                Text("1 Woche").tag(ICSEvent.AlertTime.oneWeek)
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
            Picker("Wiederholung", selection: $recurrence) {
                Text("Keine").tag(ICSEvent.RecurrenceRule.none)
                Text("Täglich").tag(ICSEvent.RecurrenceRule.daily)
                Text("Wöchentlich").tag(ICSEvent.RecurrenceRule.weekly)
                Text("Monatlich").tag(ICSEvent.RecurrenceRule.monthly)
                Text("Jährlich").tag(ICSEvent.RecurrenceRule.yearly)
                Text("Benutzerdefiniert").tag(ICSEvent.RecurrenceRule.custom)
            }
            
            if recurrence != .none {
                Stepper("Alle \(interval) \(intervalLabel)", value: $interval, in: 1...99)
                
                Picker("Endet", selection: .init(
                    get: { endDate == nil ? false : true },
                    set: { if !$0 { endDate = nil } }
                )) {
                    Text("Nie").tag(false)
                    Text("Am").tag(true)
                }
                
                if endDate != nil {
                    DatePicker("", selection: .init(
                        get: { endDate ?? Date() },
                        set: { endDate = $0 }
                    ), displayedComponents: [.date])
                }
            }
            
            if recurrence == .custom {
                NavigationLink("Benutzerdefinierte Wiederholung") {
                    CustomRecurrenceView(recurrence: $recurrence, customRecurrence: $customRecurrence)
                }
            }
        }
    }
    
    private var intervalLabel: String {
        switch recurrence {
        case .daily: return interval == 1 ? "Tag" : "Tage"
        case .weekly: return interval == 1 ? "Woche" : "Wochen"
        case .monthly: return interval == 1 ? "Monat" : "Monate"
        case .yearly: return interval == 1 ? "Jahr" : "Jahre"
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
                    Label("Fotos", systemImage: "photo")
                }
                
                Button {
                    showingFilePicker = true
                } label: {
                    Label("Dokumente", systemImage: "doc")
                }
            } label: {
                HStack {
                    Text("Anhang hinzufügen")
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
    @Binding var showingStartDatePicker: Bool
    @Binding var showingEndDatePicker: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Beginn")
                Spacer()
                Text(formatDate(startDate))
                    .foregroundColor(.blue)
                    .onTapGesture {
                        withAnimation {
                            showingStartDatePicker.toggle()
                            if showingStartDatePicker {
                                showingEndDatePicker = false
                            }
                        }
                    }
            }
            
            if showingStartDatePicker {
                DatePicker(
                    "",
                    selection: $startDate,
                    displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .onChange(of: startDate) { _, newDate in
                    handleStartDateChange(newDate)
                }
            }
            
            HStack {
                Text("Ende")
                Spacer()
                Text(formatDate(endDate))
                    .foregroundColor(.blue)
                    .onTapGesture {
                        withAnimation {
                            showingEndDatePicker.toggle()
                            if showingEndDatePicker {
                                showingStartDatePicker = false
                            }
                        }
                    }
            }
            
            if showingEndDatePicker {
                DatePicker(
                    "",
                    selection: $endDate,
                    in: startDate...,
                    displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .onChange(of: endDate) { _, newDate in
                    handleEndDateChange(newDate)
                }
            }
        }
    }
    
    private func handleStartDateChange(_ newDate: Date) {
        let calendar = Calendar.current
        if isAllDay {
            startDate = calendar.startOfDay(for: newDate)
            // Ensure end date is on the same day but at the end of the day
            endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: newDate) ?? newDate
        } else {
            // If end date is now before start date, adjust it
            if endDate < newDate {
                endDate = calendar.date(byAdding: .hour, value: 1, to: newDate) ?? newDate
            }
        }
    }
    
    private func handleEndDateChange(_ newDate: Date) {
        if isAllDay {
            let calendar = Calendar.current
            endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: newDate) ?? newDate
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        
        if isAllDay {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}

#Preview {
    EventEditorView()
        .environmentObject(EventViewModel())
}
