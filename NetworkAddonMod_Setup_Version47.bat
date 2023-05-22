@Echo Off

:WhatIsThis
  :: ---------------------------------------------------------------------
  ::  This is a command script written by Tarkus (Alex) and Cori to apply
  ::  the 4 GB Patch to SimCity 4.exe and check that it was successful.
  ::  Latest revision by Apothocary.
  :: ---------------------------------------------------------------------

:Show
  Echo.
  Echo SimCity4_4GB_Patch_Script_v3.bat
  Echo --------------------------------
  Echo This command script automates applying the 4 GB Patch to SimCity 4.exe.
  Echo.

:Check
  :: See if the 4gb_patch.exe file is in the same folder as this script.
  If NOT Exist 4gb_patch.exe Goto :Missing
  
:Check
  :: See if the laac file is in the same folder as this script.
  If NOT Exist laac.exe Goto :MissingLaac

:Start
  :: This block peeks inside the registry to find the expected location of the SimCity 4.exe file.
  FOR /F "usebackq tokens=3,* skip=2" %%L IN (
      `reg query "HKLM\SOFTWARE\WOW6432Node\Maxis\SimCity 4" /v "Install Dir"`
  ) DO SET sc4dir=%%M\Apps

:AnotherSetCommand
  :: Creates a variable we can use later.
  SET GameExe=SimCity 4.exe

:CheckLocation
  :: Check in the folder specified by the registry to make sure SimCity 4.exe is found there.
  If NOT Exist "%sc4dir%\%GameExe%" Goto :LostFile

:SaveBeforeDateTime
   :: Create a temporary file containing the last modified date and time of SimCity 4.exe before running the 4gb_patch.exe program.
   Dir "%sc4dir%\%GameExe%" /T:W | FIND /i "SimCity 4.exe" > %temp%\TempDateTimeCheckBefore.txt"

:ApplyPatch
  :: Run the patch program on the game file. Wait till that completes before proceeding with additional commands in this script.
  Start "" /wait 4gb_patch.exe "%sc4dir%\SimCity 4.exe"

:SaveAfterDateTime
   :: Create a temporary file containing the last modified date and time of SimCity 4.exe after running the 4gb_patch.exe program.
   Dir "%sc4dir%\%GameExe%" /T:W | FIND /i "SimCity 4.exe" > %temp%\TempDateTimeCheckAfter.txt"

:CompareDateTime
  :: Use the OS's FC (File Compare) program to see if the two text files are the same or different.
  ::   In this case, we actually want the compare to fail and say they are not identical.
  ::   Note that the ErrorLevel inquiry must be checked from highest to lowest because it means 'at least' whatever number is checked.
  ::   We redirect the output to NUL so only our messages will show depending on the outcome.
  FC %temp%\TempDateTimeCheckBefore.txt %temp%\TempDateTimeCheckAfter.txt > NUL

  :: Error 2 is if one or both of the files to compare are not found. (This should not happen, but we check just in case.)
  If ErrorLevel 2 Goto :Error

  :: Error 1 is when the files are not identical. In this case, that's what we want to see.
  If ErrorLevel 1 Goto :Success

  :: If the Error is zero, then the files match. In this case it tells us SimCity 4.exe was not patched.
  ::   This is a "fall thru" where neither of the above ErrorLevel checks execute their Goto.
  Goto :Fail
  
:RunCheck
  :: Run "laac.exe" to verify patch is working correctly.
  Echo.
  Echo Running LargeAddressAwareChecker...
  Start "" cmd /C "laac.exe "%sc4dir%\%GameExe%" > laac_output.txt && pause"
  Echo Verifying if the patch is working correctly...
  
  :: Wait for 4 SECONDS to let "laac.exe" finish running and output to laac_output.txt
  TIMEOUT /T 4 /NOBREAK >NUL

  :: Check the output in laac_output.txt for "LARGEADDRESSAWARE ON"
  FIND "LARGEADDRESSAWARE ON" laac_output.txt >NUL
  IF ERRORLEVEL 1 (
      ECHO * * * ERROR * * *
      ECHO Verfication Unsuccessful
      GOTO :LaacError
  ) ELSE (
      ECHO SUCCESS -- the patch is working correctly!
      GOTO :CleanUp
  )
  
:Missing
  :: This is the message displayed if we did not find 4gb_patch.exe in the same folder as this script file.
  Echo.
  Echo * * * ERROR * * *
  Echo.
  Echo The 4gb_patch.exe file was not found in this folder.
  Goto :Exit
  
:MissingLaac
  :: This is the message displayed if we did not find laac in the same folder as this script file.
  Echo.
  Echo * * * ERROR * * *
  Echo.
  Echo The "laac" file was not found in this folder.
  Goto :Exit

:LostFile
  :: This is the message displayed if we did not find SimCity 4.exe where the registry says it should be.
  Echo.
  Echo * * * ERROR * * *
  Echo.
  Echo "%sc4dir%\%GameExe%"
  Echo   was not found as expected.
  Goto :Exit

:Error
  :: This is the message if the File Compare of our temp text files failed.
  ::  (Should never happen, but could if writing to the TEMP folder is denied.)
  Echo.
  Echo * * * ERROR * * *
  Echo.
  Echo Temp file creation for checking the date / time stamp failed.
  Echo   Look at the following and check if the date and time is current:
  Echo.
  Dir "%sc4dir%\%GameExe%" /T:W | FIND /i "SimCity 4.exe"
  Goto :Cleanup

:Fail
  :: This is the message if the file compare shows the date and time of SimCity 4.exe to be the same before and after trying to patch it.
  Echo.
  Echo * * * ERROR * * *
  Echo.
  Echo The 4 GB Patch was NOT applied :(
  Goto :CleanUp
  
:LaacError
  :: This is the message if there is an error running "laac.exe"
  Echo.
  Echo * * * ERROR * * *
  Echo.
  Echo There was an error verifying the patch is working correctly. Please re-run this BAT file.
  Goto :CleanUp

:Success
  :: This is the message if the file compare shows the date and time of SimCity 4.exe to be different before and after patching it.
  Echo.
  Echo The 4 GB Patch was successfully applied.
  Goto :RunCheck
  
    :: If the Error is zero, then the files match. In this case it tells us SimCity 4.exe was not patched.
  ::   This is a "fall thru" where neither of the above ErrorLevel checks execute their Goto.
  Goto :Fail

:CleanUp
  :: This simply removes the two temp text files we created if they exist in the TEMP folder.
  If Exist %temp%\TempDateTimeCheckBefore.txt Del %temp%\TempDateTimeCheckBefore.txt
  If Exist %temp%\TempDateTimeCheckAfter.txt Del %temp%\TempDateTimeCheckAfter.txt
  If Exist laac_output.txt Del laac_output.txt

:Exit
  :: All done. We wait for the user to press the 'ANY' key before closing the Dos Command Window.
  Echo.
  Pause
  
  start /min cmd /C "java -jar NetworkAddonMod_Setup_Version47.jar || %windir%\SysWOW64\java -jar NetworkAddonMod_Setup_Version47.jar"