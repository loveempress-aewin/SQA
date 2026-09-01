#!/bin/bash
#### author : lovequeen
#### date : Mon Aug 31 16:13:46 CST 2026 (2026/08/31-16:13:46)
#### goal : if no OT016 just use this one

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${script_dir}/config.cfg"
csv_file="../csv/cpld_raw.csv"

# 1. Source configuration (variables only)
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# 2. Set default AMD_PATH if missing or empty
if [[ -z "${AMD_PATH:-}" ]]; then
    AMD_PATH="/root/AMDSCAN/"
fi

# 3. Check for ipmitool availability and execution
if command -v ipmitool >/dev/null 2>&1; then
    echo "[INFO] ipmitool detected. Attempting IPMI command..."
    # if ipmitool power status >/dev/null 2>&1; then
    if ipmitool power status  ; then
        echo "[SUCCESS] IPMI command executed successfully."
        # Proceed with normal IPMI logic...
    else
        echo "[WARNING] ipmitool failed or returned an error. Falling back to AMD tool..."
        exit 222
    fi
else
    echo "[WARNING] ipmitool is not installed. Falling back to AMD tool..."
    exit 123
fi

# 4. Fallback execution: Check AMD binary path and execute
AMD_EXEC_PATH="${AMD_PATH}/amdscan_withRW"

if [[ ! -x "$AMD_EXEC_PATH" ]]; then
    echo "[ERROR] Executable not found or not executable at: $AMD_EXEC_PATH" >&2
    exit 1
fi

echo "[ACTION] Executing fallback tool: $AMD_EXEC_PATH"
"$AMD_EXEC_PATH" |tee ${csv_file}
