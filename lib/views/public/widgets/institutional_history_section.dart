import 'package:flutter/material.dart';

class InstitutionalHistorySection extends StatefulWidget {
  final void Function(String department)? onOpenDepartment;
  final VoidCallback? onContact;

  const InstitutionalHistorySection({
    super.key,
    this.onOpenDepartment,
    this.onContact,
  });

  @override
  State<InstitutionalHistorySection> createState() => _InstitutionalHistorySectionState();
}

class _InstitutionalHistorySectionState extends State<InstitutionalHistorySection> {

  final List<Map<String, dynamic>> _entities = [
    {
      'title': 'GM Auto Solutions',
      'dept': 'GM Autosolution',
      'icon': Icons.directions_car_filled_rounded,
      'color': Color(0xFF1B7AE6),
      'badge': 'Secteur Automobile',
      'description': 'Orientée vers les services automobiles, l’entretien technique et les solutions pratiques liées aux véhicules.',
      'tag': 'Solutions Techniques',
    },
    {
      'title': 'GM Texas Visa & Billets d’Avions',
      'dept': 'GM Texa',
      'icon': Icons.flight_takeoff_rounded,
      'color': Color(0xFF00BFA5),
      'badge': 'Mobilité & Voyages',
      'description': 'Orientée vers l’accompagnement dans les démarches de voyage, les visas et les services liés à la billetterie aérienne.',
      'tag': 'Mobilité Internationale',
    },
    {
      'title': 'GM Foundation Company LTD',
      'dept': 'GM Foundation Company LTD',
      'icon': Icons.volunteer_activism_rounded,
      'color': Color(0xFF10B981),
      'badge': 'Impact Social & Humanitaire',
      'description': 'Orientée vers les initiatives sociales, humanitaires, culturelles, éducatives et le soutien aux personnes vulnérables.',
      'tag': 'Solidarité & Jeunesse',
    },
    {
      'title': 'GM Media & Production',
      'dept': 'GM Media & Production',
      'icon': Icons.movie_filter_rounded,
      'color': Color(0xFFF59E0B),
      'badge': 'Création & Communication',
      'description': 'Orientée vers la communication, la création de contenus, la production audiovisuelle, la promotion et la valorisation des talents.',
      'tag': 'Valorisation des Talents',
    },
  ];

