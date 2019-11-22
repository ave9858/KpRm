#RequireAdmin

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=assets\bug.ico
#AutoIt3Wrapper_Outfile=KpRm.exe
#AutoIt3Wrapper_Res_Description=KpRm By Kernel-Panik
#AutoIt3Wrapper_Res_Comment=Delete all removal tools
#AutoIt3Wrapper_Res_Fileversion=56
#AutoIt3Wrapper_Res_ProductName=KpRm
#AutoIt3Wrapper_Res_ProductVersion=1.22
#AutoIt3Wrapper_Res_CompanyName=kernel-panik
#AutoIt3Wrapper_Res_requestedExecutionLevel=requireAdministrator
#AutoIt3Wrapper_Res_File_Add=.\assets\bug.gif
#AutoIt3Wrapper_Res_File_Add=.\assets\close.gif
#AutoIt3Wrapper_Res_File_Add=.\config\tools.xml
#AutoIt3Wrapper_Res_File_Add=.\binaries\hobocopy32\HoboCopy.exe
#AutoIt3Wrapper_Res_File_Add=.\binaries\hobocopy32\msvcp100.dll
#AutoIt3Wrapper_Res_File_Add=.\binaries\hobocopy32\msvcr100.dll
#AutoIt3Wrapper_Res_File_Add=.\binaries\hobocopy64\HoboCopy.exe
#AutoIt3Wrapper_Res_File_Add=.\binaries\hobocopy64\msvcp100.dll
#AutoIt3Wrapper_Res_File_Add=.\binaries\hobocopy64\msvcr100.dll
#AutoIt3Wrapper_Res_File_Add=.\binaries\KPAutoUpdater\KPAutoUpdater.exe
#AutoIt3Wrapper_Res_LegalCopyright=kernel-panik
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/rm /sf=1 /sv=1
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include-once
#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <StringConstants.au3>
#include <WindowsConstants.au3>
#include <MsgBoxConstants.au3>
#include <AutoItConstants.au3>
#include <FileConstants.au3>
#include <GuiListView.au3>
#include <GuiTab.au3>
#include <Date.au3>
#include <WinAPI.au3>
#include <WinAPIProc.au3>
#include <WinAPIShellEx.au3>
#include <WinAPIFiles.au3>
#include <WinAPIEx.au3>
#include <SendMessage.au3>
#include <Array.au3>
#include <File.au3>


Global $sTmpDir = @TempDir & "\KPRM"

If FileExists($sTmpDir) Then
	DirRemove($sTmpDir, $DIR_REMOVE)
EndIf

DirCreate($sTmpDir)

FileInstall(".\assets\bug.gif", $sTmpDir & "\kprm-logo.gif")
FileInstall(".\assets\close.gif", $sTmpDir & "\kprm-close.gif")

Global $bKpRmDev = True
Global $sKprmVersion = "Dev.01"

If $bKpRmDev = True Then
	AutoItSetOption("MustDeclareVars", 1)
EndIf

Local Const $sLang = GetLanguage()

If $sLang = "fr" Then
	#include "locales\fr.au3"
ElseIf $sLang = "de" Then
	#include "locales\de.au3"
ElseIf $sLang = "it" Then
	#include "locales\it.au3"
ElseIf $sLang = "es" Then
	#include "locales\es.au3"
ElseIf $sLang = "pt" Then
	#include "locales\pt.au3"
ElseIf $sLang = "ru" Then
	#include "locales\ru.au3"
ElseIf $sLang = "nl" Then
	#include "locales\nl.au3"
Else
	#include "locales\en.au3"
EndIf

#include "libs\UAC.au3"
#include "libs\Permissions.au3"
#include "libs\_XMLDomWrapper.au3"
#include "libs\taskplanerCOM.au3"
#include "includes\actions_restart.au3"
#include "includes\utils.au3"
#include "includes\progress_bar.au3"
#include "includes\restore_points.au3"
#include "includes\registry_slow.au3"
#include "includes\registry.au3"
#include "includes\restore_uac.au3"
#include "includes\restore_system_settings.au3"
#include "includes\tools_remove.au3"
#include "includes\tools_import.au3"
#include "includes\delete_later.au3"
#include "includes\custom_search.au3"

