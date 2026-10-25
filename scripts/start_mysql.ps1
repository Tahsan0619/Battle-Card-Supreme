# Start / recover XAMPP MariaDB for Battle Card Supreme.
$ErrorActionPreference = 'Stop'
$mysqld = 'C:\xampp\mysql\bin\mysqld.exe'
$mysql = 'C:\xampp\mysql\bin\mysql.exe'
$ini = 'C:\xampp\mysql\bin\my.ini'
$pidFile = 'C:\xampp\mysql\data\mysql.pid'

if (-not (Test-Path $mysqld)) {
  Write-Error "XAMPP MySQL not found at $mysqld"
}

$listening = Get-NetTCPConnection -LocalPort 3306 -State Listen -ErrorAction SilentlyContinue
if ($listening) {
  Write-Host "MySQL already listening on 3306 (PID $($listening.OwningProcess))"
  & $mysql -u root -e "SELECT VERSION() AS version;"
  exit 0
}

# Stale pid after crash blocks some start paths.
if (Test-Path $pidFile) {
  $old = Get-Content $pidFile | Select-Object -First 1
  $alive = $null
  if ($old) { $alive = Get-Process -Id ([int]$old) -ErrorAction SilentlyContinue }
  if (-not $alive) {
    Remove-Item $pidFile -Force
    Write-Host "Removed stale mysql.pid"
  }
}

Write-Host "Starting MariaDB..."
Start-Process -FilePath $mysqld -ArgumentList "--defaults-file=$ini","--standalone","--console" -WorkingDirectory 'C:\xampp\mysql\bin' -WindowStyle Hidden
$ok = $false
for ($i = 0; $i -lt 20; $i++) {
  Start-Sleep -Seconds 1
  if (Get-NetTCPConnection -LocalPort 3306 -State Listen -ErrorAction SilentlyContinue) {
    $ok = $true
    break
  }
}
if (-not $ok) {
  Write-Error "MySQL failed to open port 3306. Check C:\xampp\mysql\data\mysql_error.log"
}
Write-Host "MySQL is up."
& $mysql -u root -e "SELECT VERSION() AS version;"
