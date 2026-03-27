```powershell

# ==============================================================

# LENOVO LEGION GO S – SETUP FINAL

# Obsluguje: Z2 Go (4 rdzenie) i Z1 Extreme (8 rdzeni)

#

# FINAL: ISLC przez Task Scheduler (brak UAC przy starcie),

# Defender wykluczenia dla folderow gier,

# Memory Integrity wylaczone (zysk 5-15% FPS),

# usunieto RSR (bez sensu na natywnej rozdzielczosci 800p)

#

# Uruchom jako Administrator: kliknij PPM -> "Uruchom jako administrator"

# ==============================================================



if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

Write-Host "BLAD: Uruchom skrypt jako Administrator!" -ForegroundColor Red

pause

exit

}



# --------------------------------------------------------------

# AUTODETECT SPRZETU

# --------------------------------------------------------------

$CPU = Get-CimInstance Win32_Processor

$Cores = $CPU.NumberOfCores

$CPUName = $CPU.Name

$RamGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)

$GPU = (Get-CimInstance Win32_VideoController | Where-Object { $_.Name -like "*AMD*" } | Select-Object -First 1).Name



Write-Host "============================================" -ForegroundColor Cyan

Write-Host " LEGION GO S – SETUP FINAL" -ForegroundColor Cyan

Write-Host "============================================" -ForegroundColor Cyan

Write-Host ""

Write-Host " Wykryty sprzet:" -ForegroundColor White

Write-Host " CPU : $CPUName" -ForegroundColor DarkGray

Write-Host " RAM : $RamGB GB" -ForegroundColor DarkGray

Write-Host " GPU : $GPU" -ForegroundColor DarkGray

Write-Host " Rdzenie fizyczne: $Cores" -ForegroundColor DarkGray

Write-Host ""



# --------------------------------------------------------------

# WYBOR PROFILU NA PODSTAWIE LICZBY RDZENI

# Z2 Go = 4 rdzenie -> BALANS

# Z1E = 8 rdzeni -> WYDAJNOSC

# --------------------------------------------------------------

if ($Cores -le 4) {

$Profil = "BALANS"

$ProfilLabel = "Z2 Go - Balans wydajnosc/bateria"

$StandbyAC = 120

$StandbyDC = 15

$HibernateAC = 120

$HibernateDC = 45

$UsunGameDVR = $false

$AnimValue = 2

Write-Host " [PROFIL] $ProfilLabel" -ForegroundColor Green

} else {

$Profil = "WYDAJNOSC"

$ProfilLabel = "Z1 Extreme - Maksymalna wydajnosc"

$StandbyAC = 180

$StandbyDC = 30

$HibernateAC = 180

$HibernateDC = 60

$UsunGameDVR = $true

$AnimValue = 3

Write-Host " [PROFIL] $ProfilLabel" -ForegroundColor Magenta

}



Write-Host ""

$potwierdzenie = Read-Host "Kontynuowac z profilem $Profil? (T/N)"

if ($potwierdzenie -ne "T" -and $potwierdzenie -ne "t") {

Write-Host "Anulowano." -ForegroundColor Yellow

pause

exit

}

Write-Host ""



# --------------------------------------------------------------

# KROK 1: GAME DVR

# Z2 Go: zachowany (Xbox Game Pass wymaga GameConfigStore)

# Z1E: wylaczany (max wydajnosc)

# --------------------------------------------------------------

if ($UsunGameDVR) {

Write-Host "[KROK 1] Wylaczanie Game DVR..." -ForegroundColor Yellow

try {

reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f | Out-Null

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /t REG_DWORD /d 0 /f | Out-Null

Write-Host " OK." -ForegroundColor Green

} catch {

Write-Host " BLAD: $($_.Exception.Message)" -ForegroundColor Red

}

} else {

Write-Host "[KROK 1] Game DVR zachowany (Xbox Game Pass)." -ForegroundColor DarkGray

}



# --------------------------------------------------------------

# KROK 2: TELEMETRIA

# --------------------------------------------------------------

Write-Host "[KROK 2] Telemetria -> Basic..." -ForegroundColor Yellow

try {

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 1 /f | Out-Null

Write-Host " OK." -ForegroundColor Green

} catch {

Write-Host " BLAD: $($_.Exception.Message)" -ForegroundColor Red

}



# --------------------------------------------------------------

# KROK 3: PELNE USUNIECIE ONEDRIVE

# Etap A: oficjalny uninstaller

# Etap B: usuniecie ikony z Eksploratora (CLSID)

# Etap C: usuniecie folderu uzytkownika

# --------------------------------------------------------------

Write-Host "[KROK 3] Usuwanie OneDrive..." -ForegroundColor Yellow

taskkill /f /im OneDrive.exe 2>$null

Start-Sleep -Seconds 2



$onedrivePath = "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"

if (!(Test-Path $onedrivePath)) { $onedrivePath = "$env:SYSTEMROOT\System32\OneDriveSetup.exe" }

if (Test-Path $onedrivePath) {

try {

Start-Process $onedrivePath "/uninstall" -NoNewWindow -Wait

Write-Host " OK - deinstalacja zakonczona." -ForegroundColor Green

} catch {

Write-Host " BLAD deinstalacji: $($_.Exception.Message)" -ForegroundColor Red

}

} else {

Write-Host " INFO - OneDrive nie znaleziony (juz usuniety)." -ForegroundColor DarkGray

}



try {

$clsid = "{018D5C66-4533-4307-9B53-224DE2ED1FE6}"

Remove-Item -Path "HKCU:\Software\Classes\CLSID\$clsid" -Recurse -Force -ErrorAction SilentlyContinue

Remove-Item -Path "HKLM:\Software\Classes\CLSID\$clsid" -Recurse -Force -ErrorAction SilentlyContinue

Remove-Item -Path "HKLM:\Software\WOW6432Node\Classes\CLSID\$clsid" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host " OK - ikona OneDrive usunieta z Eksploratora." -ForegroundColor Green

} catch {

Write-Host " BLAD czyszczenia CLSID: $($_.Exception.Message)" -ForegroundColor Red

}



$oneDriveFolder = "$env:USERPROFILE\OneDrive"

if (Test-Path $oneDriveFolder) {

try {

Remove-Item -Path $oneDriveFolder -Recurse -Force -ErrorAction Stop

Write-Host " OK - folder OneDrive usuniety." -ForegroundColor Green

} catch {

Write-Host " INFO - folder w uzyciu, zostanie usuniety po restarcie." -ForegroundColor DarkYellow

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v PendingFileRenameOperations /t REG_MULTI_SZ /d "\??\$oneDriveFolder" /f | Out-Null

}

}



# --------------------------------------------------------------

# KROK 4: BLOKADA STEROWNIKOW W WINDOWS UPDATE

# --------------------------------------------------------------

Write-Host "[KROK 4] Blokada sterownikow w Windows Update..." -ForegroundColor Yellow

try {

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v ExcludeWUDriversInQualityUpdate /t REG_DWORD /d 1 /f | Out-Null

Write-Host " OK." -ForegroundColor Green

} catch {

Write-Host " BLAD: $($_.Exception.Message)" -ForegroundColor Red

}



# --------------------------------------------------------------

# KROK 5: HIBERNACJA

# --------------------------------------------------------------

Write-Host "[KROK 5] Hibernacja (profil $Profil)..." -ForegroundColor Yellow

try {

powercfg /h on

powercfg /change standby-timeout-ac $StandbyAC

powercfg /change standby-timeout-dc $StandbyDC

powercfg /change hibernate-timeout-ac $HibernateAC

powercfg /change hibernate-timeout-dc $HibernateDC

powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS PBUTTONACTION 2

powercfg /setdcvalueindex SCHEME_CURRENT SUB_BUTTONS PBUTTONACTION 2

powercfg /s SCHEME_CURRENT

Write-Host " OK." -ForegroundColor Green

} catch {

Write-Host " BLAD: $($_.Exception.Message)" -ForegroundColor Red

}



# Opcja awaryjna Modern Standby - odkomentuj jesli bateria spada mimo hibernacji:

# reg add "HKLM\System\CurrentControlSet\Control\Power" /v PlatformAoAcOverride /t REG_DWORD /d 0 /f



# --------------------------------------------------------------

# KROK 6: ANIMACJE SYSTEMU

# --------------------------------------------------------------

Write-Host "[KROK 6] Animacje systemu..." -ForegroundColor Yellow

try {

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d $AnimValue /f | Out-Null

Write-Host " OK." -ForegroundColor Green

} catch {

Write-Host " BLAD: $($_.Exception.Message)" -ForegroundColor Red

}



# --------------------------------------------------------------

# KROK 7: WINDOWS DEFENDER - wykluczenia folderow gier

# --------------------------------------------------------------

Write-Host "[KROK 7] Defender - wykluczenia folderow gier..." -ForegroundColor Yellow

try {

$foldery = @(

"C:\Program Files (x86)\Steam\steamapps",

"C:\SteamLibrary",

"C:\XboxGames",

"$env:USERPROFILE\AppData\Local\Packages\MicrosoftGamingApp_8wekyb3d8bbwe",

"$env:USERPROFILE\AppData\Roaming\Playnite"

)

foreach ($folder in $foldery) {

Add-MpPreference -ExclusionPath $folder -ErrorAction SilentlyContinue

}

Write-Host " OK - foldery gier wykluczone z skanowania." -ForegroundColor Green

} catch {

Write-Host " BLAD: $($_.Exception.Message)" -ForegroundColor Red

}



# --------------------------------------------------------------

# KROK 8: MEMORY INTEGRITY (VBS/HVCI) - wylaczenie

# Zysk 5-15% FPS w grach CPU-bound. Wymaga restartu.

# --------------------------------------------------------------

Write-Host "[KROK 8] Wylaczanie Memory Integrity (VBS/HVCI)..." -ForegroundColor Yellow

try {

$hvciPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"

if (!(Test-Path $hvciPath)) {

New-Item -Path $hvciPath -Force | Out-Null

}

Set-ItemProperty -Path $hvciPath -Name "Enabled" -Value 0 -Type DWord

Write-Host " OK - Memory Integrity wylaczone (wymaga restartu)." -ForegroundColor Green

} catch {

Write-Host " BLAD: $($_.Exception.Message)" -ForegroundColor Red

}



# --------------------------------------------------------------

# KROK 9: PUNKT PRZYWRACANIA "STAN WYJSCIOWY"

# --------------------------------------------------------------

Write-Host "[KROK 9] Punkt przywracania STAN WYJSCIOWY..." -ForegroundColor Yellow

try {

Enable-ComputerRestore -Drive "C:\" -ErrorAction Stop

Checkpoint-Computer -Description "STAN WYJSCIOWY" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop

Write-Host " OK." -ForegroundColor Green

} catch {

Write-Host " BLAD: $($_.Exception.Message)" -ForegroundColor Red

}



# --------------------------------------------------------------

# KROK 10: WINGET - cicha instalacja programow

# --------------------------------------------------------------

Write-Host ""

$wingetInstall = Read-Host "Zainstalowac Steam, Playnite i FXSound automatycznie? (T/N)"

if ($wingetInstall -eq "T" -or $wingetInstall -eq "t") {



$wingetOK = $null -ne (Get-Command winget -ErrorAction SilentlyContinue)



if ($wingetOK) {

Write-Host " Instalacja w tle - poczekaj..." -ForegroundColor Yellow



$apps = @(

@{ Id = "Valve.Steam"; Nazwa = "Steam" },

@{ Id = "Playnite.Playnite"; Nazwa = "Playnite" },

@{ Id = "FxSound.FxSound"; Nazwa = "FXSound" }

)



foreach ($app in $apps) {

Write-Host " Instaluje: $($app.Nazwa)..." -ForegroundColor DarkGray

try {

winget install --id $app.Id --silent --accept-package-agreements --accept-source-agreements | Out-Null

Write-Host " OK - $($app.Nazwa) zainstalowany." -ForegroundColor Green

} catch {

Write-Host " BLAD ($($app.Nazwa)): $($_.Exception.Message)" -ForegroundColor Red

}

}

} else {

Write-Host " INFO - winget niedostepny, otwieram strony recznie." -ForegroundColor DarkYellow

Start-Process "https://store.steampowered.com/about/"

Start-Sleep -Seconds 1

Start-Process "https://playnite.link"

Start-Sleep -Seconds 1

Start-Process "https://www.fxsound.com/download"

}

}



# --------------------------------------------------------------

# KROK 11: ISLC - zadanie w harmonogramie (brak UAC przy starcie)

# --------------------------------------------------------------

Write-Host ""

$islcPath = Read-Host "Podaj pelna sciezke do ISLC.exe (Enter = pomin jesli ISLC nie jest jeszcze zainstalowany)"

if ($islcPath -ne "" -and (Test-Path $islcPath)) {

Write-Host "[KROK 11] Tworzenie zadania ISLC w harmonogramie..." -ForegroundColor Yellow

try {

$action = New-ScheduledTaskAction -Execute $islcPath

$trigger = New-ScheduledTaskTrigger -AtLogOn

$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0

$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -RunLevel Highest

Register-ScheduledTask -TaskName "ISLC_Autostart" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null

Write-Host " OK - ISLC uruchamia sie przy logowaniu bez UAC." -ForegroundColor Green

} catch {

Write-Host " BLAD: $($_.Exception.Message)" -ForegroundColor Red

}

} else {

Write-Host "[KROK 11] ISLC pominiety - dodaj zadanie recznie po instalacji." -ForegroundColor DarkGray

Write-Host " Instrukcja: Krok 10 w Instrukcja_FINAL.txt" -ForegroundColor DarkGray

}



# --------------------------------------------------------------

# KROK 12: OTWIERANIE STRON

# --------------------------------------------------------------

Write-Host ""

$confirm = Read-Host "Otworzyc strony dla LLT, sterownikow Lenovo i ISLC? (T/N)"

if ($confirm -eq "T" -or $confirm -eq "t") {

Start-Process "https://support.lenovo.com/pl/pl/solutions/ht516335"

Start-Sleep -Seconds 1

Start-Process "https://github.com/BartoszCichecki/LenovoLegionToolkit/releases"

Start-Sleep -Seconds 1

Start-Process "https://www.wagnardsoft.com/forums/viewtopic.php?t=1256"

Start-Sleep -Seconds 1

if ($Profil -eq "BALANS") {

Start-Process "https://store.steampowered.com/app/993090/Lossless_Scaling/"

}

Write-Host " OK - strony otwarte." -ForegroundColor Green

}



# --------------------------------------------------------------

# KROK 13: DYSK ODZYSKIWANIA

# --------------------------------------------------------------

Write-Host ""

$recovery = Read-Host "Uruchomic kreator Dysku Odzyskiwania? Potrzebny pendrive 32 GB (T/N)"

if ($recovery -eq "T" -or $recovery -eq "t") {

Start-Process "recoverydrive.exe"

Write-Host " OK." -ForegroundColor Green

}



# --------------------------------------------------------------

# KONIEC

# --------------------------------------------------------------

Write-Host ""

Write-Host "============================================" -ForegroundColor Green

Write-Host " GOTOWE! Profil: $ProfilLabel" -ForegroundColor Green

Write-Host " Teraz postepuj wedlug Instrukcja_FINAL.txt" -ForegroundColor White

Write-Host ""

Write-Host " WAZNE: Uruchom ponownie konsole przed nastepnym" -ForegroundColor Yellow

Write-Host " krokiem - wymagane przez Memory Integrity." -ForegroundColor Yellow

Write-Host "============================================" -ForegroundColor Green

Write-Host ""

pause

```