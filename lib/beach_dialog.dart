import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class BeachDialogContent extends StatefulWidget {
  final Map<String, dynamic> data;

  BeachDialogContent({required this.data});

  @override
  _BeachDialogContentState createState() => _BeachDialogContentState();
}

class _BeachDialogContentState extends State<BeachDialogContent> {

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.data['name']), // Using widget.data here
          bottom: TabBar(
            isScrollable: true, // Allows for better title fitting
            tabs: [
              Tab(text: 'Yes or No'),
              Tab(text: 'FireWood'),
              Tab(text: 'Constitution'),
              Tab(text: 'Fauna'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Adding padding around the carousel
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 200, // specify the height for the carousel
                child: CarouselSlider(
                  options: CarouselOptions(
                    aspectRatio: 16 / 9,
                    viewportFraction: 0.9,
                    enlargeCenterPage: true,
                    autoPlay: true,
                  ),
                  items: (widget.data['imageUrls'] as List).map((item) {
                    return Container(
                      child: Image.network(item, fit: BoxFit.cover),
                    );
                  }).toList(),
                ),
              ),
            ),
            // Tabs content
            Expanded(
              child: TabBarView(
                children: [
                  _buildYesOrNoPage(),
                  _buildFireWoodPage(),
                  _buildConstitutionPage(),
                  _buildFaunaPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildYesOrNoPage() {
    List<Widget> widgets = [];

    final yesOrNoAttributes = {
      "Boats on Shore": [0, 1],
      "Caves": [0, 1],
      "Patio Nearby?": [0, 1],
      "Gold": [0, 1],
      "Stink": [0, 1],
      "Lookout": [0, 1],
      "Private": [0, 1],
      "Windy": [0, 2]
      // I noticed this goes to 2, if it's a mistake and should be 1, adjust accordingly.
    };

    yesOrNoAttributes.forEach((attribute, range) {
      if (widget.data[attribute] != null && widget.data[attribute] != range[0]) {
        widgets.add(SwitchListTile(
          title: Text(attribute),
          value: widget.data[attribute] == 1,
          onChanged: (newValue) {
            // Handle change if necessary
            // E.g. save the change to the database or update the local data map
            setState(() {
              widget.data[attribute] = newValue ? 1 : 0;
            });
          },
        ));
      }
    });

    return ListView(
      children: widgets,
    );
  }

  Widget _buildFireWoodPage() {
    List<Widget> widgets = [];

    final fireWoodAttributes = {
      "Trees": [1, 5],
      "Logs": [1, 5],
      "Firewood": [1, 5],
      "Kindling": [1, 5]
    };

    fireWoodAttributes.forEach((attribute, range) {
      if (widget.data[attribute] != null && widget.data[attribute] != range[0]) {
        widgets.add(
          Column(
            children: [
              Text(attribute),
              Slider(
                value: widget.data[attribute].toDouble(),
                min: range[0].toDouble(),
                max: range[1].toDouble(),
                divisions: range[1] - range[0],
                onChanged: (newValue) {
                  // Handle change if necessary
                  // E.g., save to database or update local data
                  setState(() {
                    widget.data[attribute] = newValue.toInt();
                  });
                },
              ),
              // To display the current value below the slider
            ],
          ),
        );
      }
    });

    return ListView(
      children: widgets,
    );
  }


  Widget _buildConstitutionPage() {
    List<Widget> widgets = [];

    final constitutionAttributes = {
      "Mud": [1, 5],
      "Sand": [1, 5],
      "Midden": [1, 5],
      "Pebbles": [1, 5],
      "Baseball Rocks": [1, 5],
      "Rocks": [1, 5],
      "Boulders": [1, 5],
      "Stone": [1, 5],
      "Coal": [1, 5],
      "Islands": [1, 5]
    };

    constitutionAttributes.forEach((attribute, range) {
      if (widget.data[attribute] != null && widget.data[attribute] != range[0]) {
        widgets.add(
          Column(
            children: [
              Text(attribute),
              Slider(
                value: widget.data[attribute].toDouble(),
                min: range[0].toDouble(),
                max: range[1].toDouble(),
                divisions: range[1] - range[0],
                onChanged: (newValue) {
                  // Handle change if necessary
                  setState(() {
                    widget.data[attribute] = newValue.toInt();
                  });
                },
              ),
              // Display the current value below the slider
            ],
          ),
        );
      }
    });

    return ListView(
      children: widgets,
    );
  }


  Widget _buildFaunaPage() {
    List<Widget> widgets = [];

    final faunaAttributes = {
      "Anemones": [1, 7],
      "Barnacles": [1, 7],
      "Bugs": [1, 7],
      "Clams": [1, 7],
      "Limpets": [1, 7],
      "Mussels": [1, 7],
      "Snails": [1, 7],
      "Turtles": [1, 7],
      "Oysters": [1, 7]
    };

    faunaAttributes.forEach((attribute, range) {
      if (widget.data[attribute] != null && widget.data[attribute] != range[0]) {
        widgets.add(
          Column(
            children: [
              Text(attribute),
              Slider(
                value: widget.data[attribute].toDouble(),
                min: range[0].toDouble(),
                max: range[1].toDouble(),
                divisions: range[1] - range[0],
                onChanged: (newValue) {
                  // Handle change if necessary
                  setState(() {
                    widget.data[attribute] = newValue.toInt();
                  });
                },
              ),
              // Display the current value below the slider
            ],
          ),
        );
      }
    });

    return ListView(
      children: widgets,
    );
  }
}
