using CP;

tuple RoomCapacity{
	string room;
	int capacity;
}

tuple RoomBook {
  string room;
  string discipline;
};

tuple TeacherSkill {
  string Curriculum;
  string discipline;
};

	
tuple Preference {
	string teacher;
	string discipline;
	string Curriculum;
	int weight1;
	{int} primaryHours;
	int weight2;
	{int} secundaryHours;	
};

//Oferta
tuple Requirement {
   string Curriculum;       		// curriculo
   string discipline;       		// disciplina   
   int    repetition;       		// quantidade de horarios necessarios
   int    capacity;					// capacidade da turma
};

// Dados de entrada
{string} MorningCurriculum =...;		//curriculos de disciplinas lecionadas pela manha
{string} AfternoonCurriculum = ...;     //curriculos de disciplinas lecionadas pela tarde
{string} NoonCurriculum = ...;			//curriculos de disciplinas lecionadas pela noite

{Preference} TeacherPreference = ...;   // preferencias do professor em lecionar a disciplina de um curriculo
{RoomBook} DedicatedRoomSet = ...;      // salas reservadas para disciplinas
{Requirement} RequirementSet = ...;     // Oferta das disciplinas
{RoomCapacity} Room = ...;              // salas disponiveis

{string} Curriculum; 				    // Conjunto dos curriculos
{string} Teacher; 						// Conjunto dos professores
{string} Discipline;					// Conjunto das disciplinas 

// Dias e Horarios
int DayDuration = 8;                    // duracao total de um dia
int WorkDays =  5;          		    // dias uteis da semana
int HalfDayDuration = 3;			    // horarios até o meio dia
int MaxTime = DayDuration*WorkDays;     // numero total de horarios de uma semana
range Time = 0..MaxTime-1;              // conjunto dos horarios da semana
range RoomId = 0..card(Room)-1;		    // enumeracao das salas	
range TeacherId = 0..card(Teacher)-1;   // enumeracao dos professores	

//Matriz de salas: retorna 1 se a sala comporta a disciplina, 0 caso contrário 
int PossibleRoom[d in Discipline, x in Room ] =
 
  //Restrição de Adequação de Salas (RESERVAS DE SALAS)
  // 1 se a sala tiver reserva para disciplina, 0 caso contrario	 
  <x.room,d> in DedicatedRoomSet 
  || 0 == card({<z,k> | z in Room, k in Discipline : (<x.room,k> in DedicatedRoomSet) 
  || (<z.room,d> in DedicatedRoomSet)}) 
  
  //Restricao de capacidade de Salas
  // 1 se a capacidade da turma for menor igual a capacidade da sala
  && 1==card({ <d,q> | <c,d,r,q> in RequirementSet : q <= x.capacity });
                
// matriz de enumeracao das salas
{int} PossibleRoomIds[d in Discipline] = 
  {i | i in RoomId, z in Room : (PossibleRoom[d,z] == 1) && (i == ord(Room,z)) };


//dado um professor, retorna as disciplinas que ele leciona
{TeacherSkill} PossibleTeacherClass[teacher in Teacher];
//matriz de enumeracao dos professores
{int} PossibleTeacherIDS[c in Curriculum ,d in Discipline] = {i | i in TeacherId , t in Teacher, tp in TeacherPreference 
	: i == ord(Teacher,t) && t == tp.teacher && c == tp.Curriculum && d == tp.discipline && <c,d> in PossibleTeacherClass[t]};


//Matriz de carga horaria, dado um professor
int ch[teacher in Teacher];

//Matriz de horarios de preferencia do professor
{int} teacherHours[t in Teacher , c in Curriculum, d in Discipline];

//matriz de pesos para cada horário
int weight[i in Curriculum, j in Time, k in Teacher];

execute PRE_PROCESS {

//pre processamento do conjunto Curriculum
for(var r in RequirementSet){
		Curriculum.add(r.Curriculum);
}

//pre processamento dos conjuntos Teacher e Discipline
for(var t in TeacherPreference){
		Teacher.add(t.teacher);
		Discipline.add(t.discipline);
}


//pre processamento da matriz PossibleTeacherClass
for(var i in Teacher){
	for(var j in TeacherPreference){	
		if(i == j.teacher){
			PossibleTeacherClass[i].add(j.Curriculum, j.discipline);
		}		
	}	
} 

//pre processamento da matriz carga horária
for(var i in Teacher){
	ch[i] = 0;	
	for(var j in TeacherPreference){	
		for(var k in RequirementSet){
			if(i == j.teacher && j.Curriculum == k.Curriculum && j.discipline == k.discipline) {			
				ch[i] = ch[i] + k.repetition*2;
													
			}				
		}	
	}
}	
	
// pre processamento da matriz de teacherHours
for(var k in Teacher){
 for(var i in Curriculum){
	for(var j in Discipline){
			for(var l in TeacherPreference){					
					if(i == l.Curriculum && j == l.discipline && k == l.teacher){
						for(var h in l.primaryHours){
							teacherHours[k][i][j].add(h);					
						}
						for(var h in l.secundaryHours){
							teacherHours[k][i][j].add(h);					
						}																											
					}				
  			}												
		}		
	}	
}

//pre processamento dos pesos
 for(var i in Curriculum){
 		for(var j in Time){ 		 		
 			for(var k in TeacherPreference){
 				for(var horarios in k.primaryHours){
 				 	if(i == k.Curriculum && horarios == j){
 				 		weight[i][j][k.teacher] = k.weight1;			
 					} 				
 				}
 				
 				for(var horarios2 in k.secundaryHours){
 				 	if(i == k.Curriculum && horarios2 == j){
 				 		weight[i][j][k.teacher] = k.weight2;			
 					} 				
 				} 				  						
 			} 			 		
 		} 	
 }  
 
//FIM PRE_PROCESS
}

							
tuple Instance {
  string Curriculum;
  string discipline; 
  int    repetition;
  int    capacity; 
  int    id;
  int    requirementId;
};

