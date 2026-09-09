################################################
####  Validate USE_CAMERA from config.cfg
####  Source this AFTER config.cfg has been sourced.
####  Sets CAMERA_SETTING to "true" or "false".
################################################

function F_validate_camera(){
    love_config_file="config.cfg"
    #### if no contain
    if [[ ! -f ${love_config_file} ]];then
        echo -e "\n#### camera\nUSE_CAMERA=true" >> ${love_config_file}
    fi

    # Safety Net 1: missing variable -> false
    : ${USE_CAMERA:="false"}

    # Safety Net 2: lowercase + strip CR (Windows line endings)
    CAMERA_SETTING="${USE_CAMERA,,}"
    CAMERA_SETTING="${CAMERA_SETTING//$'\r'/}"

    # Safety Net 3: anything other than true/false -> false
    if [ "$CAMERA_SETTING" = "true" ]; then
        echo "[STATUS] CAMERA is enabled."
    elif [ "$CAMERA_SETTING" = "false" ] || [ -z "$CAMERA_SETTING" ]; then
        CAMERA_SETTING="false"
        echo "[STATUS] CAMERA is disabled (or using default value)."
    else
        echo "[WARNING] Invalid configuration value '$USE_CAMERA'!"
        echo "For safety reasons, the system will treat it as 'false' (disabled)."
        CAMERA_SETTING="false"
    fi
}

F_validate_camera
