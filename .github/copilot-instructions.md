# SMTextReplace Plugin - Copilot Development Instructions

## Repository Overview

This repository contains **SMTextReplace**, a SourceMod plugin that enhances the default "[SM]" prefix in SourceMod messages by replacing it with customizable colored text. The plugin provides administrators with the ability to define custom color schemes and optionally randomize colors for a more visually appealing server experience.

### Core Functionality
- **Text Replacement**: Intercepts SourceMod "[SM]" messages and replaces them with custom colored text
- **Color Customization**: Reads color definitions from a configuration file (`sm_textcolors.cfg`)
- **Random Colors**: Optional random color selection from the defined color palette
- **Live Reloading**: Admin commands to reload configuration without server restart
- **Cross-Platform**: Supports both legacy and Protobuf message formats

## Technical Environment

### Language & Platform
- **Language**: SourcePawn (.sp files)
- **Platform**: SourceMod 1.11+ (defined in sourceknight.yaml)
- **Compiler**: SourceMod compiler (spcomp) via SourceKnight
- **Target**: Source Engine game servers

### Dependencies
- **SourceMod**: Core framework (v1.11.0-git6917+)
- **MultiColors**: Color formatting library (from srcdslab/sm-plugin-MultiColors)

### Build System
- **Primary**: SourceKnight build system (configured in `sourceknight.yaml`)
- **CI/CD**: GitHub Actions (`.github/workflows/ci.yml`)
- **Package Output**: Compiled plugins go to `/addons/sourcemod/plugins`

## Project Structure

```
├── addons/sourcemod/
│   ├── scripting/
│   │   └── SMTextReplace.sp          # Main plugin source code
│   └── configs/
│       └── sm_textcolors.cfg         # Color configuration file
├── .github/
│   └── workflows/ci.yml              # Build and release automation
├── sourceknight.yaml                # Build configuration
└── .gitignore                       # Version control exclusions
```

## Code Style & Standards

### SourcePawn Conventions (CRITICAL)
```sourcepawn
#pragma semicolon 1                   // REQUIRED: Enforce semicolons
#pragma newdecls required             // REQUIRED: Modern variable declarations

// Variable naming patterns
Handle g_Cvar_Randomcolor;            // Global handles (legacy pattern in this codebase)
int UseRandomColors;                  // Global variables without prefix (existing pattern)
char TextColors[MAXTEXTCOLORS][256];  // Arrays with descriptive names

// Function naming
public void OnPluginStart()           // Standard SourceMod callbacks
public Action Command_ReloadConfig()  // Command handlers with "Command_" prefix
stock void RefreshConfig()            // Helper functions with descriptive names
```

### Project-Specific Patterns
- **Constants**: Use `#define` for maximum values (e.g., `#define MAXTEXTCOLORS 100`)
- **String Operations**: Use `Format()`, `ReplaceString()`, `TrimString()` for text manipulation
- **File I/O**: Use `BuildPath(Path_SM, ...)` for config file paths
- **Color Formatting**: Use MultiColors library functions (`CFormatColor`, `CAddWhiteSpace`)

### Legacy Code Patterns (Current State)
⚠️ **Note**: This codebase uses some older SourceMod patterns that should be maintained for consistency:
- `Handle` variables instead of newer `ConVar` methodmaps
- `GetConVarInt()` instead of `.IntValue` property
- `CloseHandle()` instead of `delete` operator

## Development Guidelines

### Making Changes Safely

1. **Understand Message Hooking**: The core functionality relies on hooking `TextMsg` user messages
   ```sourcepawn
   HookUserMessage(GetUserMessageId("TextMsg"), TextMsg, true);
   ```

2. **Handle Both Message Formats**: Always support both Protobuf and legacy formats
   ```sourcepawn
   if (GetUserMessageType() == UM_Protobuf) {
       // Protobuf handling
   } else {
       // Legacy bitbuffer handling
   }
   ```

3. **Config File Format**: Colors use special syntax in `sm_textcolors.cfg`
   - `*` represents `\x08` (team color)
   - `&` represents `\x07` (color code)
   - Example: `{default}[{green}SM{default}]{default}`

4. **Timer Usage**: Use DataTimers for delayed processing to avoid blocking
   ```sourcepawn
   Handle pack;
   CreateDataTimer(0.0, timer_strip, pack);
   ```

### Common Modification Patterns

