@ECHO OFF

SETLOCAL

SET CACHED_NUGET=%LocalAppData%\NuGet\NuGet.exe
SET SOLUTION_PATH="%~dp0src\CodeFormatter.sln"
SET VSWHERE_PATH="%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
SET MSBUILD15_TOOLS_PATH="%ProgramFiles(x86)%\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin\MSBuild.exe"
SET MSBUILD14_TOOLS_PATH="%ProgramFiles(x86)%\MSBuild\14.0\bin\MSBuild.exe"

IF EXIST %VSWHERE_PATH% (
  for /f "usebackq tokens=*" %%i in (`%VSWHERE_PATH% -latest -products * -requires Microsoft.Component.MSBuild -property installationPath`) do (
    set MSBUILD15_TOOLS_PATH="%%i\MSBuild\15.0\Bin\MSBuild.exe"
  )
)

SET BUILD_TOOLS_PATH=%MSBUILD15_TOOLS_PATH%

IF NOT EXIST %MSBUILD15_TOOLS_PATH% (
  echo In order to run this tool you need either Visual Studio 2017 or
  echo Microsoft Build Tools 2017 tools installed.
  echo.
  echo Visit this page to download either:
  echo.
  echo http://www.visualstudio.com/en-us/downloads/visual-studio-2017-downloads-vs
  echo.
  echo Attempting to fall back to Microsoft Build Tools 2015 ^(MSBuild 14^)
  echo.
  IF NOT EXIST %MSBUILD14_TOOLS_PATH% (
    echo Could not find MSBuild 14.  Please install build tools ^(See above^)
    exit /b 1
  ) else (
    set BUILD_TOOLS_PATH=%MSBUILD14_TOOLS_PATH%
  )
)

IF NOT EXIST %CACHED_NUGET% (
  echo Downloading latest version of NuGet.exe...
  IF NOT EXIST %LocalAppData%\NuGet md %LocalAppData%\NuGet
  @powershell -NoProfile -ExecutionPolicy unrestricted -Command "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest 'https://www.nuget.org/nuget.exe' -OutFile '%CACHED_NUGET%'"
  goto restore
)

FOR /f "tokens=3,4,5 delims=[]. " %%G in ('%CACHED_NUGET%') Do (SET NUGET_MAJOR=%%G& SET NUGET_MINOR=%%H& SET NUGET_BUILD=%%I& goto nuget_version_captured) 
:nuget_version_captured
IF %NUGET_MAJOR% LEQ 3 (
  echo Installed version of NuGet.exe is old. Attempting to upgrade to the latest version...
  echo.
  echo %CACHED_NUGET% update -self
  %CACHED_NUGET% update -self 
)

:restore
IF NOT EXIST src\packages md src\packages
%CACHED_NUGET% restore %SOLUTION_PATH%

%BUILD_TOOLS_PATH% %SOLUTION_PATH% /p:OutDir="%~dp0bin" /nologo /m /v:m /flp:verbosity=normal %*
