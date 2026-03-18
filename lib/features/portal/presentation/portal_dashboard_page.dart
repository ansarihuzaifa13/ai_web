import 'package:flutter/material.dart';

import '../../../core/utils/download/download_service.dart';
import '../../../core/utils/file_picker/file_picker_service.dart';
import '../data/mock_portal_data.dart';
import '../domain/portal_models.dart';
import 'widgets/portal_widgets.dart';

class PortalDashboardPage extends StatefulWidget {
  const PortalDashboardPage({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  @override
  State<PortalDashboardPage> createState() => _PortalDashboardPageState();
}

class _PortalDashboardPageState extends State<PortalDashboardPage> {
  WorkspaceSection _section = WorkspaceSection.prediction;
  PredictionSubtab _subtab = PredictionSubtab.prediction;
  ModelType _modelType = ModelType.champion;

  InputMode _predictionModelMode = InputMode.upload;
  InputMode _predictionDatasetMode = InputMode.defaultFile;
  InputMode _championCombineMode = InputMode.defaultFile;
  InputMode _bhCombineMode = InputMode.defaultFile;
  InputMode _ntcCombineMode = InputMode.defaultFile;
  InputMode _comparisonMode = InputMode.defaultFile;

  bool _downloadPredictionDataset = true;
  bool _savePredictionToStorage = true;
  bool _performScoring = true;
  bool _downloadCombineDataset = true;
  bool _saveCombineToStorage = false;

  final Set<StatisticalTest> _selectedTests = <StatisticalTest>{
    StatisticalTest.zTest,
    StatisticalTest.tTest,
    StatisticalTest.ksTest,
  };

  bool _predictionLoading = false;
  bool _combineLoading = false;
  bool _comparisonLoading = false;
  bool _hasPredictionResults = false;

  String? _predictionModelFile;
  String? _predictionDataFile;
  String? _championCombineFile;
  String? _bhCombineFile;
  String? _ntcCombineFile;
  String? _comparisonFile;

  final TextEditingController _predictionModelDefaultController =
      TextEditingController(text: 'champion_calibrated_model.joblib');
  final TextEditingController _predictionDefaultController =
      TextEditingController(text: 'SC_Jun25_Pred_v1_with_ag_actual.parquet');
  final TextEditingController _predictionUserIdController =
      TextEditingController(text: 'AgreementNo, ReferenceNumber, AGREEMENTNO');
  final TextEditingController _predictionActualController =
      TextEditingController(text: 'actual_target');

  final TextEditingController _comparisonDefaultController =
      TextEditingController(
        text: 'gs://analytics-prod-bucket/akashBhagal/ab_testing/compare_input.parquet',
      );
  final TextEditingController _comparisonUserIdController =
      TextEditingController(text: 'AgreementNo, ReferenceNumber, AGREEMENTNO');
  final TextEditingController _comparisonActualController =
      TextEditingController(text: 'actual_target');

  final TextEditingController _championDefaultController =
      TextEditingController(
        text: 'gs://analytics-prod-bucket/Abhiram_Nimbalkar/Default_Files/champion_combine_default.parquet',
      );
  final TextEditingController _bhDefaultController = TextEditingController(
    text: 'gs://analytics-prod-bucket/Abhiram_Nimbalkar/Default_Files/challenger_bh_combine_default.parquet',
  );
  final TextEditingController _ntcDefaultController = TextEditingController(
    text: 'gs://analytics-prod-bucket/Abhiram_Nimbalkar/Default_Files/challenger_ntc_combine_default.parquet',
  );
  final TextEditingController _combineUserIdController =
      TextEditingController(text: 'AgreementNo, ReferenceNumber, AGREEMENTNO');
  final TextEditingController _combineActualController =
      TextEditingController(text: 'actual_target');

  List<PredictionRow> _predictionRows = MockPortalData.predictionRows(
    ModelType.champion,
  );
  final List<MetricValue> _dashboardSummary = MockPortalData.dashboardSummary();
  final List<DashboardActivityRow> _dashboardActivities =
      MockPortalData.recentActivities();
  List<MetricValue> _predictionSummary = MockPortalData.predictionSummary(
    ModelType.champion,
  );
  List<CombinedPredictionRow> _combinedRows = MockPortalData.combinedRows();
  final List<ComparisonMetricRow> _comparisonMetrics =
      MockPortalData.comparisonMetrics();
  List<StatisticalSummaryRow> _statisticalRows =
      MockPortalData.statisticalSummary(
    <StatisticalTest>{
      StatisticalTest.zTest,
      StatisticalTest.tTest,
      StatisticalTest.ksTest,
    },
  );

  @override
  void dispose() {
    _predictionModelDefaultController.dispose();
    _predictionDefaultController.dispose();
    _predictionUserIdController.dispose();
    _predictionActualController.dispose();
    _comparisonDefaultController.dispose();
    _comparisonUserIdController.dispose();
    _comparisonActualController.dispose();
    _championDefaultController.dispose();
    _bhDefaultController.dispose();
    _ntcDefaultController.dispose();
    _combineUserIdController.dispose();
    _combineActualController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(
    void Function(String?) setter, {
    String accept = '.csv,.parquet,.joblib',
  }) async {
    final String? fileName = await pickFileName(accept: accept);
    if (!mounted || fileName == null) {
      return;
    }
    setState(() => setter(fileName));
  }

  Future<void> _simulatePrediction() async {
    setState(() => _predictionLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) {
      return;
    }
    setState(() {
      _predictionRows = MockPortalData.predictionRows(_modelType);
      _predictionSummary = MockPortalData.predictionSummary(_modelType);
      _predictionLoading = false;
      _hasPredictionResults = true;
    });
  }

  Future<void> _simulateCombine() async {
    setState(() => _combineLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) {
      return;
    }
    setState(() {
      _combinedRows = MockPortalData.combinedRows();
      _combineLoading = false;
    });
  }

  Future<void> _simulateComparison() async {
    setState(() => _comparisonLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) {
      return;
    }
    setState(() {
      _statisticalRows = MockPortalData.statisticalSummary(_selectedTests);
      _comparisonLoading = false;
    });
  }

  void _downloadPredictionCsv() {
    final StringBuffer buffer =
        StringBuffer('user_id,prediction,probability,actual\n');
    for (final PredictionRow row in _predictionRows) {
      buffer.writeln(
        '${row.userId},${row.prediction},${row.predictionProbability.toStringAsFixed(4)},${row.actual.toStringAsFixed(1)}',
      );
    }
    downloadTextFile(
      filename: 'prediction_results.csv',
      content: buffer.toString(),
    );
  }

  void _downloadCombinedCsv() {
    final StringBuffer buffer = StringBuffer(
      'agreement_no,actual_outcome,champion_probability,champion_prediction,challenger_probability,challenger_prediction\n',
    );
    for (final CombinedPredictionRow row in _combinedRows) {
      buffer.writeln(
        '${row.agreementNo},${row.actualOutcome.toStringAsFixed(1)},${row.championProbability.toStringAsFixed(2)},${row.championPrediction},${row.challengerProbability.toStringAsFixed(2)},${row.challengerPrediction}',
      );
    }
    downloadTextFile(
      filename: 'combined_model_results.csv',
      content: buffer.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wideLayout = constraints.maxWidth >= 1100;
        final List<SidebarDestination> destinations = <SidebarDestination>[
          SidebarDestination(
            label: 'Dashboard',
            icon: Icons.dashboard_customize_rounded,
            selected: _section == WorkspaceSection.dashboard,
          ),
          SidebarDestination(
            label: 'Prediction',
            icon: Icons.analytics_outlined,
            selected: _section == WorkspaceSection.prediction,
          ),
          SidebarDestination(
            label: 'Comparison',
            icon: Icons.compare_arrows_rounded,
            selected: _section == WorkspaceSection.comparison,
          ),
          SidebarDestination(
            label: 'Reports',
            icon: Icons.insert_chart_outlined_rounded,
            selected: _section == WorkspaceSection.reports,
          ),
        ];

        final Widget content = Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: widget.isDarkMode
                  ? const <Color>[Color(0xFF0B1220), Color(0xFF111827)]
                  : const <Color>[Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
            ),
          ),
          child: SafeArea(
            child: CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _TopHeader(
                          section: _section,
                          isDarkMode: widget.isDarkMode,
                          onThemeToggle: widget.onThemeToggle,
                        ),
                        const SizedBox(height: 24),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: switch (_section) {
                            WorkspaceSection.dashboard =>
                              _buildDashboardWorkspace(),
                            WorkspaceSection.prediction =>
                              _buildPredictionWorkspace(),
                            WorkspaceSection.comparison =>
                              _buildComparisonWorkspace(),
                            WorkspaceSection.reports => _buildReportsWorkspace(),
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        return Scaffold(
          drawer: wideLayout
              ? null
              : Drawer(
                  child: PortalSidebar(
                    destinations: destinations,
                    onTap: (int index) {
                      Navigator.of(context).pop();
                      setState(() {
                        _section = WorkspaceSection.values[index];
                      });
                    },
                  ),
                ),
          body: Row(
            children: <Widget>[
              if (wideLayout)
                PortalSidebar(
                  destinations: destinations,
                  onTap: (int index) {
                    setState(() => _section = WorkspaceSection.values[index]);
                  },
                ),
              Expanded(child: content),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPredictionWorkspace() {
    return Column(
      key: const ValueKey<String>('prediction-workspace'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _PillTabBar(
          value: _subtab,
          onChanged: (PredictionSubtab value) {
            setState(() => _subtab = value);
          },
        ),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _subtab == PredictionSubtab.prediction
              ? _buildPredictionTab()
              : _buildCombineTab(),
        ),
      ],
    );
  }

  Widget _buildDashboardWorkspace() {
    return Column(
      key: const ValueKey<String>('dashboard-workspace'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _WelcomeCard(summary: _dashboardSummary),
        const SizedBox(height: 22),
        _ResponsiveMetricGrid(metrics: _dashboardSummary),
        const SizedBox(height: 22),
        SectionCard(
          title: 'Prediction Trend',
          subtitle: 'Model performance trend across recent execution windows.',
          child: const SizedBox(
            height: 260,
            child: _LineChartIllustration(),
          ),
        ),
        const SizedBox(height: 22),
        _RecentActivityTable(rows: _dashboardActivities),
      ],
    );
  }

  Widget _buildPredictionTab() {
    return LayoutBuilder(
      key: const ValueKey<String>('prediction-tab'),
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool showSidePanel = constraints.maxWidth >= 1180;
        final Widget leftColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
              _ConfigPanel(
                title: 'Model Selection',
                child: Wrap(
                  spacing: 32,
                  runSpacing: 12,
                  children: ModelType.values.map((ModelType type) {
                    return _RadioChoice(
                      label: _labelForModelType(type),
                      selected: _modelType == type,
                      onTap: () => setState(() => _modelType = type),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              _ConfigPanel(
                title: 'Upload Model File',
                child: Column(
                  children: <Widget>[
                    _UploadDropzone(
                      label: _predictionModelFile ??
                          'Drag & Drop or Browse .Joblib File',
                      onTap: () => _pickFile(
                        (String? fileName) => _predictionModelFile = fileName,
                        accept: '.joblib',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SelectField(
                      controller: _predictionModelDefaultController,
                      enabled: _predictionModelMode == InputMode.defaultFile,
                      label: 'Or Select Default Model',
                      onToggle: () {
                        setState(() {
                          _predictionModelMode =
                              _predictionModelMode == InputMode.upload
                                  ? InputMode.defaultFile
                                  : InputMode.upload;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ConfigPanel(
                title: 'Dataset Selection',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _RadioChoice(
                      label: 'Upload Parquet File',
                      selected: _predictionDatasetMode == InputMode.upload,
                      onTap: () {
                        setState(
                          () => _predictionDatasetMode = InputMode.upload,
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _UploadDropzone(
                      label: _predictionDataFile ??
                          'Drag & Drop or Browse .parquet File',
                      onTap: () => _pickFile(
                        (String? fileName) => _predictionDataFile = fileName,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _RadioChoice(
                      label: 'Use Default Dataset',
                      selected:
                          _predictionDatasetMode == InputMode.defaultFile,
                      onTap: () {
                        setState(
                          () => _predictionDatasetMode = InputMode.defaultFile,
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _SelectField(
                      controller: _predictionDefaultController,
                      enabled:
                          _predictionDatasetMode == InputMode.defaultFile,
                      label: 'Default dataset',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ConfigPanel(
                title: 'Inputs',
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool compact = constraints.maxWidth < 680;
                    return Column(
                      children: <Widget>[
                        if (compact) ...<Widget>[
                          TextField(
                            controller: _predictionUserIdController,
                            decoration: const InputDecoration(
                              hintText: 'User ID Column',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _predictionActualController,
                            decoration: const InputDecoration(
                              hintText: 'Actual Column',
                            ),
                          ),
                        ] else
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: TextField(
                                  controller: _predictionUserIdController,
                                  decoration: const InputDecoration(
                                    hintText: 'User ID Column',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _predictionActualController,
                                  decoration: const InputDecoration(
                                    hintText: 'Actual Column',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 18),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: <Widget>[
                            FilterChip(
                              selected: _downloadPredictionDataset,
                              label: const Text('Download Results'),
                              onSelected: (bool value) {
                                setState(
                                  () => _downloadPredictionDataset = value,
                                );
                              },
                            ),
                            FilterChip(
                              selected: _savePredictionToStorage,
                              label: const Text('Save To Storage'),
                              onSelected: (bool value) {
                                setState(
                                  () => _savePredictionToStorage = value,
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed:
                              _predictionLoading ? null : _simulatePrediction,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(220, 52),
                          ),
                          child: const Text('Run Prediction'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
        );

        final Widget rightPanel = SizedBox(
          width: showSidePanel ? 370 : double.infinity,
          child: Column(
            children: <Widget>[
              _InsightChartCard(metrics: _predictionSummary),
              const SizedBox(height: 16),
              _ProcessingBanner(
                visible: _predictionLoading,
                label: 'Running prediction workflow and validating input columns...',
              ),
            ],
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _PredictionHeroPanel(
              modelType: _modelType,
              hasResults: _hasPredictionResults,
              onDownload: _hasPredictionResults ? _downloadPredictionCsv : null,
            ),
            const SizedBox(height: 20),
            if (showSidePanel)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: leftColumn),
                  const SizedBox(width: 20),
                  rightPanel,
                ],
              )
            else
              Column(
                children: <Widget>[
                  leftColumn,
                  const SizedBox(height: 16),
                  rightPanel,
                ],
              ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _hasPredictionResults
                  ? Column(
                      key: const ValueKey<String>('prediction-results-state'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _ResponsiveMetricGrid(metrics: _predictionSummary),
                        const SizedBox(height: 24),
                        _PredictionTable(rows: _predictionRows),
                      ],
                    )
                  : const _PredictionEmptyState(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCombineTab() {
    return Column(
      key: const ValueKey<String>('combine-tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _FormGrid(
          children: <Widget>[
            _SourceSelector(
              title: 'Champion Parquet Data',
              description: 'Primary baseline model output.',
              mode: _championCombineMode,
              selectedFileName: _championCombineFile,
              defaultController: _championDefaultController,
              uploadLabel: 'Upload champion file',
              defaultLabel: 'Use default file',
              onModeChanged: (InputMode value) {
                setState(() => _championCombineMode = value);
              },
              onPickFile: () => _pickFile(
                (String? fileName) => _championCombineFile = fileName,
              ),
            ),
            _SourceSelector(
              title: 'Challenger BH Parquet Data',
              description: 'Business heuristic challenger output.',
              mode: _bhCombineMode,
              selectedFileName: _bhCombineFile,
              defaultController: _bhDefaultController,
              uploadLabel: 'Upload BH file',
              defaultLabel: 'Use default file',
              onModeChanged: (InputMode value) {
                setState(() => _bhCombineMode = value);
              },
              onPickFile: () => _pickFile(
                (String? fileName) => _bhCombineFile = fileName,
              ),
            ),
            _SourceSelector(
              title: 'Challenger NTC Parquet Data',
              description: 'New treatment challenger output.',
              mode: _ntcCombineMode,
              selectedFileName: _ntcCombineFile,
              defaultController: _ntcDefaultController,
              uploadLabel: 'Upload NTC file',
              defaultLabel: 'Use default file',
              onModeChanged: (InputMode value) {
                setState(() => _ntcCombineMode = value);
              },
              onPickFile: () => _pickFile(
                (String? fileName) => _ntcCombineFile = fileName,
              ),
            ),
            TextField(
              controller: _combineUserIdController,
              decoration: const InputDecoration(
                labelText: 'User ID Column Name',
                helperText: 'Keep this aligned across all uploaded parquet files.',
              ),
            ),
            TextField(
              controller: _combineActualController,
              decoration: const InputDecoration(
                labelText: 'Actual Column Name',
                helperText: 'Optional, but required for score comparison and labels.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            FilterChip(
              selected: _performScoring,
              label: const Text('Perform Deciling'),
              onSelected: (bool value) => setState(() => _performScoring = value),
            ),
            FilterChip(
              selected: _downloadCombineDataset,
              label: const Text('Download Combine Parquet With Results'),
              onSelected: (bool value) {
                setState(() => _downloadCombineDataset = value);
              },
            ),
            FilterChip(
              selected: _saveCombineToStorage,
              label: const Text('Save Output To Google Cloud Storage'),
              onSelected: (bool value) {
                setState(() => _saveCombineToStorage = value);
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            ElevatedButton.icon(
              onPressed: _combineLoading ? null : _simulateCombine,
              icon: const Icon(Icons.merge_rounded),
              label: const Text('Combine Model Results'),
            ),
            OutlinedButton.icon(
              onPressed: _downloadCombinedCsv,
              icon: const Icon(Icons.download_rounded),
              label: const Text('Download Full Prediction File'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _ProcessingBanner(
          visible: _combineLoading,
          label: 'Combining champion and challenger datasets into a unified output...',
        ),
        const SizedBox(height: 24),
        _CombinedResultsTable(rows: _combinedRows),
      ],
    );
  }

  Widget _buildComparisonWorkspace() {
    return LayoutBuilder(
      key: const ValueKey<String>('comparison-workspace'),
      builder: (BuildContext context, BoxConstraints constraints) {
        final wide = constraints.maxWidth >= 1100;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const _ComparisonHeroPanel(),
            const SizedBox(height: 20),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 3,
                    child: SectionCard(
                      title: 'Compare Champion and Challenger Outcome',
                      subtitle:
                          'Upload one common dataset, generate model performance, and run multiple statistical tests from a single analysis lab.',
                      trailing: const StatusBadge(label: 'Challenger Ahead'),
                      child: _buildComparisonControls(context),
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: _ComparisonWinnerCard(),
                  ),
                ],
              )
            else ...<Widget>[
              SectionCard(
                title: 'Compare Champion and Challenger Outcome',
                subtitle:
                    'Upload one common dataset, generate model performance, and run multiple statistical tests from a single analysis lab.',
                trailing: const StatusBadge(label: 'Challenger Ahead'),
                child: _buildComparisonControls(context),
              ),
              const SizedBox(height: 24),
              const _ComparisonWinnerCard(),
            ],
            const SizedBox(height: 24),
            _ComparisonSummaryStrip(rows: _comparisonMetrics),
            const SizedBox(height: 24),
            SectionCard(
              title: 'Performance Comparison',
              subtitle:
                  'Core metrics and statistical interpretation for the current champion vs challenger run.',
              child: Column(
                children: <Widget>[
                  _ComparisonMetricsTable(rows: _comparisonMetrics),
                  const SizedBox(height: 24),
                  _StatisticalSummaryTable(rows: _statisticalRows),
                ],
              ),
            
          ),
          ]
        );
      },
    );
  }

  Widget _buildComparisonControls(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _FormGrid(
          children: <Widget>[
            _SourceSelector(
              title: 'File Input Options',
              description:
                  'Use a fresh upload or your comparison default file.',
              mode: _comparisonMode,
              selectedFileName: _comparisonFile,
              defaultController: _comparisonDefaultController,
              uploadLabel: 'Upload file',
              defaultLabel: 'Use default file',
              onModeChanged: (InputMode value) {
                setState(() => _comparisonMode = value);
              },
              onPickFile: () => _pickFile(
                (String? fileName) => _comparisonFile = fileName,
              ),
            ),
            TextField(
              controller: _comparisonUserIdController,
              decoration: const InputDecoration(
                labelText: 'User ID Column Name',
                helperText:
                    'The same user ID must exist for both champion and challenger outputs.',
              ),
            ),
            TextField(
              controller: _comparisonActualController,
              decoration: const InputDecoration(
                labelText: 'Actual Column Name',
                helperText: 'Used for performance metrics and hypothesis tests.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            ElevatedButton.icon(
              onPressed: _comparisonLoading ? null : _simulateComparison,
              icon: const Icon(Icons.auto_graph_rounded),
              label: const Text('Generate Model Performances'),
            ),
            OutlinedButton.icon(
              onPressed: _comparisonLoading ? null : _simulateComparison,
              icon: const Icon(Icons.science_rounded),
              label: const Text('Run Statistical Tests'),
            ),
            FilledButton.tonalIcon(
              onPressed: () {},
              icon: const Icon(Icons.download_rounded),
              label: const Text('Download CSV'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _ProcessingBanner(
          visible: _comparisonLoading,
          label:
              'Computing performance distributions and statistical significance...',
        ),
        const SizedBox(height: 24),
        Text(
          'Select Statistical Tests',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: StatisticalTest.values.map((StatisticalTest test) {
            return FilterChip(
              selected: _selectedTests.contains(test),
              label: Text(_labelForTest(test)),
              onSelected: (bool value) {
                setState(() {
                  if (value) {
                    _selectedTests.add(test);
                  } else {
                    _selectedTests.remove(test);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        FilterChip(
          selected: _selectedTests.length == StatisticalTest.values.length,
          label: const Text('Select All'),
          onSelected: (bool value) {
            setState(() {
              if (value) {
                _selectedTests.addAll(StatisticalTest.values);
              } else {
                _selectedTests.clear();
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildReportsWorkspace() {
    return Column(
      key: const ValueKey<String>('reports-workspace'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionCard(
          title: 'Reports',
          subtitle:
              'Explore performance, score distribution, and recent trend analysis across datasets.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: const <Widget>[
                  _FilterPill(label: 'Date Range'),
                  _FilterPill(label: 'Select Model'),
                  _FilterPill(label: 'Select Dataset'),
                ],
              ),
              const SizedBox(height: 22),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool compact = constraints.maxWidth < 1050;
                  if (compact) {
                    return const Column(
                      children: <Widget>[
                        _ReportChartGrid(),
                      ],
                    );
                  }

                  return const _ReportChartGrid();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _labelForModelType(ModelType type) {
    return switch (type) {
      ModelType.champion => 'Champion',
      ModelType.challengerBh => 'Challenger BH',
      ModelType.challengerNtc => 'Challenger NTC',
    };
  }

  String _labelForTest(StatisticalTest test) {
    return switch (test) {
      StatisticalTest.zTest => 'Z-Test',
      StatisticalTest.tTest => 'T-Test',
      StatisticalTest.fTest => 'F-Test',
      StatisticalTest.ksTest => 'KS-Test',
      StatisticalTest.deLong => 'DeLong / Bootstrap AUC',
      StatisticalTest.mcNemar => 'McNemar Test',
    };
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.section,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  final WorkspaceSection section;
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  @override
  Widget build(BuildContext context) {
    final (String title, String subtitle) = switch (section) {
      WorkspaceSection.dashboard => (
          'Welcome back, User',
          'Monitor platform activity, model runs, and recent prediction outcomes.',
        ),
      WorkspaceSection.prediction => (
          'Model Prediction',
          'Run predictions, combine challenger outputs, and inspect scoring results.',
        ),
      WorkspaceSection.comparison => (
          'Model Comparison',
          'Compare champion and challenger outcomes with full statistical interpretation.',
        ),
      WorkspaceSection.reports => (
          'Reports',
          'Track conversion, score distributions, and longer-term performance trends.',
        ),
    };
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        Row(
          children: <Widget>[
            _HeaderCircleIcon(
              icon: isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              onTap: onThemeToggle,
            ),
            const SizedBox(width: 12),
            const _HeaderCircleIcon(icon: Icons.notifications_rounded),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).cardColor,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFBFDBFE),
                child: Icon(Icons.person, color: Color(0xFF1D4ED8)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FormGrid extends StatelessWidget {
  const _FormGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= 900;
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children
                .expand((Widget child) => <Widget>[
                      child,
                      const SizedBox(height: 16),
                    ])
                .toList()
              ..removeLast(),
          );
        }

        final List<Widget> rows = <Widget>[];
        for (var i = 0; i < children.length; i += 2) {
          final Widget second = i + 1 < children.length
              ? children[i + 1]
              : const SizedBox.shrink();
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: children[i]),
                const SizedBox(width: 16),
                Expanded(child: second),
              ],
            ),
          );
          rows.add(const SizedBox(height: 16));
        }
        rows.removeLast();
        return Column(children: rows);
      },
    );
  }
}

class _HeaderCircleIcon extends StatelessWidget {
  const _HeaderCircleIcon({
    required this.icon,
    this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x110F172A),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
    );
  }
}

class _PillTabBar extends StatelessWidget {
  const _PillTabBar({
    required this.value,
    required this.onChanged,
  });

  final PredictionSubtab value;
  final ValueChanged<PredictionSubtab> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget buildTab(PredictionSubtab tab, String label) {
      final bool selected = value == tab;
      return GestureDetector(
        onTap: () => onChanged(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: selected
                ? const LinearGradient(
                    colors: <Color>[Color(0xFF0A66FF), Color(0xFF2563EB)],
                  )
                : null,
            color: selected ? null : Colors.white,
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF475569),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Row(
      children: <Widget>[
        buildTab(PredictionSubtab.prediction, 'Prediction'),
        const SizedBox(width: 14),
        buildTab(PredictionSubtab.combineResults, 'Combine Results'),
      ],
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.summary});

  final List<MetricValue> summary;

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? const <Color>[Color(0xFF111827), Color(0xFF172554)]
                : const <Color>[Color(0xFFFFFFFF), Color(0xFFF8FBFF)],
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Welcome back, User',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your platform is healthy. ${summary[0].value} total runs have been tracked with ${summary[1].value} average accuracy.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Live Workspace',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PredictionHeroPanel extends StatelessWidget {
  const _PredictionHeroPanel({
    required this.modelType,
    required this.hasResults,
    required this.onDownload,
  });

  final ModelType modelType;
  final bool hasResults;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final String activeModel = switch (modelType) {
      ModelType.champion => 'Champion',
      ModelType.challengerBh => 'Challenger BH',
      ModelType.challengerNtc => 'Challenger NTC',
    };

    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? const <Color>[Color(0xFF172554), Color(0xFF0F172A)]
                : const <Color>[Color(0xFFEFF6FF), Color(0xFFFFFFFF)],
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Prediction Workspace',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Active model: $activeModel. Run predictions, inspect outputs, and export results from a single polished workflow.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _HeroStatPill(
                  label: hasResults ? 'Results Ready' : 'Waiting To Run',
                  value: hasResults ? 'Live' : 'Idle',
                ),
                FilledButton.tonalIcon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Export'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonHeroPanel extends StatelessWidget {
  const _ComparisonHeroPanel();

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? const <Color>[Color(0xFF3B0764), Color(0xFF172554)]
                : const <Color>[Color(0xFFF5F3FF), Color(0xFFFFFFFF)],
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Champion vs Challenger',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Compare model quality, statistical significance, and outcome lift with an executive-friendly interface.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const _HeroStatPill(label: 'Current Leader', value: 'Challenger'),
          ],
        ),
      ),
    );
  }
}

class _HeroStatPill extends StatelessWidget {
  const _HeroStatPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _ConfigPanel extends StatelessWidget {
  const _ConfigPanel({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          letterSpacing: 0.2,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF172554)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(
                    Icons.more_horiz,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE8EDF6)),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? const Color(0xFF22314B)
              : const Color(0xFFD8E0EE),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(width: 10),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
        ],
      ),
    );
  }
}

class _RadioChoice extends StatelessWidget {
  const _RadioChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFC5D0E0),
                  width: 1.6,
                ),
              ),
              child: selected
                  ? const Center(
                      child: CircleAvatar(
                        radius: 6,
                        backgroundColor: Color(0xFF2563EB),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: const Color(0xFF334155),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadDropzone extends StatelessWidget {
  const _UploadDropzone({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFDFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFC8D5E8),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.upload_file_rounded, color: Color(0xFF64748B)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.controller,
    required this.enabled,
    required this.label,
    this.onToggle,
  });

  final TextEditingController controller;
  final bool enabled;
  final String label;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: IgnorePointer(
        ignoring: true,
        child: TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
        ),
      ),
    );
  }
}

class _InsightChartCard extends StatelessWidget {
  const _InsightChartCard({required this.metrics});

  final List<MetricValue> metrics;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Conversion Rate',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE8EDF6)),
            const SizedBox(height: 18),
            const SizedBox(
              height: 220,
              child: _LineChartIllustration(),
            ),
            const SizedBox(height: 14),
            Text(
              'Predicted conversion ${metrics.last.value}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChartIllustration extends StatelessWidget {
  const _LineChartIllustration();

  @override
  Widget build(BuildContext context) {
    const List<double> values = <double>[0.20, 0.35, 0.50, 0.65];
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: <Color>[
                      const Color(0xFFFFE4DE),
                      Colors.white,
                      const Color(0xFFDCEBFF),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            for (var i = 0; i < values.length; i++)
              Positioned(
                left: (constraints.maxWidth / (values.length + 1)) * (i + 1),
                top: 30,
                bottom: 26,
                child: Container(
                  width: 1,
                  color: const Color(0xFFD8E4F4),
                ),
              ),
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _ChartPainter(values),
            ),
            for (var i = 0; i < values.length; i++)
              Positioned(
                left: (constraints.maxWidth / (values.length + 1)) * (i + 1) - 20,
                top: (1 - values[i]) * 130 + 20,
                child: Column(
                  children: <Widget>[
                    Text(
                      '${(values[i] * 100).round()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: i == 0
                              ? const Color(0xFFF59EAF)
                              : const Color(0xFF3B82F6),
                          width: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ChartPainter extends CustomPainter {
  const _ChartPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final Path line = Path();
    final Path area = Path();
    final double step = size.width / (values.length + 1);

    for (var i = 0; i < values.length; i++) {
      final double x = step * (i + 1);
      final double y = (1 - values[i]) * 130 + 50;
      if (i == 0) {
        line.moveTo(x, y);
        area.moveTo(x, size.height - 20);
        area.lineTo(x, y);
      } else {
        line.lineTo(x, y);
        area.lineTo(x, y);
      }
    }

    area.lineTo(step * values.length, size.height - 20);
    area.close();

    final Paint fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0x663B82F6), Color(0x003B82F6)],
      ).createShader(Offset.zero & size);

    final Paint stroke = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[Color(0xFFF59EAF), Color(0xFF3B82F6)],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    canvas.drawPath(area, fill);
    canvas.drawPath(line, stroke);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class _DonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width * 0.28, size.height * 0.5);
    final double radius = size.height * 0.28;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    final List<(double, Color)> segments = <(double, Color)>[
      (1.3, const Color(0xFF3B82F6)),
      (1.1, const Color(0xFF8B5CF6)),
      (0.9, const Color(0xFFEC4899)),
      (1.4, const Color(0xFF22C55E)),
    ];

    double start = -1.57;
    for (final segment in segments) {
      final paint = Paint()
        ..color = segment.$2
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, segment.$1, false, paint);
      start += segment.$1 + 0.08;
    }

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Conversion\nvs Accuracy',
        style: TextStyle(
          color: Color(0xFF475569),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width * 0.35);

    textPainter.paint(
      canvas,
      Offset(size.width * 0.58, size.height * 0.38),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final values = <double>[0.35, 0.52, 0.40, 0.60, 0.44, 0.67, 0.81, 0.54];
    final colors = <Color>[
      const Color(0xFF3B82F6),
      const Color(0xFF38BDF8),
      const Color(0xFF2563EB),
      const Color(0xFFEC4899),
      const Color(0xFF8B5CF6),
      const Color(0xFF2563EB),
      const Color(0xFF1D4ED8),
      const Color(0xFF2563EB),
    ];
    final Paint grid = Paint()..color = const Color(0xFFE2E8F0);

    for (var i = 0; i < 4; i++) {
      final y = 18 + (size.height - 36) / 4 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final double width = size.width / (values.length * 1.5);
    for (var i = 0; i < values.length; i++) {
      final left = 8 + i * (width + 12);
      final top = size.height - 18 - (values[i] * (size.height - 52));
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, width, size.height - 18 - top),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, Paint()..color = colors[i]);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DualLinePainter extends CustomPainter {
  const _DualLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final one = <double>[0.60, 0.42, 0.55, 0.48, 0.58, 0.50, 0.57, 0.63];
    final two = <double>[0.44, 0.58, 0.46, 0.60, 0.49, 0.54, 0.66, 0.72];
    final step = size.width / (one.length - 1);

    void drawSeries(List<double> values, List<Color> colors) {
      final path = Path();
      for (var i = 0; i < values.length; i++) {
        final x = step * i;
        final y = size.height - 24 - (values[i] * (size.height - 50));
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(colors: colors).createShader(
            Offset.zero & size,
          )
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke,
      );
    }

    drawSeries(one, const <Color>[Color(0xFF60A5FA), Color(0xFF2563EB)]);
    drawSeries(two, const <Color>[Color(0xFFA78BFA), Color(0xFF7C3AED)]);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SourceSelector extends StatelessWidget {
  const _SourceSelector({
    required this.title,
    required this.description,
    required this.mode,
    required this.selectedFileName,
    required this.defaultController,
    required this.uploadLabel,
    required this.defaultLabel,
    required this.onModeChanged,
    required this.onPickFile,
  });

  final String title;
  final String description;
  final InputMode mode;
  final String? selectedFileName;
  final TextEditingController defaultController;
  final String uploadLabel;
  final String defaultLabel;
  final ValueChanged<InputMode> onModeChanged;
  final VoidCallback onPickFile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          SegmentedButton<InputMode>(
            segments: <ButtonSegment<InputMode>>[
              ButtonSegment<InputMode>(
                value: InputMode.upload,
                label: Text(uploadLabel),
                icon: const Icon(Icons.upload_file_rounded),
              ),
              ButtonSegment<InputMode>(
                value: InputMode.defaultFile,
                label: Text(defaultLabel),
                icon: const Icon(Icons.folder_copy_rounded),
              ),
            ],
            selected: <InputMode>{mode},
            onSelectionChanged: (Set<InputMode> value) {
              onModeChanged(value.first);
            },
          ),
          const SizedBox(height: 16),
          if (mode == InputMode.upload) ...<Widget>[
            OutlinedButton.icon(
              onPressed: onPickFile,
              icon: const Icon(Icons.attach_file_rounded),
              label: Text(selectedFileName ?? 'Choose file'),
            ),
            const SizedBox(height: 10),
            Text(
              selectedFileName == null
                  ? 'No file selected yet.'
                  : 'Selected: $selectedFileName',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ] else
            TextField(
              controller: defaultController,
              decoration: const InputDecoration(
                labelText: 'Default file path',
              ),
            ),
        ],
      ),
    );
  }
}

class _ProcessingBanner extends StatelessWidget {
  const _ProcessingBanner({
    required this.visible,
    required this.label,
  });

  final bool visible;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: !visible
          ? const SizedBox.shrink()
          : Container(
              key: ValueKey<String>(label),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: <Widget>[
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ResponsiveMetricGrid extends StatelessWidget {
  const _ResponsiveMetricGrid({required this.metrics});

  final List<MetricValue> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 1100
            ? 5
            : constraints.maxWidth >= 700
                ? 3
                : 1;
        final double itemWidth =
            (constraints.maxWidth - ((columns - 1) * 16)) / columns;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: metrics.map((MetricValue metric) {
            return SizedBox(
              width: itemWidth,
              child: MetricTile(
                label: metric.label,
                value: metric.value,
                highlight: metric.highlight,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _PredictionEmptyState extends StatelessWidget {
  const _PredictionEmptyState();

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Card(
      key: const ValueKey<String>('prediction-empty-state'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? const <Color>[Color(0xFF111827), Color(0xFF0F172A)]
                : const <Color>[Color(0xFFFFFFFF), Color(0xFFF8FBFF)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF172554)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.insights_rounded,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Prediction results will appear here',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Run a prediction first to reveal the result table, summary cards, and downloadable output.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PredictionTable extends StatelessWidget {
  const _PredictionTable({required this.rows});

  final List<PredictionRow> rows;

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return SectionCard(
      title: 'Prediction Results',
      subtitle: 'Top rows from the latest scoring run, displayed only after prediction execution.',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF172554)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${rows.length} rows',
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: () {
              final state = context.findAncestorStateOfType<
                  _PortalDashboardPageState>();
              state?._downloadPredictionCsv();
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Download CSV'),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF0F172A)
                : const Color(0xFFF8FBFF),
            border: Border.all(
              color: isDarkMode
                  ? const Color(0xFF22314B)
                  : const Color(0xFFE2E8F0),
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll<Color>(
                isDarkMode
                    ? const Color(0xFF111827)
                    : const Color(0xFFEEF4FF),
              ),
              dataRowMinHeight: 58,
              dataRowMaxHeight: 66,
              columnSpacing: 40,
              columns: const <DataColumn>[
                DataColumn(label: Text('User ID')),
                DataColumn(label: Text('Prediction')),
                DataColumn(label: Text('Prediction Probability')),
                DataColumn(label: Text('Actual')),
              ],
              rows: rows.asMap().entries.map((entry) {
                final int index = entry.key;
                final PredictionRow row = entry.value;
                final bool positive = row.prediction == 1;
                return DataRow(
                  color: WidgetStatePropertyAll<Color>(
                    index.isEven
                        ? Colors.transparent
                        : (isDarkMode
                            ? const Color(0xFF111827)
                            : const Color(0xFFFCFDFF)),
                  ),
                  cells: <DataCell>[
                    DataCell(
                      Text(
                        row.userId,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: positive
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          positive ? 'Positive' : 'Negative',
                          style: TextStyle(
                            color: positive
                                ? const Color(0xFF166534)
                                : const Color(0xFF475569),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 220,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: row.predictionProbability,
                                  minHeight: 10,
                                  backgroundColor: isDarkMode
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFE2E8F0),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              row.predictionProbability.toStringAsFixed(4),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        row.actual.toStringAsFixed(1),
                        style: TextStyle(
                          color: row.actual == 1.0
                              ? const Color(0xFF059669)
                              : null,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentActivityTable extends StatelessWidget {
  const _RecentActivityTable({required this.rows});

  final List<DashboardActivityRow> rows;

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return SectionCard(
      title: 'Recent Activity',
      subtitle: 'Latest scoring and comparison actions across the workspace.',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF0F172A)
                : const Color(0xFFF8FBFF),
            border: Border.all(
              color: isDarkMode
                  ? const Color(0xFF22314B)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll<Color>(
                isDarkMode
                    ? const Color(0xFF111827)
                    : const Color(0xFFEEF4FF),
              ),
              columns: const <DataColumn>[
                DataColumn(label: Text('User ID')),
                DataColumn(label: Text('Model')),
                DataColumn(label: Text('Result')),
                DataColumn(label: Text('Date')),
              ],
              rows: rows.map((DashboardActivityRow row) {
                return DataRow(
                  cells: <DataCell>[
                    DataCell(Text(row.userId)),
                    DataCell(Text(row.model)),
                    DataCell(
                      Row(
                        children: <Widget>[
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: row.success
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFFF97316),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            row.result,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: row.success
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFEA580C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(row.date)),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComparisonWinnerCard extends StatelessWidget {
  const _ComparisonWinnerCard();

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? const <Color>[Color(0xFF14532D), Color(0xFF0F172A)]
                : const <Color>[Color(0xFFDCFCE7), Color(0xFFFFFFFF)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Outcome Snapshot'),
            const SizedBox(height: 14),
            Row(
              children: const <Widget>[
                Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 34),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Challenger model currently leads the comparison run.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _WinnerStatRow(label: 'Champion Accuracy', value: '51.64%'),
            const SizedBox(height: 10),
            const _WinnerStatRow(label: 'Challenger Accuracy', value: '65.22%'),
            const SizedBox(height: 10),
            const _WinnerStatRow(label: 'Improvement', value: '+13.58%'),
          ],
        ),
      ),
    );
  }
}

class _WinnerStatRow extends StatelessWidget {
  const _WinnerStatRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF16A34A),
          ),
        ),
      ],
    );
  }
}

class _ComparisonSummaryStrip extends StatelessWidget {
  const _ComparisonSummaryStrip({required this.rows});

  final List<ComparisonMetricRow> rows;

  @override
  Widget build(BuildContext context) {
    final ComparisonMetricRow auc = rows.first;
    final ComparisonMetricRow lift = rows.firstWhere(
      (ComparisonMetricRow row) => row.metric == 'Lift',
    );
    final ComparisonMetricRow f1 = rows.firstWhere(
      (ComparisonMetricRow row) => row.metric == 'F1 Score',
    );

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: <Widget>[
        SizedBox(
          width: 240,
          child: MetricTile(
            label: 'Champion AUC',
            value: auc.champion.toStringAsFixed(4),
          ),
        ),
        SizedBox(
          width: 240,
          child: MetricTile(
            label: 'Challenger AUC',
            value: auc.challenger.toStringAsFixed(4),
            highlight: true,
          ),
        ),
        SizedBox(
          width: 240,
          child: MetricTile(
            label: 'Lift Improvement',
            value:
                '+${((lift.challenger - lift.champion) / lift.champion * 100).toStringAsFixed(1)}%',
            highlight: true,
          ),
        ),
        SizedBox(
          width: 240,
          child: MetricTile(
            label: 'F1 Delta',
            value: '+${(f1.challenger - f1.champion).toStringAsFixed(3)}',
          ),
        ),
      ],
    );
  }
}

class _CombinedResultsTable extends StatelessWidget {
  const _CombinedResultsTable({required this.rows});

  final List<CombinedPredictionRow> rows;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Output',
      subtitle: 'Unified champion and challenger records for downstream analysis.',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const <DataColumn>[
            DataColumn(label: Text('Agreement No')),
            DataColumn(label: Text('Actual Outcome')),
            DataColumn(label: Text('Champion Probability')),
            DataColumn(label: Text('Champion Prediction')),
            DataColumn(label: Text('Challenger Probability')),
            DataColumn(label: Text('Challenger Prediction')),
          ],
          rows: rows.map((CombinedPredictionRow row) {
            return DataRow(
              cells: <DataCell>[
                DataCell(Text(row.agreementNo)),
                DataCell(Text(row.actualOutcome.toStringAsFixed(1))),
                DataCell(Text(row.championProbability.toStringAsFixed(2))),
                DataCell(Text('${row.championPrediction}')),
                DataCell(Text(row.challengerProbability.toStringAsFixed(2))),
                DataCell(Text('${row.challengerPrediction}')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ReportChartGrid extends StatelessWidget {
  const _ReportChartGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final compact = constraints.maxWidth < 900;

        Widget card(String title, _MiniChartType type) {
          return _MiniChartCard(title: title, chartType: type);
        }

        if (compact) {
          return Column(
            children: <Widget>[
              card('Conversion Rate', _MiniChartType.donut),
              const SizedBox(height: 16),
              card('Accuracy', _MiniChartType.line),
              const SizedBox(height: 16),
              card('Score Distribution', _MiniChartType.bar),
              const SizedBox(height: 16),
              card('Trend Analysis', _MiniChartType.dualLine),
            ],
          );
        }

        return Column(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: card('Conversion Rate', _MiniChartType.donut)),
                const SizedBox(width: 16),
                Expanded(child: card('Accuracy', _MiniChartType.line)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: card('Score Distribution', _MiniChartType.bar),
                ),
                const SizedBox(width: 16),
                Expanded(child: card('Trend Analysis', _MiniChartType.dualLine)),
              ],
            ),
          ],
        );
      },
    );
  }
}

enum _MiniChartType { donut, line, bar, dualLine }

class _MiniChartCard extends StatelessWidget {
  const _MiniChartCard({
    required this.title,
    required this.chartType,
  });

  final String title;
  final _MiniChartType chartType;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: switch (chartType) {
                _MiniChartType.donut => const _DonutChartIllustration(),
                _MiniChartType.line => const _LineChartIllustration(),
                _MiniChartType.bar => const _BarChartIllustration(),
                _MiniChartType.dualLine => const _DualLineChartIllustration(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutChartIllustration extends StatelessWidget {
  const _DonutChartIllustration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DonutPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _BarChartIllustration extends StatelessWidget {
  const _BarChartIllustration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BarPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _DualLineChartIllustration extends StatelessWidget {
  const _DualLineChartIllustration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _DualLinePainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _ComparisonMetricsTable extends StatelessWidget {
  const _ComparisonMetricsTable({required this.rows});

  final List<ComparisonMetricRow> rows;

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FBFF),
          border: Border.all(
            color: isDarkMode
                ? const Color(0xFF22314B)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll<Color>(
              isDarkMode
                  ? const Color(0xFF111827)
                  : const Color(0xFFEEF4FF),
            ),
            columnSpacing: 36,
            columns: const <DataColumn>[
              DataColumn(label: Text('Metric')),
              DataColumn(label: Text('Champion')),
              DataColumn(label: Text('Challenger')),
            ],
            rows: rows.map((ComparisonMetricRow row) {
              final bool improved = row.challenger > row.champion;
              return DataRow(
                cells: <DataCell>[
                  DataCell(Text(row.metric)),
                  DataCell(Text(row.champion.toStringAsFixed(4))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: improved
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        row.challenger.toStringAsFixed(4),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: improved
                              ? const Color(0xFF166534)
                              : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _StatisticalSummaryTable extends StatelessWidget {
  const _StatisticalSummaryTable({required this.rows});

  final List<StatisticalSummaryRow> rows;

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (rows.isEmpty) {
      return const Text(
        'Select at least one test to generate a comparison summary.',
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FBFF),
          border: Border.all(
            color: isDarkMode
                ? const Color(0xFF22314B)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll<Color>(
              isDarkMode
                  ? const Color(0xFF111827)
                  : const Color(0xFFEEF4FF),
            ),
            columns: const <DataColumn>[
              DataColumn(label: Text('Test Name')),
              DataColumn(label: Text('Parameter Tested')),
              DataColumn(label: Text('P Value')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Final Comment')),
            ],
            rows: rows.map((StatisticalSummaryRow row) {
              return DataRow(
                cells: <DataCell>[
                  DataCell(Text(row.testName)),
                  DataCell(SizedBox(width: 220, child: Text(row.parameter))),
                  DataCell(Text(row.pValue.toStringAsFixed(4))),
                  DataCell(
                    StatusBadge(
                      label: row.status,
                      positive: row.status.contains('Reject'),
                    ),
                  ),
                  DataCell(SizedBox(width: 220, child: Text(row.comment))),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
