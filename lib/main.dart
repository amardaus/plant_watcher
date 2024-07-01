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
                          builder: (context) => RoomScreen(room: 'room1'),
                        ),
                      );
                    }
                  : null,
              child: Text('Room 1'),
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
    final room_fullname = room[0].toUpperCase() + room.substring(1);

    return Scaffold(
      appBar: AppBar(title: Text(room_fullname)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Temperature: ${mqttService.temperature[room]} °C'),
            SizedBox(height: 20),
            Text('Humidity: ${mqttService.humidity[room]} %'),
          ],
        ),
      ),
    );
  }
}