If UBound($CmdLine) > 1 Then
	Local $sAction = $CmdLine[1]
	$sAction = StringStripWS($sAction, $STR_STRIPLEADING + $STR_STRIPTRAILING)

	If $sAction = 'restart' Then
		ExecuteScriptFile($CmdLine[2])
	ElseIf $sAction = 'quarantines' Then
		RemoveQuarantines($CmdLine[2])
	EndIf

	Exit
EndIf

If Not IsAdmin() Then
	MsgBox(16, $lFail, $lAdminRequired)
	QuitKprm()
EndIf

If $bKpRmDev = False Then
	CheckVersionOfKpRm()
EndIf

Local Const $iEULAisOK = MsgBox(BitOR($MB_YESNO, $MB_ICONINFORMATION), "Disclaimer of warranty!", "Disclaimer of warranty!" & @CRLF & @CRLF _
		 & 'This software is provided "AS IS" without warranty of any kind.' & @CRLF _
		 & 'You may use this software at your own risk.' & @CRLF & @CRLF _
		 & 'This software is not permitted for commercial purposes.' & @CRLF & @CRLF _
		 & 'Are you sure you want to continue?' & @CRLF & @CRLF _
		 & 'Click Yes to continue. Click No to exit.')

If $iEULAisOK <> $IDYES Then Exit

Global $sProgramName = "KpRm"
Global $sCurrentTime = @YEAR & @MON & @MDAY & @HOUR & @MIN & @SEC
Global $sCurrentHumanTime = @YEAR & '-' & @MON & '-' & @MDAY & '-' & @HOUR & '-' & @MIN & '-' & @SEC
Global $sKPLogFile = "kprm-" & $sCurrentTime & ".txt"
Global $bRemoveToolLastPass = False
Global $bPowerShellAvailable = Null
Global $bDeleteQuarantines = Null
Global $bSearchOnly = False
Global $bSearchOnlyHasFoundElement = False
Global $aRemoveRestart = []
Global $bNeedRestart = False
Global $aElementsToKeep[1][2] = [[]]
Global $aElementsFound[1][2] = [[]]

Local Const $pLeft = 16
Local Const $pRight = 220
Local Const $pPadding1 = 8
Local Const $pWidth1 = 400
Local Const $pCtrSize = 17
Local Const $pButtonDetectionHeight = 39
Local Const $pButtonDetectionPT = 31
Local Const $pStep = 36
Local Const $cWhite = 0xFFFFFF
Local Const $cBlack = 0x1a1a1a
Local Const $cDisabled = 0x2a2a2a
Local Const $cBlue = 0x63c0f5
Local Const $cGreen = 0xb5e853
Local Const $cRed = 0xf74432
Local Const $SC_DRAGMOVE = 0xF012

Local Const $oTabSwitcher[2] = []

Local Const $oMainWindow = GUICreate($sProgramName & " v" & $sKprmVersion & " by kernel-panik", 500, 263, 202, 112, BitOR($WS_POPUP,$WS_BORDER), $WS_EX_TOPMOST))
GUICtrlSetDefColor($cWhite)

Local Const $oTitleGUI = GUICtrlCreateLabel("KpRm By Kernel-panik v" & $sKprmVersion, $pPadding1, $pPadding1)
GUICtrlSetColor($oTitleGUI, $cBlue)

Global $oHStatus = GUICtrlCreateLabel("Ready...", $pPadding1, 220, 800, $pCtrSize)
GUICtrlSetColor($oHStatus, $cBlue)

Local Const $oCloseButton = GUICtrlCreatePic($sTmpDir & "\kprm-close.gif", 475, 5, 20, 20)

Local Const $oTabSwitcher1 = GUICtrlCreateLabel($lAuto, 238, 5, 80, 20, $SS_SUNKEN + $SS_CENTER + $SS_CENTERIMAGE)
GUICtrlSetBkColor($oTabSwitcher1, $cGreen)
GUICtrlSetColor($oTabSwitcher1, $cBlack)

Local Const $oTabSwitcher2 = GUICtrlCreateLabel($lCustom, 326, 5, 80, 20, $SS_SUNKEN + $SS_CENTER + $SS_CENTERIMAGE)
GUICtrlSetBkColor($oTabSwitcher2, $cDisabled)
GUICtrlSetColor($oTabSwitcher2, $cBlue)

Local Const $oTabs = GUICtrlCreateTab(10, 40, 200, 200)
GUICtrlSetState($oTabs, $GUI_HIDE)

