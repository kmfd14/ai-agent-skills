---
name: rails-saas-builder
description: Comprehensive Rails 8.1+ SaaS application development skill for building, reviewing, and implementing features in production-ready Ruby on Rails applications. Use this skill when (1) Building or implementing new features in a Rails SaaS application (e.g., "implement subscription billing", "build admin panel", "add multi-tenancy"), (2) Reviewing existing Rails application architecture, code quality, and best practices, (3) Implementing security patterns for multi-tenant SaaS applications, (4) Setting up Podman containerization for Rails apps, (5) Optimizing database schema and performance, (6) Building full-stack features with Hotwire/Stimulus or React, (7) Designing mobile-first responsive UI/UX with Tailwind CSS and DaisyUI, or (8) Any task involving professional Rails development with focus on security, performance, maintainability, and polished user interfaces.
---

# Rails SaaS Builder

Expert Rails 8.1+ development skill for building production-ready SaaS applications with emphasis on security, performance, maintainability, and mobile-first UI/UX.

## Implementation Workflow

Follow this systematic approach for all feature implementations and reviews:

### 1. Analyze Existing Structure

Before implementing any feature, analyze the existing codebase:

```bash
# Check Rails version and stack
cat Gemfile | grep "rails"
cat Gemfile | grep -E "(devise|sidekiq|hotwire|stimulus|react)"

# Review database schema
cat db/schema.rb

# Examine model structure
ls -la app/models/

# Review controller patterns
ls -la app/controllers/

# Check frontend approach
ls -la app/javascript/
```

**Key questions to understand:**
- What Rails patterns are currently used (service objects, concerns, etc.)?
- How is multi-tenancy implemented?
- What authentication/authorization is in place?
- Frontend stack: Hotwire/Stimulus or React?
- Background job setup?
- Payment provider integrations?

**Read references/architecture-review.md for complete review checklist.**

### 2. Clarify Implementation Details

Ask the user about specific implementation preferences:

- **Feature scope**: What exactly should be built?
- **User flow**: How should users interact with this feature?
- **Integration points**: How does this connect to existing features?
- **Payment provider**: Which provider for billing features (PayMongo, Maya, PayPal)?
- **Access control**: Who can use this feature? Any role restrictions?
- **Notifications**: Should users be notified? Email, in-app, or both?

### 3. Design Database Schema

Design migrations following best practices:

```ruby
class CreateFeature < ActiveRecord::Migration[8.1]
  def change
    create_table :features, id: :uuid do |t|
      # Multi-tenancy (ALWAYS include)
      t.references :tenant, type: :uuid, null: false, foreign_key: true, index: true
      
      # User association (if applicable)
      t.references :user, type: :uuid, null: false, foreign_key: true, index: true
      
      # Feature-specific columns
      t.string :name, null: false
      t.text :description
      t.string :status, null: false, default: 'active'
      
      # Metadata for flexibility
      t.jsonb :metadata, default: {}
      
      # Timestamps (ALWAYS include)
      t.timestamps
    end
    
    # Indexes for common queries
    add_index :features, :status
    add_index :features, [:tenant_id, :status]
  end
end
```

**Database design principles:**
- UUID primary keys (already configured)
- Multi-tenancy support on every tenant-scoped table
- Foreign key constraints
- Proper indexing (especially foreign keys, status fields, frequently queried columns)
- JSONB for flexible metadata
- Timestamps for audit trail

### 4. Implement Backend

#### Models
```ruby
class Feature < ApplicationRecord
  # Multi-tenancy (ALWAYS first)
  acts_as_tenant(:tenant)
  
  # Associations
  belongs_to :tenant
  belongs_to :user
  
  # Validations
  validates :name, presence: true
  validates :status, presence: true, inclusion: { in: %w[active inactive] }
  
  # Enums for state management
  enum status: { active: 'active', inactive: 'inactive' }
  
  # Scopes for common queries
  scope :active_features, -> { where(status: 'active') }
  scope :recent, -> { order(created_at: :desc) }
  
  # Callbacks (use sparingly)
  after_create :notify_creation
  
  private
  
  def notify_creation
    # Move heavy work to background jobs
    NotifyFeatureCreatedJob.perform_later(id)
  end
end
```

