```powershell

# ==============================================================

# LENOVO LEGION GO S – WERYFIKACJA FINAL

# Uruchom jako Administrator po wykonaniu Setup FINAL

# Raport: Pulpit -> LegionGoS_Raport.txt

# ==============================================================



if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

Write-Host "BLAD: Uruchom skrypt jako Administrator!" -ForegroundColor Red

pause

exit

}



# --------------------------------------------------------------

# AUTODETECT - identyczny jak w Setup FINAL

# --------------------------------------------------------------

$CPU = Get-CimInstance Win32_Processor

$Cores = $CPU.NumberOfCores

$CPUName = $CPU.Name

$RamGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)

$GPU = (Get-CimInstance Win32_VideoController | Where-Object { $_.Name -like "*AMD*" } | Select-Object -First 1).Name



if ($Cores -le 4) {

$Profil = "BALANS"

$ProfilLabel = "Z2 Go - Balans"

$HibernateDC = 45

$HibernateAC = 120

$AnimValue = 2

$GameDVRWymagany = $true

} else {

$Profil = "WYDAJNOSC"

$ProfilLabel = "Z1 Extreme - Wydajnosc"

$HibernateDC = 60

$HibernateAC = 180

$AnimValue = 3

$GameDVRWymagany = $false

}



$raport = @()

$raport += "============================================"

$raport += " LEGION GO S - RAPORT WERYFIKACJI FINAL"

$raport += " Data : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

$raport += " Profil : $ProfilLabel"

$raport += " CPU : $CPUName ($Cores rdzeni fizycznych)"

$raport += " RAM : $RamGB GB"

$raport += " GPU : $GPU"

$raport += "============================================"

$raport += ""



$ok = 0

$blad = 0



function Sprawdz($opis, $wynik) {

if ($wynik) {

$linia = "[OK] $opis"

Write-Host $linia -ForegroundColor Green

$script:ok++

} else {

$linia = "[BLAD] $opis"

Write-Host $linia -ForegroundColor Red

$script:blad++

}

$script:raport += $linia

}



function Info($opis) {

$linia = "[INFO] $opis"

Write-Host $linia -ForegroundColor DarkGray

$script:raport += $linia

}



Write-Host ""

Write-Host "============================================" -ForegroundColor Cyan

Write-Host " LEGION GO S - WERYFIKACJA FINAL" -ForegroundColor Cyan

Write-Host " Profil: $ProfilLabel" -ForegroundColor Cyan

Write-Host "============================================" -ForegroundColor Cyan



# --------------------------------------------------------------

Write-Host ""

Write-Host "--- Telemetria ---" -ForegroundColor Cyan

$raport += "--- Telemetria ---"



$tele = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name AllowTelemetry -EA SilentlyContinue).AllowTelemetry

Sprawdz "AllowTelemetry = 1 (Basic)" ($tele -eq 1)



# --------------------------------------------------------------

Write-Host ""

Write-Host "--- Game DVR (profil: $Profil) ---" -ForegroundColor Cyan

$raport += ""

$raport += "--- Game DVR (profil: $Profil) ---"



$dvr1 = (Get-ItemProperty "HKCU:\System\GameConfigStore" -Name GameDVR_Enabled -EA SilentlyContinue).GameDVR_Enabled

$dvr2 = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name AllowGameDVR -EA SilentlyContinue).AllowGameDVR



if ($GameDVRWymagany) {

Sprawdz "Game DVR zachowany (wymagany przez Xbox Game Pass)" ($dvr1 -ne 0 -or $null -eq $dvr1)

Info "AllowGameDVR w HKLM nie powinno byc ustawione na 0"

} else {

Sprawdz "GameDVR_Enabled = 0 (wylaczone)" ($dvr1 -eq 0)

Sprawdz "AllowGameDVR = 0 (wylaczone)" ($dvr2 -eq 0)

}



# --------------------------------------------------------------

Write-Host ""

Write-Host "--- OneDrive ---" -ForegroundColor Cyan

$raport += ""

$raport += "--- OneDrive ---"



$odProc = Get-Process "OneDrive" -EA SilentlyContinue

Sprawdz "OneDrive nie dziala w tle" ($null -eq $odProc)

$odPath = "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"

Sprawdz "Plik OneDrive.exe nie istnieje" (!(Test-Path $odPath))



# --------------------------------------------------------------

Write-Host ""

Write-Host "--- Xbox / Microsoft Store ---" -ForegroundColor Cyan

$raport += ""

$raport += "--- Xbox / Microsoft Store ---"



$xboxApp = Get-AppxPackage -Name "Microsoft.GamingApp" -EA SilentlyContinue

$xboxStore = Get-AppxPackage -Name "Microsoft.WindowsStore" -EA SilentlyContinue

Sprawdz "Xbox App zainstalowana" ($null -ne $xboxApp)

Sprawdz "Microsoft Store zainstalowany" ($null -ne $xboxStore)



# --------------------------------------------------------------

Write-Host ""

Write-Host "--- Blokada sterownikow ---" -ForegroundColor Cyan

$raport += ""

$raport += "--- Blokada sterownikow ---"



$drv = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name ExcludeWUDriversInQualityUpdate -EA SilentlyContinue).ExcludeWUDriversInQualityUpdate

Sprawdz "Sterowniki chronione przed Windows Update" ($drv -eq 1)



# --------------------------------------------------------------

Write-Host ""

Write-Host "--- Hibernacja (profil: $Profil) ---" -ForegroundColor Cyan

$raport += ""

$raport += "--- Hibernacja (profil: $Profil) ---"



$hibStatus = powercfg /a | Select-String "Hibernacja"

Sprawdz "Hibernacja dostepna w systemie" ($null -ne $hibStatus)

Sprawdz "Plik hiberfil.sys istnieje" (Test-Path "$env:SystemDrive\hiberfil.sys")



$acBtn = powercfg /query SCHEME_CURRENT SUB_BUTTONS PBUTTONACTION | Select-String "Ustawienie zasilania AC.*:\s*0x00000002"

Sprawdz "Przycisk Power (AC) = Hibernacja" ($null -ne $acBtn)

$dcBtn = powercfg /query SCHEME_CURRENT SUB_BUTTONS PBUTTONACTION | Select-String "Ustawienie zasilania DC.*:\s*0x00000002"

Sprawdz "Przycisk Power (DC) = Hibernacja" ($null -ne $dcBtn)



Info "Oczekiwane timouty: DC standby=15min, hib=$HibernateDC min | AC hib=$HibernateAC min"



# --------------------------------------------------------------

Write-Host ""

Write-Host "--- Animacje (profil: $Profil) ---" -ForegroundColor Cyan

$raport += ""

$raport += "--- Animacje (profil: $Profil) ---"



$anim = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name VisualFXSetting -EA SilentlyContinue).VisualFXSetting

Sprawdz "VisualFXSetting = $AnimValue" ($anim -eq $AnimValue)



# --------------------------------------------------------------

Write-Host ""

Write-Host "--- Memory Integrity ---" -ForegroundColor Cyan

$raport += ""

$raport += "--- Memory Integrity ---"



$hvci = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -EA SilentlyContinue).Enabled

Sprawdz "Memory Integrity wylaczone (zysk FPS)" ($hvci -eq 0)



# --------------------------------------------------------------

Write-Host ""

Write-Host "--- Punkt Przywracania ---" -ForegroundColor Cyan

$raport += ""

$raport += "--- Punkt Przywracania ---"



$punkt = Get-ComputerRestorePoint -EA SilentlyContinue | Where-Object { $_.Description -eq "STAN WYJSCIOWY" }

Sprawdz "Punkt przywracania STAN WYJSCIOWY istnieje" ($null -ne $punkt)



# --------------------------------------------------------------

Write-Host ""

Write-Host "--- Narzedzia (LLT + Adrenalin) ---" -ForegroundColor Cyan

$raport += ""

$raport += "--- Narzedzia (LLT + Adrenalin) ---"



$lltInstalled = ($null -ne (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -EA SilentlyContinue |

Where-Object { $_.DisplayName -like "*Legion Toolkit*" } | Select-Object -First 1)) -or

(Test-Path "$env:LOCALAPPDATA\Programs\LenovoLegionToolkit\LenovoLegionToolkit.exe")

Sprawdz "Lenovo Legion Toolkit zainstalowany" ($lltInstalled)



$adrenalinInstalled = $null -ne (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -EA SilentlyContinue |

Where-Object { $_.DisplayName -like "*AMD Software*" -or $_.DisplayName -like "*AMD Adrenalin*" } | Select-Object -First 1)

Sprawdz "AMD Adrenalin zainstalowany" ($adrenalinInstalled)



$islcTask = Get-ScheduledTask -TaskName "ISLC_Autostart" -EA SilentlyContinue

Sprawdz "ISLC zadanie w harmonogramie istnieje" ($null -ne $islcTask)



Info "Per-game FPS: AMD Chill w Adrenalin per gra"

Info "Per-game TDP: LLT Actions per gra"



# --------------------------------------------------------------

# PODSUMOWANIE

# --------------------------------------------------------------

$raport += ""

$raport += "============================================"

$raport += " PODSUMOWANIE"

$raport += "============================================"

$raport += " Zaliczone : $ok"

$raport += " Bledy : $blad"

if ($blad -eq 0) {

$raport += " WYNIK: WSZYSTKO OK - Legion gotowy do akcji!"

} else {

$raport += " WYNIK: $blad elementow wymaga uwagi."

$raport += " Sprawdz pozycje [BLAD] powyzej i wykonaj brakujace kroki recznie."

}

$raport += ""

$raport += "Konfiguracja per-game:"

if ($Profil -eq "BALANS") {

$raport += " AMD Chill AAA : Min 38 / Max 40 FPS (frame pacing 120Hz/3)"

$raport += " AMD Chill Indie: Min 48 / Max 60 FPS (VRR aktywny)"

} else {

$raport += " AMD Chill AAA : Min 46 / Max 50 FPS"

$raport += " AMD Chill Indie: Min 48 / Max 60 FPS (VRR aktywny)"

}

$raport += " LLT AAA : Tryb Performance, TDP 25-30W"

$raport += " LLT Indie : Tryb Balanced, TDP 10-15W"

$raport += " Ekran : 120 Hz / 800p"

$raport += " LLT : Battery Conservation Mode"

$raport += " Steam : Deadzone 3-5%"

$raport += "============================================"



Write-Host ""

Write-Host "============================================" -ForegroundColor Cyan

Write-Host " PODSUMOWANIE - profil $ProfilLabel" -ForegroundColor Cyan

Write-Host "============================================" -ForegroundColor Cyan

Write-Host " Zaliczone : $ok" -ForegroundColor Green

if ($blad -gt 0) {

Write-Host " Bledy : $blad" -ForegroundColor Red

} else {

Write-Host " Bledy : $blad" -ForegroundColor Green

}



$sciezka = "$env:USERPROFILE\Desktop\LegionGoS_Raport.txt"

$raport | Out-File -FilePath $sciezka -Encoding UTF8

Write-Host ""

Write-Host " Raport zapisany: LegionGoS_Raport.txt (Pulpit)" -ForegroundColor Cyan

Write-Host "============================================" -ForegroundColor Cyan

Write-Host ""

pause

```
