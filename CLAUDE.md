# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this app is

bbb-app-rooms is a Rails 6.1 LTI tool that provides BigBlueButton rooms to LMSs (Moodle, Canvas, etc.). It does **not** speak LTI directly — it sits behind [bbb-lti-broker](https://github.com/bigbluebutton/bbb-lti-broker), which handles the LTI handshake and hands off to this app via OmniAuth (`omniauth-bbbltibroker` strategy). Running it locally requires a broker and typically the [bbb-lti-run](https://github.com/blindsidenetworks/bbb-lti-run) docker-compose environment (see README.md for the full setup).

## Commands

```bash
bundle install                  # Ruby deps (Ruby 3.1.4 in CI; PostgreSQL required)
yarn install                    # JS deps (webpacker 6 + Tailwind)

bundle exec rake db:setup       # create/migrate/seed (uses DATABASE_URL or config/database.yml)

bundle exec rspec               # run the test suite (spec/ — CI runs this)
bundle exec rspec spec/controllers/rooms_spec.rb        # single file
bundle exec rspec spec/controllers/rooms_spec.rb:42     # single example

bundle exec rubocop             # lint (CI enforces; config in .rubocop.yml)

rails s -b 0.0.0.0 -p 3012      # dev server (README's dev flow pairs it with the broker on 3011)
```

Environment comes from a `.env` file (dotenv-rails); copy `dotenv` to `.env` as a template. Key vars: `BIGBLUEBUTTON_ENDPOINT`/`BIGBLUEBUTTON_SECRET`, `OMNIAUTH_BBBLTIBROKER_SITE`/`_ROOT`/`_KEY`/`_SECRET`, `URL_HOST`, `RELATIVE_URL_ROOT` (usually `apps`), `SECRET_KEY_BASE`.

Tests live in `spec/` (RSpec + FactoryBot + webmock). The `test/` directory is leftover minitest scaffolding — CI does not run it; put new tests in `spec/`.

## Architecture

### Launch flow (the core path)

1. LMS launches the tool through the broker; broker redirects here with a `launch_nonce`.
2. `SessionsController#create` (OmniAuth callback at `/rooms/auth/bbbltibroker/callback`) stores the authenticated `uid` in the Rails session keyed by `launch_nonce`.
3. `RoomsController#launch` (`POST /rooms/launch`) calls back to the broker REST API (`/api/v1/sessions/:launch_nonce`, OAuth2 client-credentials token) to pull the full LTI launch params, then finds-or-creates the `Room` and stores the user's launch params in the session keyed by the room's `handler`.
4. Subsequent requests hit `set_room`, which loads the room by `:handler` and rebuilds `@user` (`BbbAppRooms::User`, a plain Ruby object in `lib/bbb_app_rooms/` — there is no users table; identity exists only in the session).

### Key pieces

- **`Room`** (the only ActiveRecord model): one row per LTI resource, identified by `handler` (a SHA1; `to_param` returns it, so all URL helpers use `/rooms/:handler`). Meeting/lock options (`record`, `guestPolicy`, `allModerators`, `lockSettings*`, etc.) live in the JSON `settings` column via `store_accessor`. A room may have a shared code pointing at another room; `set_chosen_room` in `RoomsController` swaps in the shared room, and most BBB operations act on `@chosen_room` rather than `@room`.
- **`BbbHelper`** (`app/controllers/concerns/bbb_helper.rb`): all BigBlueButton API interaction — create/join meeting URLs, recordings (paginated via pagy), publish/protect/delete — through the `bigbluebutton-api-ruby` gem. Recordings and meeting info are cached in `Rails.cache` when `CACHE_ENABLED`.
- **`Bbb::Credentials`** (`lib/bbb/credentials.rb`): resolves BBB endpoint/secret per tenant. Single-tenant installs use `BIGBLUEBUTTON_ENDPOINT`/`SECRET` env vars; multitenant installs fetch per-tenant credentials from the broker's tenants API and cache them.
- **`BrokerHelper` / `OmniauthHelper`**: REST calls to the broker (tenant settings such as `enable_shared_rooms`, `handler_params`) and OmniAuth URL/token plumbing. Tenant settings gate features, so behavior can differ per tenant at runtime.
- **ActionCable** (`MeetingInfoChannel` + `NotifyMeetingWatcherJob`): clients on the room page subscribe with the room handler; the job polls BBB and broadcasts meeting status so the page updates (join button, participant info) without refreshing. `Room#broadcast_room_start` also broadcasts on a `wait_channel:room_<id>` stream. Redis-backed in production.
- **Errors**: `RoomsError::CustomError` (`lib/rooms_error/error.rb`) carries `{code, message, key}`; controllers rescue it and render the shared `error` view. Non-launch failures also flow through `set_error` + `ErrorsController`.
- **Routing**: everything is under the `rooms` scope (plus `RELATIVE_URL_ROOT` prefix in deployment, e.g. `/apps/rooms/...`). Meeting and recording actions are member-style routes under `/:handler/`.
- **Presentation upload**: ActiveStorage (`has_one_attached :presentation`), stored in GCS/S3-compatible storage in production (`config/storage.yml`), passed to BBB as the meeting's pre-upload document.

### Things that aren't obvious

- The app is designed to render inside an LMS iframe: `allow_iframe_requests` strips `X-Frame-Options`, and session cookies must survive third-party-cookie restrictions.
- Sessions are DB-backed (`activerecord-session_store`), not cookie-backed.
- `handler` vs `handler_legacy`: `Room#handler` returns `handler_legacy` when present, to keep pre-existing rooms resolvable after the handler scheme changed.
- Deployment is Docker-based (Dockerfile + `scripts/start.sh`); GitHub Actions builds images on push/release, and `cloudbuild*.yaml` cover a GCP pipeline.
