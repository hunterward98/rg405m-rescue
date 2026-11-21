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
- SD card re-inserted: device rebooted and **works normally with the card in**.

## Connecting to the device (for humans and AI agents)

What has actually worked so far: **detection only.** No data has ever been
exchanged. Windows lists the device as
`USB\VID_0000&PID_0002` "Unknown USB Device (Device Descriptor Request Failed)",
problem code 43, on `Port_#0003.Hub_#0002`.

Check what Windows sees (read-only):

```powershell
Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -match 'VID_0000|VID_1782|VID_18D1' -or $_.Class -in 'WPD','AndroidUsbDeviceClass' } | Format-Table Status, Class, FriendlyName, InstanceId -AutoSize
```

or stream changes with `scripts/watch-usb.ps1`.

To get real access, fix the USB data link first:

1. Use a known **data** USB-C cable (many are charge-only) and a rear motherboard port.
   Inspect the RG405M's USB-C port for lint.
2. Success looks like a new device with `VID_1782` or `VID_18D1`, or class `WPD`,
   instead of `VID_0000`.
3. **Files (MTP):** on the device, pull down notifications, tap the USB notification,
   choose **File transfer**. It then appears in File Explorer.
4. **Shell (ADB):** Settings > About > tap Build number 7x > Developer options >
   enable **USB debugging**; install Google platform-tools
   (https://developer.android.com/tools/releases/platform-tools); run
   `adb devices` and accept the prompt on the device. Then
   `scripts/device-diag.ps1 -Tools <platform-tools dir>` collects read-only info,
   and `scrcpy` (https://github.com/Genymobile/scrcpy) can mirror the screen.

Never run `fastboot -w`, `erase`, `format`, or factory reset — see "Rule" above.

## Diagnosis

**Root cause: a fully drained battery.** At near-zero charge the RG405M sat at the
bootloader logo (the "LOCK IS UNLOCK / SKIP VERIFY" banner is normal for an
unlocked bootloader) and power-cycled instead of showing the charge screen.
After charging it boots fine, with or without the SD card. Nothing was erased.

**Open issue:** Windows only ever sees the device as error 43 "Device
Descriptor Request Failed", even with Android running. That points to a
charge-only/worn USB-C cable or a dirty USB-C port on the device. Try a
known data cable, then choose "File transfer" in the device's USB notification.

**If it happens again:** charge it switched off on a wall charger for 30+ min
before deciding it's bricked.

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
