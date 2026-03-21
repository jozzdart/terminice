import 'dart:convert';

import 'package:terminice/terminice.dart';

void main() {
  final c = terminice.config;

  final result = terminice.matrix.configEditor(
    title: 'App Settings',
    fields: [
      c.theme(
        key: 'theme',
        label: 'Theme',
        value: 'matrix',
        description: 'Color scheme for the editor',
      ),
      c.boolean(
        key: 'darkMode',
        label: 'Dark Mode',
        value: true,
        description: 'Use dark color scheme throughout the app',
      ),
      c.string(
        key: 'appName',
        label: 'App Name',
        value: 'My App',
        placeholder: 'Enter app name...',
        required: true,
        description: 'Display name shown in the title bar and about page',
      ),
      c.string(
        key: 'description',
        label: 'Description',
        multiline: true,
        visibleLines: 6,
        description: 'A longer description for your project (multiline)',
      ),
      c.group(
        key: 'network',
        label: 'Network',
        description: 'Connection, proxy, and timeout settings',
        children: [
          c.string(
              key: 'host',
              label: 'Host',
              value: 'localhost',
              description: 'Server hostname or IP address'),
          c.number(
              key: 'port',
              label: 'Port',
              value: 8080,
              min: 1,
              max: 65535,
              integerOnly: true,
              description: 'HTTP server port (1–65535)'),
          c.number(
            key: 'timeout',
            label: 'Timeout',
            value: 30,
            min: 1,
            max: 300,
            useSlider: true,
            unit: 's',
            description: 'Request timeout in seconds',
          ),
          c.group(
            key: 'proxy',
            label: 'Proxy',
            description: 'HTTP proxy configuration',
            children: [
              c.boolean(
                  key: 'enabled',
                  label: 'Enabled',
                  description: 'Route traffic through a proxy server'),
              c.string(
                  key: 'url',
                  label: 'Proxy URL',
                  placeholder: 'http://proxy:3128',
                  description: 'Full URL of the proxy server'),
              c.password(
                key: 'proxyAuth',
                label: 'Proxy Auth',
                allowReveal: true,
                description: 'Authentication token for the proxy',
                verify: true,
              ),
            ],
          ),
        ],
      ),
      c.group(
        key: 'security',
        label: 'Security',
        description: 'Authentication and encryption settings',
        children: [
          c.password(
            key: 'apiKey',
            label: 'API Key',
            allowReveal: true,
            description: 'Secret key for external service authentication',
          ),
          c.select(
            key: 'authMode',
            label: 'Auth Mode',
            value: 'token',
            options: ['token', 'oauth2', 'basic', 'none'],
            description: 'Authentication method for API requests',
          ),
          c.boolean(
            key: 'tlsVerify',
            label: 'TLS Verify',
            value: true,
            description: 'Verify TLS certificates on outgoing connections',
          ),
        ],
      ),
      c.select(
        key: 'environment',
        label: 'Environment',
        value: 'development',
        options: ['development', 'staging', 'production'],
        description: 'Target deployment environment',
      ),
      c.number(
        key: 'volume',
        label: 'Volume',
        value: 75,
        max: 100,
        useSlider: true,
        unit: '%',
        description: 'Notification sound level',
      ),
      c.range(
        key: 'priceRange',
        label: 'Price Range',
        start: 10,
        end: 50,
        max: 100,
        unit: '\$',
        description: 'Min and max price filter for search results',
      ),
      c.rating(
        key: 'priority',
        label: 'Priority',
        value: 3,
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
