#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./ssh_session.sh
source "${SCRIPT_DIR}/ssh_session.sh"

ssh_sudo_session_usage() {
  cat >&2 <<'USAGE'
usage: ssh_sudo_session.sh user@host
USAGE
  exit 1
}

ssh_sudo_remove_temp_sudoers() {
  if [[ "${SUDOERS_INSTALLED:-0}" -eq 1 ]] && ssh_session_master_is_alive; then
    ssh \
      -tt \
      -o BatchMode=yes \
      -o ControlMaster=no \
      -o ControlPath="$CTL_PATH" \
      "$HOST_NAME" \
      "sudo rm -f '$REMOTE_SUDOERS'" >/dev/null 2>&1 || true
  fi
}

ssh_sudo_start_master_background() {
  ssh -f -N -M \
    -o ControlMaster=yes \
    -o ControlPath="$CTL_PATH" \
    "$HOST_NAME"
}

ssh_sudo_install_temp_sudoers() {
  ssh -tt -o ControlPath="$CTL_PATH" "$HOST_NAME" "
    tmp=\$(mktemp) &&
    printf '%s\n' '${LOCAL_USER} ALL=(ALL) NOPASSWD: ALL' > \"\$tmp\" &&
    sudo visudo -cf \"\$tmp\" &&
    sudo install -m 440 \"\$tmp\" '$REMOTE_SUDOERS' &&
    rm -f \"\$tmp\"
  "
  SUDOERS_INSTALLED=1
}

ssh_sudo_cleanup() {
  ssh_sudo_remove_temp_sudoers
  ssh_session_cleanup_common
}

ssh_sudo_session_main() {
  [[ $# -eq 1 ]] || ssh_sudo_session_usage

  ssh_session_init_common "$1" "sudo"

  REMOTE_SUDOERS="/etc/sudoers.d/llm-session-${LOCAL_USER}-${SUDOERS_SAFE_NAME}"
  SUDOERS_INSTALLED=0

  ssh_session_create_wrapper
  ssh_session_close_existing_master

  trap ssh_sudo_cleanup EXIT INT TERM

  ssh_session_print_common_info "sudo whoami"
  echo "sudo 一時許可モードです。"
  echo "SSH認証のあと、sudoers 配置のために sudo 認証が 1 回必要です。"
  echo "終了時に '$REMOTE_SUDOERS' を削除します。"
  echo
  echo "このターミナルを開いている間だけ接続が有効です。"
  echo "いつでも Ctrl+C で終了できます。"
  echo

  ssh_sudo_start_master_background
  ssh_sudo_install_temp_sudoers

  echo
  echo "sudo 一時許可を有効化しました。"

  while :; do
    sleep 3600
  done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  ssh_sudo_session_main "$@"
fi