import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
import VisionKit

struct DateTimeSection: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isAllDay: Bool
    @Binding var showingStartDatePicker: Bool
    @Binding var showingEndDatePicker: Bool
    
    var body: some View {
        HStack {
            Text("Beginn")
            Spacer()
            Text(formatDate(startDate))
                .foregroundColor(.blue)
                .onTapGesture {
                    showingStartDatePicker.toggle()
                }
        }
        if showingStartDatePicker {
            DatePicker("", 
                     selection: $startDate,
                     displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                .datePickerStyle(.graphical)
                .onChange(of: startDate) { _, newDate in
                    if isAllDay {
                        let calendar = Calendar.current
                        startDate = calendar.startOfDay(for: newDate)
                        endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: newDate) ?? newDate
                    }
                    DispatchQueue.main.async {
                        showingStartDatePicker = false
                    }
                }
        }
        
        HStack {
            Text("Ende")
            Spacer()
            Text(formatDate(endDate))
                .foregroundColor(.blue)
                .onTapGesture {
                    showingEndDatePicker.toggle()
                }
        }
        if showingEndDatePicker {
            DatePicker("", 
                     selection: $endDate,
                     in: startDate...,
                     displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                .datePickerStyle(.graphical)
                .onChange(of: endDate) { _, newDate in
                    if isAllDay {
                        let calendar = Calendar.current
                        endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: newDate) ?? newDate
                    }
                    DispatchQueue.main.async {
                        showingEndDatePicker = false
                    }
                }
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

struct EventEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: EventViewModel
    
    let event: ICSEvent?
    @State private var title = ""
    @State private var location = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var isAllDay = false
    @State private var notes = ""
    @State private var attachments: [ICSEvent.Attachment] = []
    @AppStorage("defaultAlert") private var defaultAlert: String = ICSEvent.AlertTime.fifteenMinutes.rawValue
    
    @State private var showingStartDatePicker = false
    @State private var showingEndDatePicker = false
    @State private var showingRecurrencePicker = false
    @State private var showingCustomRecurrence = false
    @State private var showingAlert = false
    @State private var showingDocumentPicker = false
    @State private var showingCamera = false
    @State private var showingScanner = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var scannedImages: [UIImage] = []
    
    @State private var alert: ICSEvent.AlertTime = .fifteenMinutes
    @State private var recurrence: ICSEvent.RecurrenceRule = .none
    @State private var customRecurrence: ICSEvent.CustomRecurrence?
    
    init(event: ICSEvent?, viewModel: EventViewModel) {
        self.event = event
        self.viewModel = viewModel
        
        if let event = event {
            _title = State(initialValue: event.title)
            _location = State(initialValue: event.location ?? "")
            _startDate = State(initialValue: event.startDate)
            _endDate = State(initialValue: event.endDate)
            _isAllDay = State(initialValue: event.isAllDay)
            _notes = State(initialValue: event.notes ?? "")
            _alert = State(initialValue: event.alert)
            _recurrence = State(initialValue: event.recurrence)
            _customRecurrence = State(initialValue: event.customRecurrence)
            _attachments = State(initialValue: event.attachments)
        } else {
            _alert = State(initialValue: ICSEvent.AlertTime(rawValue: UserDefaults.standard.string(forKey: "defaultAlert") ?? ICSEvent.AlertTime.fifteenMinutes.rawValue) ?? .fifteenMinutes)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Titel", text: $title)
                    TextField("Ort", text: $location)
                }
                
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
                
                Section {
                    HStack {
                        Text("Wiederholen")
                        Spacer()
                        Text(recurrenceButtonTitle)
                            .foregroundColor(.blue)
                            .onTapGesture {
                                showingCustomRecurrence = true
                            }
                    }
                }
                
                Section {
                    HStack {
                        Text("Erinnerung")
                        Spacer()
                        Text(alert.localizedString)
                            .foregroundColor(.blue)
                            .onTapGesture {
                                showingAlert = true
                            }
                    }
                }
                
                Section {
                    TextField("Notizen", text: $notes, axis: .vertical)
                        .lineLimit(5...10)
                }
            }
            .navigationTitle(event == nil ? "Neuer Termin" : "Termin bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        saveEvent()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showingCustomRecurrence) {
                CustomRecurrenceView(recurrence: $recurrence, customRecurrence: $customRecurrence)
            }
            .sheet(isPresented: $showingAlert) {
                AlertPickerView(alert: $alert)
            }
        }
    }
    
    private var recurrenceButtonTitle: String {
        switch recurrence {
        case .none:
            return "Nie"
        case .daily:
            return "Täglich"
        case .weekly:
            return "Wöchentlich"
        case .monthly:
            return "Monatlich"
        case .yearly:
            return "Jährlich"
        case .custom:
            if let custom = customRecurrence {
                return custom.localizedString
            }
            return "Benutzerdefiniert"
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
            alert: alert,
            recurrence: recurrence,
            customRecurrence: recurrence == .custom ? customRecurrence : nil,
            attachments: attachments
        )
        
        if event == nil {
            viewModel.addEvent(newEvent)
        } else {
            viewModel.updateEvent(newEvent)
        }
    }
}

extension ICSEvent.AlertTime {
    var localizedString: String {
        switch self {
        case .none:
            return "Keine"
        case .atTime:
            return "Zur Startzeit"
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
        }
    }
}

extension ICSEvent.CustomRecurrence {
    var localizedString: String {
        let frequencyStr: String
        switch frequency {
        case .daily:
            frequencyStr = "Tag"
        case .weekly:
            frequencyStr = "Woche"
        case .monthly:
            frequencyStr = "Monat"
        case .yearly:
            frequencyStr = "Jahr"
        case .none, .custom:
            return "Keine"
        }
        
        let pluralStr = interval > 1 ? "e" : ""
        let intervalStr = "Alle \(interval) \(frequencyStr)\(pluralStr)"
        
        if let count = count {
            return "\(intervalStr), \(count)x"
        } else {
            return intervalStr
        }
    }
}

struct AlertPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var alert: ICSEvent.AlertTime
    @AppStorage("defaultAlert") private var defaultAlert: String = ICSEvent.AlertTime.fifteenMinutes.rawValue
    
    var body: some View {
        NavigationView {
            Form {
                Picker("Erinnerung", selection: $alert) {
                    ForEach(ICSEvent.AlertTime.allCases, id: \.self) { alertTime in
                        Text(alertTime.localizedString).tag(alertTime)
                    }
                }
                .pickerStyle(.inline)
                
                Toggle("Als Standard speichern", isOn: Binding(
                    get: { defaultAlert == alert.rawValue },
                    set: { isOn in
                        if isOn {
                            defaultAlert = alert.rawValue
                        }
                    }
                ))
            }
            .navigationTitle("Erinnerung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }
}
