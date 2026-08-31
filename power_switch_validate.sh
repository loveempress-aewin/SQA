################################################
####  Validate USE_POWER_SWITCH from config.cfg
####  Source this AFTER config.cfg has been sourced.
####  Sets CURRENT_SETTING to "true" or "false".
################################################

function F_validate_power_switch(){
    # Safety Net 1: missing variable -> false
    : ${USE_POWER_SWITCH:="false"}

    # Safety Net 2: lowercase + strip CR (Windows line endings)
    CURRENT_SETTING="${USE_POWER_SWITCH,,}"
    CURRENT_SETTING="${CURRENT_SETTING//$'\r'/}"

    # Safety Net 3: anything other than true/false -> false
    if [ "$CURRENT_SETTING" = "true" ]; then
        echo "[STATUS] POWER SWITCH is enabled."
    elif [ "$CURRENT_SETTING" = "false" ] || [ -z "$CURRENT_SETTING" ]; then
        CURRENT_SETTING="false"
        echo "[STATUS] POWER SWITCH is disabled (or using default value)."
    else
        echo "[WARNING] Invalid configuration value '$USE_POWER_SWITCH'!"
        echo "For safety reasons, the system will treat it as 'false' (disabled)."
        CURRENT_SETTING="false"
    fi
}

F_validate_power_switch
