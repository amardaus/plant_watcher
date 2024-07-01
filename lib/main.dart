import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:plant_watcher/widgets/gauge.dart';

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
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
        final MqttPublishMessage message = c![0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
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
                          builder: (context) => TemperatureScreen(client: client),
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

class TemperatureScreen extends StatelessWidget {
  final MqttServerClient client;
  double gaugeValue = 0.0;
  
  TemperatureScreen({required this.client});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Temperature')),
      body: StreamBuilder<List<MqttReceivedMessage<MqttMessage>>>(
        stream: client.updates, // Receive MQTT updates
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final updates = snapshot.data!;
          final MqttPublishMessage recMess = updates.last.payload as MqttPublishMessage;
          final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
          return Center(child: Text('Last value: $pt'));
        },
      ),
    );
  }
}
