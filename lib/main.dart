

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
  final StreamController<List<DocumentSnapshot>> _streamController = StreamController<List<DocumentSnapshot>>();

  final List<double> frequencies = [
    261.63, // C
    293.66, // D
    329.63, // E
    349.23, // F
    392.00, // G
    440.00, // A
    493.88, // B
  ];

  void _navigateToMusic() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MusicFromData(currentPosition: _currentPosition),
      ),
    );
  }


  List<double> generateSong(Map<String, dynamic> data) {
    List<double> song = [];
    data.forEach((key, value) {
      if (value is int) {
        int noteIndex = value % frequencies.length;
        song.add(frequencies[noteIndex]);
      }
    });
    return song;
  }


  @override
  void initState() {
    super.initState();
    _getLocation().then((_) {
      _streamController.addStream(getNearbyBeaches(_currentPosition));
    });
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
      appBar: AppBar(title: Text("Nearby Beaches")),
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
            itemCount: snapshot.data?.length ?? 0,
            itemBuilder: (context, index) {
              var beach = snapshot.data![index];
              var data = beach.data() as Map<String, dynamic>;

              return InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(data['name']),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 200,
                                child: CarouselSlider(
                                  options: CarouselOptions(
                                    aspectRatio: 16 / 9,
                                    viewportFraction: 0.8,
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
                              Text('Description: ${data['description']}'),
                              SizedBox(height: 10),
                              Text('Firewood: ${data['Firewood']}'),
                              SizedBox(height: 10),
                              Text('Sand: ${data['Sand']}'),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            child: Text('Close'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Column(

                    children: [


                      Container(
                        width: kIsWeb ? 200 : 100,
                        height: kIsWeb ? 200 : 100,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: NetworkImage(
                              data['imageUrls'] != null && data['imageUrls'].isNotEmpty
                                  ? data['imageUrls'][0]
                                  : 'placeholder_image_url',
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        data['name'],
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [



                          IconButton(
                            icon: Icon(Icons.info_outline),
                            onPressed: () {
                              _showBeachDialog(data);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.directions),
                            onPressed: () {
                              _launchMapsUrl(
                                data['latitude'],
                                data['longitude'],
                              );
                            },
                          ),
                          ElevatedButton(
                            child: Text('Play Song'),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => MusicFromData(currentPosition: _currentPosition),
                                ),
                              );
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
        },
      ),
    );
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }



  void _showBeachDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(data['name']),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 200,
                  child: CarouselSlider(
                    options: CarouselOptions(
                      aspectRatio: 16 / 9,
                      viewportFraction: 0.8,
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
                Text('Description: ${data['description']}'),
                SizedBox(height: 10),
                Text('Firewood: ${data['Firewood']}'),
                SizedBox(height: 10),
                Text('Sand: ${data['Sand']}'),
                // Add other beach information here as needed
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
class MusicFromData extends StatefulWidget {
  final Position? currentPosition;
  MusicFromData({required this.currentPosition});

  @override
  _MusicFromDataState createState() => _MusicFromDataState();
}

class _MusicFromDataState extends State<MusicFromData> {

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

  List<int> generateSong(Map<String, dynamic> data) {
    List<int> song = [];
    data.forEach((key, value) {
      if (value is int) {
        int noteIndex = value % midiNotes.length;
        song.add(midiNotes[noteIndex]);
      } else if (value is double) {
        int intValue = value.toInt();
        int noteIndex = intValue % midiNotes.length;
        song.add(midiNotes[noteIndex]);
      }
    });
    return song;
  }

  @override
  void initState() {
    super.initState();
    loadMidi();
  }

  void loadMidi() async {
    ByteData byteData = await rootBundle.load('assets/sounds/Piano.SF2');
    await flutterMidi.prepare(sf2: byteData);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: getNearbyBeaches(widget.currentPosition),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Error loading beach data.'));
          }

          return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var beach = snapshot.data![index];
                var data = beach.data() as Map<String, dynamic>;
                List<int> songMidiNotes = generateSong(data);

                return ListTile(
                  title: Text(data['name'] ?? 'Unknown Beach'),
                  trailing: ElevatedButton(
                    child: Text('Play Song'),
                    onPressed: () async {
                      for (int midiNote in songMidiNotes) {
                        flutterMidi.playMidiNote(midi: midiNote);

                        await Future.delayed(Duration(milliseconds: 300)); // Wait for 100ms between notes
                      }
                    },
                  ),
                );
              }
          );
        },
      ),
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
