import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stronger/UI/widgets/average_weight.dart';
import 'package:stronger/UI/widgets/body_composition_chart.dart';
import 'package:stronger/UI/widgets/volume_chart.dart';
import 'package:stronger/models/measurement.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: SizedBox(width: 600, height: 500, child: child)),
  );

  testWidgets('volume and average charts expose a clear empty state', (
    tester,
  ) async {
    await tester.pumpWidget(host(const VolumenChart(data: [])));
    expect(find.text('No hay datos suficientes'), findsOneWidget);

    await tester.pumpWidget(host(const AverageWeightChart(data: [])));
    expect(find.text('No hay datos suficientes'), findsOneWidget);
  });

  testWidgets('volume chart sorts data and creates one spot per value', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        VolumenChart(
          data: [
            {'date': DateTime(2026, 1, 2), 'volume': 200.0},
            {'date': DateTime(2026, 1, 1), 'volume': 100.0},
          ],
        ),
      ),
    );

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData.single.spots.map((spot) => spot.y), [
      100,
      200,
    ]);
  });

  testWidgets('body composition switches values and colors by metric', (
    tester,
  ) async {
    final measurements = [
      Measurement(
        weight: 80,
        fat: 20,
        muscle: 60,
        date: DateTime(2026, 1, 1),
      ),
    ];
    await tester.pumpWidget(
      host(BodyCompositionChart(measurements: measurements)),
    );

    LineChart chart() => tester.widget<LineChart>(find.byType(LineChart));
    expect(chart().data.lineBarsData.single.spots.single.y, 80);
    expect(chart().data.lineBarsData.single.color, Colors.blue);

    await tester.tap(find.text('Grasa (%)'));
    await tester.pump();
    expect(chart().data.lineBarsData.single.spots.single.y, 20);
    expect(chart().data.lineBarsData.single.color, Colors.red);

    await tester.tap(find.text('Músculo (kg)'));
    await tester.pump();
    expect(chart().data.lineBarsData.single.spots.single.y, 60);
    expect(chart().data.lineBarsData.single.color, Colors.green);
  });
}
