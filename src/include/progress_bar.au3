
Local Const $nbrTask = 9
Global $currentNbrTask = 0
Global Const $taskStep = Floor(100 / $nbrTask)

Func ProgressBarUpdate()
	$currentNbrTask += 1
	Dim $ProgressBar
	GUICtrlSetData($ProgressBar, $currentNbrTask * $taskStep)

	If $currentNbrTask = $nbrTask Then
		GUICtrlSetData($ProgressBar, 100)
	EndIf
EndFunc   ;==>ProgressBarUpdate

Func ProgressBarInit()
	$currentNbrTask = 0
	Dim $ProgressBar
	GUICtrlSetData($ProgressBar, 0)
EndFunc   ;==>ProgressBarInit
