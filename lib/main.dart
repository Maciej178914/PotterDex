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
                  builder: (context) => SelectedListScreen(nameOfPage: category["title"])
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
  final nameOfPage;
  
  const SelectedListScreen({super.key, required this.nameOfPage});
  
  @override
  State<SelectedListScreen> createState() => _SelectedListScreenState();
}

class _SelectedListScreenState extends State<SelectedListScreen> {
  bool isAddButtonVisable = false;
  late Future<List<Record>> recordsFuture;
  late String showPageName;

  @override
  void initState() {
    super.initState();
    showPageName = widget.nameOfPage;

    if(widget.nameOfPage != "Ulubione") {
      isAddButtonVisable = true;
    }

    recordsFuture = loadRecords(widget.nameOfPage);

    if(widget.nameOfPage == "Zaklecia") {
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
                        record: listOfRecords[index],
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => DetailedRecordScreen(record: listOfRecords[index], nameOfPage: widget.nameOfPage)
                            )
                          );

                          setState(() {
                            recordsFuture = loadRecords(widget.nameOfPage);
                          });
                        },
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
              MaterialPageRoute(builder: (context) => AddRecordScreen(nameOfPage: widget.nameOfPage)),
            );

            if(newRecord != null) {
              setState(() {
                addRecord(widget.nameOfPage, newRecord);
                recordsFuture = loadRecords(widget.nameOfPage);
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

  bool isNameDetailed() {
    if(nameOfPage == "Zaklecia") {
      return false;
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nowy Element"),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: Color(0xFFEFEFEF)),
              decoration: InputDecoration(
                labelText: "Nazwa",
                labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                filled: true,
                fillColor: Color(0xFF232634),
                prefixIcon: Icon(Icons.badge_outlined, color: Color(0xFFD4AF37)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Color(0xFFD4AF37), width: 2),
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
                fillColor: Color(0xFF232634),
                prefixIcon: Icon(Icons.badge_outlined, color: Color(0xFFD4AF37)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Color(0xFFD4AF37), width: 2),
                ),
              ),
            ),

            SizedBox(height: 32),

            ElevatedButton(onPressed: () {
              final newRecord = Record(
                id: generateRecordId(nameOfPage),
                id_json: "",
                name: nameController.text,
                description: descriptionController.text,
                isDetailed: isNameDetailed(),
                image: "",
                house: "",
                dateOfBirth: "",
                ancestry: "",
                patronus: "",
                actor: "",
                isFavorite: false,
                wand: {}
              );
              Navigator.pop(context, newRecord);
            },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD4AF37),
                foregroundColor: Color(0xFF12141C),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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

class DetailedRecordScreen extends StatefulWidget {
  Record record;
  final String nameOfPage;

  DetailedRecordScreen({super.key, required this.record, required this.nameOfPage});

  @override
  State<DetailedRecordScreen> createState() => _DetailedRecordScreenState();
}

class _DetailedRecordScreenState extends State<DetailedRecordScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.record.name),
        
        actions: [
          IconButton(
            icon: Icon(
              widget.record.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: widget.record.isFavorite ? Color(0xFFD4AF37) : Colors.white54,
              size: 32,
            ),
            onPressed: () {
              if(widget.record.isFavorite) {
                widget.record.isFavorite = false;
                deleteRecord("Ulubione", widget.record);
              } else {
                widget.record.isFavorite = true;
                addRecord("Ulubione", widget.record);
              }

              setState(() {
                updateRecord(widget.nameOfPage, widget.record);
              });
            },
          ),
          SizedBox(width: 10)
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildHeaderImage(),
            SizedBox(height: 24),

            Text(
              widget.record.name,
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontFamily: "serif",
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),

            if (widget.record.house.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: _getHouseColor(widget.record.house),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getHouseColor(widget.record.house)),
                ),
                child: Text(
                  widget.record.house.toUpperCase(),
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

            SizedBox(height: 32),

            _buildSectionCard(
              title: "Informacje podstawowe",
              icon: Icons.person_outline,
              content: [
                _buildInfoRow("Data urodzenia", widget.record.dateOfBirth),
                _buildInfoRow("Pochodzenie", widget.record.ancestry),
                _buildInfoRow("Aktor", widget.record.actor),
              ],
            ),

            SizedBox(height: 16),

            _buildSectionCard(
              title: "Zdolności magiczne",
              icon: Icons.auto_fix_high,
              content: [
                _buildInfoRow("Patronus", widget.record.patronus.isEmpty ? "Brak" : widget.record.patronus),
                Divider(color: Colors.white24, height: 24),
                Text(
                  "Różdżka",
                  style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                _buildInfoRow("Drewno", widget.record.wand["wood"]?.toString() ?? "Nieznane"),
                _buildInfoRow("Rdzeń", widget.record.wand["core"]?.toString() ?? "Nieznany"),
                _buildInfoRow("Długość", widget.record.wand["length"] != null ? "${widget.record.wand["length"]} cali" : "Nieznana"),
              ],
            ),

            SizedBox(height: 20),

            Wrap( children: [
              ElevatedButton(
                onPressed: () {
                  deleteRecord(widget.nameOfPage, widget.record);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: Size(150, 50),
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text("Usuń"),
              ),

              SizedBox(width: 40),

              ElevatedButton(
                onPressed: () async {
                  final Record? updatedRecord = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EditRecordDetails(recordToEdit: widget.record)
                      )
                  );

                  if(updatedRecord != null) {
                    setState(() {
                      updateRecord(widget.nameOfPage, updatedRecord);
                      widget.record = updatedRecord;
                    });
                  }
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFD4AF37),
                  foregroundColor: Color(0xFF12141C),
                  minimumSize: Size(150, 50),
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text("Edytuj"),
              ),
            ],),

            SizedBox(height: 60)
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderImage() {
    return Container(
      width: 180,
      height: 240,
      decoration: BoxDecoration(
        color: Color(0xFF232634),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFD4AF37), width: 2),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFD4AF37),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: widget.record.image.isNotEmpty ? Image.network(
          widget.record.image,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        ) : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 64),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> content}) {
    return Card(
      color: Color(0xFF232634),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Color(0xFFD4AF37)),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Color(0xFFEFEFEF),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...content,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.isEmpty) value = "Brak danych";

    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Color(0xFFEFEFEF), fontSize: 15),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(color: Color(0xFFEFEFEF), fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Color _getHouseColor(String house) {
    switch (house.toLowerCase()) {
      case 'gryffindor': return Colors.redAccent;
      case 'slytherin': return Colors.green;
      case 'ravenclaw': return Colors.blueAccent;
      case 'hufflepuff': return Colors.amber;
      default: return Color(0xFFD4AF37);
    }
  }
}

