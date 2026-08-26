@echo off
title Localhost Deployment Launcher
echo ===================================================
echo   AiDaily Cash Management - Localhost Deployment
echo ===================================================
echo.
echo Starting Backend Server on http://localhost:4000 ...
start "Backend API (Port 4000)" cmd /k "cd /d %~dp0\..\..\server && npm run dev"

echo Starting Frontend Dev Server on http://localhost:5174 ...
start "Frontend (Port 5174)" cmd /k "cd /d %~dp0\..\.. && npm run dev"

echo Starting Prisma Studio DB GUI on http://localhost:5555 ...
start "Prisma Studio (Port 5555)" cmd /k "cd /d %~dp0\..\..\server && npx prisma studio"

echo.
echo All services launched!
echo Access links:
echo   - Frontend UI:        http://localhost:5174
echo   - Backend API:         http://localhost:4000
echo   - Database GUI:        http://localhost:5555
echo   - Admin Analytics:     http://localhost:5174/app/admin
echo.
pause
