enum WorkspaceSection { dashboard, prediction, comparison, reports }

enum PredictionSubtab { prediction, combineResults }

enum ModelType { champion, challengerBh, challengerNtc }

enum InputMode { upload, defaultFile }

enum StatisticalTest {
  zTest,
  tTest,
  fTest,
  ksTest,
  deLong,
  mcNemar,
}

class PredictionRow {
  const PredictionRow({
    required this.userId,
    required this.prediction,
    required this.predictionProbability,
    required this.actual,
  });

  final String userId;
  final int prediction;
  final double predictionProbability;
  final double actual;
}

class MetricValue {
  const MetricValue({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;
}

class CombinedPredictionRow {
  const CombinedPredictionRow({
    required this.agreementNo,
    required this.actualOutcome,
    required this.championProbability,
    required this.championPrediction,
    required this.challengerProbability,
    required this.challengerPrediction,
  });

  final String agreementNo;
  final double actualOutcome;
  final double championProbability;
  final int championPrediction;
  final double challengerProbability;
  final int challengerPrediction;
}

class ComparisonMetricRow {
  const ComparisonMetricRow({
    required this.metric,
    required this.champion,
    required this.challenger,
  });

  final String metric;
  final double champion;
  final double challenger;
}

class StatisticalSummaryRow {
  const StatisticalSummaryRow({
    required this.testName,
    required this.parameter,
    required this.pValue,
    required this.status,
    required this.comment,
  });

  final String testName;
  final String parameter;
  final double pValue;
  final String status;
  final String comment;
}

class DashboardActivityRow {
  const DashboardActivityRow({
    required this.userId,
    required this.model,
    required this.result,
    required this.date,
    required this.success,
  });

  final String userId;
  final String model;
  final String result;
  final String date;
  final bool success;
}
