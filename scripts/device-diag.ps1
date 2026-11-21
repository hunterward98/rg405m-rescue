<#
  READ-ONLY RG405M diagnostics over adb or fastboot. Only queries the device:
  no flash, erase, format, -w, or reboot commands.
  Usage: device-diag.ps1 -Tools <folder with adb.exe/fastboot.exe> [-Out <folder>]
#>
param([Parameter(Mandatory)][string]$Tools, [string]$Out = "$PWD\diag-$(Get-Date -Format yyyyMMdd-HHmmss)")
$adb = Join-Path $Tools 'adb.exe'; $fb = Join-Path $Tools 'fastboot.exe'
New-Item -ItemType Directory -Force $Out | Out-Null

$adbList = & $adb devices -l 2>&1 | Out-String
$adbList | Set-Content -Encoding utf8 "$Out\adb-devices.txt"
if ($adbList -match '\b(device|recovery|sideload)\b\s') {
    "ADB device found -> collecting read-only info into $Out"
    $q = [ordered]@{
        'getprop.txt'   = 'getprop'
        'df.txt'        = 'df -h'
        'mounts.txt'    = 'cat /proc/mounts'
        'bootreason.txt'= 'getprop sys.boot.reason; getprop ro.boot.bootreason; getprop ro.boot.slot_suffix'
        'battery.txt'   = 'dumpsys battery'
        'storage.txt'   = 'sm list-volumes all; sm list-disks'
    }
    foreach ($k in $q.Keys) { & $adb shell $q[$k] 2>&1 | Set-Content -Encoding utf8 "$Out\$k" }
    & $adb logcat -d -b all 2>&1 | Set-Content -Encoding utf8 "$Out\logcat.txt"
    & $adb shell 'dmesg 2>/dev/null || su -c dmesg' 2>&1 | Set-Content -Encoding utf8 "$Out\dmesg.txt"
} else {
    $fbList = & $fb devices 2>&1 | Out-String
    $fbList | Set-Content -Encoding utf8 "$Out\fastboot-devices.txt"
    if ($fbList -match 'fastboot') {
        "fastboot device found -> getvar all (read-only)"
        & $fb getvar all 2>&1 | Set-Content -Encoding utf8 "$Out\getvar-all.txt"
    } else { "No adb or fastboot device visible." }
}
"Saved to $Out"
