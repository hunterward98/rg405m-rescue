<#
  READ-ONLY inspection of the RG405M microSD card in a PC card reader.
  Never formats, repairs, or writes. chkdsk runs WITHOUT /f (report only).
  If Windows pops "Scan and fix?" when you insert the card, choose
  "Continue without scanning" so nothing is changed.
#>
"=== Removable / SD disks ==="
$disks = Get-Disk | Where-Object { $_.BusType -in 'SD','USB','MMC' -or $_.Model -match 'SD|Card|Reader' }
$disks | Format-Table Number, FriendlyName, BusType, PartitionStyle, HealthStatus, OperationalStatus, @{n='SizeGB';e={[math]::Round($_.Size/1GB,1)}} -AutoSize
foreach ($d in $disks) {
    "=== Partitions on disk $($d.Number) ==="
    Get-Partition -DiskNumber $d.Number -ErrorAction SilentlyContinue |
        Format-Table PartitionNumber, DriveLetter, Type, @{n='SizeGB';e={[math]::Round($_.Size/1GB,1)}} -AutoSize
    Get-Partition -DiskNumber $d.Number -ErrorAction SilentlyContinue | Where-Object DriveLetter | ForEach-Object {
        $L = $_.DriveLetter
        "--- Volume ${L}: ---"
        Get-Volume -DriveLetter $L | Format-List FileSystem, FileSystemLabel, HealthStatus, SizeRemaining, Size
        "Top-level folders:"; Get-ChildItem "${L}:\" -Force -ErrorAction SilentlyContinue | Select-Object Mode, Name, Length | Format-Table -AutoSize
        "chkdsk (read-only, no /f):"; chkdsk "${L}:"
    }
}
"Partitions with no drive letter are likely ext4/f2fs (Android-formatted); Windows can't read those, which is normal."
