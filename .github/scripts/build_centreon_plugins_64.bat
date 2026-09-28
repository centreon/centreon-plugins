@ECHO OFF

set PERL_INSTALL_DIR=C:\Strawberry

CHDIR /d %~dp0

REM The PAR loader is intentionally NOT rebuilt here. Rebuilding it (to inject
REM the Centreon icon) made recursive_objdump fail to embed perl5xx.dll and its
REM runtime DLLs, producing a non-self-contained exe ("perl5xx.dll not found" on
REM machines without Strawberry). We keep pp's stock StrippedPARL, which bundles
REM the Perl runtime correctly. The custom icon/version is meant to be applied
REM after packing (e.g. rcedit) rather than by rebuilding the loader.

REM Ensure the Strawberry toolchain is first on PATH for pp and its objdump scan.
SET "PATH=%PERL_INSTALL_DIR%\perl\bin;%PERL_INSTALL_DIR%\perl\site\bin;%PERL_INSTALL_DIR%\c\bin;%PATH%"

SET PAR_VERBATIM=1

REM Build the pp argument list in a file (one token per line) and run pp through
REM run-pp.pl. This bypasses cmd's ~8191-char command-line length limit, which the
REM long -M / --link list exceeds once libcurl's dependency closure is linked.
SET "PP_ARGS=pp-args.txt"
DEL /F /Q %PP_ARGS% 2>NUL

SETLOCAL EnableDelayedExpansion
REM Standard native libraries, resolved by prefix (version-agnostic). Link EVERY
REM match, not just the first: Strawberry ships its own libs with a "__" suffix
REM (e.g. libssl-3-x64__.dll) while the mingw libcurl closure adds non-suffixed
REM ones (libssl-3-x64.dll). Net::SSLeay needs Strawberry's build, Net::Curl needs
REM mingw's -- both must be bundled (different filenames, so they coexist).
SET "LINKED= "
FOR %%L IN (libxml2-2 libiconv-2 liblzma-5 zlib1 libcrypto libssl) DO (
    SET "FOUND="
    FOR /f "delims=" %%F IN ('DIR /b "%PERL_INSTALL_DIR%\c\bin\%%L*.dll" 2^>nul') DO (
        SET "FOUND=1"
        ECHO !LINKED! | FIND /I " %%F " >NUL
        IF ERRORLEVEL 1 (
            ECHO --link=%PERL_INSTALL_DIR%\c\bin\%%F >>%PP_ARGS%
            SET "LINKED=!LINKED!%%F "
        )
    )
    IF NOT DEFINED FOUND ECHO WARNING: no DLL matching %%L*.dll found in %PERL_INSTALL_DIR%\c\bin
)
REM libcurl-4.dll and its full dependency closure (recorded by setup-strawberry-perl),
REM so Net::Curl::Easy loads at runtime. Skip any DLL already linked above.
IF EXIST "%PERL_INSTALL_DIR%\c\bin\curl-deps.txt" (
    FOR /f "usebackq delims=" %%D IN ("%PERL_INSTALL_DIR%\c\bin\curl-deps.txt") DO (
        ECHO !LINKED! | FIND /I " %%D " >NUL
        IF ERRORLEVEL 1 (
            ECHO --link=%PERL_INSTALL_DIR%\c\bin\%%D >>%PP_ARGS%
            SET "LINKED=!LINKED!%%D "
        )
    )
) ELSE (
    ECHO WARNING: curl-deps.txt not found; libcurl closure will not be linked
)
ENDLOCAL

REM Static pp options and the entry script.
(
    ECHO --lib=centreon-plugins\src\
    ECHO -o resources\scripts\x64\centreon\centreon_plugins.exe
    ECHO centreon-plugins\src\centreon_plugins.pl
    ECHO --unicode
    ECHO -X IO::Socket::INET6
    ECHO --verbose
)>>%PP_ARGS%

REM Perl modules to embed (pp cannot auto-discover the dynamically loaded modes).
FOR /f "usebackq eol=# delims=" %%M IN ("windows\pp-modules.txt") DO ECHO -M %%M >>%PP_ARGS%

perl windows\run-pp.pl %PP_ARGS%
SET PP_RC=%ERRORLEVEL%

DEL /F /Q %PP_ARGS% 2>NUL

IF NOT "%PP_RC%"=="0" (
    ECHO ERROR: pp failed with exit code %PP_RC%
    EXIT /B %PP_RC%
)
