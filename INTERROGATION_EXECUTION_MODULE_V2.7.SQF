comment "
A3_InterroGationExeCutionModUle

Arma 3 Steam Workshop
https://steamcommunity.com/sharedfiles/filedetails/?id=3041863730

MIT License
Copyright (c) 2023 M9-SD
https://github.com/M9-SD/A3_InterroGationExeCutionModUle/blob/main/LICENSE
";

comment "Delete composition helipad";

	if ((!isNull (findDisplay 312)) && (!isNil 'this')) then {
		if (!isNull this) then {
			if (typeOf this == 'Land_HelipadEmpty_F') then {
				deleteVehicle this;
			};
		};
	};

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
		_zeusLogic = objNull;
		_zeusLogic = getAssignedCuratorLogic player;
		if (isNull _zeusLogic) exitWith {systemChat 'ERROR | Zeus logic entity not found!';};
		_objType = typeOf _object;
		_objName = if (isPlayer _object) then {name _object} else {getText (configFile >> 'cfgVehicles' >> _objType >> 'displayName');};
		if (_objName == '') then 
		{
			_objName = _objType;
		};
		_feeback = format ["Adding interrogation action to [ %1 ]...", _objName];
		[_zeusLogic, _feeback] call BIS_fnc_showCuratorFeedbackMessage;
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

comment "Send Messages";

	M9SD_fnc_censorBlacklistedWords = {
		params [["_message","",[""]]];
		private _isFound = false;
		private _return = _message;
		private _badWords = [
			["s","h","i","t"] joinString "",
			["n","i","g","g","e"] joinString "",
			["n","i","g","g","a"] joinString "",
			["n","i","g","g","e","r"] joinString "",
			["n","i","g","g"] joinString "",
			["f","u","c","k"] joinString "",
			["c","u","n","t"] joinString "",
			["f","a","g"] joinString "",
			["g","a","y"] joinString "",
			["z","a","m"] joinString ""
		];
		{
			if(((toLower _return) find _x) != -1) then {
				_isFound = true;
				private _length = count _x;
				private _index = (toLower _return) find _x;
				_return = _return splitString "";
				for "_i" from _index to (_index + _length - 1) do {
					_return set [_i,"*"];
				};
				_return = _return joinString "";
			};
		} forEach _badWords;
		if (_isFound) then {
			_return = [_return] call M9SD_fnc_censorBlacklistedWords;
		};
		_return
	};

