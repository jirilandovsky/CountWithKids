import SwiftUI
import Charts

struct BarChartView: View {
    let data: [ChartBucket]
    let color: Color
    let unit: String

    var body: some View {
        if data.isEmpty || data.allSatisfy({ $0.value == 0 }) {
            Text(loc("No data yet"))
                .playfulFont(size: 14, weight: .regular)
                .foregroundColor(.secondary)
                .frame(height: 120)
                .frame(maxWidth: .infinity)
        } else {
            Chart(data) { bucket in
                BarMark(
                    x: .value("Period", bucket.label),
                    y: .value(unit, bucket.value)
                )
                .foregroundStyle(color.gradient)
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel()
                        .font(.system(size: 10, design: .rounded))
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .font(.system(size: 10, design: .rounded))
                }
            }
            .frame(height: 120)
        }
    }
}