#### Service Objects (for complex logic)
```ruby
class Features::CreateService
  def initialize(user, params)
    @user = user
    @tenant = user.tenant
    @params = params
  end
  
  def call
    ActiveRecord::Base.transaction do
      feature = create_feature
      process_additional_logic(feature)
      feature
    end
  rescue => e
    Rails.logger.error("Feature creation failed: #{e.message}")
    raise
  end
  
  private
  
  def create_feature
    @tenant.features.create!(
      user: @user,
      name: @params[:name],
      description: @params[:description]
    )
  end
  
  def process_additional_logic(feature)
    # Additional business logic here
  end
end
```

#### Controllers
```ruby
class FeaturesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_feature, only: [:show, :edit, :update, :destroy]
  
  def index
    @features = current_tenant.features
                              .includes(:user)
                              .order(created_at: :desc)
                              .page(params[:page])
    authorize @features
  end
  
  def show
    authorize @feature
  end
  
  def create
    service = Features::CreateService.new(current_user, feature_params)
    @feature = service.call
    
    authorize @feature
    
    respond_to do |format|
      format.html { redirect_to @feature, notice: 'Feature created successfully.' }
      format.turbo_stream
    end
  rescue => e
    respond_to do |format|
      format.html { 
        flash.now[:alert] = e.message
        render :new, status: :unprocessable_entity 
      }
      format.turbo_stream { 
        render turbo_stream: turbo_stream.replace('feature_form', 
          partial: 'features/form', 
          locals: { feature: @feature, error: e.message })
      }
    end
  end
  
  private
  
  def set_feature
    @feature = current_tenant.features.find(params[:id])
  end
  
  def feature_params
    params.require(:feature).permit(:name, :description, :status)
  end
end
```

**Read references/feature-patterns.md for complete implementation examples including subscription billing and admin panels.**

### 5. Implement Frontend

#### Views (Hotwire + Stimulus)
```erb
<!-- app/views/features/index.html.erb -->
<div class="container mx-auto px-4 py-8" data-controller="features">
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-3xl font-bold">Features</h1>
    <%= link_to "New Feature", new_feature_path, 
        class: "btn btn-primary",
        data: { turbo_frame: "modal" } %>
  </div>
  
  <%= turbo_frame_tag "features" do %>
    <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
      <%= render @features %>
    </div>
  <% end %>
</div>

<!-- app/views/features/_feature.html.erb -->
<%= turbo_frame_tag dom_id(feature) do %>
  <div class="card bg-white shadow-md rounded-lg p-6 hover:shadow-lg transition">
    <h3 class="text-xl font-semibold mb-2"><%= feature.name %></h3>
    <p class="text-gray-600 mb-4"><%= feature.description %></p>
    
    <div class="flex gap-2">
      <%= link_to "View", feature_path(feature), class: "btn btn-secondary btn-sm" %>
      <%= link_to "Edit", edit_feature_path(feature), 
          class: "btn btn-secondary btn-sm",
          data: { turbo_frame: "modal" } %>
      <%= button_to "Delete", feature_path(feature), 
          method: :delete,
          class: "btn btn-danger btn-sm",
          data: { 
            turbo_confirm: "Are you sure?",
            turbo_frame: dom_id(feature)
          } %>
    </div>
  </div>
<% end %>
```

#### Stimulus Controllers
```javascript
// app/javascript/controllers/features_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "list"]
  
  connect() {
    console.log("Features controller connected")
  }
  
  // Real-time search
  search(event) {
    const query = event.target.value
    clearTimeout(this.timeout)
    
    this.timeout = setTimeout(() => {
      const url = new URL(window.location.href)
      url.searchParams.set('query', query)
      
      fetch(url, {
        headers: { 'Accept': 'text/vnd.turbo-stream.html' }
      })
    }, 300)
  }
  
  // Handle form submission
  submitEnd(event) {
    if (event.detail.success) {
      this.closeModal()
    }
  }
  
  closeModal() {
    const modal = document.getElementById('modal')
    modal?.remove()
  }
}
```

#### Mobile-First CSS (Tailwind + DaisyUI)

**DaisyUI provides pre-built components that work seamlessly with Tailwind CSS.**

