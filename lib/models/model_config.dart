class ModelDefinition {
  final String id;
  final String name;
  final String downloadUrl;
  String? localPath;

  ModelDefinition({
    required this.id,
    required this.name,
    required this.downloadUrl,
    this.localPath,
  });

  bool get hasLocalPath => localPath?.isNotEmpty == true;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'downloadUrl': downloadUrl,
        'localPath': localPath,
      };

  factory ModelDefinition.fromJson(Map<String, dynamic> json) {
    return ModelDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      downloadUrl: json['downloadUrl'] as String,
      localPath: json['localPath'] as String?,
    );
  }
}

class ModelConfig {
  final String version;
  String? selectedModelId;
  List<ModelDefinition> models;

  ModelConfig({
    required this.version,
    this.selectedModelId,
    required this.models,
  });

  factory ModelConfig.defaultConfig() {
    return ModelConfig(
      version: '1.0',
      selectedModelId: 'gemma-4-e2b',
      models: [
        ModelDefinition(
          id: 'gemma-4-e2b',
          name: 'Gemma 4 E2B',
          downloadUrl: 'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
          localPath: null,
        ),
        ModelDefinition(
          id: 'gemma-4-e4b',
          name: 'Gemma 4 E4B',
          downloadUrl: 'https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/gemma-4-E4B-it.litertlm',
          localPath: null,
        ),
      ],
    );
  }

  static ModelConfig mergeWithDefaults(ModelConfig current) {
    final defaults = ModelConfig.defaultConfig();
    final mergedModels = <ModelDefinition>[];

    for (final defaultModel in defaults.models) {
      final existing = current.models.firstWhere(
        (model) => model.id == defaultModel.id,
        orElse: () => defaultModel,
      );

      final downloadUrl = (existing.downloadUrl.isEmpty || 
                           existing.downloadUrl.contains('example.com') ||
                           existing.downloadUrl.contains('huggingface.co/gemma/gemma-4'))
          ? defaultModel.downloadUrl
          : existing.downloadUrl;
      mergedModels.add(
        ModelDefinition(
          id: defaultModel.id,
          name: defaultModel.name,
          downloadUrl: downloadUrl,
          localPath: existing.localPath,
        ),
      );
    }

    return ModelConfig(
      version: current.version,
      selectedModelId: current.selectedModelId ?? defaults.selectedModelId,
      models: mergedModels,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'selectedModelId': selectedModelId,
      'models': models.map((m) => m.toJson()).toList(),
    };
  }

  factory ModelConfig.fromJson(Map<String, dynamic> json) {
    return ModelConfig(
      version: json['version'] as String? ?? '1.0',
      selectedModelId: json['selectedModelId'] as String?,
      models: (json['models'] as List<dynamic>?)
              ?.map((item) => ModelDefinition.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
