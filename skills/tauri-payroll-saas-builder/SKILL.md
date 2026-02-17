---
name: tauri-payroll-saas-builder
description: Comprehensive skill for building a desktop-first payroll & time tracking SaaS using Tauri + Qwik + embedded mruby + Rails API. Covers architecture, security, licensing, Philippine payroll computation, and deployment. Use when developing or maintaining the payroll application, implementing features, or debugging issues.
---

# Tauri Payroll SaaS Builder

A specialized skill for developing a multi-tier desktop payroll and time tracking application with cloud sync and mobile capabilities.

## Project Overview

**Core Product**: Desktop application (Tauri + Qwik)
- Offline-first architecture with embedded business logic
- Philippine payroll computation (SSS, PhilHealth, Pag-IBIG, BIR tax)
- Employee management and time record tracking
- PDF (COE, payslips) and Excel (reports) generation

**Premium Add-ons**:
- Cloud Sync: Rails API for multi-device synchronization
- Mobile App: React Native time clock for employees
- Future: DTR Device (ESP32/Arduino) for on-site time tracking

## Tech Stack

### Desktop App (Core Product)
```
Frontend: Qwik (built with Bun 1.3.8)
Backend: Rust (Tauri 2.0)
Business Logic: Embedded mruby (Ruby VM in Rust)
Database: SQLite (local, offline-capable)
Reports: rust_xlsxwriter (Excel), printpdf (PDF)
```

### Cloud Sync (Premium Add-on)
```
API: Rails 8.1+ (JSON API)
Database: PostgreSQL
Queue: Solid Queue
WebSockets: ActionCable
Hosting: Render/Fly.io/Railway
```

### Mobile App (Premium Add-on)
```
Framework: React Native + Expo
Features: Clock in/out, GPS, photo verification
Target: iOS + Android
```

### Future: DTR Device
```
Hardware: ESP32/Arduino
Sensors: RFID/Biometric
Display: LCD
Connectivity: WiFi → Rails API
```

## Architecture Principles

### 1. Desktop-First Model
- Core functionality works 100% offline
- No server dependency for basic operations
- Cloud sync is optional enhancement
- Mobile requires cloud (future: LAN support via DTR device)

### 2. Embedded Business Logic (mruby)
- All payroll calculations in Ruby scripts
- Embedded in Rust binary (no external runtime)
- Hot-reloadable for updates
- Developer writes business logic in familiar Ruby

### 3. Licensing Strategy
- Initial activation requires internet (one-time)
- JWT token with 90-day validity
- Periodic online verification (every 30 days)
- 60-day grace period if offline
- Feature flags: cloud_sync, mobile_app, max_employees

### 4. Security Layers
- Code obfuscation (LTO, strip symbols)
- String encryption (obfstr)
- Anti-debugging checks
- Binary integrity verification
- Machine fingerprint binding
- Certificate pinning for API calls

## File Structure

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
│   │   │   ├── pdf.rs              # PDF generation
│   │   │   └── excel.rs            # Excel generation
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
-- Core tables
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
    employment_status TEXT,
    pay_type TEXT,
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
    source TEXT,
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
    status TEXT,
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
    computation_details TEXT,
    FOREIGN KEY (payroll_run_id) REFERENCES payroll_runs(id),
    FOREIGN KEY (employee_id) REFERENCES employees(id)
);

