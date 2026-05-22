import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  await Hive.openBox("Postacie");
  await Hive.openBox("Zaklecia");
  await Hive.openBox("Studenci");
  await Hive.openBox("Personel");
  await Hive.openBox("Ulubione");

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
    {"title": "Zaklecia", "icon": Icons.auto_fix_high},
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

class SelectedListScreen extends StatefulWidget {
  final name;
  
  const SelectedListScreen({super.key, required this.name});
  
  @override
  State<SelectedListScreen> createState() => _SelectedListScreenState(nameOfPage: name);
}

class _SelectedListScreenState extends State<SelectedListScreen> {
  final String nameOfPage;
  bool isAddButtonVisable = false;
  late Future<List<Record>> recordsFuture;
  late String showPageName;
  
  _SelectedListScreenState({required this.nameOfPage});

  @override
  void initState() {
    super.initState();
    showPageName = nameOfPage;

    if(nameOfPage != "Ulubione") {
      isAddButtonVisable = true;
      recordsFuture = loadRecords(nameOfPage);
    } else {
      recordsFuture = Future.value([]);
    }

    if(nameOfPage == "Zaklecia") {
      showPageName = "Zaklęcia";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$showPageName"),
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<Record>>(
                future: recordsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text("Błąd: ${snapshot.error}"),
                    );
                  }

                  final listOfRecords = snapshot.data ?? [];

                  return ListView.builder(
                    itemCount: listOfRecords.length,
                    itemBuilder: (context, index) {
                      return RecordCard(
                          record: listOfRecords[index]
                      );
                    }
                  );
                }
              )
            )
          ],
        ),
      ),
      floatingActionButton: isAddButtonVisable ? SizedBox(
        height: 84,
        width: 84,
        child: FloatingActionButton(
          onPressed: () async {
            final Record? newRecord = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddRecordScreen(nameOfPage: nameOfPage)),
            );

            if(newRecord != null) {
              setState(() {
                addRecord(nameOfPage, newRecord);
                recordsFuture = loadRecords(nameOfPage);
              });
            }
          },
          backgroundColor: Color(0xFFD4AF37),
          foregroundColor: Color(0xFF12141C),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)
          ),
          child: Icon(
            Icons.add,
            size: 36,
          ),
        )
      ) : null
    );
  }
}

class AddRecordScreen extends StatelessWidget {
  final String nameOfPage;

  AddRecordScreen({super.key, required this.nameOfPage});

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nowy Element"),
      ),
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: Color(0xFFEFEFEF)),
              decoration: InputDecoration(
                labelText: "Nazwa",
                labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                filled: true,
                fillColor: const Color(0xFF232634),
                prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFFD4AF37)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2.0),
                ),
              ),
            ),

            SizedBox(height: 20),

            TextField(
              controller: descriptionController,
              style: TextStyle(color: Color(0xFFEFEFEF)),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Opis",
                labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                filled: true,
                fillColor: const Color(0xFF232634),
                prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFFD4AF37)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2.0),
                ),
              ),
            ),

            SizedBox(height: 32),

            ElevatedButton(onPressed: () {
              final newRecord = Record(
                "",
                id: generateRecordId(nameOfPage),
                id_json: "",
                name: nameController.text,
                description: descriptionController.text
              );
              Navigator.pop(context, newRecord);
            },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: const Color(0xFF12141C),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 4,
              ),
              child: Text(
                "DODAJ ELEMENT",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      )
    );
  }
}

Map<String, int> recordsLength = {
  "Postacie": 0,
  "Zaklecia": 0,
  "Studenci": 0,
  "Personel": 0,
  "Ulubione": 0,
};
int generateRecordId(String nameOfPage) {
  recordsLength[nameOfPage] = recordsLength[nameOfPage]! + 1;
  return recordsLength[nameOfPage]!;
}

class Record {
  final String id_json, name, description, image;
  final int id;

  Record(this.image, {required this.id, required this.id_json, required this.name, required this.description});

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "id_json": id_json,
      "name": name,
      "description": description,
      "image": image
    };
  }

  factory Record.fromMap(Map map) {
    return Record(
        map["image"],
        id: map["id"],
        id_json: map["id_json"],
        name: map["name"],
        description: map["description"]
    );
  }
}

class RecordCard extends StatelessWidget{
  final Record record;

  const RecordCard({super.key, required this.record});

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

class ApiService {
  static const Map<String, dynamic> baseUrl = {
    "Postacie": "https://hp-api.onrender.com/api/characters",
    "Zaklecia": "https://hp-api.onrender.com/api/spells",
    "Studenci": "https://hp-api.onrender.com/api/characters/students",
    "Personel": "https://hp-api.onrender.com/api/characters/staff"
  };

  static Future<List<Record>> fetchRecords(String nameOfPage) async {
    final response = await http.get(Uri.parse("${baseUrl[nameOfPage]}"));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data.map((record) {
        return Record(
          record["image"] ?? "",
          id: generateRecordId(nameOfPage),
          id_json: record["id"],
          name: record["name"],
          description: record["description"] ?? record["actor"]
        );
      }).toList();
    } else {
      throw Exception("Błąd pobierania danych");
    }
  }
}

class LocalDatabase {
  static List<Record> getRecords(String nameOfPage) {
    return Hive.box(nameOfPage).values.map((item) {
      return Record.fromMap(Map<String, dynamic>.from(item));
    }).toList();
  }

  static Future<void> saveRecords(String nameOfPage, List<Record> records) async {
    await Hive.box(nameOfPage).clear();

    for(final record in records) {
      await Hive.box(nameOfPage).put(record.id, record.toMap());
    }
  }

  static Future<void> addRecord(String nameOfPage, Record record) async {
    await Hive.box(nameOfPage).put(record.id, record.toMap());
  }

  static Future<void> updateRecord(String nameOfPage, Record record) async {
    await Hive.box(nameOfPage).put(record.id, record.toMap());
  }

  static Future<void> deleteRecord(String nameOfPage, int id) async {
    await Hive.box(nameOfPage).delete(id);
  }

  static Future<void> deleteAllRecords(String nameOfPage) async {
    await Hive.box(nameOfPage).clear();
  }

  static bool isEmpty(String nameOfPage) {
    return Hive.box(nameOfPage).isEmpty;
  }
}

class SyncService {
  static Future<void> loadInitialDataIfNeeded(String nameOfPage) async {
    if(!LocalDatabase.isEmpty(nameOfPage)) {
      return;
    }

    final records = await ApiService.fetchRecords(nameOfPage);
    await LocalDatabase.saveRecords(nameOfPage, records);
  }
}

Future<List<Record>> loadRecords(String nameOfPage) async {
  await SyncService.loadInitialDataIfNeeded(nameOfPage);
  return LocalDatabase.getRecords(nameOfPage);
}

Future<void> addRecord(String nameOfPage, Record record) async {
  await LocalDatabase.addRecord(nameOfPage, record);
  await loadRecords(nameOfPage);
}