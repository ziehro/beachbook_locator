import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';
import 'dart:math';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // Ensure the Flutter widgets binding is initialized.
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
  Location location = new Location();
  bool? _serviceEnabled;
  PermissionStatus? _permissionGranted;
  LocationData? _locationData;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled!) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled!) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();
  }

  Stream<List<DocumentSnapshot>> getNearbyBeaches() {
    return FirebaseFirestore.instance
        .collection('locations')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs..sort((a, b) {
        double distanceA = calculateDistance(
          _locationData?.latitude ?? 0.0,
          _locationData?.longitude ?? 0.0,
          (a.data() as Map<String, dynamic>)['latitude'].toDouble(),
          (a.data() as Map<String, dynamic>)['longitude'].toDouble(),
        );
        double distanceB = calculateDistance(
          _locationData?.latitude ?? 0.0,
          _locationData?.longitude ?? 0.0,
          (b.data() as Map<String, dynamic>)['latitude'].toDouble(),
          (b.data() as Map<String, dynamic>)['longitude'].toDouble(),
        );
        return distanceA.compareTo(distanceB);

      });
    });
  }



  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nearby Beaches"),
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: getNearbyBeaches(),
        builder: (BuildContext context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          print(snapshot.data);

          return ListView(
            children: (snapshot.data ?? []).map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;
              return ListTile(
                contentPadding: EdgeInsets.all(8.0),
                leading: Image.network(
                  data['imageUrls'] != null && data['imageUrls'].isNotEmpty
                      ? data['imageUrls'][0]
                      : 'placeholder_image_url',  // replace with your placeholder image URL
                  width: 100,  // Adjust width as per your requirement
                  height: 100, // Adjust height as per your requirement
                  fit: BoxFit.cover,
                ),
                title: Text(data['name']),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(data['name']),
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.network(data['imageUrls'][0]),
                            Text('Description: ${data['description']}'),
                          ],
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
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
