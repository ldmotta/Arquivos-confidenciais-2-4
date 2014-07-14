waitUntil { !isNil {player} };
waitUntil { player == player };

switch (side player) do 
{

    case WEST: // BLUFOR briefing goes here
    {
        player createDiaryRecord ["Diary", ["Ordem", "- Eliminar o bloqieo e dominar a cidade de Panagia<br />"+ 
                                            "- Sabotar a torre de comunicação para que não sejamos surpreendidos antes de localizar os documentos perdidos.<br />"+ 
                                            "- Libertar o informante e interrogá-lo para saber a localização dos arquivos secretos<br />"+ 
                                            "- Escoltar o informante para um local seguro onde ele será extraído em segurança para a base aliada.<br />"+ 
                                            "- Encontrar e recuperar arquivos secretos roubados."]];

        player createDiaryRecord ["Diary", ["Execução", "- Furar o bloqueio e dominar a cidade de Panagia para eliminar a possibilidade do transporte de material bélico pela rodovia principal.<br />"+ 
                                            "- Encontrar o informante que indicará a possível localização dos arquivos sercretos roubados.<br />"+ 
                                            "- Sabotar os geradores de energia e a torre de comunicação inimiga para dificultar a comunicação com a base principal.<br />"+ 
                                            "- Recuperar os arquivos secretos roubados.<br />"+
                                            "- Sair em segurança para o local de extração."]];

        player createDiaryRecord ["Diary", ["Situação", "Documentos secretos foram roubados da Base aérea aliada e levados pela coalizão comunista. Um espião "+ 
                                            "foi enviado para localizar estes arquivos mas infelizmente foi capturado pelas forças inimigas. "+ 
                                            "Temos razões para acreditar que o ele possui a localização exata destes documentos. Sabemos que "+ 
                                            "ele está sendo mantido como refém na cidade de Chalkeia sobre forte vigilância. Precisamos ter muito "+
                                            "cuidado para não sermos descobertos. Fotos aéreas revelaram um local fortemente protegido com infantaria "+ "e até blindados."]];
                                            
        player createDiaryRecord ["Diary", ["Resgatar documentos", "- Recuperar os documentos secretos que foram roubados da base aérea aliada."]];

        //Task1 - COMMENT
        /*
        task_1 = player createSimpleTask ["TASKNAME"]; 
        task_1 setSimpleTaskDescription ["TASK DESCRIPTION","Example Task","WHAT WILL BE DISPLAYED ON THE MAP"]; 
        task_1 setSimpleTaskDestination (getMarkerPos "task_1");
        task_1 setTaskState "Assigned"; 
        player setCurrentTask task_1;

        //Task2 - COMMENT
        task_2 = player createSimpleTask ["TASKNAME"]; 
        task_2 setSimpleTaskDescription ["TASK DESCRIPTION","Example Task","WHAT WILL BE DISPLAYED ON THE MAP"]; 
        task_2 setSimpleTaskDestination (getMarkerPos "task_2");
        */
    };


    case EAST: // OPFOR briefing goes here
    { 
    };


    case RESISTANCE: // RESISTANCE/INDEPENDENT briefing goes here
    { 
    };


    case CIVILIAN: // CIVILIAN briefing goes here
    { 
    };
};