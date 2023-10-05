comment "
A3_InterroGationExeCutionModUle

Arma 3 Steam Workshop
https://steamcommunity.com/sharedfiles/filedetails/?id=3041863730

MIT License
Copyright (c) 2023 M9-SD
https://github.com/M9-SD/A3_InterroGationExeCutionModUle/blob/main/LICENSE
";

comment "Module Settings";

_M9_interrogationSetting_showHints = true;
_M9_interrogationSetting_showPIP = true;
_M9_interrogationSetting_surrenderUnit = true;
_M9_interrogationSetting_restrainUnit = false;
_M9_interrogationSetting_useIntelText = true;
_M9_interrogationSetting_intelText = "Hello world.";

private _object = this;
if ((!(_object isKindOf 'man')) && (!(_object iskindof 'camanbase'))) exitWith {systemChat 'ERROR | Object must be human.';};
private _prisoner = _object;
if (_prisoner getVariable ['interrogateActionAdded', false]) exitWIth {systemChat 'An interrogation action has already been added to this unit!';};

comment "Interrogation Scripts";

M9SD_fnc_moduleInterrogation_composition = {
	params [['_objOverride', objNull]];
	_testMode = !isNull _objOverride;
	if ((isNull findDisplay 312) && (!_testMode)) exitWith {systemChat 'ERROR | Zeus is not open!';};
	private _targetObjArray = curatorMouseOver;
	_object = if (not _testMode) then { 
		if ((_targetObjArray isEqualTo []) or (_targetObjArray isEqualTo [''])) then {objNull} else {_targetObjArray select 1};
	} else {_objOverride};
	if (isNull _object) exitWith {systemChat "ERROR | No object! (Place the zeus module on top of an object’s 3D icon)";[_zeusLogic, 'NO OBJECT SELECTED'] call BIS_fnc_showCuratorFeedbackMessage;};
	if ((!(_object isKindOf 'man')) && (!(_object iskindof 'camanbase'))) exitWith {systemChat 'ERROR | Object must be human.';};

	_objType = typeOf _object;
	_objName = if (isPlayer _object) then {name _object} else {getText (configFile >> 'cfgVehicles' >> _objType >> 'displayName');};
	if (_objName == '') then 
	{
		_objName = _objType;
	};
	_zeusLogic = getAssignedCuratorLogic player;
	if (!isNull _zeusLogic) then {
		_feeback = format ["Adding interrogation action to [ %1 ]...", _objName];
		[_zeusLogic, _feeback] call BIS_fnc_showCuratorFeedbackMessage;
	};
	test_icons_interrogate = 
	[
		"a3\ui_f\data\igui\cfg\simpletasks\types\talk_ca.paa",
		"a3\ui_f\data\igui\cfg\simpletasks\types\unknown_ca.paa",
		"a3\ui_f\data\igui\cfg\simpletasks\types\danger_ca.paa",
		"a3\ui_f\data\map\diary\icons\taskcustom_ca.paa"
	];
	M9_interrogationAnimations = [
		'Acts_Executioner_Backhand',
		'Acts_Executioner_Forehand',
		'Acts_Executioner_Kill',
		'Acts_Executioner_Kill_End',
		'Acts_Executioner_Squat',
		'Acts_Executioner_Squat_End',
		'Acts_Executioner_Standing',
		'Acts_Executioner_StandingLoop',
		'Acts_Executioner_ToPistol',
		'Acts_ExecutionVictim_Backhand',
		'Acts_ExecutionVictim_Forehand',
		'Acts_ExecutionVictim_Kill',
		'Acts_ExecutionVictim_Kill_End',
		'Acts_ExecutionVictim_KillTerminal',
		'Acts_ExecutionVictim_Loop',
		'Acts_ExecutionVictim_Unbow'
	];
	publicVariable 'M9_interrogationAnimations';
	M9_interrogationAnimations_executionerStanding_lowercase = [
		"acts_executioner_standing", 
		"acts_executioner_standingloop"
	];
	publicVariable 'M9_interrogationAnimations_executionerStanding_lowercase';
	M9SD_fnc_addUnitInterrogationActionMP = {
		params [['_unit', objNull]];
		if (!alive _unit) exitWith {
			systemChat 'Unit is already dead!';
			remoteExec ['', 'M9_interrogate_singleUnit_JIP'];
		};
		if (_unit getVariable ['interrogateActionAdded', false]) exitWIth {systemChat 'Action has already been added!';};
		_unit setVariable ['interrogateActionAdded', true, true];
		_name = name _unit;
		if (_unit getVariable ['interrogated', false]) exitWith {systemChat 'Unit has already been interrogated!';};
		if (M9_interrogationSetting_surrenderUnit) then {
			[_unit,["Surrender",_unit]] remoteExec ["action"];
			[_unit,true] remoteExec ["setCaptive",0];
			_unit setVariable ['EZM_isSurrendered',true,true];
			[_unit] spawn {
				_dude = (_this select 0);
				_weapon = currentWeapon _dude; 
				if(_weapon isEqualTo "") exitWith{};
				[_dude, _weapon] remoteExec ['removeWeapon'];
				sleep 0.1;
				_weaponHolder = "WeaponHolderSimulated" createVehicle [0,0,0];
				_weaponHolder addWeaponCargoGlobal [_weapon,1];
				_weaponHolder setPos (_dude modelToWorld [0,.2,1.2]);
				_weaponHolder disableCollisionWith _dude;
				_dir = random(360);
				_speed = 1.5;
				_weaponHolder setVelocity [_speed * sin(_dir), _speed * cos(_dir),4]; 
			};
		};
		if (M9_interrogationSetting_restrainUnit) then {
			[_unit,true] remoteExec ["setCaptive",0];
			[_unit,"Acts_AidlPsitMstpSsurWnonDnon_loop"] remoteExec["switchMove",0];
		};

		M9SD_fnc_addInterrogationActionToUnit = {
			_unit = _this;
			_ehidx1 = _unit addAction [format [
				"<t color='#ff5b32' size='1.3' font='puristaBold'><img image='%2'></img> Interrogate:<br/><t color='#FFFFFF' font='puristaMedium'>%1</t>", 
				_name, 
				'a3\ui_f\data\igui\cfg\simpletasks\types\talk_ca.paa'
			], {
				params ["_target", "_caller", "_actionId", "_arguments"];
				_ehidx2 = _actionId;
				M9_interrogationActionInProgress = false;
				_prisoner = _target;
				_interrogator = _caller;
				_prisoner setVariable ['isBeingInterrogated', true, true];
				_interrogator setVariable ['isInterrogating', true, true];
				_interrogator setVariable ['prisoner', _prisoner, true];
				_prisoner setVariable ['interrogator', _interrogator, true];
				_prisoner remoteExec ['doStop'];


				M9SD_fnc_addRandomHandgunWithMag = {
					params [['_interrogator', objNull], ['_switchToWeapon', false]];
					private _handgunClassname = handgunWeapon _interrogator;
					comment "Add weapon only if pistol slot is empty";
					if (_handgunClassname == '') then {
						private _handguns = [
							'hgun_P07_F', 
							'hgun_ACPC2_F', 
							'hgun_Pistol_heavy_01_MRD_F', 
							'hgun_Pistol_heavy_02_F', 
							'hgun_Rook40_F', 
							'hgun_P07_khk_F', 
							'hgun_P07_blk_F', 
							'hgun_Pistol_01_F', 
							'hgun_Pistol_heavy_01_green_F'
						];
						_handgunClassname = selectRandom _handguns;
						_interrogator addWeaponGlobal _handgunClassname;
					};
					comment "Refil/insert mag";
					private _unitWeaponsInfo = _interrogator weaponsInfo [_handgunClassname, false];
					private _unitHandgunInfo = _unitWeaponsInfo # 0;
					private _handgunMuzzlename = _unitHandgunInfo # 3;
					private _handgunAvailableMagazineTypes = getArray (configfile >> "CfgWeapons" >> _handgunClassname >> "magazines");
					private _handgunMagazinename = _handgunAvailableMagazineTypes # 0;
					private _magAmmo = 999;

					if (False) then {
						hint format ["Weapon Info\n
							_handgunClassname = %1,\n
							_handgunMuzzlename = %2,\n
							_handgunMagazinename = %3,\n
						",
						_handgunClassname,
						_handgunMuzzlename,
						_handgunMagazinename
						];
					};

					_interrogator addWeaponItem [_handgunClassname, [_handgunMagazinename, _magAmmo, _handgunMuzzlename], true];
					comment "Switch to weapon";
					if (_switchToWeapon) then {
						private _handgunWeaponIndex = _unitHandgunInfo # 0;
						comment "systemChat ('_handgunWeaponIndex = ' +  (str _handgunWeaponIndex));";
						_interrogator action ["SwitchWeapon", _interrogator, _interrogator, _handgunWeaponIndex];
					};
					comment "return class name of pistol";
					_handgunClassname;
				};
				comment "[player, true] call M9SD_fnc_addRandomHandgunWithMag;";
				M9SD_fnc_resetInterrogationCamera = {
					params [['_unit', objNull], ['_TEXT', '(Scroll to choose an interrogation option)'], ['_OFFSET',[-0.05, 0.45, 0.108]], ['_DIR', 180], ['_followBone', true]];
					private _imgSize = 12;  
					M9_rttStr_interrogationCamPIP = "M9_rtt_interrogationCamPIP";  
					M9_rttStr_interrogationCamPIPTextureStr = format ["#(argb,512,512,1)r2t(%1,1.0)", M9_rttStr_interrogationCamPIP];  
					M9_interrogationCam_unit = _unit; 
					M9_interrogationCam_spawnPos = getPosATL M9_interrogationCam_unit;  
					M9_interrogationCam_offset = _OFFSET;  
					comment "
					if (!isNil 'M9_interrogationCam_cameraObj') then {camDestroy M9_interrogationCam_cameraObj};";
					if (isNil 'M9_interrogationCam_cameraObj') then {M9_interrogationCam_cameraObj = "camera" camCreate M9_interrogationCam_spawnPos} else {
						if (isNull 	M9_interrogationCam_cameraObj) then {
							camDestroy M9_interrogationCam_cameraObj;
							M9_interrogationCam_cameraObj = "camera" camCreate M9_interrogationCam_spawnPos
						};
					};
					M9_interrogationCam_cameraObj attachTo [M9_interrogationCam_unit, M9_interrogationCam_offset, "head", _followBone];   
					M9_interrogationCam_cameraObj setDir _DIR; 
					comment "[M9_interrogationCam_cameraObj, [0,0,0]] call BIS_fnc_setObjectRotation;";   
					M9_interrogationCam_cameraObj camsetFOV 0.3; comment " standard FOV is 0.7; lesser (e.g 0.5) is zoomed in, greater (e.g 0.9) is zoomed out";  
					M9_interrogationCam_cameraObj camCommit 0; comment " 0 for immediate change, value in seconds for transition";  
					cameraEffectEnableHUD true;  
					M9_interrogationCam_cameraObj cameraEffect ["internal", "FRONT", M9_rttStr_interrogationCamPIP];  
					private _name = name M9_interrogationCam_unit;  
					private _classname = typeOf M9_interrogationCam_unit;  
					private _displaynamerole = getText (configFile >> "cfgVehicles" >> _classname >> "displayName");;  
					if (M9_interrogationSetting_showHints) then {
						hintSilent parseText (format ["<t font='puristaBold' size='1.5'>INTERROGATING<t size='%4'><img image='%2'></img><t font='puristaBold' size='1.5' color='#ff5b32'><br/>%3<t color='#ffffff' font='puristaSemiBold' size='1.0'><br/>“%1”<t font='puristaMedium' color='#ff5b32' size='0.8'><br/><br/>%5<br/></t>", _name, if (M9_interrogationSetting_showPIP) then {M9_rttStr_interrogationCamPIPTextureStr} else {''}, _displaynamerole, _imgSize, _TEXT]);  
					};
				};
				_prisoner spawn {
					waitUntil {sleep 0.01; !M9_interrogationActionInProgress};
					[_this, '(Scroll to choose an interrogation option)', [-0.05, 0.45, 0.108], 180] call M9SD_fnc_resetInterrogationCamera;
				};
				[_interrogator, true] call M9SD_fnc_addRandomHandgunWithMag;
				M9_action_weaponSafety = _interrogator addAction ["Weapon safety on", {}, [], 0, false, false, "DefaultAction", ""];
				[_interrogator, _prisoner] spawn {
					params ['_interrogator', '_prisoner'];
					waitUntil {sleep 0.01; (!alive _prisoner)};
					sleep 5;
					if ((animationState _interrogator) in M9_interrogationAnimations) then {
						{detach _x} foreach [_interrogator, _prisoner];
						[_interrogator, ''] remoteExec ['switchMove'];
						_interrogator setVariable ['isInterrogating', false, true];
					};
				};
				[_interrogator, 'Acts_Executioner_Standing'] remoteExec ['switchMove'];
				_prisoner attachTo [_interrogator,[0.45,0.17,0.0]];
				comment "[_prisoner, -43] remoteExec ['setDir', _prisoner];";
				[[_prisoner, -43], 'RE2_M9SD_fnc_stdrAlias', _unit] call M9SD_fnc_RE2_V3;
				[_prisoner, 'Acts_ExecutionVictim_Loop'] remoteExec ['switchMove', _prisoner];
				_prisoner spawn {
					sleep 0.5;
					[[_this, -43], 'RE2_M9SD_fnc_stdrAlias', 0] call M9SD_fnc_RE2_V3;
				};
				{playSound ['click', _x]} forEach [true, false];
				_ehidx_question = _interrogator addAction [format [
					"<t color='#ff5b32' size='1.3' font='puristaBold'><img image='%2'></img> Question subject:<br/><t color='#FFFFFF' font='puristaMedium'>%1</t>", 
					'Intimidate (squat down)', 
					"a3\data_f\unknown_object.paa"
				], {
					params ["_target", "_caller", "_actionId", "_arguments"];
					M9_interrogationActionInProgress = true;
					_interrogator = _caller;
					_interrogator = _target;
					_prisoner = _interrogator getVariable ['prisoner', objNull];
					_interrogator playMoveNow 'Acts_Executioner_Squat';
					_interrogator spawn {
						sleep 5;
						_this playMoveNow 'Acts_Executioner_Squat_End';
						waitUntil {sleep 0.01; ((animationState _this) in M9_interrogationAnimations_executionerStanding_lowercase)};
						M9_interrogationActionInProgress = false;
					};
					{playSound ['click', _x]} forEach [true, false];
					[_prisoner, 'Questioning prisoner...', [-0.4, 0.45, 0.1], 160, false] call M9SD_fnc_resetInterrogationCamera;
					'[-0.5, 0.4, 0.1], 150';

					_prisoner spawn {
						waitUntil {sleep 0.01; !M9_interrogationActionInProgress};
						[_this, '(Scroll to choose an interrogation option)', [-0.05, 0.45, 0.108], 180] call M9SD_fnc_resetInterrogationCamera;
					};
				}, nil, 6968, true, true, "", "(
					(_this == vehicle _this) && 
					(_this == _target) && 
					((_target getVariable ['prisoner', objNull]) getVariable ['isBeingInterrogated', false]) && 
					(_target getVariable ['isInterrogating', false]) && 
					(alive (_target getVariable ['prisoner', objNull])) && 
					(!M9_interrogationActionInProgress)
				)", 5];
				_ehidx_hit_backhand = _interrogator addAction [format [
					"<t color='#ff5b32' size='1.3' font='puristaBold'><img image='%2'></img> Hit subject:<br/><t color='#FFFFFF' font='puristaMedium'>%1</t>", 
					'Pistol whip (backhand)', 
					"a3\ui_f\data\gui\rsccommon\rscdebugconsole\warningcdc_ca.paa"
				], {
					params ["_target", "_caller", "_actionId", "_arguments"];
					M9_interrogationActionInProgress = true;
					_interrogator = _caller;
					_interrogator = _target;
					_prisoner = _interrogator getVariable ['prisoner', objNull];
					_interrogator playMoveNow 'Acts_Executioner_Backhand'; 
					_interrogator spawn {
						waitUntil {sleep 0.01; ((animationState _this) in M9_interrogationAnimations_executionerStanding_lowercase)};
						M9_interrogationActionInProgress = false;
					};
					[_prisoner, 'Acts_ExecutionVictim_Backhand'] remoteExec ['playMoveNow', _prisoner];
					_prisoner spawn {
						sleep 0.29;
						playSound3D ['a3\missions_f_beta\data\sounds\firing_drills\target_pop-down_small.wss', _this, false, getPosASL _this, 10, 1, 50]; 
					};
					_prisoner spawn {
						sleep 0.85;
						_this setdamage 0.35;
						_this setBleedingRemaining 60;
						playSound3D ['A3\Sounds_F_Orange\MissionSFX\Orange_Lights_Off', _this, false, getPosASL _this, 1.5, 1, 50]; 
						_hitsound = format ["A3\sounds_f\characters\human-sfx\P0%1\Hit_Max_%2.wss", selectRandom [4,5,6,7,8,9], selectRandom [1,2,3,4,5]]; 
						playSound3D [_hitsound, _this, false, getPosASL _this, 1.5, 1, 50]; 
					};
					{playSound ['click', _x]} forEach [true, false];
					[_prisoner, format ["%1 prisoner...", selectRandom ['Hitting', 'Pistol-whipping', 'Abusing', 'Attacking', 'Hurting']], [0.9, -0.15, 0.06], -90, false] call M9SD_fnc_resetInterrogationCamera;
					_prisoner spawn {
						waitUntil {sleep 0.01; !M9_interrogationActionInProgress};
						[_this, '(Scroll to choose an interrogation option)', [-0.05, 0.45, 0.108], 180] call M9SD_fnc_resetInterrogationCamera;
					};
				}, nil, 6967, true, true, "", "(
					(_this == vehicle _this) && 
					(_this == _target) && 
					((_target getVariable ['prisoner', objNull]) getVariable ['isBeingInterrogated', false]) && 
					(_target getVariable ['isInterrogating', false]) && 
					(alive (_target getVariable ['prisoner', objNull])) && 
					(!M9_interrogationActionInProgress)
				)", 5];
				_ehidx_hit_forehand = _interrogator addAction [format [
					"<t color='#ff5b32' size='1.3' font='puristaBold'><img image='%2'></img> Hit subject:<br/><t color='#FFFFFF' font='puristaMedium'>%1</t>", 
					'Pistol whip (forehand)', 
					"a3\ui_f\data\gui\rsccommon\rscdebugconsole\warningcdc_ca.paa"
				], {
					params ["_target", "_caller", "_actionId", "_arguments"];
					M9_interrogationActionInProgress = true;
					_interrogator = _caller;
					_interrogator = _target;
					_prisoner = _interrogator getVariable ['prisoner', objNull];
					_interrogator playMoveNow 'Acts_Executioner_Forehand'; 
					_interrogator spawn {
						waitUntil {sleep 0.01; ((animationState _this) in M9_interrogationAnimations_executionerStanding_lowercase)};
						M9_interrogationActionInProgress = false;
					};
					[_prisoner, 'Acts_ExecutionVictim_Forehand'] remoteExec ['playMoveNow', _prisoner];
					_prisoner spawn {
						sleep 0.29;
						playSound3D ['a3\missions_f_beta\data\sounds\firing_drills\target_pop-down_small.wss', _this, false, getPosASL _this, 10, 1, 50]; 
					};
					_prisoner spawn {
						sleep 1.10;
						_this setdamage 0.35;
						_this setBleedingRemaining 60;
						playSound3D ['A3\Sounds_F_Orange\MissionSFX\Orange_Lights_Off', _this, false, getPosASL _this, 1.5, 1, 50]; 
						_hitsound = format ["A3\sounds_f\characters\human-sfx\P0%1\Hit_Max_%2.wss", selectRandom [4,5,6,7,8,9], selectRandom [1,2,3,4,5]]; 
						playSound3D [_hitsound, _this, false, getPosASL _this, 1.5, 1, 50]; 
					};
					{playSound ['click', _x]} forEach [true, false];
					[_prisoner, format ["%1 prisoner...", selectRandom ['Hitting', 'Pistol-whipping', 'Abusing', 'Attacking', 'Hurting']], [-1.1, -0.05, 0.06], 90, false] call M9SD_fnc_resetInterrogationCamera;
					_prisoner spawn {
						waitUntil {sleep 0.01; !M9_interrogationActionInProgress};
						[_this, '(Scroll to choose an interrogation option)', [-0.05, 0.45, 0.108], 180] call M9SD_fnc_resetInterrogationCamera;
					};
				}, nil, 6966, true, true, "", "(
					(_this == vehicle _this) && 
					(_this == _target) && 
					((_target getVariable ['prisoner', objNull]) getVariable ['isBeingInterrogated', false]) && 
					(_target getVariable ['isInterrogating', false]) && 
					(alive (_target getVariable ['prisoner', objNull])) && 
					(!M9_interrogationActionInProgress)
				)", 5];
				_ehidx_unbow = _interrogator addAction [format [
					"<t color='#ff5b32' size='1.3' font='puristaBold'><img image='%2'></img> End interrogation:<br/><t color='#FFFFFF' font='puristaMedium'>%1</t>", 
					'Unbow (release restraints)', 
					"a3\ui_f\data\igui\cfg\holdactions\holdaction_secure_ca.paa"
				], {
					params ["_target", "_caller", "_actionId", "_arguments"];
					if (M9_interrogationSetting_useIntelText && (M9_interrogationSetting_intelText != '')) then {
						[[format ["Interrogation INTEL | %1", [time] call BIS_fnc_timeToString], M9_interrogationSetting_intelText, side (group _caller)], 'RE2_M9SD_fnc_giveIntelToPlayer'] call M9SD_fnc_RE2_V3;
						'openmap [true,false];';
						"diary" call bis_fnc_selectDiarySubject;
					};
					M9_interrogationActionInProgress = true;
					_target removeAction _actionId;
					_interrogator = _caller;
					_interrogator = _target;
					_prisoner = _interrogator getVariable ['prisoner', objNull];
					removeAllWeapons _prisoner;
					comment "
						_logic = createVehicle ['Land_HelipadEmpty_F', getPosATL _interrogator, [], 0, 'CAN_COLLIDE'];
						_logic setDir (getDir _interrogator);
						_prisoner attachTo [_logic,[0.45,0.17,0.0]];
						[_prisoner, -43] remoteExec ['setDir', _prisoner];
					";
					M9_interolockldir = true;
					_interrogator spawn {
						_dir = getDir _this;
						_pos = getPosATl _this;
						while {M9_interolockldir} do {
							_this setDir _dir;
							_this setPosATL _pos;
						};
					};
					comment "[_interrogator, _prisoner, _logic]";
					[_interrogator, _prisoner] spawn {
						params ['_interrogator', '_prisoner', '_logic'];
						'Acts_Executioner_ToPistol';
						[_interrogator, 'amovpercmstpslowwpstdnon'] remoteExec ['switchMove'];
						sleep 0.01;
						_interrogator playAction 'putDown';
						sleep 1;
						[_prisoner, 'Acts_ExecutionVictim_Unbow'] remoteExec ['playMoveNow', _prisoner];
						_interrogator playmove 'amovpercmstpslowwpstdnon';
						_prisoner setVariable ['isBeingInterrogated', false, true];
						_interrogator setVariable ['isInterrogating', false, true];
						_prisoner setVariable ['interrogated', true, true];
						sleep 2;
						detach _prisoner;
						comment "deleteVehicle _logic;";
						waitUntil {(animationState _prisoner != 'acts_executionvictim_loop')};
						M9_interolockldir = false;
					};
					[_prisoner] join _interrogator;
					[_prisoner, _interrogator] remoteExec ['doFollow', _prisoner];
					commandStop _prisoner;
					{playSound ['click', _x]} forEach [true, false];
					[_prisoner, format ["%1 prisoner...", selectRandom ['Releasing', 'Freeing', 'Uncuffing', 'Unbinding', 'Untying']], [1.1, 0.5, -0.23], 250, false] call M9SD_fnc_resetInterrogationCamera;
					_prisoner spawn {
						waitUntil {sleep 0.01; !M9_interrogationActionInProgress};
						[_this, '(Scroll to choose an interrogation option)', [-0.05, 0.45, 0.108], 180] call M9SD_fnc_resetInterrogationCamera;
					};
				}, nil, 6965, true, true, "", "(
					(_this == vehicle _this) && 
					(_this == _target) && 
					((_target getVariable ['prisoner', objNull]) getVariable ['isBeingInterrogated', false]) && 
					(_target getVariable ['isInterrogating', false]) && 
					(alive (_target getVariable ['prisoner', objNull])) && 
					(!M9_interrogationActionInProgress)
				)", 5];
				_ehidx_kill = _interrogator addAction [format [
					"<t color='#ff5b32' size='1.3' font='puristaBold'><img image='%2'></img> End interrogation:<br/><t color='#FFFFFF' font='puristaMedium'>%1</t>", 
					'Execute victim (headshot)', 
					"a3\ui_f\data\gui\rsc\rscdisplayarsenal\handgun_ca.paa"
				], {
					params ["_target", "_caller", "_actionId", "_arguments"];
					if (M9_interrogationSetting_useIntelText && (M9_interrogationSetting_intelText != '')) then {
						[[format ["Interrogation INTEL | %1", [time] call BIS_fnc_timeToString], M9_interrogationSetting_intelText, side (group _caller)], 'RE2_M9SD_fnc_giveIntelToPlayer'] call M9SD_fnc_RE2_V3;
						'openmap [true,false];';
						"diary" call bis_fnc_selectDiarySubject;
					};
					M9_interrogationActionInProgress = true;
					_interrogator = _caller;
					_interrogator = _target;
					_prisoner = _interrogator getVariable ['prisoner', objNull];
					_interrogator playMoveNow 'Acts_Executioner_Kill'; 
					_interrogator spawn {
						sleep 1.8;
						_this removeAction M9_action_weaponSafety;
						_this fire (handgunweapon _this);
						sleep 1;
						_this action ['SwitchWeapon', _this, _this, -1];
					};
					[_prisoner, 'Acts_ExecutionVictim_Kill'] remoteExec ['playMoveNow', _prisoner];
					_prisoner spawn {
						sleep 1.85;
						_this setDamage 1;
						_this setBleedingRemaining 60;
						_deathsound = format ["A3\sounds_f\characters\human-sfx\P0%1\Hit_Max_%2.wss", selectRandom [4,5,6,7,8,9], selectRandom [1,2,3,4,5]]; 
						playSound3D [_deathsound, _this, false, getPosASL _this, 1.5, 1, 50]; 
						detach _this;
						_this setVariable ['isBeingInterrogated', false, true];
					};
					{playSound ['click', _x]} forEach [true, false];
					[_prisoner, format ["%1 prisoner...", selectRandom ['Killing', 'Shooting', 'Executing']], [0, -0.5, 0.1], 0, false] call M9SD_fnc_resetInterrogationCamera;
					_prisoner spawn {
						waitUntil {sleep 0.01; !M9_interrogationActionInProgress};
						[_this, '(Scroll to choose an interrogation option)', [-0.05, 0.45, 0.108], 180] call M9SD_fnc_resetInterrogationCamera;
					};
				}, nil, 6964, true, true, "", "(
					(_this == vehicle _this) && 
					(_this == _target) && 
					((_target getVariable ['prisoner', objNull]) getVariable ['isBeingInterrogated', false]) && 
					(_target getVariable ['isInterrogating', false]) && 
					(alive (_target getVariable ['prisoner', objNull])) && 
					(!M9_interrogationActionInProgress)
				)", 5];

				_ehidx_leave = _interrogator addAction [format [
					"<t color='#ff5b32' size='1.3' font='puristaBold'><img image='%2'></img> Pause Interrogation:<br/><t color='#FFFFFF' font='puristaMedium'>%1</t>", 
					'Leave prisoner (return to normal)', 
					"a3\missions_f_gamma\data\img\icon_exit_big_ca.paa"
				], {
					params ["_target", "_caller", "_actionId", "_arguments"];
					_interrogator = _caller;
					_interrogator = _target;
					_prisoner = _interrogator getVariable ['prisoner', objNull];
					detach _prisoner;
					detach _interrogator;
					[_interrogator, ''] remoteExec ['switchMove'];
					_prisoner setVariable ['isBeingInterrogated', false, true];
					_interrogator setVariable ['isInterrogating', false, true];
					{playSound ['click', _x]} forEach [true, false];
					[_prisoner, format ["Interrogation suspended."], [0, -0.5, 0.1], 0, false] call M9SD_fnc_resetInterrogationCamera;
					_prisoner spawn {
						sleep 1;
						comment "_this call M9SD_fnc_addInterrogationActionToUnit;;";
					};
				}, nil, 6963, true, true, "", "(
					(_this == vehicle _this) && 
					(_this == _target) && 
					((_target getVariable ['prisoner', objNull]) getVariable ['isBeingInterrogated', false]) && 
					(_target getVariable ['isInterrogating', false]) && 
					(alive (_target getVariable ['prisoner', objNull])) && 
					(!M9_interrogationActionInProgress)
				)", 5];





				[_interrogator, _prisoner] spawn {
					params ['_interrogator', '_prisoner'];
					waitUntil {sleep 0.01; ((!alive _interrogator) or (!(_interrogator getVariable ['isInterrogating', false])))};
					if (!alive _interrogator) then {
						_interrogator setVariable ['isInterrogating', false, true];
					};
					_prisoner setVariable ['isBeingInterrogated', false, true];
				};
				[_interrogator, _ehidx_question, _ehidx_hit_backhand, _ehidx_hit_forehand, _ehidx_unbow, _ehidx_kill, _ehidx_leave] spawn {
					params ['_interrogator', '_ehidx_question', '_ehidx_hit_backhand', '_ehidx_hit_forehand', '_ehidx_unbow', '_ehidx_kill', '_ehidx_leave'];
					waitUntil {sleep 0.01; !(_interrogator getVariable ['isInterrogating', false])};
					_interrogator removeAction _ehidx_question;
					_interrogator removeAction _ehidx_hit_backhand;
					_interrogator removeAction _ehidx_hit_forehand;
					_interrogator removeAction _ehidx_unbow;
					_interrogator removeAction _ehidx_kill;
					_interrogator removeAction _ehidx_leave;
					_interrogator removeAction M9_action_weaponSafety;
					hintSilent '';
					{playSound ['click', _x]} forEach [true, false];
				};
				[_interrogator, _prisoner, _ehidx2] spawn {
					params ["_interrogator", '_prisoner', "_ehidx2"];
					waitUntil {sleep 0.01; ((_prisoner getVariable ['interrogated', false]) or (!alive _prisoner))};
					hintSilent '';
					{playSound ['click', _x]} forEach [true, false];
					_interrogator removeAction M9_action_weaponSafety;
					_prisoner removeAction _ehidx2;
					if ((animationState _interrogator) in M9_interrogationAnimations_executionerStanding_lowercase) then {
						_interrogator playMoveNow 'Acts_Executioner_ToPistol';
					};
					_interrogator setVariable ['isInterrogating', false, true];
				};
				[_prisoner, 'Hurt'] remoteExec ['setMimic'];
				'detach _prisoner;';
			}, nil, 6969, true, true, "", "(
				(_this == vehicle _this) && 
				(_this != _target) && 
				!(_target getVariable ['isBeingInterrogated', false]) && 
				!(_this getVariable ['isInterrogating', false]) && 
				!((_target getVariable ['interrogated', false])) && 
				(alive _target)
			)", 3];
		};

		_unit call M9SD_fnc_addInterrogationActionToUnit;

	};
	comment "
	[cursorObject] call M9SD_fnc_addUnitInterrogationActionMP;
	";
	0 = [_object] spawn {
		params [['_unit', objNull]];
		private _initREpack = [] spawn {
			if (!isNil 'M9SD_fnc_RE2_V3') exitWith {};
			comment "Initialize Remote-Execution Package";
			M9SD_fnc_initRE2_V3 = {
				M9SD_fnc_initRE2Functions_V3 = {
					comment "Prep RE2 functions.";
					M9SD_fnc_REinit2_V3 = {
						private _functionNameRE2 = '';
						if (isNil {_this}) exitWith {false};
						if !(_this isEqualType []) exitWith {false};
						if (count _this == 0) exitWith {false};
						private _functionNames = _this;
						private _aString = "";
						private _namespaces = [missionNamespace, uiNamespace];
						{
							if !(_x isEqualType _aString) then {continue};
							private _functionName = _x;
							_functionNameRE2 = format ["RE2_%1", _functionName];
							{
								private _namespace = _x;
								with _namespace do {
									if (!isNil _functionName) then {
										private _fnc = _namespace getVariable [_functionName, {}];
										private _fncStr = str _fnc;
										private _fncStr2 = "{" + 
											"removeMissionEventHandler ['EachFrame', _thisEventHandler];" + 
											"_thisArgs call " + _fncStr + 
										"}";
										private _fncStrArr = _fncStr2 splitString '';
										_fncStrArr deleteAt (count _fncStrArr - 1);
										_fncStrArr deleteAt 0;
										_namespace setVariable [_functionNameRE2, _fncStrArr, true];
									};
								};
							} forEach _namespaces;
						} forEach _functionNames;
						true;_functionNameRE2;
					};
					M9SD_fnc_RE2_V3 = {
						params [["_REarguments", []], ["_REfncName2", ""], ["_REtarget", player], ["_JIPparam", false]];
						if (!((missionnamespace getVariable [_REfncName2, []]) isEqualType []) && !((uiNamespace getVariable [_REfncName2, []]) isEqualType [])) exitWith {
							systemChat "::Error:: remoteExec failed (invalid _REfncName2 - not an array).";
						};
						if ((count (missionnamespace getVariable [_REfncName2, []]) == 0) && (count (uiNamespace getVariable [_REfncName2, []]) == 0)) exitWith {
							systemChat "::Error:: remoteExec failed (invalid _REfncName2 - empty array).";
							systemChat str _REfncName2;
						};
						[[_REfncName2, _REarguments],{ 
							addMissionEventHandler ["EachFrame", (missionNamespace getVariable [_this # 0, ['']]) joinString '', _this # 1]; 
						}] remoteExec ['call', _REtarget, _JIPparam];
					};
					comment "systemChat '[ RE2 Package ] : RE2 functions initialized.';";
				};
				M9SD_fnc_initRE2FunctionsGlobal_V2 = {
					comment "Prep RE2 functions on all clients+jip.";
					private _fncStr = format ["{
						removeMissionEventHandler ['EachFrame', _thisEventHandler];
						_thisArgs call %1
					}", M9SD_fnc_initRE2Functions_V3];
					_fncStr = _fncStr splitString '';
					_fncStr deleteAt (count _fncStr - 1);
					_fncStr deleteAt 0;
					missionNamespace setVariable ["RE2_M9SD_fnc_initRE2Functions_V2", _fncStr, true];
					[["RE2_M9SD_fnc_initRE2Functions_V2", []],{ 
						addMissionEventHandler ["EachFrame", (missionNamespace getVariable ["RE2_M9SD_fnc_initRE2Functions_V2", ['']]) joinString '', _this # 1]; 
					}] remoteExec ['call', 0, 'RE2_M9SD_JIP_initRE2Functions_V2'];
					comment "Delete from jip queue: remoteExec ['', 'RE2_M9SD_JIP_initRE2Functions_V2'];";
				};
				call M9SD_fnc_initRE2FunctionsGlobal_V2;
			};
			call M9SD_fnc_initRE2_V3;
			waitUntil {!isNil 'M9SD_fnc_RE2_V3'};
			if (true) exitWith {true};
		};
		waitUntil {scriptDone _initREpack};
		waitUntil {!isNil 'M9SD_fnc_REinit2_V3'};
		M9SD_fnc_stdrAlias = {
			(_this # 0) setDir (_this # 1)
		};
		['M9SD_fnc_stdrAlias'] call M9SD_fnc_REinit2_V3;
		waitUntil {!isNil 'RE2_M9SD_fnc_stdrAlias'};


		M9SD_fnc_giveIntelToPlayer = { 
			params ['_title', '_text', '_side']; 
			if (side (group player) in [_side, sideLogic]) then { 
				_dname = 'diary';
				["intelAdded", [_title]] call bis_fnc_showNotification; 
				player creatediarysubject [_dname, localize "STR_A3_BIS_fnc_initIntelObject_intel"];
				player creatediaryrecord [_dname, [_title, _text]]; 

			};
		};




		['M9SD_fnc_giveIntelToPlayer'] call M9SD_fnc_REinit2_V3;
		waitUntil {!isNil 'RE2_M9SD_fnc_giveIntelToPlayer'};

		['M9SD_fnc_addUnitInterrogationActionMP'] call M9SD_fnc_REinit2_V3;
		waitUntil {!isNil 'RE2_M9SD_fnc_addUnitInterrogationActionMP'};
		M9SD_fnc_addUnitInterrogationActionMPGlobalJIP = {
			params [['_unit', objNull]];
			[[_unit], 'RE2_M9SD_fnc_addUnitInterrogationActionMP', 0, 'M9_interrogate_singleUnit_JIP'] call M9SD_fnc_RE2_V3;
		};
		[_unit] call M9SD_fnc_addUnitInterrogationActionMPGlobalJIP;
		systemChat 'Interrogation action added to prisoner.';
	};
};

if (isNull _prisoner) exitWIth {systemChat '(isNull _prisoner)';};

profileNamespace setVariable ['M9_interrogationSetting_showHints', _M9_interrogationSetting_showHints];
profileNamespace setVariable ['M9_interrogationSetting_showPIP', _M9_interrogationSetting_showPIP];
profileNamespace setVariable ['M9_interrogationSetting_surrenderUnit', _M9_interrogationSetting_surrenderUnit];
profileNamespace setVariable ['M9_interrogationSetting_restrainUnit', _M9_interrogationSetting_restrainUnit];
profileNamespace setVariable ['M9_interrogationSetting_useIntelText', _M9_interrogationSetting_useIntelText];
profileNamespace setVariable ['M9_interrogationSetting_intelText', _M9_interrogationSetting_intelText];
saveprofilenamespace;

missionNamespace setVariable ['M9_interrogationSetting_showHints', _M9_interrogationSetting_showHints, true];
missionNamespace setVariable ['M9_interrogationSetting_showPIP', _M9_interrogationSetting_showPIP, true];
missionNamespace setVariable ['M9_interrogationSetting_surrenderUnit', _M9_interrogationSetting_surrenderUnit, true];
missionNamespace setVariable ['M9_interrogationSetting_restrainUnit', _M9_interrogationSetting_restrainUnit, true];
missionNamespace setVariable ['M9_interrogationSetting_useIntelText', _M9_interrogationSetting_useIntelText, true];
missionNamespace setVariable ['M9_interrogationSetting_intelText', _M9_interrogationSetting_intelText, true];

comment "systemChat 'Adding interrogation option to prisoner...';";
[_prisoner] call M9SD_fnc_moduleInterrogation_composition;

comment "
A3_InterroGationExeCutionModUle

Arma 3 Steam Workshop
https://steamcommunity.com/sharedfiles/filedetails/?id=3041863730

MIT License
Copyright (c) 2023 M9-SD
https://github.com/M9-SD/A3_InterroGationExeCutionModUle/blob/main/LICENSE
";