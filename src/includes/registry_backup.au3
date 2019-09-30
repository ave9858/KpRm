
Func DosPathNameToPathName($sPath)
	Local $sName, $aDrive = DriveGetDrive('ALL')

	If Not IsArray($aDrive) Then
		Return SetError(1, 0, $sPath)
		Return SetError(1, 0, $sPath)
	EndIf

	For $i = 1 To $aDrive[0]
		$sName = _WinAPI_QueryDosDevice($aDrive[$i])

		If StringInStr($sPath, $sName) = 1 Then
			Return StringReplace($sPath, $sName, StringUpper($aDrive[$i]), 1)
		EndIf
	Next

	Return SetError(2, 0, $sPath)
EndFunc   ;==>DosPathNameToPathName

Func _wmic_CreateShadowCopy($DriveLetter_Func, ByRef $ShadowID_Func)
	Local Const $CommandLine = "wmic shadowcopy call create Volume='" & $DriveLetter_Func & "\'"
	Local Const $iPID = Run(@ComSpec & " /c " & $CommandLine, @ScriptDir, @SW_HIDE, $STDOUT_CHILD)

	ProcessWaitClose($iPID)

	Local $sOutput = StdoutRead($iPID)

	Local $Pos1_Retval = StringInStr($sOutput, "ReturnValue = ")
	$Pos1_Retval = $Pos1_Retval + StringLen("ReturnValue = ")

	Local $Pos2_Retval = StringInStr($sOutput, ";", 1, 1, $Pos1_Retval)
	Local $Val_ReturnValue = StringMid($sOutput, $Pos1_Retval, $Pos2_Retval - $Pos1_Retval)

	$Val_ReturnValue = Number($Val_ReturnValue)

	If $Val_ReturnValue = 0 Then
		Local $Pos1_ShadowID = StringInStr($sOutput, "ShadowID = ")
		$Pos1_ShadowID = $Pos1_ShadowID + StringLen("ShadowID = ") + 1

		Local $Pos2_ShadowID = StringInStr($sOutput, ";", 1, 1, $Pos1_ShadowID) - 1
		Local $Val_ShadowID = StringMid($sOutput, $Pos1_ShadowID, $Pos2_ShadowID - $Pos1_ShadowID)

		If $Val_ShadowID <> "" Then
			$ShadowID_Func = $Val_ShadowID
		EndIf
	EndIf

	Return $Val_ReturnValue
EndFunc   ;==>_wmic_CreateShadowCopy

