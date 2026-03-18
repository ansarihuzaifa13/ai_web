import '../domain/portal_models.dart';

class MockPortalData {
  const MockPortalData._();

  static List<PredictionRow> predictionRows(ModelType type) {
    final offset = switch (type) {
      ModelType.champion => 0.00,
      ModelType.challengerBh => 0.08,
      ModelType.challengerNtc => -0.04,
    };

    return List<PredictionRow>.generate(8, (int index) {
      final base = 0.22 + (index * 0.09) + offset;
      final probability = base.clamp(0.02, 0.98);
      return PredictionRow(
        userId: 'T000${8070622041807 + (index * 101223)}',
        prediction: probability >= 0.5 ? 1 : 0,
        predictionProbability: probability,
        actual: index.isEven ? 0 : 1,
      );
    });
  }

  static List<MetricValue> predictionSummary(ModelType type) {
    return switch (type) {
      ModelType.champion => const <MetricValue>[
          MetricValue(label: 'Total Users', value: '247,760'),
          MetricValue(label: 'Prediction Total', value: '70,700'),
          MetricValue(label: 'Actual Total', value: '82,221'),
          MetricValue(label: 'Real Conversion %', value: '33.19%'),
          MetricValue(label: 'Predicted Conversion %', value: '28.54%'),
        ],
      ModelType.challengerBh => const <MetricValue>[
          MetricValue(label: 'Total Users', value: '247,760'),
          MetricValue(
            label: 'Prediction Total',
            value: '85,120',
            highlight: true,
          ),
          MetricValue(label: 'Actual Total', value: '82,221'),
          MetricValue(label: 'Real Conversion %', value: '33.19%'),
          MetricValue(
            label: 'Predicted Conversion %',
            value: '34.36%',
            highlight: true,
          ),
        ],
      ModelType.challengerNtc => const <MetricValue>[
          MetricValue(label: 'Total Users', value: '247,760'),
          MetricValue(label: 'Prediction Total', value: '61,430'),
          MetricValue(label: 'Actual Total', value: '82,221'),
          MetricValue(label: 'Real Conversion %', value: '33.19%'),
          MetricValue(label: 'Predicted Conversion %', value: '24.79%'),
        ],
    };
  }

  static List<CombinedPredictionRow> combinedRows() {
    return const <CombinedPredictionRow>[
      CombinedPredictionRow(
        agreementNo: 'T0000207622041807',
        actualOutcome: 0.0,
        championProbability: 0.53,
        championPrediction: 1,
        challengerProbability: 0.20,
        challengerPrediction: 0,
      ),
      CombinedPredictionRow(
        agreementNo: 'T00008010425053053',
        actualOutcome: 0.0,
        championProbability: 0.39,
        championPrediction: 0,
        challengerProbability: 0.80,
        challengerPrediction: 1,
      ),
      CombinedPredictionRow(
        agreementNo: 'T00008020124030803',
        actualOutcome: 0.0,
        championProbability: 0.94,
        championPrediction: 1,
        challengerProbability: 0.73,
        challengerPrediction: 1,
      ),
      CombinedPredictionRow(
        agreementNo: 'T00008020125051957',
        actualOutcome: 1.0,
        championProbability: 0.08,
        championPrediction: 0,
        challengerProbability: 0.50,
        challengerPrediction: 0,
      ),
      CombinedPredictionRow(
        agreementNo: 'T00008020323114700',
        actualOutcome: 1.0,
        championProbability: 0.06,
        championPrediction: 0,
        challengerProbability: 0.50,
        challengerPrediction: 0,
      ),
    ];
  }

  static List<ComparisonMetricRow> comparisonMetrics() {
    return const <ComparisonMetricRow>[
      ComparisonMetricRow(metric: 'AUC', champion: 0.5164, challenger: 0.6522),
      ComparisonMetricRow(metric: 'Gini', champion: 0.0328, challenger: 0.3044),
      ComparisonMetricRow(metric: 'Recall', champion: 0.2788, challenger: 0.5142),
      ComparisonMetricRow(metric: 'Precision', champion: 0.2509, challenger: 0.3657),
      ComparisonMetricRow(metric: 'F1 Score', champion: 0.2641, challenger: 0.4274),
      ComparisonMetricRow(metric: 'Lift', champion: 0.9720, challenger: 1.4680),
      ComparisonMetricRow(
        metric: '(Mean of Means) Top Rate',
        champion: 0.2515,
        challenger: 0.3799,
      ),
    ];
  }

  static List<StatisticalSummaryRow> statisticalSummary(
    Set<StatisticalTest> tests,
  ) {
    const source = <StatisticalTest, StatisticalSummaryRow>{
      StatisticalTest.zTest: StatisticalSummaryRow(
        testName: 'Z-Test',
        parameter: 'Positive rate within a specific group',
        pValue: 0.0000,
        status: 'Reject Null Hypothesis',
        comment: 'Challenger is significantly better',
      ),
      StatisticalTest.tTest: StatisticalSummaryRow(
        testName: 'T-Test',
        parameter: 'Mean of predicted probabilities',
        pValue: 0.0000,
        status: 'Reject Null Hypothesis',
        comment: 'Challenger is significantly better',
      ),
      StatisticalTest.fTest: StatisticalSummaryRow(
        testName: 'F-Test',
        parameter: 'Variance of predicted probabilities',
        pValue: 0.0000,
        status: 'Reject Null Hypothesis',
        comment: 'Challenger is significantly better',
      ),
      StatisticalTest.ksTest: StatisticalSummaryRow(
        testName: 'KS-Test',
        parameter: 'Distribution equality',
        pValue: 0.0000,
        status: 'Reject Null Hypothesis',
        comment: 'Challenger is significantly better',
      ),
      StatisticalTest.deLong: StatisticalSummaryRow(
        testName: 'DeLong / Bootstrap AUC',
        parameter: 'AUC equality',
        pValue: 0.0010,
        status: 'Reject Null Hypothesis',
        comment: 'Challenger is significantly better',
      ),
      StatisticalTest.mcNemar: StatisticalSummaryRow(
        testName: 'McNemar Test',
        parameter: 'Discordant pair equality',
        pValue: 0.0000,
        status: 'Reject Null Hypothesis',
        comment: 'Challenger is significantly better',
      ),
    };

    return tests.map((StatisticalTest test) => source[test]!).toList();
  }

  static List<MetricValue> dashboardSummary() {
    return const <MetricValue>[
      MetricValue(label: 'Total Runs', value: '1,240'),
      MetricValue(label: 'Average Accuracy', value: '89%', highlight: true),
      MetricValue(label: 'Models Used', value: '3'),
    ];
  }

  static List<DashboardActivityRow> recentActivities() {
    return const <DashboardActivityRow>[
      DashboardActivityRow(
        userId: 'U123',
        model: 'Champion',
        result: 'Success',
        date: 'Today',
        success: true,
      ),
      DashboardActivityRow(
        userId: 'U456',
        model: 'BH',
        result: 'Failed',
        date: 'Yesterday',
        success: false,
      ),
      DashboardActivityRow(
        userId: 'U789',
        model: 'NTC',
        result: 'Success',
        date: '06/12/2024',
        success: true,
      ),
    ];
  }
}