#### Adding New ConVars
```sourcepawn
// In OnPluginStart()
g_NewCvar = CreateConVar("sm_textreplace_newfeature", "1", "Description");
HookConVarChange(g_NewCvar, OnConVarChanged);

// In RefreshConfig()
NewFeatureValue = GetConVarInt(g_NewCvar);
```

#### Extending Color Processing
```sourcepawn
// In RefreshConfig() after reading file
ReplaceString(sBuffer, sizeof(sBuffer), "NEWSYMBOL", "\x0E");
```

#### Adding Admin Commands
```sourcepawn
// In OnPluginStart()
RegAdminCmd("sm_newcommand", Command_NewFeature, ADMFLAG_CONFIG, "Description");
```

## Build & Testing Process

### Local Development
```bash
# Install SourceKnight (if not installed)
pip install sourceknight

# Build the plugin
sourceknight build

# Output will be in .sourceknight/package/
```

### Testing Checklist
1. **Compilation**: Ensure plugin compiles without warnings
2. **Config Loading**: Test config file parsing with various color formats
3. **Message Interception**: Verify "[SM]" messages are properly replaced
4. **Admin Commands**: Test reload and test commands
5. **Random Colors**: Verify random color selection works when enabled
6. **Cross-Platform**: Test on both legacy and newer Source engine games

### CI/CD Validation
- GitHub Actions automatically builds on push/PR
- Creates releases with compiled plugins
- Packages include both plugin and config files

## Configuration Management

### Color Configuration Format
```
# sm_textcolors.cfg format
{default}[{green}SM{default}]{default}     # Standard green SM prefix
{red}[{white}ADMIN{red}]{default}          # Custom admin prefix
*[&FFFFFF&800080SM*]{default}              # Using escape sequences
```

### ConVar Configuration
- `sm_textcol_random`: Enable/disable random color selection
- Auto-generated config file via `AutoExecConfig(true)`

## Performance Considerations

### Critical Performance Areas
1. **Message Hooking**: Avoid expensive operations in `TextMsg` callback
2. **String Processing**: Minimize string operations in frequently called functions
3. **Timer Cleanup**: Ensure DataTimer packs are properly handled
4. **Config Reloading**: Cache color data to avoid repeated file I/O

### Optimization Patterns
```sourcepawn
// Pre-allocate arrays
char TextColors[MAXTEXTCOLORS][256];

// Use direct array access instead of searches
int ColorChoose = GetRandomInt(0, CountColors);
Format(QuickFormat, sizeof(QuickFormat), "%s", TextColors[ColorChoose]);
```

## Common Issues & Solutions

### Message Format Compatibility
**Problem**: Different Source engine versions use different message formats
**Solution**: Always check `GetUserMessageType()` and handle both cases

### Color Code Parsing
**Problem**: Invalid color codes causing display issues
**Solution**: Validate color strings and use fallback colors

### Memory Management
**Problem**: Handle leaks from timers or file operations
**Solution**: Always close handles and use appropriate timer cleanup

### Config File Access
**Problem**: Config file not found or permission issues
**Solution**: Use `BuildPath(Path_SM, ...)` and validate file existence

## Debugging & Troubleshooting

### Debug Commands
- `sm_reloadstc`: Reload color configuration
- `sm_test_stc`: Test color replacement (requires valid client)

### Log Analysis
- Check SourceMod error logs for compilation or runtime errors
- Monitor server console for config loading messages
- Use `LogAction()` for admin command auditing

### Common Debug Patterns
```sourcepawn
// Add debug output (remove in production)
PrintToChatAll("Debug: %s", variableName);

// Validate client before operations
if (client < 1 || !IsClientInGame(client))
    return;

// Check file operations
if (hFile == INVALID_HANDLE) {
    LogError("Failed to open config file");
    return;
}
```

## Version Control Best Practices

### Commit Guidelines
- Keep plugin version in sync with repository tags
- Update version in plugin info block when making functional changes
- Test builds before committing to ensure CI passes

### Release Process
- CI automatically creates releases for tags and main branch
- Manual testing recommended before tagging releases
- Include both source and compiled plugins in releases

## Integration Points

### MultiColors Library
- Provides advanced color formatting capabilities
- Functions: `CFormatColor()`, `CAddWhiteSpace()`
- Handles cross-game color compatibility

### SourceMod Framework
- Plugin lifecycle: `OnPluginStart()`, `OnConfigsExecuted()`, `OnPluginEnd()`
- ConVar system for configuration management
- Command registration and permission handling
- User message hooking for text interception

This plugin serves as a foundation for text replacement and color customization in SourceMod environments. When modifying, always consider backward compatibility and test across different Source engine games.