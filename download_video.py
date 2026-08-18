import urllib.request
import os

def download_video(url, filename):
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'})
    print(f"Downloading {filename}...")
    try:
        with urllib.request.urlopen(req) as response, open(filename, 'wb') as out_file:
            data = response.read()
            out_file.write(data)
        print(f"Success: {filename}")
    except Exception as e:
        print(f"Failed: {e}")

os.makedirs('assets/videos', exist_ok=True)

# 1. Pool Water Surface (good for background)
download_video("https://assets.mixkit.co/videos/preview/mixkit-water-surface-in-a-pool-loop-2041-large.mp4", "assets/videos/pool_water.mp4")

# 2. Swimmer (good for coach or action)
download_video("https://assets.mixkit.co/videos/preview/mixkit-swimmer-doing-freestyle-in-a-pool-12185-large.mp4", "assets/videos/swimmer.mp4")
