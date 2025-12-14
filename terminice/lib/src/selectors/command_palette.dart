import 'package:terminice/terminice.dart';

import 'package:terminice_core/terminice_core.dart';

/// A VS Code-style command palette with fuzzy ranking and theming.
///
/// Controls:
/// - Type to search across command titles and subtitles
/// - ↑ / ↓ navigate the ranked list
/// - Enter confirms the focused command
/// - Backspace edits the query
/// - Esc cancels (returns `null`)
/// - Ctrl+R toggles fuzzy vs substring ranking
///
/// Parameters:
/// - `commands`: Entries exposed to the palette.
/// - `label`: Frame heading shown above the input.
/// - `maxVisible`: Maximum list height before scrolling.
///
/// Returns the confirmed `CommandEntry`, or `null` if cancelled.
///
/// Example:
/// ```dart
/// final command = terminice.commandPalette(
///   label: 'Command Palette',
///   commands: [
///     CommandEntry(id: 'open', title: 'Open Project', subtitle: '⌘O'),
///     CommandEntry(id: 'deploy', title: 'Deploy', subtitle: 'Prod slot'),
///   ],
/// );
/// ```
extension CommandPaletteExtensions on Terminice {
  /// Opens a command palette and returns the selected `CommandEntry`.
  ///
  /// See the file-level docs for interaction details and arguments.
  CommandEntry? commandPalette({
    required List<CommandEntry> commands,
    required String label,
    int maxVisible = 12,
  }) {
    if (commands.isEmpty) return null;
    final theme = defaultTheme;

    final prompt = RankedListPrompt<CommandEntry>(
      title: label,
      items: commands,
      theme: theme,
      maxVisible: maxVisible,
    );

    return prompt.run(
      // Custom ranking that checks both title and subtitle
      rankItem: (entry, query, useFuzzy) {
        if (query.isEmpty) return const RankResult(0, []);

        // Try title first
        final titleMatch = useFuzzy
            ? fuzzyMatch(entry.title, query)
            : substringMatch(entry.title, query);

        if (titleMatch != null) return titleMatch;

        // Fall back to subtitle
        if (entry.subtitle != null) {
          final subMatch = useFuzzy
              ? fuzzyMatch(entry.subtitle!, query)
              : substringMatch(entry.subtitle!, query);

          if (subMatch != null) {
            // Return with reduced score and empty spans (subtitle match)
            return RankResult(subMatch.score ~/ 2, const []);
          }
        }

        return null;
      },
      itemLabel: (entry) => entry.title,
      itemSubtitle: (entry) => entry.subtitle,

      // Custom rendering with subtitle and span highlighting
      renderItem: (ctx, rankedItem, index, isFocused, query) {
        final cols = TerminalInfo.columns;
        final arrow = ctx.lb.arrow(isFocused);

        // Highlight matched spans in title
        final highlightedTitle = highlightSpans(
          rankedItem.item.title,
          rankedItem.spans,
          theme,
        );

        // Add truncated subtitle if present
        final subtitle = rankedItem.item.subtitle;
        final subtitlePart = subtitle == null
            ? ''
            : '  ${theme.dim}${truncate(subtitle, cols ~/ 2)}${theme.reset}';

        ctx.highlightedLine(
          '$arrow $highlightedTitle$subtitlePart',
          highlighted: isFocused,
        );
      },

      // Custom header showing mode and match count
      beforeItems: (ctx, query, useFuzzy, matchCount) {
        ctx.headerLine('Command', query);
        ctx.writeConnector();
        final mode = useFuzzy ? 'Fuzzy' : 'Substring';
        ctx.infoLine([mode, 'Matches: $matchCount']);
      },
    );
  }
}

/// Represents a command exposed through the palette.
///
/// Provide a stable `id`, a human-friendly `title`, and an optional
/// `subtitle` (displayed dimmed to the right of the title).
class CommandEntry {
  final String id;
  final String title;
  final String? subtitle;

  const CommandEntry({required this.id, required this.title, this.subtitle});
}
