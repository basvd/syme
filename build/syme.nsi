# Name: Syme IRC
# Description: An IRC client that speaks Ruby.
# Version: 0.1
# Homepage: http://github.com/basvd/syme
# Copyright © 2010 Bas van Doren

# Basic information
!define AUTHOR    "Bas van Doren"
!define APP     "Syme"
!define LONGAPP   "${APP}"  # long application name (used in descriptions)
!define DESCRIPTION "An IRC client that speaks Ruby."
!define VER     "0.1.0.0" # using first two numbers

# Settings
!define EXE "bin\rubyw.exe"
!define EXEPARMS "app\src\SymeApp.rb"
!define PNAME "${APP}"
!define ICON "app.ico"
#!define SPLASHIMAGE "..\theme\syme-logo.png"

# Ruby environment variables
!include "app\env.nsh"

# Includes
!include "WordFunc.nsh"
!insertmacro "WordFind"
!include "FileFunc.nsh"
!insertmacro "GetParameters" # for command line parameters
#!define VAR_R0 10 #$R0 - needed for dialogs

# Compiler flags
SetCompress Auto
SetCompressor /SOLID /FINAL lzma
SetCompressorDictSize 32
SetDatablockOptimize On
OutFile "${PNAME}.exe"

# Runtime switches
CRCCheck On
WindowIcon Off
SilentInstall Silent
AutoCloseWindow True
SetOverwrite ifnewer
XPStyle On

# Working variables
Var APP_DIR # holds application directory
Var ENV_VAL # holds the value for an environment variable while it is being created

# Set basic information
Name "${LONGAPP}"
!ifdef ICON
  Icon "${ICON}"
!endif
Caption "${LONGAPP}"
OutFile "${PNAME}.exe"
RequestExecutionLevel user

# Set version information
LoadLanguageFile "${NSISDIR}\Contrib\Language files\English.nlf"
VIProductVersion "${VER}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "${LONGAPP}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "Comments" "${DESCRIPTION}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalCopyright" "By ${AUTHOR}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "CompanyName" ""
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileDescription" "${LONGAPP}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" "${VER}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductVersion" "${VER}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "InternalName" "${LONGAPP}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "OriginalFilename" "${PNAME}.exe"

# Main section
Section "Main"
  Call InitVars
  Call Init
  Call RunApp
SectionEnd

# Assign variable values
Function InitVars
  StrCpy "$APP_DIR" "$EXEDIR\app"
FunctionEnd

# Initialize environment
Function Init

  # Check whether EXE exists
  IfFileExists "$APP_DIR\${EXE}" FoundEXE
    # Program executable not where expected
    MessageBox MB_OK|MB_ICONEXCLAMATION `${EXE} was not found. Please check your configuration!`
    Abort # terminate Launcher
  FoundEXE:

  # Display splashscreen when available
  !ifdef SPLASHIMAGE
    InitPluginsDir
    File /oname=$PLUGINSDIR\splash.jpg "${SPLASHIMAGE}" 
    newadvsplash::show /NOUNLOAD 2500 200 200 -1 /L $PLUGINSDIR\splash.jpg
  !endif

  # Temporarily set Ruby environment variables for this process
  !ifdef ENV_RUBYOPT
    System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("RUBYOPT", "${ENV_RUBYOPT}").r0'
  !endif
  
  !ifdef ENV_RUBYLIB
    StrCpy "$R0" "${ENV_RUBYLIB}"
    Call EnvPaths
    System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("RUBYLIB", "$ENV_VAL").r0'
  !endif
  
  !ifdef ENV_GEM_PATH
    StrCpy "$R0" "${ENV_GEM_PATH}"
    Call EnvPaths
    System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("GEM_PATH", "$ENV_VAL").r0'
  !endif
  
  InitEnd:
FunctionEnd

# Run application
Function RunApp
  ${GetParameters} "$R0" # obtain commandline parameters
  !ifdef EXEPARMS
    StrCmp "$R0" "" 0 +2
      StrCpy "$R0" "${EXEPARMS}"
  !endif
  #SetOutPath "$EXEDIR" # current working dir

  # Start program
  ExecWait '"$APP_DIR\${EXE}" $R0' # run program
  RunAppEnd:
FunctionEnd

# Assigns resolved paths to ENV_VAL for use as environment variable
Function EnvPaths 
   # copy constant to working variable
  Call ValuesToStack # separate values
  
  StrCpy "$ENV_VAL" ""
  InitEnvLoop:
    Pop "$R9" # obtain directory from stack
    StrCmp "$R9" "EndOfStack" InitEnvEnd # stop directory parsing, when no directory given anymore
      StrCmp "$ENV_VAL" "" 0 +3
        StrCpy "$ENV_VAL" "$APP_DIR\$R9"
        Goto InitEnvLoop
      StrCpy "$ENV_VAL" "$ENV_VAL;$APP_DIR\$R9"
      Goto InitEnvLoop
  InitEnvEnd:
FunctionEnd

Function ValuesToStack
  StrCpy "$0" "0" # reset counter
  
  # Get single parameter out of list
  Push "EndOfStack" # set end marker for stack
  ValuesToStackStart:
    StrCmp "$R0" "" ValuesToStackEnd # stop registry parsing, when no keys given anymore
      IntOp "$0" "$0" + 1 # increase counter
      ${WordFind} "$R0" ";" "-01" "$9" # save last parameter to register
      ${WordFind} "$R0" ";" "-02{*"  "$R0" # remove last part from saved value
      Push $9 # save parameter to stack
      StrCmp "$R0" "$9" ValuesToStackEnd # if values are identical (last parameter) -> no more delimiters
    Goto ValuesToStackStart
  ValuesToStackEnd:
FunctionEnd
