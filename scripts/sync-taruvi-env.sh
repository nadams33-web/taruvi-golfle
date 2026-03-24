#!/usr/bin/env bash

set -euo pipefail

ENV_FILE="${1:-.env}"

if [ ! -f "$ENV_FILE" ]; then
  cp .env.example "$ENV_FILE"
fi

load_env_file() {
  local env_file="$1"

  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"

    case "$line" in
      '' | [[:space:]]*'#'*)
        continue
        ;;
    esac

    case "$line" in
      *=*)
        ;;
      *)
        continue
        ;;
    esac

    local key="${line%%=*}"
    local value="${line#*=}"

    key="$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    value="$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

    if [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
      export "$key=$value"
    fi
  done < "$env_file"
}

persist_env_var() {
  local env_file="$1"
  local key="$2"
  local value="$3"
  local escaped_value

  escaped_value="$(printf '%s' "$value" | sed 's/[&|\\]/\\&/g')"

  if grep -q "^${key}=" "$env_file"; then
    sed -i.bak "s|^${key}=.*|${key}=${escaped_value}|" "$env_file"
    rm -f "${env_file}.bak"
  else
    printf '%s=%s\n' "$key" "$value" >> "$env_file"
  fi
}

trim_value() {
  echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

load_env_file "$ENV_FILE"

SITE_URL="$(trim_value "${TARUVI_SITE_URL:-${VITE_TARUVI_BASE_URL:-}}")"
APP_SLUG="$(trim_value "${TARUVI_APP_SLUG:-${VITE_TARUVI_APP_SLUG:-}}")"
API_KEY="$(trim_value "${TARUVI_API_KEY:-${VITE_TARUVI_API_KEY:-}}")"

SITE_URL="${SITE_URL%/}"

if [ -n "${TARUVI_SITE_URL:-}" ] && [ -n "${VITE_TARUVI_BASE_URL:-}" ] && [ "$(trim_value "$TARUVI_SITE_URL")" != "$(trim_value "$VITE_TARUVI_BASE_URL")" ]; then
  echo "Warning: TARUVI_SITE_URL and VITE_TARUVI_BASE_URL differ. Using TARUVI_SITE_URL." >&2
fi

if [ -n "${TARUVI_APP_SLUG:-}" ] && [ -n "${VITE_TARUVI_APP_SLUG:-}" ] && [ "$(trim_value "$TARUVI_APP_SLUG")" != "$(trim_value "$VITE_TARUVI_APP_SLUG")" ]; then
  echo "Warning: TARUVI_APP_SLUG and VITE_TARUVI_APP_SLUG differ. Using TARUVI_APP_SLUG." >&2
fi

if [ -n "${TARUVI_API_KEY:-}" ] && [ -n "${VITE_TARUVI_API_KEY:-}" ] && [ "$(trim_value "$TARUVI_API_KEY")" != "$(trim_value "$VITE_TARUVI_API_KEY")" ]; then
  echo "Warning: TARUVI_API_KEY and VITE_TARUVI_API_KEY differ. Using TARUVI_API_KEY." >&2
fi

if [ -n "$SITE_URL" ]; then
  persist_env_var "$ENV_FILE" "TARUVI_SITE_URL" "$SITE_URL"
  persist_env_var "$ENV_FILE" "VITE_TARUVI_BASE_URL" "$SITE_URL"
fi

if [ -n "$APP_SLUG" ]; then
  persist_env_var "$ENV_FILE" "TARUVI_APP_SLUG" "$APP_SLUG"
  persist_env_var "$ENV_FILE" "VITE_TARUVI_APP_SLUG" "$APP_SLUG"
fi

if [ -n "$API_KEY" ]; then
  persist_env_var "$ENV_FILE" "TARUVI_API_KEY" "$API_KEY"
  persist_env_var "$ENV_FILE" "VITE_TARUVI_API_KEY" "$API_KEY"
fi

echo "TARUVI_SITE_URL=$SITE_URL"
echo "TARUVI_APP_SLUG=$APP_SLUG"
echo "TARUVI_API_KEY=$API_KEY"

