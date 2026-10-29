import Foundation

public struct ExteraTimezoneMatch {
    public let title: String
    public let timeZone: TimeZone
}

public enum ExteraTimezoneResolver {
    private static let cityZones: [String: String] = [
        "london": "Europe/London", "paris": "Europe/Paris", "berlin": "Europe/Berlin",
        "madrid": "Europe/Madrid", "rome": "Europe/Rome", "amsterdam": "Europe/Amsterdam",
        "brussels": "Europe/Brussels", "vienna": "Europe/Vienna", "prague": "Europe/Prague",
        "warsaw": "Europe/Warsaw", "budapest": "Europe/Budapest", "stockholm": "Europe/Stockholm",
        "oslo": "Europe/Oslo", "copenhagen": "Europe/Copenhagen", "helsinki": "Europe/Helsinki",
        "athens": "Europe/Athens", "lisbon": "Europe/Lisbon", "dublin": "Europe/Dublin",
        "zurich": "Europe/Zurich", "moscow": "Europe/Moscow", "petersburg": "Europe/Moscow",
        "kiev": "Europe/Kiev", "kyiv": "Europe/Kiev", "minsk": "Europe/Minsk",
        "istanbul": "Europe/Istanbul", "newyork": "America/New_York", "washington": "America/New_York",
        "boston": "America/New_York", "philadelphia": "America/New_York", "miami": "America/New_York",
        "toronto": "America/Toronto", "vancouver": "America/Vancouver", "chicago": "America/Chicago",
        "dallas": "America/Chicago", "houston": "America/Chicago", "denver": "America/Denver",
        "losangeles": "America/Los_Angeles", "sanfrancisco": "America/Los_Angeles", "seattle": "America/Los_Angeles",
        "lasvegas": "America/Los_Angeles", "mexicocity": "America/Mexico_City", "saopaulo": "America/Sao_Paulo",
        "riodejaneiro": "America/Sao_Paulo", "buenosaires": "America/Buenos_Aires", "santiago": "America/Santiago",
        "lima": "America/Lima", "bogota": "America/Bogota", "dubai": "Asia/Dubai", "abudhabi": "Asia/Dubai",
        "tokyo": "Asia/Tokyo", "seoul": "Asia/Seoul", "beijing": "Asia/Shanghai", "shanghai": "Asia/Shanghai",
        "shenzhen": "Asia/Shanghai", "hongkong": "Asia/Hong_Kong", "taipei": "Asia/Taipei",
        "singapore": "Asia/Singapore", "bangkok": "Asia/Bangkok", "jakarta": "Asia/Jakarta",
        "manila": "Asia/Manila", "kualalumpur": "Asia/Kuala_Lumpur", "mumbai": "Asia/Kolkata",
        "delhi": "Asia/Kolkata", "bangalore": "Asia/Kolkata", "karachi": "Asia/Karachi",
        "dhaka": "Asia/Dhaka", "tehran": "Asia/Tehran", "baghdad": "Asia/Baghdad",
        "riyadh": "Asia/Riyadh", "jeddah": "Asia/Riyadh", "jerusalem": "Asia/Jerusalem",
        "telaviv": "Asia/Jerusalem", "almaty": "Asia/Almaty", "tashkent": "Asia/Tashkent",
        "sydney": "Australia/Sydney", "melbourne": "Australia/Melbourne", "brisbane": "Australia/Brisbane",
        "perth": "Australia/Perth", "auckland": "Pacific/Auckland", "honolulu": "Pacific/Honolulu",
        "anchorage": "America/Anchorage", "halifax": "America/Halifax", "cairo": "Africa/Cairo",
        "lagos": "Africa/Lagos", "nairobi": "Africa/Nairobi", "johannesburg": "Africa/Johannesburg",
        "casablanca": "Africa/Casablanca", "algiers": "Africa/Algiers", "tunis": "Africa/Tunis"
    ]

    private static let abbreviations: [String: String] = [
        "utc": "UTC", "gmt": "GMT",
        "est": "America/New_York", "edt": "America/New_York",
        "cst": "America/Chicago", "cdt": "America/Chicago",
        "mst": "America/Denver", "mdt": "America/Denver",
        "pst": "America/Los_Angeles", "pdt": "America/Los_Angeles",
        "akst": "America/Anchorage", "akdt": "America/Anchorage",
        "hst": "Pacific/Honolulu", "cet": "CET", "cest": "CEST",
        "eet": "EET", "msk": "MSK", "ist": "Asia/Kolkata",
        "bst": "Europe/London", "aest": "Australia/Sydney", "jst": "JST", "kst": "KST"
    ]

