# Tauri Payroll SaaS - Project Summary & Context

## Project Overview

**Goal**: Create a desktop-first payroll and time tracking SaaS application with optional cloud sync and mobile capabilities.

**Business Model**: 
- **Base Product**: Desktop-only application (offline-capable)
- **Premium Add-on 1**: Cloud Sync (Rails API) - extra charge
- **Premium Add-on 2**: Mobile Time Clock (React Native) - extra charge
- **Future Add-on**: DTR Device (ESP32/Arduino) for on-site biometric time tracking

## Tech Stack Decision

### Desktop Application (Core Product)
- **Frontend**: Qwik (built with Bun 1.3.8)
- **Backend**: Rust (Tauri 2.0)
- **Business Logic**: Embedded mruby (Ruby VM embedded in Rust)
- **Database**: SQLite (local, offline-capable)
- **Reports**: 
  - PDF generation using Rust libraries (printpdf/genpdf) - not Ruby's Prawn
  - Excel generation using rust_xlsxwriter
  - Future feature: Custom report formats selectable by users

### Cloud Sync (Premium Add-on)
- **API**: Rails 8.1+ (JSON API only, no views)
- **Database**: PostgreSQL
- **Purpose**: 
  - Sync desktop data to cloud
  - Multi-device access
  - Mobile app backend
  - License management

### Mobile App (Premium Add-on)
- **Framework**: React Native + Expo
- **Reason**: Chosen because developer has web development background, no Flutter/native iOS/Android knowledge needed
- **Features**: Employee clock in/out, GPS tracking, photo verification
- **Requirement**: Requires Cloud Sync to be enabled (cloud mandatory for mobile)

### Future: DTR Device
- **Hardware**: ESP32 or Arduino
- **Features**: RFID/biometric sensors, LCD display
- **Connectivity**: WiFi → Rails API

## Architecture Decisions

### 1. Desktop-First Philosophy
- **Core functionality works 100% offline**
- All payroll computations happen locally (in Rust/mruby)
- No server dependency for basic operations
- Cloud sync is optional enhancement
- This ensures reliability even without internet

### 2. Why Embedded mruby for Business Logic?
**Developer's Choice**: Comfortable with mruby embedding approach - helps learn Rust along the way