CREATE TABLE tax_tables (
    id TEXT PRIMARY KEY,
    country_code TEXT DEFAULT 'PH',
    effective_date DATE,
    table_type TEXT,
    table_data TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sync_log (
    id TEXT PRIMARY KEY,
    sync_type TEXT,
    entity_type TEXT,
    entity_id TEXT,
    status TEXT,
    error_message TEXT,
    synced_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE app_settings (
    key TEXT PRIMARY KEY,
    value TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

## Philippine Payroll Rules

### Government Contributions

**SSS (Social Security System)**
- Monthly contribution based on salary brackets
- Shared between employee and employer
- Ranges: ₱0-4,249 → EE: ₱180, ER: ₱380
- Maximum: ₱30,000+ → EE: ₱1,350, ER: ₱2,850

**PhilHealth**
- 5% of monthly basic salary (split EE/ER)
- Minimum: ₱10,000 monthly salary
- Maximum: ₱100,000 monthly salary
- Employee pays 2.5%, Employer pays 2.5%

**Pag-IBIG**
- Employee: 1-2% of monthly compensation
- Employer: 2% of monthly compensation
- Maximum employee share: ₱100 (for ≤₱5,000 salary)

### Withholding Tax (BIR)

**Tax Table (Annual)**
```
₱0 - ₱250,000: 0%
₱250,001 - ₱400,000: 15% of excess over ₱250,000
₱400,001 - ₱800,000: ₱22,500 + 20% of excess over ₱400,000
₱800,001 - ₱2,000,000: ₱102,500 + 25% of excess over ₱800,000
₱2,000,001 - ₱8,000,000: ₱402,500 + 30% of excess over ₱2,000,000
₱8,000,001+: ₱2,202,500 + 35% of excess over ₱8,000,000
```

### Overtime Rules

**Regular Overtime**: +25% of hourly rate
**Rest Day Overtime**: +30% of hourly rate
**Night Differential**: +10% (10 PM - 6 AM)
**Holiday Pay**: 200% of daily rate (regular holiday)
**Holiday + Overtime**: 260% of hourly rate

## Code Patterns

### Tauri Command (Rust → Frontend)

```rust
// src-tauri/src/commands/employee.rs
use tauri::State;
use crate::database::Database;
use crate::models::Employee;

#[tauri::command]
pub async fn get_employees(
    db: State<'_, Database>,
) -> Result<Vec<Employee>, String> {
    db.get_all_employees()
        .await
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub async fn create_employee(
    employee: Employee,
    db: State<'_, Database>,
) -> Result<Employee, String> {
    db.insert_employee(employee)
        .await
        .map_err(|e| e.to_string())
}
```

### mruby Integration

```rust
// src-tauri/src/payroll/engine.rs
use mruby::{Mruby, MrubyImpl};

pub struct PayrollEngine {
    mruby: Mruby,
}

impl PayrollEngine {
    pub fn new() -> Result<Self, Box<dyn std::error::Error>> {
        let mruby = Mruby::new();
        
        // Load Ruby scripts
        let script = include_str!("../../embedded_scripts/ph_payroll.rb");
        mruby.run(script)?;
        
        Ok(Self { mruby })
    }
    
    pub fn compute_payroll(
        &self,
        employee: &Employee,
        time_records: &[TimeRecord],
        pay_period: &PayPeriod,
    ) -> Result<PayrollResult, Box<dyn std::error::Error>> {
        // Convert Rust structs to Ruby objects
        let rb_employee = self.mruby.serialize_to_ruby(employee)?;
        let rb_records = self.mruby.serialize_to_ruby(time_records)?;
        let rb_period = self.mruby.serialize_to_ruby(pay_period)?;
        
        // Call Ruby
        let result = self.mruby.funcall(
            "PhilippinesPayroll",
            "new",
            &[rb_employee, rb_records, rb_period],
        )?;
        
        let computed = self.mruby.funcall(result, "compute", &[])?;
        
        // Convert back to Rust
        let payroll_result: PayrollResult = 
            self.mruby.deserialize_from_ruby(computed)?;
        
        Ok(payroll_result)
    }
}
```

### Qwik Component → Tauri

```typescript
// src/components/employees/employee-list.tsx
import { component$, useSignal } from '@builder.io/qwik';
import { invoke } from '@tauri-apps/api/core';

export default component$(() => {
  const employees = useSignal([]);
  
  const loadEmployees = $(async () => {
    try {
      const data = await invoke('get_employees');
      employees.value = data;
    } catch (error) {
      console.error('Failed to load employees:', error);
    }
  });
  
  return (
    <div>
      <button onClick$={loadEmployees}>Load Employees</button>
      <ul>
        {employees.value.map((emp) => (
          <li key={emp.id}>{emp.first_name} {emp.last_name}</li>
        ))}
      </ul>
    </div>
  );
});
```

### License Validation

```rust
// src-tauri/src/license/validator.rs
use jsonwebtoken::{decode, DecodingKey, Validation, Algorithm};

pub struct LicenseValidator {
    public_key: DecodingKey,
}

impl LicenseValidator {
    pub fn validate_license(&self, license: &License) -> Result<bool, Error> {
        // 1. Verify JWT signature (offline)
        let validation = Validation::new(Algorithm::RS256);
        let token_data = decode::<JwtClaims>(
            &license.jwt_token,
            &self.public_key,
            &validation,
        )?;
        
        // 2. Check expiry
        let now = chrono::Utc::now().timestamp();
        if token_data.claims.exp < now {
            return Err(Error::LicenseExpired);
        }
        
        // 3. Verify machine fingerprint
        let current_fingerprint = get_machine_fingerprint()?;
        if token_data.claims.machine_id != current_fingerprint {
            return Err(Error::MachineMismatch);
        }
        
        // 4. Check if needs online refresh
        let days_since_verify = (now - license.last_verified_at) / 86400;
        if days_since_verify > 30 {
            if let Ok(new_license) = self.refresh_online(license).await {
                return Ok(true);
            } else if days_since_verify > 60 {
                return Err(Error::VerificationRequired);
            }
        }
        
        Ok(true)
    }
}
```

### Rails API Sync

```rust
// src-tauri/src/sync/client.rs
pub struct SyncClient {
    api_url: String,
    jwt_token: String,
}

impl SyncClient {
    pub async fn push_changes(&self) -> Result<(), Error> {
        let pending = self.db.get_pending_sync()?;
        
        let client = reqwest::Client::new();
        let response = client
            .post(&format!("{}/api/v1/sync/push", self.api_url))
            .header("Authorization", format!("Bearer {}", self.jwt_token))
            .json(&pending)
            .send()
            .await?;
        
        if response.status().is_success() {
            self.db.mark_synced(&pending)?;
        }
        
        Ok(())
    }
    
    pub async fn pull_changes(&self) -> Result<(), Error> {
        let client = reqwest::Client::new();
        let response = client
            .get(&format!("{}/api/v1/sync/pull", self.api_url))
            .header("Authorization", format!("Bearer {}", self.jwt_token))
            .send()
            .await?;
        
        if response.status().is_success() {
            let updates: SyncData = response.json().await?;
            self.db.apply_updates(updates)?;
        }
        
        Ok(())
    }
}
```

## Development Workflow

### Phase 1: Desktop Core (Current Focus)

**Week 1-2: Setup**
1. Install Rust, Bun on Fedora 43
2. Initialize Tauri + Qwik project
3. Configure mruby embedding
4. Set up SQLite schema

**Week 3-4: Employee & Time Records**
1. Employee CRUD (UI + backend)
2. Time record entry/editing
3. Manual calculations
4. Validation

**Week 5-6: Payroll Engine**
1. Philippine payroll rules in Ruby
2. SSS/PhilHealth/Pag-IBIG tables
3. BIR tax computation
4. Overtime/night diff/holiday rules

**Week 7-8: Reports & Polish**
1. PDF generation (COE, payslips)
2. Excel export (payroll reports)
3. UI/UX refinement
4. Installer (.exe, .deb, .dmg)

### Phase 2: Rails API

**Week 9-10: Setup**
1. Multi-tenant Rails API
2. Sync endpoints
3. License system
4. PostgreSQL schema

**Week 11-12: Integration**
1. Desktop sync client
2. Conflict resolution
3. Background sync
4. Testing

### Phase 3: Mobile App

**Week 13-16: React Native**
1. Login/auth
2. Clock in/out
3. GPS integration
4. API integration

### Phase 4: DTR Device (Future)

**TBD**
1. ESP32 firmware
2. RFID/biometric
3. LCD display
4. WiFi → API

## Common Tasks

### Adding a New Feature

1. **Define in Ruby** (if business logic):
   ```ruby
   # embedded_scripts/new_feature.rb
   class NewFeature
     def calculate(params)
       # Business logic here
     end
   end
   ```

2. **Add Tauri Command**:
   ```rust
   // src-tauri/src/commands/new_feature.rs
   #[tauri::command]
   pub async fn new_feature_command(
       params: Params,
       engine: State<'_, PayrollEngine>,
   ) -> Result<Output, String> {
       engine.run_feature(params)
           .map_err(|e| e.to_string())
   }
   ```

3. **Update Frontend**:
   ```typescript
   // src/components/new-feature.tsx
   const result = await invoke('new_feature_command', { params });
   ```

### Debugging mruby Issues

1. **Enable verbose mruby logging**:
   ```rust
   let mruby = Mruby::new();
   mruby.enable_debug_logging();
   ```

2. **Check Ruby script syntax**:
   ```bash
   ruby -c embedded_scripts/ph_payroll.rb
   ```

3. **Test Ruby logic separately**:
   ```ruby
   # test_payroll.rb
   load 'embedded_scripts/ph_payroll.rb'
   
   payroll = PhilippinesPayroll.new(employee, records, period)
   result = payroll.compute
   puts result.inspect
   ```

### Building for Production

```bash
# Development build
cd src-tauri
cargo build

# Production build (optimized + obfuscated)
cargo build --release

# Create installer
cargo tauri build
```

**Build outputs**:
- Linux: `.deb`, `.AppImage`
- Windows: `.msi`, `.exe`
- macOS: `.dmg`, `.app`

### Security Checklist

- [ ] Obfuscation enabled in Cargo.toml
- [ ] Strings encrypted with obfstr
- [ ] Anti-debugging checks in place
- [ ] Binary integrity verification
- [ ] License validation on startup
- [ ] Machine fingerprint binding
- [ ] Certificate pinning for API
- [ ] Encrypted local storage

## Troubleshooting

### mruby won't compile

**Error**: `mruby-sys build failed`

**Solution**:
```bash
# Install required build tools
sudo dnf install gcc make ruby-devel

# Clear cargo cache
cargo clean
```

### Tauri build fails on Fedora

**Error**: `webkit2gtk-4.1 not found`

**Solution**:
```bash
# Install Tauri dependencies for Fedora
sudo dnf install webkit2gtk4.1-devel \
    openssl-devel \
    curl \
    wget \
    file \
    libappindicator-gtk3-devel \
    librsvg2-devel
```

### SQLite locked errors

**Error**: `database is locked`

**Solution**:
- Use connection pooling
- Enable WAL mode:
  ```rust
  conn.execute("PRAGMA journal_mode=WAL", [])?;
  ```

### License verification fails offline

**Check**:
1. JWT token not expired?
2. Within 60-day grace period?
3. Machine fingerprint unchanged?
4. Local license file not corrupted?

## Best Practices

### Code Organization

1. **Separate concerns**: UI (Qwik) → Commands (Rust) → Business Logic (mruby) → Data (SQLite)
2. **Type safety**: Use Rust's type system, avoid `unwrap()` in production
3. **Error handling**: Always return `Result<T, E>`, never panic
4. **Testing**: Unit tests for Ruby logic, integration tests for Rust commands

### Performance

1. **Database**: Index frequently queried columns
2. **Sync**: Batch operations, use background threads
3. **UI**: Lazy load large lists, paginate results
4. **mruby**: Cache compiled Ruby scripts

### Security

1. **Input validation**: Sanitize all user inputs
2. **SQL injection**: Use parameterized queries only
3. **XSS**: Escape output in Qwik components
4. **License**: Never trust client-side checks alone

### Maintainability

1. **Documentation**: Comment complex business logic
2. **Versioning**: Track schema versions for migrations
3. **Logging**: Use structured logging (tracing crate)
4. **Configuration**: Environment-based settings

## Resources

**Tauri**:
- https://tauri.app/v2/guides/
- https://tauri.app/v2/reference/

**Qwik**:
- https://qwik.builder.io/docs/
- https://qwik.builder.io/qwikcity/

**mruby**:
- https://github.com/mruby/mruby
- https://mruby.org/docs/

**Philippine Labor Law**:
- DOLE Labor Advisories
- SSS Contribution Schedule
- PhilHealth Circular
- BIR Tax Tables

## When to Use This Skill

Use this skill when:
- Implementing new features in the payroll app
- Debugging issues with Tauri, Qwik, or mruby
- Adding Philippine payroll rules or tax calculations
- Setting up licensing or security features
- Integrating with Rails API for sync
- Building installers or deploying
- Reviewing architecture decisions
- Planning new premium add-ons

## Skill Limitations

This skill does NOT cover:
- Generic Rust programming (use general Rust resources)
- Generic React Native development (use RN docs)
- General Rails API design (use Rails guides)
- Other countries' payroll rules (Philippines only for now)
- Hardware programming for DTR devices (future phase)

## Development Environment

**Host**: Fedora 43
**Package Manager**: Bun 1.3.8
**No Containers**: All development local
**Required Tools**:
- Rust (via rustup)
- Bun 1.3.8
- Node.js (for some tooling)
- SQLite
- Git

## Next Steps After Phase 1

Once desktop core is complete:

1. **Beta Testing**: Local deployment, gather feedback
2. **Pricing Model**: Determine license tiers
3. **Rails API**: Build cloud sync infrastructure
4. **Mobile App**: React Native development
5. **DTR Device**: Hardware prototyping
6. **Multi-region**: Expand beyond Philippines

---

## Summary

This skill provides comprehensive guidance for building a desktop-first payroll SaaS with:
- Offline-capable core product
- Optional cloud sync
- Mobile time tracking
- Philippine payroll compliance
- Secure licensing
- Professional reports

Focus on delivering value to customers who need reliable payroll software that works even without internet access, with premium features available for those who want cloud collaboration.