Use DaisyUI components for rapid development:
```erb
<!-- Buttons -->
<%= button_to "Submit", path, class: "btn btn-primary" %>

<!-- Cards -->
<div class="card bg-base-100 shadow-xl">
  <div class="card-body">
    <h2 class="card-title">Card Title</h2>
    <p>Content here</p>
  </div>
</div>

<!-- Forms -->
<div class="form-control w-full">
  <%= f.label :name, class: "label" do %>
    <span class="label-text">Name</span>
  <% end %>
  <%= f.text_field :name, class: "input input-bordered w-full" %>
</div>

<!-- Alerts -->
<div class="alert alert-success">
  <span>Success message</span>
</div>
```

**Responsive Design Principles:**
- Use Tailwind's responsive breakpoints: `sm:`, `md:`, `lg:`, `xl:`, `2xl:`
- Mobile-first approach: base styles for mobile, then scale up
- Touch-friendly: minimum 44x44px tap targets (DaisyUI buttons are touch-optimized)
- Grid layouts: `grid-cols-1 md:grid-cols-2 lg:grid-cols-3`
- Test on actual mobile devices

**Read references/tailwind-daisyui-design.md for comprehensive component examples, responsive patterns, and mobile optimization techniques.**

### 6. Security Implementation

**CRITICAL: Security must be verified at every step.**

#### Multi-tenancy Isolation
```ruby
# ALWAYS scope queries to current tenant
class ApplicationController < ActionController::Base
  set_current_tenant_through_filter
  before_action :set_tenant
  
  def set_tenant
    if current_user
      set_current_tenant(current_user.tenant)
    else
      set_current_tenant(nil)
    end
  end
end

# NEVER write queries like this:
Feature.find(params[:id])  # ❌ DANGEROUS - no tenant scoping

# ALWAYS write queries like this:
current_tenant.features.find(params[:id])  # ✅ SAFE - tenant scoped
```

#### Authorization (Pundit)
```ruby
# app/policies/feature_policy.rb
class FeaturePolicy < ApplicationPolicy
  def index?
    user.present?
  end
  
  def show?
    record.tenant_id == user.tenant_id
  end
  
  def create?
    user.present? && user.tenant_id.present?
  end
  
  def update?
    show? && (record.user_id == user.id || user.admin?)
  end
  
  def destroy?
    update?
  end
end
```

**Read references/security-practices.md for comprehensive security patterns including encryption, API security, GDPR compliance, and payment security for Philippine providers.**

### 7. Background Jobs

Use Sidekiq for heavy operations:

```ruby
# app/jobs/process_feature_job.rb
class ProcessFeatureJob < ApplicationJob
  queue_as :default
  
  def perform(feature_id, tenant_id)
    # Set tenant context for multi-tenancy
    ActsAsTenant.with_tenant(Tenant.find(tenant_id)) do
      feature = Feature.find(feature_id)
      # Process feature
    end
  end
end

# Usage in controller/service
ProcessFeatureJob.perform_later(feature.id, current_tenant.id)
```

### 8. Testing

Write tests for critical paths:

```ruby
# test/models/feature_test.rb
require "test_helper"

class FeatureTest < ActiveSupport::TestCase
  test "should not save feature without name" do
    feature = Feature.new
    assert_not feature.save
  end
  
  test "should belong to tenant" do
    feature = features(:one)
    assert_equal tenants(:one), feature.tenant
  end
  
  test "should scope to tenant" do
    tenant = tenants(:one)
    ActsAsTenant.with_tenant(tenant) do
      assert_equal 2, Feature.count
    end
  end
end

# test/controllers/features_controller_test.rb
require "test_helper"

class FeaturesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @feature = features(:one)
  end
  
  test "should get index" do
    get features_url
    assert_response :success
  end
  
  test "should create feature" do
    assert_difference("Feature.count") do
      post features_url, params: { 
        feature: { name: "Test Feature", description: "Test" } 
      }
    end
    assert_redirected_to feature_url(Feature.last)
  end
end
```

### 9. Deployment with Podman

Create test environment:

