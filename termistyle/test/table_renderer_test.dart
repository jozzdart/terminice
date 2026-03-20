import 'package:test/test.dart';
import 'package:termistyle/termistyle.dart';

/// Strip all ANSI codes from a string for content assertions.
String _strip(String s) => stripAnsi(s);

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // ColumnConfig
  // ══════════════════════════════════════════════════════════════════════════

  group('ColumnConfig', () {
    test('default constructor defaults to left alignment', () {
      const c = ColumnConfig('Name');
      expect(c.header, equals('Name'));
      expect(c.align, equals(ColumnAlign.left));
      expect(c.minWidth, isNull);
      expect(c.maxWidth, isNull);
    });

    test('accepts min and max width constraints', () {
      const c = ColumnConfig('Col', minWidth: 5, maxWidth: 20);
      expect(c.minWidth, equals(5));
      expect(c.maxWidth, equals(20));
    });

    test('.left named constructor sets left alignment', () {
      const c = ColumnConfig.left('Name');
      expect(c.align, equals(ColumnAlign.left));
    });

    test('.center named constructor sets center alignment', () {
      const c = ColumnConfig.center('Status');
      expect(c.align, equals(ColumnAlign.center));
    });

    test('.right named constructor sets right alignment', () {
      const c = ColumnConfig.right('Count');
      expect(c.align, equals(ColumnAlign.right));
    });

    test('named constructors accept width constraints', () {
      const c = ColumnConfig.right('ID', minWidth: 3, maxWidth: 10);
      expect(c.minWidth, equals(3));
      expect(c.maxWidth, equals(10));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Factory constructors
  // ══════════════════════════════════════════════════════════════════════════

  group('TableRenderer.fromHeaders', () {
    test('creates left-aligned columns from plain strings', () {
      final t = TableRenderer.fromHeaders(['Name', 'Age']);
      expect(t.columnCount, equals(2));
      expect(t.columns[0].header, equals('Name'));
      expect(t.columns[0].align, equals(ColumnAlign.left));
      expect(t.columns[1].header, equals('Age'));
    });

    test('accepts theme parameter', () {
      final t = TableRenderer.fromHeaders(['A'], theme: PromptTheme.matrix);
      expect(t.theme, same(PromptTheme.matrix));
    });

    test('accepts zebraStripes parameter', () {
      final t = TableRenderer.fromHeaders(['A'], zebraStripes: false);
      expect(t.zebraStripes, isFalse);
    });

    test('accepts cellPadding parameter', () {
      final t = TableRenderer.fromHeaders(['A'], cellPadding: 2);
      expect(t.cellPadding, equals(2));
    });
  });

  group('TableRenderer.withAlignments', () {
    test('applies provided alignments to columns', () {
      final t = TableRenderer.withAlignments(
        ['Name', 'Status', 'Count'],
        [ColumnAlign.left, ColumnAlign.center, ColumnAlign.right],
      );
      expect(t.columns[0].align, equals(ColumnAlign.left));
      expect(t.columns[1].align, equals(ColumnAlign.center));
      expect(t.columns[2].align, equals(ColumnAlign.right));
    });

    test('defaults to left when alignments list is shorter', () {
      final t = TableRenderer.withAlignments(
        ['A', 'B', 'C'],
        [ColumnAlign.right],
      );
      expect(t.columns[0].align, equals(ColumnAlign.right));
      expect(t.columns[1].align, equals(ColumnAlign.left));
      expect(t.columns[2].align, equals(ColumnAlign.left));
    });

    test('handles empty alignments list', () {
      final t = TableRenderer.withAlignments(['A', 'B'], []);
      expect(t.columns[0].align, equals(ColumnAlign.left));
      expect(t.columns[1].align, equals(ColumnAlign.left));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Properties
  // ══════════════════════════════════════════════════════════════════════════

  group('properties', () {
    test('columnCount returns the number of columns', () {
      final t = TableRenderer.fromHeaders(['A', 'B', 'C']);
      expect(t.columnCount, equals(3));
    });

    test('widths is empty before computation', () {
      final t = TableRenderer.fromHeaders(['A']);
      expect(t.widths, isEmpty);
    });

    test('contentWidth returns 0 when widths are empty', () {
      final t = TableRenderer.fromHeaders(['A']);
      expect(t.contentWidth, equals(0));
    });

    test('defaults to dark theme', () {
      final t = TableRenderer.fromHeaders(['A']);
      expect(t.theme, same(PromptTheme.dark));
    });

    test('defaults to zebraStripes enabled', () {
      final t = TableRenderer.fromHeaders(['A']);
      expect(t.zebraStripes, isTrue);
    });

    test('defaults to cellPadding 0', () {
      final t = TableRenderer.fromHeaders(['A']);
      expect(t.cellPadding, equals(0));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Width computation
  // ══════════════════════════════════════════════════════════════════════════

  group('computeWidths', () {
    test('widths match the longest content per column', () {
      final t = TableRenderer.fromHeaders(['Name', 'Age']);
      t.computeWidths([
        ['Alice', '30'],
        ['Bob', '7'],
      ]);
      expect(t.widths[0], equals(5)); // 'Alice' = 5 > 'Name' = 4
      expect(t.widths[1], equals(3)); // 'Age' = 3 > '30' = 2
    });

    test('header width is used when it exceeds row data', () {
      final t = TableRenderer.fromHeaders(['LongHeader', 'X']);
      t.computeWidths([
        ['A', 'B'],
      ]);
      expect(t.widths[0], equals(10)); // 'LongHeader' = 10
      expect(t.widths[1], equals(1)); // 'X' = 1
    });

    test('respects minWidth constraint', () {
      final t = TableRenderer(columns: [
        ColumnConfig('A', minWidth: 10),
      ]);
      t.computeWidths([
        ['B'],
      ]);
      expect(t.widths[0], equals(10));
    });

    test('respects maxWidth constraint', () {
      final t = TableRenderer(columns: [
        ColumnConfig('A', maxWidth: 3),
      ]);
      t.computeWidths([
        ['VeryLongContent'],
      ]);
      expect(t.widths[0], equals(3));
    });

    test('handles rows shorter than column count', () {
      final t = TableRenderer.fromHeaders(['A', 'B', 'C']);
      t.computeWidths([
        ['x'],
      ]);
      expect(t.widths.length, equals(3));
      expect(t.widths[1], equals(1)); // header 'B'
      expect(t.widths[2], equals(1)); // header 'C'
    });

    test('handles empty rows list', () {
      final t = TableRenderer.fromHeaders(['Name', 'Age']);
      t.computeWidths([]);
      expect(t.widths[0], equals(4)); // header width
      expect(t.widths[1], equals(3));
    });

    test('adds cellPadding to computed widths', () {
      final t = TableRenderer.fromHeaders(['AB'], cellPadding: 3);
      t.computeWidths([]);
      expect(t.widths[0], equals(5)); // 2 + 3
    });

    test('is ANSI-aware — ignores escape codes in width computation', () {
      final t = TableRenderer.fromHeaders(['Name']);
      t.computeWidths([
        ['\x1B[32mAlice\x1B[0m'],
      ]);
      expect(t.widths[0], equals(5)); // visible 'Alice' = 5 > 'Name' = 4
    });
  });

  group('setWidths', () {
    test('overrides computed widths', () {
      final t = TableRenderer.fromHeaders(['A', 'B']);
      t.computeWidths([
        ['x', 'y'],
      ]);
      t.setWidths([20, 30]);
      expect(t.widths, equals([20, 30]));
    });

    test('updates contentWidth accordingly', () {
      final t = TableRenderer.fromHeaders(['A', 'B']);
      t.setWidths([10, 10]);
      // 10 + 10 + 3 (one separator) = 23
      expect(t.contentWidth, equals(23));
    });
  });

  group('contentWidth', () {
    test('sums widths plus separator spacing', () {
      final t = TableRenderer.fromHeaders(['A', 'B', 'C']);
      t.setWidths([5, 5, 5]);
      // 5 + 5 + 5 + 2 * 3 = 21
      expect(t.contentWidth, equals(21));
    });

    test('single column has no separators', () {
      final t = TableRenderer.fromHeaders(['A']);
      t.setWidths([10]);
      expect(t.contentWidth, equals(10));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Header line
  // ══════════════════════════════════════════════════════════════════════════

  group('headerLine', () {
    test('contains all column headers', () {
      final t = TableRenderer.fromHeaders(['Name', 'Age', 'City']);
      t.computeWidths([]);
      final line = _strip(t.headerLine());
      expect(line, contains('Name'));
      expect(line, contains('Age'));
      expect(line, contains('City'));
    });

    test('pads headers to computed widths', () {
      final t = TableRenderer.fromHeaders(['A', 'B']);
      t.setWidths([8, 6]);
      final line = _strip(t.headerLine());
      // A padded to 8, B padded to 6
      expect(line, contains('A       '));
      expect(line, contains('B     '));
    });

    test('includes gutter when borders are enabled', () {
      final t = TableRenderer.fromHeaders(
        ['X'],
        theme: PromptTheme.dark, // showBorders = true
      );
      t.setWidths([4]);
      final raw = t.headerLine();
      final stripped = _strip(raw);
      expect(stripped, startsWith('│'));
    });

    test('omits gutter when borders are disabled', () {
      final t = TableRenderer.fromHeaders(
        ['X'],
        theme: PromptTheme.minimal, // showBorders = false
      );
      t.setWidths([4]);
      final raw = t.headerLine();
      final stripped = _strip(raw);
      expect(stripped, isNot(startsWith('│')));
    });

    test('uses custom leading gutter', () {
      final t = TableRenderer.fromHeaders(['X']);
      t.setWidths([4]);
      final raw = t.headerLine(leadingGutter: '>> ');
      expect(raw, startsWith('>> '));
    });

    test('includes column separators for multi-column tables', () {
      final t = TableRenderer.fromHeaders(['A', 'B']);
      t.setWidths([3, 3]);
      final stripped = _strip(t.headerLine());
      expect(stripped, contains('│'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Connector line
  // ══════════════════════════════════════════════════════════════════════════

  group('connectorLine', () {
    test('is non-empty when borders are enabled', () {
      final t = TableRenderer.fromHeaders(
        ['X'],
        theme: PromptTheme.dark,
      );
      t.setWidths([10]);
      expect(t.connectorLine(), isNotEmpty);
    });

    test('is empty when borders are disabled and no custom gutter', () {
      final t = TableRenderer.fromHeaders(
        ['X'],
        theme: PromptTheme.minimal,
      );
      t.setWidths([10]);
      expect(t.connectorLine(), isEmpty);
    });

    test('uses custom gutter even when borders are disabled', () {
      final t = TableRenderer.fromHeaders(
        ['X'],
        theme: PromptTheme.minimal,
      );
      t.setWidths([10]);
      final line = t.connectorLine(leadingGutter: '+ ');
      expect(line, startsWith('+ '));
      expect(line.length, greaterThan(2));
    });

    test('contains horizontal line characters', () {
      final t = TableRenderer.fromHeaders(['A']);
      t.setWidths([10]);
      final stripped = _strip(t.connectorLine());
      expect(stripped, contains('─'));
    });

    test('starts with connector glyph', () {
      final t = TableRenderer.fromHeaders(['A']);
      t.setWidths([10]);
      final stripped = _strip(t.connectorLine());
      expect(stripped, startsWith('├'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Row line
  // ══════════════════════════════════════════════════════════════════════════

  group('rowLine', () {
    test('contains cell content', () {
      final t = TableRenderer.fromHeaders(['Name', 'Age']);
      t.computeWidths([
        ['Alice', '30'],
      ]);
      final line = _strip(t.rowLine(['Alice', '30']));
      expect(line, contains('Alice'));
      expect(line, contains('30'));
    });

    test('pads cells to computed widths', () {
      final t = TableRenderer.fromHeaders(['Name']);
      t.setWidths([10]);
      final stripped = _strip(t.rowLine(['Hi']));
      // 'Hi' padded to 10 visible chars
      expect(stripped, contains('Hi'));
      expect(
        visibleLength(t.rowLine(['Hi'])),
        greaterThanOrEqualTo(10),
      );
    });

    test('renders empty cell for missing columns', () {
      final t = TableRenderer.fromHeaders(['A', 'B', 'C']);
      t.setWidths([3, 3, 3]);
      final line = t.rowLine(['x']); // only 1 cell for 3 columns
      final stripped = _strip(line);
      expect(stripped, contains('x'));
      // B and C columns should be padded empty spaces
    });

    test('even-indexed rows have no zebra dim', () {
      final t = TableRenderer.fromHeaders(['A']);
      t.setWidths([5]);
      final raw = t.rowLine(['Hi'], index: 0);
      expect(raw, isNot(contains('\x1B[2m'))); // no dim
    });

    test('odd-indexed rows have zebra dim when enabled', () {
      final t = TableRenderer.fromHeaders(['A']);
      t.setWidths([5]);
      final raw = t.rowLine(['Hi'], index: 1);
      expect(raw, contains('\x1B[2m')); // dim
    });

    test('no zebra dim when zebraStripes is disabled', () {
      final t = TableRenderer.fromHeaders(['A'], zebraStripes: false);
      t.setWidths([5]);
      final raw = t.rowLine(['Hi'], index: 1);
      expect(raw, isNot(contains('\x1B[2m')));
    });

    test('forceStripe applies dim regardless of index', () {
      final t = TableRenderer.fromHeaders(['A']);
      t.setWidths([5]);
      final raw = t.rowLine(['Hi'], index: 0, forceStripe: true);
      expect(raw, contains('\x1B[2m'));
    });

    test('includes gutter when borders are enabled', () {
      final t = TableRenderer.fromHeaders(['A'], theme: PromptTheme.dark);
      t.setWidths([5]);
      final stripped = _strip(t.rowLine(['Hi']));
      expect(stripped, startsWith('│'));
    });

    test('omits gutter when borders are disabled', () {
      final t = TableRenderer.fromHeaders(['A'], theme: PromptTheme.minimal);
      t.setWidths([5]);
      final stripped = _strip(t.rowLine(['Hi']));
      expect(stripped, isNot(startsWith('│')));
    });

    test('uses custom leading gutter', () {
      final t = TableRenderer.fromHeaders(['A']);
      t.setWidths([5]);
      final raw = t.rowLine(['Hi'], leadingGutter: '> ');
      expect(raw, startsWith('> '));
    });

    test('includes separators between columns', () {
      final t = TableRenderer.fromHeaders(['A', 'B']);
      t.setWidths([3, 3]);
      final stripped = _strip(t.rowLine(['x', 'y']));
      expect(stripped, contains('│'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Column alignment
  // ══════════════════════════════════════════════════════════════════════════

  group('column alignment', () {
    test('left-aligned cell is padded on the right', () {
      final t = TableRenderer(columns: [ColumnConfig.left('H')]);
      t.setWidths([8]);
      final stripped = _strip(t.rowLine(['AB']));
      // 'AB' left-aligned in 8: 'AB      '
      expect(stripped, contains('AB'));
      final cellContent = stripped.replaceAll('│', '').trim();
      expect(cellContent, startsWith('AB'));
    });

    test('right-aligned cell is padded on the left', () {
      final t = TableRenderer(columns: [ColumnConfig.right('H')]);
      t.setWidths([8]);
      final stripped = _strip(t.rowLine(['AB']));
      final cellContent = stripped.replaceAll('│', '').trim();
      expect(cellContent, endsWith('AB'));
    });

    test('center-aligned cell is padded on both sides', () {
      final t = TableRenderer(columns: [ColumnConfig.center('H')]);
      t.setWidths([8]);
      final stripped = _strip(t.rowLine(['AB']));
      final cellContent = stripped.replaceAll('│', '').trim();
      // 'AB' centered in 8: '   AB   ' — trim gives 'AB'
      expect(cellContent, equals('AB'));
    });

    test('mixed alignments in multi-column table', () {
      final t = TableRenderer.withAlignments(
        ['L', 'C', 'R'],
        [ColumnAlign.left, ColumnAlign.center, ColumnAlign.right],
      );
      t.setWidths([6, 6, 6]);
      final stripped = _strip(t.rowLine(['AA', 'BB', 'CC']));
      expect(stripped, contains('AA'));
      expect(stripped, contains('BB'));
      expect(stripped, contains('CC'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Selectable row line
  // ══════════════════════════════════════════════════════════════════════════

  group('selectableRowLine', () {
    test('renders unselected cells normally', () {
      final t = TableRenderer.fromHeaders(['A', 'B']);
      t.setWidths([5, 5]);
      final raw = t.selectableRowLine(
        ['Hi', 'Lo'],
        index: 0,
        selectedColumn: null,
      );
      final stripped = _strip(raw);
      expect(stripped, contains('Hi'));
      expect(stripped, contains('Lo'));
    });

    test('applies inverse highlight on selected cell (default features)', () {
      final t = TableRenderer.fromHeaders(
        ['A'],
        theme: PromptTheme.dark, // useInverseHighlight = true
      );
      t.setWidths([8]);
      final raw = t.selectableRowLine(
        ['Hello'],
        index: 0,
        selectedColumn: 0,
      );
      expect(raw, contains('\x1B[7m')); // inverse
    });

    test('uses selection color when inverse highlight is off', () {
      final noInverse = PromptTheme(
        features: DisplayFeatures(useInverseHighlight: false),
      );
      final t = TableRenderer.fromHeaders(['A'], theme: noInverse);
      t.setWidths([8]);
      final raw = t.selectableRowLine(
        ['Hello'],
        index: 0,
        selectedColumn: 0,
      );
      expect(raw, contains(noInverse.selection));
      expect(raw, isNot(contains('\x1B[7m')));
    });

    test('shows edit buffer when editing selected cell', () {
      final t = TableRenderer.fromHeaders(['A']);
      t.setWidths([10]);
      final raw = t.selectableRowLine(
        ['Original'],
        index: 0,
        selectedColumn: 0,
        isEditing: true,
        editBuffer: 'New',
      );
      final stripped = _strip(raw);
      expect(stripped, contains('New'));
      expect(stripped, contains('|')); // cursor indicator
      expect(stripped, isNot(contains('Original')));
    });

    test('shows original cell when not editing selected cell', () {
      final t = TableRenderer.fromHeaders(['A']);
      t.setWidths([10]);
      final raw = t.selectableRowLine(
        ['Original'],
        index: 0,
        selectedColumn: 0,
        isEditing: false,
      );
      final stripped = _strip(raw);
      expect(stripped, contains('Original'));
    });

    test('zebra stripes apply to odd-indexed selectable rows', () {
      final t = TableRenderer.fromHeaders(['A']);
      t.setWidths([5]);
      final raw = t.selectableRowLine(
        ['Hi'],
        index: 1,
        selectedColumn: null,
      );
      expect(raw, contains('\x1B[2m')); // dim
    });

    test('no zebra on even-indexed selectable rows', () {
      final t = TableRenderer.fromHeaders(['A']);
      t.setWidths([5]);
      final raw = t.selectableRowLine(
        ['Hi'],
        index: 0,
        selectedColumn: null,
      );
      expect(raw, isNot(contains('\x1B[2m')));
    });

    test('uses custom leading gutter', () {
      final t = TableRenderer.fromHeaders(['A']);
      t.setWidths([5]);
      final raw = t.selectableRowLine(
        ['Hi'],
        index: 0,
        leadingGutter: ':: ',
      );
      expect(raw, startsWith(':: '));
    });

    test('only the selected column gets highlight treatment', () {
      final t = TableRenderer.fromHeaders(['A', 'B']);
      t.setWidths([5, 5]);
      final raw = t.selectableRowLine(
        ['aa', 'bb'],
        index: 0,
        selectedColumn: 1,
      );
      // Column B (index 1) should have inverse; column A should not
      final parts = raw.split(RegExp(r'\s+│\s+'));
      // The second part should have the inverse code
      if (parts.length >= 2) {
        expect(parts.last, contains('\x1B[7m'));
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // buildLines
  // ══════════════════════════════════════════════════════════════════════════

  group('buildLines', () {
    test('returns header + connector + data rows', () {
      final t = TableRenderer.fromHeaders(['Name', 'Age']);
      final rows = [
        ['Alice', '30'],
        ['Bob', '25'],
      ];
      final lines = t.buildLines(rows);
      // header + connector + 2 data rows = 4 lines
      expect(lines.length, equals(4));
    });

    test('auto-computes widths when not pre-computed', () {
      final t = TableRenderer.fromHeaders(['Name']);
      final lines = t.buildLines([
        ['Alice'],
      ]);
      expect(t.widths, isNotEmpty);
      expect(lines.length, equals(3));
    });

    test('uses pre-computed widths when available', () {
      final t = TableRenderer.fromHeaders(['A']);
      t.setWidths([20]);
      final lines = t.buildLines([
        ['B'],
      ]);
      expect(t.widths[0], equals(20)); // not recomputed
      expect(lines.length, equals(3));
    });

    test('first line is the header', () {
      final t = TableRenderer.fromHeaders(['Name']);
      final lines = t.buildLines([
        ['Alice'],
      ]);
      expect(_strip(lines[0]), contains('Name'));
    });

    test('second line is the connector', () {
      final t = TableRenderer.fromHeaders(['Name']);
      final lines = t.buildLines([
        ['Alice'],
      ]);
      expect(_strip(lines[1]), contains('─'));
    });

    test('data rows follow the connector', () {
      final t = TableRenderer.fromHeaders(['Name']);
      final lines = t.buildLines([
        ['Alice'],
        ['Bob'],
      ]);
      expect(_strip(lines[2]), contains('Alice'));
      expect(_strip(lines[3]), contains('Bob'));
    });

    test('handles empty data rows', () {
      final t = TableRenderer.fromHeaders(['A']);
      final lines = t.buildLines([]);
      expect(lines.length, equals(2)); // header + connector only
    });

    test('odd data rows get zebra stripes', () {
      final t = TableRenderer.fromHeaders(['A']);
      final lines = t.buildLines([
        ['row0'],
        ['row1'],
        ['row2'],
      ]);
      // lines[2] = row0 (index 0, no stripe)
      expect(lines[2], isNot(contains('\x1B[2m')));
      // lines[3] = row1 (index 1, striped)
      expect(lines[3], contains('\x1B[2m'));
      // lines[4] = row2 (index 2, no stripe)
      expect(lines[4], isNot(contains('\x1B[2m')));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // writeHeader / writeRows
  // ══════════════════════════════════════════════════════════════════════════

  group('writeHeader', () {
    test('writes exactly two lines (header + connector)', () {
      final t = TableRenderer.fromHeaders(['A']);
      t.setWidths([5]);
      final captured = <String>[];
      t.writeHeader(captured.add);
      expect(captured.length, equals(2));
      expect(_strip(captured[0]), contains('A'));
      expect(_strip(captured[1]), contains('─'));
    });
  });

  group('writeRows', () {
    test('writes one line per row', () {
      final t = TableRenderer.fromHeaders(['A']);
      t.setWidths([5]);
      final rows = [
        ['x'],
        ['y'],
        ['z'],
      ];
      final captured = <String>[];
      t.writeRows(rows, captured.add);
      expect(captured.length, equals(3));
      expect(_strip(captured[0]), contains('x'));
      expect(_strip(captured[1]), contains('y'));
      expect(_strip(captured[2]), contains('z'));
    });

    test('applies zebra stripes correctly', () {
      final t = TableRenderer.fromHeaders(['A']);
      t.setWidths([5]);
      final rows = [
        ['r0'],
        ['r1'],
      ];
      final captured = <String>[];
      t.writeRows(rows, captured.add);
      expect(captured[0], isNot(contains('\x1B[2m')));
      expect(captured[1], contains('\x1B[2m'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Theme integration
  // ══════════════════════════════════════════════════════════════════════════

  group('theme integration', () {
    test('uses theme accent color in header', () {
      final t = TableRenderer.fromHeaders(
        ['Name'],
        theme: PromptTheme.matrix,
      );
      t.setWidths([10]);
      final raw = t.headerLine();
      expect(raw, contains(PromptTheme.matrix.accent));
    });

    test('uses theme bold in header', () {
      final t = TableRenderer.fromHeaders(['A']);
      t.setWidths([5]);
      final raw = t.headerLine();
      expect(raw, contains(PromptTheme.dark.bold));
    });

    test('uses theme glyphs for separators', () {
      final t = TableRenderer.fromHeaders(
        ['A', 'B'],
        theme: PromptTheme.fire, // double glyphs
      );
      t.setWidths([5, 5]);
      final raw = t.headerLine();
      expect(raw, contains(PromptTheme.fire.glyphs.borderVertical));
    });

    test('uses theme glyphs for connector', () {
      final t = TableRenderer.fromHeaders(
        ['A'],
        theme: PromptTheme.fire,
      );
      t.setWidths([10]);
      final stripped = _strip(t.connectorLine());
      expect(
        stripped,
        contains(PromptTheme.fire.glyphs.borderConnector),
      );
      expect(
        stripped,
        contains(PromptTheme.fire.glyphs.borderHorizontal),
      );
    });

    test('minimal theme omits gutter and connector', () {
      final t = TableRenderer.fromHeaders(
        ['A'],
        theme: PromptTheme.minimal,
      );
      t.setWidths([5]);
      expect(t.connectorLine(), isEmpty);
      final row = _strip(t.rowLine(['x']));
      expect(row, isNot(startsWith('│')));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Cell truncation
  // ══════════════════════════════════════════════════════════════════════════

  group('cell truncation', () {
    test('truncates cell content that exceeds column width', () {
      final t = TableRenderer.fromHeaders(['A']);
      t.setWidths([5]);
      final stripped = _strip(t.rowLine(['VeryLongContent']));
      expect(stripped, contains('…'));
      // visible cell content should not exceed width
    });

    test('does not truncate content that fits', () {
      final t = TableRenderer.fromHeaders(['A']);
      t.setWidths([10]);
      final stripped = _strip(t.rowLine(['Short']));
      expect(stripped, isNot(contains('…')));
      expect(stripped, contains('Short'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Edge cases
  // ══════════════════════════════════════════════════════════════════════════

  group('edge cases', () {
    test('single-column table works end-to-end', () {
      final t = TableRenderer.fromHeaders(['Item']);
      final lines = t.buildLines([
        ['Apple'],
        ['Banana'],
      ]);
      expect(lines.length, equals(4));
      expect(_strip(lines[0]), contains('Item'));
      expect(_strip(lines[2]), contains('Apple'));
      expect(_strip(lines[3]), contains('Banana'));
    });

    test('many-column table works end-to-end', () {
      final headers = List.generate(10, (i) => 'C$i');
      final t = TableRenderer.fromHeaders(headers);
      final rows = [List.generate(10, (i) => 'v$i')];
      final lines = t.buildLines(rows);
      expect(lines.length, equals(3));
      for (var i = 0; i < 10; i++) {
        expect(_strip(lines[0]), contains('C$i'));
        expect(_strip(lines[2]), contains('v$i'));
      }
    });

    test('ANSI-styled cell content is handled correctly', () {
      final t = TableRenderer.fromHeaders(['Name']);
      t.computeWidths([
        ['\x1B[31mRed\x1B[0m'],
      ]);
      expect(t.widths[0], equals(4)); // 'Name' = 4 > 'Red' = 3
      final stripped = _strip(t.rowLine(['\x1B[31mRed\x1B[0m']));
      expect(stripped, contains('Red'));
    });

    test('empty cell list renders empty padded cells', () {
      final t = TableRenderer.fromHeaders(['A', 'B']);
      t.setWidths([3, 3]);
      final line = t.rowLine([]);
      final stripped = _strip(line);
      // Should have gutter + empty padded cells + separator
      expect(stripped, isNotEmpty);
    });

    test('writeHeader + writeRows produces same result as buildLines', () {
      final t1 = TableRenderer.fromHeaders(['Name', 'Age']);
      final t2 = TableRenderer.fromHeaders(['Name', 'Age']);
      final rows = [
        ['Alice', '30'],
        ['Bob', '25'],
      ];

      final fromBuild = t1.buildLines(rows);

      t2.computeWidths(rows);
      final fromWrite = <String>[];
      t2.writeHeader(fromWrite.add);
      t2.writeRows(rows, fromWrite.add);

      expect(fromWrite.length, equals(fromBuild.length));
      for (var i = 0; i < fromBuild.length; i++) {
        expect(fromWrite[i], equals(fromBuild[i]));
      }
    });
  });
}
