import cv2
import time
from datetime import datetime

# ================= 設定區 =================
CAMERA_IP = "192.168.199.55"
PASSWORD = "dh123456"
RECORD_SECONDS = 10  # 想要錄影的秒數
# =========================================

# 大華標準 RTSP 串流網址 (subtype=0 代表主碼流，高畫質)
rtsp_url = f"rtsp://admin:{PASSWORD}@{CAMERA_IP}:554/cam/realmonitor?channel=1&subtype=0"

# 產生不重複的影片檔名
current_time = datetime.now().strftime("%Y%m%d_%H%M%S")
output_file = f"video_{current_time}.mp4"

print("正在連線至攝影機 RTSP 串流...")
cap = cv2.VideoCapture(rtsp_url)

if not cap.isOpened():
    print("無法連線至攝影機串流，請檢查 IP、密碼或網路。")
    exit()

# 取得攝影機的解析度與 FPS (幀率)
frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
fps = cap.get(cv2.CAP_PROP_FPS)
if fps == 0 or fps > 60:  # 防呆機制
    fps = 25.0

print(f"連線成功！解析度: {frame_width}x{frame_height}, FPS: {fps}")

# 設定影片編碼器與輸出設定 (MP4 格式)
fourcc = cv2.VideoWriter_fourcc(*'mp4v')
out = cv2.VideoWriter(output_file, fourcc, fps, (frame_width, frame_height))

print(f"開始錄影，預計錄製 {RECORD_SECONDS} 秒...")
start_time = time.time()

# 根據設定的秒數進行錄影迴圈
while int(time.time() - start_time) < RECORD_SECONDS:
    ret, frame = cap.read()
    if not ret:
        print("影像讀取中斷。")
        break

    # 寫入影格到檔案中
    out.write(frame)

# 釋放資源
cap.release()
out.release()
print(f"錄影結束！影片已儲存至：{output_file}")
