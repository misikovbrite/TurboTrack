import Foundation
import CoreLocation

struct Airport: Identifiable, Codable {
    let id: String // ICAO code
    let name: String
    let city: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var icao: String { id }

    var displayName: String {
        "\(city) (\(id))"
    }

    /// Search by city name, airport name, or ICAO code
    static func search(_ query: String) -> [Airport] {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }

        return commonAirports.filter { airport in
            airport.id.lowercased().contains(q) ||
            airport.city.lowercased().contains(q) ||
            airport.name.lowercased().contains(q)
        }
    }

    static func find(icao: String) -> Airport? {
        commonAirports.first { $0.id.uppercased() == icao.uppercased() }
    }

    /// Find by city name or ICAO — also handles displayName format "City (ICAO)"
    static func findByQuery(_ query: String) -> Airport? {
        let q = query.trimmingCharacters(in: .whitespaces)

        // Try exact ICAO first
        if let exact = find(icao: q) { return exact }

        // Try displayName format: "City (ICAO)"
        if q.contains("("), let icaoStart = q.lastIndex(of: "(") {
            let icao = String(q[q.index(after: icaoStart)...]).replacingOccurrences(of: ")", with: "").trimmingCharacters(in: .whitespaces)
            if let exact = find(icao: icao) { return exact }
        }

        // Try city match
        let results = search(q)
        if let first = results.first { return first }

        // Try each word separately (e.g. "Madrid LEMD" → try "Madrid", try "LEMD")
        let words = q.split(separator: " ").map(String.init)
        for word in words {
            if let exact = find(icao: word) { return exact }
        }
        for word in words {
            if let first = search(word).first { return first }
        }

        return nil
    }

    static let commonAirports: [Airport] = [
        // ========== USA ==========
        Airport(id: "KJFK", name: "John F. Kennedy Intl", city: "New York", latitude: 40.6413, longitude: -73.7781),
        Airport(id: "KLGA", name: "LaGuardia", city: "New York", latitude: 40.7769, longitude: -73.8740),
        Airport(id: "KLAX", name: "Los Angeles Intl", city: "Los Angeles", latitude: 33.9425, longitude: -118.4081),
        Airport(id: "KORD", name: "O'Hare Intl", city: "Chicago", latitude: 41.9742, longitude: -87.9073),
        Airport(id: "KMDW", name: "Midway Intl", city: "Chicago", latitude: 41.7868, longitude: -87.7522),
        Airport(id: "KATL", name: "Hartsfield-Jackson Intl", city: "Atlanta", latitude: 33.6407, longitude: -84.4277),
        Airport(id: "KDFW", name: "Dallas/Fort Worth Intl", city: "Dallas", latitude: 32.8998, longitude: -97.0403),
        Airport(id: "KDAL", name: "Dallas Love Field", city: "Dallas", latitude: 32.8471, longitude: -96.8518),
        Airport(id: "KDEN", name: "Denver Intl", city: "Denver", latitude: 39.8561, longitude: -104.6737),
        Airport(id: "KSFO", name: "San Francisco Intl", city: "San Francisco", latitude: 37.6213, longitude: -122.3790),
        Airport(id: "KOAK", name: "Oakland Intl", city: "Oakland", latitude: 37.7213, longitude: -122.2208),
        Airport(id: "KSJC", name: "San Jose Intl", city: "San Jose", latitude: 37.3626, longitude: -121.9291),
        Airport(id: "KSEA", name: "Seattle-Tacoma Intl", city: "Seattle", latitude: 47.4502, longitude: -122.3088),
        Airport(id: "KMIA", name: "Miami Intl", city: "Miami", latitude: 25.7959, longitude: -80.2870),
        Airport(id: "KFLL", name: "Fort Lauderdale-Hollywood Intl", city: "Fort Lauderdale", latitude: 26.0726, longitude: -80.1527),
        Airport(id: "KBOS", name: "Boston Logan Intl", city: "Boston", latitude: 42.3656, longitude: -71.0096),
        Airport(id: "KLAS", name: "Harry Reid Intl", city: "Las Vegas", latitude: 36.0840, longitude: -115.1537),
        Airport(id: "KMSP", name: "Minneapolis-St Paul Intl", city: "Minneapolis", latitude: 44.8848, longitude: -93.2223),
        Airport(id: "KDTW", name: "Detroit Metro Wayne County", city: "Detroit", latitude: 42.2124, longitude: -83.3534),
        Airport(id: "KPHL", name: "Philadelphia Intl", city: "Philadelphia", latitude: 39.8721, longitude: -75.2411),
        Airport(id: "KIAH", name: "George Bush Intercontinental", city: "Houston", latitude: 29.9902, longitude: -95.3368),
        Airport(id: "KHOU", name: "William P. Hobby", city: "Houston", latitude: 29.6454, longitude: -95.2789),
        Airport(id: "KPHX", name: "Phoenix Sky Harbor Intl", city: "Phoenix", latitude: 33.4373, longitude: -112.0078),
        Airport(id: "KEWR", name: "Newark Liberty Intl", city: "Newark", latitude: 40.6895, longitude: -74.1745),
        Airport(id: "KMCO", name: "Orlando Intl", city: "Orlando", latitude: 28.4312, longitude: -81.3081),
        Airport(id: "KCLT", name: "Charlotte Douglas Intl", city: "Charlotte", latitude: 35.2140, longitude: -80.9431),
        Airport(id: "KDCA", name: "Ronald Reagan Washington Natl", city: "Washington", latitude: 38.8512, longitude: -77.0402),
        Airport(id: "KIAD", name: "Washington Dulles Intl", city: "Washington", latitude: 38.9531, longitude: -77.4565),
        Airport(id: "KBWI", name: "Baltimore/Washington Intl", city: "Baltimore", latitude: 39.1754, longitude: -76.6683),
        Airport(id: "KTPA", name: "Tampa Intl", city: "Tampa", latitude: 27.9755, longitude: -82.5332),
        Airport(id: "KSLC", name: "Salt Lake City Intl", city: "Salt Lake City", latitude: 40.7884, longitude: -111.9778),
        Airport(id: "KSAN", name: "San Diego Intl", city: "San Diego", latitude: 32.7336, longitude: -117.1897),
        Airport(id: "KPDX", name: "Portland Intl", city: "Portland", latitude: 45.5898, longitude: -122.5951),
        Airport(id: "KSTL", name: "St. Louis Lambert Intl", city: "St. Louis", latitude: 38.7487, longitude: -90.3700),
        Airport(id: "KPIT", name: "Pittsburgh Intl", city: "Pittsburgh", latitude: 40.4915, longitude: -80.2329),
        Airport(id: "KMCI", name: "Kansas City Intl", city: "Kansas City", latitude: 39.2976, longitude: -94.7139),
        Airport(id: "KRDU", name: "Raleigh-Durham Intl", city: "Raleigh", latitude: 35.8776, longitude: -78.7875),
        Airport(id: "KAUS", name: "Austin-Bergstrom Intl", city: "Austin", latitude: 30.1975, longitude: -97.6664),
        Airport(id: "KSAT", name: "San Antonio Intl", city: "San Antonio", latitude: 29.5337, longitude: -98.4698),
        Airport(id: "KBNA", name: "Nashville Intl", city: "Nashville", latitude: 36.1246, longitude: -86.6782),
        Airport(id: "KSNA", name: "John Wayne Orange County", city: "Orange County", latitude: 33.6757, longitude: -117.8682),
        Airport(id: "KIND", name: "Indianapolis Intl", city: "Indianapolis", latitude: 39.7173, longitude: -86.2944),
        Airport(id: "KCLE", name: "Cleveland Hopkins Intl", city: "Cleveland", latitude: 41.4117, longitude: -81.8498),
        Airport(id: "KCMH", name: "John Glenn Columbus Intl", city: "Columbus", latitude: 39.9980, longitude: -82.8919),
        Airport(id: "KMKE", name: "Milwaukee Mitchell Intl", city: "Milwaukee", latitude: 42.9472, longitude: -87.8966),
        Airport(id: "PANC", name: "Ted Stevens Anchorage Intl", city: "Anchorage", latitude: 61.1743, longitude: -149.9962),
        Airport(id: "PHNL", name: "Daniel K. Inouye Intl", city: "Honolulu", latitude: 21.3187, longitude: -157.9225),
        Airport(id: "PHOG", name: "Kahului", city: "Maui", latitude: 20.8986, longitude: -156.4305),
        // ========== CANADA ==========
        Airport(id: "CYYZ", name: "Toronto Pearson", city: "Toronto", latitude: 43.6777, longitude: -79.6248),
        Airport(id: "CYVR", name: "Vancouver Intl", city: "Vancouver", latitude: 49.1947, longitude: -123.1792),
        Airport(id: "CYUL", name: "Montreal Trudeau", city: "Montreal", latitude: 45.4706, longitude: -73.7408),
        Airport(id: "CYOW", name: "Ottawa Macdonald-Cartier", city: "Ottawa", latitude: 45.3225, longitude: -75.6692),
        Airport(id: "CYYC", name: "Calgary Intl", city: "Calgary", latitude: 51.1215, longitude: -114.0076),
        Airport(id: "CYEG", name: "Edmonton Intl", city: "Edmonton", latitude: 53.3097, longitude: -113.5800),
        Airport(id: "CYWG", name: "Winnipeg Richardson Intl", city: "Winnipeg", latitude: 49.9100, longitude: -97.2399),
        Airport(id: "CYHZ", name: "Halifax Stanfield Intl", city: "Halifax", latitude: 44.8808, longitude: -63.5086),
        // ========== MEXICO / CENTRAL AMERICA / CARIBBEAN ==========
        Airport(id: "MMMX", name: "Mexico City Intl", city: "Mexico City", latitude: 19.4363, longitude: -99.0721),
        Airport(id: "MMUN", name: "Cancun Intl", city: "Cancun", latitude: 21.0365, longitude: -86.8771),
        Airport(id: "MMGL", name: "Guadalajara Intl", city: "Guadalajara", latitude: 20.5218, longitude: -103.3113),
        Airport(id: "MMMY", name: "Monterrey Intl", city: "Monterrey", latitude: 25.7785, longitude: -100.1069),
        Airport(id: "MMSM", name: "San Jose del Cabo Intl", city: "Los Cabos", latitude: 23.1518, longitude: -109.7215),
        Airport(id: "MMPR", name: "Puerto Vallarta Intl", city: "Puerto Vallarta", latitude: 20.6801, longitude: -105.2544),
        Airport(id: "MROC", name: "Juan Santamaria Intl", city: "San Jose", latitude: 9.9939, longitude: -84.2088),
        Airport(id: "MPTO", name: "Tocumen Intl", city: "Panama City", latitude: 9.0714, longitude: -79.3835),
        Airport(id: "MKJP", name: "Norman Manley Intl", city: "Kingston", latitude: 17.9357, longitude: -76.7875),
        Airport(id: "TNCM", name: "Princess Juliana Intl", city: "St. Maarten", latitude: 18.0410, longitude: -63.1089),
        Airport(id: "TBPB", name: "Grantley Adams Intl", city: "Barbados", latitude: 13.0746, longitude: -59.4925),
        Airport(id: "MDPC", name: "Punta Cana Intl", city: "Punta Cana", latitude: 18.5674, longitude: -68.3634),
        // ========== SOUTH AMERICA ==========
        Airport(id: "SBGR", name: "Sao Paulo Guarulhos", city: "Sao Paulo", latitude: -23.4356, longitude: -46.4731),
        Airport(id: "SBGL", name: "Rio Galeao", city: "Rio de Janeiro", latitude: -22.8100, longitude: -43.2506),
        Airport(id: "SCEL", name: "Santiago Intl", city: "Santiago", latitude: -33.3930, longitude: -70.7858),
        Airport(id: "SAEZ", name: "Ezeiza Intl", city: "Buenos Aires", latitude: -34.8222, longitude: -58.5358),
        Airport(id: "SKBO", name: "El Dorado Intl", city: "Bogota", latitude: 4.7016, longitude: -74.1469),
        Airport(id: "SPJC", name: "Jorge Chavez Intl", city: "Lima", latitude: -12.0219, longitude: -77.1143),
        Airport(id: "SEQM", name: "Mariscal Sucre Intl", city: "Quito", latitude: -0.1292, longitude: -78.3575),
        Airport(id: "SVMI", name: "Simon Bolivar Intl", city: "Caracas", latitude: 10.6012, longitude: -66.9912),
        Airport(id: "SUMU", name: "Carrasco Intl", city: "Montevideo", latitude: -34.8384, longitude: -56.0308),
        // ========== UK & IRELAND ==========
        Airport(id: "EGLL", name: "London Heathrow", city: "London", latitude: 51.4700, longitude: -0.4543),
        Airport(id: "EGKK", name: "London Gatwick", city: "London", latitude: 51.1537, longitude: -0.1821),
        Airport(id: "EGSS", name: "London Stansted", city: "London", latitude: 51.8850, longitude: 0.2350),
        Airport(id: "EGLC", name: "London City", city: "London", latitude: 51.5053, longitude: 0.0553),
        Airport(id: "EGGW", name: "London Luton", city: "London", latitude: 51.8747, longitude: -0.3684),
        Airport(id: "EGBB", name: "Birmingham", city: "Birmingham", latitude: 52.4539, longitude: -1.7480),
        Airport(id: "EGCC", name: "Manchester", city: "Manchester", latitude: 53.3537, longitude: -2.2750),
        Airport(id: "EGPH", name: "Edinburgh", city: "Edinburgh", latitude: 55.9500, longitude: -3.3725),
        Airport(id: "EGPF", name: "Glasgow", city: "Glasgow", latitude: 55.8719, longitude: -4.4331),
        Airport(id: "EGGD", name: "Bristol", city: "Bristol", latitude: 51.3827, longitude: -2.7191),
        Airport(id: "EGNX", name: "East Midlands", city: "Nottingham", latitude: 52.8311, longitude: -1.3281),
        Airport(id: "EIDW", name: "Dublin", city: "Dublin", latitude: 53.4213, longitude: -6.2701),
        Airport(id: "EICK", name: "Cork", city: "Cork", latitude: 51.8413, longitude: -8.4911),
        // ========== FRANCE ==========
        Airport(id: "LFPG", name: "Paris Charles de Gaulle", city: "Paris", latitude: 49.0097, longitude: 2.5479),
        Airport(id: "LFPO", name: "Paris Orly", city: "Paris", latitude: 48.7233, longitude: 2.3794),
        Airport(id: "LFML", name: "Marseille Provence", city: "Marseille", latitude: 43.4393, longitude: 5.2214),
        Airport(id: "LFLL", name: "Lyon Saint-Exupery", city: "Lyon", latitude: 45.7256, longitude: 5.0811),
        Airport(id: "LFMN", name: "Nice Cote d'Azur", city: "Nice", latitude: 43.6584, longitude: 7.2159),
        Airport(id: "LFBD", name: "Bordeaux Merignac", city: "Bordeaux", latitude: 44.8283, longitude: -0.7156),
        Airport(id: "LFBO", name: "Toulouse Blagnac", city: "Toulouse", latitude: 43.6291, longitude: 1.3638),
        Airport(id: "LFSB", name: "Basel Mulhouse Freiburg", city: "Basel", latitude: 47.5896, longitude: 7.5299),
        // ========== GERMANY ==========
        Airport(id: "EDDF", name: "Frankfurt Main", city: "Frankfurt", latitude: 50.0379, longitude: 8.5622),
        Airport(id: "EDDM", name: "Munich", city: "Munich", latitude: 48.3538, longitude: 11.7861),
        Airport(id: "EDDB", name: "Berlin Brandenburg", city: "Berlin", latitude: 52.3667, longitude: 13.5033),
        Airport(id: "EDDL", name: "Dusseldorf", city: "Dusseldorf", latitude: 51.2895, longitude: 6.7668),
        Airport(id: "EDDH", name: "Hamburg", city: "Hamburg", latitude: 53.6304, longitude: 9.9882),
        Airport(id: "EDDS", name: "Stuttgart", city: "Stuttgart", latitude: 48.6899, longitude: 9.2220),
        Airport(id: "EDDK", name: "Cologne Bonn", city: "Cologne", latitude: 50.8659, longitude: 7.1427),
        Airport(id: "EDDW", name: "Bremen", city: "Bremen", latitude: 53.0475, longitude: 8.7867),
        Airport(id: "EDDN", name: "Nuremberg", city: "Nuremberg", latitude: 49.4987, longitude: 11.0669),
        Airport(id: "EDDP", name: "Leipzig/Halle", city: "Leipzig", latitude: 51.4324, longitude: 12.2416),
        Airport(id: "EDLW", name: "Dortmund", city: "Dortmund", latitude: 51.5183, longitude: 7.6122),
        // ========== SPAIN ==========
        Airport(id: "LEMD", name: "Madrid Barajas", city: "Madrid", latitude: 40.4936, longitude: -3.5668),
        Airport(id: "LEBL", name: "Barcelona El Prat", city: "Barcelona", latitude: 41.2971, longitude: 2.0785),
        Airport(id: "LEPA", name: "Palma de Mallorca", city: "Palma", latitude: 39.5517, longitude: 2.7388),
        Airport(id: "LEAL", name: "Alicante", city: "Alicante", latitude: 38.2822, longitude: -0.5582),
        Airport(id: "LEMG", name: "Malaga Costa del Sol", city: "Malaga", latitude: 36.6749, longitude: -4.4991),
        Airport(id: "GCTS", name: "Tenerife South", city: "Tenerife", latitude: 28.0445, longitude: -16.5725),
        Airport(id: "GCFV", name: "Fuerteventura", city: "Fuerteventura", latitude: 28.4527, longitude: -13.8638),
        Airport(id: "GCLP", name: "Gran Canaria", city: "Gran Canaria", latitude: 27.9319, longitude: -15.3866),
        Airport(id: "LEZL", name: "Seville San Pablo", city: "Seville", latitude: 37.4180, longitude: -5.8931),
        Airport(id: "LEBB", name: "Bilbao", city: "Bilbao", latitude: 43.3011, longitude: -2.9106),
        Airport(id: "LEVC", name: "Valencia", city: "Valencia", latitude: 39.4893, longitude: -0.4816),
        Airport(id: "GCRR", name: "Lanzarote", city: "Lanzarote", latitude: 28.9455, longitude: -13.6052),
        // ========== ITALY ==========
        Airport(id: "LIRF", name: "Rome Fiumicino", city: "Rome", latitude: 41.8003, longitude: 12.2389),
        Airport(id: "LIMC", name: "Milan Malpensa", city: "Milan", latitude: 45.6306, longitude: 8.7281),
        Airport(id: "LIME", name: "Milan Bergamo", city: "Bergamo", latitude: 45.6739, longitude: 9.7042),
        Airport(id: "LIPZ", name: "Venice Marco Polo", city: "Venice", latitude: 45.5053, longitude: 12.3519),
        Airport(id: "LIPE", name: "Bologna Marconi", city: "Bologna", latitude: 44.5354, longitude: 11.2887),
        Airport(id: "LIRN", name: "Naples Capodichino", city: "Naples", latitude: 40.8860, longitude: 14.2908),
        Airport(id: "LICJ", name: "Palermo Falcone Borsellino", city: "Palermo", latitude: 38.1760, longitude: 13.0910),
        Airport(id: "LICC", name: "Catania Fontanarossa", city: "Catania", latitude: 37.4668, longitude: 15.0664),
        Airport(id: "LIRP", name: "Pisa Galilei", city: "Pisa", latitude: 43.6839, longitude: 10.3927),
        // ========== BENELUX ==========
        Airport(id: "EHAM", name: "Amsterdam Schiphol", city: "Amsterdam", latitude: 52.3086, longitude: 4.7639),
        Airport(id: "EHRD", name: "Rotterdam The Hague", city: "Rotterdam", latitude: 51.9569, longitude: 4.4372),
        Airport(id: "EHEH", name: "Eindhoven", city: "Eindhoven", latitude: 51.4501, longitude: 5.3746),
        Airport(id: "EBBR", name: "Brussels", city: "Brussels", latitude: 50.9014, longitude: 4.4844),
        Airport(id: "ELLX", name: "Luxembourg Findel", city: "Luxembourg", latitude: 49.6233, longitude: 6.2044),
        // ========== SWITZERLAND / AUSTRIA ==========
        Airport(id: "LSZH", name: "Zurich", city: "Zurich", latitude: 47.4647, longitude: 8.5492),
        Airport(id: "LSGG", name: "Geneva", city: "Geneva", latitude: 46.2381, longitude: 6.1089),
        Airport(id: "LOWW", name: "Vienna Schwechat", city: "Vienna", latitude: 48.1103, longitude: 16.5697),
        Airport(id: "LOWS", name: "Salzburg", city: "Salzburg", latitude: 47.7933, longitude: 13.0043),
        Airport(id: "LOWG", name: "Graz", city: "Graz", latitude: 46.9911, longitude: 15.4396),
        Airport(id: "LOWI", name: "Innsbruck", city: "Innsbruck", latitude: 47.2602, longitude: 11.3440),
        // ========== SCANDINAVIA ==========
        Airport(id: "EKCH", name: "Copenhagen Kastrup", city: "Copenhagen", latitude: 55.6181, longitude: 12.6561),
        Airport(id: "ENGM", name: "Oslo Gardermoen", city: "Oslo", latitude: 60.1939, longitude: 11.1004),
        Airport(id: "ENBR", name: "Bergen Flesland", city: "Bergen", latitude: 60.2934, longitude: 5.2181),
        Airport(id: "ESSA", name: "Stockholm Arlanda", city: "Stockholm", latitude: 59.6519, longitude: 17.9186),
        Airport(id: "ESGG", name: "Gothenburg Landvetter", city: "Gothenburg", latitude: 57.6628, longitude: 12.2798),
        Airport(id: "EFHK", name: "Helsinki Vantaa", city: "Helsinki", latitude: 60.3172, longitude: 24.9633),
        Airport(id: "BIKF", name: "Keflavik Intl", city: "Reykjavik", latitude: 63.9850, longitude: -22.6056),
        // ========== EASTERN EUROPE ==========
        Airport(id: "EPWA", name: "Warsaw Chopin", city: "Warsaw", latitude: 52.1657, longitude: 20.9671),
        Airport(id: "EPKK", name: "Krakow Balice", city: "Krakow", latitude: 50.0777, longitude: 19.7848),
        Airport(id: "LKPR", name: "Prague Vaclav Havel", city: "Prague", latitude: 50.1008, longitude: 14.2600),
        Airport(id: "LHBP", name: "Budapest Liszt Ferenc", city: "Budapest", latitude: 47.4369, longitude: 19.2556),
        Airport(id: "LROP", name: "Bucharest Otopeni", city: "Bucharest", latitude: 44.5711, longitude: 26.0850),
        Airport(id: "LWSK", name: "Skopje Intl", city: "Skopje", latitude: 41.9616, longitude: 21.6214),
        Airport(id: "LBSF", name: "Sofia", city: "Sofia", latitude: 42.6952, longitude: 23.4062),
        Airport(id: "LDZA", name: "Zagreb Franjo Tudman", city: "Zagreb", latitude: 45.7429, longitude: 16.0688),
        Airport(id: "LJLJ", name: "Ljubljana Joze Pucnik", city: "Ljubljana", latitude: 46.2237, longitude: 14.4576),
        Airport(id: "LYBE", name: "Belgrade Nikola Tesla", city: "Belgrade", latitude: 44.8184, longitude: 20.3091),
        // ========== PORTUGAL ==========
        Airport(id: "LPPT", name: "Lisbon Portela", city: "Lisbon", latitude: 38.7742, longitude: -9.1342),
        Airport(id: "LPPR", name: "Porto Francisco Sa Carneiro", city: "Porto", latitude: 41.2481, longitude: -8.6814),
        Airport(id: "LPFR", name: "Faro", city: "Faro", latitude: 37.0144, longitude: -7.9659),
        Airport(id: "LPMA", name: "Madeira Cristiano Ronaldo", city: "Funchal", latitude: 32.6942, longitude: -16.7745),
        // ========== GREECE / CYPRUS ==========
        Airport(id: "LGAV", name: "Athens Eleftherios Venizelos", city: "Athens", latitude: 37.9364, longitude: 23.9445),
        Airport(id: "LGTS", name: "Thessaloniki Macedonia", city: "Thessaloniki", latitude: 40.5197, longitude: 22.9709),
        Airport(id: "LGIR", name: "Heraklion Nikos Kazantzakis", city: "Heraklion", latitude: 35.3397, longitude: 25.1803),
        Airport(id: "LGSR", name: "Santorini", city: "Santorini", latitude: 36.3992, longitude: 25.4793),
        Airport(id: "LGMK", name: "Mykonos", city: "Mykonos", latitude: 37.4351, longitude: 25.3481),
        Airport(id: "LGRP", name: "Rhodes Diagoras", city: "Rhodes", latitude: 36.4054, longitude: 28.0862),
        Airport(id: "LGKR", name: "Corfu Ioannis Kapodistrias", city: "Corfu", latitude: 39.6019, longitude: 19.9117),
        Airport(id: "LCLK", name: "Larnaca Intl", city: "Larnaca", latitude: 34.8754, longitude: 33.6249),
        Airport(id: "LCPH", name: "Paphos Intl", city: "Paphos", latitude: 34.7180, longitude: 32.4857),
        // ========== TURKEY ==========
        Airport(id: "LTFM", name: "Istanbul", city: "Istanbul", latitude: 41.2753, longitude: 28.7519),
        Airport(id: "LTFJ", name: "Istanbul Sabiha Gokcen", city: "Istanbul", latitude: 40.8986, longitude: 29.3092),
        Airport(id: "LTAC", name: "Ankara Esenboga", city: "Ankara", latitude: 40.1281, longitude: 32.9951),
        Airport(id: "LTBJ", name: "Izmir Adnan Menderes", city: "Izmir", latitude: 38.2924, longitude: 27.1570),
        Airport(id: "LTAI", name: "Antalya", city: "Antalya", latitude: 36.8987, longitude: 30.8005),
        Airport(id: "LTFE", name: "Dalaman", city: "Dalaman", latitude: 36.7131, longitude: 28.7925),
        Airport(id: "LTBS", name: "Bodrum Milas", city: "Bodrum", latitude: 37.2506, longitude: 27.6643),
        // ========== RUSSIA / CIS ==========
        Airport(id: "UUEE", name: "Moscow Sheremetyevo", city: "Moscow", latitude: 55.9726, longitude: 37.4146),
        Airport(id: "UUDD", name: "Moscow Domodedovo", city: "Moscow", latitude: 55.4088, longitude: 37.9063),
        Airport(id: "UUWW", name: "Moscow Vnukovo", city: "Moscow", latitude: 55.5915, longitude: 37.2615),
        Airport(id: "ULLI", name: "St Petersburg Pulkovo", city: "St Petersburg", latitude: 59.8003, longitude: 30.2625),
        // ========== MIDDLE EAST ==========
        Airport(id: "OMDB", name: "Dubai Intl", city: "Dubai", latitude: 25.2528, longitude: 55.3644),
        Airport(id: "OMDW", name: "Dubai Al Maktoum", city: "Dubai", latitude: 24.8960, longitude: 55.1614),
        Airport(id: "OMAA", name: "Abu Dhabi Intl", city: "Abu Dhabi", latitude: 24.4330, longitude: 54.6511),
        Airport(id: "OTHH", name: "Hamad Intl", city: "Doha", latitude: 25.2731, longitude: 51.6081),
        Airport(id: "OEJN", name: "King Abdulaziz Intl", city: "Jeddah", latitude: 21.6796, longitude: 39.1565),
        Airport(id: "OERK", name: "King Khalid Intl", city: "Riyadh", latitude: 24.9576, longitude: 46.6988),
        Airport(id: "OBBI", name: "Bahrain Intl", city: "Bahrain", latitude: 26.2708, longitude: 50.6336),
        Airport(id: "OOMS", name: "Muscat Intl", city: "Muscat", latitude: 23.5933, longitude: 58.2844),
        Airport(id: "OKBK", name: "Kuwait Intl", city: "Kuwait City", latitude: 29.2266, longitude: 47.9689),
        Airport(id: "OIIE", name: "Tehran Imam Khomeini", city: "Tehran", latitude: 35.4161, longitude: 51.1522),
        Airport(id: "LLBG", name: "Tel Aviv Ben Gurion", city: "Tel Aviv", latitude: 32.0114, longitude: 34.8867),
        Airport(id: "OLBA", name: "Beirut Rafic Hariri", city: "Beirut", latitude: 33.8209, longitude: 35.4884),
        Airport(id: "OJAM", name: "Amman Queen Alia", city: "Amman", latitude: 31.7226, longitude: 35.9932),
        // ========== EAST ASIA ==========
        Airport(id: "RJTT", name: "Tokyo Haneda", city: "Tokyo", latitude: 35.5494, longitude: 139.7798),
        Airport(id: "RJAA", name: "Tokyo Narita", city: "Tokyo", latitude: 35.7720, longitude: 140.3929),
        Airport(id: "RJBB", name: "Osaka Kansai", city: "Osaka", latitude: 34.4347, longitude: 135.2440),
        Airport(id: "RJGG", name: "Nagoya Chubu Centrair", city: "Nagoya", latitude: 34.8584, longitude: 136.8125),
        Airport(id: "RJFF", name: "Fukuoka", city: "Fukuoka", latitude: 33.5859, longitude: 130.4511),
        Airport(id: "RJCC", name: "New Chitose", city: "Sapporo", latitude: 42.7752, longitude: 141.6925),
        Airport(id: "ROAH", name: "Naha", city: "Okinawa", latitude: 26.1958, longitude: 127.6459),
        Airport(id: "RKSI", name: "Incheon Intl", city: "Seoul", latitude: 37.4602, longitude: 126.4407),
        Airport(id: "RKSS", name: "Gimpo Intl", city: "Seoul", latitude: 37.5586, longitude: 126.7906),
        Airport(id: "RKPK", name: "Gimhae Intl", city: "Busan", latitude: 35.1795, longitude: 128.9382),
        Airport(id: "RKPC", name: "Jeju Intl", city: "Jeju", latitude: 33.5113, longitude: 126.4929),
        Airport(id: "ZBAD", name: "Beijing Daxing", city: "Beijing", latitude: 39.5098, longitude: 116.4105),
        Airport(id: "ZBAA", name: "Beijing Capital", city: "Beijing", latitude: 40.0799, longitude: 116.6031),
        Airport(id: "ZSPD", name: "Shanghai Pudong", city: "Shanghai", latitude: 31.1443, longitude: 121.8083),
        Airport(id: "ZSSS", name: "Shanghai Hongqiao", city: "Shanghai", latitude: 31.1979, longitude: 121.3363),
        Airport(id: "ZGGG", name: "Guangzhou Baiyun", city: "Guangzhou", latitude: 23.3924, longitude: 113.2988),
        Airport(id: "ZGSZ", name: "Shenzhen Bao'an", city: "Shenzhen", latitude: 22.6393, longitude: 113.8107),
        Airport(id: "ZUUU", name: "Chengdu Shuangliu", city: "Chengdu", latitude: 30.5785, longitude: 103.9471),
        Airport(id: "ZUCK", name: "Chongqing Jiangbei", city: "Chongqing", latitude: 29.7192, longitude: 106.6417),
        Airport(id: "ZHCC", name: "Zhengzhou Xinzheng", city: "Zhengzhou", latitude: 34.5197, longitude: 113.8409),
        Airport(id: "ZLXY", name: "Xi'an Xianyang", city: "Xi'an", latitude: 34.4471, longitude: 108.7516),
        Airport(id: "ZPPP", name: "Kunming Changshui", city: "Kunming", latitude: 25.1019, longitude: 102.9292),
        Airport(id: "VHHH", name: "Hong Kong Intl", city: "Hong Kong", latitude: 22.3080, longitude: 113.9185),
        Airport(id: "VMMC", name: "Macau Intl", city: "Macau", latitude: 22.1496, longitude: 113.5920),
        Airport(id: "RCTP", name: "Taiwan Taoyuan", city: "Taipei", latitude: 25.0777, longitude: 121.2325),
        Airport(id: "RCSS", name: "Taipei Songshan", city: "Taipei", latitude: 25.0694, longitude: 121.5525),
        // ========== SOUTHEAST ASIA ==========
        Airport(id: "WSSS", name: "Singapore Changi", city: "Singapore", latitude: 1.3502, longitude: 103.9940),
        Airport(id: "VTBS", name: "Suvarnabhumi", city: "Bangkok", latitude: 13.6900, longitude: 100.7501),
        Airport(id: "VTBD", name: "Don Mueang", city: "Bangkok", latitude: 13.9126, longitude: 100.6068),
        Airport(id: "VTSP", name: "Phuket Intl", city: "Phuket", latitude: 8.1132, longitude: 98.3169),
        Airport(id: "VVNB", name: "Noi Bai Intl", city: "Hanoi", latitude: 21.2212, longitude: 105.8070),
        Airport(id: "VVTS", name: "Tan Son Nhat", city: "Ho Chi Minh City", latitude: 10.8188, longitude: 106.6520),
        Airport(id: "WMKK", name: "Kuala Lumpur Intl", city: "Kuala Lumpur", latitude: 2.7456, longitude: 101.7099),
        Airport(id: "WBKK", name: "Kota Kinabalu Intl", city: "Kota Kinabalu", latitude: 5.9372, longitude: 116.0517),
        Airport(id: "RPLL", name: "Ninoy Aquino Intl", city: "Manila", latitude: 14.5086, longitude: 121.0198),
        Airport(id: "RPVM", name: "Mactan Cebu Intl", city: "Cebu", latitude: 10.3075, longitude: 123.9794),
        Airport(id: "WIII", name: "Soekarno-Hatta", city: "Jakarta", latitude: -6.1256, longitude: 106.6559),
        Airport(id: "WADD", name: "Ngurah Rai Intl", city: "Bali", latitude: -8.7482, longitude: 115.1672),
        Airport(id: "VRMM", name: "Velana Intl", city: "Male", latitude: 4.1918, longitude: 73.5291),
        Airport(id: "VCBI", name: "Bandaranaike Intl", city: "Colombo", latitude: 7.1808, longitude: 79.8841),
        Airport(id: "VYYY", name: "Yangon Intl", city: "Yangon", latitude: 16.9073, longitude: 96.1332),
        Airport(id: "VDPP", name: "Phnom Penh Intl", city: "Phnom Penh", latitude: 11.5466, longitude: 104.8441),
        Airport(id: "VLVT", name: "Vientiane Wattay", city: "Vientiane", latitude: 17.9883, longitude: 102.5633),
        // ========== SOUTH ASIA ==========
        Airport(id: "VIDP", name: "Indira Gandhi Intl", city: "Delhi", latitude: 28.5562, longitude: 77.1000),
        Airport(id: "VABB", name: "Chhatrapati Shivaji Intl", city: "Mumbai", latitude: 19.0896, longitude: 72.8656),
        Airport(id: "VOBL", name: "Kempegowda Intl", city: "Bangalore", latitude: 13.1986, longitude: 77.7066),
        Airport(id: "VOMM", name: "Chennai Intl", city: "Chennai", latitude: 12.9941, longitude: 80.1709),
        Airport(id: "VECC", name: "Netaji Subhas Chandra Bose Intl", city: "Kolkata", latitude: 22.6547, longitude: 88.4467),
        Airport(id: "VOCI", name: "Cochin Intl", city: "Kochi", latitude: 10.1520, longitude: 76.4019),
        Airport(id: "VOHS", name: "Rajiv Gandhi Intl", city: "Hyderabad", latitude: 17.2403, longitude: 78.4294),
        Airport(id: "VAAH", name: "Ahmedabad Intl", city: "Ahmedabad", latitude: 23.0772, longitude: 72.6347),
        Airport(id: "VAGO", name: "Goa Manohar Intl", city: "Goa", latitude: 15.3809, longitude: 73.8314),
        Airport(id: "OPKC", name: "Jinnah Intl", city: "Karachi", latitude: 24.9065, longitude: 67.1610),
        Airport(id: "OPRN", name: "Islamabad Intl", city: "Islamabad", latitude: 33.5491, longitude: 72.8276),
        Airport(id: "OPLA", name: "Allama Iqbal Intl", city: "Lahore", latitude: 31.5216, longitude: 74.4036),
        Airport(id: "VGHS", name: "Hazrat Shahjalal Intl", city: "Dhaka", latitude: 23.8433, longitude: 90.3978),
        Airport(id: "VNKT", name: "Tribhuvan Intl", city: "Kathmandu", latitude: 27.6966, longitude: 85.3591),
        // ========== OCEANIA ==========
        Airport(id: "YSSY", name: "Sydney Kingsford Smith", city: "Sydney", latitude: -33.9461, longitude: 151.1772),
        Airport(id: "YMML", name: "Melbourne Tullamarine", city: "Melbourne", latitude: -37.6733, longitude: 144.8433),
        Airport(id: "YBBN", name: "Brisbane", city: "Brisbane", latitude: -27.3842, longitude: 153.1175),
        Airport(id: "YPPH", name: "Perth", city: "Perth", latitude: -31.9403, longitude: 115.9672),
        Airport(id: "YPAD", name: "Adelaide", city: "Adelaide", latitude: -34.9450, longitude: 138.5306),
        Airport(id: "YBCS", name: "Cairns", city: "Cairns", latitude: -16.8858, longitude: 145.7554),
        Airport(id: "YSCB", name: "Canberra", city: "Canberra", latitude: -35.3069, longitude: 149.1951),
        Airport(id: "NZAA", name: "Auckland", city: "Auckland", latitude: -37.0082, longitude: 174.7850),
        Airport(id: "NZWN", name: "Wellington", city: "Wellington", latitude: -41.3272, longitude: 174.8053),
        Airport(id: "NZCH", name: "Christchurch", city: "Christchurch", latitude: -43.4894, longitude: 172.5322),
        Airport(id: "NZQN", name: "Queenstown", city: "Queenstown", latitude: -45.0211, longitude: 168.7392),
        Airport(id: "NFFN", name: "Nadi Intl", city: "Fiji", latitude: -17.7554, longitude: 177.4431),
        // ========== AFRICA ==========
        Airport(id: "FAOR", name: "O.R. Tambo Intl", city: "Johannesburg", latitude: -26.1392, longitude: 28.2460),
        Airport(id: "FACT", name: "Cape Town Intl", city: "Cape Town", latitude: -33.9649, longitude: 18.6017),
        Airport(id: "FALE", name: "King Shaka Intl", city: "Durban", latitude: -29.6144, longitude: 31.1197),
        Airport(id: "HECA", name: "Cairo Intl", city: "Cairo", latitude: 30.1219, longitude: 31.4056),
        Airport(id: "HEGN", name: "Hurghada Intl", city: "Hurghada", latitude: 27.1783, longitude: 33.7994),
        Airport(id: "HESH", name: "Sharm El Sheikh Intl", city: "Sharm El Sheikh", latitude: 27.9773, longitude: 34.3950),
        Airport(id: "GMMN", name: "Mohammed V Intl", city: "Casablanca", latitude: 33.3675, longitude: -7.5900),
        Airport(id: "GMME", name: "Rabat Sale", city: "Rabat", latitude: 34.0515, longitude: -6.7515),
        Airport(id: "GMMX", name: "Marrakech Menara", city: "Marrakech", latitude: 31.6069, longitude: -8.0363),
        Airport(id: "DTTA", name: "Tunis Carthage", city: "Tunis", latitude: 36.8510, longitude: 10.2272),
        Airport(id: "DAAG", name: "Algiers Houari Boumediene", city: "Algiers", latitude: 36.6910, longitude: 3.2154),
        Airport(id: "HKJK", name: "Jomo Kenyatta Intl", city: "Nairobi", latitude: -1.3192, longitude: 36.9278),
        Airport(id: "HAAB", name: "Addis Ababa Bole", city: "Addis Ababa", latitude: 8.9779, longitude: 38.7993),
        Airport(id: "DNMM", name: "Murtala Muhammed Intl", city: "Lagos", latitude: 6.5774, longitude: 3.3211),
        Airport(id: "DGAA", name: "Kotoka Intl", city: "Accra", latitude: 5.6052, longitude: -0.1668),
        Airport(id: "HTDA", name: "Julius Nyerere Intl", city: "Dar es Salaam", latitude: -6.8781, longitude: 39.2026),
        Airport(id: "FMEE", name: "Sir Seewoosagur Ramgoolam", city: "Mauritius", latitude: -20.4302, longitude: 57.6836),
        Airport(id: "FMCH", name: "Prince Said Ibrahim", city: "Moroni", latitude: -11.5337, longitude: 43.2718),
    ]
}