    private static let collapsedCityTitles: [String: String] = [
        "america/new_york": "New York", "america/chicago": "Chicago", "america/denver": "Denver",
        "america/los_angeles": "Los Angeles", "europe/london": "London", "europe/paris": "Paris",
        "europe/moscow": "Moscow", "asia/tokyo": "Tokyo", "asia/shanghai": "Shanghai",
        "asia/dubai": "Dubai", "australia/sydney": "Sydney", "asia/kolkata": "Mumbai",
        "europe/kiev": "Kyiv", "asia/hong_kong": "Hong Kong", "america/sao_paulo": "S\u{00E3}o Paulo"
    ]

    public static func match(in query: String) -> ExteraTimezoneMatch? {
        let words = query.lowercased().split(whereSeparator: { $0 == " " }).map(String.init)
        if words.isEmpty {
            return nil
        }

        if let offsetMatch = offsetZone(in: words) {
            return offsetMatch
        }

        for word in words {
            guard let identifier = abbreviations[word], let zone = TimeZone(identifier: identifier) else {
                continue
            }
            return ExteraTimezoneMatch(title: word.uppercased(), timeZone: zone)
        }

        var candidates = words + [words.joined()]
        if words.count >= 2 {
            candidates.append(words[(words.count - 2)...].joined())
        }
        for candidate in candidates {
            if candidate == "time" || candidate == "in" || candidate == "at" || candidate.isEmpty {
                continue
            }
            if let identifier = cityZones[candidate], let zone = TimeZone(identifier: identifier) {
                return ExteraTimezoneMatch(title: displayTitle(for: candidate), timeZone: zone)
            }
        }
        return nil
    }

    public static func currentTimeString(match: ExteraTimezoneMatch) -> String {
        return formatDate(inZone: match.timeZone, date: Date()) + " " + match.title
    }

    public static func convertedTimeString(from query: String, match: ExteraTimezoneMatch) -> String? {
        let timeComponents = query.split(whereSeparator: { $0 == " " }).filter({ $0.contains(":") })
        guard let components = timeComponents.first else {
            return nil
        }
        let parts = components.split(separator: ":")
        guard parts.count >= 2, let hour = Int(parts[0]), let minute = Int(parts[1]), hour < 24, minute < 60 else {
            return nil
        }
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        var reference = utcCalendar.dateComponents([.year, .month, .day], from: Date())
        reference.hour = hour
        reference.minute = minute
        guard let wallClockReference = utcCalendar.date(from: reference) else {
            return nil
        }
        return formatDate(inZone: match.timeZone, date: wallClockReference) + " " + match.title
    }

    private static func formatDate(inZone zone: TimeZone, date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = zone
        return formatter.string(from: date)
    }

    private static func displayTitle(for normalizedCity: String) -> String {
        if let identifier = cityZones[normalizedCity], let known = collapsedCityTitles[identifier.lowercased()] {
            return known
        }
        let canonical = cityZones[normalizedCity] ?? normalizedCity
        let zonePart = canonical.split(separator: "/").last.map(String.init) ?? canonical
        var spaced = ""
        for character in zonePart where character != "_" {
            if character.isUppercase && !spaced.isEmpty {
                spaced.append(" ")
            }
            spaced.append(character)
        }
        return spaced.capitalized
    }

    private static func offsetZone(in words: [String]) -> ExteraTimezoneMatch? {
        for word in words {
            let valueSource = word.replacingOccurrences(of: "utc", with: "").replacingOccurrences(of: "gmt", with: "")
            guard valueSource.count > 1, valueSource.hasPrefix("+") || valueSource.hasPrefix("-") else {
                continue
            }
            let sign = valueSource.hasPrefix("+") ? 1.0 : -1.0
            let digits = valueSource.dropFirst()
            let numberParts = digits.split(separator: ":")
            guard let hours = Double(numberParts[0]), abs(hours) <= 14.0 else {
                continue
            }
            let minutes: Double
            if numberParts.count > 1, let parsedMinutes = Double(numberParts[1]) {
                minutes = parsedMinutes
            } else {
                minutes = 0.0
            }
            let offsetSeconds = Int(sign * (hours * 3600.0 + minutes * 60.0))
            guard let zone = TimeZone(secondsFromGMT: offsetSeconds) else {
                continue
            }
            let prefix = valueSource.hasPrefix("+") ? "UTC+" : "UTC-"
            return ExteraTimezoneMatch(title: prefix + digits, timeZone: zone)
        }
        return nil
    }
}
