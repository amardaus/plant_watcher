import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'room_model.dart';

class MQTTService with ChangeNotifier {
  late MqttServerClient client;
  String connectionStatus = "Disconnected";
  List<Room> rooms = [];

  Map<String, double> _temperature = {};
  Map<String, double> _humidity = {};

  Map<String, double> get temperature => _temperature;
  Map<String, double> get humidity => _humidity;

  MQTTService() {
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
      await client.connect();
      connectionStatus = "Connected to ${client.server}";
      notifyListeners();

      List<String> rooms = ['room1', 'garden'];

      for(String room in rooms){
        client.subscribe('/$room/temperature', MqttQos.atLeastOnce);
        client.subscribe('/$room/humidity', MqttQos.atLeastOnce);
      }

      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
        final MqttPublishMessage message = c![0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
        final topic = c[0].topic;
        final parts = topic.split('/');
        final room = parts[1];
        final type = parts[2];

        if (type == 'temperature') {
          _temperature[room] = double.tryParse(payload) ?? 0.0;
        } else if (type == 'humidity') {
          _humidity[room] = double.tryParse(payload) ?? 0.0;
        }

        notifyListeners();
      });
    } 
    catch (e) {
      print('Exception: $e');
      client.disconnect();
      connectionStatus = "Connection failed";
      notifyListeners();
    }
  }

  void disconnect() {
    client.disconnect();
    connectionStatus = "Disconnected";
    notifyListeners();
  }

  void onConnected() {
    print('Connected');
  }

  void onDisconnected() {
    print('Disconnected');
    connectionStatus = "Disconnected";
    notifyListeners();
  }

  void onSubscribed(String topic) {
    print('Subscribed topic: $topic');
  }

  void publishMessage(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }
}
