import 'dart:convert';

import 'package:terminice/terminice.dart';

void main() {
  final result = terminice.configEditor(
    title: 'App Settings',
    fields: [
      ThemeConfigurable(
        key: 'theme',
        label: 'Theme',
        value: 'dark',
        description: 'Color scheme for the editor (changes live!)',
      ),
      BoolConfigurable(
        key: 'darkMode',
        label: 'Dark Mode',
        value: true,
        description: 'Use dark color scheme throughout the app',
      ),
      StringConfigurable(
        key: 'appName',
        label: 'App Name',
        value: 'My App',
        placeholder: 'Enter app name...',
        required: true,
        description: 'Display name shown in the title bar and about page',
      ),
      StringConfigurable(
        key: 'description',
        label: 'Description',
        value: '',
        multiline: true,
        visibleLines: 6,
        description: 'A longer description for your project (multiline)',
      ),

      // --- Groups ---

      GroupConfigurable(
        key: 'network',
        label: 'Network',
        description: 'Connection, proxy, and timeout settings',
        children: [
          StringConfigurable(
            key: 'host',
            label: 'Host',
            value: 'localhost',
            description: 'Server hostname or IP address',
          ),
          NumberConfigurable(
            key: 'port',
            label: 'Port',
            value: 8080,
            min: 1,
            max: 65535,
            integerOnly: true,
            description: 'HTTP server port (1–65535)',
          ),
          NumberConfigurable(
            key: 'timeout',
            label: 'Timeout',
            value: 30,
            min: 1,
            max: 300,
            useSlider: true,
            unit: 's',
            description: 'Request timeout in seconds',
          ),
          GroupConfigurable(
            key: 'proxy',
            label: 'Proxy',
            description: 'HTTP proxy configuration',
            children: [
              BoolConfigurable(
                key: 'enabled',
                label: 'Enabled',
                value: false,
                description: 'Route traffic through a proxy server',
              ),
              StringConfigurable(
                key: 'url',
                label: 'Proxy URL',
                value: '',
                placeholder: 'http://proxy:3128',
                description: 'Full URL of the proxy server',
              ),
              PasswordConfigurable(
                key: 'proxyAuth',
                label: 'Proxy Auth',
                allowReveal: true,
                description: 'Authentication token for the proxy',
              ),
            ],
          ),
        ],
      ),

      GroupConfigurable(
        key: 'security',
        label: 'Security',
        description: 'Authentication and encryption settings',
        children: [
          PasswordConfigurable(
            key: 'apiKey',
            label: 'API Key',
            allowReveal: true,
            description: 'Secret key for external service authentication',
          ),
          EnumConfigurable(
            key: 'authMode',
            label: 'Auth Mode',
            value: 'token',
            options: ['token', 'oauth2', 'basic', 'none'],
            description: 'Authentication method for API requests',
          ),
          BoolConfigurable(
            key: 'tlsVerify',
            label: 'TLS Verify',
            value: true,
            description: 'Verify TLS certificates on outgoing connections',
          ),
        ],
      ),

      // --- Remaining leaf fields ---

      EnumConfigurable(
        key: 'environment',
        label: 'Environment',
        value: 'development',
        options: ['development', 'staging', 'production'],
        description: 'Target deployment environment',
      ),
      NumberConfigurable(
        key: 'volume',
        label: 'Volume',
        value: 75,
        min: 0,
        max: 100,
        useSlider: true,
        unit: '%',
        description: 'Notification sound level',
      ),
      RangeConfigurable(
        key: 'priceRange',
        label: 'Price Range',
        start: 10,
        end: 50,
        min: 0,
        max: 100,
        unit: '\$',
        description: 'Min and max price filter for search results',
      ),
      RatingConfigurable(
        key: 'priority',
        label: 'Priority',
        value: 3,
        maxStars: 5,
        labels: ['Lowest', 'Low', 'Medium', 'High', 'Critical'],
        description: 'Task priority level from 1 (lowest) to 5 (critical)',
      ),
    ],
  );

  if (result == null) {
    print('\nCancelled.');
    return;
  }

  print('\n--- Result ---');
  print('Changed: ${result.hasChanges}');

  if (result.hasChanges) {
    print('Modified fields:');
    printModified(result.fields);
  }

  final json = const JsonEncoder.withIndent('  ').convert(result.toMap());
  print('\nJSON output:\n$json');
}

void printModified(List<Configurable> fields, {int indent = 1}) {
  final pad = '  ' * indent;
  for (final field in fields) {
    if (!field.isModified) continue;
    if (field is GroupConfigurable) {
      print('$pad${field.key}: ${field.displayValue}');
      printModified(field.children, indent: indent + 1);
    } else {
      print('$pad${field.key}: ${field.displayValue}');
    }
  }
}
