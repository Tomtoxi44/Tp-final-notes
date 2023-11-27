import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tp_final_notes/main.dart';

class FirestorePage extends StatelessWidget {
  final CollectionReference notes = FirebaseFirestore.instance.collection('notes');

  void _addOrUpdateNote(BuildContext context, [DocumentSnapshot? documentSnapshot]) async {
    String action = 'add';
    TextEditingController titleController = TextEditingController();
    TextEditingController contentController = TextEditingController();

    if (documentSnapshot != null) {
      action = 'update';
      titleController.text = documentSnapshot['title'];
      contentController.text = documentSnapshot['content'];
    }

    await showModalBottomSheet(
  context: context,
  backgroundColor: Colors.grey[900],
  builder: (BuildContext ctx) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom, 
      ),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
      
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepPurpleAccent),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 10),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepPurpleAccent),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.deepPurple, 
                ),
                child: Text(action == 'add' ? 'Create' : 'Update'),
                onPressed: () async {
                  String title = titleController.text;
                  String content = contentController.text;
                  if (title.isNotEmpty && content.isNotEmpty) {
                    if (action == 'add') {
                      await notes.add({'title': title, 'content': content});
                    } else {
                      await notes.doc(documentSnapshot!.id).update({'title': title, 'content': content});
                    }
                    Navigator.of(ctx).pop();
                  }
                },
              )
            ],
          ),
      )
        );
      },
    );
  }
    void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => MyHomePage(title: "Connexion page"), 
    ));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        title: const Text('Notes'),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notes.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text("Loading");
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
              return ListTile(
                tileColor: Colors.grey[800],
                title: Text(data['title'], style: TextStyle(color: Colors.white)),
                subtitle: Text(data['content'], style: TextStyle(color: Colors.grey[300])),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.amber),
                      onPressed: () => _addOrUpdateNote(context, document),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await notes.doc(document.id).delete();
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => _addOrUpdateNote(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
