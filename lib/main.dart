import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:provider/provider.dart';
import 'mqtt_service.dart';
import 'dart:convert';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MQTTService()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant watcher',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mqttService = Provider.of<MQTTService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Plant watcher'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(mqttService.connectionStatus),
            SizedBox(height: 20),
            if (mqttService.connectionStatus == "Disconnected" ||
                mqttService.connectionStatus == "Connection failed")
              ElevatedButton(
                onPressed: () {
                  mqttService.connectClient();
                },
                child: Text('Retry Connection'),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: mqttService.connectionStatus.startsWith("Connected")
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoomScreen(room: 'room'),
                        ),
                      );
                    }
                  : null,
                child: Text('Room'),
            ),
            ElevatedButton(
              onPressed: mqttService.connectionStatus.startsWith("Connected")
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoomScreen(room: 'garden'),
                        ),
                      );
                    }
                  : null,
                child: Text('Garden'),
            ),
          ],
        ),
      ),
    );
  }
}

class RoomScreen extends StatelessWidget {
  final String room;

  RoomScreen({required this.room});

  @override
  Widget build(BuildContext context) {
    final mqttService = Provider.of<MQTTService>(context);

    return Scaffold(
      appBar: AppBar(title: Text(room[0].toUpperCase() + room.substring(1))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ..._buildPlantWidgets(mqttService.temperature[room] ?? {}, mqttService.humidity[room] ?? {}, room, mqttService.plants),
           if (room == 'garden') ElevatedButton(onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => DetectionScreen()));
              },child: Text('Snail detections'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPlantWidgets(Map<String, double> plantTemperature, Map<String, double> plantHumidity, String room, List<String> plants) {
    List<Widget> widgets = [];
   
    for (String plant in plants){
      List<Widget> plantWidgets = [];
      if (plantTemperature.containsKey(plant)) {
        double temperature = plantTemperature[plant] ?? 0.0;
        plantWidgets.add(Text('Temperature: $temperature °C'));
      }
      if (plantHumidity.containsKey(plant)) {
        double humidity = plantHumidity[plant] ?? 0.0;
        plantWidgets.add(Text('Humidity: $humidity %'));
      }

      if (plantWidgets.isNotEmpty) {
      widgets.add(Column(
        children: [
          Text('$plant', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
          ...plantWidgets,
        ],
      ));
      widgets.add(SizedBox(height: 20));
      }
    }
    return widgets;
  }
}

class DetectionScreen extends StatelessWidget{
  
  @override
  Widget build(BuildContext context) {
    final mqttService = Provider.of<MQTTService>(context);
    
      return Scaffold(
        appBar: AppBar(
        title: Text('Detections'),
      ),
      body: ListView.builder(
        itemCount: mqttService.detections.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(mqttService.detections[index]['label']),
            onTap: () {
              print('index: ' + index.toString());
              Navigator.push(context, MaterialPageRoute(builder: (context) => DetectionDetailsScreen(index: index)));
            },
          );
        },
      )
    );
  }
}

class DetectionDetailsScreen extends StatelessWidget {
  final int index;

  DetectionDetailsScreen({required this.index});

  @override
  Widget build(BuildContext context) {
    final mqttService = Provider.of<MQTTService>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Recent detection'),
      ),
      body: Center(
        child: Builder(builder: (context) {
          if (mqttService.detections.isEmpty) {
            return Text('No detections received');
          } else {
            return Column(children: [
              Image.memory(base64Decode(mqttService.detections[index]['im_bytes'])),
              Text(mqttService.detections[index]['label'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              Text("Time of detection: " + mqttService.detections[index]['time'])
              ],);
          }
        },)
      ),
    );
  }
}