import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:budget_tracker/login.dart';
import 'package:budget_tracker/signup.dart';
import 'package:fl_chart/fl_chart.dart';

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
      // Define the routes for navigation
      routes: {
        '/': (context) => LoginPage(),
        '/home': (context) => HomeScreen(userId: ModalRoute.of(context)!.settings.arguments as String),
        '/signup': (context) => SignUpScreen(),
      },
      // Handle unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (context) => NotFoundPage());
      },
    );
  }
}

class NotFoundPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page Not Found'),
      ),
      body: Center(
        child: Text('Page Not Found'),
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
  int totalExpense = 0;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Call fetchCategories whenever the widget becomes visible or when the dependencies change
    fetchCategories();
  }

  void fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('categories')
        .get();
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

  void addCategory(String name, int price) async {
    final newCategoryRef = await FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('categories').add({
      'name': name,
      'price': price,
    });
    final newCategory = Category(id: newCategoryRef.id, name: name, price: price);
    setState(() {
      categories.add(newCategory);
      totalExpense += price;
    });
    Navigator.pop(context);
  }

  void deleteCategory(String categoryId) async {
    final categoryRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('categories')
        .doc(categoryId);
    final categorySnapshot = await categoryRef.get();
    if (categorySnapshot.exists) {
      final category = Category.fromDocumentSnapshot(categorySnapshot);

      // Optimistic UI update: Remove the item from the list immediately.
      setState(() {
        categories.removeWhere((element) => element.id == categoryId);
        totalExpense -= category.price;
      });

      // Now, try to delete the category from the database.
      try {
        await categoryRef.delete();
      } catch (e) {
        // If there was an error, revert the UI back to the previous state.
        setState(() {
          categories.add(category);
          totalExpense += category.price;
        });
      }
      Navigator.pop(context);
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
                    builder: (context) => TotalScreen(categories: categories, onCategoryChanged: fetchCategories, deleteCategory: deleteCategory, addCategory: addCategory),
                  ),
                );
                if (result == true) {
                  fetchCategories();
                }
              },
              child: Text('Total: \$${totalExpense.toStringAsFixed(2)}'),
            ),
            SizedBox(height: 16),
            _buildChart(categories),
          ],
        ),
      ),
    );
  }
}

class ChartData {
  final int x; // X-axis value, e.g., month index
  final int y; // Y-axis value, e.g., total expense for that month
  List<Category> categories = [];

  ChartData(this.x, this.y, this.categories);
}
List<ChartData> _generateChartData(List<Category> categories) {
  List<ChartData> data = [];
  for (int i = 0; i < categories.length; i++) {
    Category category = categories[i];
    data.add(ChartData(i, category.price, categories));
  }
  return data;
}
Widget _buildChart(List<Category> categories) {
  final List<ChartData> data = _generateChartData(categories);

  if (data.isEmpty) {
    return Text('No data available for the chart.');
  }

  return Container(
    width: 300,
    height: 200,
    child: LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            getTextStyles: (context, value) => const TextStyle(
              color: Color(0xff68737d),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            getTitles: (value) {
              // Replace this with your own logic to show proper labels on the X-axis.
              // For example, if you have months, you can use value.toInt() as the index to get the month name.
              return '${value.toInt()}';
            },
            margin: 10,
          ),
          leftTitles: SideTitles(
            showTitles: true,
            getTextStyles: (context, value) => const TextStyle(
              color: Color(0xff67727d),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            margin: 10,
            reservedSize: 30,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1),
        ),
        minX: 0,
        maxX: data.length - 1,
        minY: 0,
        maxY: 100000, // Replace this with your own method to get the maximum value from your data
        lineBarsData: [
          LineChartBarData(
            spots: data.map((chartData) => FlSpot(chartData.x.toDouble(), chartData.y.toDouble())).toList(),
            isCurved: true,
            colors: [Colors.blue],
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    ),
  );
}


class Category {
  String id;
  String name;
  int price;

  Category({required this.id, required this.name, required this.price});

  Category.fromDocumentSnapshot(DocumentSnapshot doc)
      : id = doc.id,
        name = doc['name'],
        price = doc['price'];
}

class TotalScreen extends StatelessWidget {
  final List<Category> categories;
  final VoidCallback onCategoryChanged;
  final Function(String) deleteCategory;
  final Function(String, int) addCategory;

  TotalScreen({required this.categories, required this.onCategoryChanged, required this.deleteCategory, required this.addCategory});

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
                  '\$${(categories.isNotEmpty ? categories.fold(0.0, (sum, category) => category.price) : 0.0).toStringAsFixed(2)}',
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
              ],
            ),
          ),
          Expanded( // This Expanded widget will make the ListView take all the available space
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  title: Text(category.name),
                  subtitle: Text('Price: \$${category.price.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      deleteCategory(category.id);
                    },
                  ),
                );
              },
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
  final Function(String, int) onAddCategory;

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
            final int price = int.tryParse(priceController.text) ?? 0;
            widget.onAddCategory(name, price);
            Navigator.pop(context);
            setState(() {});
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}
