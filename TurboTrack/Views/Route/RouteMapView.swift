import SwiftUI
import MapKit

struct RouteMapView: View {
    @ObservedObject var viewModel: RouteViewModel

    var body: some View {
        Map(position: $viewModel.cameraPosition) {
            // Route line
            if viewModel.routePolyline.count >= 2 {
                MapPolyline(coordinates: viewModel.routePolyline)
                    .stroke(.blue, lineWidth: 3)
            }

            // Departure airport
            if let dep = viewModel.departureAirport {
                Annotation(dep.icao, coordinate: dep.coordinate) {
                    VStack(spacing: 2) {
                        Image(systemName: "airplane.departure")
                            .font(.title3)
                            .foregroundColor(.blue)
                        Text(dep.icao)
                            .font(.caption2.bold())
                            .foregroundColor(.blue)
                    }
                }
            }

            // Arrival airport
            if let arr = viewModel.arrivalAirport {
                Annotation(arr.icao, coordinate: arr.coordinate) {
                    VStack(spacing: 2) {
                        Image(systemName: "airplane.arrival")
                            .font(.title3)
                            .foregroundColor(.blue)
                        Text(arr.icao)
                            .font(.caption2.bold())
                            .foregroundColor(.blue)
                    }
                }
            }

            // Forecast turbulence points along route
            ForEach(viewModel.forecastMapPoints) { point in
                Annotation(
                    point.severity.displayName,
                    coordinate: point.coordinate,
                    anchor: .center
                ) {
                    TurbulenceAnnotation(severity: point.severity)
                }
            }

            // Current PIREP points (shown alongside forecast)
            ForEach(viewModel.routePireps) { report in
                if let coord = report.coordinate {
                    Annotation(
                        report.severity.displayName,
                        coordinate: coord,
                        anchor: .center
                    ) {
                        TurbulenceAnnotation(severity: report.severity)
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }
}

#Preview {
    RouteMapView(viewModel: RouteViewModel())
}
