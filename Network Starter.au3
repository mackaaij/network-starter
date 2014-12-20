;Required for trayicon
#include <Constants.au3>
;Required for working with arrays
#include <Array.au3>
;To shutdown TCP on exit
Opt("OnExitFunc", "Endscript")

; Title of application
$windowtitle="Network Starter v2.5.000"

;Required for lookup
TCPStartup()

;Set script NOT to fail if executables cannot be started but to return a silent error to this script
AutoItSetOption("RunErrorsFatal",0)
;Set script NOT to have a menu on the trayicon (default is a pause option)
AutoItSetOption("TrayMenuMode",1)
;Set script NOT to pause if the trayicon is clicked
AutoItSetOption("TrayAutoPause",0)

;Array used to build information about which folders are found and programs to start from there
dim $arrayFolders_ToStart[1]
dim $popupRequest="The following will start in 10 seconds:"&@LF&@LF

;If more than one parameter is supplied return an error (one is the max and is optional)
If $CmdLine[0]>1 then
	MsgBox(4096 + 16,$windowtitle,"Usage: network starter.exe <optional base folder>")
	Exit
EndIf

;If a parameter is supplied check if it's an existing directory
If $CmdLine[0]=1 then
	
	;Take command line parameter as a base folder
	$BaseFolder = $CmdLine[1]
	
	;Strip trailing backslashes from working directory
	While StringRight($BaseFolder,1)="\"
		$BaseFolder=StringTrimRight ($BaseFolder,1)
	Wend
	;Add ONE trailing slash to the base folder
	$BaseFolder = $BaseFolder & "\"
		
	;Get attributes of Base Folder (used to check for existance and for verifying it's a folder and not a file)
	$attrib = FileGetAttrib($BaseFolder)
	If @error Then
		MsgBox(4096 + 16,$windowtitle,"Supplied folder (" & $BaseFolder & ") cannot be located." & @LF & "Usage: network starter.exe <optional base folder>")
		Exit
		Else
		If NOT StringInStr($attrib, "D") Then
		MsgBox(4096 + 16,$windowtitle,"Supplied folder (" & $BaseFolder & ") seems to be a file instead of a folder." & @LF & "Usage: network starter.exe <optional base folder>")
		Exit
		EndIf
	EndIf
	;Change the working directory to the base folder
	FileChangeDir($BaseFolder)
EndIf
;If no parameter is supplied then @WorkingDir is used as a starting point
If $CmdLine[0]=0 Then
	$BaseFolder = @WorkingDir
	;Add ONE trailing slash to the base folder
	$BaseFolder = $BaseFolder & "\"
EndIf

;Function Scan scans the supplied folder for folders and files
Func Scan($foldername)
	
	;Change the working directory to the supplied folder
	FileChangeDir($foldername)
		
	;Search the supplied folder for files
	$search = FileFindFirstFile("*.*")
	;If the supplied folder does not contain files return without an error (nothing has to run apparently)
	If $search = -1 Then Return
		
	;Add the current folder to the array
	_ArrayAdd($arrayFolders_ToStart,$foldername)
		
	;Add each found item (file or directory) to the $arrayFolders_ToStart
	While 1
		$file = FileFindNextFile($search)
		;An error means there are no more files left
		If @error Then ExitLoop
		
		;Add the found file/directory to the arrayposition of the foldername
		$arrayFolders_ToStart[UBound($arrayFolders_ToStart)-1]=$arrayFolders_ToStart[UBound($arrayFolders_ToStart)-1]&"|"&$file
	WEnd
	; Close the search handle
	FileClose($search)
	
	;Change the working directory back to the base folder
	FileChangeDir($BaseFolder)
EndFunc

;Request via a popup window (shows all programs about to be started)
Func popupRequest()
	For $i = 0 To UBound($arrayFolders_ToStart)-1
		$perFolder=StringSplit($arrayFolders_ToStart[$i],"|")
		
		;Add Foldernames to the popupRequest
		$popupRequest=$popupRequest&$perFolder[1]&@LF
		
		;Add filenames to the popupRequest
		For $k = 2 To UBound($perFolder)-1
			$popupRequest=$popupRequest&"- " & $perFolder[$k]&@LF
		Next
	Next
	
	;Msgbox System modal + OK and Cancel button + Question-mark icon
	$returnValue=MsgBox(4096+1+32,$windowtitle,$popupRequest,10)
	Switch $returnValue
	Case -1 to 1
		StartAll()
	Case 2
		; Quit if starting is not requested
		Exit;
	EndSwitch
EndFunc

;Start all programs from the array via the command shell
Func StartAll()
	For $i = 0 To UBound($arrayFolders_ToStart)-1
		$perFolder=StringSplit($arrayFolders_ToStart[$i],"|")
		
		;Loops through all the filenames
		For $k = 2 To UBound($perFolder)-1
			;Run the file (as: start "" "basefolder"filename)
			;The double quotes after the start commands are required by Windows for long filenames
			Run(@ComSpec & " /c start """" " & """" & $basefolder&$perFolder[1]&"\"&$perFolder[$k] & """", $BaseFolder, @SW_HIDE)	
		Next
	Next
	; Quit after starting programs
	Exit
EndFunc

;Search the base folder for directories and files
Func ScanFolder()
	$searchfolder = FileFindFirstFile("*.*")
	;If the base folder does not contain subdirectories return an error with reference to user manual
	If $searchfolder = -1 Then
		MsgBox(4096 + 16,$windowtitle,"Supplied folder (" & $BaseFolder & ") does not contain subfolders." & @LF & "Subfolders are resolved as a hostname and if this is possible the files within the 'reachable' folder are executed.")
		Exit
	EndIf
	;For each object check if it's a subdirectory and then run a resolve; if the folder is "resolvable" run the ScanAndRun function
	While 1
		$foldername = FileFindNextFile($searchfolder)
		;An error means there are no more directories left
		If @error Then ExitLoop
		
		;If the found object is a directory and not a file try to resolve it
		$attrib = FileGetAttrib($foldername)
		If StringInStr($attrib, "D") Then
			;Try to ping the foldername and if it exists run everything inside the folder
			Ping($foldername,250)
			If @error = 0 Then
				Scan($foldername)
			ElseIf @error = 2 Then
				;Since ping is sometimes blocked (as is the case at my employer) try to convert the name to an IP Address
				;Since TCPNameToIP will always return @error as 0 for IP addresses the function is only called for NON ip addresses
				If NOT IsIP($foldername) Then
					TCPNameToIP($foldername)
					If @error = 0 Then Scan($foldername)
				EndIf
			EndIf
		EndIf
	WEnd
	; Close the search handle
	FileClose($searchfolder)
EndFunc

;Main program starts here

;Scan the network every 5 seconds
For $i = 1 to 12
	TraySetToolTip ($windowtitle & " - Attempt  "&$i&"/12 of scanning the network")
	CheckAction()
	Sleep(5000)
Next

;Create tray items to click on if nothing was to be started
$retryitem      = TrayCreateItem("Retry")
$aboutitem       = TrayCreateItem("About")
$exititem       = TrayCreateItem("Exit")
TraySetToolTip ($windowtitle & " - click to rescan the network")
TraySetState()

; Loop waiting for action
While 1
    $msg = TrayGetMsg()
    Select
        Case $msg = 0
            ContinueLoop
        Case $msg = $retryitem
            CheckAction()
			TrayTip($windowtitle,"Nothing to start. Check these:"&@LF&@LF&"1. Is the (wireless) network available?"&@LF&"2. Do foldernames correspond with network devices in: "&$basefolder&"?"&@LF&"3. Are there items in these folders?",10,1)
        Case $msg = $aboutitem
            Msgbox(64,"About: " & $windowtitle,"Network Starter starts programs based on devices found on the connected network."&@LF&@LF&"Network Starter remains in your system tray so you can rescan the network in case of a network connection being actived later on."&@LF&"You can also close Network Starter via the system tray though.")
        Case $msg = $exititem
            ExitLoop
    EndSelect
WEnd
Exit

Func CheckAction()
	;ScanFolders
	ScanFolder()
	;$arrayFolders_ToStart contains a row per folder in which there are things to start
	;if _ArrayDelete failes there where no folders which led to a network detection which will result in a retry every 10 seconds
	_ArrayDelete($arrayFolders_ToStart,0)
	If @error = 0 Then popupRequest()
EndFunc

;Test whether the string is an IP address
Func IsIP($foldernameinternal)
	$array=StringSplit($foldernameinternal,".")
	
	;Check if string could be split
	If @error Then Return 0
		
	;Check whether there are 4 strings returned
	If $array[0]<>4 Then Return 0
	
	;Check if all 4 strings are numbers
	If StringIsInt($array[1]) And StringIsInt($array[2]) And StringIsInt($array[3]) And StringIsInt($array[4]) Then
		Return 1
	Else
		Return 0
	EndIf
EndFunc

Func Endscript()
	;Cleanup (was required for lookup)
	TCPShutdown()
EndFunc