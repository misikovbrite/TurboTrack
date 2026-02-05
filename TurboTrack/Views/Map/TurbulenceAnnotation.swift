import SwiftUI

struct TurbulenceAnnotation: View {
    let severity: TurbulenceSeverity

    var body: some View {
        ZStack {
            Circle()
                .fill(severity.color.opacity(0.3))
                .frame(width: 28, height: 28)

            Circle()
                .fill(severity.color)
                .frame(width: 16, height: 16)

            Circle()
                .strokeBorder(.white, lineWidth: 2)
                .frame(width: 16, height: 16)
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        TurbulenceAnnotation(severity: .light)
        TurbulenceAnnotation(severity: .moderate)
        TurbulenceAnnotation(severity: .severe)
        TurbulenceAnnotation(severity: .extreme)
    }
    .padding()
    .background(.gray.opacity(0.3))
}