Local Const $oTab1 = GUICtrlCreateTabItem("tab1")
Local Const $oPic1 = GUICtrlCreatePic($sTmpDir & "\kprm-logo.gif", 415, 50, 75, 75)

XPStyle(1)
Global $oProgressBar = GUICtrlCreateProgress(0, 245, 500, $pCtrSize)
GUICtrlSetBkColor($oProgressBar, $cWhite)
GUICtrlSetColor($oProgressBar, $cBlack)

Local Const $oGroup1 = GUICtrlCreateGroup($lActions, $pPadding1, 25, $pWidth1, 120)
GUICtrlSetColor($oGroup1, $cWhite)

Local Const $oGroup2 = GUICtrlCreateGroup($lRemoveQuarantine, $pPadding1, ($pPadding1 + ($pStep * 4)), $pWidth1, 58)
GUICtrlSetColor($oGroup2, $cWhite)

Local Const $oRemoveTools = GUICtrlCreateCheckbox($lDeleteTools, $pLeft, $pPadding1 + $pStep, 129, $pCtrSize)
GUICtrlSetState($oRemoveTools, 1)
GUICtrlSetColor($oRemoveTools, $cWhite)

Local Const $oRemoveRP = GUICtrlCreateCheckbox($lDeleteSystemRestorePoints, $pLeft, ($pPadding1 + ($pStep * 2)), 190, $pCtrSize)
GUICtrlSetColor($oRemoveRP, $cWhite)

Local Const $oCreateRP = GUICtrlCreateCheckbox($lCreateRestorePoint, $pLeft, ($pPadding1 + ($pStep * 3)), 190, $pCtrSize)
GUICtrlSetColor($oCreateRP, $cWhite)

Local Const $oBackupRegistry = GUICtrlCreateCheckbox($lSaveRegistry, $pRight, $pPadding1 + $pStep, 137, $pCtrSize)
GUICtrlSetColor($oBackupRegistry, $cWhite)

Local Const $oRestoreUAC = GUICtrlCreateCheckbox($lRestoreUAC, $pRight, ($pPadding1 + ($pStep * 2)), 137, $pCtrSize)
GUICtrlSetColor($oRestoreUAC, $cWhite)

Local Const $oRestoreSystemSettings = GUICtrlCreateCheckbox($lRestoreSettings, $pRight, ($pPadding1 + ($pStep * 3)), 180, $pCtrSize)
GUICtrlSetColor($oRestoreSystemSettings, $cWhite)

Local Const $oDeleteQuarantine = GUICtrlCreateCheckbox($lRemoveNow, $pLeft, 176, 137, $pCtrSize)
GUICtrlSetColor($oDeleteQuarantine, $cWhite)

Local Const $oDeleteQuarantineAfter7Days = GUICtrlCreateCheckbox($lRemoveQuarantineAfterNDays, $pRight, 176, 137, $pCtrSize)
GUICtrlSetColor($oDeleteQuarantineAfter7Days, $cWhite)
XPStyle(0)

Local Const $oRunKp = GUICtrlCreateButton($lRun, 415, 159, 75, 52)
GUICtrlSetBkColor($oRunKp, $cGreen)
GUICtrlSetColor($oRunKp, $cBlack)

Local Const $oTab2 = GUICtrlCreateTabItem("tab2")
Local Const $oUnSelectAllSearchLines = GUICtrlCreateButton($lNoElement, 415, $pButtonDetectionPT, 75, $pButtonDetectionHeight)
GUICtrlSetColor($oUnSelectAllSearchLines, $cWhite)

Local Const $oSelectAllSearchLines = GUICtrlCreateButton($lAll, 415, ($pButtonDetectionPT + $pButtonDetectionHeight + $pPadding1), 75, $pButtonDetectionHeight)
GUICtrlSetColor($oSelectAllSearchLines, $cWhite)

Local Const $oClearSearchLines = GUICtrlCreateButton($lEmpty, 415, ($pButtonDetectionPT + ($pButtonDetectionHeight * 2) + ($pPadding1 * 2)), 75, $pButtonDetectionHeight)
GUICtrlSetColor($oClearSearchLines, $cWhite)

