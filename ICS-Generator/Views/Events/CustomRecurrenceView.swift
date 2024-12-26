import SwiftUI

struct CustomRecurrenceView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var recurrence: ICSEvent.RecurrenceRule
    @Binding var customRecurrence: ICSEvent.CustomRecurrence?
    
    @State private var frequency: ICSEvent.RecurrenceRule = .daily
    @State private var interval: Int = 1
    @State private var selectedWeekDays: Set<ICSEvent.WeekDay> = []
    @State private var showingEndDatePicker = false
    @State private var endDate: Date?
    @State private var count: Int = 1
    
    private var intervalText: String {
        switch frequency {
        case .daily: return interval == 1 ? String(localized: "Tag") : String(localized: "Tage")
        case .weekly: return interval == 1 ? String(localized: "Woche") : String(localized: "Wochen")
        case .monthly: return interval == 1 ? String(localized: "Monat") : String(localized: "Monate")
        case .yearly: return interval == 1 ? String(localized: "Jahr") : String(localized: "Jahre")
        default: return ""
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                frequencySection
                
                if frequency == .weekly {
                    weekDaysSection
                }
                
                endSection
            }
            .navigationTitle(String(localized: "Benutzerdefinierte Wiederholung"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(String(localized: "Abbrechen")) {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(String(localized: "Fertig")) {
                        saveCustomRecurrence()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var frequencySection: some View {
        Section(header: Text(String(localized: "Wiederholen"))) {
            Picker(String(localized: "Frequenz"), selection: $frequency) {
                Text(String(localized: "Täglich")).tag(ICSEvent.RecurrenceRule.daily)
                Text(String(localized: "Wöchentlich")).tag(ICSEvent.RecurrenceRule.weekly)
                Text(String(localized: "Monatlich")).tag(ICSEvent.RecurrenceRule.monthly)
                Text(String(localized: "Jährlich")).tag(ICSEvent.RecurrenceRule.yearly)
            }
            
            Stepper("\(String(localized: "Alle")) \(interval) \(intervalText)", value: $interval, in: 1...99)
        }
    }
    
    private var weekDaysSection: some View {
        Section(header: Text(String(localized: "Wochentage"))) {
            ForEach(ICSEvent.WeekDay.allCases, id: \.self) { weekDay in
                weekDayToggle(for: weekDay)
            }
        }
    }
    
    private func weekDayToggle(for weekDay: ICSEvent.WeekDay) -> some View {
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
    
    private var endSection: some View {
        Section(header: Text(String(localized: "Ende"))) {
            endDateToggle
            
            if showingEndDatePicker {
                endDatePicker
            } else {
                repeatCountField
            }
        }
    }
    
    private var endDateToggle: some View {
        Toggle(String(localized: "Enddatum festlegen"), isOn: $showingEndDatePicker)
    }
    
    private var endDatePicker: some View {
        DatePicker(
            String(localized: "Enddatum"),
            selection: Binding(
                get: { endDate ?? Date() },
                set: { endDate = $0 }
            ),
            displayedComponents: [.date]
        )
    }
    
    private var repeatCountField: some View {
        Stepper("\(String(localized: "Anzahl Wiederholungen")): \(count)", value: $count, in: 1...99)
    }
    
    private func saveCustomRecurrence() {
        let weekDaysSet = frequency == .weekly && !selectedWeekDays.isEmpty ? selectedWeekDays : nil
        
        let newCustomRecurrence = ICSEvent.CustomRecurrence(
            frequency: frequency,
            interval: interval,
            count: showingEndDatePicker ? nil : count,
            until: showingEndDatePicker ? endDate : nil,
            weekDays: weekDaysSet
        )
        
        customRecurrence = newCustomRecurrence
        recurrence = .custom
    }
}

#Preview {
    CustomRecurrenceView(
        recurrence: .constant(.none),
        customRecurrence: .constant(nil)
    )
}
