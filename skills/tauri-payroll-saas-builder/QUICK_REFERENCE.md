# Tauri Payroll SaaS - Quick Reference

## Tech Stack at a Glance

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Desktop UI | Qwik | Frontend framework |
| Desktop Backend | Rust (Tauri) | System integration |
| Business Logic | mruby | Payroll calculations |
| Local DB | SQLite | Offline data storage |
| Cloud API | Rails 8.1+ | Sync & licensing |
| Cloud DB | PostgreSQL | Multi-tenant data |
| Mobile | React Native | Employee time clock |
| Package Manager | Bun 1.3.8 | Frontend dependencies |
| Build Tool | Cargo | Rust compilation |

## Common Commands

### Project Setup
```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install Bun
curl -fsSL https://bun.sh/install | bash

# Create Tauri project
bun create tauri-app

# Install dependencies
bun install

# Add Tauri dependencies (Fedora 43)
sudo dnf install webkit2gtk4.1-devel openssl-devel \
    curl wget file libappindicator-gtk3-devel librsvg2-devel
```

### Development
```bash
# Run development mode
bun run tauri dev

# Build for production
bun run tauri build

# Run tests
cargo test
bun test

# Check Rust code
cargo clippy

# Format code
cargo fmt
```

### Database
```bash
# Create migration
sqlite3 data.db < migrations/001_initial.sql

# Inspect database
sqlite3 data.db
.tables
.schema employees
```

## Key File Locations

```
src-tauri/src/commands/     → Tauri commands (Rust → Frontend API)
src-tauri/embedded_scripts/ → Ruby business logic
src/components/             → Qwik UI components
src/routes/                 → Qwik routes/pages
```

## Cargo.toml Key Dependencies

```toml
[dependencies]
tauri = "2.0"
serde = { version = "1.0", features = ["derive"] }
rusqlite = { version = "0.31", features = ["bundled"] }
rust_xlsxwriter = "0.76"
mruby = "2.0"
reqwest = { version = "0.12", features = ["json"] }
jsonwebtoken = "9.0"
aes-gcm = "0.10"

[profile.release]
opt-level = "z"
lto = true
strip = true
```

## Tauri Command Template

```rust
#[tauri::command]
pub async fn my_command(
    param: String,
    state: State<'_, MyState>,
) -> Result<ReturnType, String> {
    // Implementation
    Ok(result)
}

// Register in main.rs:
.invoke_handler(tauri::generate_handler![my_command])
```

## Qwik → Tauri Template

```typescript
import { invoke } from '@tauri-apps/api/core';

const result = await invoke<ReturnType>('my_command', { 
  param: 'value' 
});
```

## mruby Integration Template

```rust
// Load script
let script = include_str!("../embedded_scripts/script.rb");
mruby.run(script)?;

// Call Ruby method
let result = mruby.funcall("ClassName", "method_name", &[args])?;

// Convert types
let rb_value = mruby.serialize_to_ruby(&rust_value)?;
let rust_value: Type = mruby.deserialize_from_ruby(rb_value)?;
```

## Philippine Payroll Quick Reference

### SSS Brackets (2024)
| Salary Range | EE | ER | Total |
|--------------|----|----|-------|
| ₱0-4,249 | 180 | 380 | 560 |
| ₱4,250-4,749 | 202.50 | 427.50 | 630 |
| ₱29,750-30,000+ | 1,350 | 2,850 | 4,200 |

### PhilHealth
- Rate: 5% of monthly salary (split 2.5% EE / 2.5% ER)
- Min: ₱10,000 salary
- Max: ₱100,000 salary

### Pag-IBIG
- EE: 1-2% (max ₱100 for ≤₱5,000 salary)
- ER: 2%

### BIR Tax (Annual)
| Bracket | Tax |
|---------|-----|
| ≤₱250,000 | 0% |
| ₱250,001-400,000 | 15% excess |
| ₱400,001-800,000 | ₱22,500 + 20% excess |
| ₱800,001-2,000,000 | ₱102,500 + 25% excess |
| ₱2,000,001-8,000,000 | ₱402,500 + 30% excess |
| >₱8,000,000 | ₱2,202,500 + 35% excess |

### Overtime Rates
- Regular OT: +25%
- Rest day OT: +30%
- Night diff: +10% (10 PM - 6 AM)
- Holiday: 200%
- Holiday + OT: 260%

## Database Schema Cheat Sheet