Local Const $oSearchLines = GUICtrlCreateButton($lSearch, 415, ($pButtonDetectionPT + ($pButtonDetectionHeight * 3) + ($pPadding1 * 3)), 75, $pButtonDetectionHeight)
GUICtrlSetColor($oSearchLines, $cWhite)
GUICtrlSetBkColor($oSearchLines, $cBlue)

Local Const $oRemoveSearchLines = GUICtrlCreateButton($lRemove, 415, ($pButtonDetectionPT + ($pButtonDetectionHeight * 3) + ($pPadding1 * 3)), 75, $pButtonDetectionHeight)
GUICtrlSetBkColor($oRemoveSearchLines, $cRed)
GUICtrlSetColor($oRemoveSearchLines, $cWhite)

Global $oListView = GUICtrlCreateListView("Line", $pPadding1, 30, $pWidth1, 180, $LVS_NOCOLUMNHEADER, BitOR($WS_EX_CLIENTEDGE, $LVS_EX_CHECKBOXES, $LVS_EX_FULLROWSELECT))
GUICtrlSetBkColor($oListView, $cBlack)
GUICtrlSetColor($oListView, $cWhite)
_GUICtrlListView_SetColumnWidth($oListView, 0, $pWidth1 - 5)
SetButtonSearchMode()
GUICtrlCreateTabItem("")

GUISetBkColor($cBlack)
GUISetState(@SW_SHOW)

While 1
	Sleep(10)

	Local $nMsg = GUIGetMsg()

	Switch $nMsg
	    Case $GUI_EVENT_PRIMARYDOWN
            _SendMessage($hGUI, $WM_SYSCOMMAND, $SC_DRAGMOVE, 0)
		Case $GUI_EVENT_CLOSE
			Exit
		Case $oCloseButton
			Exit
		Case $oTabSwitcher1
			If GUICtrlRead($oTabs, 1) = $oTab1 Then
				ContinueLoop
			EndIf
			GUICtrlSetState($oTab1, $GUI_SHOW)
			GUICtrlSetBkColor($oTabSwitcher1, $cGreen)
			GUICtrlSetColor($oTabSwitcher1, $cBlack)
			GUICtrlSetBkColor($oTabSwitcher2, $cDisabled)
			GUICtrlSetColor($oTabSwitcher2, $cBlue)
		Case $oTabSwitcher2
			If GUICtrlRead($oTabs, 1) = $oTab2 Then
				ContinueLoop
			EndIf
			GUICtrlSetState($oTab2, $GUI_SHOW)
			GUICtrlSetBkColor($oTabSwitcher1, $cDisabled)
			GUICtrlSetColor($oTabSwitcher1, $cBlue)
			GUICtrlSetBkColor($oTabSwitcher2, $cGreen)
			GUICtrlSetColor($oTabSwitcher2, $cBlack)
		Case $oDeleteQuarantine
			GUICtrlSetState($oDeleteQuarantineAfter7Days, $GUI_UNCHECKED)
			If GUICtrlRead($oDeleteQuarantine) = $GUI_CHECKED Then
				GUICtrlSetState($oRemoveTools, $GUI_CHECKED)
			EndIf
		Case $oDeleteQuarantineAfter7Days
			GUICtrlSetState($oDeleteQuarantine, $GUI_UNCHECKED)
			If GUICtrlRead($oDeleteQuarantineAfter7Days) = $GUI_CHECKED Then
				GUICtrlSetState($oRemoveTools, $GUI_CHECKED)
			EndIf
		Case $oRemoveTools
			If GUICtrlRead($oDeleteQuarantine) = $GUI_CHECKED Or GUICtrlRead($oDeleteQuarantineAfter7Days) = $GUI_CHECKED Then
				GUICtrlSetState($oRemoveTools, $GUI_CHECKED)
			EndIf
		Case $oSearchLines
			InitGlobalVars()
			UpdateStatusBar("Search ...")
			KpSearch()
		Case $oRunKp
			InitGlobalVars()
			UpdateStatusBar("Running ...")
			KpRemover()
		Case $oSelectAllSearchLines
			_GUICtrlListView_SetItemChecked($oListView, -1, True)
		Case $oUnSelectAllSearchLines
			_GUICtrlListView_SetItemChecked($oListView, -1, False)
		Case $oClearSearchLines
			_GUICtrlListView_DeleteAllItems($oListView)
			SetButtonSearchMode()
			InitGlobalVars()
		Case $oRemoveSearchLines
			Local $aRemoveSelection[1][2] = [[]]

			For $i = 1 To UBound($aElementsFound) - 1
				If _GUICtrlListView_GetItemChecked($oListView, $i - 1) Then
					_ArrayAdd($aRemoveSelection, $aElementsFound[$i][0] & '~~~~' & $aElementsFound[$i][1], 0, '~~~~')
				EndIf
			Next

			If UBound($aRemoveSelection) = 1 Then
				MsgBox($MB_ICONWARNING, "Warning", $lNoSelected)
			Else
				Local $hGlobalTimer = TimerInit()
				InitGlobalVars()
				Init()
				ProgressBarUpdate()
				LogMessage(@CRLF & "- Checked options -" & @CRLF)
				LogMessage("    ~ Custom deletions")
				RemoveAllSelectedLineSearch($aRemoveSelection)
				UpdateStatusBar("Finish")
				RestartIfNeeded()
				_GUICtrlListView_DeleteAllItems($oListView)
				SetButtonSearchMode()
				MsgBox(64, "OK", $lFinish)
				OpenReport()
			EndIf
	EndSwitch
