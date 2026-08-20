@ECHO OFF
REM Build the Centreon NSClient++ x64 installer.
REM Expects, relative to this script:
REM   resources\scripts\x64\centreon\centreon_plugins.exe  (built beforehand)
REM   resources\nsclient.ini, resources\centreon.ico, resources\security\nrpe_dh_2048.pem
REM   resources\%MSI_NSCLIENT%  (downloaded beforehand)
REM Requires 7z and makensis on PATH (installed by the workflow).
REM PACKAGE_VERSION / PRODUCT_VERSION / MSI_NSCLIENT are passed via environment.

SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

CHDIR /d %~dp0

IF NOT DEFINED PACKAGE_VERSION SET PACKAGE_VERSION=00000000
IF NOT DEFINED PRODUCT_VERSION SET PRODUCT_VERSION=0.11.8
IF NOT DEFINED MSI_NSCLIENT SET MSI_NSCLIENT=NSCP-0.11.8-x64.msi

SET SETUP64=builddef-x64.nsi

REM --- assemble the build tree ---
RMDIR /S /Q build 2> NUL
MKDIR build
MKDIR build\scripts
MKDIR build\security
XCOPY resources\scripts\x64 build\scripts /E /S /Y 2> NUL
COPY resources\nsclient.ini build\nsclient.ini /Y 2> NUL
COPY resources\security\nrpe_dh_2048.pem build\security\nrpe_dh_2048.pem /Y 2> NUL
COPY resources\centreon.ico build\centreon.ico /Y 2> NUL

REM --- zip it (7-Zip from PATH) ---
DEL /F /Q resources\resources.zip 2> NUL
CHDIR build
7z a -tzip ..\resources\resources.zip .\ -r
SET ZIP_RC=!ERRORLEVEL!
CHDIR ..
IF NOT "%ZIP_RC%"=="0" (
    ECHO ERROR: 7z failed with exit code %ZIP_RC%
    EXIT /B %ZIP_RC%
)

REM --- build the installer (makensis from PATH) ---
makensis /V2 /DPRODUCT_VERSION=%PRODUCT_VERSION% /DPACKAGE_VERSION=%PACKAGE_VERSION% /DMSI_NSCLIENT=%MSI_NSCLIENT% %SETUP64%
SET NSIS_RC=!ERRORLEVEL!

REM --- cleanup ---
RMDIR /S /Q build 2> NUL
DEL /F /Q resources\resources.zip 2> NUL

IF NOT "%NSIS_RC%"=="0" (
    ECHO ERROR: makensis failed with exit code %NSIS_RC%
    EXIT /B %NSIS_RC%
)

ENDLOCAL
