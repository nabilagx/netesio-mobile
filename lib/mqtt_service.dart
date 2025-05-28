import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  static final MQTTService _instance = MQTTService._internal();
  factory MQTTService() => _instance;
  MQTTService._internal();

  late MqttServerClient client;

  void initialize() async {
    client = MqttServerClient('broker.hivemq.com', '');
    client.port = 1883;
    client.keepAlivePeriod = 20;
    client.logging(on: false);
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onSubscribed = onSubscribed;
    client.onUnsubscribed = (t) => print('Unsubscribed: $t');
    client.onSubscribeFail = (t) => print('Subscribe failed: $t');

    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier('netes_client_${DateTime.now().millisecondsSinceEpoch}')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    try {
      await client.connect();
    } catch (e) {
      print('MQTT connect error: $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('MQTT connected');
      client.subscribe('netes/status', MqttQos.atLeastOnce);
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final payload = (c[0].payload as MqttPublishMessage).payload.message;
        final message = String.fromCharCodes(payload);
        print('MQTT message received on ${c[0].topic}: $message');
      });
    } else {
      print('MQTT connection failed: ${client.connectionStatus}');
      client.disconnect();
    }
  }

  void publish(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void onConnected() => print('MQTT connected!');
  void onDisconnected() => print('MQTT disconnected.');
  void onSubscribed(String topic) => print('Subscribed to $topic');
}
