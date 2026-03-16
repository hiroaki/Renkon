# Stream Architecture (Subscriptions UI)

## Purpose
This codebase uses a server-driven Turbo Stream approach for subscriptions and groups CRUD flows.
The goal is to keep UI state transitions consistent after writes (create/update/destroy).

## Current Policy
- Controllers decide outcome (success/failure, redirect vs turbo_stream).
- Stream payload construction is centralized in `SubscriptionsStreams`.
- Stimulus controllers handle post-update chained behavior (for example: select new item, refresh row, reload articles pane).

## Why This Direction
- Reduces duplicated stream fragments across controllers.
- Keeps subscriptions tree refresh behavior consistent for both subscription and group actions.
- Avoids split-brain logic where both server and client independently decide list refresh timing.

## Responsibility Split
### Server (Turbo Stream)
- Replace `subscriptions` frame after successful CRUD mutations.
- Close modal on success where policy says so.
- Reset dependent panes (`articles`, `contents`) when deletion requires it.
- Emit explicit DOM hook updates when a post-create client flow must run.

### Client (Stimulus)
- Run chained UI logic after server updates have landed.
- Keep selection state, focus behavior, and pane synchronization.
- Handle async follow-up requests (row refresh, status error presentation).

## Stream Building Rules
- Reuse concern methods; do not handcraft duplicate stream fragments in controllers.
- Use explicit method names that describe updated targets (for example: `subscriptions_reload_stream`).
- Keep concern methods pure (build stream only, no business/data mutation).

## Add/Change Checklist
1. Is this a write operation that should refresh subscriptions list?
2. Can existing concern stream helpers be reused?
3. If a new target is needed, add a helper in `SubscriptionsStreams` first.
4. Does the change require chained client behavior after stream apply?
5. Add or update request/system specs for the final UI state.

## Anti-Patterns to Avoid
- Reading request params in list views only to trigger client flow.
- Mixing server-driven refresh and client-driven refresh arbitrarily for the same action type.
- Embedding business logic inside stream builder concern methods.

## Related Files
- `app/controllers/concerns/subscriptions_streams.rb`
- `app/controllers/subscriptions_controller.rb`
- `app/controllers/groups_controller.rb`
- `app/javascript/controllers/subscription_create_success_controller.js`
- `app/views/subscriptions/_create_flow_trigger.html.erb`
