class ToolDefinition {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  ToolDefinition({
    required this.name,
    required this.description,
    required this.parameters,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'parameters': parameters,
  };
}

final List<ToolDefinition> availableTools = [
  ToolDefinition(
    name: 'get_battery_level',
    description: 'Get the current battery level of the device',
    parameters: {
      'type': 'object',
      'properties': {},
    },
  ),
  ToolDefinition(
    name: 'get_current_time',
    description: 'Get the current system time',
    parameters: {
      'type': 'object',
      'properties': {},
    },
  ),
  ToolDefinition(
    name: 'toggle_flashlight',
    description: 'Turn the device flashlight on or off',
    parameters: {
      'type': 'object',
      'properties': {
        'state': {
          'type': 'string',
          'enum': ['on', 'off'],
          'description': 'The desired state of the flashlight',
        }
      },
      'required': ['state'],
    },
  ),
];
