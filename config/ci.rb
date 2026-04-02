# Run using bin/ci
#
# This local CI is organized around three principles:
# - Keep fast host-side checks first so routine feedback stays quick.
# - Run only the local prerequisites needed for host-side checks, rather than
#   reusing the broader development setup flow.
# - Use a staging Docker image boot check to catch deployment-only failures
#   that do not appear in development or test, such as missing runtime gems.

CI.run do
  step "Setup: Local test prerequisites", <<~SH
    bundle check || bundle install
    env RAILS_ENV=test bin/rails db:prepare
  SH

  step "Security: Importmap vulnerability audit", "bin/importmap audit"
  step "Tests: RSpec", "bin/rspec"

  step "Boot: Staging image", <<~SH
    docker build --build-arg RAILS_ENV=staging -t renkon-staging-check .
    docker run --rm \
      -e RAILS_ENV=staging \
      -e SECRET_KEY_BASE_DUMMY=1 \
      --entrypoint bin/rails \
      renkon-staging-check \
      runner 'Rails.application.eager_load!; puts :ok'
  SH

  # Optional: Re-enable if test seeds become part of the supported setup.
  # step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"

  # Optional: Split slower system specs into a dedicated CI step later.
  # step "Tests: System specs", "bin/rspec spec/system"

  # Optional: Add static/security analysis if these tools are adopted.
  # step "Security: Brakeman", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
  # step "Style: Ruby", "bin/rubocop"

  # Optional: If merge readiness is gated through local CI, enable GitHub signoff.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
