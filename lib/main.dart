import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "PotterDex",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFF12141C),
        canvasColor: Color(0xFF12141C),
        
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF12141C),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(
            color: Color(0xFFD4AF37)
          ),
          titleTextStyle: TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontFamily: "serif",
          ),
        ),

        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder()
          }
        )
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final List<Map<String, dynamic>> categories = [
    {"title": "Postacie", "icon": Icons.people_alt_outlined},
    {"title": "Zaklęcia", "icon": Icons.auto_fix_high},
    {"title": "Studenci", "icon": Icons.school},
    {"title": "Personel", "icon": Icons.home_repair_service},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PotterDex"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return categoryCard(categories[index]);
              },
            ),
            SizedBox(
              height: 160,
              child: categoryCard({"title": "Ulubione", "icon": Icons.hotel_class}),
            )
          ],
        ),
      )
    );
  }

  Widget categoryCard(Map<String, dynamic> category) {
    return Card(
      color: Color(0xFF232634),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SelectedListScreen(name: category["title"])
              )
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category["icon"],
              size: 54,
              color: Color(0xFFD4AF37),
            ),
            SizedBox(height: 16),
            Text(
              category["title"],
              style: TextStyle(
                color: Color(0xFFEFEFEF),
                fontSize: 18,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Record {
  final String id, name, description, image;

  Record(this.image, {required this.id, required this.name, required this.description});
}

class RecordCard extends StatelessWidget{
  final Record record;

  RecordCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(record.name),
        subtitle: Text(record.description),
      ),
    );
  }
}

List<Record> listOfRecords = [
  Record("", id: "1", name: "Test1", description: "aaaa"),
  Record("", id: "2", name: "Test2", description: "bbbb"),
  Record("", id: "3", name: "Test3", description: "cccc"),
];

class SelectedListScreen extends StatefulWidget {
  final name;
  
  const SelectedListScreen({super.key, required this.name});
  
  @override
  State<SelectedListScreen> createState() => _SelectedListScreenState(name: name);
}

class _SelectedListScreenState extends State<SelectedListScreen> {
  final name;
  bool isAddButtonVisable = false;
  
  _SelectedListScreenState({required this.name});

  @override
  void initState() {
    super.initState();
    if(name != "Ulubione") {
      isAddButtonVisable = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PotterDex - $name"),
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: listOfRecords.length,
                itemBuilder: (context, index) {
                  return RecordCard(
                      record: listOfRecords[index]
                  );
                }
              )
            )
          ],
        ),
      ),
      floatingActionButton: isAddButtonVisable ? FloatingActionButton(
        onPressed: () async {
          final Record? newRecord = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddRecordScreen()),
          );

          if(newRecord != null) {
            setState(() {
              listOfRecords.add(newRecord);
            });
          }
        },
        child: Icon(Icons.add),
      ) : null
    );
  }
}

class AddRecordScreen extends StatelessWidget {
  AddRecordScreen({super.key});

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PotterDex - Nowy Element"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Nazwa",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12,),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: "Opis",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15,),
            ElevatedButton(onPressed: () {
              final newRecord = Record(
                "",
                id: "1",
                name: nameController.text,
                description: descriptionController.text
              );
              Navigator.pop(context, newRecord);
            }, child: Text("Dodaj Element")),
          ],
        ),
      ),
    );
  }
}