WEnd

Func CreateKPRMDir()
	Local Const $sDir = @HomeDrive & "\KPRM"

	If Not FileExists($sDir) Then
		DirCreate($sDir)
	EndIf

	If Not FileExists($sDir) Then
		MsgBox(16, $lFail, $lRegistryBackupError)
		Exit
	EndIf
EndFunc   ;==>CreateKPRMDir

Func CountKpRmPass()
	Local Const $sDir = @HomeDrive & "\KPRM"

	Local $aFileList = _FileListToArray($sDir, "kprm-*.txt", $FLTA_FILES)

	If @error <> 0 Then Return 1

	Return $aFileList[0]
EndFunc   ;==>CountKpRmPass

Func Init()
	CreateKPRMDir()
	LogMessage("# Run at " & _Now())
	LogMessage("# KpRm (Kernel-panik) version " & $sKprmVersion)
	LogMessage("# Website https://kernel-panik.me/tool/kprm/")
	LogMessage("# Run by " & @UserName & " from " & @WorkingDir)
	LogMessage("# Computer Name: " & @ComputerName)
	LogMessage("# OS: " & GetHumanVersion() & " " & @OSArch & " (" & @OSBuild & ") " & @OSServicePack)
	LogMessage("# Number of passes: " & CountKpRmPass())

	ProgressBarInit()
EndFunc   ;==>Init

Func UpdateStatusBar($sText)
	GUICtrlSetData($oHStatus, $sText)
EndFunc   ;==>UpdateStatusBar

Func SetButtonSearchMode()
	GUICtrlSetState($oRemoveSearchLines, $GUI_HIDE)
	GUICtrlSetState($oSearchLines, $GUI_SHOW)
	GUICtrlSetBkColor($oUnSelectAllSearchLines, $cDisabled)
	GUICtrlSetBkColor($oSelectAllSearchLines, $cDisabled)
	GUICtrlSetBkColor($oClearSearchLines, $cDisabled)
	GUICtrlSetState($oUnSelectAllSearchLines, $GUI_DISABLE)
	GUICtrlSetState($oSelectAllSearchLines, $GUI_DISABLE)
	GUICtrlSetState($oClearSearchLines, $GUI_DISABLE)
EndFunc   ;==>SetButtonSearchMode

Func SetButtonDeleteSearchMode()
	GUICtrlSetState($oRemoveSearchLines, $GUI_SHOW)
	GUICtrlSetState($oSearchLines, $GUI_HIDE)
	GUICtrlSetBkColor($oUnSelectAllSearchLines, $cBlue)
	GUICtrlSetBkColor($oSelectAllSearchLines, $cBlue)
	GUICtrlSetBkColor($oClearSearchLines, $cBlue)
	GUICtrlSetState($oUnSelectAllSearchLines, $GUI_ENABLE)
	GUICtrlSetState($oSelectAllSearchLines, $GUI_ENABLE)
	GUICtrlSetState($oClearSearchLines, $GUI_ENABLE)
EndFunc   ;==>SetButtonDeleteSearchMode

