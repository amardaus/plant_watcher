import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'mqtt_service.dart';

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
            ..._buildPlantWidgets(mqttService.temperature[room] ?? {}, mqttService.humidity[room] ?? {}, room, mqttService.plants)
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
