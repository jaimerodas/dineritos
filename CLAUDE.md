# Dineritos - Investment Tracking Application

## Project Overview
Dineritos is a personal finance tracking application built with Rails 8 to monitor investment accounts across different platforms and currencies. It helps track balances over time and provides insights into investment performance.

**Primary Purpose**: Track investment account balances across multiple platforms (MXN/USD) with automatic currency conversion and performance analytics.

## Tech Stack
- **Backend**: Ruby 3.4.7, Rails 8.1
- **Database**: PostgreSQL
- **Deployment**: Kamal 2 on DigitalOcean, Docker, ghcr.io
- **CI/CD**: GitHub Actions (CI + auto-deploy on push to main)
- **Frontend**: ERB templates, Stimulus, Turbo
- **Styling**: Modern CSS with Propshaft asset pipeline
- **Testing**: RSpec
- **Authentication**: Custom session-based auth with Passkeys support
- **External APIs**: fixer.io (currency rates), Postmark (emails)
- **Scheduling**: `whenever` gem for cron tasks (balance updates, session cleanup)

## Key Features
- Multi-currency account tracking (MXN/USD)
- Automatic currency conversion using fixer.io
- Investment performance analytics (IRR, P&L reports)
- Balance history and trend visualization
- Email notifications for updates
- Passkey authentication
- Chart visualizations with D3.js
- Portfolio Statements (EDC) - cross-account reports by period

## Architecture & Important Concepts

### Core Models
- **User**: Main user account with settings
- **Account**: Investment accounts (savings, platforms like Bitso, Afluenta)
- **Balance**: Historical balance entries for accounts
- **CurrencyRate**: Exchange rates from fixer.io
- **Session**: Custom session management
- **Passkey**: WebAuthn credentials for passwordless auth

### Key Services
- **AccountReport**: Generates P&L and performance metrics for accounts
- **AccountsComparisonReport**: Aggregates data across multiple accounts
- **CurrencyConverter**: Handles MXN/USD conversions
- **UpdateBalance**: Updates account balances from external sources
- **Reports::PortfolioStatement**: Cross-account portfolio statements with per-currency breakdowns
- **Updaters (Bitso, Afluenta, etc.)**: Platform-specific balance fetchers

### Navigation Structure
**Main navigation** (bottom bar):
1. **Resumen** (`/`) - Investment summary dashboard
2. **Cuentas** (`/cuentas`) - Account listing
3. **Agregar** (`/saldos_faltantes`) - Add missing balances
4. **EDC** (`/reportes/estados_de_cuenta`) - Portfolio Statements
5. **Opciones** (`/opciones`) - User settings
6. **Salir** - Logout

**Account sub-navigation** (per-account pages):
1. **Resumen** (`/cuentas/:id`) - Monthly P&L summary table
2. **Detalle** (`/cuentas/:id/movimientos`) - Detailed movements and balances
3. **Estadísticas** (`/cuentas/:id/estadisticas`) - Charts, graphs, and statistics
4. **Opciones** (`/cuentas/:id/editar`) - Account settings

## Testing Standards
- **Framework**: RSpec with fixtures (not factories)
- **Structure**: Request specs for controllers, unit specs for models/services
- **Helpers**: Use `stub_current_user` for authentication in tests
- **Mocking**: Use `double()` for service objects with specific method expectations
- **Coverage**: Maintains test coverage with SimpleCov

## Development Workflow

### Running Tests
```bash
bundle exec rspec                    # All tests
bundle exec rspec spec/requests/     # Controller tests
bundle exec rspec spec/models/       # Model tests
bundle exec rspec spec/services/     # Service tests
```

### Code Quality & Linting
```bash
bundle exec standardrb               # Lint Ruby files
bundle exec standardrb --fix         # Auto-fix linting issues
```

### Development Server
```bash
rails server                        # Standard Rails server
bin/dev                             # Development with assets
```

### Key Commands
- `rails db:setup` - Initial database setup
- `rails db:migrate` - Run migrations
- `bin/importmap` - Manage JS dependencies
- `bin/kamal_db_pull` - Download production DB and restore locally

### Deployment Commands
```bash
kamal deploy              # Deploy latest code to production
kamal setup               # First-time server setup (installs Docker, starts PG, etc.)
kamal console             # Rails console in production
kamal logs                # Tail production logs
kamal db-console          # psql to production database
kamal db-dump             # Create pg_dump on the server (/tmp/latest.dump)
```

### Ruby Version Management
Ruby versions are managed via `.tool-versions` and **mise**. If you encounter Ruby version
mismatches when running commands, prefix them with `mise exec --`:
```bash
mise exec -- bundle install
mise exec -- bundle exec rspec
```

## Code Conventions

