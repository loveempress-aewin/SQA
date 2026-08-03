#!/bin/bash
####author : lovequeen

DEVICE_IP="192.168.199.45"
COOKIE_JAR="/tmp/device_cookie.txt"
USERNAME="admin"
PLAIN_PASSWORD="1234" # Put your REAL plain-text password here

echo "1. Fetching login page to extract challenge token..."

# Fetch the login page HTML
LOGIN_PAGE=$(curl -s -c "$COOKIE_JAR" "http://${DEVICE_IP}/login.htm")
#### {IP}/login.tgi --> error
#### {IP}/login.htm -->will into

# Extract the challenge token (Adjust the grep/sed regex based on your HTML source!)
# Example assumes HTML contains: var challenge="XYZ123"; or <input name="challenge" value="XYZ123">
CHALLENGE=$(echo "$LOGIN_PAGE" | grep -i 'challenge' | sed -E 's/.*value="([^"]+)".*/\1/')

if [ -z "$CHALLENGE" ]; then
    # Alternative check if it's stored in a JS variable like var challenge = '...';
    CHALLENGE=$(echo "$LOGIN_PAGE" | grep -i 'challenge' | sed -E "s/.*='([^']+)'.*/\1/")
fi

echo "   Challenge Token Found: ${CHALLENGE}"

# 2. Compute dynamic MD5 hash: MD5(PLAIN_PASSWORD + CHALLENGE)
# (Change the string order if your device uses MD5(CHALLENGE + PLAIN_PASSWORD))
PASSWORD_HASH=$(echo -n "${PLAIN_PASSWORD}${CHALLENGE}" | md5sum | awk '{print $1}')

echo "   Computed Hash: ${PASSWORD_HASH}"

echo "2. Logging in..."
curl -s -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
     -X POST "http://${DEVICE_IP}/login.tgi" \
     -H 'Content-Type: application/x-www-form-urlencoded' \
     -H "Origin: http://${DEVICE_IP}" \
     -H "Referer: http://${DEVICE_IP}/" \
     --data-raw "Username=${USERNAME}&Password=${PASSWORD_HASH}" \
     > /dev/null

# Verify login succeeded
if [ ! -s "$COOKIE_JAR" ]; then
    echo "❌ Failed to obtain session cookie!"
    exit 1
fi

echo "3. Turning Outlet 1 ON..."
RESPONSE=$(curl -s -b "$COOKIE_JAR" \
     -H "Referer: http://${DEVICE_IP}/index.htm" \
     "http://${DEVICE_IP}/outlet?1=ON")

echo "Response from device:"
echo "$RESPONSE"

# Cleanup
rm -f "$COOKIE_JAR"
