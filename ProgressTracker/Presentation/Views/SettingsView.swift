import SwiftUI

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("reminderTime") private var reminderTime: Double = Date().timeIntervalSince1970
    @State private var exportPresented = false

    private var reminderDate: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: reminderTime) },
            set: { reminderTime = $0.timeIntervalSince1970 }
        )
    }

    var body: some View {
        Form {
            Section(header: Text("Notifications")) {
                Toggle("Daily reminders", isOn: $notificationsEnabled)
                DatePicker(
                    "Reminder time",
                    selection: reminderDate,
                    displayedComponents: .hourAndMinute
                )
                .disabled(!notificationsEnabled)
            }

            Section(header: Text("Data")) {
                Button("Export Progress") {
                    exportPresented = true
                }
            }

            Section(header: Text("About")) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ProgressTracker v2.0")
                        .font(.headline)
                    Text("Track your daily resilience journey with mindful check-ins and detailed challenge notes.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Export", isPresented: $exportPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Export functionality will be available in a future update.")
        }
    }
}
