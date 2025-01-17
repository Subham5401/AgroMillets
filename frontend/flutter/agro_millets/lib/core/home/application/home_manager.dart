import 'dart:async';
import 'dart:convert';

import 'package:agro_millets/core/home/application/home_provider.dart';
import 'package:agro_millets/data/cache/app_cache.dart';
import 'package:agro_millets/models/millet_item.dart';
import "package:agro_millets/secrets.dart";
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class HomeManager {
  final BuildContext context;
  late Timer? timer;
  final WidgetRef ref;

  HomeManager(this.context, this.ref) {
    attach();
  }

  dispose() {
    debugPrint("[home_manager] Detaching Listeners...");
    if (timer != null) {
      timer!.cancel();
    }
  }

  // Using Polling instead of WebSockets
  attach() async {
    debugPrint("[home_manager] Attaching Listeners...");
    var data = await getAllItems();
    ref.read(homeProvider).updateItems(data);

    timer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) async {
        if (context.mounted) {
          var data = await getAllItems();
          ref.read(homeProvider).updateItems(data);
        }
      },
    );
  }

  Future<List<MilletItem>> getAllItems() async {
    if (appCache.isFarmer()) {
      return await getAllFarmerItems(appState.value.user!.id);
    }
    return getAll();
  }

  Future<List<MilletItem>> getAll() async {
    var response = await http.get(
      Uri.parse("$API_URL/list/getAll"),
    );

    Map data = json.decode(response.body);
    if (data["statusCode"] == 200) {
      List dataMap = data["data"];
      List<MilletItem> list = [];

      for (var e in dataMap) {
        list.add(MilletItem.fromMap(e));
      }
      return list;
    }
    return [];
  }
}

Future<List<MilletItem>> getAllFarmerItems(String id) async {
  var response = await http.get(
    Uri.parse("$API_URL/list/getAll/$id"),
  );

  debugPrint(response.request!.url.toString());
  Map data = json.decode(response.body);

  if (data["statusCode"] == 200) {
    List dataMap = data["data"];
    List<MilletItem> list = [];

    for (var e in dataMap) {
      list.add(MilletItem.fromMap(e));
    }
    debugPrint("Farmer Items $list");

    return list;
  }
  return [];
}

Future<void> addItem({
  required String name,
  required String listedBy,
  required String description,
  required List<String> images,
  required double price,
}) async {
  var response = await http.post(
    Uri.parse("$API_URL/list/addItem"),
    headers: {"content-type": "application/json"},
    body: json.encode(
      {
        "listedBy": listedBy,
        "name": name,
        "description": description,
        "images": images,
        "price": price,
        "comments": [],
      },
    ),
  );
}

Future<MilletItem?> getItemById(String id) async {
  var response = await http.get(Uri.parse("$API_URL/list/getItem/$id"));
  Map data = json.decode(response.body);

  if (data["statusCode"] == 200) {
    MilletItem item = MilletItem.fromMap(data["data"]);
    return item;
  }
  return null;
}
