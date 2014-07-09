// Script para recuperação de documentos
_thief = _this select 0;
_thief playAction "Surrender";

// Ativa a trigger por presença do bluefor
//trigger3 setTriggerActivation ["WEST", "PRESENT", true];
//trigger3 setTriggerStatements ["this"];

recuperado=1;
publicVariable "recuperado";

// Marca o local do ponto de extração
_n = "Ponto de extração";
_position = position trigger4;
_m = createMarker [_n, _position];
_m setMarkerType "mil_pickup";
_m setMarkerText _n;
_m setMarkerColor 'ColorRed';

sleep 2;
A3CN=[West,"HQ"]; A3CN SideChat "Nunca sairão daqui com vida...";
sleep 2;
A3CN=[West,"HQ"]; A3CN SideChat "O alerme foi disparado, e as nossas tropas estão a caminho.";
sleep 1;
A3CN=[West,"HQ"]; A3CN SideChat "Dirija-se para o ponto de resgate o mais rápido possível.";

