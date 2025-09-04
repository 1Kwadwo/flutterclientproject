import 'package:flutter/foundation.dart';
import '../models/client.dart';
import '../services/simple_storage.dart';

class ClientProvider with ChangeNotifier {
  final SimpleStorage _storage = SimpleStorage();
  List<Client> _clients = [];
  bool _isLoading = false;

  List<Client> get clients => _clients;
  bool get isLoading => _isLoading;

  Future<void> loadClients() async {
    _isLoading = true;
    notifyListeners();

    try {
      _clients = await _storage.getAllClients();
    } catch (e) {
      debugPrint('Error loading clients: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addClient(Client client) async {
    try {
      final id = await _storage.insertClient(client);
      final newClient = client.copyWith(id: id);
      _clients.add(newClient);
      _clients.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding client: $e');
      rethrow;
    }
  }

  Future<void> updateClient(Client client) async {
    try {
      await _storage.updateClient(client);
      final index = _clients.indexWhere((c) => c.id == client.id);
      if (index != -1) {
        _clients[index] = client;
        _clients.sort((a, b) => a.name.compareTo(b.name));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating client: $e');
      rethrow;
    }
  }

  Future<void> deleteClient(int id) async {
    try {
      debugPrint('Deleting client with ID: $id');
      await _storage.deleteClient(id);
      // Reload all clients to ensure UI is in sync
      await loadClients();
      debugPrint(
        'Client deleted successfully. Remaining clients: ${_clients.length}',
      );
    } catch (e) {
      debugPrint('Error deleting client: $e');
      rethrow;
    }
  }

  Client? getClientById(int id) {
    try {
      return _clients.firstWhere((client) => client.id == id);
    } catch (e) {
      return null;
    }
  }
}
