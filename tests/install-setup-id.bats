#!/usr/bin/env bats

setup() {
  export TEST_ROOT="$BATS_TEST_TMPDIR/case-$BATS_TEST_NUMBER"
  export HOME="$TEST_ROOT/home"
  export XDG_CONFIG_HOME="$TEST_ROOT/config"
  export GITKB_INSTALLER_LIB_ONLY=1
  mkdir -p "$HOME" "$XDG_CONFIG_HOME"
  # shellcheck source=../install.sh
  source "$BATS_TEST_DIRNAME/../install.sh"
}

file_mode() {
  stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1"
}

@test "persists a valid UUID without printing it and with owner-only permissions" {
  export GITKB_SETUP_ID="550e8400-e29b-41d4-a716-446655440000"

  run persist_setup_id

  [ "$status" -eq 0 ]
  [ -z "$output" ]
  [ "$(cat "$XDG_CONFIG_HOME/gitkb/setup-id")" = "$GITKB_SETUP_ID" ]
  [ "$(file_mode "$XDG_CONFIG_HOME/gitkb/setup-id")" = "600" ]
  [ "$(file_mode "$XDG_CONFIG_HOME/gitkb")" = "700" ]
}

@test "preserves the first valid pending ID across an upgrade" {
  mkdir -p "$XDG_CONFIG_HOME/gitkb"
  printf '%s\n' "6ba7b810-9dad-41d1-80b4-00c04fd430c8" > "$XDG_CONFIG_HOME/gitkb/setup-id"
  chmod 600 "$XDG_CONFIG_HOME/gitkb/setup-id"
  export GITKB_SETUP_ID="550e8400-e29b-41d4-a716-446655440000"

  persist_setup_id

  [ "$(cat "$XDG_CONFIG_HOME/gitkb/setup-id")" = "6ba7b810-9dad-41d1-80b4-00c04fd430c8" ]
  [ "$(file_mode "$XDG_CONFIG_HOME/gitkb/setup-id")" = "600" ]
}

@test "ignores malformed and non-v4 identifiers" {
  export GITKB_SETUP_ID="x'; touch /tmp/pwned; #"
  persist_setup_id
  [ ! -e "$XDG_CONFIG_HOME/gitkb/setup-id" ]

  export GITKB_SETUP_ID="550e8400-e29b-11d4-a716-446655440000"
  persist_setup_id
  [ ! -e "$XDG_CONFIG_HOME/gitkb/setup-id" ]
}

@test "refuses a symlink target without modifying its destination" {
  mkdir -p "$XDG_CONFIG_HOME/gitkb"
  printf 'sentinel\n' > "$TEST_ROOT/target"
  ln -s "$TEST_ROOT/target" "$XDG_CONFIG_HOME/gitkb/setup-id"
  export GITKB_SETUP_ID="550e8400-e29b-41d4-a716-446655440000"

  run persist_setup_id

  [ "$status" -eq 0 ]
  [ "$(cat "$TEST_ROOT/target")" = "sentinel" ]
  [[ "$output" != *"$GITKB_SETUP_ID"* ]]
}

@test "refuses to replace an insecure existing regular file" {
  mkdir -p "$XDG_CONFIG_HOME/gitkb"
  printf 'sentinel\n' > "$XDG_CONFIG_HOME/gitkb/setup-id"
  chmod 644 "$XDG_CONFIG_HOME/gitkb/setup-id"
  export GITKB_SETUP_ID="550e8400-e29b-41d4-a716-446655440000"

  run persist_setup_id

  [ "$status" -eq 0 ]
  [ "$(cat "$XDG_CONFIG_HOME/gitkb/setup-id")" = "sentinel" ]
  [ "$(file_mode "$XDG_CONFIG_HOME/gitkb/setup-id")" = "644" ]
  [[ "$output" != *"$GITKB_SETUP_ID"* ]]
}

@test "refuses to replace a non-regular target" {
  mkdir -p "$XDG_CONFIG_HOME/gitkb/setup-id"
  printf 'sentinel\n' > "$XDG_CONFIG_HOME/gitkb/setup-id/child"
  export GITKB_SETUP_ID="550e8400-e29b-41d4-a716-446655440000"

  run persist_setup_id

  [ "$status" -eq 0 ]
  [ "$(cat "$XDG_CONFIG_HOME/gitkb/setup-id/child")" = "sentinel" ]
  [[ "$output" != *"$GITKB_SETUP_ID"* ]]
}

@test "falls back to HOME when XDG_CONFIG_HOME is relative" {
  export XDG_CONFIG_HOME="relative"
  export GITKB_SETUP_ID="550e8400-e29b-41d4-a716-446655440000"

  persist_setup_id

  [ "$(cat "$HOME/.config/gitkb/setup-id")" = "$GITKB_SETUP_ID" ]
}

@test "refuses a symlinked configuration home without modifying its destination" {
  local redirected="$TEST_ROOT/redirected"
  mkdir -p "$redirected"
  rmdir "$XDG_CONFIG_HOME"
  ln -s "$redirected" "$XDG_CONFIG_HOME"
  export GITKB_SETUP_ID="550e8400-e29b-41d4-a716-446655440000"

  run persist_setup_id

  [ "$status" -eq 0 ]
  [ ! -e "$redirected/gitkb/setup-id" ]
  [[ "$output" != *"$GITKB_SETUP_ID"* ]]
}

@test "restores the caller umask after persistence" {
  export GITKB_SETUP_ID="550e8400-e29b-41d4-a716-446655440000"
  umask 0022
  local before
  local after
  before="$(umask)"

  persist_setup_id
  after="$(umask)"

  [ "$after" = "$before" ]
}
