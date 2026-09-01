import requests
from requests.auth import HTTPDigestAuth
from datetime import datetime  # 引入時間模組
import os

# ================= 設定區 =================
CAMERA_IP = "192.168.199.55"
USERNAME = "admin"
PASSWORD = "dh123456"
OUTPUT_DIR = "pic"  # Target directory under current path
# =========================================

# 0. 確保 pic/ 目錄存在，若不存在則自動建立
os.makedirs(OUTPUT_DIR, exist_ok=True)

# 1. 取得當前時間，並格式化為字串（格式：年分月日_時分秒，例如 20260714_091530）
current_time = datetime.now().strftime("%Y%m%d_%H%M%S")

# 2. 將目錄與檔名組合在一起 (pic/snapshot_20260714_091530.jpg)
filename = f"snapshot_{current_time}.jpg"
SAVE_PATH = os.path.join(OUTPUT_DIR, filename)

# 大華抓取當前畫面的 Snapshot API 網址
url = f"http://{CAMERA_IP}/cgi-bin/snapshot.cgi?channel=1"

print(f"正在連線至攝影機 {CAMERA_IP} 請求拍照...")

try:
    response = requests.get(
        url,
        auth=HTTPDigestAuth(USERNAME, PASSWORD),
        timeout=5
    )

    if response.status_code == 200:
        with open(SAVE_PATH, "wb") as f:
            f.write(response.content)
        print(f"成功！照片已儲存至：{os.path.abspath(SAVE_PATH)}")
    else:
        print(f"失敗，錯誤代碼: {response.status_code}")

except requests.exceptions.RequestException as e:
    print(f"連線發生異常: {e}")
