# GPU Passthrough Guide (Proxmox VE)

## Overview
This guide enables Intel QuickSync hardware transcoding by passing through the physical Intel iGPU to your Ubuntu VM.

**Benefits:**
- 85% CPU reduction during transcoding
- 3-5 simultaneous transcodes possible
- Lower power consumption (~15W savings)

## Prerequisites
- Proxmox VE 7.0+ or 8.0+
- Intel CPU with integrated graphics (N100, 12th gen+)
- Ubuntu Server VM
- No other VM using the Intel iGPU

---

## Step 1: Enable IOMMU on Proxmox Host

### Edit GRUB configuration:
```bash
nano /etc/default/grub
```

### Modify the kernel command line:
```bash
# Find this line:
GRUB_CMDLINE_LINUX_DEFAULT="quiet"

# Change to (Intel CPU):
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"

# For AMD CPU:
GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on iommu=pt"
```

### Update GRUB and reboot:
```bash
update-grub
reboot
```

### Verify IOMMU is enabled:
```bash
dmesg | grep -e DMAR -e IOMMU

# Should show:
# DMAR: IOMMU enabled
```

---

## Step 2: Load VFIO Modules

### Add required modules:
```bash
nano /etc/modules
```

### Add these lines:
```
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd
```

### Update initramfs:
```bash
update-initramfs -u -k all
reboot
```

---

## Step 3: (Optional) Blacklist i915 Driver on Host

**Only if Proxmox doesn't need the GPU for console output.**

```bash
nano /etc/modprobe.d/blacklist-i915.conf
```

Add:
```
blacklist i915
blacklist snd_hda_intel
blacklist snd_hda_codec_hdmi
```

Update and reboot:
```bash
update-initramfs -u -k all
reboot
```

---

## Step 4: Identify GPU PCI Address

```bash
lspci -nn | grep VGA

# Example output:
# 00:02.0 VGA compatible controller [0300]: Intel Corporation Alder Lake-N [UHD Graphics] [8086:46d0]
```

**Note the PCI address:** `00:02.0`

---

## Step 5: Add GPU to VM via Proxmox Web UI

1. **Select your VM** (e.g., Ubuntu Server)
2. **Hardware** → **Add** → **PCI Device**
3. **Configuration:**
   - Device: `0000:00:02.0` (your Intel GPU)
   - ✅ All Functions
   - ✅ Primary GPU (if no other GPU in VM)
   - ✅ PCI-Express
   - ☐ ROM-Bar (leave unchecked)
4. **Add**
5. **Shutdown VM** (full shutdown, not restart!)
6. **Start VM**

---

## Step 6: Verify GPU in Ubuntu VM

### SSH into Ubuntu VM:
```bash
# Check GPU is visible
lspci | grep VGA

# Should now show:
# 00:10.0 VGA compatible controller: Intel Corporation Alder Lake-N [UHD Graphics]
```

### Check render node:
```bash
ls -la /dev/dri/

# Should show:
# card0
# card1 (optional)
# renderD128  ← This is critical!
```

### If renderD128 is missing:
```bash
# Load i915 driver
sudo modprobe i915

# Check again
ls -la /dev/dri/
```

### Make i915 load on boot:
```bash
echo "i915" | sudo tee -a /etc/modules
```

---

## Step 7: Configure Plex for Hardware Transcoding

### Ensure docker-compose.yml has GPU devices:
```yaml
plex:
  devices:
    - /dev/dri:/dev/dri
```

### Recreate Plex container:
```bash
docker compose up -d plex
```

### Verify Plex sees GPU:
```bash
docker exec plex ls -la /dev/dri/

# Should show renderD128
```

### Enable in Plex Settings:
1. Settings → Transcoder
2. ✅ Use hardware acceleration when available
3. ✅ Use hardware-accelerated video encoding
4. Hardware transcoding device: **Intel Quick Sync Video**
5. Save

---

## Step 8: Test Hardware Transcoding

### Start a remote stream that requires transcoding

### Check CPU usage:
```bash
docker stats plex --no-stream

# Should be 20-40% (not 100-200%)
```

### Verify GPU is being used:
```bash
sudo lsof /dev/dri/renderD128

# Should show Plex Transcoder process
```

### Check Tautulli:
```
http://YOUR_IP:8181
Activity → Stream Info → Video Decision: "hw transcode"
```

---

## Troubleshooting

### VM won't start after adding GPU
**Solution:** Remove GPU passthrough, check IOMMU groups:
```bash
# On Proxmox host
find /sys/kernel/iommu_groups/ -type l
```

### renderD128 doesn't exist in VM
```bash
# Check if i915 module is loaded
lsmod | grep i915

# Load manually
sudo modprobe i915

# Add to /etc/modules for persistence
echo "i915" | sudo tee -a /etc/modules
```

### Plex shows "Hardware transcoding not available"
```bash
# Check permissions
ls -la /dev/dri/renderD128

# Should be: crw-rw---- 1 root render

# Add Plex user to render group (inside container)
docker exec plex id
# Should show: groups=... render(109)
```

### GPU passthrough works but CPU still high
- Check Plex Transcoder settings (must be enabled)
- Verify stream actually requires transcoding (not Direct Play)
- Check for subtitle burn-in (use SRT instead of PGS)

---

## Performance Metrics

### Expected CPU Usage (Intel N100):

| Scenario | Without QuickSync | With QuickSync | Improvement |
|----------|------------------|----------------|-------------|
| 1x 1080p→720p | 80-100% | 15-25% | **75-85% reduction** |
| 2x 1080p→720p | 160-200% | 30-40% | **75-80% reduction** |
| 3x 1080p→720p | Server crash | 45-60% | Now possible |
| 1x 4K→1080p HDR | 200%+ | 40-60% | **70% reduction** |

### Power Consumption:
- Idle: 8-12W
- 1x CPU transcode: 25-35W
- 1x QuickSync transcode: 15-20W
- **Savings: ~10-15W per stream**

---

## Alternative: Docker on Proxmox Host

**If GPU passthrough is problematic**, consider running Docker directly on Proxmox host:

**Pros:**
- Direct GPU access (no passthrough needed)
- Lower overhead
- Simpler configuration

**Cons:**
- Mixing Proxmox with applications
- Less isolation

### Quick setup:
```bash
# On Proxmox host
apt update
apt install docker.io docker-compose

# Transfer compose files from VM
# Run stack on host
```

---

## References
- [Proxmox PCIe Passthrough](https://pve.proxmox.com/wiki/PCI_Passthrough)
- [Intel QuickSync Support Matrix](https://ark.intel.com/)
- [Plex Hardware Transcoding](https://support.plex.tv/articles/115002178853-using-hardware-accelerated-streaming/)
