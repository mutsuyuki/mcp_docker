#!/usr/bin/env bash
set -Eeuo pipefail

ssh_session_usage() {
  cat >&2 <<'USAGE'
usage: ssh_session.sh user@host
USAGE
  exit 1
}

ssh_session_detect_local_user() {
  if [[ -n "${USER:-}" ]]; then
    printf '%s\n' "$USER"
    return 0
  fi
  id -un
}

ssh_session_detect_local_home() {
  local local_user="$1"

  if [[ -n "${HOME:-}" ]]; then
    printf '%s\n' "$HOME"
    return 0
  fi

  local home_from_passwd=""
  if command -v getent >/dev/null 2>&1; then
    home_from_passwd="$(getent passwd "$local_user" | cut -d: -f6 || true)"
  fi

  if [[ -z "$home_from_passwd" ]]; then
    home_from_passwd="$(awk -F: -v u="$local_user" '$1 == u { print $6; exit }' /etc/passwd 2>/dev/null || true)"
  fi

  if [[ -z "$home_from_passwd" ]]; then
    echo "Failed to determine HOME for user '$local_user'" >&2
    return 1
  fi

  printf '%s\n' "$home_from_passwd"
}

ssh_session_init_common() {
  local host_name="$1"
  local session_kind="${2:-normal}"

  if [[ -z "$host_name" ]]; then
    echo "HOST_NAME is empty" >&2
    return 1
  fi

  HOST_NAME="$host_name"
  SESSION_KIND="$session_kind"

  LOCAL_USER="$(ssh_session_detect_local_user)"
  LOCAL_HOME="$(ssh_session_detect_local_home "$LOCAL_USER")"

  SAFE_NAME="$(printf '%s' "$HOST_NAME" | sed 's/[^a-zA-Z0-9_.-]/_/g')"
  SUDOERS_SAFE_NAME="$(printf '%s' "$HOST_NAME" | sed 's/[^a-zA-Z0-9_-]/_/g')"

  SESSION_BASE_DIR="/tmp/ssh-llm-${LOCAL_USER}"
  CTL_DIR="${SESSION_BASE_DIR}/control"
  WRAPPER_DIR="${SESSION_BASE_DIR}/bin"

  CTL_PATH="${CTL_DIR}/${SAFE_NAME}.${SESSION_KIND}"
  WRAPPER="${WRAPPER_DIR}/ssh_llm_${SAFE_NAME}_${SESSION_KIND}"

  mkdir -p "$CTL_DIR" "$WRAPPER_DIR"
  chmod 700 "$SESSION_BASE_DIR" "$CTL_DIR" "$WRAPPER_DIR"
}

ssh_session_create_wrapper() {
  cat > "$WRAPPER" <<EOF
#!/usr/bin/env bash
set -Eeuo pipefail
exec ssh \\
  -o ControlMaster=no \\
  -o BatchMode=yes \\
  -o ControlPath="$CTL_PATH" \\
  "$HOST_NAME" "\$@"
EOF
  chmod 700 "$WRAPPER"
}

ssh_session_remove_wrapper() {
  rm -f "$WRAPPER" >/dev/null 2>&1 || true
}

ssh_session_master_is_alive() {
  ssh \
    -o BatchMode=yes \
    -o ControlMaster=no \
    -o ControlPath="$CTL_PATH" \
    -O check \
    "$HOST_NAME" >/dev/null 2>&1
}

ssh_session_close_master() {
  ssh \
    -o BatchMode=yes \
    -o ControlMaster=no \
    -o ControlPath="$CTL_PATH" \
    -O exit \
    "$HOST_NAME" >/dev/null 2>&1 || true
}

ssh_session_close_existing_master() {
  ssh_session_close_master
}

ssh_session_cleanup_common() {
  ssh_session_close_master
  ssh_session_remove_wrapper
}

ssh_session_print_common_info() {
  local extra_example="${1:-}"

  echo "接続を開始します。認証が必要ならSSHが表示します。"
  echo
  echo "local user   : $LOCAL_USER"
  echo "local home   : $LOCAL_HOME"
  echo "session kind : $SESSION_KIND"
  echo "session base : $SESSION_BASE_DIR"
  echo "control path : $CTL_PATH"
  echo "wrapper      : $WRAPPER"
  echo
  echo "セッション中は以下のコマンドで接続できます:"
  echo "  $WRAPPER '<remote-command>'"
  echo
  echo "例:"
  echo "  $WRAPPER 'hostname'"
  if [[ -n "$extra_example" ]]; then
    echo "  $WRAPPER '$extra_example'"
  fi
  echo
}

ssh_session_main() {
  [[ $# -eq 1 ]] || ssh_session_usage

  ssh_session_init_common "$1" "normal"
  ssh_session_create_wrapper
  ssh_session_close_existing_master

  trap ssh_session_cleanup_common EXIT INT TERM

  ssh_session_print_common_info
  echo "通常モードです。"
  echo "このターミナルを開いている間だけ接続が有効です。"
  echo "いつでも Ctrl+C で終了できます。"
  echo

  ssh -MN \
    -o ControlMaster=yes \
    -o ControlPath="$CTL_PATH" \
    "$HOST_NAME"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  ssh_session_main "$@"
fi