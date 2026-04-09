import 'package:flutter/material.dart';


class DetailRespondenSurveyBpkPage extends StatefulWidget {
  const DetailRespondenSurveyBpkPage({super.key});

  @override
  State<DetailRespondenSurveyBpkPage> createState() =>
      _DetailRespondenSurveyPageState();
}

class _DetailRespondenSurveyPageState
    extends State<DetailRespondenSurveyBpkPage> {
  int selectedTab = 0;

  final List<Map<String, dynamic>> tabs = [
    {'label': 'Semua', 'count': 0},
    {'label': 'Terdaftar', 'count': 0},
    {'label': 'Campaign', 'count': 0},
    {'label': 'Guest', 'count': 0},
  ];

  final List<Map<String, dynamic>> statCards = [
    {
      'title': 'Total Responden',
      'count': 0,
      'icon': Icons.groups_rounded,
      'gradient': [Color(0xFF2E7D32), Color(0xFF43A047)],
    },
    {
      'title': 'Responden Terdaftar',
      'count': 0,
      'icon': Icons.verified_user_rounded,
      'gradient': [Color(0xFF00838F), Color(0xFF26C6DA)],
    },
    {
      'title': 'Campaign',
      'count': 0,
      'icon': Icons.campaign_rounded,
      'gradient': [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
    },
    {
      'title': 'Responden Guest',
      'count': 0,
      'icon': Icons.person_outline_rounded,
      'gradient': [Color(0xFF558B2F), Color(0xFF9CCC65)],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // ── HEADER ──
          _buildHeader(context),

          // ── CONTENT ──
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Stat Cards
                  SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: statCards.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) =>
                          _buildStatCard(statCards[index]),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tab Bar
                  _buildTabBar(),

                  const SizedBox(height: 40),

                  // Empty State
                  _buildEmptyState(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Detail Responden Survey",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Analisis data responden terdaftar, campaign, dan guest",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> data) {
    final gradients = data['gradient'] as List<Color>;
    return Container(
      width: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: gradients,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradients[0].withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data['icon'] as IconData, color: Colors.white, size: 22),
          ),
          const Spacer(),
          Text(
            data['title'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${data['count']}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = selectedTab == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tab['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.3)
                            : const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${tab['count']}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF888888),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_unread_rounded,
            color: Color(0xFF4CAF50),
            size: 34,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Belum Ada Responden",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Belum ada responden di kategori ini",
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFFAAAAAA),
          ),
        ),
      ],
    );
  }
}