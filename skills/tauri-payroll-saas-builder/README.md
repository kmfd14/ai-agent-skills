# Tauri Payroll SaaS Builder - Custom Claude Skill

A comprehensive skill for building a desktop-first payroll and time tracking SaaS application using Tauri + Qwik + embedded mruby + Rails API.

## What This Skill Does

This skill helps you develop a complete payroll management system with:

- **Desktop Core Product** (Tauri + Qwik + mruby)
  - Offline-first architecture
  - Philippine payroll computation (SSS, PhilHealth, Pag-IBIG, BIR)
  - Employee management & time tracking
  - PDF and Excel report generation
  
- **Cloud Sync Add-on** (Rails API)
  - Multi-tenant architecture
  - License management
  - Real-time synchronization
  
- **Mobile Time Clock** (React Native)
  - Employee clock in/out
  - GPS tracking
  - Photo verification

- **Future: DTR Device** (ESP32/Arduino)
  - On-site biometric time tracking

## Installation for VS Code

### Prerequisites

1. **VS Code** with one of these Claude extensions:
   - [Continue](https://marketplace.visualstudio.com/items?itemName=Continue.continue)
   - [Claude Dev](https://marketplace.visualstudio.com/items?itemName=saoudrizwan.claude-dev)
   - [Cline](https://marketplace.visualstudio.com/items?itemName=saoudrizwan.claude-dev) (formerly Claude Dev)

2. **Anthropic API Key** (required for VS Code extensions)

### Setup Instructions

#### Option 1: Using Continue Extension

1. **Copy the skill folder** to your Continue skills directory:

   ```bash
   # Linux/macOS
   cp -r tauri-payroll-saas-builder ~/.continue/skills/
   
   # Windows
   xcopy /E /I tauri-payroll-saas-builder %USERPROFILE%\.continue\skills\tauri-payroll-saas-builder
   ```

2. **Configure Continue**:
   - Open VS Code
   - Press `Cmd/Ctrl + Shift + P`
   - Search for "Continue: Open Config"
   - Add to your `config.json`:

   ```json
   {
     "skills": [
       {
         "name": "tauri-payroll-saas-builder",
         "path": "~/.continue/skills/tauri-payroll-saas-builder/SKILL.md"
       }
     ]
   }
   ```

3. **Activate the skill**:
   - Open Continue chat (`Cmd/Ctrl + L`)
   - Type: `@tauri-payroll-saas-builder` to activate the skill
   - Or in settings, enable it as a default skill

#### Option 2: Using Claude Dev/Cline Extension

1. **Copy the skill folder**:

   ```bash
   # Linux/macOS
   cp -r tauri-payroll-saas-builder ~/.vscode/extensions/claude-dev-skills/
   
   # Windows
   xcopy /E /I tauri-payroll-saas-builder %USERPROFILE%\.vscode\extensions\claude-dev-skills\tauri-payroll-saas-builder
   ```

2. **Reference the skill**:
   - In Claude Dev chat, you can reference the skill by pasting the SKILL.md content
   - Or configure Claude Dev to auto-load skills from a directory

#### Option 3: Manual Usage (Any Claude Interface)

1. **Copy SKILL.md content**
2. **Paste into Claude chat** before asking questions:
   ```
   [Paste entire SKILL.md content]
   
   Now help me with: [your question about the payroll app]
   ```

## Usage Examples

### Starting a New Feature

```
@tauri-payroll-saas-builder

I need to implement employee overtime calculation with Philippine labor law rules.
Can you help me:
1. Write the mruby script for overtime computation
2. Create the Rust Tauri command
3. Build the Qwik UI component
```

### Debugging Issues

```
@tauri-payroll-saas-builder

I'm getting "database is locked" errors when running payroll computations.
What's the best way to fix this?
```

### Architecture Questions

```
@tauri-payroll-saas-builder

Should I implement the PDF generation in Rust or call Ruby's Prawn via mruby?
What are the trade-offs?
```

### Adding Security Features

```
@tauri-payroll-saas-builder

I want to implement machine fingerprinting for license validation.
Show me the complete implementation including:
- Rust code for fingerprint generation
- Storage encryption
- Validation logic
```

### License Verification

```
@tauri-payroll-saas-builder

Help me implement the offline/online license verification system with:
- Initial activation flow
- Periodic refresh
- 60-day grace period
```

## Skill Capabilities

The skill provides expert guidance on:

### Architecture
- Desktop-first design patterns
- Offline-capable sync strategies
- Multi-tier licensing models
- Security best practices

### Technologies
- **Tauri 2.0**: Commands, state management, window controls
- **Qwik**: Components, routing, signals, state
- **mruby**: Embedding Ruby in Rust, type conversions
- **SQLite**: Schema design, migrations, performance
- **Rails API**: Multi-tenancy, sync endpoints, JWT auth
- **React Native**: Mobile development, native modules

### Domain Knowledge
- **Philippine Payroll**:
  - SSS contribution tables
  - PhilHealth computation
  - Pag-IBIG deductions
  - BIR withholding tax
  - Overtime/holiday pay rules
  
- **Business Logic**:
  - License validation
  - Feature flags
  - Sync conflict resolution
  - Report generation

### Development Workflow
- Project setup on Fedora 43
- Build and deployment
- Testing strategies
- Debugging techniques
- Performance optimization

## Project Structure Reference

The skill understands this project structure:

```
tauri-payroll-app/
├── src-tauri/              # Rust backend
│   ├── src/
│   │   ├── commands/       # Tauri commands
│   │   ├── database/       # SQLite operations
│   │   ├── payroll/        # mruby engine
│   │   ├── reports/        # PDF/Excel generation
│   │   ├── sync/           # Rails API client
│   │   ├── license/        # License validation
│   │   └── security/       # Anti-tamper, encryption
│   └── embedded_scripts/   # Ruby business logic
│
├── src/                    # Qwik frontend
│   ├── components/
│   ├── routes/
│   └── services/
│
├── rails-api/              # Cloud sync (separate project)
│   ├── app/
│   ├── config/
│   └── db/
│
└── mobile-app/             # React Native (future)
```

## Development Phases

The skill is optimized for the current development phase:

**Phase 1: Desktop Core** (Current - Weeks 1-8)
- Setup and infrastructure
- Employee & time record management
- Payroll computation engine
- Report generation

**Phase 2: Rails API** (Weeks 9-12)
- API setup and endpoints
- License management
- Sync implementation

**Phase 3: Mobile App** (Weeks 13-16)
- React Native development
- API integration
- Testing

**Phase 4: DTR Device** (Future)
- Hardware integration

## Tips for Best Results

1. **Be specific**: Instead of "help with payroll", say "implement SSS contribution calculation for monthly employees earning ₱25,000"

2. **Mention the context**: "I'm working on the mruby integration" or "This is for the Qwik frontend"

3. **Reference the architecture**: The skill knows the full system design, so you can ask "how should this fit into the sync strategy?"

4. **Ask for complete solutions**: Request code for Rust, Ruby, and Qwik together for a feature

5. **Security questions**: The skill can review your code for security issues specific to desktop licensing

## Updating the Skill

As your project evolves, you can update the skill:

1. **Edit SKILL.md** to add new patterns, troubleshooting tips, or features
2. **No need to reload** - Continue/Claude Dev will use the updated version
3. **Share improvements**: If you discover better approaches, update the skill

## Getting Help

If the skill doesn't cover something you need:

1. **Ask Claude directly**: The skill is comprehensive but may need clarification
2. **Update the skill**: Add your findings to SKILL.md
3. **Consult documentation**:
   - Tauri: https://tauri.app
   - Qwik: https://qwik.builder.io
   - mruby: https://mruby.org

## Common Workflows

### Daily Development

```
@tauri-payroll-saas-builder

I'm starting work today. What should I focus on for Phase 1, Week 3?
```

### Code Review

```
@tauri-payroll-saas-builder

Review this Rust code for security issues:
[paste code]
```

### Troubleshooting

```
@tauri-payroll-saas-builder

The mruby engine isn't loading my Ruby scripts. Here's the error:
[paste error]
```

### Planning

```
@tauri-payroll-saas-builder

I want to add a new report type for 13th month pay.
What files do I need to modify?
```

## License

This skill is part of your proprietary payroll application project.
The skill itself can be freely modified and shared within your development team.

---

## Quick Start Checklist

- [ ] Install Continue/Claude Dev in VS Code
- [ ] Copy skill to appropriate directory
- [ ] Configure extension to load the skill
- [ ] Test with: `@tauri-payroll-saas-builder Hello, can you help me set up the project?`
- [ ] Start building your payroll app!

Happy coding! 🚀