```sql
-- Quick employee insert
INSERT INTO employees (id, employee_number, first_name, last_name, basic_salary)
VALUES ('uuid', 'EMP001', 'Juan', 'Dela Cruz', 25000.00);

-- Quick time record
INSERT INTO time_records (id, employee_id, record_date, time_in, time_out)
VALUES ('uuid', 'emp_id', '2024-01-15', '08:00:00', '17:00:00');

-- Calculate total hours
SELECT 
    employee_id,
    SUM(total_hours) as total_hours,
    SUM(overtime_hours) as overtime_hours
FROM time_records
WHERE record_date BETWEEN ? AND ?
GROUP BY employee_id;
```

## License Validation Flow

1. **Initial Activation** (requires internet)
   - User enters license key
   - App sends to Rails API with machine fingerprint
   - API validates and returns JWT (90-day validity)
   
2. **Startup Validation** (offline OK)
   - Load encrypted local license
   - Verify JWT signature
   - Check expiry date
   
3. **Periodic Refresh** (every 30 days)
   - Connect to Rails API
   - Refresh JWT
   - Update features
   
4. **Grace Period**
   - 30-60 days: Warning message
   - 60+ days: Read-only mode

## Security Checklist

- [ ] `opt-level = "z"` in Cargo.toml release profile
- [ ] `lto = true` and `strip = true`
- [ ] Strings encrypted with `obfstr!` macro
- [ ] Anti-debugging checks enabled
- [ ] Machine fingerprint validation
- [ ] License encrypted with AES-256-GCM
- [ ] API calls use certificate pinning
- [ ] Binary integrity verification

## Build & Deploy

```bash
# Development build
cargo build

# Production build (optimized)
cargo build --release

# Create installers
cargo tauri build

# Outputs:
# Linux: target/release/bundle/deb/*.deb
# Linux: target/release/bundle/appimage/*.AppImage
# Windows: target/release/bundle/msi/*.msi
# macOS: target/release/bundle/dmg/*.dmg
```

## Troubleshooting Quick Fixes

### mruby build fails
```bash
sudo dnf install gcc make ruby-devel
cargo clean
```

### Database locked
```rust
conn.execute("PRAGMA journal_mode=WAL", [])?;
```

### Tauri dev won't start
```bash
# Clear cache
rm -rf target/
bun install
```

### License verification fails
1. Check JWT expiry
2. Verify machine fingerprint unchanged
3. Check internet connectivity
4. Validate local license file exists

## Environment Variables

```bash
# Development
export RUST_LOG=debug
export DATABASE_URL=sqlite:///home/user/payroll.db

# Production
export RUST_LOG=info
export API_URL=https://api.yourapp.com
export LICENSE_PUBLIC_KEY_PATH=/etc/payroll/license.pub
```

## VS Code Extensions Recommended

- Rust Analyzer
- Tauri
- Qwik
- ESLint
- Prettier
- SQLite Viewer
- Continue (for Claude integration)

## API Endpoints (Rails)

```
POST   /api/v1/license/activate      # Activate license
GET    /api/v1/license/verify        # Refresh JWT
POST   /api/v1/sync/push             # Push local changes
GET    /api/v1/sync/pull             # Pull remote changes
POST   /api/v1/mobile/clockin        # Mobile clock in
POST   /api/v1/mobile/clockout       # Mobile clock out
```

## Development Phases

**Phase 1** (Current): Desktop Core
- Employee management
- Time records
- Payroll engine
- Reports

**Phase 2**: Rails API
- Sync endpoints
- License system
- Multi-tenancy

**Phase 3**: Mobile App
- React Native
- Time clock
- GPS tracking

**Phase 4**: DTR Device
- ESP32/Arduino
- Biometric/RFID
- WiFi connectivity

## Getting Help

1. Check SKILL.md for detailed guidance
2. Use `@tauri-payroll-saas-builder` in VS Code with Continue
3. Consult official docs:
   - Tauri: https://tauri.app
   - Qwik: https://qwik.builder.io
   - mruby: https://mruby.org
   - Rails: https://guides.rubyonrails.org

---

**Pro Tips:**
- Always test payroll calculations manually before deploying
- Keep tax tables updated (check DOLE/BIR quarterly)
- Use SQLite WAL mode for better concurrency
- Encrypt sensitive data before syncing to cloud
- Version your Ruby scripts in embedded_scripts/
