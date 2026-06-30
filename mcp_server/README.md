# SmartShopper MCP Server

A custom Model Context Protocol (MCP) server that exposes Dart and Flutter SDK capabilities for the SmartShopper Mobile project.

This server enables AI clients (like Claude Desktop, Cursor, Roo Code, etc.) to:
1. Get a summary of the project architecture (`get_project_summary`)
2. Run code analysis (`analyze_code`)
3. Format Dart code files (`format_code`)
4. Run project unit/widget tests (`run_tests`)

---

## Prerequisites

- **Dart SDK**: `^3.7.2` (Make sure `dart` is in your system PATH)
- **Flutter SDK**: `^3.7.2` (Make sure `flutter` is in your system PATH)

---

## Getting Started

1. **Install Dependencies**:
   Open a terminal in the `mcp_server` directory and run:
   ```bash
   dart pub get
   ```

2. **Test Locally**:
   Run the server locally to ensure it builds and runs:
   ```bash
   dart run bin/server.dart
   ```
   *Note: Since MCP servers use stdout for protocol communication, diagnostic messages are sent to `stderr`. The server will wait for input on standard input.*

---

## Client Integration Configurations

### 1. Claude Desktop
Add the following configuration to your `claude_desktop_config.json` (located at `%APPDATA%\Claude\claude_desktop_config.json` on Windows or `~/Library/Application Support/Claude/claude_desktop_config.json` on macOS):

```json
{
  "mcpServers": {
    "smartshopper-mcp": {
      "command": "dart",
      "args": [
        "run",
        "bin/server.dart"
      ],
      "cwd": "C:\\Users\\HP VICTUS\\AndroidStudioProjects\\smartshopper_mobile\\mcp_server"
    }
  }
}
```
*Note: Make sure to adjust the `cwd` (current working directory) if the project path is different on your machine.*

### 2. Cursor / Windsurf
In Cursor settings:
1. Go to **Settings** > **Features** > **MCP**.
2. Click **+ Add New MCP Server**.
3. Configure as:
   - **Name**: `smartshopper-mcp`
   - **Type**: `stdio`
   - **Command**: `dart run bin/server.dart`
4. Set the environment working directory to the absolute path of the `mcp_server` folder.
