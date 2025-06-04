//
//  ContentView.swift
//  Forecast
//
//  Created by VietMac on 4/6/25.
//

import Alamofire
import SwiftUI

struct ContentView: View {
    @State private var results = [ForecastDay]()
    @State var hourlyForecast = [Hour]()
    @State var query: String = ""
    @State var contentSize: CGSize = .zero
    @State var textFieldHeight = 15.0

    @State var backgroundColor = Color(red: 135 / 255, green: 206 / 255, blue: 235 / 255)
    @State var weatherEmoji = "☀️"
    @State var currentTemp = 0
    @State var conditionText = "Sightly Overcast"
    @State var cityName = "Toronto"
    @State var loading = true

    var body: some View {
        if loading {
            ZStack {
                Color(backgroundColor)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(2, anchor: .center)
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .task {
                        await fetchWeather(query: "")
                    }
            }
        } else {
            NavigationView {
                VStack {
                    Spacer()
                    TextField("Enter city name or postal code", text: $query, onEditingChanged: getFocus)
                        .textFieldStyle(PlainTextFieldStyle())
                        .background(
                            Rectangle()
                                .foregroundColor(.white.opacity(0.2))
                                .cornerRadius(25)
                                .frame(height: 50)
                        )
                        .padding(.leading, 40)
                        .padding(.trailing, 40)
                        .padding(.bottom, 15)
                        .padding(.top, textFieldHeight)
                        .multilineTextAlignment(.center)
                        .accentColor(.white)
                        .font(Font.system(size: 20, design: .default))
                        .onSubmit {
                            Task {
                                await fetchWeather(query: query)
                            }
                            withAnimation {
                                textFieldHeight = 15
                            }
                        }

                    Text("\(cityName)")
                        .font(.system(size: 35))
                        .foregroundColor(.white)
                        .bold()
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 2)
                        .padding(.bottom, 1)
                    Text("\(Date().formatted(date: .complete, time: .omitted))")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 2)
                    Text(weatherEmoji)
                        .font(.system(size: 70))
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 2)
                    Text("\(currentTemp)°C")
                        .font(.system(size: 70))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 2)
                    Text("\(conditionText)")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 2)
                    Spacer()
                    Spacer()
                    Spacer()
                    // Hourly Forecast
                    Text("Hourly Forecast")
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 2)
                        .bold()
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                Spacer(minLength: 10)
                                ForEach(hourlyForecast) { forecast in
                                    VStack(spacing: 4) {
                                        if isCurrentHour(forecastTime: forecast.time, cityName: cityName) {
                                            Text("🔻")
                                                .font(.system(size: 20))
                                                .foregroundColor(.red)
                                        } else {
                                            Text(" ")
                                                .frame(height: 24)
                                        }

                                        Text(getShortTime(time: forecast.time))
                                            .shadow(color: .black.opacity(0.2), radius: 1)

                                        Text(getWeatherEmoji(code: forecast.condition.code))
                                            .shadow(color: .black.opacity(0.2), radius: 1)
                                        Text("\(Int(forecast.temp_c))°C")
                                            .shadow(color: .black.opacity(0.2), radius: 1)
                                    }
                                    .frame(width: 50, height: 90)
                                    .id(forecast.time)
                                }
                                Spacer(minLength: 10)
                            }
                        }
                        .onAppear {
                            if let currentForecast = hourlyForecast.first(where: { isCurrentHour(forecastTime: $0.time, cityName: cityName) }) {
                                withAnimation {
                                    proxy.scrollTo(currentForecast.time, anchor: .center)
                                }
                            }
                        }
                    }
                    .padding()

                    Text("3 Day Forecast")
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .bold()
                        .padding(.top, 12)
                    List {
                        ForEach(Array(results.enumerated()), id: \.1.id) { index, forecast in
                            NavigationLink {
                                WeatherDetails(results: $results, cityName: $cityName, index: index)
                            } label: {
                                HStack(alignment: .center) {
                                    Text("\(getShortDate(epoch: forecast.date_epoch))")
                                        .frame(maxWidth: 50, alignment: .leading)
                                        .bold()
                                    Text("\(getWeatherEmoji(code: forecast.day.condition.code))")
                                        .frame(maxWidth: 30, alignment: .leading)
                                    Text("\(Int(forecast.day.avgtemp_c))°C")
                                        .frame(maxWidth: 50, alignment: .leading)
                                    Spacer()
                                    Text("\(forecast.day.condition.text)")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 2)
                                }
                            }
                        }
                        .listRowBackground(Color.white.blur(radius: 75).opacity(0.5))
                    }
                    .contentMargins(.vertical, 0)
                    .scrollContentBackground(.hidden)
                    .preferredColorScheme(.dark)
                    Spacer()
                    Text("Data supplied by Weather API")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                .background(backgroundColor)
            }
            .accentColor(.white)
        }
    }

    func getFocus(focused: Bool) {
        withAnimation {
            textFieldHeight = 130
        }
    }

    func timeZoneIdentifier(for cityName: String) -> String {
        switch cityName.lowercased() {
        case "london": return "Europe/London"
        case "new york": return "America/New_York"
        case "tokyo": return "Asia/Tokyo"
        case "paris": return "Europe/Paris"
        case "toronto": return "America/Toronto"
        default: return TimeZone.current.identifier
        }
    }

    func isCurrentHour(forecastTime: String, cityName: String) -> Bool {
        let timeZoneID = timeZoneIdentifier(for: cityName)
        guard let cityTimeZone = TimeZone(identifier: timeZoneID) else { return false }

        let formatter = DateFormatter()
        formatter.timeZone = cityTimeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        guard let forecastDate = formatter.date(from: forecastTime) else { return false }

        let now = Date()
        let calendar = Calendar.current

        let nowComponents = calendar.dateComponents(in: cityTimeZone, from: now)
        let forecastComponents = calendar.dateComponents(in: cityTimeZone, from: forecastDate)

        return nowComponents.hour == forecastComponents.hour
    }

    func fetchWeather(query: String) async {
        let queryText: String
        if query.isEmpty {
            queryText = "http://api.weatherapi.com/v1/forecast.json?key=8173cebed5f24336b0a124608250206&q=London&days=3&aqi=no&alerts=no"
        } else {
            queryText = "http://api.weatherapi.com/v1/forecast.json?key=8173cebed5f24336b0a124608250206&q=\(query)&days=3&aqi=no&alerts=no"
        }

        await withCheckedContinuation { continuation in
            AF.request(queryText).responseDecodable(of: Weather.self) { response in
                switch response.result {
                case let .success(weather):
                    DispatchQueue.main.async {
                        cityName = weather.location.name
                        results = weather.forecast.forecastday

                        var index = 0
                        // Find today or tomorrow forecast index
                        if Date(timeIntervalSince1970: TimeInterval(results[0].date_epoch)).formatted(.dateTime.weekday(.abbreviated)) != Date().formatted(.dateTime.weekday(.abbreviated)) {
                            index = 1
                        }

                        currentTemp = Int(weather.current.temp_c)
                        hourlyForecast = results[index].hour
                        backgroundColor = getBackgroundColor(code: weather.current.condition.code)
                        weatherEmoji = getWeatherEmoji(code: weather.current.condition.code)
                        conditionText = weather.current.condition.text
                        loading = false
                    }
                    continuation.resume()
                case let .failure(error):
                    print("Fetch error:", error)
                    continuation.resume()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
