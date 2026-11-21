import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';

final appwriteClientProvider = Provider<Client>(
  (ref) => Client()
      .setEndpoint(AppConfig.appwriteEndpoint)
      .setProject(AppConfig.appwriteProjectId),
);

final accountProvider = Provider<Account>((ref) => Account(ref.watch(appwriteClientProvider)));

final tablesDbProvider = Provider<TablesDB>((ref) => TablesDB(ref.watch(appwriteClientProvider)));

final functionsProvider = Provider<Functions>((ref) => Functions(ref.watch(appwriteClientProvider)));

/// Row permissions granting a single user full access to their own row.
List<String> ownerPermissions(String userId) => [
      Permission.read(Role.user(userId)),
      Permission.update(Role.user(userId)),
      Permission.delete(Role.user(userId)),
    ];