Func _wmic_Globalroot_to_ShadowID($ShadowID_Func)
	Local Const $CommandLine = "wmic shadowcopy"
	Local Const $iPID = Run(@ComSpec & " /c " & $CommandLine, @ScriptDir, @SW_HIDE, $STDOUT_CHILD)

	ProcessWaitClose($iPID)

	Local $sOutput = StdoutRead($iPID)

	Local Const $Pos_ShadowID = StringInStr($sOutput, $ShadowID_Func)

	If $Pos_ShadowID = 0 Then
		Return ""
	EndIf

	Local Const $Pos_GlobalRoo1 = StringInStr($sOutput, "\\?\GLOBALROOT\Device\", 1, -1, $Pos_ShadowID)

	If $Pos_GlobalRoo1 = 0 Then
		Return ""
	EndIf

	Local Const $Pos_GlobalRoot2 = StringInStr($sOutput, " ", 1, 1, $Pos_GlobalRoo1, 60)

	If $Pos_GlobalRoot2 = 0 Then
		Return ""
	EndIf

	Return StringMid($sOutput, $Pos_GlobalRoo1, $Pos_GlobalRoot2 - $Pos_GlobalRoo1)
EndFunc   ;==>_wmic_Globalroot_to_ShadowID

Func _Return_First_Free_Drive_Letter()
	Local Const $array_lettere = _GetFreeDriveLetters()

	If (UBound($array_lettere) - 1) >= 1 Then
		Return $array_lettere[1]
	Else
		Return -1
	EndIf
EndFunc   ;==>_Return_First_Free_Drive_Letter

Func _GetFreeDriveLetters()
	Local $aArray[1]

	For $x = 67 To 90
		If DriveStatus(Chr($x) & ':\') = 'INVALID' Then
			ReDim $aArray[UBound($aArray) + 1]
			$aArray[UBound($aArray) - 1] = Chr($x) & ':'
		EndIf
	Next

	$aArray[0] = UBound($aArray) - 1

	Return ($aArray)
EndFunc   ;==>_GetFreeDriveLetters

Func _RemoveVSSLetter($Drive_Letter_VSS)
	Local Const $Path_DOSDEV = _TempFile(@TempDir, "kprm-dosdev", ".exe")

	_DosDev_Exe($Path_DOSDEV)

	RunWait(@ComSpec & " /c " & '"' & $Path_DOSDEV & '"' & " -d " & $Drive_Letter_VSS, "", @SW_HIDE)

	FileDelete($Path_DOSDEV)
EndFunc   ;==>_RemoveVSSLetter

Func _AssignVSSLetter($Drive_Letter_VSS, $PathUNC_ShadowCopy)
	Local Const $Path_DOSDEV = _TempFile(@TempDir, "kprm-dosdev", ".exe")

	_DosDev_Exe($Path_DOSDEV)

	RunWait(@ComSpec & " /c " & '"' & $Path_DOSDEV & '"' & " " & $Drive_Letter_VSS & " " & $PathUNC_ShadowCopy, "", @SW_HIDE)

	FileDelete($Path_DOSDEV)

	If DriveStatus($Drive_Letter_VSS & "\") = "READY" Then
		Return 0
	EndIf

	Return -1
EndFunc   ;==>_AssignVSSLetter

Func _DosDev_Exe($Path_FileName)
	Local $sData = '0x'
	$sData &= '4D5A90000300000004000000FFFF0000B800000000000000400000000000000000000000000000000000000000000000000000000000000000000000E00000000E1FBA0E00B409CD21B8014CCD21546869732070726F6772616D2063616E6E6F742062652072756E20696E20444F53206D6F64652E0D0D0A240000000000000056C8818312A9EFD012A9EFD012A9EFD091A1E0D013A9EFD091A1B2D015A9EFD012A9EED03EA9EFD09CA1B0D002A9EFD091A1B1D013A9EFD091A1B5D013A9EFD05269636812A9EFD0000000000000000000000000000000000000000000000000504500004C010300FCA6513E0000000000000000E0000F010B01070A001000000026030000000000FF190000001000000020000000000001001000000002000005000200050002000400000000000000006003000004000076AD0000030000800000040000200000000010000010000000000000100000000000000000000000001C00005000000000500300E8030000000000000000000000000000000000000000000000000000C01000001C0000000000000000000000000000000000000000000000000000004013000040000000000000000000000000100000B40000000000000000000000000000000000000000000000000000002E74657874000000BC0F0000001000000010000000040000000000000000000000000000200000602E6461746100000098200300002000000002000000140000000000000000000000000000400000C02E72737263000000E8030000005003000004000000160000000000000000000000000000400000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008A1F00009E1F00007C1F0000000000004C1D00005E1D0000701D0000841D00009E1D00003C1D0000C41D0000DA1D0000F41D0000081E00001C1E00002C1D0000181D0000AE1D0000041D0000000000006C1E0000781E0000801E0000621E0000941E00009E1E0000A81E0000B21E0000BA1E0000C81E0000D21E0000DE1E0000EE1E0000FA1E00000E1F00001E1F00002E1F00003C1F00004E1F00006E1F00005A1E0000501E0000481E00008A1E00000000000000000000000000000000000000000000FCA6513E00000000020000001B000000881300008807000052616D4469736B004344526F6D00000052656D6F74650000466978656400000052656D6F7661626C650000004E6F526F6F74446972000000556E6B6E6F776E000000000075736167653A20444F53444556205B2D615D205B2D735D205B2D685D205B5B2D725D205B2D64205B2D655D5D204465766963654E616D65205B546172676574506174685D5D0A000025730000203B200025732573203D2000526567517565727956616C75654578206661696C656420776974682025640A0053797374656D506172746974696F6E005265674F70656E4B65794578206661696C656420776974682025640A0000000053595354454D5C53657475700000000025732064656C657465642E0A00000000444F534445563A20556E61626C6520746F20257320646576696365206E616D65202573202D2025750A000000646566696E65000064656C657465000043757272656E7420646566696E6974696F6E3A200000000025633A203D202A2A2A204C4F474943414C204452495645204249542053455420425554204E4F204452495645204C4554544552202A2A2A0A00000000202A2A2A204C4F474943414C20445249564520424954204E4F5420534554202A2A2A0000205B25735D0000000A00000025735C002A2A2A20756E61626C6520746F207175657279207461726765742070617468202D202575202A2A2A00000000444F534445563A20556E61626C6520746F20717565727920646576696365206E616D6573202D2025750A0000556E68616E646C6564457863657074696F6E46696C746572000000006B65726E656C33322E646C6C00000000FFFFFFFF4B1B00015F1B00010000000048000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030200001B0130001010000004E42313000000000FCA6513E01000000646F736465762E7064620000000000000000000000000000F41B0000A1A010000183C040682011000150FF15A410000159596A01FF15A8100001CC558BEC535657FF750C8B3D5C100001FF75086870110001FFD78B751083C40C33DBEB2E395D'
	$sData &= '14742D3B75107608686C110001FFD759566868110001FFD75959EB0B8B451446FF4D1485C07410381E75F146381E75CE5F5E5B5DC21000895D14EBF0558BEC51518D45FC506A016A0068C81100016802000080FF150410000185C074125068A8110001FF155C100001595933C0EB46578D45F850FF7508C745F8040100006A006A006898110001FF75FCFF1500100001FF75FC8BF8FF150810000185FF7412576878110001FF155C100001595933C0EB0333C0405FC9C204008B442408FF308B442408FF30FF15501000015959C381EC1C010000A130200001535533ED33DB43FF8C2428010000568984242401000057896C2418896C2410895C241C896C24140F84C70000008BBC243401000083C7048B378A063C2D746F3C2F746B837C241800750689742418EB65837C2410000F85DD02000089742410EB540FBEC050FF156410000183E83F590F84C302000083E822742F83E803742348741983E8030F84AD02000083E80A740548751B8BEB095C2414EB13834C241404EB0C834C241402EB058364241C00468A0684C075ACFF8C24300100000F8572FFFFFF33F63BEE74188D4424245089442414E88DFEFFFF85C0750653E93F020000397424180F853B020000397424100F85440200006800500000BD80F00201556A00FF151010000185C07520FF152410000150A1A010000183C04068D812000150FF15A410000183C40CEBAF803D80F00201000F84E0000000BF6060010168005000005755FF15101000018BD885DB751BFF15241000015068AC12000157FF156010000183C40CE99C0000008BC58D50018A084084C975F92BC283F8027556807D013A7550A1804003018D34804055A3804003018D44242468A8120001508D34B560200001FF156010000183C40C8D44242050FF153C1000018B04851420000133C98A4D0089460C33C04083E941D3E0894610EB15A160F002018D3480408D34B560B00101A360F002018D430150892E895E04FF15AC100001535750894608FF155810000183C4108A45004584C075F83845000F8525FFFFFF68B11400016A14FF35804003016860200001FF155410000183C410FF15401000018364241000833D80400301008B3D5C1000018BD8BDA4120001764DBE68200001FF76FCFF36FF76F868A2120001E897FCFFFFFF7604689C120001FFD78B460885C35959740433D8EB086878120001FFD75955FFD7FF4424148B44241483C6143B05804003015972B885DB742033F633C0408BCED3E085C3740D8D464150683C120001FFD759594683FE1A72E2837C241C00755155FFD7C70424B11400016A14FF3560F002016860B00101FF155410000133DB83C410391D60F002017627BE68B00101FF76FCFF36FF76F868A2120001E8F5FBFFFF55FFD74383C6143B1D60F002015972DE6A00FF15A81000018B44241483E0028944241C750B397424107505E9A6FBFFFF8B3510100001BB0050000053BF6060010157FF742420FFD685C0BDA412000174185057FF7424206824120001E894FBFFFF55FF155C10000159FF742410FF74241CFF74241CFF154810000185C075353944241CBE1C1200017505BE14120001FF152410000150FF74241CA1A01000015683C04068E811000150FF15A410000183C414EB31538B5C241C5753FFD685C074165057536824120001E827FBFFFF55FF155C100001EB0D5368D8110001FF155C10000159598B8C24280100005F5E5D33C05B81C41C010000E986000000558BEC83EC10A13020000185C074073D4EE640BB756E568D45F850FF152C1000018B75FC3375F8FF152810000133F0FF154410000133F0FF152010000133F08D45F050FF151C1000018B45F43345F033F0893530200001750AC705302000014EE640BB6820130001FF151810000185C05E7411680413000150FF1514100001A388400301C9C33B0D302000017501C3E900000000558DAC2458FDFFFF81EC28030000A1302000018985A4020000A18440030185C07402FFD0833D8840030100743E5733C02145D86A13598D7D84F3ABB9B20000008D7DDCF3AB8D45808945D08D45D86A00C74580090400C08945D4FF15381000018D45D050FF15884003015F6802050000FF153410000150FF15301000018B8DA4020000E86AFFFFFF81C5A8020000C9C36A286830130001E89D01000066813D000000014D5A7528A13C00000181B8000000015045000075170FB7881800000181F90B010000742181F90B02000074068365E400EB2A83B8840000010E76F133C93988F8000001EB1183B8740000010E76DE33C93988E80000010F95C1894DE48365FC006A01FF159410000159830D8C400301FF830D90400301FFFF15901000018B0D4C2000018908FF158C1000018B0D482000018908A1881000018B00A394400301E8EC000000833D3420000100750C68A21B0001FF158410000159E8C00000006810200001680C200001E8AB000000A1442000018945DC8D45DC50FF35402000018D45E0508D45D8508D45D450FF157C1000018945CC68082000016800200001E8750000008B45E08B0D781000018901FF75E0FF75D8FF75D4E898F9FFFF83C4308BF08975C8837DE400750756FF15A8100001FF1574100001EB2D8B45EC8B088B09894DD05051E8280000005959C38B65E88B75D0837DE400750756FF156C100001FF1568100001834DFCFF8BC6E860000000C3FF2570100001FF258010000168000003006800000100E85B0000005959C333C0C3CCCCCC68F41B000164A100000000508B442410896C24108D6C24102BE05356578B45F88965E8508B45FCC745FCFFFFFFFF8945F88D45F064A300000000C38B4DF064890D00000000595F5E'
	$sData &= '5BC951C3FF2598100001FF259C100001601C000000000000000000003A1E000010100000A01C00000000000000000000621F000050100000501C00000000000000000000AE1F00000010000000000000000000000000000000000000000000008A1F00009E1F00007C1F0000000000004C1D00005E1D0000701D0000841D00009E1D00003C1D0000C41D0000DA1D0000F41D0000081E00001C1E00002C1D0000181D0000AE1D0000041D0000000000006C1E0000781E0000801E0000621E0000941E00009E1E0000A81E0000B21E0000BA1E0000C81E0000D21E0000DE1E0000EE1E0000FA1E00000E1F00001E1F00002E1F00003C1F00004E1F00006E1F00005A1E0000501E0000481E00008A1E0000000000007600446566696E65446F7344657669636541000070014765744C6F676963616C44726976657300004B01476574447269766554797065410069014765744C6173744572726F72000095025175657279446F734465766963654100980147657450726F6341646472657373000077014765744D6F64756C6548616E646C6541000099025175657279506572666F726D616E6365436F756E74657200D5014765745469636B436F756E7400003E0147657443757272656E74546872656164496400003B0147657443757272656E7450726F63657373496400C00147657453797374656D54696D65417346696C6554696D650051035465726D696E61746550726F6365737300003A0147657443757272656E7450726F63657373003D03536574556E68616E646C6564457863657074696F6E46696C746572004B45524E454C33322E646C6C00009A02657869740000A902667072696E74660044015F696F620000EF027072696E7466000001025F73747269636D700000F50271736F727400E9026D656D6D6F766500E2026D616C6C6F6300000303737072696E7466002403746F6C6F77657200CA005F635F6578697400FB005F65786974004E005F5863707446696C74657200CD005F6365786974000071005F5F696E6974656E760070005F5F6765746D61696E617267730040015F696E69747465726D009E005F5F736574757365726D6174686572720000BB005F61646A7573745F66646976000083005F5F705F5F636F6D6D6F6465000088005F5F705F5F666D6F646500009C005F5F7365745F6170705F747970650000F2005F6578636570745F68616E646C65723300006D73766372742E646C6C0000DB005F636F6E74726F6C66700000C901526567436C6F73654B657900EC01526567517565727956616C75654578410000E2015265674F70656E4B65794578410041445641504933322E646C6C0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000DB1800010000000000000000000000001411000108110001FC100001F4100001EC100001E4100001DC1000014EE640BB01000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001001000000018000080000000000000000000000000000001000100000030000080000000000000000000000000000001000904000048000000605003008403000000000000000000000000000000000000840334000000560053005F00560045005200530049004F004E005F0049004E0046004F0000000000BD04EFFE00000100020005000000BC0E020005000000BC0E3F000000000000000400040001000000000000000000000000000000E2020000010053007400720069006E006700460069006C00650049006E0066006F000000BE02000001003000340030003900300034004200300000004C001600010043006F006D00700061006E0079004E0061006D006500000000004D006900630072006F0073006F0066007400200043006F00720070006F0072006100740069006F006E0000005A0019000100460069006C0065004400650073006300720069007000740069006F006E000000000044006900730070006C0061007900200044004F005300200044006500760069006300650020004E0061006D0065007300000000005E001F000100460069006C006500560065007200730069006F006E000000000035002E0032002E0033003700370032002E0030002000280064006E007300720076002E0030003300'
	$sData &= '30003200310037002D00310036003400380029000000000036000B00010049006E007400650072006E0061006C004E0061006D006500000044004F0053004400450056002E004500580045000000000080002E0001004C006500670061006C0043006F0070007900720069006700680074000000A90020004D006900630072006F0073006F0066007400200043006F00720070006F0072006100740069006F006E002E00200041006C006C0020007200690067006800740073002000720065007300650072007600650064002E0000003E000B0001004F0072006900670069006E0061006C00460069006C0065006E0061006D006500000044004F0053004400450056002E00450058004500000000006A0025000100500072006F0064007500630074004E0061006D006500000000004D006900630072006F0073006F0066007400AE002000570069006E0064006F0077007300AE0020004F007000650072006100740069006E0067002000530079007300740065006D00000000003A000B000100500072006F006400750063007400560065007200730069006F006E00000035002E0032002E0033003700370032002E00300000000000440000000100560061007200460069006C00650049006E0066006F00000000002400040000005400720061006E0073006C006100740069006F006E00000000000904B00400000000000000000000000000000000000000000000000000000000'

	$sData = Binary($sData)
	Local $file = FileOpen($Path_FileName, 18)
	FileWrite($file, $sData)
	FileClose($file)
EndFunc   ;==>_DosDev_Exe

Func _CreateVSS_ShadowCopy_Drive($SourceDrive_Func, ByRef $Drive_Letter_VSS_Func, ByRef $ShadowID_Func)
	$Drive_Letter_VSS_Func = ""
	$ShadowID_Func = ""

	If _wmic_CreateShadowCopy($SourceDrive_Func, $ShadowID_Func) <> 0 Then
		Return -1 ; Error create shadow copy
	EndIf

	Local $VolumeGlobalRoot = _wmic_Globalroot_to_ShadowID($ShadowID_Func)

	If $VolumeGlobalRoot = "" Then
		Return -2 ; cannot find GLOBALROOT
	EndIf

	Local $ShadowCopyDrive = _Return_First_Free_Drive_Letter()

	If _AssignVSSLetter($ShadowCopyDrive, $VolumeGlobalRoot) = -1 Then
		Return -3 ; drive not ready
	EndIf

	$Drive_Letter_VSS_Func = $ShadowCopyDrive

	Return 0
EndFunc   ;==>_CreateVSS_ShadowCopy_Drive

Func _DeleteShadowCopy($ShadowID_Func)
	Local Const $CommandLine = "vssadmin Delete Shadows /Shadow=" & $ShadowID_Func & " /Quiet"

	Return RunWait(@ComSpec & " /c " & $CommandLine, @ScriptDir, @SW_HIDE)
EndFunc   ;==>_DeleteShadowCopy

Func FileCopyVSS(ByRef Const $oHives)
	Local $ShadowCopyDrive = ""
	Local $ShadowID = ""

	For $sSourceDrive In $oHives
		If DriveStatus($sSourceDrive & "\") <> "READY" Then
			Return -7 ;Source Drive not ready
		EndIf

		Local $Retval_CreateVSS = _CreateVSS_ShadowCopy_Drive($sSourceDrive, $ShadowCopyDrive, $ShadowID) ; -1/-2/-3

		If $Retval_CreateVSS < 0 Then
			Return $Retval_CreateVSS
		EndIf

		If $ShadowCopyDrive = "" Then
			Return -4 ; Cannot create shadow copy
		EndIf

		Local $oDriveHives = $oHives.Item($sSourceDrive)

		For $sHiveItem In $oDriveHives
			Local $sBackupPath = $oDriveHives.Item($sHiveItem)

			Local $Path_Source_Strip = StringMid($sHiveItem, 3)

			UpdateStatusBar("Backup hive  " & $sSourceDrive & $Path_Source_Strip)

			Local $Retval_Copy = FileCopy($ShadowCopyDrive & $Path_Source_Strip, $sBackupPath)

			If $Retval_Copy = 0 Then
				Return -5 ; Autoit Copy Error
			EndIf

			Local $sDrive = "", $sDir = "", $sFileName = "", $sExtension = ""
			Local $aPathSplit = _PathSplit($sHiveItem, $sDrive, $sDir, $sFileName, $sExtension)
			Local $sBackupFile = $sBackupPath & '\' & $sFileName & $sExtension

			If Not FileExists($sBackupFile) Then
				Return -9
			Else
				Local $sAttrib = FileGetAttrib($sBackupFile)

				If StringInStr($sAttrib, "R") Then
					FileSetAttrib($sBackupFile, "-R")
				EndIf

				If StringInStr($sAttrib, "S") Then
					FileSetAttrib($sBackupFile, "-S")
				EndIf

				If StringInStr($sAttrib, "H") Then
					FileSetAttrib($sBackupFile, "-H")
				EndIf

				If StringInStr($sAttrib, "A") Then
					FileSetAttrib($sBackupFile, "-A")
				EndIf

				LogMessage("    ~ [OK] Hive " & $sHiveItem & " backed up")
			EndIf
		Next

		_RemoveVSSLetter($ShadowCopyDrive)

		Local $Retval_Canc_VSS = _DeleteShadowCopy($ShadowID)

		If $Retval_Canc_VSS <> 0 Then
			LogMessage("  [!] Error Delete Shadow Copy")
		EndIf
	Next

	Return 0
EndFunc   ;==>FileCopyVSS

Func CreateBackupRegistry()
	LogMessage(@CRLF & "- Create Registry Backup -" & @CRLF)

	Dim $lFail
	Dim $lRegistryBackupError
	Dim $sCurrentHumanTime
	Local Const $sBackupPath = @HomeDrive & "\KPRM\backup\" & $sCurrentHumanTime
	Local Const $sSuffixKey = GetSuffixKey()
	Local $sHiveList = "HKLM" & $sSuffixKey & "\System\CurrentControlSet\Control\hivelist"
	Local $i = 0

	If Not FileExists($sBackupPath) Then
		DirCreate($sBackupPath)
	EndIf

	Local $oHives = ObjCreate("Scripting.Dictionary")

	While True
		$i += 1
		Local $sEntry = RegEnumVal($sHiveList, $i)
		If @error <> 0 Or $i > 100 Then ExitLoop

		Local $sName = RegRead($sHiveList, $sEntry)

		If $sName Then
			Local $sPathName = DosPathNameToPathName($sName)

			If StringRegExp($sPathName, '(?i)^[A-Z]\:\\') Then
				Local $sDrive = "", $sDir = "", $sFileName = "", $sExtension = ""
				Local $aPathSplit = _PathSplit($sPathName, $sDrive, $sDir, $sFileName, $sExtension)

				$sDrive = StringUpper($sDrive)
				$sDir = StringRegExpReplace($sDir, "\\$", "")

				Local $sScriptBackUpPath = $sBackupPath & $sDir

				If $sDrive And $sPathName And $sScriptBackUpPath Then
					If Not FileExists($sScriptBackUpPath) Then
						DirCreate($sScriptBackUpPath)
					EndIf

					If $oHives.Exists($sDrive) Then
						Local $oDriveHives = $oHives.Item($sDrive)
						$oDriveHives.add($sPathName, $sScriptBackUpPath)
						$oHives.Item($sDrive) = $oDriveHives
					Else
						Local $oDriveHives = ObjCreate("Scripting.Dictionary")
						$oDriveHives.add($sPathName, $sScriptBackUpPath)
						$oHives.Item($sDrive) = $oDriveHives
					EndIf
				EndIf
			EndIf
		EndIf
	WEnd

	If @AutoItX64 = 0 Then _WinAPI_Wow64EnableWow64FsRedirection(False)

	Local Const $iBackupStatus = FileCopyVSS($oHives)

	If $iBackupStatus <> 0 Then
		MsgBox(16, $lFail, $lRegistryBackupError & @CRLF & "code: " & $iBackupStatus)
		LogMessage(@CRLF & "  [X] Failed Registry Backup (code: " & $iBackupStatus & ')')
		QuitKprm(False)
	EndIf

	LogMessage(@CRLF & "  [OK] Registry Backup: " & $sBackupPath)
EndFunc   ;==>CreateBackupRegistry