// Cnjunto de Alocação
{Instance} InstanceSet = { 
  <c,d,r,q,i,z> | <c,d,r,q> in RequirementSet
                , z in ord(RequirementSet,<c,d,r,q>) .. ord(RequirementSet,<c,d,r,q>)
                , i in 1..r                
};

//VARIAVEIS DE DECISAO

dvar int Start[InstanceSet] in Time;               			// Variavel de alocacao sobre o tempo
dvar int room[InstanceSet] in RoomId;              			// Variavel de alocacao no espaço
dvar int teacher[InstanceSet] in TeacherId;        			// Variavel de alocacao de recurso
dvar int classTeacher[Curriculum,Discipline] in TeacherId;  // teacher working once per time point

//FUNCAO OBJETIVO

// maximizar a preferencia dos professores em lecionar em determinado horario
dexpr int objetivo = sum(i in Curriculum, j in Time, l in InstanceSet: i == l.Curriculum, 
m in TeacherPreference : i == m.Curriculum && l.discipline == m.discipline) 
	weight[i][j][m.teacher] * ( Start[l] == j );

// SETUP DE BUSCA
//
execute {
   writeln("MaxTime = ", MaxTime);
   writeln("DayDuration = ", DayDuration);
   writeln("Teacher = ", Teacher);
   writeln("Discipline = ", Discipline);
   writeln("Curriculum = ", Curriculum);
   var f = cp.factory;
   var selectVar = f.selectSmallest(f.domainSize());
   var selectValue = f.selectRandomValue();
   var assignRoom = f.searchPhase(room, selectVar, selectValue);
   var assignTeacher = f.searchPhase(teacher, selectVar, selectValue);
   var assignStart = f.searchPhase(Start, selectVar, selectValue);
   cp.setSearchPhases(assignTeacher, assignStart, assignRoom);
   var p = cp.param;
   p.logPeriod = 100000;
   p.searchType = "DepthFirst";
   p.timeLimit = 240;
}


maximize objetivo;