comment "Dialog Creation";

	M9SD_fnc_convertToGUI_GRIDFormat = {
		params ["_mode","_value"];

		comment "Defines";
			private _GUI_GRID_WAbs = ((safeZoneW / safeZoneH) min 1.2);
			private _GUI_GRID_HAbs = (_GUI_GRID_WAbs / 1.2);
			private _GUI_GRID_W = (_GUI_GRID_WAbs / 40);
			private _GUI_GRID_H = (_GUI_GRID_HAbs / 25);
			private _GUI_GRID_X = (safeZoneX);
			private _GUI_GRID_Y = (safeZoneY + safeZoneH - _GUI_GRID_HAbs);

			private _GUI_GRID_CENTER_WAbs = _GUI_GRID_WAbs;
			private _GUI_GRID_CENTER_HAbs = _GUI_GRID_HAbs;
			private _GUI_GRID_CENTER_W = _GUI_GRID_W;
			private _GUI_GRID_CENTER_H = _GUI_GRID_H;
			private _GUI_GRID_CENTER_X = (safeZoneX + (safeZoneW - _GUI_GRID_CENTER_WAbs)/2);
			private _GUI_GRID_CENTER_Y = (safeZoneY + (safeZoneH - _GUI_GRID_CENTER_HAbs)/2);

		comment "Mode Selection";
		private _return = switch (toUpper _mode) do {
			case "X": {((_value) * _GUI_GRID_W + _GUI_GRID_CENTER_X)};
			case "Y": {((_value) * _GUI_GRID_H + _GUI_GRID_CENTER_Y)};
			case "W": {((_value) * _GUI_GRID_W)};
			case "H": {((_value) * _GUI_GRID_H)};
		};
		_return
	};
	uiNamespace setVariable ["M9SD_fnc_convertToGUI_GRIDFormat",M9SD_fnc_convertToGUI_GRIDFormat];

	M9SD_fnc_initDynamicDisplay = {
		params [
			['_dialogueColor', [0,0.5,0.5,1]],
			['_dialogBackgroundCO', [0,0,0,0.7]]
		];
		createDialog "RscDisplayEmpty";
		showchat true;
		private _display = findDisplay -1;

		private _label = _display ctrlCreate ["RscText",IDC_TITLE];
		_label ctrlSetPositionX (["X",6.5] call M9SD_fnc_convertToGUI_GRIDFormat);
		_label ctrlSetPositionW (["W",27] call M9SD_fnc_convertToGUI_GRIDFormat);
		_label ctrlSetPositionH (["H",1] call M9SD_fnc_convertToGUI_GRIDFormat);
		_label ctrlSetBackgroundColor _dialogueColor;
		_label ctrlCommit 0;

		private _background = _display ctrlCreate ["RscText",IDC_BACKGROUND];
		_background ctrlSetPositionX (["X",6.5] call M9SD_fnc_convertToGUI_GRIDFormat);
		_background ctrlSetPositionW (["W",27] call M9SD_fnc_convertToGUI_GRIDFormat);
		_background ctrlSetBackgroundColor _dialogBackgroundCO;
		_background ctrlCommit 0;

		private _contentGroup = _display ctrlCreate ["RscControlsGroupNoScrollbars",IDC_CONTENT];
		_contentGroup ctrlSetPositionX (["X",7] call M9SD_fnc_convertToGUI_GRIDFormat);
		_contentGroup ctrlSetPositionW (["W",26] call M9SD_fnc_convertToGUI_GRIDFormat);
		_contentGroup ctrlCommit 0;

		private _okayButton = _display ctrlCreate ["RscButtonMenuOk",IDC_CONFIRM];
		_okayButton ctrlSetPositionX (["X",28.5] call M9SD_fnc_convertToGUI_GRIDFormat);
		_okayButton ctrlSetPositionW (["W",5] call M9SD_fnc_convertToGUI_GRIDFormat);
		_okayButton ctrlSetPositionH (["H",1] call M9SD_fnc_convertToGUI_GRIDFormat);
		_okayButton ctrlAddEventhandler ["ButtonClick",{
			params ["_control"];
			private _display = ctrlParent _control;
			(_display getVariable "M9_dynamicDisplayData") params ["_controls","_onConfirm","_onCancel","_args"];

			private _values = _controls apply {
				_x params ["_controlsGroup","_settings"];

				[_controlsGroup,_settings] call (_controlsGroup getVariable "controlValue");
			};

			[_values,_args,_display] call _onConfirm;
		}];
		_okayButton ctrlCommit 0;

		private _cancelButton = _display ctrlCreate ["RscButtonMenuCancel",IDC_CANCEL];
		_cancelButton ctrlSetPositionX (["X",6.5] call M9SD_fnc_convertToGUI_GRIDFormat);
		_cancelButton ctrlSetPositionW (["W",5] call M9SD_fnc_convertToGUI_GRIDFormat);
		_cancelButton ctrlSetPositionH (["H",1] call M9SD_fnc_convertToGUI_GRIDFormat);
		_cancelButton ctrlAddEventhandler ["ButtonClick",{
			params ["_control"];
			private _display = ctrlParent _control;
			(_display getVariable "M9_dynamicDisplayData") params ["_controls","_onConfirm","_onCancel","_args"];

			private _values = _controls apply {
				_x params ["_controlsGroup","_settings"];

				[_controlsGroup,_settings] call (_controlsGroup getVariable "controlValue");
			};

			[_values,_args,_display] call _onCancel;
		}];
		_cancelButton ctrlCommit 0;

		_display displayAddEventHandler ["KeyDown", {
			params ["_display", "_keyCode"];

			if (_keyCode == 1) then {
				(_display getVariable "M9_dynamicDisplayData") params ["_controls","_onConfirm","_onCancel","_args"];

				private _values = _controls apply {
					_x params ["_controlsGroup","_settings"];

					[_controlsGroup,_settings] call (_controlsGroup getVariable "controlValue");
				};

				[_values,_args,_display] call _onCancel;
			};

			false
		}];

		_display
	};

	M9SD_fnc_createRowBase = {
		params ["_display"];
		private _contentGroup = _display displayCtrl IDC_CONTENT;
		private _controlsGroupRow = _display ctrlCreate ["RscControlsGroupNoScrollbars",IDC_ROW_GROUP,_contentGroup];
		_controlsGroupRow ctrlSetPosition [0,0,(["W",26] call M9SD_fnc_convertToGUI_GRIDFormat),(["H",1] call M9SD_fnc_convertToGUI_GRIDFormat)];
		_controlsGroupRow ctrlCommit 0;

		private _rowLabel = _display ctrlCreate ["RscText",IDC_ROW_LABEL,_controlsGroupRow];
		_rowLabel ctrlSetPosition [0,0,(["W",10] call M9SD_fnc_convertToGUI_GRIDFormat),(["H",1] call M9SD_fnc_convertToGUI_GRIDFormat)];
		_rowLabel ctrlSetBackgroundColor [0,0,0,0.5];
		_rowLabel ctrlCommit 0;

		_controlsGroupRow
	};

	M9SD_fnc_createComboRow = {
		params ["_display","_defaultValue","_settings", '_ctrlVarname'];
		_settings params ["_entries"];
		private _rowControlGroup = [_display] call M9SD_fnc_createRowBase;

		private _combo = _display ctrlCreate ["RscCombo",IDC_ROW_COMBO,_rowControlGroup];
		_display setVariable [_ctrlVarname, _combo];
		_combo ctrlSetPosition [(["W",10.1] call M9SD_fnc_convertToGUI_GRIDFormat),0,(["W",15.9] call M9SD_fnc_convertToGUI_GRIDFormat),(["H",1] call M9SD_fnc_convertToGUI_GRIDFormat)];
		_combo ctrlCommit 0;

		{
			_x params ["_value","_text","_tooltip","_picture","_textColor"];

			private _index = _combo lbAdd _text;
			_combo lbSetTooltip [_index,_tooltip];
			_combo lbSetPicture [_index,_picture];
			_combo lbSetColor [_index,_textColor];
			_combo setVariable [str _index,_value];

			if(_value isEqualTo _defaultValue) then {
				_combo lbSetCurSel _index;
			};
		} forEach _entries;
		_combo lbAdd "   ";
		_combo lbAdd "    ";

		_rowControlGroup setVariable ["controlValue",{
			params ["_controlsGroup"];

			private _ctrlCombo = _controlsGroup controlsGroupCtrl IDC_ROW_COMBO;
			_ctrlCombo getVariable str lbCurSel _ctrlCombo
		}];

		_rowControlGroup
	};

	M9SD_fnc_createEditRow = {
		params ["_display","_defaultValue","_settings", '_ctrlVarname'];
		_settings params ["_height"];
		private _rowControlGroup = [_display] call M9SD_fnc_createRowBase;

		private _edit = _display ctrlCreate ["RscEdit",IDC_ROW_EDIT,_rowControlGroup];
		_display setVariable [_ctrlVarname, _edit];
		_edit ctrlSetPosition [(["W",10.1] call M9SD_fnc_convertToGUI_GRIDFormat),pixelH,(["W",15.9] call M9SD_fnc_convertToGUI_GRIDFormat),(["H",1] call M9SD_fnc_convertToGUI_GRIDFormat) - pixelH];
		_edit ctrlSetTextColor [1,1,1,1];
		_edit ctrlSetBackgroundColor [0,0,0,0.2];
		_edit ctrlCommit 0;

		_edit ctrlSetText _defaultValue;

		_rowControlGroup setVariable ["controlValue", {
			params ["_controlsGroup"];
			ctrlText (_controlsGroup controlsGroupCtrl IDC_ROW_EDIT)
		}];

		_rowControlGroup
	};

	M9SD_fnc_createEditMultiRow = {
		params ["_display","_defaultValue","_settings", '_ctrlVarname'];
		_settings params [["_height",4]];
		private _rowControlGroup = [_display] call M9SD_fnc_createRowBase;
		_rowControlGroup ctrlSetPositionH (["H",_height + 1] call M9SD_fnc_convertToGUI_GRIDFormat);
		_rowControlGroup ctrlCommit 0;

		private _label = _rowControlGroup controlsGroupCtrl IDC_ROW_LABEL;
		_label ctrlSetPositionW (["W",26] call M9SD_fnc_convertToGUI_GRIDFormat);
		_label ctrlCommit 0;

		private _edit = _display ctrlCreate ["RscEditMulti",IDC_ROW_EDIT,_rowControlGroup];
		_display setVariable [_ctrlVarname, _edit];
		_edit ctrlSetPosition [pixelW,(["H",1] call M9SD_fnc_convertToGUI_GRIDFormat),(["W",26] call M9SD_fnc_convertToGUI_GRIDFormat) - pixelW,(["H",1] call M9SD_fnc_convertToGUI_GRIDFormat) - pixelH];
		_edit ctrlSetPositionH (["H",_height] call M9SD_fnc_convertToGUI_GRIDFormat);
		_edit ctrlSetTextColor [1,1,1,1];
		_edit ctrlSetBackgroundColor [0,0,0,0.2];
		_edit ctrlSetText _defaultValue;
		_edit ctrlCommit 0;

		_rowControlGroup setVariable ["controlValue", {
			params ["_controlsGroup"];
			ctrlText (_controlsGroup controlsGroupCtrl IDC_ROW_EDIT)
		}];

		_rowControlGroup
	};

	M9SD_fnc_createEditCodeRow = {
		params ["_display","_defaultValue","_settings"];
		_settings params ["_height"];
		private _rowControlGroup = [_display,_defaultValue,[_height]] call M9SD_fnc_createEditMultiRow;

		private _execButton = _display displayCtrl IDC_CONFIRM;
		_execButton ctrlSetText "Exec";
		_execButton ctrlCommit 0;

		private _edit = _display displayCtrl IDC_ROW_EDIT;
		_edit ctrlSetTextColor [1,1,1,1];
		_edit ctrlSetBackgroundColor [0,0,0,0.5];
		_edit ctrlSetFont "EtelkaMonospacePro";
		_edit ctrlSetFontHeight 0.03;
		_edit ctrlSetText _defaultValue;
		_edit ctrlCommit 0;

		_rowControlGroup
	};

	M9SD_fnc_createListRow = {
		params ["_display","_defaultValue","_settings", '_ctrlVarname'];
		_settings params ["_entries","_height"];
		private _rowControlGroup = [_display] call M9SD_fnc_createRowBase;
		_rowControlGroup ctrlSetPositionH (["H",_height + 1] call M9SD_fnc_convertToGUI_GRIDFormat);
		_rowControlGroup ctrlCommit 0;

		private _label = _rowControlGroup controlsGroupCtrl IDC_ROW_LABEL;
		_label ctrlSetPositionW (["W",26] call M9SD_fnc_convertToGUI_GRIDFormat);
		_label ctrlCommit 0;

		private _listBox = _display ctrlCreate ["RscListBox",IDC_ROW_COMBO,_rowControlGroup];
		_display setVariable [_ctrlVarname, _listBox];
		_listBox ctrlSetPosition [0,(["H",1] call M9SD_fnc_convertToGUI_GRIDFormat),(["W",26] call M9SD_fnc_convertToGUI_GRIDFormat),(["H",6] call M9SD_fnc_convertToGUI_GRIDFormat)];
		_listBox ctrlSetPositionH (["H",_height] call M9SD_fnc_convertToGUI_GRIDFormat);
		_listBox ctrlCommit 0;

		{
			_x params ["_value","_text","_tooltip","_picture","_textColor"];

			private _index = _listBox lbAdd _text;
			_listBox lbSetTooltip [_index,_tooltip];
			_listBox lbSetPicture [_index,_picture];
			_listBox lbSetColor [_index,_textColor];
			_listBox setVariable [str _index,_value];

			if(_value isEqualTo _defaultValue) then {
				_listBox lbSetCurSel _index;
			};
		} forEach _entries;

		_rowControlGroup setVariable ["controlValue",{
			params ["_controlsGroup"];

			private _ctrlCombo = _controlsGroup controlsGroupCtrl IDC_ROW_COMBO;
			_ctrlCombo getVariable str lbCurSel _ctrlCombo
		}];

		_rowControlGroup
	};

	M9SD_fnc_createSidesRow = {
		params ["_display","_defaultValue","_settings"];
		private _rowControlGroup = [_display] call M9SD_fnc_createRowBase;

		_rowControlGroup ctrlSetPositionH (["H",2.5] call M9SD_fnc_convertToGUI_GRIDFormat);

		private _label = _rowControlGroup controlsGroupCtrl IDC_ROW_LABEL;
		_label ctrlSetPositionH (["H",2.5] call M9SD_fnc_convertToGUI_GRIDFormat);
		_label ctrlCommit 0;

		private _background = _display ctrlCreate ["RscText",-1,_rowControlGroup];
		_background ctrlSetBackgroundColor [0,0,0,0.6];
		_background ctrlSetPosition [(["W",10] call M9SD_fnc_convertToGUI_GRIDFormat),0,(["W",16] call M9SD_fnc_convertToGUI_GRIDFormat),(["H",2.5] call M9SD_fnc_convertToGUI_GRIDFormat)];
		_background ctrlSetTextColor [1,1,1,0.5];
		_background ctrlCommit 0;

		private _sidesGroup = _display ctrlCreate ["RscControlsGroupNoScrollbars",IDC_ROW_SIDES,_rowControlGroup];
		_sidesGroup ctrlSetPosition [(["W",10] call M9SD_fnc_convertToGUI_GRIDFormat),0,(["W",16] call M9SD_fnc_convertToGUI_GRIDFormat),(["H",2.5] call M9SD_fnc_convertToGUI_GRIDFormat)];
		_sidesGroup ctrlCommit 0;

		private _blufor = _display ctrlCreate ["RscActivePicture",IDC_SIDES_BLUFOR,_sidesGroup];
		_blufor ctrlSetText "\a3\Ui_F_Curator\Data\Displays\RscDisplayCurator\side_west_ca.paa";
		_blufor ctrlSetPosition [(["W",2.5] call M9SD_fnc_convertToGUI_GRIDFormat),(["H",0.25] call M9SD_fnc_convertToGUI_GRIDFormat),(["W",2] call M9SD_fnc_convertToGUI_GRIDFormat),(["H",2] call M9SD_fnc_convertToGUI_GRIDFormat)];
		_blufor ctrlCommit 0;

		private _opfor = _display ctrlCreate ["RscActivePicture",IDC_SIDES_OPFOR,_sidesGroup];
		_opfor ctrlSetText "\a3\Ui_F_Curator\Data\Displays\RscDisplayCurator\side_east_ca.paa";
		_opfor ctrlSetPosition [(["W",5.5] call M9SD_fnc_convertToGUI_GRIDFormat),(["H",0.25] call M9SD_fnc_convertToGUI_GRIDFormat),(["W",2] call M9SD_fnc_convertToGUI_GRIDFormat),(["H",2] call M9SD_fnc_convertToGUI_GRIDFormat)];
		_opfor ctrlCommit 0;

		private _indep = _display ctrlCreate ["RscActivePicture",IDC_SIDES_INDEPENDENT,_sidesGroup];
		_indep ctrlSetText "\a3\Ui_F_Curator\Data\Displays\RscDisplayCurator\side_guer_ca.paa";
		_indep ctrlSetPosition [(["W",8.5] call M9SD_fnc_convertToGUI_GRIDFormat),(["H",0.25] call M9SD_fnc_convertToGUI_GRIDFormat),(["W",2] call M9SD_fnc_convertToGUI_GRIDFormat),(["H",2] call M9SD_fnc_convertToGUI_GRIDFormat)];
		_indep ctrlCommit 0;

		private _civ = _display ctrlCreate ["RscActivePicture",IDC_SIDES_CIVILIAN,_sidesGroup];
		_civ ctrlSetText "\a3\Ui_F_Curator\Data\Displays\RscDisplayCurator\side_civ_ca.paa";
		_civ ctrlSetPosition [(["W",11.5] call M9SD_fnc_convertToGUI_GRIDFormat),(["H",0.25] call M9SD_fnc_convertToGUI_GRIDFormat),(["W",2] call M9SD_fnc_convertToGUI_GRIDFormat),(["H",2] call M9SD_fnc_convertToGUI_GRIDFormat)];
		_civ ctrlCommit 0;

		if (_defaultValue isEqualType []) then {
			_defaultValue = +_defaultValue;
		};

		private _allowMultiple = _defaultValue isEqualType [];
		_sidesGroup setVariable ["controlValue",_defaultValue];

		private _controls = [];
		private _IDCs = [IDC_SIDES_OPFOR,IDC_SIDES_BLUFOR,IDC_SIDES_INDEPENDENT,IDC_SIDES_CIVILIAN];
		{
			private _sideCtrl = _sidesGroup controlsGroupCtrl _x;
			private _color = [_forEachIndex] call BIS_fnc_sideColor;
			private _side = [_forEachIndex] call BIS_fnc_sideType;

			_sideCtrl ctrlSetActiveColor _color;
			if(_allowMultiple) then {
				if(_side in _defaultValue) then {
					[_sideCtrl,1.2,0] call BIS_fnc_ctrlSetScale;
				} else {
					_color set [3,0.5];
				};
			} else {
				if(_side isEqualTo _defaultValue) then {
					[_sideCtrl,1.2,0] call BIS_fnc_ctrlSetScale;
				} else {
					_color set [3,0.5];
				};
			};
			_sideCtrl ctrlSetTextColor _color;

			if(_allowMultiple) then {
				_sideCtrl ctrlAddEventHandler ["ButtonClick",{
					params ["_sideCtrl"];
					(_sideCtrl getVariable "params") params ["_color","_side"];
					private _controlGroup = ctrlParentControlsGroup _sideCtrl;
					private _value = _controlGroup getVariable "controlValue";

					private _scale = "";
					private _alpha = "";
					if(_side in _value) then {
						_value deleteAt (_value find _side);
						_scale = 1;
						_alpha = 0.5;
					} else {
						_value pushBack _side;
						_scale = 1.25;
						_alpha = 1;
					};
					_color set [3,_alpha];
					_sideCtrl ctrlSetTextColor _color;
					[_sideCtrl,_scale,0.1] call BIS_fnc_ctrlSetScale;
				}];
			} else {
				_sideCtrl ctrlAddEventHandler ["ButtonClick",{
					params ["_sideCtrl"];
					(_sideCtrl getVariable "params2") params ["_controls"];
					private _controlGroup = ctrlParentControlsGroup _sideCtrl;
					{
						_x params ["_ctrl","_color","_side"];
						private _scale = "";
						private _alpha = "";
						if(_ctrl isEqualTo _sideCtrl) then {
							_scale = 1.25;
							_alpha = 1;
							_controlGroup setVariable ["controlValue",_side];
						} else {
							_scale = 1;
							_alpha = 0.5;
						};
						_color set [3,_alpha];
						_ctrl ctrlSetTextColor _color;
						[_ctrl,_scale,0.1] call BIS_fnc_ctrlSetScale;
					}forEach _controls;
				}];

				_controls pushBack [_sideCtrl, _color, _side];
			};
			_sideCtrl setVariable ["params",[_color,_side]];
			_sideCtrl setVariable ["params2",[_controls]];
		}forEach [IDC_SIDES_OPFOR,IDC_SIDES_BLUFOR,IDC_SIDES_INDEPENDENT,IDC_SIDES_CIVILIAN];

		_rowControlGroup setVariable ["controlValue", {
			params ["_controlsGroup"];

			private _ctrlSides = _controlsGroup controlsGroupCtrl IDC_ROW_SIDES;
			_ctrlSides getVariable "controlValue"
		}];

		_rowControlGroup
	};

	M9SD_fnc_createSliderRow = {
		params ["_display","_defaultValue","_settings", '_ctrlVarname'];
		_settings params ["_min","_max","_isPercent","_drawRadius","_radiusCenter","_radiusColor"];
		private _rowControlGroup = [_display] call M9SD_fnc_createRowBase;
		_rowControlGroup setVariable ["M9SD_isPercent",_isPercent];

		private _slider = _display ctrlCreate ["RscXSliderH",IDC_ROW_SLIDER,_rowControlGroup];
		_slider ctrlSetPosition [(["W",10.1] call M9SD_fnc_convertToGUI_GRIDFormat),0,(["W",13.5] call M9SD_fnc_convertToGUI_GRIDFormat),(["H",1] call M9SD_fnc_convertToGUI_GRIDFormat)];
		_slider ctrlSetTextColor [1,1,1,0.6];
		_slider ctrlSetActiveColor [1,1,1,1];
		_slider ctrlCommit 0;

		private _sliderEdit = _display ctrlCreate ["RscEdit",IDC_ROW_EDIT,_rowControlGroup];
		_sliderEdit ctrlSetPosition [(["W",23.7] call M9SD_fnc_convertToGUI_GRIDFormat),pixelH,(["W",2.3] call M9SD_fnc_convertToGUI_GRIDFormat),((["H",1] call M9SD_fnc_convertToGUI_GRIDFormat) - pixelH)];
		_sliderEdit ctrlSetTextColor [1,1,1,1];
		_sliderEdit ctrlSetBackgroundColor [0,0,0,0.2];
		_sliderEdit ctrlCommit 0;

		if(_drawRadius) then {
			["M9SD_drawSliderRadius","onEachFrame",{
				params ["_ctrlSlider","_center","_color"];
				if(isNull _ctrlSlider || {_center isEqualTo objNull}) exitWith {
					["M9SD_drawSliderRadius","onEachFrame"] call BIS_fnc_removeStackedEventHandler;
				};

				if (_center isEqualType objNull) then {
					_center = ASLToAGL getPosASLVisual _center;
				};

				private _radius = sliderPosition _ctrlSlider;
				private _count = 6 max floor (2 * pi * _radius / 15);
				private _intervals = 360 / _count;

				for "_i" from 0 to (_count - 1) do {
					private _circumferencePos = _i * _intervals;
					drawIcon3D ["\a3\ui_f\data\map\markers\military\dot_ca.paa", _color, [_radius * cos _circumferencePos + (_center # 0),_radius * sin _circumferencePos + (_center # 1),0], 0.5, 0.5, 0];
				};
			},[_slider,_radiusCenter,_radiusColor]] call BIS_fnc_addStackedEventHandler;
		};

		_slider sliderSetRange [_min, _max];
		_slider sliderSetSpeed [1, 1];
		_slider sliderSetPosition _defaultValue;
		if(_isPercent) then {
			private _text = (str (round (_defaultValue * 100))) + "%";
			_sliderEdit ctrlSetText _text;
		} else {
			_sliderEdit ctrlSetText (str _defaultValue);
		};

		_slider ctrlAddEventHandler ["sliderPosChanged", {
			params ["_ctrlSlider", "_value"];
			private _controlGroup = ctrlParentControlsGroup _ctrlSlider;
			private _isPercent = _controlGroup getVariable ["M9SD_isPercent",false];
			private _ctrlEdit = _controlGroup controlsGroupCtrl IDC_ROW_EDIT;
			if(_isPercent) then {
				private _text = (str (round (_value * 100))) + "%";
				_ctrlEdit ctrlSetText _text;
			} else {
				private _roundedValue = round _value;
				_ctrlEdit ctrlSetText format ["%1",_roundedValue];
			};
		}];

		_sliderEdit ctrlAddEventHandler ["keyUp",{
			params ["_displayOrControl", "_key", "_shift", "_ctrl", "_alt"];
			private _num = parseNumber (ctrlText _displayOrControl);
			private _ctrlGroup = ctrlParentControlsGroup _displayOrControl;
			private _isPercent = _ctrlGroup getVariable ["M9SD_isPercent",false];
			private _sliderCtrl = _ctrlGroup controlsGroupCtrl IDC_ROW_SLIDER;
			if(_isPercent) then {
				_sliderCtrl sliderSetPosition (_num/100);
			} else {
				_sliderCtrl sliderSetPosition _num;
			};
		}];

		_rowControlGroup setVariable ["controlValue",{
			params ["_controlsGroup"];
			sliderPosition (_controlsGroup controlsGroupCtrl IDC_ROW_SLIDER)
		}];

		_rowControlGroup
	};

	M9SD_fnc_createToolBoxRow = {
		params ["_display","_defaultValue","_settings", '_ctrlVarname'];
		_settings params ["_strings"];
		private _rowControlGroup = [_display] call M9SD_fnc_createRowBase;

		private _ctrlToolbox = _display ctrlCreate ["RscToolBox",IDC_ROW_TOOLBOX,_rowControlGroup];
		_display setVariable [_ctrlVarname, _ctrlToolbox];
		_ctrlToolbox ctrlSetPosition [(["W",10.1] call M9SD_fnc_convertToGUI_GRIDFormat),0,(["W",15.9] call M9SD_fnc_convertToGUI_GRIDFormat),(["H",1] call M9SD_fnc_convertToGUI_GRIDFormat)];
		_ctrlToolbox ctrlSetTextColor [1,1,1,1];
		_ctrlToolbox ctrlSetBackgroundColor [0,0,0,0.3];
		_ctrlToolbox ctrlCommit 0;
		lbClear _ctrlToolbox;
		
		{
			_x params ["_text","_tooltip"];

			private _index = _ctrlToolbox lbAdd _text;
			_ctrlToolbox lbSetTooltip [_index, _tooltip];
		} forEach _strings;

		if(_defaultValue isEqualType false) then {
			_defaultValue = parseNumber _defaultValue;
		};
		_ctrlToolbox lbSetCurSel _defaultValue;

		_rowControlGroup setVariable ["controlValue", {
			params ["_controlsGroup", "_settings"];

			private _value = lbCurSel (_controlsGroup controlsGroupCtrl IDC_ROW_TOOLBOX);
			_value = _value > 0;

			_value
		}];
		
		_rowControlGroup
	};

	M9SD_fnc_createVectorRow = {
		params ["_display","_defaultValue","_settings"];
		_settings params ["_labelData","_numOfEdits"];
		_labelData params ["_labels","_labelColors"];
		private _rowControlGroup = [_display] call M9SD_fnc_createRowBase;

		private ["_width","_gap"];
		if(_numOfEdits > 3) then {
			_numOfEdits = 3;
		};
		if(_numOfEdits < 2) then {
			_numOfEdits = 2;
		};
		switch (_numOfEdits) do {
			case 2: {
				_width = 6.5;
				_gap = 0.2;
			};
			case 3: {
				_width = 4.5;
				_gap = 0.2;
			};
		};

		for "_i" from 0 to (_numOfEdits - 1) do {
			
			private _widthPosLabel = (_i * _width) + ((_i + 1) * (_gap * 3)) + 10;
			private _widthPos = _widthPosLabel + 1.2;
			_widthPos = ["W",_widthPos] call M9SD_fnc_convertToGUI_GRIDFormat;
			_widthPosLabel = ["W",_widthPosLabel] call M9SD_fnc_convertToGUI_GRIDFormat;

			private _editLabel = _display ctrlCreate ["RscStructuredText",-1,_rowControlGroup];
			_editLabel ctrlSetStructuredText parseText (format ["<t align='center'>%1</t>",_labels select _i]);
			_editLabel ctrlSetBackgroundColor (_labelColors select _i);
			_editLabel ctrlSetPosition [_widthPosLabel,0,["W",1] call M9SD_fnc_convertToGUI_GRIDFormat,["H",1] call M9SD_fnc_convertToGUI_GRIDFormat];
			_editLabel ctrlCommit 0;

			private _editBox  = _display ctrlCreate ["RscEdit",IDCS_ROW_VECTOR select _i,_rowControlGroup];
			_editBox ctrlSetText (str (_defaultValue select _i));
			_editBox ctrlSetPosition [_widthPos,0,["W",_width - 1] call M9SD_fnc_convertToGUI_GRIDFormat,["H",1] call M9SD_fnc_convertToGUI_GRIDFormat];
			_editBox ctrlCommit 0;
		};

		_rowControlGroup ctrlSetPositionH (["H",1] call M9SD_fnc_convertToGUI_GRIDFormat);
		_rowControlGroup ctrlCommit 0;

		_rowControlGroup setVariable ["numOfVectorControls",_numOfEdits];

		_rowControlGroup setVariable ["controlValue", {
			params ["_controlsGroup", "_settings"];
			private _numOfEdits = _controlsGroup getVariable "numOfVectorControls";
			private _value = [];
			for "_i" from 0 to (_numOfEdits - 1) do {
				private _editBox = _controlsGroup controlsGroupCtrl (IDCS_ROW_VECTOR select _i);
				_value pushBack (parseNumber (ctrlText _editBox));
			};

			_value
		}];
		
		_rowControlGroup
	};

	M9SD_fnc_changeDisplayHeights = {
		params ["_display"];
		private _ctrlContent = _display displayCtrl IDC_CONTENT;
		ctrlPosition _ctrlContent params ["_posX","","_posW","_posH"];

		_ctrlContent ctrlSetPositionY (0.5 - (_posH / 2));
		_ctrlContent ctrlCommit 0;

		private _ctrlTitle = _display displayCtrl IDC_TITLE;
		_ctrlTitle ctrlSetPositionY (0.5 - (_posH / 2) - (["H",1.6] call M9SD_fnc_convertToGUI_GRIDFormat));
		_ctrlTitle ctrlCommit 0;

		private _ctrlBG = _display displayCtrl IDC_BACKGROUND;
		_ctrlBG ctrlSetPositionY (0.5 - (_posH / 2) - (["H",0.5] call M9SD_fnc_convertToGUI_GRIDFormat));
		_ctrlBG ctrlSetPositionH (_posH + (["H",1] call M9SD_fnc_convertToGUI_GRIDFormat));
		_ctrlBG ctrlCommit 0;

		private _ctrlOkBtn = _display displayCtrl IDC_CONFIRM;
		_ctrlOkBtn ctrlSetPositionY (0.5 + (_posH / 2) + (["H",0.6] call M9SD_fnc_convertToGUI_GRIDFormat));
		_ctrlOkBtn ctrlCommit 0;

		private _ctrlCancelBtn = _display displayCtrl IDC_CANCEL;
		_ctrlCancelBtn ctrlSetPositionY (0.5 + (_posH / 2) + (["H",0.6] call M9SD_fnc_convertToGUI_GRIDFormat));
		_ctrlCancelBtn ctrlCommit 0;
	};

	M9SD_fnc_configureDynamicDisplay = {
		params [
			["_title","",[""]],
			["_content",[],[[]]],
			["_onConfirm",{},[{}]],
			["_onCancel",{},[{}]],
			["_args",[]]
		];

		private _controlsData = [];
		{
			_x params [
				["_type","",[""]],
				["_name",[],["",[]]],
				["_value",[]],
				["_ctrlVarName", ""]
			];
			_name params [["_label","",[""]],["_toolTip","",[""]]];

			(toUpper _type splitString ":") params [["_type",""],["_subType",""]];

			private ["_defaultValue","_controlType","_settings"];

			switch (_type) do {
				case "COMBO": {
					_value params [["_values",[],[[]]],["_labels",[],[[]]],["_defaultIndex",0,[0]]];
					if(_values isEqualTo []) then {
						{
							_values pushBack _forEachIndex;
						} forEach _labels;
					};

					_defaultValue = _values param [_defaultIndex];
					_controlType = M9SD_fnc_createComboRow;

					private _entries = [];
					for "_i" from 0 to (count _values - 1) do {
						(_labels select _i) params [["_text","",[""]],["_tooltip","",[""]],["_picture","",[""]],["_textColor",[1,1,1,1],[[]],4]];
						_entries pushBack [_values select _i,_text,_tooltip,_picture,_textColor];
					};

					_settings = [_entries];
				};
				case "EDIT": {
					_value params [["_default",""],["_height",5,[0]]];
					if!(_default isEqualType "") then {
						_default = str _default;
					};

					_defaultValue = _default;

					_controlType = switch (_subType) do {
						case "MULTI": {
							M9SD_fnc_createEditMultiRow
						};
						case "CODE": {
							M9SD_fnc_createEditCodeRow
						};
						default {
							M9SD_fnc_createEditRow
						};
					};

					private _isMulti = _subType in ["MULTI","CODE"];
					_settings = [_height];
				};
				case "LIST": {
					_value params [["_values",[],[[]]],["_labels",[],[[]]],["_defaultIndex",0,[0]],["_height",6,[0]],["_sort",false,[false]]];

					if(_values isEqualTo []) then {
						{
							_values pushBack _forEachIndex;
						}forEach _labels;
					};

					_defaultValue = _values param [_defaultIndex];
					_controlType = M9SD_fnc_createListRow;

					private _entries = [];
					for "_i" from 0 to (count _values - 1) do {
						(_labels select _i) params [["_text","",[""]],["_tooltip","",[""]],["_picture","",[""]],["_textColor",[1,1,1,1],[[]],4]];
						_entries pushBack [_values select _i,_text,_tooltip,_picture,_textColor];
					};

					_settings = [_entries,_height];
				};
				case "SIDES": {
					_defaultValue = [_value] param [0,west,[west,[]]];
					_controlType = M9SD_fnc_createSidesRow;
				};
				case "SLIDER": {
					_value params [
						["_min",0,[0]],
						["_max",1,[0]],
						["_default",0,[0]],
						["_radiusCenter",objNull,[objNull,[]], 3],
						["_radiusColor",[1,1,1,0.7],[[]], 4],
						["_isPercent",false,[false]]
					];

					_defaultValue = _default;
					_controlType = M9SD_fnc_createSliderRow;

					private _drawRadius = _subType == "RADIUS" && {_radiusCenter isNotEqualTo objNull};
					if(_isPercent) then {
						_radiusCenter = objNull;
					};

					_settings = [_min,_max,_isPercent,_drawRadius,_radiusCenter,_radiusColor];
				};
				case "TOOLBOX": {
					_value params [["_default",0,[0,false]],["_strings",[],[[]]]];

					switch (_subType) do {
						case "YESNO": {
							_strings = [["NO",""],["YES",""]];
						};
						case "ENABLED": {
							_strings = [["DISABLE",""],["ENABLE",""]];
						};
					};

					_defaultValue = _default;
					_controlType = M9SD_fnc_createToolBoxRow;

					_settings = [_strings];
				};
				case "VECTOR": {
					_value params [
						["_default",[0,0,0],[[]]],
						["_labels",["X","Y","Z"],[[]]],
						["_numOfEdits",3,[3]]
					];
					private _labelData = [_labels,[[0.765,0.18,0.1,1],[0.575,0.815,0.22,1],[0.26,0.52,0.92,1]]];

					_defaultValue = _default;
					_controlType = M9SD_fnc_createVectorRow;

					_settings = [_labelData,_numOfEdits];
				};
			};
			_controlsData pushBack [_controlType,_label,_tooltip,_defaultValue,_settings, _ctrlVarName];
		} forEach _content;

		private _display = [[0.8,0.3,0.0,1]] call M9SD_fnc_initDynamicDisplay;
		_display setVariable ['M9SD_onAttribsCancel',_onCancel];
		_display setVariable ['M9SD_onAttribsConfirm',_onConfirm];

		if(isNull _display) exitWith {false};

		private _ctrlTitle = _display displayCtrl IDC_TITLE;
		_ctrlTitle ctrlSetText (toUpper _title);

		private _ctrlContent = _display displayCtrl IDC_CONTENT;
		private _contentPosY = 0;
		private _controls = [];

		{
			_x params ["_controlType","_label","_tooltip","_defaultValue","_settings", '_ctrlVarName'];

			private _controlsGroup = [_display,_defaultValue,_settings, _ctrlVarName] call _controlType;

			

			private _ctrlLabel = _controlsGroup controlsGroupCtrl IDC_ROW_LABEL;
			_ctrlLabel ctrlSetText (format ["%1",_label]);
			_ctrlLabel ctrlSetTooltip _tooltip;

			_controlsGroup ctrlSetPositionY _contentPosY;
			_controlsGroup ctrlCommit 0;

			_contentPosY = (_contentPosY + (ctrlPosition _controlsGroup select 3) + (["H",0.1] call M9SD_fnc_convertToGUI_GRIDFormat));

			_controls pushBack [_controlsGroup, _settings];
		} forEach _controlsData;

		_ctrlContent ctrlSetPositionH (_contentPosY - (["H",0.1] call M9SD_fnc_convertToGUI_GRIDFormat));
		_ctrlContent ctrlCommit 0;

		[_display] call M9SD_fnc_changeDisplayHeights;

		_display setVariable ["M9_dynamicDisplayData",[_controls,_onConfirm,_onCancel,_args]];
		_display;
	};

	M9SD_fnc_defineDialogIDCS = {
		IDC_TITLE = 201;
		IDC_BACKGROUND = 202;
		IDC_CONTENT = 203;
		IDC_CONFIRM = 204;
		IDC_CANCEL = 205;

		IDC_ROW_GROUP = 210;
		IDC_ROW_LABEL = 211;
		IDC_ROW_CHECKBOX = 212;
		IDC_ROW_COMBO = 213;
		IDC_ROW_EDIT = 214;
		IDC_ROW_SLIDER = 215;
		IDC_ROW_TOOLBOX = 216;
		IDC_ROW_SIDES = 217;
		IDC_ROW_VECTOR_X = 220;
		IDC_ROW_VECTOR_Y = 221;
		IDC_ROW_VECTOR_Z = 222;

		IDC_SIDES_BLUFOR = 250;
		IDC_SIDES_OPFOR = 251;
		IDC_SIDES_INDEPENDENT = 252;
		IDC_SIDES_CIVILIAN = 253;

		IDCS_ROW_VECTOR = [IDC_ROW_VECTOR_X,IDC_ROW_VECTOR_Y,IDC_ROW_VECTOR_Z];
	};
	[] call M9SD_fnc_defineDialogIDCS;



comment "Module Settings Menu";

	private _targetObjArray = curatorMouseOver;
	private _object = if (isNull findDisplay 49) then {objnull} else {cursorObject};
	_object = if (isNull _object) then {
		 if ((_targetObjArray isEqualTo []) or (_targetObjArray isEqualTo [''])) then {objNull} else {_targetObjArray select 1};
	} else {_object};
	comment "for testing:
		_object = cursorObject;
	";
	if (isNull _object) exitWith {systemChat "ERROR | No object! (Place the zeus module on top of an object’s 3D icon)";};
	if ((!(_object isKindOf 'man')) && (!(_object iskindof 'camanbase'))) exitWith {systemChat 'ERROR | Object must be human.';};

	if (False) then {
		_x params [
			["_type","",[""]],
			["_name",[],["",[]]],
			["_value",[]],
			["_ctrlVarName", ""]
		];
		_x params ["_controlType","_label","_tooltip","_defaultValue","_settings", '_ctrlVarName']
	};

	_unit = _object;
	if (_unit getVariable ['interrogateActionAdded', false]) exitWIth {systemChat 'An interrogation action has already been added to this unit!';};

	private _display = [
		"INTERROGATION MODULE | Customization",
		[
			[
				"TOOLBOX",
				["Interrogation Hints", "A hint that displays the name of the prisoner and interrogation status to the interrogator.\n(Required for PIP Cam)"],
				[
					profileNamespace getVariable ['M9_interrogationSetting_showHints', true], 
					[
						"Disable",
						"Enable"
					]
				],
				'M9_interrogationSetting_showHints_ctrl'
			],
			[
				"TOOLBOX",
				["Dynamic PIP Cam", "Live cinematic camera that changes angles when choosing different actions.\n(Requires interrogation hints)"],
				[
					profileNamespace getVariable ['M9_interrogationSetting_showPIP', true], 
					[
						"Disable",
						"Enable"
					]
				],
				'M9_interrogationSetting_showHints_ctrl'
			],
			[
				"TOOLBOX",
				["Surrender Unit", "Put the unit in a surrender animation (also stops the unit from moving/reacting) until someone starts the interrogation."],
				[
					profileNamespace getVariable ['M9_interrogationSetting_surrenderUnit', true], 
					[
						"Disable",
						"Enable"
					]
				],
				'M9_interrogationSetting_showHints_ctrl'
			],
			[
				"TOOLBOX",
				["Restrain Unit", "Put the unit in a restrained (sitting hostage) animation (also stops the unit from moving/reacting) until someone starts the interrogation."],
				[
					profileNamespace getVariable ['M9_interrogationSetting_restrainUnit', false], 
					[
						"Disable",
						"Enable"
					]
				],
				'M9_interrogationSetting_restrainUnit_ctrl'
			],
			[
				"TOOLBOX",
				["Use Intel Text", "Use the text inputted below as INTEL to be revealed to the player's side."],
				[
					profileNamespace getVariable ['M9_interrogationSetting_useIntelText', false], 
					[
						"Disable",
						"Enable"
					]
				],
				'M9_interrogationSetting_useIntelText_ctrl'
			],
			[
				"EDIT:MULTI",
				["INTEL", "Input intel that should be added when the interrogation ends (scripted success)."],
				[
					profileNamespace getVariable ['M9_interrogationSetting_intelText', selectRandom [
						"The blacksite is at grid ______.", 
						"My assignment is to ______.", 
						"I work for ______.", 
						"The " + selectRandom ["access", 'activation', 'deactivation', 'launch', 'terminal'] + selectRandom ['code is', 'codes are'] + " ______."
					]]
					
				],
				'M9_interrogationSetting_intelInputText_ctrl'
			]
		],{
			M9_interroGUIsettings = _THIS;
			params ["_values","_args","_display"];
			_args params [['_prisoner', objNull]];
			if (isNull _prisoner) exitWith {systemChat 'Error; No Prisoner.'};
			_values params [
				"_M9_interrogationSetting_showHints",
				"_M9_interrogationSetting_showPIP",
				"_M9_interrogationSetting_surrenderUnit", 
				'_M9_interrogationSetting_restrainUnit', 
				'_M9_interrogationSetting_useIntelText', 
				'_M9_interrogationSetting_intelText'
			];
			if (!_M9_interrogationSetting_showHints && _M9_interrogationSetting_showPIP) exitWith {
				systemChat 'Error; You must enable hints for PIP.'
			};
			if (_M9_interrogationSetting_surrenderUnit && _M9_interrogationSetting_restrainUnit) exitWith {
				systemChat 'Error; You cannot surrender and restrain, pick only one.'
			};
			private _intelText = ctrlText (_display getVariable ['M9_interrogationSetting_intelInputText_ctrl', controlNull]);
			_intelText = [_intelText] call M9SD_fnc_censorBlacklistedWords;
			if (count _intelText > 300) exitWith {
				playSound ['additemfailed', true];
				playSound ['additemfailed', false];
				systemChat "Message too long! Cannot send, max characters is 300.";
			};
			_M9_interrogationSetting_intelText = _intelText;

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
			
			if (isNull _prisoner) exitWIth {systemChat '(isNull _prisoner)';};
			systemChat 'Adding interrogation option to prisoner...';
			[_prisoner] call M9SD_fnc_moduleInterrogation_composition;
			_display closeDisplay 1;
		},{
			params ["_values","_args","_display"];
			_display closeDisplay 2;
		},
		[_object]
	] call M9SD_fnc_configureDynamicDisplay;

	_M9_interrogationSetting_showHints_ctrl = _display getVariable ['M9_interrogationSetting_showHints_ctrl', controlNull];

	showChat true;

comment "
A3_InterroGationExeCutionModUle

Arma 3 Steam Workshop
https://steamcommunity.com/sharedfiles/filedetails/?id=3041863730

MIT License
Copyright (c) 2023 M9-SD
https://github.com/M9-SD/A3_InterroGationExeCutionModUle/blob/main/LICENSE
";