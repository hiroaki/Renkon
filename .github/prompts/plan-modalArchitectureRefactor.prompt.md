## Plan: Modal Architecture Refactor

Current modal behavior is spread across multiple views and tightly coupled to Turbo Stream targets. The recommended approach is to refactor in phases: first centralize modal rendering (single host + shared shell), then centralize modal stream assembly (single concern/service boundary), and finally simplify controller actions and tests. Backward compatibility is intentionally out of scope.

**Steps**
1. Phase 1: Establish a single modal rendering architecture.
2. Create one shared modal shell partial for overlay, dialog container, close controls, and modal Stimulus bindings. The shell must own all markup now duplicated in subscription/group new/edit views. *blocks step 3-6*
3. Convert subscription modal views to the shared shell by moving only screen-specific content into body blocks/partials. Include create, edit, and success modal paths. *depends on 2*
4. Convert group modal views to the shared shell with the same API shape used in subscription views. *depends on 2, parallel with 3 once shell API is fixed*
5. Remove inline modal frame declarations from feature views so modal rendering is always mediated by one shared path. *depends on 3 and 4*
6. Phase 2: Centralize Turbo Stream modal operations.
7. Replace ad-hoc stream arrays in controllers with a single stream builder boundary (keep it in the existing concern or move to a dedicated service). Stream builder must expose composable operations for subscriptions reload, modal close, create-flow trigger, articles reset, contents reset. *depends on 3-5*
8. Standardize target naming in one place (constants or helper methods) so stream targets are not duplicated string literals across concerns/views/controllers. *depends on 7*
9. Refactor SubscriptionsController create/update/destroy and GroupsController create/update/destroy to use the centralized stream composition path. Remove duplicated action-level stream assembly logic. *depends on 7-8*
10. Phase 3: Simplify modal behavior ownership.
11. Define explicit ownership boundaries: view shell handles structure/accessibility, modal Stimulus handles open/close/focus lifecycle, controllers only decide success/failure and call stream builder. Remove mixed responsibilities in templates where possible. *depends on 9*
12. Review and simplify modal event wiring so close behavior is predictable for cancel, Escape, overlay click, and successful submit. Keep only required events and remove redundant bindings. *depends on 11*
13. Phase 4: Verification and cleanup.
14. Update request/system specs affected by modal rendering and stream composition changes; ensure tests assert target updates and modal lifecycle behavior explicitly. *depends on 9-12*
15. Remove obsolete partials/branches and dead paths from views/controllers after all tests pass. *depends on 14*

**Relevant files**
- app/views/layouts/viewport_full.erb — current modal host frame.
- app/views/subscriptions/new.html.erb — duplicated modal wrapper to replace.
- app/views/subscriptions/edit.html.erb — duplicated modal wrapper to replace.
- app/views/subscriptions/_success_modal.html.erb — success flow modal to integrate into shared shell API.
- app/views/groups/new.html.erb — duplicated modal wrapper to replace.
- app/views/groups/edit.html.erb — duplicated modal wrapper to replace.
- app/views/subscriptions/main.html.erb — create-flow hook and modal-trigger entry points.
- app/controllers/concerns/subscriptions_streams.rb — stream composition boundary to centralize.
- app/controllers/subscriptions_controller.rb — create/update/destroy stream call sites.
- app/controllers/groups_controller.rb — create/update/destroy stream call sites.
- app/javascript/controllers/modal_controller.js — modal lifecycle behavior.
- app/javascript/controllers/subscription_create_success_controller.js — post-create follow-up behavior coupling.
- spec/requests/subscriptions/create_spec.rb — request-level stream assertions.
- spec/requests/subscriptions/update_spec.rb — request-level stream assertions.
- spec/requests/groups/create_spec.rb — request-level stream assertions.
- spec/requests/groups/update_spec.rb — request-level stream assertions.
- spec/requests/groups/destroy_spec.rb — request-level stream assertions.
- spec/system/subscriptions_spec.rb — end-to-end modal behavior.

**Verification**
1. Run targeted request specs for group/subscription CRUD stream responses: bin/rspec spec/requests/subscriptions/create_spec.rb spec/requests/subscriptions/update_spec.rb spec/requests/groups/create_spec.rb spec/requests/groups/update_spec.rb spec/requests/groups/destroy_spec.rb.
2. Run modal-centric system coverage: bin/rspec spec/system/subscriptions_spec.rb.
3. Run adjacent regression checks for pane behavior affected by stream updates: bin/rspec spec/system/subscriptions_selection_spec.rb spec/system/articles_spec.rb.
4. Manual check in browser: open each modal from main page and subscriptions index; verify overlay close, Escape close, cancel close, successful submit close, validation error keeps modal open.
5. Manual check after create/destroy: subscriptions pane reloads, create-flow hook behavior still runs, and articles/contents panes reset where expected.

**Decisions**
- Included scope: modal view architecture, stream composition architecture, modal lifecycle wiring, and test updates.
- Excluded scope: backward compatibility with the old modal API/DOM structure.
- Excluded scope: redesign of non-modal pane architecture and sortable/tree behaviors outside modal side effects.
- Preferred migration style: phased refactor with test gates at each phase, not one-shot replacement.

**Further Considerations**
1. Keep stream composition in the concern vs move to service object. Recommendation: start in concern for low overhead; extract to service only if concern grows again.
2. Shared modal body API style. Recommendation: use block-based rendering to keep feature templates readable and avoid locals explosion.
3. Modal close semantics source of truth. Recommendation: treat server turbo stream close as authoritative; use client-side close only for explicit user actions (cancel/overlay/Escape).
