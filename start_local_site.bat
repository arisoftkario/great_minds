@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set PORT=8080

:find_available_port
netstat -ano | findstr /c:":%PORT% " | findstr /i "LISTENING" >nul
if errorlevel 1 goto start_site

set /a PORT+=1
if %PORT% LEQ 8090 goto find_available_port

echo Aucun port libre entre 8080 et 8090.
pause
exit /b 1

echo Lancement du serveur Flutter Web sur le port %PORT%...
echo Veuillez patienter pendant la compilation du projet (cela peut prendre 1 a 2 minutes)...
start "GREAT MINDS GROUP - Serveur local" /min cmd /c "flutter run -d web-server --web-hostname localhost --web-port %PORT%"
set /a ATTEMPTS=0

:wait_for_site
timeout /t 2 /nobreak >nul
netstat -ano | findstr /c:":%PORT% " | findstr /i "LISTENING" >nul
if not errorlevel 1 (
  echo Serveur pret ! Ouverture du navigateur sur http://localhost:%PORT%...
  timeout /t 1 /nobreak >nul
  start "" "http://localhost:%PORT%"
  exit /b 0
)

set /a ATTEMPTS+=1
set /a SECONDS_PASSED=!ATTEMPTS!*2
<nul set /p =.
if !ATTEMPTS! LSS 90 goto wait_for_site

echo.
echo Le delai d'attente est depasse (180s).
echo Si le serveur est encore en cours de compilation, le site sera bientot accessible sur http://localhost:%PORT%
pause
exit /b 1
