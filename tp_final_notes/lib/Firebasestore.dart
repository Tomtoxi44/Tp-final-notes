import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tp_final_notes/main.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirestorePage extends StatefulWidget {
  @override
  _FirestorePageState createState() => _FirestorePageState();
}

class _FirestorePageState extends State<FirestorePage> {
  CollectionReference? notes;
  bool isLoading = true;
  String? _imageUrl;
  File? _image;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImageAndGetUrl() async {
    if (_image == null) return null;

    String fileName =
        'images/${DateTime.now().millisecondsSinceEpoch}_${_image!.path.split('/').last}';
    try {
      TaskSnapshot snapshot =
          await FirebaseStorage.instance.ref().child(fileName).putFile(_image!);
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print(e); 
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _setupNotes();
  }

  void _deleteNote(DocumentSnapshot document) async {
    await notes?.doc(document.id).delete();
  }

  // fonction pour vérifier l'utilisateur si il est bien connecté et 
  void _setupNotes() {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;
    if (user != null) {
      notes = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notes');
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const MyHomePage(title: "Connexion page"),
        ));
      });
    }
    setState(() => isLoading = false);
  }

  Future<String?> uploadImageAndGetUrl() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      String fileName =
          'images/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
      try {
        TaskSnapshot snapshot =
            await FirebaseStorage.instance.ref().child(fileName).putFile(file);
        String downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      } catch (e) {
        print(e);
        return null;
      }
    } else {
      print('Aucune image sélectionnée.');
      return null;
    }
  }

  // fonction pour ajouter une notes ou l'update et l'ajout d'image
  void _addOrUpdateNote(BuildContext context,
      [DocumentSnapshot? documentSnapshot]) async {
    String action = documentSnapshot == null ? 'add' : 'update';
    TextEditingController titleController =
        TextEditingController(text: documentSnapshot?.get('title'));
    TextEditingController contentController =
        TextEditingController(text: documentSnapshot?.get('content'));

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (BuildContext ctx) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
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
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
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
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text("Choisir une Image"),
                ),
                _image != null ? Image.file(_image!, width: 100, height: 100) : Container(),
                ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, backgroundColor: Colors.deepPurple,
        ),
        child: Text(action == 'add' ? 'Create' : 'Update'),
        onPressed: () async {
          String title = titleController.text;
          String content = contentController.text;

          // Télécharger l'image uniquement si elle est sélectionnée
          String? imageUrl;
          if (_image != null) {
            imageUrl = await _uploadImageAndGetUrl();
          }

          if (title.isNotEmpty && content.isNotEmpty) {
            Map<String, dynamic> noteData = {
              'title': title,
              'content': content,
              'imageUrl': imageUrl
            };
            if (action == 'add') {
              await notes!.add(noteData);
            } else {
              await notes!.doc(documentSnapshot!.id).update(noteData);
            }
            Navigator.of(ctx).pop();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // fonction de déconnexion
  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => const MyHomePage(title: "Connexion page"),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || notes == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        title: const Text('Notes'),
        backgroundColor: Colors.grey[900],
        actions: [
          // Button de déconnexion
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notes!.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text("Loading");
          }
          // Liste des notes
          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data()! as Map<String, dynamic>;
              return ListTile(
                tileColor: Colors.grey[800],
                leading: data['imageUrl'] != null
                    ? Image.network(data['imageUrl'],
                        width: 100, height: 100, fit: BoxFit.cover)
                    : null,
                title: Text(data['title'],
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(data['content'],
                    style: TextStyle(color: Colors.grey[300])),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Button qui apelle une fonction pour update la note
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.amber),
                      onPressed: () => _addOrUpdateNote(context, document),
                    ),
                    // Button qui apelle une fonction pour supprimer la note
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        _deleteNote;
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
