import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_body_atlas/flutter_body_atlas.dart';
import 'package:stronger/infrastructure/services/muscle_fatigue_service.dart';

class MuscleMapPage extends StatefulWidget {
  const MuscleMapPage({super.key});

  @override
  State<MuscleMapPage> createState() => _MuscleMapPageState();
}

class _MuscleMapPageState extends State<MuscleMapPage> {
  // Maps Gemini keys → flutter_body_atlas SVG element IDs
  static const Map<String, List<String>> _muscleIds = {
    'chest': ['pectoralis_major_l', 'pectoralis_major_r'],
    'frontShoulders': ['anterior_deltoid_l', 'anterior_deltoid_r'],
    'biceps': [
      'biceps_brachii_caput_longum_l', 'biceps_brachii_caput_longum_r',
      'biceps_brachii_caput_breve_l', 'biceps_brachii_caput_breve_r',
    ],
    'forearms': [
      'brachioradialis_l', 'brachioradialis_r',
      'flexor_carpi_radialis_l', 'flexor_carpi_radialis_r',
      'flexor_carpi_ulnaris_l', 'flexor_carpi_ulnaris_r',
      'extensor_carpi_radialis_longus_l', 'extensor_carpi_radialis_longus_r',
    ],
    'abs': [
      'rectus_abdominis_1',
      'rectus_abdominis_2_l', 'rectus_abdominis_2_r',
      'rectus_abdominis_3_l', 'rectus_abdominis_3_r',
      'rectus_abdominis_4_l', 'rectus_abdominis_4_r',
      'external_oblique_1_l', 'external_oblique_1_r',
    ],
    'quads': [
      'rectus_femoris_l', 'rectus_femoris_r',
      'vastus_lateralis_l', 'vastus_lateralis_r',
      'vastus_medialis_l', 'vastus_medialis_r',
    ],
    'calves': [
      'gastrocnemius_l', 'gastrocnemius_r',
      'tibialis_anterior_l', 'tibialis_anterior_r',
      'fibularis_longus_l', 'fibularis_longus_r',
    ],
    'traps': [
      'trapezius_upper_l', 'trapezius_upper_r',
      'trapezius_middle_l', 'trapezius_middle_r',
      'trapezius_lower_l', 'trapezius_lower_r',
    ],
    'lats': ['latissimus_dorsi_l', 'latissimus_dorsi_r'],
    'rearShoulders': ['posterior_deltoid_l', 'posterior_deltoid_r'],
    'triceps': [
      'triceps_brachii_caput_laterale_l', 'triceps_brachii_caput_laterale_r',
      'triceps_brachii_caput_longum_l', 'triceps_brachii_caput_longum_r',
      'triceps_brachii_caput_mediale_l', 'triceps_brachii_caput_mediale_r',
    ],
    'glutes': [
      'gluteus_maximus_l', 'gluteus_maximus_r',
      'gluteus_medius_1_l', 'gluteus_medius_1_r',
      'gluteus_medius_2_l', 'gluteus_medius_2_r',
    ],
    'hamstrings': [
      'semimembranosus_1_l', 'semimembranosus_1_r',
      'semimembranosus_2_l', 'semimembranosus_2_r',
      'semitendinosus_l', 'semitendinosus_r',
      'biceps_femoris_l', 'biceps_femoris_r',
    ],
    'lowerBack': [
      // erector spinae group — IDs may vary by package version
      'erector_spinae_l', 'erector_spinae_r',
    ],
  };

  final _service = MuscleFatigueService();
  bool _showFront = true;
  bool _loading = true;
  Map<String, double> _scores = {};

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final scores =
        uid != null ? await _service.loadCurrentScores(uid) : <String, double>{};
    if (!mounted) return;
    setState(() {
      _scores = scores;
      _loading = false;
    });
  }

  Map<MuscleInfo, Color> _buildColorMapping() {
    final mapping = <MuscleInfo, Color>{};
    for (final entry in _scores.entries) {
      final ids = _muscleIds[entry.key] ?? [];
      final color = _scoreToColor(entry.value);
      for (final id in ids) {
        final info = MuscleCatalog.tryById(id);
        if (info != null) mapping[info] = color;
      }
    }
    return mapping;
  }

  Color _scoreToColor(double score) {
    if (score < 25) return const Color(0xFF4CAF50); // verde  — descansado
    if (score < 50) return const Color(0xFFFFC107); // amarillo — recuperando
    if (score < 75) return const Color(0xFFFF9800); // naranja  — cansado
    return const Color(0xFFF44336); //               rojo     — fatigado
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Muscular'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () {
              setState(() => _loading = true);
              _loadScores();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 12),
                _buildToggle(),
                Expanded(child: _buildAtlas()),
                _buildLegend(),
                const SizedBox(height: 8),
              ],
            ),
    );
  }

  Widget _buildToggle() {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(
          value: true,
          label: Text('Frontal'),
          icon: Icon(Icons.face),
        ),
        ButtonSegment(
          value: false,
          label: Text('Dorsal'),
          icon: Icon(Icons.face_retouching_natural),
        ),
      ],
      selected: {_showFront},
      onSelectionChanged: (s) => setState(() => _showFront = s.first),
    );
  }

  Widget _buildAtlas() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: BodyAtlasView<MuscleInfo>(
        view: _showFront ? AtlasAsset.musclesFront : AtlasAsset.musclesBack,
        resolver: const MuscleResolver(),
        colorMapping: _buildColorMapping(),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _chip(const Color(0xFF4CAF50), 'Descansado'),
          _chip(const Color(0xFFFFC107), 'Recuperando'),
          _chip(const Color(0xFFFF9800), 'Cansado'),
          _chip(const Color(0xFFF44336), 'Fatigado'),
          _chip(Colors.grey, 'Sin datos'),
        ],
      ),
    );
  }

  Widget _chip(Color color, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 9)),
      ],
    );
  }
}
