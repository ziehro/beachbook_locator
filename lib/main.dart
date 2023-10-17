

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:async';
import 'AdMobService.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';  // Add this import for kIsWeb
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_midi/flutter_midi.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'beach_dialog.dart';




void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeachBook',
      debugShowCheckedModeBanner: false, // Add this line

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

  late final BannerAd _bannerAd;

  @override
  void initState() {
    super.initState();
    loadMidi();

    _getLocation().then((_) {
      getNearbyBeachesStream(_currentPosition).listen((beaches) {
        _streamController.add(beaches);
      });
    });

    _bannerAd = createBannerAd()
      ..load();
  }

  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: AdMobService().getBannerAdUnitId(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          print("BannerAd event: Loaded");
        },
        onAdFailedToLoad: (ad, error) {
          print("BannerAd failed to load: $error");
          ad.dispose();
        },
        // ... Add other event handlers if needed
      ),
      request: AdRequest(),
    );
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
      bottomNavigationBar: Container(
        height: 50.0, // Typically, banner ads are 50dp in height
        child: AdWidget(ad: _bannerAd),
      ),
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
                  _showBeachDetails(context, data);
                },
                child: Container(
                  height: (MediaQuery
                      .of(context)
                      .size
                      .height - 100) / 3,
                  // Adjusted height to account for the banner ad
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
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
                                  _showBeachDetails(context, data);
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
    _bannerAd?.dispose();
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


}

  Stream<List<DocumentSnapshot<Object?>>> getNearbyBeachesStream(Position? currentPosition, {int precision = 5}) {
  return Stream.fromFuture(getNearbyBeaches(currentPosition, precision: precision));
}



Future<List<DocumentSnapshot>> getNearbyBeaches(Position? currentPosition, {int precision = 5}) async {
  if (currentPosition == null) return [];
  GeoHasher geoHasher = GeoHasher();
  var geohash = geoHasher.encode(currentPosition.longitude, currentPosition.latitude, precision: precision);
  var query = FirebaseFirestore.instance
      .collection('locations')
      .where('geohash', isGreaterThanOrEqualTo: geohash.substring(0, precision))
      .where('geohash', isLessThan: geohash.substring(0, precision) + "z")
      .limit(3); // Limit to 3 results

  var snapshot = await query.get();
  var beaches = snapshot.docs.toList();

  // If fewer than 3 beaches are found, reduce precision and try again
  if (beaches.length < 3 && precision > 1) {
    return getNearbyBeaches(currentPosition, precision: precision - 1);
  } else {
    return beaches;
  }
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

void _showBeachDetails(BuildContext context, Map<String, dynamic> data) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (BuildContext context) {
      return BeachDialogContent(data: data);
    },
  ));
}