class EditRecordDetails extends StatelessWidget {
  final Record recordToEdit;

  EditRecordDetails({super.key, required this.recordToEdit});

  @override
  Widget build(BuildContext context) {
    TextEditingController nameController = TextEditingController(text: recordToEdit.name);
    TextEditingController imageController = TextEditingController(text: recordToEdit.image);
    TextEditingController houseController = TextEditingController(text: recordToEdit.house);
    TextEditingController dateOfBirthController = TextEditingController(text: recordToEdit.dateOfBirth);
    TextEditingController ancestryController = TextEditingController(text: recordToEdit.ancestry);
    TextEditingController actorController = TextEditingController(text: recordToEdit.actor);
    TextEditingController patronusController = TextEditingController(text: recordToEdit.patronus);
    TextEditingController woodController = TextEditingController(text: recordToEdit.wand["wood"]);
    TextEditingController coreController = TextEditingController(text: recordToEdit.wand["core"]);
    TextEditingController lengthController = TextEditingController(text: recordToEdit.wand["length"].toString());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edytuj Element"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Color(0xFF232634),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Color(0xFFD4AF37), width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: imageController.text.isNotEmpty ? Image.network(
                      imageController.text,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Icon(
                          Icons.image_not_supported,
                          color: Colors.white24
                      )
                  ) : Icon(Icons.image, color: Colors.white24),
                ),
              ),
            ),

            SizedBox(height: 30),

            _buildTextField(
              controller: nameController,
              label: "Nazwa",
              icon: Icons.badge_outlined,
            ),
            SizedBox(height: 20),

            _buildTextField(
              controller: imageController,
              label: "URL Zdjęcia",
              icon: Icons.link,
            ),
            SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Informacje podstawowe",
                  style: TextStyle(
                    color: Color(0xFFEFEFEF),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),

            SizedBox(height: 6),
            Divider(
              color: Colors.white12,
              thickness: 1,
            ),
            SizedBox(height: 10),

            _buildTextField(
              controller: houseController,
              label: "Dom",
              icon: Icons.home,
            ),
            SizedBox(height: 20),

            _buildTextField(
              controller: dateOfBirthController,
              label: "Data urodzenia",
              icon: Icons.cake,
            ),
            SizedBox(height: 20),

            _buildTextField(
              controller: ancestryController,
              label: "Pochodzenie",
              icon: Icons.family_restroom,
            ),
            SizedBox(height: 20),

            _buildTextField(
              controller: actorController,
              label: "Aktor",
              icon: Icons.recent_actors,
            ),
            SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Zdolności magiczne",
                  style: TextStyle(
                    color: Color(0xFFEFEFEF),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),

            SizedBox(height: 6),
            Divider(
              color: Colors.white12,
              thickness: 1,
            ),
            SizedBox(height: 10),

            _buildTextField(
              controller: patronusController,
              label: "Patronus",
              icon: Icons.shield,
            ),
            SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Różdżka",
                  style: TextStyle(
                    color: Color(0xFFEFEFEF),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),

            Divider(
              color: Colors.white12,
              thickness: 1,
            ),
            SizedBox(height: 10),

            _buildTextField(
              controller: woodController,
              label: "Drewno",
              icon: Icons.forest,
            ),
            SizedBox(height: 20),

            _buildTextField(
              controller: coreController,
              label: "Rdzeń",
              icon: Icons.align_horizontal_center,
            ),
            SizedBox(height: 20),

            _buildTextField(
              controller: lengthController,
              label: "Długość",
              icon: Icons.straighten,
            ),

            SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                final updatedRecord = Record(
                    id: recordToEdit.id,
                    id_json: recordToEdit.id_json,
                    name: nameController.text,
                    description: actorController.text,
                    isDetailed: recordToEdit.isDetailed,
                    isFavorite: recordToEdit.isFavorite,
                    image: imageController.text,
                    house: houseController.text,
                    dateOfBirth: dateOfBirthController.text,
                    ancestry: ancestryController.text,
                    patronus: patronusController.text,
                    actor: actorController.text,
                    wand: {
                      "wood": woodController.text,
                      "core": coreController.text,
                      "length": lengthController.text
                    }
                );

                Navigator.pop(context, updatedRecord);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD4AF37),
                foregroundColor: Color(0xFF12141C),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                "ZAPISZ ZMIANY",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            SizedBox(height: 60),
          ],
        ),
      )
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Color(0xFFEFEFEF)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFFD4AF37)),
        filled: true,
        fillColor: Color(0xFF232634),
        prefixIcon: Icon(icon, color: Color(0xFFD4AF37)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFFD4AF37), width: 2),
        ),
      ),
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
  final String id_json, name, description, image, house, dateOfBirth, ancestry, patronus, actor;
  final Map<String, dynamic> wand;
  bool isDetailed, isFavorite;
  final int id;

  Record({
    required this.id,
    required this.id_json,
    required this.name,
    required this.description,
    required this.isDetailed,
    required this.isFavorite,
    required this.image,
    required this.house,
    required this.dateOfBirth,
    required this.ancestry,
    required this.patronus,
    required this.actor,
    required this.wand
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "id_json": id_json,
      "name": name,
      "description": description,
      "image": image,
      "isDetailed": isDetailed,
      "house": house,
      "dateOfBirth": dateOfBirth,
      "ancestry": ancestry,
      "patronus": patronus,
      "actor": actor,
      "isFavorite": isFavorite,
      "wand": wand
    };
  }

  factory Record.fromMap(Map map) {
    return Record(
      id: map["id"],
      id_json: map["id_json"],
      name: map["name"],
      description: map["description"],
      isDetailed: map["isDetailed"],
      image: map["image"],
      house: map["house"],
      dateOfBirth: map["dateOfBirth"],
      ancestry: map["ancestry"],
      patronus: map["patronus"],
      actor: map["actor"],
      isFavorite: map["isFavorite"],
      wand: map["wand"]
    );
  }
}

