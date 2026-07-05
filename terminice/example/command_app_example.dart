import 'dart:io';

import 'package:terminice/terminice.dart';

const _ok = 0;
const _usageError = 64;
const _cancelled = 1;

Future<void> main(List<String> args) async {
  exitCode = await runCommandApp(args, terminice.autoFallback);
}

Future<int> runCommandApp(List<String> args, Terminice t) async {
  final options = _CommandOptions.parse(args);
  final cli = options.ci ? t.legacy.fallback : t;

  if (options.unknownArguments.isNotEmpty) {
    final label = options.unknownArguments.length == 1
        ? 'Unknown option'
        : 'Unknown options';
    cli.error('$label: ${options.unknownArguments.join(', ')}');
    _showHelp(cli);
    return _usageError;
  }

  switch (options.command) {
    case null:
    case 'help':
      _showHelp(cli);
      return _ok;
    case 'init':
      return _init(options, cli);
    case 'publish':
      return _publish(options, cli);
    default:
      cli.error('Unknown command: ${options.command}');
      cli.detail('Run `dart run example/command_app_example.dart help`.');
      return _usageError;
  }
}

Future<int> _init(_CommandOptions options, Terminice t) async {
  if (options.ci && (options.name == null || !options.yes)) {
    t.error('CI init requires --name=<project> and --yes.');
    return _usageError;
  }

  final setup = options.name == null
      ? _runInitFlow(t)
      : _InitSetup(
          name: options.name!,
          template: 'console',
          features: const ['README'],
          confirmed: options.yes || t.confirm(message: 'Create project?'),
        );

  if (!setup.confirmed) {
    t.warn('Project creation cancelled.');
    return _cancelled;
  }

  t.info('Creating ${setup.name}');
  t.detail('Template: ${setup.template}');
  t.detail('Features: ${setup.features.join(', ')}');

  await t.task<void>(
    'Install starter files',
    display: options.ci ? TaskDisplay.plain : TaskDisplay.auto,
    run: () async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    success: 'Project ready: ${setup.name}',
  );

  t.success('Created ${setup.name}');
  return _ok;
}

Future<int> _publish(_CommandOptions options, Terminice t) async {
  if (options.ci && !options.yes) {
    t.error('CI publish requires --yes.');
    return _usageError;
  }

  final confirmed = options.yes ||
      t.confirm(
        message: 'Publish this package?',
        defaultYes: false,
      );

  if (!confirmed) {
    t.warn('Publish cancelled.');
    return _cancelled;
  }

  t.info('Preparing release');
  await t.task<void>(
    'Upload package',
    message: options.ci ? 'CI mode' : null,
    display: options.ci ? TaskDisplay.plain : TaskDisplay.auto,
    run: () async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    success: 'Package published',
  );
  t.success('Publish complete');
  return _ok;
}

_InitSetup _runInitFlow(Terminice t) {
  final result = t
      .flow('Initialize app')
      .progress()
      .text(
        'name',
        'Project name',
        placeholder: 'terminice_app',
        validator: (value) =>
            value.trim().isEmpty ? 'Enter a project name.' : null,
      )
      .select<String>(
        'template',
        'Template',
        options: const ['console', 'worker', 'library'],
        showSearch: false,
      )
      .checkboxes<String>(
        'features',
        'Features',
        options: const ['README', 'CI workflow', 'Sample command'],
        initialSelected: const {0},
        summarize: (values, _) => values.isEmpty ? 'none' : values.join(', '),
      )
      .confirm(
        'create',
        prompt: 'Create project',
        message: 'Create project?',
      )
      .run();

  return _InitSetup(
    name: result.valueOr<String>('name', 'terminice_app'),
    template: result.valueOr<String>('template', 'console'),
    features: result.valueOr<List<String>>('features', const ['README']),
    confirmed: result.valueOr<bool>('create', false),
  );
}

void _showHelp(Terminice t) {
  t.log('Terminice command app example');
  t.newline();
  t.info('Commands');
  t.detail('init [--name=<project>] [--yes] [--ci]');
  t.detail('publish [--yes] [--ci]');
  t.detail('help');
  t.newline();
  t.log('Examples:');
  t.log('  dart run example/command_app_example.dart init --name=atlas --yes');
  t.log('  dart run example/command_app_example.dart publish --ci --yes');
}

class _CommandOptions {
  const _CommandOptions({
    required this.command,
    required this.name,
    required this.yes,
    required this.ci,
    required this.unknownArguments,
  });

  final String? command;
  final String? name;
  final bool yes;
  final bool ci;
  final List<String> unknownArguments;

  static _CommandOptions parse(List<String> args) {
    String? command;
    String? name;
    var yes = false;
    var ci = false;
    final unknownArguments = <String>[];

    for (final arg in args) {
      if (arg.startsWith('--name=')) {
        name = arg.substring('--name='.length).trim();
        if (name.isEmpty) name = null;
      } else if (arg == '--yes') {
        yes = true;
      } else if (arg == '--ci') {
        ci = true;
      } else if (arg.startsWith('-')) {
        unknownArguments.add(arg);
      } else if (command == null && !arg.startsWith('-')) {
        command = arg;
      }
    }

    return _CommandOptions(
      command: command,
      name: name,
      yes: yes,
      ci: ci,
      unknownArguments: unknownArguments,
    );
  }
}

class _InitSetup {
  const _InitSetup({
    required this.name,
    required this.template,
    required this.features,
    required this.confirmed,
  });

  final String name;
  final String template;
  final List<String> features;
  final bool confirmed;
}
