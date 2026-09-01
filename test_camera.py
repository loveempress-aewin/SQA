import os
from datetime import datetime
import requests
from requests.auth import HTTPDigestAuth

# ================= Configuration =================
CAMERA_IP = "192.168.199.55"
USERNAME = "admin"
PASSWORD = "dh123456"
# Save to the pic/ directory located in the parent directory (../pic)
OUTPUT_DIR = os.path.join("..", "pic")
# =================================================

# 0. Create ../pic directory if it doesn't exist
os.makedirs(OUTPUT_DIR, exist_ok=True)

# 1. Get current timestamp and format it as a string (YYYYMMDD_HHMMSS)
current_time = datetime.now().strftime("%Y%m%d_%H%M%S")

# 2. Construct filename and full save path (e.g., ../pic/snapshot_20260901_145000.jpg)
filename = f"snapshot_{current_time}.jpg"
SAVE_PATH = os.path.join(OUTPUT_DIR, filename)

# Dahua Snapshot API URL
url = f"http://{CAMERA_IP}/cgi-bin/snapshot.cgi?channel=1"

print(f"Connecting to camera at {CAMERA_IP} to capture snapshot...")

try:
    response = requests.get(
        url,
        auth=HTTPDigestAuth(USERNAME, PASSWORD),
        timeout=5
    )

    if response.status_code == 200:
        with open(SAVE_PATH, "wb") as f:
            f.write(response.content)
        print(f"Success! Image saved to: {os.path.abspath(SAVE_PATH)}")
    else:
        print(f"Failed to capture snapshot. Status code: {response.status_code}")

except requests.exceptions.RequestException as e:
    print(f"Connection exception occurred: {e}")
