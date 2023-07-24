import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(BudgetTrackerApp());
}

class BudgetTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  Future<void> _login() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      if (userCredential.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(userId: userCredential.user!.uid),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('No user found for that email.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else if (e.code == 'wrong-password') {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Wrong password provided for that user.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _login,
                child: Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String userId;

  HomeScreen({required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Category> categories = [];
  double totalExpense = 0;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  void fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('categories').get();
    setState(() {
      categories.clear();
      totalExpense = 0;
      for (var doc in snapshot.docs) {
        final category = Category.fromDocumentSnapshot(doc);
        categories.add(category);
        totalExpense += category.price;
      }
    });
  }

  void addCategory(String name, double price) async {
    final newCategoryRef = await FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('categories').add({
      'name': name,
      'price': price,
    });
    final newCategory = Category(id: newCategoryRef.id, name: name, price: price);
    setState(() {
      categories.add(newCategory);
      totalExpense += price;
    });
  }

  void deleteCategory(String categoryId) async {
    final categoryRef = FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('categories').doc(categoryId);
    final categorySnapshot = await categoryRef.get();
    if (categorySnapshot.exists) {
      final category = Category.fromDocumentSnapshot(categorySnapshot);
      await categoryRef.delete();
      setState(() {
        categories.removeWhere((element) => element.id == categoryId);
        totalExpense -= category.price;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budget Tracker'),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome Back !',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('Name: Kavya Gupta'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TotalScreen(categories: categories, onCategoryChanged: fetchCategories),
                  ),
                );
                if (result == true) {
                  fetchCategories();
                }
              },
              child: Text('Total: \$${totalExpense.toStringAsFixed(2)}'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AddCategoryDialog(onAddCategory: addCategory);
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class Category {
  String id;
  String name;
  double price;

  Category({required this.id, required this.name, required this.price});

  Category.fromDocumentSnapshot(DocumentSnapshot doc)
      : id = doc.id,
        name = doc['name'],
        price = doc['price'];
}

class TotalScreen extends StatefulWidget {
  final List<Category> categories;
  final VoidCallback onCategoryChanged;

  TotalScreen({required this.categories, required this.onCategoryChanged});

  @override
  _TotalScreenState createState() => _TotalScreenState();
}

class _TotalScreenState extends State<TotalScreen> {
  void addCategory(String name, double price) async {
    final newCategoryRef = await FirebaseFirestore.instance.collection('users').doc(widget.categories.first.id).collection('categories').add({
      'name': name,
      'price': price,
    });
    final newCategory = Category(id: newCategoryRef.id, name: name, price: price);
    setState(() {
      widget.categories.add(newCategory);
      widget.onCategoryChanged();
    });
  }

  void deleteCategory(String categoryId) async {
    final categoryRef = FirebaseFirestore.instance.collection('users').doc(widget.categories.first.id).collection('categories').doc(categoryId);
    final categorySnapshot = await categoryRef.get();
    if (categorySnapshot.exists) {
      final category = Category.fromDocumentSnapshot(categorySnapshot);
      await categoryRef.delete();
      setState(() {
        widget.categories.removeWhere((element) => element.id == categoryId);
        widget.onCategoryChanged();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Total'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest or Last-Added Expense',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '\$${(widget.categories != null ? widget.categories.fold(0.0, (sum, category) => category.price) : 0.0).toStringAsFixed(2)}',
                ),
                SizedBox(height: 16),
                Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.categories.length,
                    itemBuilder: (context, index) {
                      final category = widget.categories[index];
                      return Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: Text(category.name),
                              subtitle: Text('Price: \$${category.price.toStringAsFixed(2)}'),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              deleteCategory(category.id);
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AddCategoryDialog(onAddCategory: addCategory);
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddCategoryDialog extends StatefulWidget {
  final Function(String, double) onAddCategory;

  AddCategoryDialog({required this.onAddCategory});

  @override
  _AddCategoryDialogState createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  TextEditingController nameController = TextEditingController();
  TextEditingController priceController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Category'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: priceController,
            decoration: InputDecoration(labelText: 'Price'),
            keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final String name = nameController.text;
            final double price = double.tryParse(priceController.text) ?? 0;
            widget.onAddCategory(name, price);
            Navigator.pop(context);
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}
