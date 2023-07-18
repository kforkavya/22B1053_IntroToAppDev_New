import 'package:flutter/material.dart';

void main() {
  List<Category> categories = [];
  runApp(BudgetTrackerApp(categories: categories));
}

class BudgetTrackerApp extends StatelessWidget {
  final List<Category> categories;

  BudgetTrackerApp({required this.categories});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(categories: categories),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final List<Category> categories;

  HomeScreen({required this.categories});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double totalExpense = 0;

  @override
  void initState() {
    super.initState();
    calculateTotalExpense();
  }

  void calculateTotalExpense() {
    totalExpense = widget.categories.fold(0.0, (sum, category) => sum + category.price);
  }

  void addCategory(String name, double price) {
    setState(() {
      widget.categories.add(Category(name: name, price: price));
      calculateTotalExpense();
    });
  }

  void deleteCategory(Category category) {
    setState(() {
      widget.categories.remove(category);
      calculateTotalExpense();
    });
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
                    builder: (context) => TotalScreen(
                      categories: widget.categories,
                      onCategoryChanged: () {
                        setState(() {
                          calculateTotalExpense();
                        });
                      },
                    ),
                  ),
                );
                if (result == true) {
                  calculateTotalExpense();
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
              return AddCategoryDialog(
                onAddCategory: addCategory,
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class Category {
  String name;
  double price;

  Category({required this.name, required this.price});
}

class TotalScreen extends StatefulWidget {
  final List<Category> categories;
  final VoidCallback onCategoryChanged;

  TotalScreen({required this.categories, required this.onCategoryChanged});

  @override
  _TotalScreenState createState() => _TotalScreenState();
}

class _TotalScreenState extends State<TotalScreen> {
  void addCategory(String name, double price) {
    setState(() {
      widget.categories.add(Category(name: name, price: price));
      widget.onCategoryChanged();
    });
  }

  void deleteCategory(Category category) {
    setState(() {
      widget.categories.remove(category);
      widget.onCategoryChanged();
    });
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
                  'Total Expense',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text('Total: \$${widget.categories.fold(0.0, (sum, category) => sum + category.price).toStringAsFixed(2)}'),
                SizedBox(height: 16),
                Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
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
                            deleteCategory(category);
                          },
                        ),
                      ],
                    );
                  },
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
              return AddCategoryDialog(
                onAddCategory: addCategory,
              );
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