### Controllers
- Use service objects for complex business logic
- Keep controllers thin - delegate to services
- Return JSON for API endpoints, HTML for web pages
- Use `before_action :auth` for authentication

### Models
- Encrypt sensitive data with `lockbox` gem
- Use money-rails for currency handling
- ActiveRecord validations for data integrity
- Scopes for common queries

### Services
- Single responsibility classes in `app/services/`
- Initialize with required dependencies
- Public interface with descriptive method names
- Return structured data (hashes/objects)

### Views & Helpers
- ERB templates with minimal logic
- Helper methods for complex view logic
- Stimulus controllers for JavaScript interactions
- Modern CSS for styling with component-based organization

### Routing
- Spanish paths for user-facing URLs (`cuentas`, `movimientos`, etc.)
- RESTful nested resources
- JSON API endpoints under `/api/` (future consideration)

## External Integrations

### Currency Exchange (fixer.io)
- Daily USD/MXN rate fetching
- Automatic conversion for USD accounts
- Rate caching to minimize API calls

### Email (Postmark)
- Daily balance update notifications
- Login magic links
- User preference-based sending

### Platform Integrations
- **Bitso**: Cryptocurrency exchange
- **Afluenta**: P2P lending platform
- **Generic updaters**: For manual balance entry

## Security Considerations
- Encrypted sensitive data (account settings, API keys)
- Session-based authentication with secure tokens
- Passkey support for passwordless auth
- CSRF protection on all forms
- Environment-based secret management

## Environment Setup
Required credentials (stored in `credentials.yml.enc`):
- `fixer`: API key for currency exchange rates
- `auth_secret`: Session validation secret
- `postmark`: Email service API key
- `lockbox_master_key`: Encryption key for sensitive data at rest

### Production Environment Variables
Set via Kamal secrets (`.kamal/secrets`, not committed):
- `RAILS_MASTER_KEY` - Decrypts `credentials.yml.enc`
- `DINERITOS_DATABASE_PASSWORD` - PostgreSQL password
- `KAMAL_REGISTRY_PASSWORD` - GitHub PAT for ghcr.io
- `DATABASE_HOST` - PostgreSQL host (set to `dineritos-db` in Kamal)
- `WEBAUTHN_HOST` - WebAuthn allowed origin (`https://dineritos.mx`)

### Scheduled Tasks
Defined in `config/schedule.rb` using the `whenever` gem:
- **Daily at 5:00 AM CST**: `get_latest_balances` — updates all account balances
- **Monthly**: `remove_expired_sessions` — cleans up expired session records

Tasks run via cron on the server, executing `docker exec` into the app container.
Logs go to `/var/log/dineritos-cron.log` on the server.

### Key Deployment Files
- `config/deploy.yml` - Kamal deployment configuration
- `config/schedule.rb` - Cron schedule (whenever gem)
- `.kamal/secrets` - Secret references (NOT committed)
- `.kamal/hooks/post-deploy` - Updates crontab after each deploy
- `Dockerfile` - Production Docker image
- `.github/workflows/deploy.yml` - Auto-deploy workflow

## Common Tasks

### Adding a New Account Type
1. Add platform to `Account` model constants
2. Create updater service in `app/services/updaters/`
3. Add platform-specific settings encryption
4. Write tests for the new updater

### Adding New Reports
1. Create service in `app/services/`
2. Add controller action if needed
3. Create view template
4. Add navigation links if public-facing

### Database Changes
1. Generate migration: `rails g migration DescriptiveName`
2. Update model validations/associations
3. Add/update tests
4. Run migration: `rails db:migrate`

## Performance Notes
- Use database indexes on frequently queried columns
- Eager load associations to avoid N+1 queries
- Cache currency rates to minimize external API calls
- Background jobs for long-running balance updates (future consideration)

### Database Scripts
- `bin/update_db` - Downloads production DB from Heroku (transitional, will be removed)
- `bin/kamal_db_pull` - Downloads production DB via Kamal and restores locally

## Recent Changes
- **Kamal Migration**: Migrated deployment from Heroku to DigitalOcean with Kamal 2, Docker, and ghcr.io
- **Scheduled Tasks**: Added `whenever` gem for cron-based balance updates and session cleanup
- **Asset Pipeline Migration**: Migrated from Sprockets to Propshaft for Rails 8 compatibility
- **Modern CSS**: Converted SCSS files to modern CSS, leveraging CSS custom properties and native features
- **Ruby Version**: Updated to Ruby 3.4.7 with .tool-versions for mise compatibility
- Navigation reorganization: moved P&L content from separate page to main account summary
- **Portfolio Statements**: Added EDC (Estado de Cuenta) feature — cross-account reports by period with per-currency breakdowns, exchange rates, and MXN-aggregated totals