subject to {
  
  //-------------------------------- ||
  //PREFERENCIA DO PROFESSOR       	
    
   //garantir que a preferencia do professor pelo horario seja respeitada
   
	forall(r in InstanceSet, x in TeacherPreference)
	  if(r.Curriculum == x.Curriculum && r.discipline == x.discipline)
	  	Start[r] in teacherHours[x.teacher][x.Curriculum][x.discipline];
	  
   
  //----------------------------------------------  
  //RESTRICAO DE DISPONIBILIDADE DO PROFESSOR
  
  
  //Garantir que o professor tenha uma ou nenhuma aula em determinado horário
  
  forall(r in InstanceSet, x in Teacher) {
    if(<r.discipline, r.Curriculum> in PossibleTeacherClass[x])
      (sum(o in InstanceSet
                                : <r.discipline, r.Curriculum> in PossibleTeacherClass[x] && r.id != o.id)
        (Start[o] != Start[r]) == 0) * (teacher[r] == ord(Teacher,x)) < 2 ;

  }
 
   
  //garantir que o professor pode lecionar a disciplina daquele curriculo
  forall(r in InstanceSet) 
    teacher[r] in PossibleTeacherIDS[r.Curriculum, r.discipline];    
    
  //garantir que o professor é sempre o mesmo para uma disciplina e um curriculo
  forall(c in Curriculum, d in Discipline, r in InstanceSet 
         : r.Curriculum == c && r.discipline == d) 
    teacher[r] == classTeacher[c, d];
        
	//Garantir que a carga horaria minima do professor durante a semana seja respeitada
	forall(teacher in Teacher){
	  ch[teacher] < 26;	
	}  
	    
    
  //---------------------
     
  //RESTRICAO DE OCUPACAO DAS SALAS   
  
  //garantir que nao tenha duas ou mais aulas em uma mesma sala no mesmo horario
  forall(r in InstanceSet, x in Room) {
    if(PossibleRoom[r.discipline,x] == 1)
      (sum(o in InstanceSet : 1 == PossibleRoom[o.discipline,x] && r.id != o.id)      	
        (Start[o] == Start[r]) *(room[o] == ord(Room,x))) < 2;                     
  }
  
  //RESTRICAO DE CAPACIDADE DE SALAS
  // garantir que aquela sala suporta a turma
  forall(r in InstanceSet)
    room[r] in PossibleRoomIds[r.discipline];
    
 //Restrição de Estabilidade das salas   
 //garantir que as aulas acontecam na mesma sala sempre   
 forall(i,j in InstanceSet)
    if(i.Curriculum == j.Curriculum &&  i.discipline == j.discipline)
    	room[i] == room[j];
     
    
  //RESTRICAO DE CONFLITO  E RESTRICOES DE AULA 
  
  //garantir uma unica aula de um curriculo em determinado horario
  forall(r in InstanceSet, x in Curriculum) {
    if(r.Curriculum == x)      
      (sum(o in InstanceSet : o.Curriculum == x)
      		(Start[r] == Start[o]) ) == 1; 
       //(1 == (Start[o] >= Start[r])*(Start[o] < End[r]))
       //) < 2;
  }  
    
  //garantir que os cursos da manha iniciem e acabem pela manha
  forall(d in MorningCurriculum, i in InstanceSet
         : i.Curriculum == d) 
    (Start[i] % DayDuration) >= 0 && (Start[i] % DayDuration) < HalfDayDuration;
       
  //garantir que os cursos da tarde iniciem e acabem pela tarde
  forall(d in AfternoonCurriculum, i in InstanceSet
         : i.Curriculum == d)    
    (Start[i] % DayDuration) >= HalfDayDuration && (Start[i] % DayDuration) < 6;    

  //garantir que os cursos da noite iniciem e acabem pela noite 
  forall(d in NoonCurriculum, i in InstanceSet
         : i.Curriculum == d) 
    (Start[i] % DayDuration) >= 5 && (Start[i] % DayDuration) < DayDuration; 
      
  //Restrição minima de dias: Garantir que as aulas ocorram com a quantidade especificada na oferta   
  forall(r in RequirementSet, i in InstanceSet)
     if(r.discipline == i.discipline && r.Curriculum == i.Curriculum)
     	i.id >= 1 && i.id  <= r.repetition;   
	
};

//
// generate time table
//
tuple Course {
   string teacher;
   string discipline;
   RoomCapacity room;
   int    id;
   int    repetition;
};

{Course} timetable[t in Time][c in Curriculum] = {
  <p,d,r,i,n> 
  | d in Discipline
  , r in Room
  , x in InstanceSet
  , n in x.repetition..x.repetition
  , p in Teacher 
  , i in x.id..x.id
  : (t == Start[x])
  && (x.Curriculum == c)
  && (room[x] == ord(Room, r))
  && (ord(Teacher,p) == teacher[x])
  && (d == x.discipline) 
};

execute POST_PROCESS {

  timetable;
  for(var c in Curriculum) {
	    writeln("Curriculum ", c);
	    var day = 0;
	    for(var t = 0; t < MaxTime; t++) {
	      if(t % DayDuration == 0) {
		        day++;
		        writeln();
			     if(day == 1){
			     	writeln("SEG");	     
			     }
			     else if(day == 2){
			     	writeln("TER");	     
			     }
			     else if(day == 3){
			     	writeln("QUA");	     
			     }
			     else if(day == 4){
			     	writeln("QUI");	     
			     }
			     else if(day == 5){
			     	writeln("SEX");	     
			     }  
	      	}
	      
	      if(t % DayDuration == HalfDayDuration) 
	        writeln("Almoço");
	      if(t % DayDuration == 6) 
	        writeln("Janta");
	        
	      var activity = 0;
	      for(var x in timetable[t][c]) {
		        activity++;
		        if(t % DayDuration+1 == 1){
		        	write("07-09", "\t");        
		        }
		        else if(t % DayDuration+1 == 2){
		        	write("09-11", "\t");        
		        } 
		        else if(t % DayDuration+1 == 3){
		        	write("11-13", "\t");        
		        }
		        else if(t % DayDuration+1 == 4){
		        	write("13-15", "\t");        
		        }
		        else if(t % DayDuration+1 == 5){
		        	write("15-17", "\t");        
		        }  
		        else if(t % DayDuration+1 == 6){
		        	write("17-19", "\t");        
		        }  
		        else if(t % DayDuration+1 == 7){
		        	write("19-21", "\t");        
		        }
		        else if(t % DayDuration+1 == 8){
		        	write("21-22", "\t");        
		        } 
		        if(activity != 0)       
			        writeln(x.room, "\t", 
			                x.discipline, "\t",			           
			                x.teacher);			             
	      	}
		    if(activity == 0){
		        writeln("Free time");
		    }
	    }
	 writeln("---------------------------------------------");
	}
}