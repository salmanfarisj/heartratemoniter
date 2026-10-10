import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/wahoo_header.dart';
import '../../domain/models/activity.dart';
import '../../domain/models/activity_type.dart';
import '../bloc/activity_bloc.dart';
import '../bloc/activity_event.dart';
import '../bloc/activity_state.dart';

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  ActivityType _selectedType = ActivityType.run;
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _avgHrController = TextEditingController();
  final _maxHrController = TextEditingController();
  final _minHrController = TextEditingController();
  final _paceController = TextEditingController();
  final _elevationController = TextEditingController();
  final _cadenceController = TextEditingController();
  final _speedController = TextEditingController();
  final _stepsController = TextEditingController();
  final _floorsController = TextEditingController();
  final _notesController = TextEditingController();
  final _zone1Controller = TextEditingController();
  final _zone2Controller = TextEditingController();
  final _zone3Controller = TextEditingController();
  final _zone4Controller = TextEditingController();
  final _zone5Controller = TextEditingController();

  ActivityIntensity _selectedIntensity = ActivityIntensity.medium;
  String? _selectedWeather;

  bool _heartRateExpanded = false;
  bool _paceExpanded = false;
  bool _zonesExpanded = false;
  bool _additionalExpanded = false;

  /// When true, the activity is logged without GPS-tracked fields
  /// (distance, pace, speed, cadence, elevation). Heart-rate and zone
  /// data are still captured. The form hides the relevant inputs and
  /// the submit handler nulls them on the saved [Activity].
  bool _manualOnly = false;

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    _caloriesController.dispose();
    _avgHrController.dispose();
    _maxHrController.dispose();
    _minHrController.dispose();
    _paceController.dispose();
    _elevationController.dispose();
    _cadenceController.dispose();
    _speedController.dispose();
    _stepsController.dispose();
    _floorsController.dispose();
    _notesController.dispose();
    _zone1Controller.dispose();
    _zone2Controller.dispose();
    _zone3Controller.dispose();
    _zone4Controller.dispose();
    _zone5Controller.dispose();
    super.dispose();
  }

  void _submitActivity() {
    final name = _nameController.text.trim();
    final duration = int.tryParse(_durationController.text) ?? 0;

    if (name.isEmpty || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter activity name and duration')),
      );
      return;
    }

    context.read<ActivityBloc>().add(AddActivity(
          type: _selectedType,
          name: name,
          durationMinutes: duration,
          distanceKm: _manualOnly
              ? null
              : double.tryParse(_distanceController.text),
          calories: int.tryParse(_caloriesController.text),
          avgHr: int.tryParse(_avgHrController.text),
          maxHr: int.tryParse(_maxHrController.text),
          minHr: int.tryParse(_minHrController.text),
          avgPace: _manualOnly ? null : double.tryParse(_paceController.text),
          elevationGain: _manualOnly
              ? null
              : double.tryParse(_elevationController.text),
          cadence: _manualOnly
              ? null
              : int.tryParse(_cadenceController.text),
          avgSpeed:
              _manualOnly ? null : double.tryParse(_speedController.text),
          zone1Time: int.tryParse(_zone1Controller.text),
          zone2Time: int.tryParse(_zone2Controller.text),
          zone3Time: int.tryParse(_zone3Controller.text),
          zone4Time: int.tryParse(_zone4Controller.text),
          zone5Time: int.tryParse(_zone5Controller.text),
          steps: int.tryParse(_stepsController.text),
          floorsClimbed: int.tryParse(_floorsController.text),
          intensity: _selectedIntensity,
          perceivedExertion: null,
          weather: _selectedWeather,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        ));

    _clearForm();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activity saved!')),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _durationController.clear();
    _distanceController.clear();
    _caloriesController.clear();
    _avgHrController.clear();
    _maxHrController.clear();
    _minHrController.clear();
    _paceController.clear();
    _elevationController.clear();
    _cadenceController.clear();
    _speedController.clear();
    _stepsController.clear();
    _floorsController.clear();
    _notesController.clear();
    _zone1Controller.clear();
    _zone2Controller.clear();
    _zone3Controller.clear();
    _zone4Controller.clear();
    _zone5Controller.clear();
    // Always wipe the GPS input fields so toggling it back on after
    // submitting doesn't accidentally save stale distance/pace values.
    _distanceController.clear();
    _paceController.clear();
    _speedController.clear();
    _elevationController.clear();
    _cadenceController.clear();

    setState(() {
      _selectedType = ActivityType.run;
      _selectedIntensity = ActivityIntensity.medium;
      _selectedWeather = null;
      _heartRateExpanded = false;
      _paceExpanded = false;
      _zonesExpanded = false;
      _additionalExpanded = false;
      _manualOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paperWhite,
      appBar: WahooHeader(
        title: 'Record',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.brandBlue),
            onPressed: _clearForm,
            tooltip: 'Clear form',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.huge,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Today's Summary
              BlocBuilder<ActivityBloc, ActivityState>(
                builder: (context, state) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.warmLinen,
                      borderRadius: BorderRadius.circular(AppRadius.cards),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SummaryItem(
                          label: 'Activities',
                          value: '${state.activities.length}',
                        ),
                        _SummaryItem(
                          label: 'Duration',
                          value: '${state.todayDuration}',
                          unit: 'min',
                        ),
                        _SummaryItem(
                          label: 'Calories',
                          value: '${state.todayCalories}',
                          unit: 'kcal',
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // Activity type
              Text('Activity Type', style: AppTypography.label),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ActivityType.values.map((type) {
                    final isSelected = type == _selectedType;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.brandBlue
                                : AppColors.warmLinen,
                            borderRadius: BorderRadius.circular(AppSpacing.xs),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getIconForType(type),
                                size: 16,
                                color: isSelected
                                    ? AppColors.paperWhite
                                    : AppColors.charcoal,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                type.label,
                                style: AppTypography.bodySm.copyWith(
                                  color: isSelected
                                      ? AppColors.paperWhite
                                      : AppColors.charcoal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Manual / No-GPS toggle. When ON, distance + the entire
              // Pace & Speed section are hidden and the saved Activity
              // carries nulls for those fields — only HR, calories,
              // zones and notes survive.
              _ManualModeToggle(
                enabled: _manualOnly,
                onChanged: (value) {
                  setState(() {
                    _manualOnly = value;
                    if (value) {
                      // Wipe any half-typed GPS text so it can't sneak
                      // back in if the user flips the toggle off then
                      // submits without re-typing.
                      _distanceController.clear();
                      _paceController.clear();
                      _speedController.clear();
                      _elevationController.clear();
                      _cadenceController.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // Basic Details Section
              Text('Basic Details', style: AppTypography.label),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Activity Name',
                  hintText: 'e.g., Morning Run',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duration *',
                        hintText: 'Minutes',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  if (!_manualOnly) ...[
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextField(
                        controller: _distanceController,
                        decoration: const InputDecoration(
                          labelText: 'Distance',
                          hintText: 'km',
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _caloriesController,
                      decoration: const InputDecoration(
                        labelText: 'Calories',
                        hintText: 'kcal',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildIntensitySelector(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Heart Rate Section
              _buildExpandableSection(
                title: 'Heart Rate',
                icon: Icons.favorite,
                isExpanded: _heartRateExpanded,
                onTap: () =>
                    setState(() => _heartRateExpanded = !_heartRateExpanded),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _avgHrController,
                          decoration: const InputDecoration(
                            labelText: 'Avg HR',
                            hintText: 'bpm',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextField(
                          controller: _maxHrController,
                          decoration: const InputDecoration(
                            labelText: 'Max HR',
                            hintText: 'bpm',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextField(
                          controller: _minHrController,
                          decoration: const InputDecoration(
                            labelText: 'Min HR',
                            hintText: 'bpm',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (!_manualOnly) ...[
              const SizedBox(height: AppSpacing.md),

              // Pace & Speed Section
              _buildExpandableSection(
                title: 'Pace & Speed',
                icon: Icons.speed,
                isExpanded: _paceExpanded,
                onTap: () => setState(() => _paceExpanded = !_paceExpanded),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _paceController,
                          decoration: const InputDecoration(
                            labelText: 'Avg Pace',
                            hintText: 'min/km',
                          ),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextField(
                          controller: _speedController,
                          decoration: const InputDecoration(
                            labelText: 'Avg Speed',
                            hintText: 'km/h',
                          ),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _elevationController,
                          decoration: const InputDecoration(
                            labelText: 'Elevation Gain',
                            hintText: 'meters',
                          ),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextField(
                          controller: _cadenceController,
                          decoration: const InputDecoration(
                            labelText: 'Cadence',
                            hintText: 'spm/rpm',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ], // end if (!_manualOnly)
              const SizedBox(height: AppSpacing.md),

              // Time in Zones Section
              _buildExpandableSection(
                title: 'Time in Zones',
                icon: Icons.bar_chart,
                isExpanded: _zonesExpanded,
                onTap: () => setState(() => _zonesExpanded = !_zonesExpanded),
                children: [
                  _buildZoneRow('Zone 1 (Rest)', Icons.favorite_border,
                      AppColors.pewter, _zone1Controller),
                  _buildZoneRow('Zone 2 (Fat Burn)', Icons.favorite,
                      AppColors.zoneFatBurn, _zone2Controller),
                  _buildZoneRow('Zone 3 (Cardio)', Icons.favorite,
                      AppColors.zoneRest, _zone3Controller),
                  _buildZoneRow('Zone 4 (Hard)', Icons.favorite,
                      AppColors.brandBlue, _zone4Controller),
                  _buildZoneRow(
                      'Zone 5 (Max)', Icons.favorite, AppColors.zonePeak, _zone5Controller),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Additional Metrics Section
              _buildExpandableSection(
                title: 'Additional Metrics',
                icon: Icons.more_horiz,
                isExpanded: _additionalExpanded,
                onTap: () =>
                    setState(() => _additionalExpanded = !_additionalExpanded),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _stepsController,
                          decoration: const InputDecoration(
                            labelText: 'Steps',
                            hintText: 'count',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextField(
                          controller: _floorsController,
                          decoration: const InputDecoration(
                            labelText: 'Floors Climbed',
                            hintText: 'count',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildWeatherSelector(),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'How did you feel?',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitActivity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                    foregroundColor: AppColors.paperWhite,
                    padding: const EdgeInsets.all(AppSpacing.md),
                  ),
                  child: const Text('Save Activity'),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Recent Activities
              Text('Recent Activities', style: AppTypography.label),
              const SizedBox(height: AppSpacing.md),
              BlocBuilder<ActivityBloc, ActivityState>(
                builder: (context, state) {
                  if (state.activities.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          'No activities logged yet',
                          style: AppTypography.bodySm
                              .copyWith(color: AppColors.pewter),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.activities.length.clamp(0, 5),
                    itemBuilder: (context, index) {
                      final activity = state.activities[index];
                      return _ActivityListItem(activity: activity);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoneRow(
      String label, IconData icon, Color color, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: AppTypography.bodySm)),
          SizedBox(
            width: 80,
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'min',
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Intensity', style: AppTypography.caption),
        const SizedBox(height: 4),
        Row(
          children: ActivityIntensity.values.map((intensity) {
            final isSelected = intensity == _selectedIntensity;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedIntensity = intensity),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.brandBlue : AppColors.warmLinen,
                    borderRadius: BorderRadius.horizontal(
                      left: intensity == ActivityIntensity.low
                          ? const Radius.circular(4)
                          : Radius.zero,
                      right: intensity == ActivityIntensity.high
                          ? const Radius.circular(4)
                          : Radius.zero,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      intensity.name[0].toUpperCase(),
                      style: AppTypography.bodySm.copyWith(
                        color: isSelected ? AppColors.paperWhite : AppColors.charcoal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWeatherSelector() {
    final weatherOptions = ['Sunny', 'Cloudy', 'Rainy', 'Windy', 'Indoor', 'Snowy'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Weather', style: AppTypography.caption),
        const SizedBox(height: 4),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: weatherOptions.map((weather) {
            final isSelected = weather == _selectedWeather;
            return GestureDetector(
              onTap: () => setState(() => _selectedWeather = weather),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.zoneFatBurn : AppColors.warmLinen,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  weather,
                  style: AppTypography.caption.copyWith(
                    color: isSelected ? AppColors.paperWhite : AppColors.charcoal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperWhite,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(AppRadius.cards),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.brandBlue, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(title, style: AppTypography.bodySm),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.pewter,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(children: children),
            ),
        ],
      ),
    );
  }

IconData _getIconForType(ActivityType type) => iconForActivity(type);
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;

  const _SummaryItem({required this.label, required this.value, this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style:
                  AppTypography.titleLarge.copyWith(color: AppColors.brandBlue),
            ),
            if (unit != null) ...[
              const SizedBox(width: 2),
              Text(unit!, style: AppTypography.caption),
            ],
          ],
        ),
      ],
    );
  }
}

class _ActivityListItem extends StatelessWidget {
  final Activity activity;

  const _ActivityListItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.paperWhite,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(AppRadius.cards),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getIconForType(activity.type),
                color: AppColors.charcoal,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity.name, style: AppTypography.bodySm),
                    Text(
                      '${activity.durationMinutes} min',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              if (activity.calories != null)
                Text(
                  '${activity.calories} kcal',
                  style: AppTypography.caption,
                ),
            ],
          ),
          if (activity.avgHr != null || activity.avgPace != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Row(
                children: [
                  if (activity.avgHr != null) ...[
                    Icon(Icons.favorite, size: 14, color: AppColors.zonePeak),
                    const SizedBox(width: 2),
                    Text('${activity.avgHr}', style: AppTypography.caption),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  if (activity.avgPace != null) ...[
                    Icon(Icons.speed, size: 14, color: AppColors.zoneFatBurn),
                    const SizedBox(width: 2),
                    Text('${activity.paceDisplay}/km', style: AppTypography.caption),
                  ],
                  if (activity.intensity != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getIntensityColor(activity.intensity!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        activity.intensity!.name.toUpperCase(),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.paperWhite,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getIntensityColor(ActivityIntensity intensity) {
    switch (intensity) {
      case ActivityIntensity.low:
        return AppColors.zoneRest;
      case ActivityIntensity.medium:
        return AppColors.brandBlue;
      case ActivityIntensity.high:
        return AppColors.zonePeak;
    }
  }

  IconData _getIconForType(ActivityType type) => iconForActivity(type);
}

/// Single source of truth for the Material icon associated with each
/// [ActivityType]. Keeps the page free of duplicated switch statements.
IconData iconForActivity(ActivityType type) {
  switch (type) {
    case ActivityType.run:
      return Icons.directions_run;
    case ActivityType.ride:
      return Icons.directions_bike;
    case ActivityType.swim:
      return Icons.pool;
    case ActivityType.gym:
      return Icons.fitness_center;
    case ActivityType.walk:
      return Icons.directions_walk;
    case ActivityType.hike:
      return Icons.terrain;
    case ActivityType.yoga:
      return Icons.self_improvement;
    case ActivityType.hiit:
      return Icons.timer;
    case ActivityType.rowing:
      return Icons.rowing;
    case ActivityType.basketball:
      return Icons.sports_basketball;
    case ActivityType.tennis:
      return Icons.sports_tennis;
    case ActivityType.soccer:
      return Icons.sports_soccer;
    case ActivityType.dancing:
      return Icons.nightlife;
    case ActivityType.boxing:
      return Icons.sports_mma;
    case ActivityType.climbing:
      return Icons.terrain;
    case ActivityType.skiing:
      return Icons.downhill_skiing;
    case ActivityType.snowboarding:
      return Icons.snowboarding;
    case ActivityType.elliptical:
      return Icons.circle_outlined;
    case ActivityType.stairmaster:
      return Icons.stairs;
    case ActivityType.other:
      return Icons.more_horiz;
  }
}

/// Toggle that flips the form into "Manual / No GPS" mode.
///
/// When [enabled] is true the form hides the Distance field and the
/// entire Pace & Speed section (pace / speed / cadence / elevation).
/// Submitted activities still carry heart rate, calories, zones,
/// intensity, weather and notes — only GPS-derived metrics are dropped.
class _ManualModeToggle extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ManualModeToggle({
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.cards),
        onTap: () => onChanged(!enabled),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: enabled ? AppColors.brandBlueTint : AppColors.paperWhite,
            border: Border.all(
              color: enabled ? AppColors.brandBlue : AppColors.hairline,
              width: enabled ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(AppRadius.cards),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: enabled
                      ? AppColors.brandBlue
                      : AppColors.brandBlueTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.favorite,
                  size: 20,
                  color: enabled
                      ? AppColors.paperWhite
                      : AppColors.brandBlue,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manual — No GPS',
                      style: AppTypography.titleLarge.copyWith(
                        color: enabled
                            ? AppColors.brandBlueDark
                            : AppColors.inkBlack,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      enabled
                          ? 'Recording heart rate and related metrics only'
                          : 'Tap to log without distance / pace / speed',
                      style: AppTypography.caption.copyWith(
                        color: enabled
                            ? AppColors.brandBlueDark
                            : AppColors.pewter,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Switch(
                value: enabled,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
