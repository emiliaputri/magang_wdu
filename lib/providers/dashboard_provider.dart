import 'package:flutter/material.dart';
import '../service/auth_service.dart';
import '../service/client_service.dart';
import '../models/client_model.dart';
import '../models/user_project_model.dart';

class DashboardProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ClientService _clientService = ClientService();

  Map<String, dynamic>? user;
  List<Client> clients = [];
  List<UserProject> projects = [];
  bool loading = true;
  bool clientsLoading = true;
  String? error;
  String clientSearch = '';

  List<Client> get filteredClients {
    if (clientSearch.isEmpty) return clients;
    final q = clientSearch.toLowerCase();
    return clients
        .where((c) => c.clientName.toLowerCase().contains(q))
        .toList();
  }

  List<UserProject> get filteredProjects {
    if (clientSearch.isEmpty) return projects;
    final q = clientSearch.toLowerCase();
    return projects
        .where((p) =>
            p.projectName.toLowerCase().contains(q) ||
            p.clientName.toLowerCase().contains(q))
        .toList();
  }

  Future<void> init() async {
    await loadUser(); // ✅ tunggu token tersimpan dulu
    await loadClients(); // ✅ baru fetch clients
  }

  Future<void> loadUser() async {
    try {
      user = await _authService.getUser();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // dashboard_provider.dart
Future<void> loadClients() async {
  try {
    clientsLoading = true;
    notifyListeners();

    final data = await _clientService.getDashboardData();

    final List<dynamic> rawClients  = (data['clients']     as List<dynamic>?) ?? [];
    final List<dynamic> rawProjects = (data['userProjects'] as List<dynamic>?) ?? [];

    // ✅ debug per item untuk cari yang error
    clients = [];
    for (final e in rawClients) {
      try {
        clients.add(Client.fromJson(e));
      } catch (err) {
        print('Error parse Client: $err');
        print('Data: $e');
      }
    }

    projects = [];
    for (final e in rawProjects) {
      try {
        UserProject p = UserProject.fromJson(e);

        // ✅ SINKRONISASI LOGO: Jika project tidak punya logo, cari dari list clients
        if (p.clientImage == null || p.clientImage!.isEmpty) {
          final clientMatch = clients.where((c) => c.slug == p.clientSlug).firstOrNull;
          if (clientMatch != null && clientMatch.image != null) {
            p = p.copyWith(clientImage: clientMatch.image);
          }
        }

        projects.add(p);
      } catch (err) {
        print('Error parse UserProject: $err');
        print('Data: $e');
      }
    }

    print('Clients parsed: ${clients.length}');
    print('Projects parsed: ${projects.length}');

    error = null;
  } catch (e) {
    print('Error loadClients: $e');
    error = e.toString();
  } finally {
    clientsLoading = false;
    notifyListeners();
  }
}

  void updateSearch(String val) {
    clientSearch = val;
    notifyListeners();
  }
}
