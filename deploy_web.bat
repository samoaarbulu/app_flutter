@echo off
setlocal

set "APP_DIR=d:\proyectos\creds\app_flutter"
set "DIST_DIR=d:\proyectos\creds\app_web_build"
set "REPO_URL=https://github.com/samoaarbulu/demo_app_html.git"

echo [1/4] Limpiando cache y compilando Flutter Web (Release)...
cd /d "%APP_DIR%"
if exist ".dart_tool\flutter_build" rd /s /q ".dart_tool\flutter_build"
call flutter build web --release
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Fallo al compilar flutter build web.
    pause
    exit /b %ERRORLEVEL%
)

if not exist "%APP_DIR%\build\web\manifest.json" (
    echo ERROR: Build incompleto - falta build\web\manifest.json.
    pause
    exit /b 1
)
if not exist "%APP_DIR%\build\web\assets\FontManifest.json" (
    echo ERROR: Build incompleto - falta build\web\assets\FontManifest.json.
    pause
    exit /b 1
)

echo [2/4] Verificando carpeta de despliegue...
if not exist "%DIST_DIR%" mkdir "%DIST_DIR%"
cd /d "%DIST_DIR%"
if not exist ".git" (
    git init
    git branch -M main
    git remote add origin "%REPO_URL%"
)

echo [3/4] Copiando HTML compilado a app_web_build...
robocopy "%APP_DIR%\build\web" "%DIST_DIR%" /MIR /XD .git /XF Dockerfile nginx.conf .dockerignore
if %ERRORLEVEL% GEQ 8 (
    echo ERROR: Fallo al copiar los archivos con robocopy.
    pause
    exit /b %ERRORLEVEL%
)

echo [4/4] Haciendo commit y push hacia demo_app_html...
cd /d "%DIST_DIR%"
git add -A
git diff --cached --quiet
if %ERRORLEVEL% NEQ 0 (
    git commit -m "deploy: actualizacion web"
) else (
    echo No hay cambios nuevos en el build respecto al ultimo commit.
)

git push -u origin main
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR al hacer git push. Si el repo en GitHub tenia un README inicial,
    echo puedes ejecutar manualmente: git push -u origin main --force
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Listo! Coolify desplegara la nueva version automaticamente.
pause
