import UIKit

struct PDFReportGenerator {

    static func generate(from viewModel: RouteViewModel) -> Data {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - margin * 2

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        return renderer.pdfData { context in
            var yOffset: CGFloat = 0

            func startNewPage() {
                context.beginPage()
                yOffset = margin
            }

            func ensureSpace(_ needed: CGFloat) {
                if yOffset + needed > pageHeight - margin {
                    startNewPage()
                }
            }

            func drawText(_ text: String, font: UIFont, color: UIColor = .black, maxWidth: CGFloat = contentWidth) -> CGFloat {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 2
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraphStyle
                ]
                let attrStr = NSAttributedString(string: text, attributes: attrs)
                let boundingRect = attrStr.boundingRect(
                    with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                )
                attrStr.draw(in: CGRect(x: margin, y: yOffset, width: maxWidth, height: boundingRect.height))
                let height = ceil(boundingRect.height)
                yOffset += height
                return height
            }

            func drawSeverityCircle(color: UIColor, x: CGFloat, y: CGFloat, radius: CGFloat) {
                let path = UIBezierPath(ovalIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
                color.setFill()
                path.fill()
            }

            func drawDivider() {
                ensureSpace(16)
                let path = UIBezierPath()
                path.move(to: CGPoint(x: margin, y: yOffset + 8))
                path.addLine(to: CGPoint(x: pageWidth - margin, y: yOffset + 8))
                UIColor.lightGray.setStroke()
                path.lineWidth = 0.5
                path.stroke()
                yOffset += 16
            }

            // === PAGE 1 ===
            startNewPage()

            // Title
            _ = drawText("Turbulence Forecast Report", font: .boldSystemFont(ofSize: 22))
            yOffset += 4
            _ = drawText(viewModel.routeTitle, font: .systemFont(ofSize: 16), color: .darkGray)
            yOffset += 2
            _ = drawText(viewModel.forecastHorizonText, font: .systemFont(ofSize: 13), color: .gray)
            yOffset += 4

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            _ = drawText("Generated: \(dateFormatter.string(from: Date()))", font: .systemFont(ofSize: 11), color: .gray)
            yOffset += 12

            // Severity Banner
            let advice = viewModel.forecastAdvice
            let severityColor = uiColor(for: viewModel.forecastSeverity)

            ensureSpace(60)
            let bannerRect = CGRect(x: margin, y: yOffset, width: contentWidth, height: 50)
            let bannerPath = UIBezierPath(roundedRect: bannerRect, cornerRadius: 8)
            severityColor.setFill()
            bannerPath.fill()

            let bannerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.white
            ]
            let bannerStr = NSAttributedString(string: advice.title, attributes: bannerAttrs)
            bannerStr.draw(at: CGPoint(x: margin + 16, y: yOffset + 15))
            yOffset += 60

            // Advisory
            yOffset += 8
            ensureSpace(60)
            _ = drawText("Passenger Advisory", font: .boldSystemFont(ofSize: 14), color: .darkGray)
            yOffset += 4
            _ = drawText(advice.detail, font: .systemFont(ofSize: 12), color: .darkGray)
            yOffset += 8

            // Per-leg breakdown (connecting only)
            if viewModel.isConnecting {
                drawDivider()
                ensureSpace(80)
                _ = drawText("Per-Leg Breakdown", font: .boldSystemFont(ofSize: 14), color: .darkGray)
                yOffset += 6

                let leg1Color = uiColor(for: viewModel.leg1Severity)
                let leg2Color = uiColor(for: viewModel.leg2Severity)

                // Leg 1
                drawSeverityCircle(color: leg1Color, x: margin + 6, y: yOffset + 7, radius: 5)
                let leg1Attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.darkGray
                ]
                let leg1Str = NSAttributedString(string: "Leg 1: \(viewModel.leg1Title) — \(viewModel.leg1Severity.displayName)", attributes: leg1Attrs)
                leg1Str.draw(at: CGPoint(x: margin + 18, y: yOffset))
                yOffset += 20

                // Leg 2
                drawSeverityCircle(color: leg2Color, x: margin + 6, y: yOffset + 7, radius: 5)
                let leg2Str = NSAttributedString(string: "Leg 2: \(viewModel.leg2Title) — \(viewModel.leg2Severity.displayName)", attributes: leg1Attrs)
                leg2Str.draw(at: CGPoint(x: margin + 18, y: yOffset))
                yOffset += 20
            }

