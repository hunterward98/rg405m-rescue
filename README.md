# RG405M rescue

Tools and notes for un-sticking an Anbernic RG405M (Unisoc T618) that hangs at
the Anbernic logo showing:

```
INFO: LOCK IS : UNLOCK!!
WARNING: LOCK FLAG IS : UNLOCK, SKIP VERIFY!!!
```

## What that message means

It is **not** the error. It is printed on every boot by the Unisoc bootloader
when the bootloader is unlocked (e.g. after installing GammaOS or rooting).
The real problem is that boot stops *after* this point. At this stage the
device has not enabled USB yet, so Windows showing nothing is expected — it is
not proof that the port or cable is broken.

## Rule: don't lose data

Never run any of these unless we have decided to give up on the data:

- `fastboot -w`, `fastboot erase userdata`, `fastboot format userdata`
- GammaOS `EraseUserData.bat/.sh`
- "Wipe data / factory reset" in recovery
- The Unisoc `.pac` unbricker with default settings (re-flashes everything)

## Scripts

| Script | What it does |
| --- | --- |
| `scripts/watch-usb.ps1` | Read-only. Prints every USB device that appears/disappears and names the RG405M mode (download / fastboot / ADB / failed-to-enumerate). |
| `scripts/inspect-sdcard.ps1` | Read-only. Reports the microSD card's partitions, health and top-level folders from a PC card reader; `chkdsk` without `/f`. |
| `scripts/device-diag.ps1` | Read-only. With adb or fastboot connected, saves getprop, storage, battery, logcat/dmesg or `fastboot getvar all` to a folder. `-Tools <dir with adb.exe>` |

## Progress log

- Stuck at logo with SD card in; Windows saw only an error-43 "Device Descriptor Request Failed" device that kept reconnecting.
- Removing the SD card -> device showed the **battery empty** screen. Likely cause: nearly dead battery (plus SD card delaying boot). Charging on a wall charger next.
- After charging, with the SD card still out: **boots normally into the custom frontend.** Not bricked. Next: re-insert SD card to see whether it causes the hang.

```powershell
powershell -ExecutionPolicy Bypass -File scripts\watch-usb.ps1
```

## USB IDs this looks for

| ID | Mode |
| --- | --- |
| `VID_1782&PID_4D00` | Unisoc download mode (SPRD U2S Diag) |
| `VID_1782&*` | Unisoc Android (ADB/MTP) or fastboot |
| `VID_18D1&PID_4EE0` / `PID_D00D` | fastboot / fastbootd |
| `VID_18D1&PID_4EE7` | ADB |
| `VID_0000` / descriptor failure | device tried to connect but USB failed |
