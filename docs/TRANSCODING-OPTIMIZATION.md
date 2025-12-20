# Transcoding Optimization Guide

## Problem: High CPU Usage During Remote Streaming

### Symptoms
- CPU usage 80-100% (or 200%+ on multi-core) during single remote transcode
- Laggy playback for remote users
- Server becomes unresponsive
- High temperature and power consumption

### Root Causes

#### 1. Image-based Subtitles (PGS/SUP) Burn-in
**Problem:** Blu-ray discs contain PGS (Picture-based Graphics Subtitles) - bitmap images, not text.
- Converting PGS → ASS/SRT requires OCR (Optical Character Recognition)
- CPU-intensive: 40-60% CPU on Intel N100
- Happens when user's language preference doesn't match available SRT subtitles

**Solution:** Use Bazarr for automatic SRT subtitle downloads

#### 2. No Hardware Transcoding (Virtual GPU in Proxmox VM)
**Problem:** Ubuntu VM in Proxmox has virtual VGA (Device 1234:1111) instead of Intel iGPU
- Video transcoding runs on CPU: 60-80% per stream
- `/dev/dri/renderD128` doesn't exist
- Intel QuickSync unavailable

**Solution:** GPU Passthrough in Proxmox (see GPU-PASSTHROUGH.md)

#### 3. Audio Transcoding
**Problem:** Some audio formats always transcode on CPU
- AAC → OPUS: 15-25% CPU
- DTS/TrueHD → AAC: 20-30% CPU
- No hardware acceleration available for audio

**Mitigation:** Limit remote quality or encourage Direct Play

---

## Solution 1: Bazarr for SRT Subtitles

### Why Bazarr?
- Automatically downloads text-based SRT subtitles
- SRT = Direct stream (copy), <1% CPU
- Supports multiple languages (Polish, English, etc.)
- Integrates with Sonarr/Radarr

### Configuration

**1. Enable Bazarr in docker-compose.yml** (already included in this repo)

**2. Access Bazarr:**
```
http://YOUR_SERVER_IP:6767
```

**3. Connect to Sonarr:**
- Settings → Sonarr
- Hostname: `localhost` (with network_mode: host)
- Port: `8989`
- API Key: (from Sonarr Settings → General → Security)
- Test → Save

**4. Connect to Radarr:**
- Settings → Radarr
- Hostname: `localhost`
- Port: `7878`
- API Key: (from Radarr Settings → General → Security)
- Test → Save

**5. Configure Languages:**
- Settings → Languages
- Languages Filter: Polish, English (or your preferences)
- Default Enabled: YES

**6. Add Subtitle Providers:**
- Settings → Providers
- Enable: OpenSubtitles, Subscene, Podnapisi
- For Polish: Enable Napiprojekt

**7. Configure Subtitle Settings:**
- Settings → Subtitles
- Series/Movies Subtitle Type: **External** (not Embedded!)
- Encoding: UTF-8

**8. Run Initial Scan:**
- Movies → Mass Editor → Select All → Search
- Wait 10-30 minutes for downloads

### Expected Results
- SRT files appear next to media files: `Movie (2023).pl.srt`, `Movie (2023).en.srt`
- Plex automatically detects new subtitles
- CPU during transcode: 40-60% reduction

---

## Solution 2: GPU Passthrough (Proxmox)

### Prerequisites
- Proxmox VE host with Intel CPU (N100, i3, i5, i7, i9)
- Ubuntu Server VM
- Intel QuickSync support (12th gen+)

### Implementation
See detailed guide: [GPU-PASSTHROUGH.md](GPU-PASSTHROUGH.md)

### Verification
```bash
# Check if GPU is available
lspci | grep VGA
# Should show: Intel Corporation Alder Lake-N [UHD Graphics]

# Check render node
ls -la /dev/dri/
# Should show: renderD128

# Check if Plex container sees GPU
docker exec plex ls -la /dev/dri/
```

