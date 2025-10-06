import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PassengerPollsPage extends StatelessWidget {
  const PassengerPollsPage({Key? key}) : super(key: key);

  Future<bool> _hasVoted(String pollId, String userId) async {
    try {
      final voteDoc = await FirebaseFirestore.instance
          .collection('polls')
          .doc(pollId)
          .collection('votes')
          .doc(userId)
          .get();
      return voteDoc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, int>> _getVoteCounts(String pollId, List<String> options) async {
    Map<String, int> counts = {};
    for (var option in options) {
      counts[option] = 0;
    }

    try {
      final votesSnapshot = await FirebaseFirestore.instance
          .collection('polls')
          .doc(pollId)
          .collection('votes')
          .get();

      for (var doc in votesSnapshot.docs) {
        final selectedOption = doc.data()['selectedOption'] as String?;
        if (selectedOption != null && counts.containsKey(selectedOption)) {
          counts[selectedOption] = counts[selectedOption]! + 1;
        }
      }
    } catch (e) {
      debugPrint("Error getting vote counts: $e");
    }

    return counts;
  }

  Future<String?> _getUserVote(String pollId, String userId) async {
    try {
      final voteDoc = await FirebaseFirestore.instance
          .collection('polls')
          .doc(pollId)
          .collection('votes')
          .doc(userId)
          .get();

      if (voteDoc.exists) {
        return voteDoc.data()?['selectedOption'] as String?;
      }
    } catch (e) {
      debugPrint("Error getting user vote: $e");
    }
    return null;
  }

  Future<void> _castVote(BuildContext context, String pollId, String option) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to vote')),
      );
      return;
    }

    try {
      // Simply set/update the vote - Firestore will overwrite the previous vote
      await FirebaseFirestore.instance
          .collection('polls')
          .doc(pollId)
          .collection('votes')
          .doc(user.uid)
          .set({
        'userId': user.uid,
        'selectedOption': option,
        'votedAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vote updated to $option!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error voting: $e')),
      );
    }
  }

  void _showAddDestinationDialog(BuildContext context) {
    final destinationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Destination'),
        content: TextField(
          controller: destinationController,
          decoration: const InputDecoration(
            labelText: 'Destination',
            hintText: 'e.g., Kannaga, Albuera, Tacloban',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final destination = destinationController.text.trim();

              if (destination.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a destination')),
                );
                return;
              }

              try {
                // Check if poll already exists
                final pollDoc = await FirebaseFirestore.instance
                    .collection('polls')
                    .doc('destinations')
                    .get();

                if (pollDoc.exists) {
                  // Add to existing options
                  final currentOptions = List<String>.from(pollDoc.data()?['options'] ?? []);

                  if (currentOptions.contains(destination)) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Destination already exists')),
                    );
                    return;
                  }

                  currentOptions.add(destination);
                  await FirebaseFirestore.instance
                      .collection('polls')
                      .doc('destinations')
                      .update({'options': currentOptions});
                } else {
                  // Create new poll
                  await FirebaseFirestore.instance
                      .collection('polls')
                      .doc('destinations')
                      .set({
                    'options': [destination],
                    'createdAt': Timestamp.now(),
                  });
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Destination added!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Where do you want to go?'),
        backgroundColor: Colors.blue,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDestinationDialog(context),
        icon: const Icon(Icons.add_location),
        label: const Text('Add Destination'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('polls')
            .doc('destinations')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading destinations'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.location_off, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'No destinations yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Add one using the button below!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final options = List<String>.from(data['options'] ?? []);

          if (options.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.location_off, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'No destinations yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('polls')
                .doc('destinations')
                .collection('votes')
                .snapshots(),
            builder: (context, votesSnapshot) {
              // Calculate vote counts from stream
              Map<String, int> voteCounts = {};
              for (var option in options) {
                voteCounts[option] = 0;
              }

              String? userVote;
              bool hasVoted = false;

              if (votesSnapshot.hasData) {
                for (var voteDoc in votesSnapshot.data!.docs) {
                  final voteData = voteDoc.data() as Map<String, dynamic>;
                  final selectedOption = voteData['selectedOption'] as String?;

                  if (selectedOption != null && voteCounts.containsKey(selectedOption)) {
                    voteCounts[selectedOption] = voteCounts[selectedOption]! + 1;
                  }

                  // Check if current user voted
                  if (voteDoc.id == user?.uid) {
                    hasVoted = true;
                    userVote = selectedOption;
                  }
                }
              }

              final totalVotes = voteCounts.values.fold(0, (sum, count) => sum + count);

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final voteCount = voteCounts[option] ?? 0;
                  final percentage = totalVotes > 0
                      ? (voteCount / totalVotes * 100).toStringAsFixed(1)
                      : '0.0';
                  final isSelected = userVote == option;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _castVote(context, 'destinations', option),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.shade50
                              : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.check_circle : Icons.location_on,
                                  color: isSelected ? Colors.blue : Colors.grey,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (hasVoted)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '$voteCount',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      Text(
                                        '$percentage%',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            if (hasVoted) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: totalVotes > 0 ? voteCount / totalVotes : 0,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isSelected ? Colors.blue : Colors.grey.shade400,
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}