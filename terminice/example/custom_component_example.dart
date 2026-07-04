import 'package:terminice/testing.dart';

class _ProjectNameComponent extends TerminiceComponent<String> {
  const _ProjectNameComponent();

  @override
  String run(TerminiceComponentContext context) {
    final name = context.terminice.text(
      'Project name',
      placeholder: 'terminice_app',
    );

    return name == null || name.isEmpty ? 'terminice_app' : name;
  }
}

TerminiceComponent<List<String>> _featuresComponent({
  required String prompt,
  required String fallbackPrompt,
}) {
  return TerminiceComponent<List<String>>.from((context) {
    final title = context.shouldUseFallback ? fallbackPrompt : prompt;

    return context.terminice.searchSelector(
      prompt: title,
      options: const ['Git repository', 'CI workflow', 'Dockerfile'],
      multiSelect: true,
      showSearch: true,
    );
  });
}

FlowResult _runProjectFlow(Terminice t) {
  return t
      .flow('Scaffold project')
      .progress()
      .component<String>(
        'name',
        'Project name',
        component: const _ProjectNameComponent(),
        reviewLabel: 'Project',
      )
      .custom<List<String>>(
        'features',
        'Features',
        includeInReview: true,
        editable: true,
        summarize: (values, _) => values.isEmpty ? 'none' : values.join(', '),
        run: (context) {
          return context.runComponent<List<String>>(
            _featuresComponent(
              prompt: context.promptTitle('Features'),
              fallbackPrompt: context.fallbackPromptTitle('Features'),
            ),
          );
        },
      )
      .confirm(
        'create',
        prompt: 'Create project',
        message: 'Create project?',
        reviewLabel: 'Create',
        summarize: (value, _) => value ? 'yes' : 'no',
      )
      .run();
}

void main() {
  final tester = TerminiceTester.fallback(
    base: terminice.ocean.basic,
    lines: const ['atlas', '1,3', 'yes'],
  );

  final result = tester.run(_runProjectFlow);

  if (result.cancelled || !result.valueOr<bool>('create', false)) {
    print('Project creation cancelled.');
    return;
  }

  final name = result.string('name');
  final features = result.list<String>('features');

  print('Created $name with ${features.join(', ')}.');
}
