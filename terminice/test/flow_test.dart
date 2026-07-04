import 'package:test/test.dart';
import 'package:terminice/terminice.dart';

import 'mock_terminal.dart';

void main() {
  setUp(TerminalContext.reset);
  tearDown(TerminalContext.reset);

  group('flow', () {
    test('custom step stores typed values and result is confirmed', () {
      final result = terminice
          .flow('Profile')
          .custom<String>(
            'name',
            'Name',
            run: (_) => 'Ada',
          )
          .custom<int>(
            'age',
            'Age',
            run: (_) => 36,
          )
          .run();

      expect(result.confirmed, isTrue);
      expect(result.cancelled, isFalse);
      expect(result.cancelledKey, isNull);
      expect(result.value<String>('name'), 'Ada');
      expect(result.value<int>('age'), 36);
    });

    test('duplicate step keys are rejected while building', () {
      final builder = terminice.flow('Duplicates').custom<String>(
            'name',
            'Name',
            run: (_) => 'Ada',
          );

      expect(
        () => builder.custom<String>(
          'name',
          'Display name',
          run: (_) => 'Grace',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains("Flow 'Duplicates' already contains step key 'name'"),
              contains("'Name'"),
              contains("'Display name'"),
            ),
          ),
        ),
      );
    });

    test('include validates duplicate key collisions immediately', () {
      void template(FlowBuilder flow) {
        flow.text('name', 'Template name');
      }

      final builder = terminice.flow('Template').text('name', 'Name');

      expect(
        () => builder.include(template),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains("Flow 'Template' already contains step key 'name'"),
              contains("'Name'"),
              contains("'Template name'"),
            ),
          ),
        ),
      );
    });

    test('include composes template steps in declaration order', () {
      void template(FlowBuilder flow) {
        flow.text('name', 'Name').confirm('create', message: 'Create project?');
      }

      final result = _fallbackWithLines(['Ada', 'yes'])
          .flow('Template')
          .include(template)
          .custom<String>(
        'summary',
        'Summary',
        run: (context) {
          return '${context.string('name')}:${context.flag('create')}';
        },
      ).run();

      expect(result.confirmed, isTrue);
      expect(result.toMap().keys, orderedEquals(['name', 'create', 'summary']));
      expect(
        result.toMap(),
        equals({
          'name': 'Ada',
          'create': true,
          'summary': 'Ada:true',
        }),
      );
    });

    test('empty step keys are rejected while building', () {
      expect(
        () => terminice.flow('Empty key').custom<String>(
              '  ',
              'Name',
              run: (_) => 'Ada',
            ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('Flow step key must not be empty'),
          ),
        ),
      );
    });

    test('fallback text and confirm built-ins store queued answers', () {
      final result = _fallbackWithLines(['Ada', 'yes'])
          .flow('Project')
          .text('name', 'Name')
          .confirm('create', message: 'Create project?')
          .run();

      expect(result.confirmed, isTrue);
      expect(result.value<String>('name'), 'Ada');
      expect(result.value<bool>('create'), isTrue);
      expect(result.toMap(), equals({'name': 'Ada', 'create': true}));
    });

    test('text cancellation cancels flow with partial values preserved', () {
      var afterStepRan = false;

      final result = terminice.fallback
          .withTerminal(MockTerminal())
          .flow('Cancel text')
          .custom<String>(
            'before',
            'Before',
            run: (_) => 'kept',
          )
          .text('name', 'Name')
          .custom<String>(
        'after',
        'After',
        run: (_) {
          afterStepRan = true;
          return 'unexpected';
        },
      ).run();

      expect(result.confirmed, isFalse);
      expect(result.cancelledKey, 'name');
      expect(result.value<String>('before'), 'kept');
      expect(result.contains('name'), isFalse);
      expect(result.contains('after'), isFalse);
      expect(result.toMap(), equals({'before': 'kept'}));
      expect(afterStepRan, isFalse);
    });

    test('password cancellation cancels flow with partial values preserved',
        () {
      var afterStepRan = false;

      final result = terminice.fallback
          .withTerminal(MockTerminal())
          .flow('Cancel password')
          .custom<String>(
            'before',
            'Before',
            run: (_) => 'kept',
          )
          .password('secret', 'Secret')
          .custom<String>(
        'after',
        'After',
        run: (_) {
          afterStepRan = true;
          return 'unexpected';
        },
      ).run();

      expect(result.confirmed, isFalse);
      expect(result.cancelledKey, 'secret');
      expect(result.value<String>('before'), 'kept');
      expect(result.contains('secret'), isFalse);
      expect(result.contains('after'), isFalse);
      expect(result.toMap(), equals({'before': 'kept'}));
      expect(afterStepRan, isFalse);
    });

    test('confirm false and empty selectors do not cancel flow', () {
      final result = _fallbackWithLines(['no'])
          .flow('Built-in cancellation')
          .confirm('confirmed', message: 'Continue?')
          .select<String>(
        'choice',
        'Choice',
        options: const ['A', 'B'],
      ).checkboxes<String>(
        'choices',
        'Choices',
        options: const ['A', 'B'],
      ).run();

      expect(result.confirmed, isTrue);
      expect(result.cancelled, isFalse);
      expect(result.cancelledKey, isNull);
      expect(result.value<bool>('confirmed'), isFalse);
      expect(result.contains('choice'), isTrue);
      expect(result.maybe<String>('choice'), isNull);
      expect(result.value<List<String>>('choices'), isEmpty);
      expect(
        result.toMap(),
        equals({
          'confirmed': false,
          'choice': null,
          'choices': <String>[],
        }),
      );
    });

    test('select built-in stores the typed selected value', () {
      final result = _fallbackWithLines(['2'])
          .flow('Select')
          .select<int>(
            'port',
            'Port',
            options: const [3000, 8080, 9000],
            labelBuilder: (value) => 'port $value',
          )
          .run();

      expect(result.confirmed, isTrue);
      expect(result.value<int>('port'), 8080);
    });

    test('checkboxes built-in stores a typed list', () {
      final result = _fallbackWithLines(['1, 3'])
          .flow('Checkboxes')
          .checkboxes<int>(
            'ports',
            'Ports',
            options: const [3000, 8080, 9000],
            labelBuilder: (value) => 'port $value',
          )
          .run();

      expect(result.confirmed, isTrue);
      expect(result.value<List<int>>('ports'), [3000, 9000]);
    });

    test('checkboxes built-in stores an unmodifiable result list', () {
      final result = _fallbackWithLines(['1, 3'])
          .flow('Checkboxes')
          .checkboxes<int>(
            'ports',
            'Ports',
            options: const [3000, 8080, 9000],
            labelBuilder: (value) => 'port $value',
          )
          .run();

      final value = result.value<List<int>>('ports');
      final mappedValue = result.toMap()['ports'] as List<int>;

      expect(() => value.add(8080), throwsUnsupportedError);
      expect(() => mappedValue.add(8080), throwsUnsupportedError);
      expect(result.value<List<int>>('ports'), [3000, 9000]);
    });

    test('password built-in stores value in fallback plain mode', () {
      final result = _fallbackWithLines(['secret'])
          .flow('Credentials')
          .password('secret', 'Secret')
          .run();

      expect(result.confirmed, isTrue);
      expect(result.value<String>('secret'), 'secret');
    });

    test('review submit confirms collected values', () {
      final result = _fallbackWithLines(['Ada', '1'])
          .flow('Profile')
          .text('name', 'Name')
          .review()
          .run();

      expect(result.confirmed, isTrue);
      expect(result.cancelledKey, isNull);
      expect(result.toMap(), equals({'name': 'Ada'}));
    });

    test('review submit preserves insertion order and values', () {
      final result = _fallbackWithLines(['Ada', 'yes', '1, 3', '1'])
          .flow('Profile')
          .text('name', 'Name')
          .confirm('active', prompt: 'Active', message: 'Active?')
          .checkboxes<int>(
            'ports',
            'Ports',
            options: const [3000, 8080, 9000],
            labelBuilder: (value) => 'port $value',
          )
          .review()
          .run();

      final values = result.toMap();

      expect(result.confirmed, isTrue);
      expect(values.keys, orderedEquals(['name', 'active', 'ports']));
      expect(values['name'], 'Ada');
      expect(values['active'], isTrue);
      expect(values['ports'], equals([3000, 9000]));
    });

    test('review cancel preserves collected values without a cancelled key',
        () {
      final result = _fallbackWithLines(['Ada', '3'])
          .flow('Profile')
          .text('name', 'Name')
          .review()
          .run();

      expect(result.confirmed, isFalse);
      expect(result.cancelled, isTrue);
      expect(result.cancelledKey, isNull);
      expect(result.toMap(), equals({'name': 'Ada'}));
    });

    test('review edit reruns from the selected step and downstream values', () {
      var slugRuns = 0;

      final result = _fallbackWithLines(['Ada', '2', '2', 'Grace', '1'])
          .flow('Profile')
          .text('name', 'Name')
          .custom<String>(
            'slug',
            'Slug',
            includeInReview: true,
            run: (context) {
              slugRuns++;
              return context.string('name').toLowerCase();
            },
          )
          .review()
          .run();

      expect(result.confirmed, isTrue);
      expect(result.toMap(), equals({'name': 'Grace', 'slug': 'grace'}));
      expect(slugRuns, 2);
    });

    test('review edit re-evaluates conditions and removes invalidated values',
        () {
      final result = _fallbackWithLines(
        ['yes', 'details', '2', '2', 'no', '1'],
      )
          .flow('Conditional review')
          .confirm(
            'include',
            prompt: 'Include',
            message: 'Include details?',
          )
          .text(
            'details',
            'Details',
            when: (context) => context.flag('include'),
          )
          .review()
          .run();

      expect(result.confirmed, isTrue);
      expect(result.flag('include'), isFalse);
      expect(result.contains('details'), isFalse);
      expect(result.toMap(), equals({'include': false}));
    });

    test('review edit re-evaluates downstream validators', () {
      expect(
        () => _fallbackWithLines(['dev', 'dev', '2', '2', 'prod', 'dev'])
            .flow('Validate review edit')
            .text('target', 'Target')
            .text(
              'environment',
              'Environment',
              validate: (value, context) {
                final target = context.string('target');
                if (target == 'prod' && value != 'prod') {
                  return 'Production target must use prod environment';
                }
                return null;
              },
            )
            .review()
            .run(),
        throwsA(
          isA<FlowValidationException>()
              .having((error) => error.key, 'key', 'environment')
              .having((error) => error.label, 'label', 'Environment')
              .having(
                (error) => error.message,
                'message',
                'Production target must use prod environment',
              ),
        ),
      );
    });

    test('review edit can add newly enabled conditional values', () {
      final result = _fallbackWithLines(
        ['no', '2', '2', 'yes', 'details', '1'],
      )
          .flow('Conditional review')
          .confirm(
            'include',
            prompt: 'Include',
            message: 'Include details?',
          )
          .text(
            'details',
            'Details',
            when: (context) => context.flag('include'),
          )
          .review()
          .run();

      expect(result.confirmed, isTrue);
      expect(result.flag('include'), isTrue);
      expect(result.string('details'), 'details');
      expect(result.toMap().keys, orderedEquals(['include', 'details']));
    });

    test('review edit cancellation restores the pre-edit snapshot', () {
      var nameRuns = 0;
      var afterRuns = 0;
      final terminal = _terminalWithLines(['2', '2', '1']);

      final result = terminice.fallback
          .withTerminal(terminal)
          .flow('Restore edit')
          .custom<String>(
            'name',
            'Name',
            includeInReview: true,
            editable: true,
            run: (_) {
              nameRuns++;
              return nameRuns == 1 ? 'Ada' : null;
            },
          )
          .custom<String>(
            'after',
            'After',
            includeInReview: true,
            run: (_) {
              afterRuns++;
              return 'done $afterRuns';
            },
          )
          .review()
          .run();

      expect(result.confirmed, isTrue);
      expect(result.toMap(), equals({'name': 'Ada', 'after': 'done 1'}));
      expect(nameRuns, 2);
      expect(afterRuns, 1);
      expect(
        RegExp('Review Restore edit')
            .allMatches(terminal.outputSnapshot.plainText)
            .length,
        greaterThanOrEqualTo(2),
      );
    });

    test('review summaries honor metadata and safe defaults', () {
      final terminal = _terminalWithLines([
        'secret',
        '',
        'token',
        'hidden',
        'visible',
        '1',
      ]);

      final result = terminice.fallback
          .withTerminal(terminal)
          .flow('Review summaries')
          .password('secret', 'Secret')
          .password('optional', 'Optional', required: false)
          .password(
            'token',
            'Token',
            summarize: (value, _) => 'length ${value.length}',
          )
          .text('hidden', 'Hidden', includeInReview: false)
          .text(
            'custom',
            'Custom',
            reviewLabel: 'Friendly',
            summarize: (value, _) => 'custom $value',
          )
          .custom<List<String>>(
            'empty_list',
            'Empty list',
            includeInReview: true,
            run: (_) => const <String>[],
          )
          .custom<List<String>>(
            'list',
            'List',
            includeInReview: true,
            run: (_) => const <String>['one', 'two'],
          )
          .review()
          .run();

      final output = terminal.outputSnapshot.plainText;

      expect(result.confirmed, isTrue);
      expect(output, contains('Secret: ••••••••'));
      expect(output, contains('Optional: (empty)'));
      expect(output, contains('Token: length 5'));
      expect(output, contains('Friendly: custom visible'));
      expect(output, contains('Empty list: none'));
      expect(output, contains('List: one, two'));
      expect(output, isNot(contains('Secret: secret')));
      expect(output, isNot(contains('Hidden: hidden')));
    });

    test('review allowEdit false hides edit behavior', () {
      final terminal = _terminalWithLines(['Ada', '2']);

      final result = terminice.fallback
          .withTerminal(terminal)
          .flow('Locked review')
          .text('name', 'Name')
          .review(allowEdit: false)
          .run();

      final output = terminal.outputSnapshot.plainText;

      expect(result.confirmed, isFalse);
      expect(result.cancelled, isTrue);
      expect(result.cancelledKey, isNull);
      expect(result.toMap(), equals({'name': 'Ada'}));
      expect(output, contains('Review Locked review'));
      expect(output, contains('Name: Ada'));
      expect(output, contains('Submit'));
      expect(output, contains('Cancel'));
      expect(output, isNot(contains('Edit')));
      expect(output, isNot(contains('Edit review item')));
    });

    test('custom review items are not editable unless opted in', () {
      var runs = 0;
      final terminal = _terminalWithLines(['2', '1']);

      final result = terminice.fallback
          .withTerminal(terminal)
          .flow('Review defaults')
          .custom<String>(
            'generated',
            'Generated',
            includeInReview: true,
            run: (_) {
              runs++;
              return 'value';
            },
          )
          .review()
          .run();

      final output = terminal.outputSnapshot.plainText;

      expect(result.confirmed, isTrue);
      expect(result.toMap(), equals({'generated': 'value'}));
      expect(runs, 1);
      expect(output, contains('Generated: value'));
      expect(output, contains('No editable review items.'));
    });

    test('review direct output uses the configured terminal', () {
      final configured = _terminalWithLines(['2', '1']);
      final other = MockTerminal();
      final client = terminice.fallback.withTerminal(configured);
      TerminalContext.current = other;

      final result = client
          .flow('Routed review')
          .custom<String>(
            'name',
            'Name',
            includeInReview: true,
            run: (_) => 'Ada',
            summarize: (value, _) {
              TerminalContext.current = other;
              return 'summary $value';
            },
          )
          .review()
          .run();

      final configuredOutput = configured.outputSnapshot.plainText;
      final otherOutput = other.outputSnapshot.plainText;

      expect(result.confirmed, isTrue);
      expect(configuredOutput, contains('Review Routed review'));
      expect(configuredOutput, contains('Name: summary Ada'));
      expect(configuredOutput, contains('No editable review items.'));
      expect(otherOutput, isNot(contains('Review Routed review')));
      expect(otherOutput, isNot(contains('Name: summary Ada')));
      expect(otherOutput, isNot(contains('No editable review items.')));
    });

    test('progress decorates built-in fallback prompt titles when enabled', () {
      final terminal = _terminalWithLines(['Ada', 'yes']);

      final result = terminice.fallback
          .withTerminal(terminal)
          .flow('Progress')
          .progress()
          .text('first', 'First')
          .confirm('ready', prompt: 'Ready', message: 'Ready?')
          .run();

      expect(result.confirmed, isTrue);
      expect(terminal.outputSnapshot.plainText, contains('Step 1/2 - First'));
      expect(terminal.outputSnapshot.plainText, contains('Step 2/2 - Ready?'));
    });

    test('progress labels do not leak into review labels', () {
      final terminal = _terminalWithLines(['Ada', 'yes', '1']);

      final result = terminice.fallback
          .withTerminal(terminal)
          .flow('Progress review')
          .progress()
          .text('name', 'Name', reviewLabel: 'Display name')
          .confirm(
            'ready',
            prompt: 'Ready',
            message: 'Ready?',
            reviewLabel: 'Ready status',
            summarize: (value, _) => value ? 'yes' : 'no',
          )
          .review()
          .run();

      final output = terminal.outputSnapshot.plainText;
      final reviewStart = output.indexOf('Review Progress review');

      expect(result.confirmed, isTrue);
      expect(reviewStart, greaterThanOrEqualTo(0));

      final reviewOutput = output.substring(reviewStart);

      expect(output, contains('Step 1/2 - Name'));
      expect(output, contains('Step 2/2 - Ready?'));
      expect(reviewOutput, contains('Display name: Ada'));
      expect(reviewOutput, contains('Ready status: yes'));
      expect(reviewOutput, isNot(contains('Step 1/2')));
      expect(reviewOutput, isNot(contains('Step 2/2')));
    });

    test('fallback prompt titles keep old style without progress', () {
      final terminal = _terminalWithLines(['Ada', 'yes']);

      final result = terminice.fallback
          .withTerminal(terminal)
          .flow('No progress')
          .text('first', 'First')
          .confirm('ready', prompt: 'Ready', message: 'Ready?')
          .run();

      final output = terminal.outputSnapshot.plainText;

      expect(result.confirmed, isTrue);
      expect(output, contains('First: '));
      expect(output, contains('Ready? [Y/n]: '));
      expect(output, isNot(contains('Step 1/2 - First')));
      expect(output, isNot(contains('Step 2/2 - Ready?')));
    });

    test('conditions work with built-ins', () {
      final result = _fallbackWithLines(['no', 'done'])
          .flow('Conditional built-ins')
          .confirm('include', message: 'Include optional value?')
          .text(
            'skipped',
            'Skipped',
            when: (context) => context.value<bool>('include'),
          )
          .text('after', 'After')
          .run();

      expect(result.confirmed, isTrue);
      expect(result.value<bool>('include'), isFalse);
      expect(result.contains('skipped'), isFalse);
      expect(result.value<String>('after'), 'done');
      expect(result.toMap().keys, orderedEquals(['include', 'after']));
    });

    test('flow-level validators can use prior built-in answers', () {
      expect(
        () => _fallbackWithLines(['prod', '1'])
            .flow('Validate built-ins')
            .text('target', 'Target')
            .select<String>(
          'environment',
          'Environment',
          options: const ['dev', 'prod'],
          validate: (value, context) {
            final target = context.value<String>('target');
            if (target == 'prod' && value != 'prod') {
              return 'Production target must use prod environment';
            }
            return null;
          },
        ).run(),
        throwsA(
          isA<FlowValidationException>()
              .having((error) => error.key, 'key', 'environment')
              .having((error) => error.label, 'label', 'Environment')
              .having(
                (error) => error.message,
                'message',
                'Production target must use prod environment',
              ),
        ),
      );
    });

    test('text built-in validate can use prior answers', () {
      expect(
        () => _fallbackWithLines(['prod', 'dev'])
            .flow('Validate text')
            .text('target', 'Target')
            .text(
          'environment',
          'Environment',
          validate: (value, context) {
            final target = context.value<String>('target');
            if (target == 'prod' && value != 'prod') {
              return 'Production target must use prod environment';
            }
            return null;
          },
        ).run(),
        throwsA(
          isA<FlowValidationException>()
              .having((error) => error.key, 'key', 'environment')
              .having((error) => error.label, 'label', 'Environment')
              .having(
                (error) => error.message,
                'message',
                'Production target must use prod environment',
              ),
        ),
      );
    });

    test('password built-in validate can use prior answers', () {
      final result = _fallbackWithLines(['secret', 'secret'])
          .flow('Validate password')
          .text('expected', 'Expected')
          .password(
        'secret',
        'Secret',
        validate: (value, context) {
          return value == context.value<String>('expected')
              ? null
              : 'Password must match expected value';
        },
      ).run();

      expect(result.confirmed, isTrue);
      expect(result.value<String>('secret'), 'secret');
    });

    test('value, maybe, contains, and toMap expose stored values', () {
      final result = terminice
          .flow('Settings')
          .custom<String>(
            'name',
            'Name',
            run: (_) => 'Ada',
          )
          .custom<bool>(
            'enabled',
            'Enabled',
            run: (_) => true,
          )
          .run();

      expect(result.value<String>('name'), 'Ada');
      expect(result.maybe<String>('name'), 'Ada');
      expect(result.maybe<String>('missing'), isNull);
      expect(result.contains('enabled'), isTrue);
      expect(result.contains('missing'), isFalse);

      final map = result.toMap();
      expect(map.keys, orderedEquals(['name', 'enabled']));
      expect(map, equals({'name': 'Ada', 'enabled': true}));

      map['name'] = 'Grace';
      expect(result.value<String>('name'), 'Ada');

      final nextMap = result.toMap();
      expect(identical(map, nextMap), isFalse);
      expect(nextMap, equals({'name': 'Ada', 'enabled': true}));
    });

    test('helper APIs expose typed values on result and context', () {
      final result = terminice
          .flow('Helpers')
          .custom<String>(
            'name',
            'Name',
            run: (_) => 'Ada',
          )
          .custom<bool>(
            'enabled',
            'Enabled',
            run: (_) => true,
          )
          .custom<List<int>>(
            'ports',
            'Ports',
            run: (_) => List<int>.unmodifiable([3000, 9000]),
          )
          .custom<String>(
        'summary',
        'Summary',
        run: (context) {
          expect(context.string('name'), 'Ada');
          expect(context.maybeString('name'), 'Ada');
          expect(context.maybeString('missing'), isNull);
          expect(context.flag('enabled'), isTrue);
          expect(context.maybeFlag('enabled'), isTrue);
          expect(context.maybeFlag('missing'), isNull);
          expect(context.list<int>('ports'), [3000, 9000]);
          expect(context.valueOr<String>('name', 'fallback'), 'Ada');
          expect(context.valueOr<String>('missing', 'fallback'), 'fallback');

          return context.string('name');
        },
      ).run();

      expect(result.string('name'), 'Ada');
      expect(result.maybeString('name'), 'Ada');
      expect(result.maybeString('missing'), isNull);
      expect(result.flag('enabled'), isTrue);
      expect(result.maybeFlag('enabled'), isTrue);
      expect(result.maybeFlag('missing'), isNull);
      expect(result.list<int>('ports'), [3000, 9000]);
      expect(result.valueOr<String>('summary', 'fallback'), 'Ada');
      expect(result.valueOr<String>('missing', 'fallback'), 'fallback');
    });

    test('context helper APIs throw for wrong types', () {
      final result = terminice
          .flow('Context helper types')
          .custom<int>(
            'count',
            'Count',
            run: (_) => 3,
          )
          .custom<List<int>>(
            'ports',
            'Ports',
            run: (_) => List<int>.unmodifiable([3000]),
          )
          .custom<String>(
        'after',
        'After',
        run: (context) {
          expect(
            () => context.string('count'),
            throwsA(
              isA<StateError>().having(
                (error) => error.toString(),
                'message',
                allOf(
                  contains("Flow value 'count'"),
                  contains('cannot be read as String'),
                ),
              ),
            ),
          );
          expect(
            () => context.maybeString('count'),
            throwsA(isA<StateError>()),
          );
          expect(
            () => context.flag('count'),
            throwsA(isA<StateError>()),
          );
          expect(
            () => context.maybeFlag('count'),
            throwsA(isA<StateError>()),
          );
          expect(
            () => context.list<String>('ports'),
            throwsA(isA<StateError>()),
          );
          expect(
            () => context.valueOr<String>('count', 'fallback'),
            throwsA(isA<StateError>()),
          );

          return 'checked';
        },
      ).run();

      expect(result.string('after'), 'checked');
    });

    test('flow summary item stores public immutable review shape', () {
      const item = FlowSummaryItem(
        key: 'name',
        label: 'Name',
        value: 'Ada',
        summary: 'Ada Lovelace',
        editable: true,
      );

      expect(item.key, 'name');
      expect(item.label, 'Name');
      expect(item.value, 'Ada');
      expect(item.summary, 'Ada Lovelace');
      expect(item.editable, isTrue);
      expect(
        item,
        const FlowSummaryItem(
          key: 'name',
          label: 'Name',
          value: 'Ada',
          summary: 'Ada Lovelace',
          editable: true,
        ),
      );
    });

    test('flow context exposes prior values as a snapshot copy', () {
      FlowContext? capturedContext;

      final result = terminice
          .flow('Context')
          .custom<String>(
            'first',
            'First',
            run: (_) => 'one',
          )
          .custom<String>(
            'second',
            'Second',
            run: (context) {
              capturedContext = context;

              final values = context.toMap();
              expect(values, equals({'first': 'one'}));

              values['first'] = 'changed';
              expect(context.value<String>('first'), 'one');

              return context.value<String>('first');
            },
          )
          .custom<String>(
            'third',
            'Third',
            run: (_) => 'three',
          )
          .run();

      expect(result.confirmed, isTrue);
      expect(capturedContext, isNotNull);
      expect(capturedContext!.contains('third'), isFalse);
      expect(capturedContext!.toMap(), equals({'first': 'one'}));
      expect(
        result.toMap(),
        equals({
          'first': 'one',
          'second': 'one',
          'third': 'three',
        }),
      );
    });

    test('flow context cannot mutate stored checkbox list', () {
      final result = _fallbackWithLines(['1, 3'])
          .flow('Context checkbox list')
          .checkboxes<int>(
            'ports',
            'Ports',
            options: const [3000, 8080, 9000],
            labelBuilder: (value) => 'port $value',
          )
          .custom<String>(
        'after',
        'After',
        run: (context) {
          final value = context.value<List<int>>('ports');
          final mappedValue = context.toMap()['ports'] as List<int>;

          expect(() => value.add(8080), throwsUnsupportedError);
          expect(() => mappedValue.add(8080), throwsUnsupportedError);
          expect(context.value<List<int>>('ports'), [3000, 9000]);

          return 'done';
        },
      ).run();

      expect(result.confirmed, isTrue);
      expect(result.value<List<int>>('ports'), [3000, 9000]);
    });

    test('value and maybe throw useful errors for missing or wrong types', () {
      final result = terminice
          .flow('Types')
          .custom<int>(
            'count',
            'Count',
            run: (_) => 3,
          )
          .run();

      expect(
        () => result.value<String>('missing'),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            contains("Flow value 'missing' is missing"),
          ),
        ),
      );
      expect(
        () => result.value<String>('count'),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(
              contains("Flow value 'count'"),
              contains('cannot be read as String'),
            ),
          ),
        ),
      );
      expect(
        () => result.maybe<String>('count'),
        throwsA(isA<StateError>()),
      );
      expect(
        () => result.string('count'),
        throwsA(isA<StateError>()),
      );
      expect(
        () => result.maybeString('count'),
        throwsA(isA<StateError>()),
      );
      expect(
        () => result.flag('count'),
        throwsA(isA<StateError>()),
      );
      expect(
        () => result.maybeFlag('count'),
        throwsA(isA<StateError>()),
      );
      expect(
        () => result.list<String>('count'),
        throwsA(isA<StateError>()),
      );
      expect(
        () => result.valueOr<String>('count', 'fallback'),
        throwsA(isA<StateError>()),
      );
    });

    test('when skips a step without writing a value', () {
      var skippedStepRan = false;

      final result = terminice
          .flow('Conditional')
          .custom<bool>(
            'include',
            'Include',
            run: (_) => false,
          )
          .custom<String>(
            'skipped',
            'Skipped',
            when: (context) => context.value<bool>('include'),
            run: (_) {
              skippedStepRan = true;
              return 'unexpected';
            },
          )
          .custom<String>(
        'after',
        'After',
        run: (context) {
          expect(context.contains('skipped'), isFalse);
          return 'done';
        },
      ).run();

      expect(skippedStepRan, isFalse);
      expect(result.contains('include'), isTrue);
      expect(result.contains('skipped'), isFalse);
      expect(result.value<String>('after'), 'done');
      expect(result.toMap().keys, orderedEquals(['include', 'after']));
      expect(result.toMap(), equals({'include': false, 'after': 'done'}));
    });

    test('null custom step cancels by default with partial values preserved',
        () {
      var afterStepRan = false;

      final result = terminice
          .flow('Cancel')
          .custom<String>(
            'name',
            'Name',
            run: (_) => 'Ada',
          )
          .custom<String>(
            'cancelled',
            'Cancelled',
            run: (_) => null,
          )
          .custom<String>(
        'after',
        'After',
        run: (_) {
          afterStepRan = true;
          return 'unexpected';
        },
      ).run();

      expect(result.confirmed, isFalse);
      expect(result.cancelled, isTrue);
      expect(result.cancelledKey, 'cancelled');
      expect(result.value<String>('name'), 'Ada');
      expect(result.contains('cancelled'), isFalse);
      expect(result.contains('after'), isFalse);
      expect(result.toMap(), equals({'name': 'Ada'}));
      expect(afterStepRan, isFalse);
    });

    test('cancelOnNull false stores null and continues', () {
      final result = terminice
          .flow('Nullable')
          .custom<String>(
            'optional',
            'Optional',
            run: (_) => null,
            cancelOnNull: false,
          )
          .custom<String>(
        'after',
        'After',
        run: (context) {
          expect(context.contains('optional'), isTrue);
          expect(context.maybe<String>('optional'), isNull);
          return 'done';
        },
      ).run();

      expect(result.confirmed, isTrue);
      expect(result.contains('optional'), isTrue);
      expect(result.maybe<String>('optional'), isNull);
      expect(result.value<String>('after'), 'done');
      expect(
        result.toMap().entries.map((entry) => entry.key),
        orderedEquals(['optional', 'after']),
      );
      expect(result.toMap()['optional'], isNull);
    });

    test('custom nullable step validator can reject stored null', () {
      expect(
        () => terminice
            .flow('Nullable validation')
            .custom<String?>(
              'optional',
              'Optional',
              run: (_) => null,
              validate: (value, _) =>
                  value == null ? 'Optional value is required' : null,
              cancelOnNull: false,
            )
            .run(),
        throwsA(
          isA<FlowValidationException>()
              .having((error) => error.key, 'key', 'optional')
              .having((error) => error.label, 'label', 'Optional')
              .having(
                (error) => error.message,
                'message',
                'Optional value is required',
              ),
        ),
      );
    });

    test('select validator can reject no selection', () {
      expect(
        () => terminice.fallback
            .withTerminal(MockTerminal())
            .flow('Required select')
            .select<String>(
              'choice',
              'Choice',
              options: const ['A', 'B'],
              validate: (value, _) =>
                  value == null ? 'Choose one option' : null,
            )
            .run(),
        throwsA(
          isA<FlowValidationException>()
              .having((error) => error.key, 'key', 'choice')
              .having((error) => error.label, 'label', 'Choice')
              .having(
                (error) => error.message,
                'message',
                'Choose one option',
              ),
        ),
      );
    });

    test('validator accepts null and empty string, and rejects error string',
        () {
      final accepted = terminice
          .flow('Validation')
          .custom<String>(
            'null_ok',
            'Null OK',
            run: (_) => 'Ada',
            validate: (_, __) => null,
          )
          .custom<String>(
            'empty_ok',
            'Empty OK',
            run: (_) => 'Grace',
            validate: (_, __) => '',
          )
          .run();

      expect(accepted.confirmed, isTrue);
      expect(accepted.value<String>('null_ok'), 'Ada');
      expect(accepted.value<String>('empty_ok'), 'Grace');

      expect(
        () => terminice
            .flow('Invalid')
            .custom<String>(
              'name',
              'Name',
              run: (_) => 'Ada',
              validate: (_, __) => 'Wrong value',
            )
            .run(),
        throwsA(
          isA<FlowValidationException>()
              .having((error) => error.key, 'key', 'name')
              .having((error) => error.label, 'label', 'Name')
              .having((error) => error.message, 'message', 'Wrong value'),
        ),
      );
    });

    test('validation exception includes key label message and readable text',
        () {
      try {
        terminice
            .flow('Invalid')
            .custom<String>(
              'name',
              'Display name',
              run: (_) => 'Ada',
              validate: (_, __) => 'Wrong value',
            )
            .run();
        fail('Expected validation to throw.');
      } on FlowValidationException catch (error) {
        expect(error.key, 'name');
        expect(error.label, 'Display name');
        expect(error.message, 'Wrong value');
        expect(
          error.toString(),
          allOf(
            contains("step 'name'"),
            contains('Display name'),
            contains('Wrong value'),
          ),
        );
      }
    });

    test('custom step runs with the configured Terminice terminal active', () {
      final configured = MockTerminal();
      final other = MockTerminal();
      final client = terminice.withTerminal(configured);
      TerminalContext.current = other;

      Terminal? activeTerminal;
      Terminice? contextTerminice;

      final result = client.flow('Terminal').custom<Terminal>(
        'terminal',
        'Terminal',
        run: (context) {
          activeTerminal = TerminalContext.current;
          contextTerminice = context.terminice;
          return TerminalContext.current;
        },
      ).run();

      expect(activeTerminal, same(configured));
      expect(contextTerminice, same(client));
      expect(result.value<Terminal>('terminal'), same(configured));
      expect(TerminalContext.current, same(configured));
    });

    test('flow API is exported from package barrel', () {
      final FlowBuilder builder = terminice.flow('Export');

      String runner(FlowContext context) => 'ok';
      String? validator(String value, FlowContext context) => null;
      bool condition(FlowContext context) => true;

      final FlowResult result = builder
          .custom<String>(
            'key',
            'Key',
            run: runner,
            validate: validator,
            when: condition,
          )
          .run();

      expect(result.value<String>('key'), 'ok');
    });
  });
}

Terminice _fallbackWithLines(List<String> lines) {
  return terminice.fallback.withTerminal(_terminalWithLines(lines));
}

MockTerminal _terminalWithLines(List<String> lines) {
  final mock = MockTerminal();
  mock.mockInput.queueLines(lines);
  return mock;
}
