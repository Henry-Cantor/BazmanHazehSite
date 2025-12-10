//
//  Untitled.swift
//  BazemanLayout
//
//  Created by Charlie Aronson on 5/1/25.
//

import UIKit
import SwiftUI

// MARK: ZmanRow View

enum UnitType: String, CaseIterable, Identifiable, Codable {
    case degrees = "°", hours = "hrs", minutes = "min", fixedHours = "Fixed hrs"
    var id: String { rawValue }
    static let sortOrder: [UnitType] = [.degrees, .hours, .minutes, .fixedHours]
    static var userSelectable: [UnitType] {
            return [.degrees, .hours, .minutes]
        }
}

extension View {
    func keyboardToolbarButton(label: String = "Return", action: @escaping () -> Void) -> some View {
        self
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(action: {
                        action()
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }) {
                        Text(label)
                    }
                }
            }
    }
}


// MARK: - ZmanRow View

// MARK: - ZmanRow View

import UIKit
import SwiftUI

struct ZmanRow: View {
    @ObservedObject var entry: SettingsView.ZmanEntry
    @Binding var isEditing: Bool
    var onUpdate: (SettingsView.ZmanEntry) -> Void
    var onDelete: (SettingsView.ZmanEntry) -> Void

    @State private var localValue: String = ""
    @State private var localKey: String = ""
    @State private var localAlarmOffset: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if isEditing {
                    TextField("Title", text: Binding(
                        get: { localKey },
                        set: {
                            localKey = $0
                            entry.key = $0
                            onUpdate(entry)
                        }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    Text(entry.key)
                        .foregroundColor(entry.isVisible ? .primary : .gray)
                }

                Spacer()

                if entry.isVisible {
                    if isEditing {
                        TextField("Value", text: Binding(
                            get: { localValue },
                            set: {
                                localValue = $0
                                if Double($0) != nil {
                                    entry.value = $0
                                    onUpdate(entry)
                                }
                            }
                        ))
                        .frame(width: 60)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .multilineTextAlignment(.trailing)

                        Text(entry.unit.rawValue)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(entry.value) \(entry.unit.rawValue)")
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Hidden")
                        .italic()
                        .foregroundColor(.gray)
                }

                if isEditing {
                    if entry.isCustom {
                        Button(action: { onDelete(entry) }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    } else {
                        if entry.lock {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                                .help("Visibility is locked")
                        } else {
                            Button(action: {
                                entry.isVisible.toggle()
                                onUpdate(entry)
                            }) {
                                Image(systemName: entry.isVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    Button(action: {
                        entry.alarmOn.toggle()
                        onUpdate(entry)
                    }) {
                        Image(systemName: entry.alarmOn ? "alarm.fill" : "alarm")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }

            if isEditing && entry.alarmOn {
                HStack {
                    Image(systemName: "alarm")
                        .foregroundColor(.blue)
                    Text("Alarm:")
                        .foregroundColor(.secondary)

                    TextField("minutes before", text: Binding(
                        get: { localAlarmOffset },
                        set: {
                            localAlarmOffset = $0
                            if let val = Int($0), val >= 0 {
                                entry.alarmOffset = $0
                                onUpdate(entry)
                            }
                        }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)

                    Text("min before")
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)
                .padding(.top, 4)
            } else if entry.alarmOn {
                let alarmVal = Int(entry.alarmOffset) ?? 0
                HStack(spacing: 6) {
                    Image(systemName: "alarm.fill")
                        .foregroundColor(.blue)
                        .font(.subheadline)
                    Text("\(alarmVal) min before")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 6)
        .onAppear {
            localValue = entry.value
            localKey = entry.key
            localAlarmOffset = entry.alarmOffset
        }
    }
}

// UIKit ViewController embedding SwiftUI SettingsView

class SettingsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.blue,
            .font: UIFont.systemFont(ofSize: 20, weight: .bold)
        ]

        let host = UIHostingController(rootView: SettingsView())
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        host.didMove(toParent: self)
    }
}

struct SettingsView: View {
    // MARK: Models
    func ret() -> [ZmanEntry] {
        return entries
    }
    
    class ZmanEntry: Identifiable, ObservableObject, Codable {
        let id: UUID  // change from 'let id = UUID()' to this so we can decode/set it
        
        @Published var key: String
        @Published var value: String
        var unit: UnitType
        @Published var isVisible: Bool
        var isCustom: Bool
        var isAlot: Bool
        var lock: Bool
        @Published var alarmOffset: String  // Added alarmOffset as a String
        @Published var alarmOn: Bool = false

        enum CodingKeys: CodingKey {
            case id, key, value, unit, isVisible, isCustom, isAlot, lock, alarmOffset, alarmOn
        }

        init(key: String, value: String, unit: UnitType, isVisible: Bool, isCustom: Bool, isAlot: Bool) {
            self.id = UUID()  // generate new UUID
            self.key = key
            self.value = value
            self.unit = unit
            self.isVisible = isVisible
            self.isCustom = isCustom
            self.isAlot = isAlot
            self.lock = false
            self.alarmOffset = "0"
        }
        init(key: String, value: String, unit: UnitType, isVisible: Bool, isCustom: Bool, isAlot: Bool, lock:      Bool, isAlarm: Bool, alarmOffset: String) {
            self.id = UUID()  // generate new UUID
            self.key = key
            self.value = value
            self.unit = unit
            self.isVisible = isVisible
            self.isCustom = isCustom
            self.isAlot = isAlot
            self.lock = lock
            self.alarmOffset = alarmOffset
            self.alarmOn = isAlarm
        }

        init(key: String, value: String, unit: UnitType, isVisible: Bool, isCustom: Bool, isAlot: Bool, lock: Bool) {
            self.id = UUID()  // generate new UUID
            self.key = key
            self.value = value
            self.unit = unit
            self.isVisible = isVisible
            self.isCustom = isCustom
            self.isAlot = isAlot
            self.lock = lock
            self.alarmOffset = "0"
        }
        
        // MARK: Codable Conformance
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(UUID.self, forKey: .id)
            key = try container.decode(String.self, forKey: .key)
            value = try container.decode(String.self, forKey: .value)
            unit = try container.decode(UnitType.self, forKey: .unit)
            isVisible = try container.decode(Bool.self, forKey: .isVisible)
            isCustom = try container.decode(Bool.self, forKey: .isCustom)
            isAlot = try container.decode(Bool.self, forKey: .isAlot)
            lock = try container.decode(Bool.self, forKey: .lock)
            alarmOffset = try container.decode(String.self, forKey: .alarmOffset)
            alarmOn = try container.decodeIfPresent(Bool.self, forKey: .alarmOn) ?? false
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(key, forKey: .key)
            try container.encode(value, forKey: .value)
            try container.encode(unit, forKey: .unit)
            try container.encode(isVisible, forKey: .isVisible)
            try container.encode(isCustom, forKey: .isCustom)
            try container.encode(isAlot, forKey: .isAlot)
            try container.encode(lock, forKey: .lock)
            try container.encode(alarmOffset, forKey: .alarmOffset)
            try container.encode(alarmOn, forKey: .alarmOn)
        }
    }

    let k = 1
    
    // MARK: State
    
    @State private var isSephardi = true
    @State private var isEditing = false
    @State private var showResetConfirmation = false
    @State private var reset1 = true
    
    @State private var newKey = ""
    @State private var newValue = ""
    @State private var newUnit: UnitType = .hours
    @State private var newAlarmOffset = "0"  // New alarm offset for add new
    
    // NEW STATE for the MA/GRA or Before/After button
    enum MaGrazOption: String, CaseIterable, Identifiable {
        case ma = "MA"
        case gra = "GRA"
        case beforeHatzot = "Before Hatzot"
        case afterHatzot = "After Hatzot"
        case fixed = "Fixed (mins after sunset)"
        var id: String { rawValue }
    }
     public func edit() {
        isEditing = true
        isEditing = false
    }
    @State private var newMaGrazOption: MaGrazOption = .ma
    
    @ObservedObject var manager = ZmanimManager.shared
    var entries: [ZmanEntry] { manager.entries }
    
    // MARK: Body
    
    var body: some View {
        NavigationView {
            Form {
                // Add-New Section
                
                Section(header: Text("Add New Zeman (Set Notifications!)")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            TextField("Name", text: $newKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(minWidth: 120)

                            TextField("Value", text: $newValue)
                                .frame(width: 60)
                                .textFieldStyle(RoundedBorderTextFieldStyle(  ))
                                .keyboardToolbarButton(label: "Return" ) {
                                }

                            Picker("", selection: $newUnit) {
                                ForEach(UnitType.userSelectable) {  unit in
                                    Text(unit.rawValue).tag(unit)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width:  140)
                        }
                        
                        HStack(spacing: 12) {
                            Text("Notification  (Minutes):")
                                .frame(width: 130, alignment: .leading)

                            TextField("0", text: $newAlarmOffset)
                                .keyboardType(.numberPad)
                                .frame(width: 60)
                                .textFieldStyle(RoundedBorderTextFieldStyle() )
                
                        }
                        
                        HStack {
                            Spacer()
                            Picker("", selection: $newMaGrazOption) {
                                if  newUnit == .degrees {
                                    Text("AM").tag(MaGrazOption.beforeHatzot)
                                    Text("PM").tag(MaGrazOption.afterHatzot)
                                } else if newUnit ==  .hours {
                                    Text("MA").tag(MaGrazOption.ma)
                                    Text("GRA").tag(MaGrazOption.gra)
                                } else if newUnit == .minutes {
                                    Text("Fixed (Mins After Sunset)")
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width:  180)
                            Spacer()
                        }
                        Button(action: {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            addNew()
                        }) {
                            Label("Add Zman", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .contentShape(Rectangle())
                        .disabled(newKey.isEmpty || !isValid(newValue) || !isValidAlarmOffset(newAlarmOffset))
                    }
                    .padding(.vertical, 4)
                }
                
                // Visible Entries Section
                Section(header: Text("Zemanim Offsets")) {
                    ForEach(sortedEntries().filter { $0.isVisible }) { entry in
                        ZmanRow(
                            entry: entry,
                            isEditing: $isEditing,
                            onUpdate: updateEntry,
                            onDelete: deleteEntry
                        )
                    }
                }
                
                // Hidden Entries Section
                if sortedEntries().contains(where: { !$0.isVisible }) {
                    Section(header: Text("Hidden Zemanim").foregroundColor(.gray)) {
                        ForEach(sortedEntries().filter { !$0.isVisible }) { entry in
                            ZmanRow(
                                entry: entry,
                                isEditing: $isEditing,
                                onUpdate: updateEntry,
                                onDelete: deleteEntry
                            )
                        }
                    }
                }
                
                // Reset to Default Button Section
                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Text("Reset to Defaults")
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationBarItems(trailing: Button(isEditing ? "Done" : "Set Alarms / Hide Zemanim (Click Here)") {
                isEditing.toggle()
            } .foregroundColor(.red))
            .alert("Reset to Defaults?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetToDefaults()
                }
            } message: {
                Text("This will discard all your custom changes and reset all settings to their default values.")
            }
        }
    }
    
    // MARK: Helper Functions
    
    func sortedEntries() -> [ZmanEntry] {
        return entries.sorted { a, b  in
            // Sort by unit order first
            if UnitType.sortOrder.firstIndex(of: a.unit)! != UnitType.sortOrder.firstIndex(of: b.unit)! {
                return UnitType.sortOrder.firstIndex(of: a.unit)! < UnitType.sortOrder.firstIndex(of: b.unit)!
            }
            
            // If units are the same, sort by numeric value ascending
            let aValue = Double(a.value) ?? Double.infinity
            let bValue = Double(b.value) ?? Double.infinity
            
            return aValue < bValue
        }
    }
    
    func isValid(_ value: String) -> Bool {
        Double(value) != nil
    }
    
    func isValidAlarmOffset(_ value: String) -> Bool {
        if let intVal = Int(value) {
            return intVal >= 0
        }
        return false
    }
    
    func addNew() {
        // isAlot = true if MA or Before Hatzot is selected
        let alot = (newUnit != .degrees && newMaGrazOption == .ma) || (newUnit == .degrees && newMaGrazOption == .beforeHatzot)
        
        let newEntry = ZmanEntry(
            key: newKey,
            value: newValue,
            unit: newUnit,
            isVisible: true,
            isCustom: true,
            isAlot: alot
        )
        newEntry.alarmOffset = newAlarmOffset
        
        manager.entries.append(newEntry)
        
        // Reset inputs to defaults
        newKey = ""
        newValue = ""
        newUnit = .hours
        newAlarmOffset = "0"
        newMaGrazOption = .ma
    }
    
    func updateEntry(_ entry: ZmanEntry) {
        if let index = manager.entries.firstIndex(where: { $0.id == entry.id }) {
            manager.entries[index] = entry
        }
    }
    
    func deleteEntry(_ entry: ZmanEntry) {
        if let index = manager.entries.firstIndex(where: { $0.id == entry.id }) {
            manager.entries.remove(at: index)
        }
    }

    // MARK: Reset to Defaults Handler
    func resetToDefaults() {
        manager.reset()
    }
}
import Foundation

class ZmanimManager: ObservableObject {
     @State var replace1 = true
    static let shared = ZmanimManager()

    @Published var entries: [SettingsView.ZmanEntry] = [] {
        didSet {
            saveSettings()
        }
    }

    private init() {
        loadSettings()
        replace1 = false
    }

    private let saveKey = "ZmanimEntries"

    func saveSettings() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(entries)
            UserDefaults.standard.set(data, forKey: saveKey)
            print("Saved settings")
        } catch {
            print("Error saving settings:", error)
        }
    }

    func loadSettings() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else {
            // No saved data, load defaults
            loadDefaults(for: Date())
            return
        }
        do {
            let decoder = JSONDecoder()
            let savedEntries = try decoder.decode([SettingsView.ZmanEntry].self, from: data)
            entries = savedEntries
            print("Loaded saved settings")
        } catch {
            print("Error loading settings:", error)
            loadDefaults(for: Date())
        }
    }

    func getZmanim() -> [SettingsView.ZmanEntry] {
        return entries
    }

    func loadDefaults(for selectedDate: Date) {
        let calendar = Calendar.current
        let isFriday = calendar.component(.weekday, from: selectedDate) == 6
        let isSaturday = calendar.component(.weekday, from: selectedDate) ==   7
          var  tztkey = "Tzet Hakochavim (3 stars)"
        if isSaturday {
             tztkey = "Shabbat Ends"
        }

        if entries.isEmpty  {
             entries = [
                .init(key: "Alot Hashachar",  value: "-16.1", unit: .degrees, isVisible: true, isCustom: false, isAlot: true),
                .init(key: "Sunrise", value: "-0.83", unit: .degrees, isVisible: true, isCustom: false, isAlot: true),
                .init(key: "Sunset", value: "-0.83", unit: .degrees, isVisible: true, isCustom: false, isAlot: false),
                .init(key: tztkey, value: "-08.5", unit: .degrees, isVisible:  true, isCustom: false, isAlot: false),
                .init(key: "Misheyakir", value: "-10.2", unit: .degrees, isVisible: true, isCustom: false, isAlot: true),
                .init(key: "Latest Shemah (GR\"A)", value: "3.0", unit: .hours, isVisible: true, isCustom: false, isAlot: false),
                .init(key: "Latest Shemah (M\"A)", value: "3.0", unit: .hours, isVisible: true, isCustom: false, isAlot: true),
                .init(key: "Hatzot", value: "6.0", unit: .hours, isVisible: true, isCustom: false, isAlot: false),
                .init(key: "Minha Gedolah", value: "6.5", unit: .hours, isVisible: true, isCustom: false, isAlot: false),
                .init(key: "Minha Ketanah", value: "9.5", unit: .hours, isVisible: true, isCustom: false, isAlot: false),
                .init(key: "Plag Hamincha", value: "10.75", unit: .hours, isVisible: true, isCustom: false, isAlot: false),
                .init(key: "Candle Lighting", value: "-18", unit: .minutes, isVisible: isFriday, isCustom: false, isAlot: false, lock: true,  isAlarm: true, alarmOffset:  "15"),
                .init(key: "Hatzot Halailah", value: "12", unit: .fixedHours, isVisible: true, isCustom: false, isAlot: false)
            ]
        }
        else {
            // Update candle lighting visibility when loading defaults for a new date
            if let index = entries.firstIndex(where: { $0.key == "Candle Lighting" }) {
                entries[index].isVisible = isFriday
            }
            if let index = entries.firstIndex(where: {$0.key == "Tzet Hakochavim (3 stars)"}) {
                entries[index].key = tztkey
                print("Changed")
            }
            if let index = entries.firstIndex(where: {$0.key == "Shabbat Ends"}) {
                entries[index].key = tztkey
                print("2 Changed")
            }
        }
    }
    func reset() {
        entries = [
            .init(key: "Alot Hashachar", value: "-16.1", unit: .degrees, isVisible: true, isCustom: false, isAlot: true),
            .init(key: "Sunrise",  value: "-0.83", unit: .degrees, isVisible: true, isCustom: false, isAlot: true),
            .init(key: "Sunset", value: "-0.83", unit: .degrees, isVisible: true, isCustom: false, isAlot: false),
            .init(key: "Tzet Hakochavim (3 stars)", value: "-08.5", unit: .degrees, isVisible: true, isCustom: false, isAlot: false),
            .init(key: "Misheyakir", value: "-10.2", unit: .degrees, isVisible: true, isCustom: false, isAlot: true),
            .init(key: "Latest Shemah (GR\"A)", value: "3.0", unit: .hours, isVisible: true, isCustom: false, isAlot: false),
            .init(key: "Latest Shemah (M\"A)", value: "3.0", unit: .hours, isVisible: true, isCustom: false, isAlot: true),
            .init(key: "Hatzot", value: "6.0", unit: .hours, isVisible: true, isCustom: false, isAlot: false),
            .init(key: "Minha Gedolah", value: "6.5", unit: .hours, isVisible: true, isCustom: false, isAlot: false),
            .init(key: "Minha Ketanah", value: "9.5", unit: .hours, isVisible: true, isCustom: false, isAlot: false),
            .init(key: "Plag Hamincha", value: "10.75", unit: .hours, isVisible: true, isCustom: false, isAlot: false),
            .init(key: "Candle Lighting", value: "-18", unit: .minutes, isVisible: false, isCustom: false, isAlot: false, lock: true, isAlarm: true, alarmOffset: "15"),
            .init(key: "Hatzot Halailah", value: "12", unit: .fixedHours, isVisible: true, isCustom: false, isAlot: false)
        ]
    }
}
