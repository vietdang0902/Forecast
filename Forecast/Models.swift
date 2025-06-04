
//  Created by VietMac
//

import Foundation
import SwiftUI

struct Weather: Codable {
    var location: Location
    var forecast: Forecast
    var current: Current
}

struct Current: Codable {
    var temp_c: Double
    var condition: Condition
}

struct Location: Codable {
    var name: String
}

struct Forecast: Codable {
    var forecastday: [ForecastDay]
}

struct ForecastDay: Codable, Identifiable {
    var date_epoch: Int
    var hour: [Hour]
    var id: Int {date_epoch}
    var day: Day
}

struct Day: Codable {
    var avgtemp_c: Double
    var maxwind_kph: Double
    var totalprecip_mm: Double
    var daily_chance_of_rain: Int
    var avghumidity: Int
    var uv: Double
    var avgvis_km: Double
    var condition: Condition
}

struct Condition: Codable {
    var text: String
    var code: Int
}

struct Hour: Codable, Identifiable {
    var time_epoch: Int
    var time: String
    var temp_c: Double
    var feelslike_c: Double
    var condition: Condition
    var id: Int { time_epoch }
}
