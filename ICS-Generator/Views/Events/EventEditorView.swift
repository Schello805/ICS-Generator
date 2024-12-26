import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
import Photos
import os.log

// MARK: - Event Details Section
struct EventDetailsSection: View {
    @Binding var title: String
    @Binding var location: String
    @Binding var travelTime: Int
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isAllDay: Bool
    let validateEvent: () -> Void
    let checkChanges: () -> Void
    
    var body: some View {
        Section(header: Text("Details")) {
            TextField("Titel", text: $title)
                .onChange(of: title) { oldValue, newValue in
                    validateEvent()
                    checkChanges()
                }
            
            TextField("Ort", text: $location)
                .onChange(of: location) { oldValue, newValue in checkChanges() }
            
            Stepper("Anfahrtszeit: \(travelTime) Minuten", value: $travelTime, in: 0...180, step: 15)
                .onChange(of: travelTime) { oldValue, newValue in checkChanges() }
            
            Toggle("Ganztägig", isOn: $isAllDay)
                .onChange(of: isAllDay) { oldValue, newValue in
                    validateEvent()
                    checkChanges()
                }
            
            if isAllDay {
                DatePicker("Datum", selection: $startDate, displayedComponents: .date)
                    .onChange(of: startDate) { oldValue, newValue in
                        if startDate > endDate {
                            endDate = startDate.addingTimeInterval(3600)
                        }
                        validateEvent()
                        checkChanges()
                    }
            } else {
                DatePicker("Start", selection: $startDate)
                    .onChange(of: startDate) { oldValue, newValue in
                        if startDate > endDate {
                            endDate = startDate.addingTimeInterval(3600)
                        }
                        validateEvent()
                        checkChanges()
                    }
                
                DatePicker("Ende", selection: $endDate)
                    .onChange(of: endDate) { oldValue, newValue in
                        validateEvent()
                        checkChanges()
                    }
            }
        }
    }
}

// MARK: - Additional Information Section
struct AdditionalInformationSection: View {
    @Binding var url: String
    @Binding var notes: String
    let checkChanges: () -> Void
    
    var body: some View {
        Section(header: Text("Zusätzliche Informationen")) {
            TextField("URL", text: $url)
                .onChange(of: url) { oldValue, newValue in checkChanges() }
            
            TextField("Notizen", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .onChange(of: notes) { oldValue, newValue in checkChanges() }
        }
    }
}

// MARK: - Alert Section
struct AlertSection: View {
    @Binding var alert: ICSEvent.AlertTime
    let checkChanges: () -> Void
    
    var body: some View {
        Section(header: Text("Erinnerung")) {
            Picker("Erinnerung", selection: $alert) {
                ForEach(ICSEvent.AlertTime.allCases, id: \.self) { alertTime in
                    Text(String(describing: alertTime)).tag(alertTime)
                }
            }
            .onChange(of: alert) { oldValue, newValue in checkChanges() }
        }
    }
}

// MARK: - Main View
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
    @State private var alert: ICSEvent.AlertTime = .fifteenMinutes
    @State private var secondAlert: ICSEvent.AlertTime = .none
    @State private var travelTime: Int = 0
    @State private var recurrence: ICSEvent.RecurrenceRule = .none
    @State private var customRecurrence: ICSEvent.CustomRecurrence? = nil
    @State private var isValid = false
    @State private var hasChanges = false
    @State private var showingDiscardAlert = false
    @State private var validationError: String?
    @State private var attachments: [ICSEvent.Attachment] = []
    @State private var showingAttachmentPicker = false
    @State private var selectedAttachmentType: AttachmentType = .document
    @State private var selectedItem: PhotosPickerItem?

    private enum AttachmentType {
        case document
        case photo
    }
    
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
                // Basic Details
                Section {
                    TextField("Titel", text: $title)
                        .onChange(of: title) { oldValue, newValue in
                            validateEvent()
                            checkChanges()
                        }
                    
                    TextField("Standort oder Videoanruf", text: $location)
                        .onChange(of: location) { oldValue, newValue in 
                            checkChanges()
                        }
                }
                
