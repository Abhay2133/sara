import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sara/models/model_config.dart';

class ModelConfigService {
  static const String _configFileName = 'model_config.json';
  static const String _settingsFileName = 'sara_settings.json';

  String? _customConfigFolder;

  void setConfigFolder(String folderPath) {
    _customConfigFolder = folderPath;
  }

  Future<Directory> _appSupportDirectory() async {
    return await getApplicationSupportDirectory();
  }

  Future<Directory> getConfigFolder() async {
    if (_customConfigFolder != null && _customConfigFolder!.isNotEmpty) {
      return Directory(_customConfigFolder!);
    }

    final appSupport = await _appSupportDirectory();
    final defaultFolder = Directory('${appSupport.path}${Platform.pathSeparator}sara_config');
    if (!await defaultFolder.exists()) {
      await defaultFolder.create(recursive: true);
    }
    return defaultFolder;
  }

  Future<File> _configFile() async {
    final folder = await getConfigFolder();
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return File('${folder.path}${Platform.pathSeparator}$_configFileName');
  }

  Future<File> _settingsFile() async {
    final appSupport = await _appSupportDirectory();
    return File('${appSupport.path}${Platform.pathSeparator}$_settingsFileName');
  }

  Future<void> loadSettings() async {
    final file = await _settingsFile();
    if (!await file.exists()) return;

    try {
      final contents = await file.readAsString();
      final json = jsonDecode(contents) as Map<String, dynamic>;
      final folderPath = json['customConfigFolder'] as String?;
      if (folderPath != null && folderPath.isNotEmpty) {
        _customConfigFolder = folderPath;
      }
    } catch (_) {
      // ignore invalid settings
    }
  }

  Future<void> saveSettings() async {
    final file = await _settingsFile();
    await file.writeAsString(jsonEncode({
      'customConfigFolder': _customConfigFolder,
    }));
  }

  Future<ModelConfig> loadConfig() async {
    await loadSettings();
    final file = await _configFile();
    if (!await file.exists()) {
      final config = ModelConfig.defaultConfig();
      await saveConfig(config);
      return config;
    }

    try {
      final contents = await file.readAsString();
      final raw = jsonDecode(contents) as Map<String, dynamic>;
      final loaded = ModelConfig.fromJson(raw);
      final migrated = ModelConfig.mergeWithDefaults(loaded);
      await saveConfig(migrated);
      return migrated;
    } catch (_) {
      final config = ModelConfig.defaultConfig();
      await saveConfig(config);
      return config;
    }
  }

  Future<void> saveConfig(ModelConfig config) async {
    final file = await _configFile();
    await file.writeAsString(jsonEncode(config.toJson()));
  }

  Future<Directory> currentConfigFolder() async {
    return await getConfigFolder();
  }
}