```bash
# Build image
podman build -t myapp:test .

# Run test container
podman run -d \
  --name myapp_test \
  -p 3001:3000 \
  -e RAILS_ENV=test \
  -e DATABASE_URL="postgresql://user:pass@host.containers.internal:5432/myapp_test" \
  myapp:test

# Run tests in container
podman exec myapp_test bundle exec rails test

# Check logs
podman logs -f myapp_test

# Clean up
podman stop myapp_test
podman rm myapp_test
```

**Read references/deployment-podman.md for complete Podman setup including production deployment, systemd services, zero-downtime deployments, and monitoring.**

## Code Quality Standards

### Maintainability for Junior Developers

1. **Clear naming**: Use descriptive variable and method names
2. **Comments**: Explain "why", not "what"
3. **Small methods**: Keep methods under 10 lines when possible
4. **Single responsibility**: Each class/method does one thing
5. **Consistent patterns**: Follow established codebase patterns
6. **Documentation**: Add README for complex features

### Rails Best Practices

1. **Thin controllers**: Move logic to models/services
2. **Service objects**: Extract complex business logic
3. **Concerns**: Share behavior across models
4. **Avoid callbacks**: Use explicit service calls
5. **Query optimization**: Eager load associations
6. **Database indexes**: Index foreign keys and query fields

### Performance Optimization

1. **N+1 queries**: Use `includes`, `preload`, `eager_load`
2. **Database indexes**: Critical for foreign keys and WHERE clauses
3. **Caching**: Fragment caching, Russian doll caching
4. **Background jobs**: Offload slow operations
5. **Asset optimization**: Minimize, compress, CDN
6. **Database connection pooling**: Configure properly

## Technology Stack

### Default Stack
- Rails 8.1.2
- Ruby 3.3+
- PostgreSQL (non-containerized)
- Hotwire (Turbo + Stimulus)
- Tailwind CSS + DaisyUI
- Sidekiq for background jobs
- Podman for containerization

### Authentication & Authorization
- Devise for authentication
- Pundit or CanCanCan for authorization
- acts_as_tenant for multi-tenancy

### Payment Providers (Philippines)
- **Local**: PayMongo, Maya (PayMaya)
- **International**: PayPal

### Alternative Frontend
When React is preferred:
- Use `rails new --javascript=esbuild` or Vite
- Keep API endpoints RESTful
- Use Jbuilder for JSON responses
- Consider separate frontend deployment if needed

## Bundled Resources

### References
- **architecture-review.md**: Comprehensive checklist for reviewing Rails application structure
- **security-practices.md**: Security patterns for multi-tenant SaaS including encryption, auth, API security, GDPR, and Philippine payment providers
- **deployment-podman.md**: Complete Podman containerization guide with production deployment, systemd services, and monitoring
- **feature-patterns.md**: Detailed implementation patterns for common features like subscription billing and admin panels
- **tailwind-daisyui-design.md**: Complete UI/UX design guide with Tailwind CSS and DaisyUI components, responsive patterns, mobile-first design, and accessibility best practices

## Common Features Quick Reference

### Subscription Billing
- Models: Subscription, Payment
- Service: SubscriptionService
- Jobs: ProcessSubscriptionRenewalJob
- Webhooks: PayMongo, Maya, PayPal
- See references/feature-patterns.md for complete implementation

### Admin Panel
- Models: AdminUser, SupportRequest
- Controllers: Admin::BaseController, Admin::DashboardController
- Authorization: Role-based with Pundit
- See references/feature-patterns.md for complete implementation

### Multi-tenancy
- Use acts_as_tenant gem
- Scope all queries: `current_tenant.resources.find(id)`
- Add tenant_id to all tenant-scoped tables
- Test isolation thoroughly

### API Development
- Namespace: `Api::V1::ResourcesController`
- Authentication: JWT tokens
- Rate limiting: rack-attack
- Versioning: URL-based (/api/v1/)
- Documentation: Consider Swagger/OpenAPI

## Key Reminders

- **Multi-tenancy first**: ALWAYS scope queries to current tenant
- **Security**: Verify authorization on every action
- **Performance**: Optimize queries, add indexes, use background jobs
- **Mobile-first**: Ensure responsive design, touch-friendly UI
- **Maintainability**: Write clear code that junior devs can understand
- **Testing**: Test critical paths, multi-tenancy isolation
- **Deployment**: Test in Podman before production deployment