                // Date and Time
                Section {
                    Toggle("Ganztägig", isOn: $isAllDay)
                        .onChange(of: isAllDay) { oldValue, newValue in
                            validateEvent()
                            checkChanges()
                        }
                    
                    if isAllDay {
                        DatePicker("Beginn", selection: $startDate, displayedComponents: .date)
                            .onChange(of: startDate) { oldValue, newValue in
                                if startDate > endDate {
                                    endDate = startDate.addingTimeInterval(3600)
                                }
                                validateEvent()
                                checkChanges()
                            }
                        
                        DatePicker("Ende", selection: $endDate, displayedComponents: .date)
                            .onChange(of: endDate) { oldValue, newValue in
                                validateEvent()
                                checkChanges()
                            }
                    } else {
                        DatePicker("Beginn", selection: $startDate)
                            .onChange(of: startDate) { oldValue, newValue in
                                if startDate > endDate {
                                    endDate = startDate.addingTimeInterval(3600)
                                }
                                validateEvent()
                                checkChanges()
                            }
                        
                        DatePicker("Ende", selection: $endDate)
                            .onChange(of: endDate) { oldValue, newValue in
                                validateEvent()
                                checkChanges()
                            }
                    }
                }
                
                // Additional Options
                Section {
                    NavigationLink {
                        Form {
                            Picker("Hinweis", selection: $alert) {
                                Text("Keine").tag(ICSEvent.AlertTime.none)
                                Text("Zur Startzeit").tag(ICSEvent.AlertTime.atTime)
                                Text("5 Minuten vorher").tag(ICSEvent.AlertTime.fiveMinutes)
                                Text("10 Minuten vorher").tag(ICSEvent.AlertTime.tenMinutes)
                                Text("15 Minuten vorher").tag(ICSEvent.AlertTime.fifteenMinutes)
                                Text("30 Minuten vorher").tag(ICSEvent.AlertTime.thirtyMinutes)
                                Text("1 Stunde vorher").tag(ICSEvent.AlertTime.oneHour)
                                Text("2 Stunden vorher").tag(ICSEvent.AlertTime.twoHours)
                                Text("1 Tag vorher").tag(ICSEvent.AlertTime.oneDay)
                                Text("2 Tage vorher").tag(ICSEvent.AlertTime.twoDays)
                                Text("1 Woche vorher").tag(ICSEvent.AlertTime.oneWeek)
                            }
                            .onChange(of: alert) { oldValue, newValue in
                                checkChanges()
                            }
                        }
                        .navigationTitle("Hinweis")
                    } label: {
                        HStack {
                            Text("Hinweis")
                            Spacer()
                            Text(alertTimeToString(alert))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink {
                        Form {
                            Picker("2. Hinweis", selection: $secondAlert) {
                                Text("Keine").tag(ICSEvent.AlertTime.none)
                                Text("Zur Startzeit").tag(ICSEvent.AlertTime.atTime)
                                Text("5 Minuten vorher").tag(ICSEvent.AlertTime.fiveMinutes)
                                Text("10 Minuten vorher").tag(ICSEvent.AlertTime.tenMinutes)
                                Text("15 Minuten vorher").tag(ICSEvent.AlertTime.fifteenMinutes)
                                Text("30 Minuten vorher").tag(ICSEvent.AlertTime.thirtyMinutes)
                                Text("1 Stunde vorher").tag(ICSEvent.AlertTime.oneHour)
                                Text("2 Stunden vorher").tag(ICSEvent.AlertTime.twoHours)
                                Text("1 Tag vorher").tag(ICSEvent.AlertTime.oneDay)
                                Text("2 Tage vorher").tag(ICSEvent.AlertTime.twoDays)
                                Text("1 Woche vorher").tag(ICSEvent.AlertTime.oneWeek)
                            }
                            .onChange(of: secondAlert) { oldValue, newValue in
                                checkChanges()
                            }
                        }
                        .navigationTitle("2. Hinweis")
                    } label: {
                        HStack {
                            Text("2. Hinweis")
                            Spacer()
                            Text(alertTimeToString(secondAlert))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink {
                        Form {
                            Stepper("Anfahrtszeit: \(travelTime) Minuten", value: $travelTime, in: 0...180, step: 15)
                                .onChange(of: travelTime) { oldValue, newValue in
                                    checkChanges()
                                }
                        }
                        .navigationTitle("Anfahrtszeit")
                    } label: {
                        HStack {
                            Text("Anfahrtszeit")
                            Spacer()
                            if travelTime > 0 {
                                Text("\(travelTime) Minuten")
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Ohne")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    NavigationLink {
                        Form {
                            Picker("Wiederholen", selection: $recurrence) {
                                ForEach(ICSEvent.RecurrenceRule.allCases, id: \.self) { rule in
                                    Text(rule.localizedString).tag(rule)
                                }
                            }
                            .onChange(of: recurrence) { oldValue, newValue in
                                checkChanges()
                            }
                        }
                        .navigationTitle("Wiederholen")
                    } label: {
                        HStack {
                            Text("Wiederholen")
                            Spacer()
                            Text(recurrence.localizedString)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Notes Section
                Section {
                    TextField("URL", text: $url)
                        .onChange(of: url) { oldValue, newValue in 
                            checkChanges()
                        }
                    
                    TextField("Notizen", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .onChange(of: notes) { oldValue, newValue in 
                            checkChanges()
                        }
                }
                
                // Attachments Section
                if !attachments.isEmpty {
                    Section("Anhänge") {
                        ForEach(attachments) { attachment in
                            HStack {
                                Image(systemName: attachment.type.iconName)
                                    .foregroundColor(.accentColor)
                                Text(attachment.fileName)
                                Spacer()
                            }
                        }
                        .onDelete { indexSet in
                            attachments.remove(atOffsets: indexSet)
                            checkChanges()
                        }
                    }
                }
                
                Section {
                    Menu {
                        Button {
                            selectedAttachmentType = .document
                            showingAttachmentPicker = true
                        } label: {
                            Label("Dokument", systemImage: "doc.fill")
                        }
                        
                        Button {
                            selectedAttachmentType = .photo
                            showingAttachmentPicker = true
                        } label: {
                            Label("Foto oder Video", systemImage: "photo.fill")
                        }
                    } label: {
                        Text("Anhang hinzufügen...")
                    }
                }
                
                if let error = validationError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(event == nil ? "Neu" : "Bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        if hasChanges {
                            showingDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Hinzufügen") {
                        saveEvent()
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .alert("Änderungen verwerfen?", isPresented: $showingDiscardAlert) {
                Button("Abbrechen", role: .cancel) { }
                Button("Verwerfen", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("Möchten Sie die Änderungen wirklich verwerfen?")
            }
        }
        .sheet(isPresented: $showingAttachmentPicker) {
            if selectedAttachmentType == .photo {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Text("Foto auswählen")
                }
                .onChange(of: selectedItem) { _, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self) {
                            handleImageSelection(data, fileName: "Foto.jpg")
                            selectedItem = nil
                            showingAttachmentPicker = false
                        }
                    }
                }
            } else {
                DocumentPicker(types: [.pdf]) { url in
                    handleDocumentSelection(url)
                    showingAttachmentPicker = false
                }
            }
        }
        .onAppear {
            if let event = event {
                title = event.title
                location = event.location ?? ""
                startDate = event.startDate
                endDate = event.endDate
                isAllDay = event.isAllDay
                notes = event.notes ?? ""
                url = event.url ?? ""
                alert = event.alert
                secondAlert = event.secondAlert
                recurrence = event.recurrence
                customRecurrence = event.customRecurrence
                travelTime = event.travelTime
                attachments = event.attachments
                validateEvent()
            }
        }
    }
    
    private func handleDocumentSelection(_ url: URL) {
        guard let data = try? Data(contentsOf: url),
              let type = ICSEvent.AttachmentType.from(utType: url.pathExtension) else {
            return
        }
        
        let attachment = ICSEvent.Attachment(
            fileName: url.lastPathComponent,
            data: data,
            type: type
        )
        attachments.append(attachment)
        checkChanges()
    }
    
    private func handleImageSelection(_ data: Data, fileName: String) {
        let attachment = ICSEvent.Attachment(
            fileName: fileName,
            data: data,
            type: .jpeg
        )
        attachments.append(attachment)
        checkChanges()
    }
    
    private func saveEvent() {
        logger.info("Starting saveEvent()")
        logger.info("Current state - title: \(title), startDate: \(startDate), endDate: \(endDate)")
        
        let newEvent = ICSEvent(
            id: event?.id ?? UUID(),  // Verwende existierende ID oder erstelle neue
            title: title,
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            location: location.isEmpty ? nil : location,
            notes: notes.isEmpty ? nil : notes,
            url: url.isEmpty ? nil : url,
            alert: alert,
            secondAlert: secondAlert,
            travelTime: travelTime,
            recurrence: recurrence,
            customRecurrence: customRecurrence,
            attachments: attachments
        )
        
        if let bindingEvent = bindingEvent {
            bindingEvent.wrappedValue = newEvent
        } else if let existingEvent = event {
            viewModel.updateEvent(existingEvent, newEvent)
        } else {
            viewModel.addEvent(newEvent)
        }
        
        logger.info("Event saved successfully")
        dismiss()
    }
    
    private func validateEvent() {
        validationError = nil
        
        // Titel-Validierung
        if title.isEmpty {
            validationError = "Bitte geben Sie einen Titel ein"
            isValid = false
            return
        }
        
        // Datum-Validierung
        if endDate < startDate {
            validationError = "Das Enddatum muss nach dem Startdatum liegen"
            isValid = false
            return
        }
        
        // URL-Validierung
        if !url.isEmpty {
            guard URL(string: url) != nil else {
                validationError = "Ungültige URL"
                isValid = false
                return
            }
        }
        
        isValid = true
    }
    
    private func checkChanges() {
        if let event = event {
            hasChanges = title != event.title ||
                        location != (event.location ?? "") ||
                        startDate != event.startDate ||
                        endDate != event.endDate ||
                        isAllDay != event.isAllDay ||
                        notes != (event.notes ?? "") ||
                        url != (event.url ?? "") ||
                        alert != event.alert ||
                        secondAlert != event.secondAlert ||
                        recurrence != event.recurrence ||
                        customRecurrence != event.customRecurrence ||
                        travelTime != event.travelTime ||
                        attachments != event.attachments
        } else {
            hasChanges = !title.isEmpty ||
                        !location.isEmpty ||
                        startDate != Date() ||
                        endDate != Date().addingTimeInterval(3600) ||
                        isAllDay ||
                        !notes.isEmpty ||
                        !url.isEmpty ||
                        alert != .fifteenMinutes ||
                        secondAlert != .none ||
                        recurrence != .none ||
                        customRecurrence != nil ||
                        travelTime != 0 ||
                        !attachments.isEmpty
        }
    }
    
    private func alertTimeToString(_ alertTime: ICSEvent.AlertTime) -> String {
        switch alertTime {
        case .none: return "Keine"
        case .atTime: return "Zur Startzeit"
        case .fiveMinutes: return "5 Minuten vorher"
        case .tenMinutes: return "10 Minuten vorher"
        case .fifteenMinutes: return "15 Minuten vorher"
        case .thirtyMinutes: return "30 Minuten vorher"
        case .oneHour: return "1 Stunde vorher"
        case .twoHours: return "2 Stunden vorher"
        case .oneDay: return "1 Tag vorher"
        case .twoDays: return "2 Tage vorher"
        case .oneWeek: return "1 Woche vorher"
        }
    }
}
