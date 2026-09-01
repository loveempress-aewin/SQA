import requests
from requests.auth import HTTPDigestAuth
from datetime import datetime  # 引入時間模組
import os

# ================= 設定區 =================
CAMERA_IP = "192.168.199.55"
USERNAME = "admin"
PASSWORD = "dh123456"
# =========================================

# 1. 取得當前時間，並格式化為字串（格式：年分月日_時分秒，例如 20260714_091530）
current_time = datetime.now().strftime("%Y%m%d_%H%M%S")

# 2. 把時間組合進檔名裡，這樣每次執行檔名都絕對不同
SAVE_PATH = f"snapshot_{current_time}.jpg"

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
