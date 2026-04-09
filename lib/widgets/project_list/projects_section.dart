import 'package:flutter/material.dart';
import '../../models/client_model.dart';
import '../../models/project_model.dart';
import '../../core/theme/app_theme.dart';
import 'header_cell.dart';
import 'project_row.dart';

class ProjectsSection extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearch;
  final List<Project> projects;
  final Client client;

  const ProjectsSection({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.onSearch,
    required this.projects,
    required this.client,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 14),
        _buildSearchBar(),
        const SizedBox(height: 12),
        _buildTable(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.green,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Projects',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            Text(
              '${projects.length} project found',
              style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: TextField(
        controller: searchController,
        onChanged: onSearch,
        style: const TextStyle(fontSize: 12),
        decoration: const InputDecoration(
          hintText: 'Search projects...',
          hintStyle: TextStyle(color: AppTheme.textGrey, fontSize: 12),
          prefixIcon: Icon(Icons.search, size: 18, color: AppTheme.textGrey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            _buildTableHeader(),
            if (projects.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Tidak ada project ditemukan.',
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
                  ),
                ),
              )
            else
              ...projects.asMap().entries.map((entry) {
                return ProjectRow(
                  index:   entry.key + 1,
                  project: entry.value,
                  client:  client,
                  isLast:  entry.key == projects.length - 1,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: AppTheme.green,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: const Row(
        children: [
          SizedBox(width: 28),
          SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: HeaderCell(
              icon: Icons.assignment_outlined,
              label: 'PROJECT NAME',
            ),
          ),
          Expanded(
            flex: 5,
            child: HeaderCell(
              icon: Icons.notes_outlined,
              label: 'DESCRIPTION',
            ),
          ),
          SizedBox(
            width: 80,
            child: HeaderCell(
              icon: Icons.list_alt_outlined,
              label: 'SURVEYS',
            ),
          ),
        ],
      ),
    );
  }
}