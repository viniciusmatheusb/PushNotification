import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_notifications_start/http/web.dart';
import 'package:flutter_notifications_start/models/device.dart';
import 'package:flutter_notifications_start/screens/events_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: true,
    badge: true,
    carPlay: true,
    criticalAlert: true,
    provisional: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('Permissão concedida pelo usuario: ${settings.authorizationStatus}');
    _startPushnotificationHandler(messaging);
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print(
        'Permissão concedida provisoriamente pelo usuario: ${settings.authorizationStatus}');
    _startPushnotificationHandler(messaging);
  } else {
    print('Permissão negada pelo usuario.');
  }

  runApp(App());
}

void _startPushnotificationHandler(FirebaseMessaging messaging) async {
  String? token = await messaging.getToken();
  print('TOKEN: $token');
  _setPushToken(token);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Recebi uma mensagem');
    print('Dados da mensagem: ${message.data}');

    if (message.notification != null) {
      print(
          'A mensagem contém uma notificação: ${message.notification!.title}, ${message.notification!.body}');
    }
  });
}

void _setPushToken(String? token) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? prefsToken = prefs.getString('pushToken');
  bool? prefSent = prefs.getBool('tokenSent');
  print('Prefs Token: $prefsToken');

  if (prefsToken != token || (prefsToken == token && prefSent == false)) {
    print('Enviando Token para o servidor!');

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String? brand;
    String? model;

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidDevice = await deviceInfo.androidInfo;
      print('Modelo: ${androidDevice.model}');
      model = androidDevice.model;
      brand = androidDevice.brand;
    } else {
      IosDeviceInfo iosDevice = await deviceInfo.iosInfo;
      print('Modelo: ${iosDevice.utsname.machine}');
      model = iosDevice.utsname.machine;
      brand = 'Apple';
    }

    Device device = Device(brand: brand, model: model, token: token);

    sendDevice(device);
  } else {
    print('aparelho cadastrado');
  }
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dev meetups',
      home: EventsScreen(),
    );
  }
}
