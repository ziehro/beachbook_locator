

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:async';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';  // Add this import for kIsWeb
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_midi/flutter_midi.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';







void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beach Locator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BeachListScreen(),
    );
  }
}

class BeachListScreen extends StatefulWidget {
  @override
  _BeachListScreenState createState() => _BeachListScreenState();
}

class _BeachListScreenState extends State<BeachListScreen> {
  Position? _currentPosition;
  final StreamController<
      List<DocumentSnapshot>> _streamController = StreamController<
      List<DocumentSnapshot>>();


  @override
  void initState() {
    super.initState();
    loadMidi();
    _getLocation().then((_) {
      _streamController.addStream(getNearbyBeaches(_currentPosition));
    });
  }

  void loadMidi() async {
    ByteData byteData = await rootBundle.load('assets/sounds/Piano.SF2');
    await flutterMidi.prepare(sf2: byteData);
  }

  void _launchMapsUrl(double latitude, double longitude) async {
    String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude";

    if (kIsWeb) {
      launchWebURL(googleMapsUrl);
    } else {
      if (await canLaunch(googleMapsUrl)) {
        await launch(googleMapsUrl);
      } else {
        throw 'Could not launch Google Maps';
      }
    }
  }

  void launchWebURL(String url) {
    if (kIsWeb) {
      launch(url);
    }
  }


  Future<void> _getLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          return; // Location permissions are denied
        }
      }

      _currentPosition = await Geolocator.getCurrentPosition();
      setState(() {}); // Trigger a UI refresh now that we have location.
    } catch (e) {
      print("Error fetching location: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: _streamController.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error loading beaches.'));
          }

          return ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            itemCount: snapshot.data?.length ?? 0,
            itemBuilder: (context, index) {
              var beach = snapshot.data![index];
              var data = beach.data() as Map<String, dynamic>;

              return InkWell(
                onTap: () {
                  _showBeachDialog(data);
                },
                child: Container(
                  height: (MediaQuery
                      .of(context)
                      .size
                      .height - 50) / 3,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: NetworkImage(
                        data['imageUrls'] != null &&
                            data['imageUrls'].isNotEmpty
                            ? data['imageUrls'][0]
                            : 'placeholder_image_url',
                      ),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Title (beach name) centered
                      Center(
                        child: Text(
                          data['name'],
                          style: TextStyle(fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Row of buttons positioned 10dp above the bottom
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          padding: EdgeInsets.symmetric(
                              vertical: 5, horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              IconButton(
                                icon: Icon(
                                    Icons.info_outline, color: Colors.white),
                                onPressed: () {
                                  _showBeachDialog(data);
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                    Icons.directions, color: Colors.white),
                                onPressed: () {
                                  _launchMapsUrl(
                                    data['latitude'],
                                    data['longitude'],
                                  );
                                },
                              ),
                              ElevatedButton(
                                child: Text('Play Song'),
                                onPressed: () async {
                                  List<Note> songNotes = generateSong(data);
                                  for (var note in songNotes) {
                                    flutterMidi.playMidiNote(
                                        midi: note.midiValue);
                                    await Future.delayed(note
                                        .duration); // Wait based on the duration of the note
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }


  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  final flutterMidi = FlutterMidi();

  final List<int> midiNotes = [
    60, // C4
    62, // D4
    64, // E4
    65, // F4
    67, // G4
    69, // A4
    71, // B4
  ];

  List<Note> generateSong(Map<String, dynamic> data) {
    List<Note> song = [];
    data.forEach((key, value) {
      if (value is int) {
        int noteIndex = value % midiNotes.length;
        song.add(Note(midiNotes[noteIndex], Duration(milliseconds: 300)));
      } else if (value is double) {
        int intValue = value.toInt();
        int noteIndex = intValue % midiNotes.length;
        song.add(Note(midiNotes[noteIndex], Duration(milliseconds: 300)));
      } else if (value is String) {
        // Use the length of the string to influence rhythm
        int rhythmValue = value.length %
            4; // This will give values between 0 and 3
        switch (rhythmValue) {
          case 0:
          // Add a fast note sequence (e.g., four eighth notes)
            for (int i = 0; i < 4; i++) {
              song.add(Note(midiNotes[(i + rhythmValue) % midiNotes.length],
                  Duration(milliseconds: 150)));
            }
            break;
          case 1:
          // Add a medium note sequence (e.g., two quarter notes)
            for (int i = 0; i < 2; i++) {
              song.add(Note(midiNotes[(i + rhythmValue) % midiNotes.length],
                  Duration(milliseconds: 300)));
            }
            break;
          case 2:
          // Add a slow note (e.g., one half note)
            song.add(Note(midiNotes[rhythmValue], Duration(milliseconds: 600)));
            break;
          case 3:
          // Add a very slow note (e.g., one whole note)
            song.add(
                Note(midiNotes[rhythmValue], Duration(milliseconds: 1200)));
            break;
        }
      }
    });
    return song;
  }


  void _showBeachDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            width: MediaQuery
                .of(context)
                .size
                .width * 0.95, // 90% of screen width
            height: MediaQuery
                .of(context)
                .size
                .height * 0.95, // 80% of screen height
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    data['name'],
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: MediaQuery
                              .of(context)
                              .size
                              .height * 0.4, // 40% of screen height
                          child: CarouselSlider(
                            options: CarouselOptions(
                              aspectRatio: 16 / 9,
                              viewportFraction: 0.9,
                              // Make images fill up more of the carousel
                              enlargeCenterPage: true,
                              autoPlay: true,
                            ),
                            items: (data['imageUrls'] as List).map((item) {
                              return Container(
                                child: Image.network(item, fit: BoxFit.cover),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Description: ${data['description']}'),
                              SizedBox(height: 10),
                              Text('Firewood: ${data['Firewood']}'),
                              SizedBox(height: 10),
                              Text('Sand: ${data['Sand']}'),
                              // Add other beach information here as needed
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: Text('Close'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
Stream<List<DocumentSnapshot>> getNearbyBeaches(Position? currentPosition) {
  return FirebaseFirestore.instance.collection('locations').snapshots().map((snapshot) {
    var sortedDocs = snapshot.docs.toList()
      ..sort((a, b) => _compareDistance(a, b, currentPosition));
    return sortedDocs.take(3).toList();
  });
}

int _compareDistance(DocumentSnapshot a, DocumentSnapshot b, Position? currentPosition) {
  double distanceA = _calculateDistanceFromUser(a, currentPosition);
  double distanceB = _calculateDistanceFromUser(b, currentPosition);
  return distanceA.compareTo(distanceB);
}
double _calculateDistanceFromUser(DocumentSnapshot doc, Position? currentPosition) {
  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
  return _calculateDistance(
    currentPosition?.latitude ?? 0,
    currentPosition?.longitude ?? 0,
    data['latitude'],
    data['longitude'],
  );
}


double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  var p = 0.017453292519943295; // Pi/180
  var a = 0.5 - cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a));
}


class Note {
  final int midiValue;
  final Duration duration;
  Note(this.midiValue, this.duration);
}
