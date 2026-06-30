import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('SmartShopper MCP Server integration test - list tools', () async {
    // Spawn the server process
    final process = await Process.start(
      'dart',
      ['run', 'bin/server.dart'],
      workingDirectory: Directory.current.path,
    );

    final completer = Completer<List<dynamic>>();
    final stderrList = <String>[];
    final stdoutList = <String>[];

    // Collect stderr for diagnostics
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(stderrList.add);

    // Listen to stdout to drive the protocol sequence
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      stdoutList.add(line);
      if (line.trim().startsWith('{')) {
        try {
          final response = jsonDecode(line) as Map<String, dynamic>;
          if (response['id'] == 1) {
            // Received initialize response!
            // Send the 'notifications/initialized' notification
            final initializedNotification = {
              'jsonrpc': '2.0',
              'method': 'notifications/initialized',
            };
            process.stdin.writeln(jsonEncode(initializedNotification));
            
            // Send the 'tools/list' request
            final listRequest = {
              'jsonrpc': '2.0',
              'id': 2,
              'method': 'tools/list',
              'params': {},
            };
            process.stdin.writeln(jsonEncode(listRequest));
          } else if (response['id'] == 2) {
            if (response.containsKey('result')) {
              final result = response['result'] as Map<String, dynamic>;
              completer.complete(result['tools'] as List<dynamic>);
            } else {
              completer.completeError(response['error'] ?? 'Unknown error');
            }
          }
        } catch (_) {
          // Ignore json parsing issues on partial or non-json lines
        }
      }
    });

    // Send the first 'initialize' request
    final initializeRequest = {
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'initialize',
      'params': {
        'protocolVersion': '2024-11-05',
        'capabilities': {},
        'clientInfo': {
          'name': 'test-client',
          'version': '1.0.0',
        },
      },
    };

    process.stdin.writeln(jsonEncode(initializeRequest));

    try {
      final tools = await completer.future.timeout(const Duration(seconds: 5));
      final toolNames = tools.map((t) => t['name'] as String).toList();
      
      expect(toolNames, contains('get_project_summary'));
      expect(toolNames, contains('analyze_code'));
      expect(toolNames, contains('run_tests'));
      expect(toolNames, contains('format_code'));
    } catch (e) {
      print('--- Server Stderr Logs ---');
      print(stderrList.join('\n'));
      print('--- Server Stdout Logs ---');
      print(stdoutList.join('\n'));
      fail('Failed during MCP handshake or tool verification: $e');
    } finally {
      process.stdin.close();
      process.kill();
    }
  });
}
