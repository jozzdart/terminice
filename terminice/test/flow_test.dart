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
  final mock = MockTerminal();
  mock.mockInput.queueLines(lines);
  return terminice.fallback.withTerminal(mock);
}
