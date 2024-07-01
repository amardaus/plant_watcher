import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(MyApp());
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

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late MqttServerClient client;
  String connectionStatus = "Disconnected";
  double _temperatureValue = 0;
  double _humidityValue = 0;

  @override
  void initState() {
    super.initState();
    client = MqttServerClient('192.168.187.101', 'client1');
    client.logging(on: true); // Enable logging for debugging
    connectClient();
  }

  Future<void> connectClient() async {
    client.keepAlivePeriod = 20;
    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;
    client.onSubscribed = onSubscribed;

    try {
      await client.connect('client1');
      setState(() {
        connectionStatus = "Connected to ${client.server}";
      });
      client.subscribe('/room1/temperature', MqttQos.atLeastOnce);
      client.subscribe('/room1/humidity', MqttQos.atLeastOnce);

      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
        final MqttPublishMessage message = c![0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
        final topic = c[0].topic;

        if (topic == '/room1/temperature') {
          _temperatureValue = double.tryParse(payload) ?? 0.0;
        }
        else if (topic == '/room1/humidity'){
          _humidityValue = double.tryParse(payload) ?? 0.0;
        }

        DateTime _now = DateTime.now();
        publishMessage('/time_received', 'Time received: $_now');
      });
    } 
    catch (e) {
      print('Exception: $e');
      client.disconnect();
      setState(() {
        connectionStatus = "Connection failed";
      });
    }
  }

  void disconnect() {
    client.disconnect();
  }

  void onConnected() {
    print('Connected');
  }

  void onDisconnected() {
    print('Disconnected');
    setState(() {
      connectionStatus = "Disconnected";
    });
  }

   void onSubscribed(String topic) {
    print('Subscribed topic: $topic');
  }

  void publishMessage(String topic, String message) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plant watcher'),

      ),
      body: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(connectionStatus),
            SizedBox(height: 20),
            if(connectionStatus == "Disconnected" || connectionStatus == "Connection failed")
            ElevatedButton(
              onPressed: () {
                connectClient();
              },
              child: Text('Retry Connection'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: connectionStatus.startsWith("Connected")
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TemperatureHumidityScreen(client: client),
                        ),
                      );
                    }
                  : null,
              child: Text('Room 1'),
            ),
          ],
        )
      ,)
    );
  }
}

class TemperatureHumidityScreen extends StatefulWidget {
  final MqttServerClient client;

  TemperatureHumidityScreen({required this.client});

  @override
  _TemperatureHumidityScreenState createState() => _TemperatureHumidityScreenState();
}

class _TemperatureHumidityScreenState extends State<TemperatureHumidityScreen> {
  double _temperatureValue = 0.0;
  double _humidityValue = 0.0;
  
  @override
  void initState() {
    super.initState();
    widget.client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final MqttPublishMessage message = c![0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
      final topic = c[0].topic;

      setState(() {
        if (topic == '/room1/temperature') {
          _temperatureValue = double.tryParse(payload) ?? 0.0;
        } else if (topic == '/room1/humidity') {
          _humidityValue = double.tryParse(payload) ?? 0.0;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Temperature and Humidity')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Temperature: $_temperatureValue °C'),
            SizedBox(height: 20),
            Text('Humidity: $_humidityValue %'),
          ],
        ),
      ),
    );
  }
}