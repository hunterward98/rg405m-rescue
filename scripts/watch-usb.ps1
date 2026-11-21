<#
.SYNOPSIS
  Watches Windows for USB devices appearing/disappearing and identifies
  RG405M (Unisoc T618) boot modes. Read-only: it never talks to the device.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\watch-usb.ps1
#>
param([double]$IntervalSeconds = 1)

function Get-ModeGuess([string]$id) {
    switch -Regex ($id) {
        'VID_1782&PID_4D00'          { return 'UNISOC DOWNLOAD MODE (SPRD U2S Diag) - needs Unisoc driver' }
        'VID_1782'                   { return 'Unisoc/Spreadtrum device (Android ADB/MTP or fastboot)' }
        'VID_18D1&PID_4EE0'          { return 'FASTBOOT (bootloader)' }
        'VID_18D1&PID_D00D'          { return 'FASTBOOT (bootloader / fastbootd)' }
        'VID_18D1&PID_4EE7'          { return 'ANDROID ADB' }
        'VID_18D1'                   { return 'Google-ID Android device (ADB / MTP / fastboot)' }
        'VID_0000|DEVICE_DESCRIPTOR_FAILURE|PORT_RESET_FAILURE|SET_ADDRESS_FAILURE'
                                     { return 'USB DEVICE FAILED TO ENUMERATE - bad cable/port or device USB not ready' }
        default                      { return $null }
    }
}

function Get-Snapshot {
    $h = @{}
    Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
        Where-Object { $_.InstanceId -match '^(USB|USBSTOR|SWD\\WPDBUSENUM)' } |
        ForEach-Object { $h[$_.InstanceId] = $_ }
    return $h
}

$prev = Get-Snapshot
Write-Output ("[{0}] watching USB ({1} devices present). Plug in / change device mode now." -f (Get-Date -Format HH:mm:ss), $prev.Count)
[Console]::Out.Flush()

while ($true) {
    Start-Sleep -Milliseconds ([int]($IntervalSeconds * 1000))
    $cur = Get-Snapshot
    foreach ($k in $cur.Keys) {
        if (-not $prev.ContainsKey($k)) {
            $d = $cur[$k]
            $guess = Get-ModeGuess $k
            $tag = if ($guess) { " >>> $guess" } else { '' }
            Write-Output ("[{0}] ARRIVED  status={1} class={2} name='{3}' id={4}{5}" -f (Get-Date -Format HH:mm:ss), $d.Status, $d.Class, $d.FriendlyName, $k, $tag)
        }
    }
    foreach ($k in $prev.Keys) {
        if (-not $cur.ContainsKey($k)) {
            Write-Output ("[{0}] REMOVED  name='{1}' id={2}" -f (Get-Date -Format HH:mm:ss), $prev[$k].FriendlyName, $k)
        }
    }
    [Console]::Out.Flush()
    $prev = $cur
}
