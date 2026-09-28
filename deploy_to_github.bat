@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

echo ========================================================
echo   DEPLOIEMENT FLUTTER WEB SUR GITHUB PAGES
echo   URL: https://arisoftkario.github.io/great_minds/
echo ========================================================
echo.

:: Recuperer l'URL du remote git actuel
for /f "tokens=*" %%a in ('git remote get-url origin') do set REMOTE_URL=%%a

echo [1/3] Compilation du site Flutter Web pour great_minds...
call flutter build web --release --base-href "/great_minds/"
if errorlevel 1 (
    echo Erreur lors du build Flutter.
    pause
    exit /b 1
)

echo.
echo [2/3] Preparation des fichiers (.nojekyll et 404.html)...
copy /Y "build\web\index.html" "build\web\404.html" >nul
type nul > "build\web\.nojekyll"
if exist "build\web\CNAME" del /f /q "build\web\CNAME"

echo.
echo [3/3] Publication sur la branche gh-pages de GitHub (%REMOTE_URL%)...
cd build\web
if exist ".git" (
    rmdir /s /q ".git"
)
git init -b gh-pages
git config user.email "arisoftkario@users.noreply.github.com"
git config user.name "arisoftkario"
git add .
git commit -m "Deploy site web to https://arisoftkario.github.io/great_minds/"
git remote add origin %REMOTE_URL%
git push -f origin gh-pages

cd /d "%~dp0"

echo.
echo ========================================================
echo   SUCCES ! VOTRE SITE EST EN LIGNE
echo ========================================================
echo.
echo Votre site sera accessible sur :
echo   https://arisoftkario.github.io/great_minds/
echo.
echo ========================================================
pause
