//
//  ViewController.swift
//  BazemanLayout
//
//  Created by Charlie Aronson on 5/1/25.
//

//
//  ViewController.swift
//  BazemanLayout
//

import UIKit
import CoreLocation
import SwiftAA
import MapKit
import UserNotifications

class ViewController: UIViewController, CLLocationManagerDelegate {
    func scheduleAlarm(title: String, time: Date, offsetMinutes: Int, isHidden: Bool, alarm: Bool) {
        // Cancel any existing alarm for today
        let dateFormatter = DateFormatter()
            dateFormatter.timeZone = currentTimeZone
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateTag = dateFormatter.string(from: time)

            let identifier =  "\(title ) - \(dateTag)"

        // Don't schedule if alarm is off or hidden
        guard !isHidden,  alarm else {
            print("🔕 Alarm for \(title) not scheduled because it's hidden or turned off.")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = identifier

        let formatter = DateFormatter()
        formatter.timeZone = currentTimeZone
        formatter.dateFormat = "h:mm a"
        let timeString = formatter.string(from: time)

        content.body = "\(offsetMinutes) minutes before \(timeString)"
        content.sound = .default

        guard let triggerDate = Calendar.current.date(byAdding: .minute, value: -offsetMinutes, to: time) else {
            print("Invalid trigger date")
            return
        }
        
        if triggerDate < Date() {
                print("⏩ Skipping \(title) at \(triggerDate) because it’s in the past")
                return
            }

        // Get today’s trigger date components (no repeat!)
        let calendar = Calendar.current
        let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling alarm: \(error)")
            }
        }

        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
        print("✅ Alarm scheduled for \(title) at \(formatter.string(from: triggerDate))")
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("📋 Currently scheduled alarms:")
            if requests.isEmpty {
                print("— None —")
            } else {
                for request in requests {
                    print("🔔 \(request.identifier)")
                    if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                       let nextTriggerDate = trigger.nextTriggerDate() {
                        print("    Next trigger date: \(formatter.string(from:nextTriggerDate))"     )
                    }
                }
            }
        }
    }



   // MARK: - Properties

   var latitude: Double = 40.274128
   var longitude: Double = -74.025496
   var currentLocationName: String = "Current Location"
   var currentTimeZone: TimeZone = TimeZone.current
   var entries = SettingsView().ret()
   var labels: [(String, UILabel)] =  []
   var selectedDate: Date = Date()
    var use24HourTime =  false

   // UI elements
   let locationManager = CLLocationManager()
   let locationButton = UIButton(type: .system)
   let hourLabel = UILabel()
   let hourMALabel = UILabel()
   let hatzotLabel = UILabel()
   let hatzotLailahLabel = UILabel()
    let appLogoImageView = UIImageView()
    let currentTimeLabel = UILabel()
    let halachicHourLabel = UILabel()


   // MARK: - View Lifecycle

   override func viewDidLoad() {
       let toggleButton = UIBarButtonItem(
           title: use24HourTime ?  "24H" :  "12H",
           style: .plain,
           target: self,
           action: #selector(toggleTimeFormat)
       )
       navigationItem.leftBarButtonItem = toggleButton
       
       super.viewDidLoad()
       navigationController?.navigationBar.titleTextAttributes = [
           .foregroundColor: UIColor.blue,
           .font: UIFont.systemFont(ofSize:  20, weight: .bold)
       ]
       title = "Home" // or whatever you want the title to be
       view.backgroundColor = .systemBackground

       // Setup Location Manager
       locationManager.delegate = self
       locationManager.desiredAccuracy = kCLLocationAccuracyBest
       locationManager.requestWhenInUseAuthorization()

       if CLLocationManager.locationServicesEnabled() {
           locationManager.startUpdatingLocation()
       }
       
       setupUI()
       startCurrentTimeTimer()
       computeZmanim(for: selectedDate)
   }

   override func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(animated)

       ZmanimManager.shared.loadDefaults(for: selectedDate)
       entries = SettingsView().ret()
       refreshLabels()
       setupUI()
       computeZmanim(for: selectedDate)
   }
    func startCurrentTimeTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            formatter.timeZone = self.currentTimeZone
            self.currentTimeLabel.text = formatter.string(from: Date())
        }
    }

   // MARK: - UI Setup

    func setupUI() {
        // Clear old subviews
        view.subviews.forEach { $0.removeFromSuperview() }

        // Configure appLogoImageView
        appLogoImageView.image = UIImage(named: "appLogo") // Ensure appLogo is in Assets.xcassets
        appLogoImageView.contentMode = .scaleAspectFit
        appLogoImageView.translatesAutoresizingMaskIntoConstraints = false

        // Date Picker
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.date = selectedDate
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)

        // Location Button
        locationButton.setTitle(currentLocationName, for: .normal)
        locationButton.setTitleColor(.label, for: .normal)
        locationButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        locationButton.contentHorizontalAlignment = .center
        locationButton.layer.cornerRadius = 6
        locationButton.backgroundColor = .tertiarySystemFill
        locationButton.translatesAutoresizingMaskIntoConstraints = false
        locationButton.addTarget(self, action: #selector(changeLocationTapped), for: .touchUpInside)

        // Small labels for "Tap to change"
        let dateTapLabel = UILabel()
        dateTapLabel.text = "Tap Date to Change"
        dateTapLabel.font = UIFont.systemFont(ofSize: 13)
        dateTapLabel.textColor = .secondaryLabel
        dateTapLabel.translatesAutoresizingMaskIntoConstraints = false

        let locationTapLabel = UILabel()
        locationTapLabel.text = "Tap Location to Change"
        locationTapLabel.font = UIFont.systemFont(ofSize: 13)
        locationTapLabel.textColor = .secondaryLabel
        locationTapLabel.translatesAutoresizingMaskIntoConstraints = false

        // Container views for date picker + label, and location button + label
        let dateContainer = UIStackView(arrangedSubviews: [datePicker, dateTapLabel])
        dateContainer.axis = .vertical
        dateContainer.spacing = 8
        dateContainer.alignment = .center
        dateContainer.translatesAutoresizingMaskIntoConstraints = false

        let locationContainer = UIStackView(arrangedSubviews: [locationButton, locationTapLabel])
        locationContainer.axis = .vertical
        locationContainer.spacing = 8
        locationContainer.alignment = .center
        locationContainer.translatesAutoresizingMaskIntoConstraints = false

        // Scroll View
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        // Content View inside scrollView (to hold stack + logo)
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        // Stack View for labels
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        let thanksLabel = UILabel()
        thanksLabel.text = "Created by Charlie A. and Henry C."
        thanksLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        thanksLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(thanksLabel)

        // Add Current Time and Halachic Hour row at top

        let currentTimeTitleLabel = UILabel()
        currentTimeTitleLabel.text = "Current Time:"
        currentTimeTitleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        currentTimeTitleLabel.textColor = .label
        currentTimeTitleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        currentTimeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .semibold)
        currentTimeLabel.textColor = .systemBlue
        currentTimeLabel.textAlignment = .right
        currentTimeLabel.text = "--:--:--"
        currentTimeLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        currentTimeLabel.layer.cornerRadius = 6
        currentTimeLabel.layer.masksToBounds = true
        currentTimeLabel.layoutMargins = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        currentTimeLabel.isUserInteractionEnabled = false

        let halachicHourTitleLabel = UILabel()
        halachicHourTitleLabel.text = "Halachic Hour (GR\"A):"
        halachicHourTitleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        halachicHourTitleLabel.textColor = .label
        halachicHourTitleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        halachicHourLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .semibold)
        halachicHourLabel.textColor = .systemGreen
        halachicHourLabel.textAlignment = .right
        halachicHourLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        halachicHourLabel.layer.cornerRadius = 6
        halachicHourLabel.layer.masksToBounds = true
        halachicHourLabel.layoutMargins = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        halachicHourLabel.isUserInteractionEnabled = false

        let currentTimeRow = UIStackView(arrangedSubviews: [currentTimeTitleLabel, currentTimeLabel])
        currentTimeRow.axis = .horizontal
        currentTimeRow.alignment = .center
        currentTimeRow.distribution = .fill
        currentTimeRow.spacing = 12

        let halachicHourRow = UIStackView(arrangedSubviews: [halachicHourTitleLabel, halachicHourLabel])
        halachicHourRow.axis = .horizontal
        halachicHourRow.alignment = .center
        halachicHourRow.distribution = .fill
        halachicHourRow.spacing = 12

        // Add these rows to the main stack view
        stack.addArrangedSubview(currentTimeRow)
        stack.addArrangedSubview(halachicHourRow)

        // Add rows and separators to stack
        for (title, label) in labels {
            let titleLabel = UILabel()
            let boldAttribute = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: titleLabel.font.pointSize)]
            let titleText = NSAttributedString(string: title, attributes: boldAttribute)
            titleLabel.attributedText = titleText

            let row = UIStackView(arrangedSubviews: [titleLabel, label])
            row.axis = .horizontal
            row.distribution = .equalSpacing
            stack.addArrangedSubview(row)

            // Separator line
            let separator = UIView()
            separator.backgroundColor = .separator
            separator.translatesAutoresizingMaskIntoConstraints = false
            stack.addArrangedSubview(separator)
            NSLayoutConstraint.activate([
                separator.heightAnchor.constraint(equalToConstant: 1)
            ])
        }

        // Add appLogoImageView below stack inside contentView
        contentView.addSubview(appLogoImageView)

        // Add fixed controls to main view: scrollView already added above
        // Add dateContainer and locationContainer inside contentView, above stack
        contentView.addSubview(dateContainer)
        contentView.addSubview(locationContainer)
        contentView.addSubview(thanksLabel)

        // Constraints
        NSLayoutConstraint.activate([
            // ScrollView constraints
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // ContentView inside scrollView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Date container near top, centered horizontally
            dateContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            dateContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            // Location container below date container
            locationContainer.topAnchor.constraint(equalTo: dateContainer.bottomAnchor, constant: 10),
            locationContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            // Stack view below location container, pinned to sides
            stack.topAnchor.constraint(equalTo: locationContainer.bottomAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // appLogoImageView below stack, centered horizontally
            appLogoImageView.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 20),
            appLogoImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            appLogoImageView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5),
            appLogoImageView.heightAnchor.constraint(equalToConstant: 100),

            // thanksLabel below logo, centered
            thanksLabel.topAnchor.constraint(equalTo: appLogoImageView.bottomAnchor, constant: 15),
            thanksLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            thanksLabel.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, constant: -40),
            thanksLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
        ])
    }


   func refreshLabels() {
       entries = SettingsView().ret()
       labels.removeAll()

       let calendar = Calendar.current
       var calendarWithTimeZone = calendar
       calendarWithTimeZone.timeZone = currentTimeZone

       let weekday = calendarWithTimeZone.component(.weekday, from: selectedDate)
       let isFriday = weekday == 6

       // Update Candle Lighting visibility dynamically based on isFriday
       if let index = entries.firstIndex(where: { $0.key == "Candle Lighting" }) {
           entries[index].isVisible = isFriday
       }

       for entry in entries where entry.isVisible {
           labels.append((entry.key, UILabel()))
       }
       labels.append(("Hour (GR\"A):", hourLabel))
       labels.append(("Hour (M\"A):", hourMALabel))
   }

   // MARK: - Date & Location Handlers

   @objc func dateChanged(_ sender: UIDatePicker) {
       selectedDate = sender.date

       // Update Candle Lighting visibility in ZmanimManager entries
       let calendar = Calendar.current
       var calendarWithTimeZone = calendar
       calendarWithTimeZone.timeZone = currentTimeZone
       let weekday = calendarWithTimeZone.component(.weekday, from: selectedDate)
       let isFriday = weekday == 6
       if let idx = ZmanimManager.shared.entries.firstIndex(where: { $0.key == "Candle Lighting" }) {
           ZmanimManager.shared.entries[idx].isVisible = isFriday
       }

       ZmanimManager.shared.loadDefaults(for: selectedDate)
       entries = SettingsView().ret()
       refreshLabels()
       setupUI()
       computeZmanim(for: selectedDate)
   }
    @objc func toggleTimeFormat() {
        use24HourTime.toggle()
        navigationItem.leftBarButtonItem?.title = use24HourTime ?  "24H" :  "12H"
        ZmanimManager.shared.loadDefaults(for: selectedDate)
        entries = SettingsView().ret()
        refreshLabels()
        setupUI()
        computeZmanim(for: selectedDate)
    }

    @objc func changeLocationTapped() {
        let searchVC = LocationSearchViewController()
        searchVC.onLocationSelected = { [weak self] (coordinate: CLLocationCoordinate2D, name: String) in
            guard let self = self else { return }
            self.latitude = coordinate.latitude
            self.longitude = coordinate.longitude
            self.currentLocationName = name

            self.updateTimeZoneForCoordinate(coordinate) { timeZone in
                DispatchQueue.main.async {
                    self.currentTimeZone = timeZone ?? TimeZone.current
                    self.setupUI()
                    self.refreshLabels()
                    self.computeZmanim(for: self.selectedDate)
                }
            }
        }

        // ✅ Handle “Use Current Location” button
        searchVC.onUseCurrentLocation = { [weak self] in
            guard let self = self else { return }
            self.locationManager.requestLocation()  // <-- fetch a new location update
        }

        present(searchVC, animated: true, completion: nil)
    }


   func updateTimeZoneForCoordinate(_ coordinate: CLLocationCoordinate2D, completion: @escaping (TimeZone?) -> Void) {
       let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
       let geocoder = CLGeocoder()
       geocoder.reverseGeocodeLocation(location) { placemarks, error in
           completion(placemarks?.first?.timeZone)
       }
   }

   // MARK: - CLLocationManagerDelegate

   func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
       guard let location = locations.last else { return }

       latitude = location.coordinate.latitude
       longitude = location.coordinate.longitude

       let geocoder = CLGeocoder()
       geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
           guard let self = self else { return }
           if let placemark = placemarks?.first {
               let name = placemark.locality ?? placemark.name ?? "Current Location"
               self.currentLocationName = name
               self.currentTimeZone = placemark.timeZone ?? TimeZone.current

               DispatchQueue.main.async {
                   self.locationButton.setTitle(self.currentLocationName, for: .normal)
                   self.refreshLabels()
                   self.computeZmanim(for: self.selectedDate)
               }
           }
       }

       // Stop updates if you want just one fix
       locationManager.stopUpdatingLocation()
   }

   func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
       print("Failed to get location: \(error.localizedDescription)")
       DispatchQueue.main.async {
           self.currentLocationName = "Location Unavailable"
           self.locationButton.setTitle(self.currentLocationName, for: .normal)
       }
   }

   // MARK: - Placeholder for your Zmanim compute method
   // MARK: - Zmanim Calculation

    func computeZmanim(for date1: Date) -> [Date?] {
        let date =  date1
        let lat = Degree(latitude)
        let lon = Degree(longitude)
        let geo = GeographicCoordinates(positivelyWestwardLongitude: Degree(-lon.value), latitude: lat)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = currentTimeZone

        func elevationTime(_ elevation: Degree, isSunrise: Bool) -> Date? {
            let startOfDay = calendar.startOfDay(for: date)
            let maxMillis = 24 * 60 * 60 * 1000
            var low = 0, high = maxMillis
            while low < high {
                let mid = (low + high) / 2
                let time = startOfDay.addingTimeInterval(Double(mid) / 1000)
                let jd = JulianDay(time)
                let sun = Sun(julianDay: jd, highPrecision: true)
                let alt = sun.makeHorizontalCoordinates(with: geo).altitude
                if (isSunrise && alt >= elevation) || (!isSunrise && alt <= elevation) {
                    high = mid
                } else {
                    low = mid + 1
                }
            }
            if low == maxMillis || low == 0 { return nil }
            return startOfDay.addingTimeInterval(Double(low) / 1000)
        }

        func offset(_ base: Date?, hours: Double?) -> Date? {
            guard let base = base, let h = hours else { return nil }
            return base.addingTimeInterval(h * 60 * 60)
        }

        let dawn = elevationTime(Degree(Double(entries[0].value)!), isSunrise: true)
        let sunrise = elevationTime(Degree(Double(entries[1].value)!), isSunrise: true)
        let sunset = elevationTime(Degree(Double(entries[2].value)!), isSunrise: false)
        let tzet = elevationTime(Degree(Double(entries[3].value)!), isSunrise: false)

        let hour = (sunrise != nil && sunset != nil) ? sunset!.timeIntervalSince(sunrise!) / 12 : nil
        let hourMA = (dawn != nil && tzet != nil) ? tzet!.timeIntervalSince(dawn!) / 12 : nil
        let now = Date()

        if let sunrise = sunrise, let sunset = sunset {
            guard sunset > sunrise else {
                halachicHourLabel.text = "NA"
                return []
            }

            if now >= sunrise && now <= sunset {
                let elapsedSeconds = now.timeIntervalSince(sunrise)
                let exactHour = elapsedSeconds / (hour ?? 1)
                let quarterHour = (exactHour * 4).rounded() / 4
                halachicHourLabel.text = String(format: "%.2f", quarterHour)
            } else {
                halachicHourLabel.text = "Night"
            }
        } else {
            halachicHourLabel.text = "NA"
        }

        hourLabel.text = format(hour)
        hourMALabel.text = format(hourMA)
        let hatzot = (sunrise != nil && sunset != nil) ? sunrise!.addingTimeInterval(sunset!.timeIntervalSince(sunrise!) / 2) : nil
        hatzotLabel.text = format(hatzot)
        hatzotLailahLabel.text = format(offset(hatzot, hours: 12))

        var zmanTimes: [Date?] = []
        for entry in entries where entry.isVisible {
            switch entry.unit {
            case .degrees:
                let deg = Degree(Double(entry.value)!)
                zmanTimes.append(elevationTime(deg, isSunrise: entry.isAlot))
            case .hours:
                let multiplier = Double(entry.value)! / 3600
                let time = entry.isAlot
                    ? offset(dawn, hours: multiplier * (hourMA ?? 0))
                    : offset(sunrise, hours: multiplier * (hour ?? 0))
                zmanTimes.append(time)
            case .minutes:
                zmanTimes.append(offset(sunset, hours: Double(entry.value)! / 60))
            case .fixedHours:
                zmanTimes.append(offset(hatzot, hours: 12))
            }
        }

        for i in 0..<min(zmanTimes.count, labels.count) {
            labels[i].1.text = format(zmanTimes[i])
        }

        func sort(times: [Date?]) {
            guard labels.count >= 2, labels.count == times.count + 2 else { return }
            let countToSort = labels.count - 2
            let sortedPart = Array(times[0..<countToSort])
                .enumerated()
                .sorted { ($0.element ?? Date.distantFuture) < ($1.element ?? Date.distantFuture) }
                .map { labels[$0.offset] }
            labels = sortedPart + Array(labels.suffix(2))
        }
        sort(times: zmanTimes)

        let zman1 = entries.filter { $0.isVisible }

        // 🔁 Schedule alarms OFF the main thread
        DispatchQueue.global(qos: .userInitiated).async { [zman1, zmanTimes] in
            for (i, entry)  in zman1.enumerated() {
                let offsetMin = Int(entry.alarmOffset) ?? 0
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                if entry.alarmOn, i < zmanTimes.count, let zman = zmanTimes[i] {
                    DispatchQueue.main.async {
                        print("SCHEDULING INSIDE")
                        self.scheduleAlarmsForVisibleZmanim()
                        print("FINDIHSEHD THE SCHEUDLEEEE")
                    }
                }
            }
        }
        
        func printAllScheduledAlarms() {
            print("Staring Alarm Print")
            let center = UNUserNotificationCenter.current()
            let formatter = DateFormatter()
            formatter.timeZone = currentTimeZone
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"

            center.getPendingNotificationRequests { requests in
                print("📋 All upcoming scheduled alarms:")
                
                if requests.isEmpty {
                    print("— None —")
                    return
                }

                for request in requests {
                    let identifier = request.identifier
                    let title = request.content.title
                    let body = request.content.body

                    if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                       let nextTrigger = trigger.nextTriggerDate() {
                        print("🔔 \(identifier)")
                        print("    Title: \(title)")
                        print("    Body: \(body)")
                        print("    Will ring at: \(formatter.string(from: nextTrigger))")
                    } else {
                        print("⚠️ Could not get next trigger date for: \(identifier)")
                    }
                }
            }
        }
        printAllScheduledAlarms()

        // Clean up old views and refresh
        for subview in view.subviews where subview is UIStackView {
            subview.removeFromSuperview()
        }
        setupUI()
        return zmanTimes
    }
 //The problem is that the data is being appneded instead of jut replacing the array with the data

    func format(_ date: Date?) -> String {
        guard let date = date else { return "NA" }
        let f = DateFormatter()
        f.timeZone = currentTimeZone
        f.dateFormat = use24HourTime ? "HH:mm:ss.SSS" : "h:mm:ss a"
        return f.string(from: date)
    }
    func scheduleAlarmsForVisibleZmanim() {
        let calendar = Calendar.current
        var date = calendar.startOfDay(for: Date()) // start from today
        let endDate = calendar.date(byAdding: .day, value: 9, to: date)! // example: next 10 days

        while date <= endDate {
            // Fetch dayEntries for THIS specific day so isVisible updates correctly
            let dayEntries = SettingsView().ret() // <-- pass the loop date

            var calendarWithTimeZone = calendar
            calendarWithTimeZone.timeZone = currentTimeZone

            let lat = Degree(latitude)
            let lon = Degree(longitude)
            let geo = GeographicCoordinates(positivelyWestwardLongitude: Degree(-lon.value), latitude: lat)

            func elevationTime(_ elevation: Degree, isSunrise: Bool) -> Date? {
                let startOfDay = calendarWithTimeZone.startOfDay(for: date)
                let maxMillis = 24 * 60 * 60 * 1000
                var low = 0, high = maxMillis
                while low < high {
                    let mid = (low + high) / 2
                    let time = startOfDay.addingTimeInterval(Double(mid) / 1000)
                    let jd = JulianDay(time)
                    let sun = Sun(julianDay: jd, highPrecision: true)
                    let alt = sun.makeHorizontalCoordinates(with: geo).altitude
                    if (isSunrise && alt >= elevation) || (!isSunrise && alt <= elevation) {
                        high = mid
                    } else {
                        low = mid + 1
                    }
                }
                if low == maxMillis || low == 0 { return nil }
                return startOfDay.addingTimeInterval(Double(low) / 1000)
            }

            func offset(_ base: Date?, hours: Double?) -> Date? {
                guard let base = base, let h = hours else { return nil }
                return base.addingTimeInterval(h * 60 * 60)
            }

            let dawn = elevationTime(Degree(Double(dayEntries[0].value)!), isSunrise: true)
            let sunrise = elevationTime(Degree(Double(dayEntries[1].value)!), isSunrise: true)
            let sunset = elevationTime(Degree(Double(dayEntries[2].value)!), isSunrise: false)
            let tzet = elevationTime(Degree(Double(dayEntries[3].value)!), isSunrise: false)
            let hour = (sunrise != nil && sunset != nil) ? sunset!.timeIntervalSince(sunrise!) / 12 : nil
            let hourMA = (dawn != nil && tzet != nil) ? tzet!.timeIntervalSince(dawn!) / 12 : nil
            let hatzot = (sunrise != nil && sunset != nil) ? sunrise!.addingTimeInterval(sunset!.timeIntervalSince(sunrise!) / 2) : nil

            var zmanTimes: [Date?] = []
            for entry in dayEntries where entry.isVisible {
                switch entry.unit {
                case .degrees:
                    zmanTimes.append(elevationTime(Degree(Double(entry.value)!), isSunrise: entry.isAlot))
                case .hours:
                    let multiplier = Double(entry.value)! / 3600
                    let time = entry.isAlot
                        ? offset(dawn, hours: multiplier * (hourMA ?? 0))
                        : offset(sunrise, hours: multiplier * (hour ?? 0))
                    zmanTimes.append(time)
                case .minutes:
                    zmanTimes.append(offset(sunset, hours: Double(entry.value)! / 60))
                case .fixedHours:
                    zmanTimes.append(offset(hatzot, hours: 12))
                }
            }

            var i = 0
            for entry in dayEntries where entry.isVisible {
                if i >= zmanTimes.count { break }
                if let zman = zmanTimes[i], entry.alarmOn {
                    let offsetMin = Int(entry.alarmOffset)!
                    let uniqueTitle =  "\(entry.key)"
                    print("🔔 Scheduling alarm: \(uniqueTitle) at \(zman)")
                    scheduleAlarm(
                        title: uniqueTitle,
                        time: zman,
                        offsetMinutes: offsetMin,
                        isHidden: !entry.isVisible,
                        alarm: entry.alarmOn
                    )
                }
                i += 1
            }

            // Move to next day
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
    }

               func format(_ interval: TimeInterval?) -> String {
                   guard let interval =  interval else { return "NA" }
                   let mins = Int(interval) / 60
                   let secs = Int(interval) % 60
                   let millis = Int((interval - floor(interval)) * 1000)
                   return String(format: "%02d:%02d.%03d", mins, secs, millis)
               } //There is a bug that whne the times are deleted, the Hour GR"A and Hour M"A do not display the correct times
           }

