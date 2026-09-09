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

: "${AMDSCAN_DIR:=amdscan_withRW}"
: "${AMD_exe:=amdscan_withRW}"

# 2. If AMD_PATH is not configured, search home/dir then env/dir
if [[ -z "${AMD_PATH:-}" ]]; then
    home_dir="${HOME:-}"
    env_dir="$(cd "${script_dir}/.." && pwd)"

    if [[ -n "$home_dir" && -d "${home_dir}/${AMDSCAN_DIR}" ]]; then
        declare AMD_PATH="$(cd "${home_dir}/${AMDSCAN_DIR}" && pwd)"
        echo "[INFO] Found ${AMDSCAN_DIR} in home: $AMD_PATH"
    elif [[ -d "${env_dir}/${AMDSCAN_DIR}" ]]; then
        declare AMD_PATH="$(cd "${env_dir}/${AMDSCAN_DIR}" && pwd)"
        echo "[INFO] Found ${AMDSCAN_DIR} in env: $AMD_PATH"
    else
        echo "[ERROR] Directory '${AMDSCAN_DIR}' not found in:" >&2
        echo "        home: ${home_dir:-<unset>}/${AMDSCAN_DIR}" >&2
        echo "        env:  ${env_dir}/${AMDSCAN_DIR}" >&2
        exit 1
    fi
fi

AMD_EXEC_PATH="${AMD_PATH}/${AMD_exe}"
AMD_SRC_PATH="${AMD_PATH}/${AMD_exe}.c"

# 3. Prefer the binary; if missing, compile from amdscan_withRW.c
if [[ ! -x "$AMD_EXEC_PATH" ]]; then
    echo "[INFO] Executable not found at: $AMD_EXEC_PATH"
    if [[ -f "$AMD_SRC_PATH" ]]; then
        echo "[ACTION] Compiling: gcc ${AMD_exe}.c -o ${AMD_exe}"
        if ! gcc "$AMD_SRC_PATH" -o "$AMD_EXEC_PATH"; then
            echo "[ERROR] gcc failed to build $AMD_EXEC_PATH" >&2
            exit 1
        fi
        echo "[INFO] Built executable: $AMD_EXEC_PATH"
    else
        echo "[ERROR] Neither executable nor source found in $AMD_PATH" >&2
        echo "        binary: $AMD_EXEC_PATH" >&2
        echo "        source: $AMD_SRC_PATH" >&2
        exit 1
    fi
fi

# 4. Check for ipmitool availability and execution
if command -v ipmitool >/dev/null 2>&1; then
    echo "[INFO] ipmitool detected. Attempting IPMI command..."
    # if ipmitool power status >/dev/null 2>&1; then
    if ipmitool power status  ; then
        echo "[SUCCESS] IPMI command executed successfully."
        exit 0
    else
        echo "[WARNING] ipmitool failed or returned an error. Falling back to AMD tool..."
    fi
else
    echo "[WARNING] ipmitool is not installed. Falling back to AMD tool..."
fi

# 5. Execute AMD_EXEC_PATH
"$AMD_EXEC_PATH" | tee ${csv_file}
