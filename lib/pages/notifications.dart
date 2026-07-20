import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sale_manager/session.dart';
import 'package:sale_manager/config.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> notifications = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() => loading = true);
    final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/get_notifications.php'), headers: await Session.authHeaders());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        notifications = List<Map<String, dynamic>>.from(data['data']);
      }
    }
    setState(() => loading = false);
  }

  Future<void> markRead(int idNotification) async {
    await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/mark_notification_read.php'),
      headers: await Session.authHeaders(),
      body: jsonEncode({'idNotification': idNotification}),
    );
    await fetchNotifications();
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'stock_bas':
        return Icons.trending_down;
      case 'capacite_depassee':
        return Icons.warning_amber;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 63, 129, 86),
        title: const Text("Notifications", style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: fetchNotifications,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : notifications.isEmpty
                ? const Center(child: Text("Aucune notification"))
                : ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      final lue = n['lue'] == 1 || n['lue'] == true;
                      return Card(
                        color: lue ? null : const Color.fromARGB(255, 255, 244, 220),
                        child: ListTile(
                          leading: Icon(_iconFor(n['type']), color: lue ? Colors.grey : Colors.orange),
                          title: Text(n['message']),
                          subtitle: Text(n['cree_le'].toString()),
                          trailing: lue
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.check),
                                  tooltip: "Marquer comme lue",
                                  onPressed: () => markRead(n['id_notification']),
                                ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
