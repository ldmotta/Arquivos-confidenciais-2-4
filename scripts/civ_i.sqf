// Script de interrogatório
_spy = _this select 0;
_spy playAction "gestureNod";

// Ativa a trigger por presença do bluefor
//trigger2 setTriggerActivation ["WEST", "PRESENT", true];
//trigger2 setTriggerStatements ["this"];

interrogado=1;
publicVariable "interrogado";

// Cria o civil com os documentos
_milGroup = createGroup civilian;    
_markerArray = ["spawn1", "spawn2", "spawn3", "spawn4"];
_spawnPos = _markerArray select (floor(random(count _markerArray)));    
"C_man_1" createUnit [ getMarkerPos _spawnPos, _milGroup, "this addAction ['Pegar documentos','scripts\civ_d.sqf',[false],1,false,true,'','(_target distance _this) < 3'];this disableAI 'MOVE';"];

// Indica local de captura dos documentos
_n = "Local dos documentos";
_m = createMarker [_n, getMarkerPos _spawnPos];
_m setMarkerType "mil_objective";
_m setMarkerText _n;
_m setMarkerColor 'ColorRed';

_spy enableAI "MOVE";
[_spy] join (group player);

sleep 2;
A3CN=[West,"HQ"]; A3CN SideChat "Que bom que você chegaram...";
sleep 2;
A3CN=[West,"HQ"]; A3CN SideChat "Veja no mapa onde devem procurar os documentos...";
sleep 2;
A3CN=[West,"HQ"]; A3CN SideChat "Eles estão com o Makarov, vocês precisam se apressar.";