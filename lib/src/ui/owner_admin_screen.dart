import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerAdminScreen extends StatelessWidget {
  const OwnerAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Owner Admin'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Users'),
              Tab(text: 'Deletion Requests'),
              Tab(text: 'Activity (Today)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ---------------- USERS ----------------
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: db
                  .collection('users')
                  .orderBy('lastLoginAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();

                    final nameCtrl =
                    TextEditingController(text: data['name'] ?? '');
                    final roleCtrl =
                    TextEditingController(text: data['role'] ?? '');

                    return ListTile(
                      title: Text(data['phoneNumber'] ?? '(no phone)'),
                      subtitle: Text(
                        'Last login: ${data['lastLoginAt'] != null ? (data['lastLoginAt'] as Timestamp).toDate() : '-'}',
                      ),
                      trailing: SizedBox(
                        width: 250,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: nameCtrl,
                                decoration:
                                const InputDecoration(hintText: 'Name'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: roleCtrl,
                                decoration:
                                const InputDecoration(hintText: 'Role'),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: () async {
                                await db.collection('users').doc(doc.id).set({
                                  'name': nameCtrl.text,
                                  'role': roleCtrl.text.trim().toLowerCase(),
                                }, SetOptions(merge: true));
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // ---------------- DELETION REQUESTS ----------------
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: db
                  .collection('deletion_requests')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text('No pending requests.'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();

                    return Card(
                      margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text('${data['target']} → ${data['targetId']}'),
                        subtitle: Text(
                          'Requested by: ${data['requestedByUid']} '
                              'at ${data['requestedAt'] != null ? (data['requestedAt'] as Timestamp).toDate() : ''}',
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                if (data['target'] == 'voter') {
                                  await db
                                      .collection('voters')
                                      .doc(data['targetId'])
                                      .delete();
                                } else if (data['target'] == 'building') {
                                  // ⚠️ NOTE: In production, you'd use a Cloud Function
                                  // to delete all voters in that building.
                                }
                                await doc.reference.update({
                                  'status': 'approved',
                                  'resolvedAt': FieldValue.serverTimestamp(),
                                });
                              },
                              child: const Text('Approve'),
                            ),
                            OutlinedButton(
                              onPressed: () async {
                                await doc.reference.update({
                                  'status': 'rejected',
                                  'resolvedAt': FieldValue.serverTimestamp(),
                                });
                              },
                              child: const Text('Reject'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // ---------------- ACTIVITY LOGS ----------------
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: db
                  .collection('activity_logs')
                  .orderBy('at', descending: true)
                  .limit(200)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text('No activity today.'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();

                    return ListTile(
                      title: Text('${data['action']} — ${data['entity']}'),
                      subtitle: Text(
                        '${data['uid']} • '
                            '${data['at'] != null ? (data['at'] as Timestamp).toDate() : ''} '
                            '• ${data['entityId'] ?? ''}',
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
