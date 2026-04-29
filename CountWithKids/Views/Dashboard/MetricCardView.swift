import SwiftUI

struct MetricCardView: View {
    @Environment(\.appTheme) var theme
    let title: String
    let value: String
    let subtitle: String
    let chartData: [ChartBucket]
    let chartColor: Color
    let chartUnit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .playfulFont(.footnote, weight: .medium)
                        .foregroundColor(.secondary)

                    Text(value)
                        .playfulFont(.title)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .playfulFont(.caption2, weight: .regular)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            BarChartView(data: chartData, color: chartColor, unit: chartUnit)
        }
        .padding()
        .clayCard(cornerRadius: 22, elevation: .resting)
    }
}