**Benefits**:
- Write payroll calculations in Ruby (developer's strength)
- Embedded in Rust binary (no external Ruby runtime needed)
- Small footprint (~500KB)
- Hot-reloadable scripts
- Type-safe bridge between Rust and Ruby

**All payroll computations (SSS, PhilHealth, Pag-IBIG, BIR tax, overtime) in Ruby scripts**

### 3. Sync Architecture
**Chosen Model**: Hybrid Cloud-Optional

```
Mobile (React Native) 
    ↓ HTTPS/REST
Rails API (Central Server - Optional)
    ↓ WebSocket/REST
Desktop (Tauri + Qwik)
```

**For clients who want offline-only**:
- Skip Rails deployment entirely
- Desktop app has all functionality
- No cloud costs

**For clients who want cloud**:
- Deploy Rails to cloud (Render/Fly.io/Railway)
- Desktop syncs when online
- Mobile apps always connected

**Developer will host Rails API for customers** (SaaS model for better profit margins)

### 4. License Verification Model

**Business Model Decision**: Desktop licensing with feature flags

**Hybrid Online/Offline Licensing**:

1. **Initial Activation** (requires internet - one time):
   - User enters license key + company email
   - Desktop → Rails API with machine fingerprint
   - API validates and returns JWT (90-day validity)
   - JWT stored encrypted locally

2. **Ongoing Usage** (offline OK):
   - App checks local encrypted license on startup
   - Verifies JWT signature offline
   - Checks expiry date

3. **Periodic Refresh** (every 30 days):
   - When internet available: Desktop → Rails API
   - Refresh JWT token
   - Update enabled features

4. **Grace Period**:
   - 30-60 days offline: Show "please connect" warning
   - 60+ days offline: Read-only mode (can view data, can't create new)

**Feature Flags in License**:
- `cloud_sync_enabled`: true/false
- `mobile_app_enabled`: true/false
- `max_employees`: integer limit

**Machine Fingerprint**:
- Combines hardware identifiers (machine ID, hostname)
- Hashed with SHA-256
- Binds license to specific computer
- Prevents license sharing

### 5. Security Strategy

**Multi-Layer Approach**:

**Layer 1: Code Obfuscation**
```toml
[profile.release]
opt-level = "z"      # Optimize for size (harder to decompile)
lto = true           # Link-time optimization
strip = true         # Strip symbols
```

**Layer 2: String Encryption**
- Use `obfstr` crate to encrypt strings at compile time
- API URLs, secrets not visible in binary

**Layer 3: Critical Logic in Server**
- License generation/validation on Rails API
- Desktop does basic offline checks only
- Server has final authority

**Layer 4: Anti-Debugging**
- Detect debugger presence on startup
- Exit if debugger detected (production builds only)

**Layer 5: Encrypted Embedded Assets**
- Ruby scripts encrypted at build time
- Decrypted at runtime

**Layer 6: License Pinning**
- Bind license to machine + time period
- Check for time manipulation (system clock changes)

**Layer 7: Certificate Pinning**
- Prevent MITM attacks on license verification
- Hardcode expected SSL certificate

**Reality Check**: No perfect protection exists. Goal is to make cracking:
- Expensive (time/skill required)
- Not worth it (easier to just buy license)
- Detectable (monitor unusual activation patterns)

**Why it's still secure**: Even if desktop is cracked, premium features (cloud sync, mobile) require valid Rails API credentials, which can't be bypassed.

## Domain Knowledge: Philippine Payroll

**Target Region**: Philippines (for now, multi-region support planned for future)

### Government Contributions

**SSS (Social Security System)**:
- Monthly contribution based on salary brackets
- Shared between employee and employer
- Example: ₱25,000 salary → EE: ₱1,125, ER: ₱2,375
- Maximum bracket: ₱30,000+ → EE: ₱1,350, ER: ₱2,850

**PhilHealth**:
- 5% of monthly basic salary (split 2.5% EE / 2.5% ER)
- Minimum: ₱10,000 monthly salary
- Maximum: ₱100,000 monthly salary

**Pag-IBIG**:
- Employee: 1-2% of monthly compensation
- Employer: 2% of monthly compensation
- Max employee share: ₱100 (for ≤₱5,000 salary)

**BIR Withholding Tax (Annual Brackets)**:
```
₱0 - ₱250,000: 0%
₱250,001 - ₱400,000: 15% of excess over ₱250,000
₱400,001 - ₱800,000: ₱22,500 + 20% of excess over ₱400,000
₱800,001 - ₱2,000,000: ₱102,500 + 25% of excess over ₱800,000
₱2,000,001 - ₱8,000,000: ₱402,500 + 30% of excess over ₱2,000,000
₱8,000,001+: ₱2,202,500 + 35% of excess over ₱8,000,000
```

### Overtime Rules

- **Regular Overtime**: +25% of hourly rate
- **Rest Day Overtime**: +30% of hourly rate
- **Night Differential**: +10% (10 PM - 6 AM)
- **Holiday Pay**: 200% of daily rate (regular holiday)
- **Holiday + Overtime**: 260% of hourly rate

## Project Structure

```
tauri-payroll-app/
├── src-tauri/                      # Rust backend
│   ├── src/
│   │   ├── main.rs
│   │   ├── commands/               # Tauri commands (frontend API)
│   │   │   ├── employee.rs
│   │   │   ├── time_record.rs
│   │   │   ├── payroll.rs
│   │   │   └── reports.rs
│   │   ├── database/
│   │   │   ├── mod.rs
│   │   │   ├── models.rs
│   │   │   └── migrations.rs
│   │   ├── payroll/
│   │   │   ├── mod.rs
│   │   │   └── engine.rs           # mruby integration
│   │   ├── reports/
│   │   │   ├── pdf.rs              # PDF generation (Rust)
│   │   │   └── excel.rs            # Excel generation (Rust)
│   │   ├── sync/
│   │   │   ├── mod.rs
│   │   │   └── client.rs           # Rails API sync
│   │   ├── license/
│   │   │   ├── mod.rs
│   │   │   ├── validator.rs
│   │   │   ├── fingerprint.rs
│   │   │   └── storage.rs
│   │   └── security/
│   │       ├── mod.rs
│   │       └── anti_debug.rs
│   ├── embedded_scripts/           # Ruby business logic
│   │   ├── ph_payroll.rb
│   │   ├── tax_calculator.rb
│   │   └── overtime_rules.rb
│   ├── Cargo.toml
│   └── tauri.conf.json
│
├── src/                            # Qwik frontend
│   ├── components/
│   │   ├── employees/
│   │   ├── time-records/
│   │   ├── payroll/
│   │   └── reports/
│   ├── routes/
│   │   ├── index.tsx
│   │   ├── employees/
│   │   ├── time-records/
│   │   ├── payroll/
│   │   └── reports/
│   └── services/
│       └── tauri-api.ts            # Wrapper for Tauri commands
│
├── bun.lockb
├── package.json
└── README.md
```

## Database Schema (SQLite)

```sql
CREATE TABLE employees (
    id TEXT PRIMARY KEY,
    employee_number TEXT UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    date_hired DATE,
    position TEXT,
    department TEXT,
    employment_status TEXT,        -- regular, contractual, probationary
    pay_type TEXT,                 -- monthly, daily, hourly
    basic_salary REAL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    sync_status TEXT DEFAULT 'pending',
    last_synced_at DATETIME
);

CREATE TABLE time_records (
    id TEXT PRIMARY KEY,
    employee_id TEXT NOT NULL,
    record_date DATE NOT NULL,
    time_in DATETIME,
    time_out DATETIME,
    break_start DATETIME,
    break_end DATETIME,
    total_hours REAL,
    overtime_hours REAL,
    night_diff_hours REAL,
    source TEXT,                   -- desktop, mobile, device
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    sync_status TEXT DEFAULT 'pending',
    FOREIGN KEY (employee_id) REFERENCES employees(id)
);

CREATE TABLE payroll_runs (
    id TEXT PRIMARY KEY,
    pay_period_start DATE NOT NULL,
    pay_period_end DATE NOT NULL,
    run_date DATETIME NOT NULL,
    status TEXT,                   -- draft, approved, paid
    total_gross REAL,
    total_deductions REAL,
    total_net REAL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    sync_status TEXT DEFAULT 'pending'
);

CREATE TABLE payroll_items (
    id TEXT PRIMARY KEY,
    payroll_run_id TEXT NOT NULL,
    employee_id TEXT NOT NULL,
    basic_pay REAL,
    overtime_pay REAL,
    night_diff_pay REAL,
    holiday_pay REAL,
    gross_pay REAL,
    sss_employee REAL,
    philhealth_employee REAL,
    pagibig_employee REAL,
    withholding_tax REAL,
    other_deductions REAL,
    total_deductions REAL,
    net_pay REAL,
    computation_details TEXT,      -- JSON of full breakdown
    FOREIGN KEY (payroll_run_id) REFERENCES payroll_runs(id),
    FOREIGN KEY (employee_id) REFERENCES employees(id)
);

CREATE TABLE tax_tables (
    id TEXT PRIMARY KEY,
    country_code TEXT DEFAULT 'PH',
    effective_date DATE,
    table_type TEXT,               -- sss, philhealth, tax_withholding
    table_data TEXT,               -- JSON of rates/brackets
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sync_log (
    id TEXT PRIMARY KEY,
    sync_type TEXT,                -- push, pull
    entity_type TEXT,
    entity_id TEXT,
    status TEXT,                   -- success, failed, conflict
    error_message TEXT,
    synced_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE app_settings (
    key TEXT PRIMARY KEY,
    value TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

## Development Phases

### Phase 1: Desktop Core (Weeks 1-8) - CURRENT PHASE

**Week 1-2: Setup & Infrastructure** ✅ COMPLETED
- [x] Install Rust, Bun on Fedora 43
- [x] Set up Tauri + Qwik project
- [x] Configure mruby embedding
- [x] Create SQLite schema
- [x] Set up project structure

**Week 3-4: Employee & Time Records** ✅ COMPLETED
- [x] Employee CRUD (UI + backend)

**Week 3-4: Employee & Time Records** 🔄 IN PROGRESS
- [ ] Time record entry/editing
- [ ] Manual time calculations
- [ ] Basic validation

**Week 5-6: Payroll Engine** 📋 NEXT
- [ ] Implement PH payroll rules in Ruby
- [ ] SSS, PhilHealth, Pag-IBIG tables
- [ ] BIR withholding tax computation
- [ ] Overtime/night diff/holiday rules
- [ ] Payroll run generation

**Week 7-8: Reports & Polish** 📋 UPCOMING
- [ ] PDF generation (COE, Payslips)
- [ ] Excel export (Payroll reports)
- [ ] Print functionality
- [ ] UI/UX refinement
- [ ] Testing & bug fixes
- [ ] Performance optimization
- [ ] Installer creation (.exe, .deb, .dmg)
- [ ] User documentation

### Phase 2: Rails API (Weeks 9-12) - FUTURE

**Week 9-10: API Setup**
- [ ] Rails 8.1+ API setup (multi-tenant)
- [ ] Sync endpoints (push/pull)
- [ ] License/subscription system
- [ ] PostgreSQL schema

**Week 11-12: Desktop Integration**
- [ ] Desktop sync client (Rust)
- [ ] Conflict resolution
- [ ] Background sync
- [ ] Testing

### Phase 3: Mobile App (Weeks 13-16) - FUTURE

- [ ] React Native + Expo setup
- [ ] Login/auth
- [ ] Clock in/out UI
- [ ] GPS integration
- [ ] API integration
- [ ] iOS/Android testing

### Phase 4: DTR Device - FUTURE

- [ ] ESP32 firmware
- [ ] RFID/biometric sensor
- [ ] LCD display
- [ ] WiFi → Rails API
- [ ] Employee lookup

## Pricing Model Decision

**Decision**: Deferred until desktop application is complete

**Reasoning**: Need to build the desktop core first, then create licensing model to verify users per license using Rails API

**Initial Setup Requirement**: License validation will be done on initial app setup (requires internet one-time)

## Development Environment

**Host OS**: Fedora 43
**Package Manager**: Bun 1.3.8
**No Containers**: All development is local (no Docker/Podman)

**Installed Tools**:
- Rust 1.93.0
- Cargo 1.93.0
- Bun 1.3.8
- Node.js v22.22.0
- npm 10.9.4
- Ruby 4.0.1 (system), 3.4.1 (rbenv for Rails development)
- GCC 15.2.1

**Note on Ruby**: Developer uses rbenv to manage Ruby versions. System Ruby (4.0.1) is available, but rbenv global is set to 3.4.1. This is fine - mruby will be embedded in Rust binary, and system Ruby is just for testing scripts.

## Key Dependencies (Cargo.toml)

```toml
[dependencies]
tauri = "2.0"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
tokio = { version = "1", features = ["full"] }
rusqlite = { version = "0.31", features = ["bundled"] }
rust_xlsxwriter = "0.76"              # Excel generation
mruby = "2.0"                         # Embedded Ruby
mruby-sys = "2.0"
reqwest = { version = "0.12", features = ["json"] }  # Cloud sync
chrono = "0.4"
uuid = { version = "1.0", features = ["v4"] }
jsonwebtoken = "9.0"                  # License JWT
aes-gcm = "0.10"                      # License encryption
obfstr = "0.4"                        # String encryption
printpdf = "0.7"                      # PDF generation (or genpdf)

[profile.release]
opt-level = "z"
lto = true
codegen-units = 1
strip = true
panic = "abort"
```

## Current Status

**Completed**:
- ✅ Development environment setup (Fedora 43)
- ✅ All required tools installed (Rust, Bun, Tauri dependencies)
- ✅ Project structure created (Tauri + Qwik)
- ✅ mruby embedding configured
- ✅ SQLite schema designed
- ✅ Employee CRUD implemented (UI + backend)

**Current Work** (Week 3-4):
- 🔄 Time Records implementation
  - Time record entry/editing UI
  - Time calculation logic (total hours, overtime, night differential)
  - Validation (no overlapping times, no future dates)

**Next Up** (Week 5-6):
- Payroll computation engine (mruby)
- Philippine payroll rules implementation

## Important Architectural Notes

### Why This Stack?

1. **Tauri over Electron**: Smaller bundle, faster, native performance
2. **Qwik over React**: Performance benefits, resumability
3. **mruby over pure Rust**: Developer can write business logic in familiar Ruby
4. **SQLite over PostgreSQL locally**: Offline capability, simplicity
5. **Rails API separate**: Optional, not required for core product

### Design Principles

1. **Offline-first**: App must work without internet
2. **Desktop computations**: All payroll calculations happen locally, not on server
3. **Progressive enhancement**: Cloud and mobile are add-ons, not requirements
4. **Security in depth**: Multiple layers, no single point of failure
5. **Performance matters**: Using Rust for heavy operations, Ruby for business logic
6. **Developer experience**: Use Ruby (familiar) for complex business rules

## Questions Previously Asked & Answered

**Q: Should I use Rails for desktop computations?**
A: No. Initially wanted Tauri to perform computations since:
- Desktop needs to work when Rails API is down
- User might not have cloud access
- Cloud and mobile are premium add-ons

**Q: How to verify users with desktop-only license?**
A: Initial activation requires internet (one-time), then JWT token valid for 90 days offline, with 30-day periodic refresh and 60-day grace period.

**Q: How to avoid reverse engineering?**
A: Multi-layer security (obfuscation, encryption, anti-debugging, server-side validation), but acknowledged no perfect protection exists. Goal is to make it not worth the effort.

**Q: Which mobile framework?**
A: React Native + Expo (developer has web background, no Flutter/native knowledge needed, deploy to both iOS/Android from single codebase)

**Q: Which PDF library?**
A: Rust library (printpdf or genpdf), NOT Ruby's Prawn. Future feature: custom formats selectable by users.

**Q: Is mruby embedding approach OK?**
A: Yes, developer is comfortable with it and wants to learn Rust along the way.

**Q: When to think about pricing?**
A: After desktop application is finished. Need working product first to create licensing model.

## Next Session Focus

**Immediate Goal**: Complete Time Records feature (Week 3-4)

**Tasks**:
1. Time record entry UI (Qwik component)
2. Time record Tauri commands (Rust)
3. Time calculation logic (total hours, overtime, night differential)
4. Validation rules
5. Testing

**After Time Records**: Move to Week 5-6 Payroll Engine

---

*This summary provides context for continuing development in VS Code with Claude integration. It captures all architectural decisions, tech stack choices, and current progress without the skill files and setup scripts.*