            // Daily Forecast
            let dailyForecast = viewModel.dailyForecast
            if !dailyForecast.isEmpty {
                drawDivider()
                ensureSpace(30)
                _ = drawText("Daily Forecast", font: .boldSystemFont(ofSize: 14), color: .darkGray)
                yOffset += 6

                let dayFormatter = DateFormatter()
                dayFormatter.dateFormat = "EEEE, MMM d"

                for day in dailyForecast {
                    ensureSpace(22)
                    let calendar = Calendar.current
                    let label: String
                    if calendar.isDateInToday(day.date) {
                        label = "Today"
                    } else if calendar.isDateInTomorrow(day.date) {
                        label = "Tomorrow"
                    } else {
                        label = dayFormatter.string(from: day.date)
                    }

                    let dayColor = uiColor(for: day.worst)
                    drawSeverityCircle(color: dayColor, x: margin + 6, y: yOffset + 7, radius: 4)

                    let dayAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 12),
                        .foregroundColor: UIColor.darkGray
                    ]
                    let dayStr = NSAttributedString(string: "\(label): \(day.worst.displayName)", attributes: dayAttrs)
                    dayStr.draw(at: CGPoint(x: margin + 18, y: yOffset))
                    yOffset += 20
                }
            }

            // Flight Level Breakdown
            let levels = viewModel.flightLevelBreakdown
            if !levels.isEmpty {
                drawDivider()
                ensureSpace(30)
                _ = drawText("Flight Level Breakdown", font: .boldSystemFont(ofSize: 14), color: .darkGray)
                yOffset += 6

                // Header row
                let headerAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 10),
                    .foregroundColor: UIColor.gray
                ]
                NSAttributedString(string: "FL", attributes: headerAttrs).draw(at: CGPoint(x: margin, y: yOffset))
                NSAttributedString(string: "Severity", attributes: headerAttrs).draw(at: CGPoint(x: margin + 60, y: yOffset))
                NSAttributedString(string: "Shear (kt/kft)", attributes: headerAttrs).draw(at: CGPoint(x: margin + 160, y: yOffset))
                NSAttributedString(string: "Jet (kt)", attributes: headerAttrs).draw(at: CGPoint(x: margin + 300, y: yOffset))
                yOffset += 18

                let rowAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedSystemFont(ofSize: 11, weight: .regular),
                    .foregroundColor: UIColor.darkGray
                ]

                for level in levels {
                    ensureSpace(20)
                    let lvlColor = uiColor(for: level.severity)
                    drawSeverityCircle(color: lvlColor, x: margin + 48, y: yOffset + 7, radius: 3)

                    NSAttributedString(string: "FL\(level.level)", attributes: rowAttrs).draw(at: CGPoint(x: margin, y: yOffset))
                    NSAttributedString(string: level.severity.displayName, attributes: rowAttrs).draw(at: CGPoint(x: margin + 60, y: yOffset))
                    NSAttributedString(string: String(format: "%.1f", level.avgShear), attributes: rowAttrs).draw(at: CGPoint(x: margin + 160, y: yOffset))
                    if level.maxJet > 0 {
                        NSAttributedString(string: "\(Int(level.maxJet))", attributes: rowAttrs).draw(at: CGPoint(x: margin + 300, y: yOffset))
                    }
                    yOffset += 18
                }
            }

            // PIREPs Summary
            drawDivider()
            ensureSpace(40)
            _ = drawText("Pilot Reports (PIREPs)", font: .boldSystemFont(ofSize: 14), color: .darkGray)
            yOffset += 4
            _ = drawText(viewModel.pirepSummary, font: .systemFont(ofSize: 12), color: .darkGray)
            yOffset += 8

            // Safety Tips
            drawDivider()
            ensureSpace(30)
            _ = drawText("Safety Tips", font: .boldSystemFont(ofSize: 14), color: .darkGray)
            yOffset += 6

            let tips = tipsForSeverity(viewModel.forecastSeverity)
            for tip in tips {
                ensureSpace(30)
                _ = drawText("• \(tip)", font: .systemFont(ofSize: 12), color: .darkGray)
                yOffset += 4
            }

            // Disclaimer
            yOffset += 12
            ensureSpace(60)
            drawDivider()
            _ = drawText(
                "Disclaimer: This forecast is for informational purposes only. Turbulence predictions are based on atmospheric wind data and may not reflect actual conditions. Always follow crew instructions and official aviation weather briefings.",
                font: .italicSystemFont(ofSize: 9),
                color: .gray
            )
            yOffset += 8
            _ = drawText("Generated by Turbulence Forecast App", font: .systemFont(ofSize: 9), color: .lightGray)
        }
    }

    private static func uiColor(for severity: TurbulenceSeverity) -> UIColor {
        switch severity {
        case .none: return UIColor.systemGreen
        case .light: return UIColor.systemYellow
        case .moderate: return UIColor.systemOrange
        case .severe, .extreme: return UIColor.systemRed
        }
    }

    private static func tipsForSeverity(_ severity: TurbulenceSeverity) -> [String] {
        var tips = [
            "Keep your seatbelt fastened when seated",
            "Secure loose items in overhead bins or under seat",
            "Follow crew instructions at all times",
        ]
        switch severity {
        case .moderate:
            tips.append("Avoid hot drinks during expected turbulence")
        case .severe, .extreme:
            tips.append("Avoid hot drinks during expected turbulence")
            tips.append("Return to your seat during severe turbulence")
            tips.append("Check on children and elderly passengers")
        default:
            break
        }
        return tips
    }
}
