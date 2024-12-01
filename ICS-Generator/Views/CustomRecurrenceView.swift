import SwiftUI

struct CustomRecurrenceView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var recurrence: ICSEvent.RecurrenceRule
    @Binding var customRecurrence: ICSEvent.CustomRecurrence?
    
    @State private var frequency: ICSEvent.RecurrenceRule = .daily
    @State private var interval: Int = 1
    @State private var selectedWeekDays: Set<ICSEvent.WeekDay> = []
    @State private var endDate: Date?
    @State private var count: Int?
    @State private var showingEndDatePicker = false
    
    private var intervalText: String {
        switch frequency {
        case .daily: return interval == 1 ? "Tag" : "Tage"
        case .weekly: return interval == 1 ? "Woche" : "Wochen"
        case .monthly: return interval == 1 ? "Monat" : "Monate"
        case .yearly: return interval == 1 ? "Jahr" : "Jahre"
        default: return ""
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Häufigkeit", selection: $frequency) {
                        Text("Täglich").tag(ICSEvent.RecurrenceRule.daily)
                        Text("Wöchentlich").tag(ICSEvent.RecurrenceRule.weekly)
                        Text("Monatlich").tag(ICSEvent.RecurrenceRule.monthly)
                        Text("Jährlich").tag(ICSEvent.RecurrenceRule.yearly)
                    }
                    
                    Stepper("Alle \(interval) \(intervalText)", value: $interval, in: 1...99)
                }
                
                if frequency == .weekly {
                    Section(header: Text("Wochentage")) {
                        ForEach(ICSEvent.WeekDay.allCases, id: \.self) { weekDay in
                            Toggle(weekDay.localizedName, isOn: Binding(
                                get: { selectedWeekDays.contains(weekDay) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedWeekDays.insert(weekDay)
                                    } else {
                                        selectedWeekDays.remove(weekDay)
                                    }
                                }
                            ))
                        }
                    }
                }
                
                Section(header: Text("Ende")) {
                    Toggle("Enddatum", isOn: Binding(
                        get: { showingEndDatePicker },
                        set: { isOn in
                            showingEndDatePicker = isOn
                            if !isOn {
                                endDate = nil
                            }
                        }
                    ))
                    
                    if showingEndDatePicker {
                        DatePicker(
                            "Enddatum",
                            selection: Binding(
                                get: { endDate ?? Date() },
                                set: { endDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                    }
                    
                    if !showingEndDatePicker {
                        HStack {
                            Text("Anzahl Wiederholungen")
                            Spacer()
                            TextField("Anzahl", value: $count, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }
            .navigationTitle("Wiederholung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        let customRecurrence = ICSEvent.CustomRecurrence(
                            frequency: frequency,
                            interval: interval,
                            count: showingEndDatePicker ? nil : count,
                            until: endDate,
                            weekDays: frequency == .weekly ? selectedWeekDays : nil
                        )
                        self.customRecurrence = customRecurrence
                        self.recurrence = .custom
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CustomRecurrenceView(
        recurrence: .constant(.none),
        customRecurrence: .constant(nil)
    )
}
