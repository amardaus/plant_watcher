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
  bool isConnected = false;
  String connectionStatus = "Disconnected";

  @override
  void initState() {
    super.initState();
    client = MqttServerClient('192.168.187.101', '')
      ..logging(on: true)
      ..setProtocolV311()
      ..keepAlivePeriod = 20
      ..onDisconnected = onDisconnected
      ..secure = false; // Disable SSL/TLS
    connectClient();
  }

  Future<void> connectClient() async {
    final connMess = MqttConnectMessage()
        .withClientIdentifier('MQTTClient')
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMess;

    try {
      await client.connect();
      setState(() {
        isConnected = true;
        connectionStatus = "Connected to ${client.server}";
      });
      client.subscribe('/temperature', MqttQos.atMostOnce);
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
      setState(() {
        isConnected = false;
        connectionStatus = "Connection failed";
      });
    }
  }

  void onDisconnected() {
    print('Disconnected');
    setState(() {
      isConnected = false;
      connectionStatus = "Disconnected";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MQTT Client Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(connectionStatus),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                connectClient();
              },
              child: Text('Retry Connection'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isConnected
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WeatherScreen(client: client),
                        ),
                      );
                    }
                  : null,
              child: Text('Go to Weather Screen'),
            ),
          ],
        ),
      ),
    );
  }
}

class WeatherScreen extends StatelessWidget {
  final MqttServerClient client;

  WeatherScreen({required this.client});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Weather Updates')),
      body: StreamBuilder<List<MqttReceivedMessage<MqttMessage>>>(
        stream: client.updates,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final updates = snapshot.data!;
          final MqttPublishMessage recMess = updates.last.payload as MqttPublishMessage;
          final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

          return Center(
            child: Text('Latest Weather: $pt'),
          );
        },
      ),
    );
  }
}