class RecordCard extends StatelessWidget{
  final Record record;
  final VoidCallback onTap;

  const RecordCard({super.key, required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFF232634),
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),

        leading: _buildAvatar(),

        title: Text(
          record.name,
          style: TextStyle(
            color: Color(0xFFEFEFEF),
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),

        subtitle: Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            record.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFFEFEFEF),
              fontSize: 14,
            ),
          ),
        ),

        trailing: record.isDetailed ? Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFFD4AF37),
          size: 32,
        ) : null,

        onTap: record.isDetailed ? onTap : null,
      ),
    );
  }

  Widget _buildAvatar() {
    if(record.image.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          record.image,
          width: 60,
          height: 60,
          fit: BoxFit.cover,

          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        ),
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Color(0xFF12141C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFFD4AF37),
          width: 1.5,
        ),
      ),
      child: Icon(
        Icons.auto_awesome,
        color: Color(0xFFD4AF37),
        size: 28,
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
      bool isNameDetailed;

      return data.map((record) {
        if(nameOfPage == "Zaklecia") {
          isNameDetailed = false;
        } else {
          isNameDetailed = true;
        }

        return Record(
          image: record["image"] ?? "",
          id: generateRecordId(nameOfPage),
          id_json: record["id"],
          name: record["name"],
          description: record["description"] ?? record["actor"],
          isDetailed: isNameDetailed,
          house: record["house"] ?? "Brak",
          dateOfBirth: record["dateOfBirth"] ?? "Nieznana",
          ancestry: record["ancestry"] ?? "Nieznane",
          patronus: record["patronus"] ?? "Brak",
          actor: record["actor"] ?? "Nieznany",
          isFavorite: false,
          wand: record["wand"] ?? {}
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
    if(!LocalDatabase.isEmpty(nameOfPage) || nameOfPage == "Ulubione") {
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

Future<void> deleteRecord(String nameOfPage, Record record) async {
  await LocalDatabase.deleteRecord(nameOfPage, record.id);
  await loadRecords(nameOfPage);
}

Future<void> updateRecord(String nameOfPage, Record record) async {
await LocalDatabase.updateRecord(nameOfPage, record);
await loadRecords(nameOfPage);
}