Func InitGlobalVars()
	Dim $sCurrentTime = @YEAR & @MON & @MDAY & @HOUR & @MIN & @SEC
	Dim $sCurrentHumanTime = @YEAR & '-' & @MON & '-' & @MDAY & '-' & @HOUR & '-' & @MIN & '-' & @SEC
	Dim $sKPLogFile = "kprm-" & $sCurrentTime & ".txt"
	Dim $bRemoveToolLastPass = False
	Dim $bPowerShellAvailable = Null
	Dim $bDeleteQuarantines = Null
	Dim $bSearchOnly = False
	Dim $bSearchOnlyHasFoundElement = False
	Dim $aRemoveRestart = []
	Dim $bNeedRestart = False
	Dim $aElementsToKeep[1][2] = [[]]
	Dim $aElementsFound[1][2] = [[]]

	InitOToolCpt()
	UpdateStatusBar("Ready ...")
	ProgressBarInit()
EndFunc   ;==>InitGlobalVars

Func KpSearch()
	SetButtonSearchMode()

	Dim $bSearchOnly = True
	Dim $bSearchOnlyHasFoundElement = False

	RunRemoveTools()

	If $bSearchOnlyHasFoundElement = True Then
		SetButtonDeleteSearchMode()
	Else
		MsgBox($MB_ICONINFORMATION, $lFinishTitle, $lNoTool)
		SetButtonSearchMode()
	EndIf

EndFunc   ;==>KpSearch

Func KpRemover()
	Local $hGlobalTimer = TimerInit()

	Init()
	ProgressBarUpdate()
	LogMessage(@CRLF & "- Checked options -" & @CRLF)

	If GUICtrlRead($oBackupRegistry) = $GUI_CHECKED Then LogMessage("    ~ Registry Backup")
	If GUICtrlRead($oRemoveTools) = $GUI_CHECKED Then LogMessage("    ~ Delete Tools")
	If GUICtrlRead($oRestoreSystemSettings) = $GUI_CHECKED Then LogMessage("    ~ Restore System Settings")
	If GUICtrlRead($oRestoreUAC) = $GUI_CHECKED Then LogMessage("    ~ UAC Restore")
	If GUICtrlRead($oRemoveRP) = $GUI_CHECKED Then LogMessage("    ~ Delete Restore Points")
	If GUICtrlRead($oCreateRP) = $GUI_CHECKED Then LogMessage("    ~ Create Restore Point")
	If GUICtrlRead($oDeleteQuarantine) = $GUI_CHECKED Then LogMessage("    ~ Delete Quarantines")
	If GUICtrlRead($oDeleteQuarantineAfter7Days) = $GUI_CHECKED Then LogMessage("    ~ Delete Quarantines after 7 days")

	$bDeleteQuarantines = Null

	If GUICtrlRead($oDeleteQuarantine) = $GUI_CHECKED Then
		$bDeleteQuarantines = 1
	ElseIf GUICtrlRead($oDeleteQuarantineAfter7Days) = $GUI_CHECKED Then
		$bDeleteQuarantines = 7
	EndIf

	If GUICtrlRead($oBackupRegistry) = $GUI_CHECKED Then
		CreateBackupRegistry()
	EndIf

	ProgressBarUpdate()

	If GUICtrlRead($oRemoveTools) = $GUI_CHECKED Then
		RunRemoveTools()
		$bRemoveToolLastPass = True
		RunRemoveTools()
	Else
		ProgressBarUpdate(32)
	EndIf

	ProgressBarUpdate()

	If GUICtrlRead($oRestoreSystemSettings) = $GUI_CHECKED Then
		RestoreSystemSettingsByDefault()
	EndIf

	ProgressBarUpdate()

	If GUICtrlRead($oRestoreUAC) = $GUI_CHECKED Then
		RestoreUAC()
	EndIf

	ProgressBarUpdate()

	If GUICtrlRead($oRemoveRP) = $GUI_CHECKED Then
		ClearRestorePoint()
	EndIf

	ProgressBarUpdate()

	If GUICtrlRead($oCreateRP) = $GUI_CHECKED Then
		CreateRestorePoint()
	EndIf

	TimerWriteReport($hGlobalTimer, "KPRM")

	GUICtrlSetData($oProgressBar, 100)

	SetDeleteQuarantinesIn7DaysIfNeeded()
	RestartIfNeeded()
	UpdateStatusBar("Finish")
	MsgBox(64, "OK", $lFinish)

	QuitKprm(True)
EndFunc   ;==>KpRemover