import UIKit
import MapKit

class LocationSearchViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, MKLocalSearchCompleterDelegate {

    let searchBar = UISearchBar()
    let tableView = UITableView()

    let searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()

    // Closure to send back selected location or current location
    var onLocationSelected: ((CLLocationCoordinate2D, String) -> Void)?
    var onUseCurrentLocation: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address

        searchBar.delegate = self
        searchBar.placeholder = "Search for location"
        searchBar.sizeToFit()
        view.addSubview(searchBar)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        // Add "Use Current Location" button as table header
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 50))
        let currentLocButton = UIButton(type: .system)
        currentLocButton.setTitle("📍 Use Current Location", for: .normal)
        currentLocButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        currentLocButton.backgroundColor = .systemBlue
        currentLocButton.tintColor = .white
        currentLocButton.layer.cornerRadius = 8
        currentLocButton.addTarget(self, action: #selector(useCurrentLocationTapped), for: .touchUpInside)
        currentLocButton.frame = CGRect(x: 16, y: 5, width: view.bounds.width - 32, height: 40)
        headerView.addSubview(currentLocButton)
        tableView.tableHeaderView = headerView

        // Layout
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: - Actions

    @objc func useCurrentLocationTapped() {
        dismiss(animated: true) {
            self.onUseCurrentLocation?()
        }
    }

    // MARK: - UISearchBarDelegate

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            searchResults = []
            tableView.reloadData()
        } else {
            searchCompleter.queryFragment = searchText
        }
    }

    // MARK: - MKLocalSearchCompleterDelegate

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        tableView.reloadData()
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Autocomplete error: \(error.localizedDescription)")
    }

    // MARK: - UITableViewDelegate & DataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let result = searchResults[indexPath.row]
        cell.textLabel?.text = result.title
        cell.detailTextLabel?.text = result.subtitle
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let completion = searchResults[indexPath.row]
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        search.start { [weak self] response, error in
            guard
                let self = self,
                let coordinate = response?.mapItems.first?.placemark.coordinate
            else { return }

            let name = completion.title
            self.dismiss(animated: true) {
                self.onLocationSelected?(coordinate, name)
            }
        }
    }
}
