import 'dart:io';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:path/path.dart' as p;

void main() async {
  // Output diagnostic messages to stderr so we do not disrupt JSON-RPC communication on stdout.
  stderr.writeln('Starting SmartShopper MCP Server...');

  final server = McpServer(
    const Implementation(
      name: 'smartshopper-mcp-server',
      version: '1.0.0',
    ),
    options: const McpServerOptions(
      capabilities: ServerCapabilities(
        tools: ServerCapabilitiesTools(),
      ),
    ),
  );

  // Determine the root directory of the Flutter project.
  // The server is typically run from within the smartshopper_mobile/mcp_server directory
  // or the workspace root.
  final serverDir = Directory.current.path;
  final rootDir = p.basename(serverDir) == 'mcp_server'
      ? p.dirname(serverDir)
      : serverDir;

  stderr.writeln('Project Root Directory: $rootDir');

  // Tool 1: Get Project Summary
  server.registerTool(
    'get_project_summary',
    description: 'Provides a quick summary of the project architecture and content file counts.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async {
      try {
        final libDir = Directory(p.join(rootDir, 'lib'));
        if (!libDir.existsSync()) {
          return CallToolResult(
            isError: true,
            content: [TextContent(text: 'Error: lib/ directory not found in $rootDir')],
          );
        }

        final files = libDir.listSync(recursive: true);
        int dartFilesCount = 0;
        final categories = <String, int>{};

        for (var entity in files) {
          if (entity is File && entity.path.endsWith('.dart')) {
            dartFilesCount++;
            final relativePath = p.relative(entity.path, from: libDir.path);
            final parts = p.split(relativePath);
            if (parts.isNotEmpty) {
              final category = parts[0];
              categories[category] = (categories[category] ?? 0) + 1;
            }
          }
        }

        final buffer = StringBuffer()
          ..writeln('### SmartShopper Mobile Project Summary')
          ..writeln('- **Project Root**: $rootDir')
          ..writeln('- **Total Dart files under lib/**: $dartFilesCount')
          ..writeln('\n**Directory structure counts:**');

        categories.forEach((cat, count) {
          buffer.writeln('- `lib/$cat/`: $count Dart files');
        });

        return CallToolResult(
          content: [TextContent(text: buffer.toString())],
        );
      } catch (e) {
        return CallToolResult(
          isError: true,
          content: [TextContent(text: 'Error generating summary: $e')],
        );
      }
    },
  );

  // Tool 2: Analyze Code
  server.registerTool(
    'analyze_code',
    description: 'Runs `flutter analyze` in the project root to check for compiler errors or lint warnings.',
    inputSchema: JsonSchema.object(properties: {}),
    callback: (args, extra) async {
      stderr.writeln('Running flutter analyze...');
      try {
        final result = await Process.run(
          'flutter',
          ['analyze'],
          workingDirectory: rootDir,
          runInShell: true,
        );
        final output = result.stdout.toString() + result.stderr.toString();
        return CallToolResult(
          isError: result.exitCode != 0,
          content: [TextContent(text: output)],
        );
      } catch (e) {
        return CallToolResult(
          isError: true,
          content: [TextContent(text: 'Failed to run flutter analyze: $e')],
        );
      }
    },
  );

  // Tool 3: Run Tests
  server.registerTool(
    'run_tests',
    description: 'Runs `flutter test` for all unit/widget tests in the project.',
    inputSchema: JsonSchema.object(
      properties: {
        'target': JsonSchema.string(
          description: 'Optional specific test file path (e.g. test/widget_test.dart)',
        ),
      },
    ),
    callback: (args, extra) async {
      final target = args['target'] as String?;
      final testArgs = ['test'];
      if (target != null) {
        testArgs.add(target);
      }
      stderr.writeln('Running flutter ${testArgs.join(' ')}...');
      try {
        final result = await Process.run(
          'flutter',
          testArgs,
          workingDirectory: rootDir,
          runInShell: true,
        );
        final output = result.stdout.toString() + result.stderr.toString();
        return CallToolResult(
          isError: result.exitCode != 0,
          content: [TextContent(text: output)],
        );
      } catch (e) {
        return CallToolResult(
          isError: true,
          content: [TextContent(text: 'Failed to run flutter test: $e')],
        );
      }
    },
  );

  // Tool 4: Format Code
  server.registerTool(
    'format_code',
    description: 'Formats Dart source code files using `dart format`.',
    inputSchema: JsonSchema.object(
      properties: {
        'path': JsonSchema.string(
          description: 'File or directory path to format relative to project root (e.g., lib/main.dart or lib/).',
        ),
      },
      required: ['path'],
    ),
    callback: (args, extra) async {
      final targetPath = args['path'] as String;
      final fullPath = p.join(rootDir, targetPath);

      stderr.writeln('Running dart format on $fullPath...');
      try {
        final result = await Process.run(
          'dart',
          ['format', fullPath],
          runInShell: true,
        );
        final output = result.stdout.toString() + result.stderr.toString();
        return CallToolResult(
          isError: result.exitCode != 0,
          content: [TextContent(text: output)],
        );
      } catch (e) {
        return CallToolResult(
          isError: true,
          content: [TextContent(text: 'Failed to run dart format: $e')],
        );
      }
    },
  );

  final transport = StdioServerTransport();
  await server.connect(transport);
  stderr.writeln('SmartShopper MCP Server is connected and running.');
}
