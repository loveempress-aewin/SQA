#!/bin/bash
####author : lovequeen

function error1(){
    DEVICE_IP="192.168.199.45"
    USERNAME="admin"
    # Your hashed password from DevTools
    PASSWORD_HASH="a0fc5431b538abe6a511c7ced1a4e711"

    echo "1. Logging in and capturing session cookie..."

    # Step 1: POST to login.tgi and capture the Set-Cookie response header
    LOGIN_RESPONSE=$(curl -s -i -X POST "http://${DEVICE_IP}/login.tgi" \
                          -H 'Content-Type: application/x-www-form-urlencoded' \
                          -H "Origin: http://${DEVICE_IP}" \
                          -H "Referer: http://${DEVICE_IP}/" \
                          --data-raw "Username=${USERNAME}&Password=${PASSWORD_HASH}")

    # Extract DLILPC cookie value
    COOKIE=$(echo "$LOGIN_RESPONSE" | grep -i 'Set-Cookie: DLILPC=' | sed -E 's/.*DLILPC="?([^";]+)"?.*/\1/')

    if [ -z "$COOKIE" ]; then
        echo "❌ Login failed! No DLILPC cookie returned."
        echo "Full Response Headers:"
        echo "$LOGIN_RESPONSE" | head -n 20
        exit 1
    fi

    echo "✅ Acquired Cookie: DLILPC=\"${COOKIE}\""

    echo "2. Sending Outlet Command..."

    # Step 2: Send outlet control request using the acquired cookie
    RESPONSE=$(curl -s -b "DLILPC=\"${COOKIE}\"" \
                    -H "Referer: http://${DEVICE_IP}/index.htm" \
                    "http://${DEVICE_IP}/outlet?1=ON")

    echo "Response from device:"
    echo "$RESPONSE"
}

DEVICE_IP="192.168.199.45"
USERNAME="admin"
PASSWORD="1234" # Your actual plain-text password
# let love_port=0;
love_port=$1;
love_control=$2;

function love_send(){

echo "1. Fetching login page and extracting Challenge..."

# 1. Fetch HTML page
PAGE=$(curl -s "http://${DEVICE_IP}/")

# 2. Extract Challenge safely (handles slashes like La66A/kUUi5Bcy3)
CHALLENGE=$(echo "$PAGE" | grep -i 'name="Challenge"' | sed -E 's#.*value="([^"]+)".*#\1#')

if [ -z "$CHALLENGE" ]; then
    echo "❌ Failed to extract Challenge token!"
    exit 1
fi

echo "   Challenge Token: ${CHALLENGE}"

# 3. Build string: Challenge + Username + Password + Challenge
RAW_STR="${CHALLENGE}${USERNAME}${PASSWORD}${CHALLENGE}"

# 4. Compute MD5
HASH=$(echo -n "${RAW_STR}" | md5sum | awk '{print $1}')

echo "   Computed Hash: ${HASH}"

echo "2. Logging in..."

# 5. POST hash to login.tgi and capture response headers
LOGIN_RESP=$(curl -s -i -X POST "http://${DEVICE_IP}/login.tgi" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H "Origin: http://${DEVICE_IP}" \
  -H "Referer: http://${DEVICE_IP}/" \
  --data-raw "Username=${USERNAME}&Password=${HASH}")

# 6. Extract DLILPC session cookie
COOKIE=$(echo "$LOGIN_RESP" | grep -i 'Set-Cookie: DLILPC=' | sed -E 's#.*DLILPC="?([^";]+)"?.*#\1#')

if [ -z "$COOKIE" ]; then
    echo "❌ Login failed! DLILPC cookie was not returned."
    exit 1
fi

echo "✅ Cookie Acquired: DLILPC=\"${COOKIE}\""

echo "3. Sending Outlet Command..."

# 7. Execute Outlet Control
# curl -s -b "DLILPC=\"${COOKIE}\"" \
#   -H "Referer: http://${DEVICE_IP}/index.htm" \
#   "http://${DEVICE_IP}/outlet?1=ON"
curl -s -b "DLILPC=\"${COOKIE}\"" \
  -H "Referer: http://${DEVICE_IP}/index.htm" \
  "http://${DEVICE_IP}/outlet?${love_port}=${love_control}"

echo -e "\nTHE -> [${love_port}]\nswitch:[${love_control}]\nDone!"
}

let love_count=$#;
if (( ${love_count} == 2 ));then
    love_send
else
    echo "ERROR!need 2"
    exit 5;
fi
