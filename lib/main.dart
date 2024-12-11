import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_firestore_tuto/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class Todo {
  final String? uid;
  final String title;

  Todo({this.uid, required this.title});

  Map<String, dynamic> toJson() {
    return {'title': title};
  }

  factory Todo.fromJson(String id, Map<String, dynamic> json) {
    return Todo(uid: id, title: json['title']);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController todoController = TextEditingController();
  FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final Stream<QuerySnapshot> _todosStream =
      FirebaseFirestore.instance.collection('todos').snapshots();
  List<Todo> todos = [];

  @override
  void initState() {
    _loadTodos();
    super.initState();
  }

  @override
  void dispose() {
    todoController.dispose();
    super.dispose();
  }

  void _addTodo() async {
    Todo todo = Todo(title: todoController.text);

    try {
      await firebaseFirestore.collection("todos").add(todo.toJson());
      todoController.clear();
      _loadTodos();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  void _loadTodos() async {
    try {
      FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

      final todosSnapshot = await firebaseFirestore.collection("todos").get();

      setState(() {
        todos = todosSnapshot.docs
            .map((doc) => Todo.fromJson(doc.id, doc.data()))
            .toList();
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  void _deleteTodo(String uid) async {
    try {
      FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

      await firebaseFirestore.collection("todos").doc(uid).delete();

      _loadTodos();
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: todoController,
            ),
            const SizedBox(
              height: 50,
            ),
            TextButton(onPressed: _addTodo, child: const Text("Submit")),
            const SizedBox(
              height: 50,
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                  stream: _todosStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Something went wrong');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text("Loading");
                    }
                    return ListView(
                      children: snapshot.data!.docs
                          .map((DocumentSnapshot document) {
                            Map<String, dynamic> data =
                                document.data()! as Map<String, dynamic>;
                            Todo todo = Todo.fromJson(document.id, data);
                            return ListTile(
                              title: Text(todo.title),
                              subtitle: Text(todo.uid!),
                              trailing: GestureDetector(
                                onTap: () {
                                  _deleteTodo(todo.uid!);
                                },
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                              ),
                            );
                          })
                          .toList()
                          .cast(),
                      // children: snapshot.data!.docs.map((DocumentSnapshot document) {
                      //   Map<String, dynamic> data =
                      //   document.data()! as Map<String, dynamic>;
                      //   return ListTile(
                      //               title: Text(todos[index].title),
                      //               subtitle: Text(todos[index].uid!),
                      //               trailing: GestureDetector(
                      //                 onTap: () {
                      //                   _deleteTodo(todos[index].uid!);
                      //                 },
                      //                 child: const Icon(
                      //                   Icons.delete,
                      //                   color: Colors.redAccent,
                      //                 ),
                      //               ),
                      //             );
                    );
                  }),
            ),
            // Expanded(
            //   child: ListView.builder(
            //     itemBuilder: (context, index) {
            //       return ListTile(
            //         title: Text(todos[index].title),
            //         subtitle: Text(todos[index].uid!),
            //         trailing: GestureDetector(
            //           onTap: () {
            //             _deleteTodo(todos[index].uid!);
            //           },
            //           child: const Icon(
            //             Icons.delete,
            //             color: Colors.redAccent,
            //           ),
            //         ),
            //       );
            //     },
            //     itemCount: todos.length,
            //   ),
            // )
          ],
        ),
      ),
    );
  }
}
