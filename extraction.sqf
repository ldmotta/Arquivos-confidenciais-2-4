//////////////////////////////////////////////////////////////////
// Function file for Arma 3
// Created by: M0TT4: M0TT4
//////////////////////////////////////////////////////////////////
_resquePos = (_this select 0);

sleep 1;

// Cria área de pouso na posição do player (Land_HelipadCivil_F, Land_HelipadEmpty_F)
// _pad = "Land_HelipadEmpty_F" createVehicle (position player);
      
Hint "Resgate a caminho, dirija-se para a pista principal.";
_wp0_1 = group chopper1 addWaypoint [getpos _resquePos, 10];
_wp0_1 setWaypointType "MOVE";
_wp0_1 setWaypointStatements ["true", "dostop chopper1; chopper1 land 'Get in';"];
sleep 6;
_wp0_2 = group chopper2 addWaypoint [getpos _resquePos, 10];  
_wp0_2 setWaypointType "MOVE";
_wp0_2 setWaypointStatements ["true", "dostop chopper2; chopper2 land 'Get in';"];

// Aguardar até que todas as unidades vivas tenham embarcado
// waituntil {sleep 0.1;({_x in chopper1} count _this)+({_x in chopper2} count _this)==({alive _x} count _this)};
waituntil {sleep 0.1;({_x in chopper1} count list _resquePos)+({_x in chopper2} count list _resquePos)==({alive _x} count list _resquePos)};

extracted=1;
publicVariable "extracted";
// Cria waypoint na base para que os helicóptero 1 retorne e finalize a missão
_wp1_1 = group chopper1 addWaypoint [getpos base, 50];
_wp1_1 setWaypointType "MOVE";
_wp2_1 setWaypointScript "endMission 'END1'";

// Cria waypoint na base para que os helicóptero 2 retorne e finalize a missão
_wp1_2 = group chopper2 addWaypoint [getpos base, 50];
_wp1_2 setWaypointType "MOVE";
_wp2_2 setWaypointScript "endMission 'END1'";

// Cria waypont para desembarque das unidades no chopper1
_wp2_1 = group chopper1 addWaypoint [getpos base, 50];
_wp2_1 setWaypointType "TR UNLOAD";

// Cria waypont para desembarque das unidades no chopper2
_wp2_2 = group chopper2 addWaypoint [getpos base, 50];
_wp2_2 setWaypointType "TR UNLOAD";

// Não permite danos nos helicópteros 1 e 2
_wp2_1 setWaypointStatements ["true", "chopper1 land 'land';chopper1 setdamage 0"];
_wp2_2 setWaypointStatements ["true", "chopper2 land 'land';chopper2 setdamage 0"];



/*
waitUntil{(unitReady (driver _vehicle))}; // don't do this!
_vehicleReady = {
     private ["_veh", "_ready"];
     _veh = _this;
     _ready = true;
     {
        if (!(isNull _x)) then
        {
           _ready = _ready && (unitReady _x);
        };
     } forEach [
        (commander _veh),
        (gunner _veh),
        (driver _veh)
     ];
     _ready
  };
  */