### Enable Hardware Transcoding in Plex
1. Settings → Transcoder
2. ✅ Use hardware acceleration when available
3. ✅ Use hardware-accelerated video encoding
4. Hardware transcoding device: Intel Quick Sync Video
5. Save

### Expected Results
- CPU during transcode: 60-80% reduction (10-20% instead of 60-80%)
- Can handle 3-5 simultaneous transcodes
- Lower power consumption (~15-20W savings)

---

## Performance Comparison

| Scenario | Before | After | Improvement |
|----------|--------|-------|-------------|
| **Idle** | 5-10% | 1-2% | - |
| **1x Remote Transcode (720p)** | 205% | 20-30% | **85% reduction** |
| **2x Remote Transcodes** | Server crash | 40-50% | Now possible |
| **3x Remote Transcodes** | Impossible | 60-70% | Now possible |
| **Power consumption** | ~35W | ~20W | ~15W savings |

### Breakdown (per stream)
| Component | Without Optimization | With Bazarr | With Bazarr + QuickSync |
|-----------|---------------------|-------------|-------------------------|
| Subtitles (PGS→ASS OCR) | 40-60% | - | - |
| Subtitles (SRT copy) | - | <1% | <1% |
| Video (CPU transcode) | 60-80% | 60-80% | - |
| Video (QuickSync) | - | - | 10-20% |
| Audio (CPU) | 15-25% | 15-25% | 15-25% |
| **Total** | **115-165%** | **75-105%** | **25-45%** |

---

## Troubleshooting

### Bazarr shows "Connection timeout" to Sonarr/Radarr
**Solution:** Use `localhost` as hostname (requires `network_mode: host`)

### SRT subtitles not appearing in Plex
**Check naming convention:**
```bash
# Correct:
Movie (2023).mkv
Movie (2023).pl.srt
Movie (2023).en.srt

# Wrong:
Movie.2023.1080p.BluRay.srt  # Name doesn't match exactly
polski.srt                    # Missing movie name
```

**Force Plex refresh:**
- Library → Movie → ... → Refresh Metadata

### QuickSync not working (high CPU persists)
```bash
# Check if renderD128 exists
ls -la /dev/dri/renderD128

# Check if Plex uses GPU during transcode
sudo lsof /dev/dri/renderD128 | grep -i plex

# Check Plex logs
docker logs plex | grep -i hardware
```

### User still sees PGS subtitles instead of SRT
**Cause:** Plex prefers embedded subtitles over external

**Solution in Plex Settings → Languages:**
- ✅ Prefer external subtitles
- ☐ Burn subtitles automatically

---

## Recommendations

### For Best Performance:
1. ✅ Enable Bazarr (SRT subtitles)
2. ✅ GPU Passthrough (if using Proxmox/ESXi)
3. ✅ Limit remote quality to 4-8 Mbps
4. ✅ Encourage users to use devices that support Direct Play

### For Specific Use Cases:

**Family/Friends Remote Access:**
- Remote bitrate limit: 4 Mbps (720p)
- Bazarr: Enable for popular languages
- QuickSync: Highly recommended

**Local Network Only:**
- Direct Play preferred
- QuickSync: Optional (but still useful)
- SRT subtitles: Nice to have

**Multiple Concurrent Users:**
- QuickSync: **Essential**
- Bazarr: **Essential**
- Consider upgrading CPU/GPU if >5 users

---

## Monitoring Transcoding Performance

### Using Tautulli (included in stack)
```
http://YOUR_SERVER_IP:8181
```

**Check Stream Info:**
- Activity → Click on active stream
- Video Decision: Look for "hw transcode" (good) vs "transcode" (CPU)
- Subtitles: Look for "copy" (good) vs "transcode" (bad)

### Using Docker Stats
```bash
# Real-time CPU usage
docker stats plex --no-stream

# Check GPU usage
sudo lsof /dev/dri/renderD128
```

### Expected CPU During Active Transcode:
- **Without optimizations:** 80-200%
- **With Bazarr only:** 50-100%
- **With Bazarr + QuickSync:** 20-45%
