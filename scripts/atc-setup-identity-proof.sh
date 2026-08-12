#!/usr/bin/env bash
set -uo pipefail

proof_log=$(mktemp "${TMPDIR:-/tmp}/gitkb-installer-setup-identity-proof.XXXXXX") || exit 1
proof_dir=$(mktemp -d "${TMPDIR:-/tmp}/gitkb-installer-setup-identity.XXXXXX") || exit 1
trap 'rm -f "$proof_log"; rm -rf "$proof_dir"' EXIT INT TERM

status=passed
if ! bash -n install.sh >"$proof_log" 2>&1; then
  status=failed
else
  printf 'bash syntax: passed\n' >>"$proof_log"
fi
if ! HOME="$proof_dir/home" \
  XDG_CONFIG_HOME="$proof_dir/config" \
  GITKB_INSTALLER_LIB_ONLY=1 \
  GITKB_SETUP_ID=550e8400-e29b-41d4-a716-446655440000 \
  bash -c '
    set -eu
    mkdir -p "$HOME" "$XDG_CONFIG_HOME"
    . ./install.sh
    persist_setup_id
    test "$(cat "$XDG_CONFIG_HOME/gitkb/setup-id")" = "$GITKB_SETUP_ID"
    case "$(stat -c %a "$XDG_CONFIG_HOME/gitkb/setup-id" 2>/dev/null || stat -f %Lp "$XDG_CONFIG_HOME/gitkb/setup-id")" in 600) ;; *) exit 1 ;; esac
  ' >>"$proof_log" 2>&1; then
  status=failed
else
  printf 'secure persistence: passed\n' >>"$proof_log"
fi

if command -v sha256sum >/dev/null 2>&1; then
  evidence_sha=$(sha256sum "$proof_log" | awk '{print $1}')
else
  evidence_sha=$(shasum -a 256 "$proof_log" | awk '{print $1}')
fi

printf '{"acceptance_target":"gitkb-installer-setup-identity-v1","disposable":true,"evidence_sha256":"%s","schema_version":1,"status":"%s","summary":"installer setup identity shell and persistence proof %s"}\n' \
  "$evidence_sha" "$status" "$status"

test "$status" = passed