  final List<Map<String, dynamic>> _philosophyPillars = [
    {'icon': Icons.visibility_rounded, 'title': 'Vision', 'desc': 'Voir au-delà des limites immédiates.'},
    {'icon': Icons.school_rounded, 'title': 'Formation', 'desc': 'Apprendre continuellement.'},
    {'icon': Icons.emoji_events_rounded, 'title': 'Excellence', 'desc': 'Rechercher l’amélioration permanente.'},
    {'icon': Icons.lightbulb_rounded, 'title': 'Innovation', 'desc': 'Transformer les problèmes en possibilités.'},
    {'icon': Icons.military_tech_rounded, 'title': 'Discipline', 'desc': 'Transformer les intentions en actions.'},
    {'icon': Icons.verified_user_rounded, 'title': 'Intégrité', 'desc': 'Construire avec responsabilité.'},
    {'icon': Icons.handshake_rounded, 'title': 'Solidarité', 'desc': 'Ne pas réussir seul.'},
    {'icon': Icons.face_retouching_natural_rounded, 'title': 'Jeunesse', 'desc': 'Investir dans le potentiel humain.'},
    {'icon': Icons.auto_awesome_rounded, 'title': 'Spiritualité', 'desc': 'Donner un sens supérieur à l’action.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF071424),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 90),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // 1. HEADER INSTITUTIONNEL & SLOGAN
              // ==========================================
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF59D6B6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFF59D6B6).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.history_edu_rounded, size: 16, color: Color(0xFF59D6B6)),
                          SizedBox(width: 8),
                          Text(
                            'PRÉSENTATION INSTITUTIONNELLE & HISTOIRE',
                            style: TextStyle(
                              color: Color(0xFF59D6B6),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'GM GROUPE – GREAT MINDS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF59D6B6).withValues(alpha: 0.2),
                            const Color(0xFF1B7AE6).withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF59D6B6).withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        '« Construire l’excellence – Faire grandir le peu »',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF59D6B6),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 880),
                      child: const Text(
                        'GM Groupe – Great Minds est une structure entrepreneuriale conçue comme un écosystème de réflexion, d’action, de formation, d’innovation et de développement humain. Son ambition est de réunir sous une même vision plusieurs domaines d’activités complémentaires afin de transformer les idées en projets, les compétences en opportunités et les opportunités en résultats durables.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFCBDCEB),
                          fontSize: 16,
                          height: 1.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.psychology_rounded, size: 28, color: Color(0xFF59D6B6)),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Le terme « Great Minds », qui signifie « grands esprits », traduit une philosophie fondamentale : les grandes réalisations commencent par une vision, une pensée structurée et la capacité de transformer cette pensée en action.',
                                style: TextStyle(
                                  color: Color(0xFFEAF4FC),
                                  fontSize: 14,
                                  height: 1.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // ==========================================
              // 2. L'ÉCOSYSTÈME MULTISECTORIEL (4 PÔLES)
              // ==========================================
              Row(
                children: const [
                  Icon(Icons.account_tree_rounded, color: Color(0xFF59D6B6), size: 22),
                  SizedBox(width: 10),
                  Text(
                    'III. L’ÉCOSYSTÈME MULTISECTORIEL GM GROUPE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'GM Groupe constitue la tête stratégique et organisationnelle qui réunit et coordonne plusieurs entités spécialisées :',
                style: TextStyle(color: Color(0xFFA0BFDA), fontSize: 14),
              ),
              const SizedBox(height: 20),

              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 780;
                  final width = compact ? double.infinity : (constraints.maxWidth - 20) / 2;

                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: _entities.map((ent) {
                      return SizedBox(
                        width: width,
                        child: _buildEntityCard(ent),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 60),

              // ==========================================
              // 3. LA JEUNESSE : POINT FOCAL & CHAÎNE STRATÉGIQUE
              // ==========================================
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0E2A47), Color(0xFF091E34)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF1B558B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF59D6B6).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.rocket_launch_rounded, color: Color(0xFF59D6B6), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'II. LA JEUNESSE : LE POINT FOCAL',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '« Faire grandir la jeunesse, c’est contribuer à l’équilibre du présent. »',
                                style: TextStyle(
                                  color: Color(0xFF59D6B6),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'La jeunesse représente le point focal de la stratégie de GM Groupe. Cette orientation repose sur une conviction : investir dans la jeunesse revient à investir dans le présent et dans la capacité de construire l’avenir.\n\nGM Groupe souhaite créer un environnement dans lequel le jeune n’est pas seulement considéré comme un bénéficiaire, mais comme un acteur économique, social et intellectuel capable de participer à la construction de solutions.',
                      style: TextStyle(color: Color(0xFFCBDCEB), fontSize: 14, height: 1.6),
                    ),
                    const SizedBox(height: 24),

                    // Frise séquentielle de création de valeur
                    const Text(
                      'Idée stratégique de création de valeur GM :',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    _buildValueFlowStepper(context),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // ==========================================
              // 4. LES PILIERS ET DIMENSIONS FONDAMENTALES (I, IV, V, VI, VII, VIII)
              // ==========================================
              Row(
                children: const [
                  Icon(Icons.auto_stories_rounded, color: Color(0xFF59D6B6), size: 22),
                  SizedBox(width: 10),
                  Text(
                    'LES DIMENSIONS FONDAMENTALES DU GROUPE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 800;
                  final itemWidth = compact ? double.infinity : (constraints.maxWidth - 24) / 2;

                  return Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      // I. Vision fondée sur la connaissance
                      SizedBox(
                        width: itemWidth,
                        child: _buildDimensionCard(
                          icon: Icons.psychology_alt_rounded,
                          color: const Color(0xFF1B7AE6),
                          number: 'I',
                          title: 'Vision fondée sur la connaissance',
                          content: 'Le capital humain constitue l’un des principaux moteurs du développement. Dans un environnement économique en constante mutation, la capacité d’apprendre, de s’adapter et d’innover devient une ressource stratégique.',
                        ),
                      ),
                      // IV. La formation comme moteur
                      SizedBox(
                        width: itemWidth,
                        child: _buildDimensionCard(
                          icon: Icons.model_training_rounded,
                          color: const Color(0xFF00BFA5),
                          number: 'IV',
                          title: 'Formation & Transformation',
                          content: 'GM Groupe ne veut pas simplement créer des activités ; il veut également créer des capacités. Les formations continues de haut niveau permettent d’acquérir des compétences pratiques, techniques et managériales contemporaines.',
                        ),
                      ),
                      // V. Dimension scientifique & entrepreneuriale
                      SizedBox(
                        width: itemWidth,
                        child: _buildDimensionCard(
                          icon: Icons.biotech_rounded,
                          color: const Color(0xFF10B981),
                          number: 'V',
                          title: 'Dimension Scientifique & Méthode',
                          content: 'Recherche de méthodes, observation, analyse des besoins, expérimentation rigoureuse, mesure des résultats et amélioration continue :\n\nObservation ➔ Analyse ➔ Expérimentation ➔ Évaluation ➔ Amélioration.',
                        ),
                      ),
                      // VI. Dimension spirituelle
                      SizedBox(
                        width: itemWidth,
                        child: _buildDimensionCard(
                          icon: Icons.self_improvement_rounded,
                          color: const Color(0xFF9333EA),
                          number: 'VI',
                          title: 'Dimension Spirituelle & Intérieure',
                          content: 'Le développement matériel doit être accompagné par le développement intérieur. La réussite se traduit par la capacité de développer ses talents, servir son prochain, transmettre son savoir et contribuer à une œuvre collective supérieure.',
                        ),
                      ),
                      // VII. Viser la lune
                      SizedBox(
                        width: itemWidth,
                        child: _buildDimensionCard(
                          icon: Icons.nightlight_round,
                          color: const Color(0xFFF59E0B),
                          number: 'VII',
                          title: 'Viser la Lune 🌙',
                          content: 'Refuser de limiter sa vision aux frontières de l’immédiat. Une grande ambition accompagnée d’une méthode, d’une discipline et d’une progression étape par étape. La lune représente la vision, la persévérance et l’élévation.',
                        ),
                      ),
                      // VIII. Construire l'avenir à partir du présent
                      SizedBox(
                        width: itemWidth,
                        child: _buildDimensionCard(
                          icon: Icons.foundation_rounded,
                          color: const Color(0xFFEC4899),
                          number: 'VIII',
                          title: 'Construire l’Avenir dès le Présent',
                          content: '« Faire grandir les personnes pour faire grandir les structures, et faire grandir les structures pour contribuer au développement de la société. » Travailler sur le présent pour hisser nos structures aux standards internationaux.',
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 60),

              // ==========================================
              // 5. VISION & MISSION (BLOCS D'IMPACT)
              // ==========================================
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 780;
                  return compact
                      ? Column(
                          children: [
                            _buildVisionBox(),
                            const SizedBox(height: 20),
                            _buildMissionBox(),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: _buildVisionBox()),
                            const SizedBox(width: 24),
                            Expanded(child: _buildMissionBox()),
                          ],
                        );
                },
              ),

              const SizedBox(height: 60),

              // ==========================================
              // 6. PHILOSOPHIE (LES 9 PILIERS GM)
              // ==========================================
              Center(
                child: Column(
                  children: [
                    const Text(
                      'XI. NOTRE PHILOSOPHIE EN 9 PILIERS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Les valeurs cardinales qui guident chacune de nos décisions et actions',
                      style: TextStyle(color: Color(0xFFA0BFDA), fontSize: 14),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),

              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 650;
                  final medium = constraints.maxWidth < 950;
                  final width = compact
                      ? double.infinity
                      : medium
                          ? (constraints.maxWidth - 20) / 2
                          : (constraints.maxWidth - 40) / 3;

                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: _philosophyPillars.map((p) {
                      return SizedBox(
                        width: width,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E2238),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFF1E4369)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF59D6B6).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(p['icon'] as IconData, color: const Color(0xFF59D6B6), size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p['title'] as String,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      p['desc'] as String,
                                      style: const TextStyle(
                                        color: Color(0xFFB0CFE8),
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 60),

              // ==========================================
              // 7. MANTRAS & CONCLUSION GM
              // ==========================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF04483C), Color(0xFF062340)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF59D6B6).withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF59D6B6).withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.star_rounded, size: 40, color: Color(0xFF59D6B6)),
                    const SizedBox(height: 14),
                    const Text(
                      'LES 5 MANTRAS DU GROUPE',
                      style: TextStyle(
                        color: Color(0xFF59D6B6),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: const [
                        _MantraChip(label: 'GRANDIR PAR LA CONNAISSANCE'),
                        _MantraChip(label: 'CONSTRUIRE PAR L’ACTION'),
                        _MantraChip(label: 'SERVIR PAR LA RESPONSABILITÉ'),
                        _MantraChip(label: 'ÉLEVER PAR LA FORMATION'),
                        _MantraChip(label: 'VISER LA LUNE 🌙'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 18),
                    const Text(
                      '« GM GROUPE – GREAT MINDS : Construire l’excellence – Faire grandir le peu »',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntityCard(Map<String, dynamic> ent) {
    final color = ent['color'] as Color;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0C223A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(ent['icon'] as IconData, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ent['badge'] as String,
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      ent['title'] as String,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            ent['description'] as String,
            style: const TextStyle(color: Color(0xFFCBDCEB), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ent['tag'] as String,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () {
                  widget.onOpenDepartment?.call(ent['dept'] as String);
                },
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('Découvrir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueFlowStepper(BuildContext context) {
    final steps = [
      {'num': '1', 'title': 'Idée', 'desc': 'Vision structurée', 'icon': Icons.lightbulb_outline_rounded},
      {'num': '2', 'title': 'Formation', 'desc': 'Savoirs pratiques', 'icon': Icons.school_outlined},
      {'num': '3', 'title': 'Compétence', 'desc': 'Maîtrise technique', 'icon': Icons.bolt_rounded},
      {'num': '4', 'title': 'Opportunité', 'desc': 'Marché & emploi', 'icon': Icons.work_outline_rounded},
      {'num': '5', 'title': 'Expérience', 'desc': 'Pratique réelle', 'icon': Icons.trending_up_rounded},
      {'num': '6', 'title': 'Valeur', 'desc': 'Création durable', 'icon': Icons.diamond_outlined},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        if (compact) {
          return Column(
            children: steps.map((s) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF59D6B6),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          s['num'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF061A2E), fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(s['icon'] as IconData, size: 18, color: const Color(0xFF59D6B6)),
                    const SizedBox(width: 8),
                    Text(s['title'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                    const Spacer(),
                    Text(s['desc'] as String, style: const TextStyle(color: Color(0xFFA0BFDA), fontSize: 11)),
                  ],
                ),
              );
            }).toList(),
          );
        }

        return Row(
          children: steps.asMap().entries.map((entry) {
            final idx = entry.key;
            final s = entry.value;
            final isLast = idx == steps.length - 1;

            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF1B558B)),
                      ),
                      child: Column(
                        children: [
                          Icon(s['icon'] as IconData, size: 20, color: const Color(0xFF59D6B6)),
                          const SizedBox(height: 6),
                          Text(
                            s['title'] as String,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s['desc'] as String,
                            style: const TextStyle(color: Color(0xFFA0BFDA), fontSize: 9),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF59D6B6)),
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDimensionCard({
    required IconData icon,
    required Color color,
    required String number,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2239),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  number,
                  style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            content,
            style: const TextStyle(color: Color(0xFFCBDCEB), fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildVisionBox() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F365C), Color(0xFF0B243E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF225C95)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.flag_rounded, color: Color(0xFF59D6B6), size: 24),
              SizedBox(width: 10),
              Text(
                'IX. NOTRE VISION',
                style: TextStyle(color: Color(0xFF59D6B6), fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          SizedBox(height: 14),
          Text(
            'GM Groupe – Great Minds aspire à devenir progressivement un écosystème entrepreneurial de référence capable de réunir entrepreneuriat, formation, innovation, mobilité, technologie, communication, services, responsabilité sociale et développement de la jeunesse.',
            style: TextStyle(color: Colors.white, fontSize: 14, height: 1.7),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionBox() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B463E), Color(0xFF072B26)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF157B6D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.track_changes_rounded, color: Color(0xFF59D6B6), size: 24),
              SizedBox(width: 10),
              Text(
                'X. NOTRE MISSION',
                style: TextStyle(color: Color(0xFF59D6B6), fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          SizedBox(height: 14),
          Text(
            'Développer les compétences, créer des opportunités, accompagner l’entrepreneuriat, valoriser la jeunesse et construire des solutions innovantes dans différents secteurs d’activité, tout en intégrant une dimension sociale, humaine et spirituelle au développement.',
            style: TextStyle(color: Colors.white, fontSize: 14, height: 1.7),
          ),
        ],
      ),
    );
  }
}

class _MantraChip extends StatelessWidget {
  final String label;

  const _MantraChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF59D6B6).withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
