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
  string Class;
  string discipline;
};

	
tuple Preference {
	string teacher;
	string discipline;
	string Class;
	int weight;
	{int} hours;	
};

//Oferta
tuple Requirement {
   string Class;            // curriculo
   string discipline;       // disciplina
   int    Duration;         // quantas aulas no dia
   int    repetition;       // quantidade de dias necessarios
   int    capacity;			// capacidade da turma
};

// Dados de entrada

{string} MorningClass =...;				 //curriculos de disciplinas lecionadas pela manha
{string} AfternoonClass = ...;         	 //curriculos de disciplinas lecionadas pela tarde
{string} NoonClass = ...;				 //curriculos de disciplinas lecionadas pela noite

{Preference} TeacherPreference = ...;    // preferencias do professor em lecionar a disciplina de um curriculo
{RoomBook} DedicatedRoomSet = ...;        // salas reservadas para disciplinas
{Requirement} RequirementSet = ...;      // Oferta das disciplinas
{RoomCapacity} Room = ...;               // salas disponiveis

{string} Class; 						 //Todos os curriculos
{string} Teacher; 						 //Todos os professores
{string} Discipline;					 //Todas as disciplinas 

// Dias e Horarios
int DayDuration = 8;                   // duracao total de um dia
int WorkDays =  5;          		   // dias uteis da semana
int HalfDayDuration = 3;			   // horarios até o meio dia
int MaxTime = DayDuration*WorkDays;    // numero total de horarios de uma semana
range Time = 0..MaxTime-1;             // conjunto dos horarios da semana


//Matriz booleana: retorna 1 se a sala comporta a disciplina, 0 caso contrário 
int PossibleRoom[d in Discipline, x in Room ] = 
  //Restrição de Adequação de Salas (RESERVAS DE SALAS)
  // 1 se a sala tiver reserva para disciplina, 0 caso contrario	 
  <x.room,d> in DedicatedRoomSet 
  || 0 == card({<z,k> | z in Room, k in Discipline : (<x.room,k> in DedicatedRoomSet) 
  || (<z.room,d> in DedicatedRoomSet)}) 
  
  //Restricao de capacidade de Salas
  // 1 se a capacidade da turma for menor igual a capacidade da sala
  && 1==card({ <d,q> | <c,d,u,n,q> in RequirementSet : q <= x.capacity });
                
range RoomId = 0..card(Room)-1;
{int} PossibleRoomIds[d in Discipline] = 
  {i | i in RoomId, z in Room : (PossibleRoom[d,z] == 1) && (i == ord(Room,z)) };

//dado um curriculo e uma disciplina, retorna o mais valor de preferencia associado a um professor
int preferWeight[class in Class, discipline in Discipline];

range TeacherId = 0..card(Teacher)-1;

{TeacherSkill} PossibleTeacherClass[teacher in Teacher];

{int} PossibleTeacherIDS[c in Class ,d in Discipline] = {i | i in TeacherId , t in Teacher, tp in TeacherPreference 
	: i == ord(Teacher,t) && t == tp.teacher && c == tp.Class && d == tp.discipline && <c,d> in PossibleTeacherClass[t]};

//dado um professor, retorna a sua carga horaria
int ch[teacher in Teacher];
							
//dado um professor, retorna seus horarios de preferencia 
{int} teacherHours[t in Teacher , c in Class, d in Discipline];


execute PRE_PROCESS {
//pre processamento do conjunto Class
for(var r in RequirementSet){
		Class.add(r.Class);
}

//pre processamento dos conjuntos Teacher e Discipline
for(var t in TeacherPreference){
		Teacher.add(t.teacher);
		Discipline.add(t.discipline);
}
/*
//pre processamento da matriz PossibleRoom
for(var i in RequirementSet){
	for(var j in Room){	
		for(var k in DedicatedRoomSet){
		    //Restricao de Adequacao de Sala	
			if(i.discipline == k.discipline && j == k.room){
				PossibleRoom[i.discipline][j] = 1;					
			}
			//se nao for sala reservada, checar a capacidade
			else if(j.capacity >= i.capacity){
				PossibleRoom[i.discipline][j] = 1;						
			}						
			else{
				PossibleRoom[i.discipline][j] = 0;			
			}				
		}			
	}
}*/

//pre processamento da matriz preferWeight
for(var i in Class){
	for(var j in Discipline){
		var weight = 0;	
		preferWeight[i][j] = 0;
		
		for(var k in TeacherPreference){
			if(i == k.Class && j == k.discipline){
				if(k.weight > weight){
					weight = k.weight;											
					preferWeight[i][j] = weight;					
				}			
			}	
		}			
	}
}

//pre processamento da matriz PossibleTeacherClass
for(var i in Teacher){
	for(var j in TeacherPreference){	
		if(i == j.teacher && j.weight == preferWeight[j.Class][j.discipline]){
			PossibleTeacherClass[i].add(j.Class, j.discipline);
		}		
	}	
} 

//pre processamento da matriz carga horária
for(var i in Teacher){
	ch[i] = 0;	
	for(var j in TeacherPreference){	
		for(var k in RequirementSet){
			if(i == j.teacher && j.Class == k.Class && j.discipline == k.discipline) {			
				ch[i] = ch[i] + k.Duration*k.repetition*2;
													
			}				
		}	
	}
}	
	
// pre processamento da matriz de teacherHours
for(var k in Teacher){
 for(var i in Class){
	for(var j in Discipline){		
			for(var l in TeacherPreference){
				if(i == l.Class && j == l.discipline && k == l.teacher){
					teacherHours[k][i][j] = l.hours;						
												
				}						
			}		
		}	
	}	
}
	

}

										
// for a given requirement, an instance is one course occurrence
tuple Instance {
  string Class;
  string discipline;
  int    Duration;
  int    repetition;
  int    capacity; 
  int    id;
  int    requirementId;
};

{Instance} InstanceSet = { 
  <c,d,t,r,q,i,z> | <c,d,t,r,q> in RequirementSet
                , z in ord(RequirementSet,<c,d,t,r,q>) .. ord(RequirementSet,<c,d,t,r,q>)
                , i in 1..r
};

//
// decision variables
//

dvar int Start[InstanceSet] in Time;               // the course starting point
dvar int room[InstanceSet] in RoomId;              // the room in which the course is held
dvar int teacher[InstanceSet] in TeacherId;        // the teacher in charge of the course

dvar int End[InstanceSet] in Time;                      // the course end time
dvar int classTeacher[Class,Discipline] in TeacherId;   // teacher working once per time point

// maximizar a preferencia dos professores em lecionar uma disciplina de um curriculo
dexpr int objetivo = sum(i in RequirementSet) preferWeight[i.Class,i.discipline];

// search setup
//

execute {
   writeln("MaxTime = ", MaxTime);
   writeln("DayDuration = ", DayDuration);
   writeln("Teacher = ", Teacher);
   writeln("Discipline = ", Discipline);
   writeln("Class = ", Class);
   var f = cp.factory;
   var selectVar = f.selectSmallest(f.domainSize());
   var selectValue = f.selectRandomValue();
   var assignRoom = f.searchPhase(room, selectVar, selectValue);
   var assignTeacher = f.searchPhase(teacher, selectVar, selectValue);
   var assignStart = f.searchPhase(Start, selectVar, selectValue);
   cp.setSearchPhases(assignTeacher, assignStart, assignRoom);
   var p = cp.param;
   p.logPeriod = 10000;
   p.searchType = "DepthFirst";
   p.timeLimit = 30;
}


maximize objetivo;

subject to {
  
  //--------------------------------
  //PREFERENCIA DO PROFESSOR       	
    
   //garantir que a preferencia do professor pelo horario seja respeitada
   forall(r in InstanceSet, x in TeacherPreference)
     if(r.Class == x.Class && r.discipline == x.discipline) 
   		Start[r] in teacherHours[x.teacher][x.Class][x.discipline]; 
   
  //----------------------------------------------  
  //RESTRICAO DE DISPONIBILIDADE DO PROFESSOR
  
  //Garantir que o professor tenha uma ou nenhuma aula em determinado horário
  forall(r in InstanceSet, x in Teacher) {
    if(<r.discipline, r.Class> in PossibleTeacherClass[x])
      (sum(o in InstanceSet
                                : <r.discipline, r.Class> in PossibleTeacherClass[x])
        (Start[o] >= Start[r])
        *(Start[o] < End[r])
        *(teacher[o] == ord(Teacher,x))) < 2 ;
  }
 
   
  //garantir que o professor pode lecionar a disciplina daquele curriculo
  forall(r in InstanceSet) 
    teacher[r] in PossibleTeacherIDS[r.Class, r.discipline];    
    
  //garantir que o professor é sempre o mesmo para uma disciplina e um curriculo
  forall(c in Class, d in Discipline, r in InstanceSet 
         : r.Class == c && r.discipline == d) 
    teacher[r] == classTeacher[c, d];
        
	//Garantir que a carga horaria maxima do professor durante a semana seja respeitada
	forall(teacher in Teacher){
	  ch[teacher] < 18;	
	}  
	    
    
  //---------------------
     
  //RESTRICAO DE OCUPACAO DAS SALAS   
  
  //garantir que nao tenha duas ou mais aulas em uma mesma sala no mesmo horario
  forall(r in InstanceSet, x in Room) {
    if(PossibleRoom[r.discipline,x] == 1)
      (sum(o in InstanceSet : 1 == PossibleRoom[o.discipline,x])
        (Start[o] >= Start[r])
        *(Start[o] < End[r])
        *(room[o] == ord(Room,x))) < 2;            
  }
  
  //RESTRICAO DE CAPACIDADE DE SALAS
  // garantir que aquela sala suporta a turma
  forall(r in InstanceSet)
    room[r] in PossibleRoomIds[r.discipline];
    
 //Restrição de Estabilidade das salas   
 //garantir que as aulas acontecam na mesma sala sempre   
 forall(i,j in InstanceSet)
    if(i.Class == j.Class &&  i.discipline == j.discipline)
    	room[i] == room[j];
   
//-------------------    
    
  //RESTRICAO DE CONFLITO  
  
  //garantir uma unica aula de um curriculo em determinado horario
  forall(r in InstanceSet, x in Class) {
    if(r.Class == x)
      (sum(o in InstanceSet : o.Class == x) 
       (1 == (Start[o] >= Start[r])*(Start[o] < End[r]))) < 2;
  }  
  /*
  //garantir que determinada disciplina nao tenha mais de uma aula no mesmo dia 
  forall(ordered i,j in InstanceSet: i.discipline == j.discipline && i.Class == j.Class) 
    (Start[i] div DayDuration) != (Start[j] div DayDuration);

   
  //-------------------   
    
  // RESTRICOES DE AULA  
   forall(ordered i, j in InstanceSet, a,b in Discipline
         : i != j
         && i.Class == j.Class
         && ((i.discipline == a && j.discipline == b)
             || (i.discipline == b && j.discipline == a)))
             
    //aulas de uma mesma disciplina e curriculo devem estar alocadas em horarios diferentes
    ((Start[i] div DayDuration) != (Start[j] div DayDuration));*/
  
  //garantir que a aula acaba após iniciar
  forall(r in InstanceSet) {
    restricao1: End[r] == r.Duration + Start[r];       	
  }    
  
    //garantir que os cursos da manha iniciem e acabem pela manha
  forall(d in MorningClass, i in InstanceSet
         : i.Class == d) 
    (Start[i] % DayDuration) >= 0 && (Start[i] % DayDuration) < HalfDayDuration;
     
  
  //garantir que os cursos da tarde iniciem e acabem pela tarde
  forall(d in AfternoonClass, i in InstanceSet
         : i.Class == d)    
    (Start[i] % DayDuration) >= HalfDayDuration && (Start[i] % DayDuration) < 6;    

  //garantir que os cursos da noite iniciem e acabem pela noite 
  forall(d in NoonClass, i in InstanceSet
         : i.Class == d) 
    (Start[i] % DayDuration) >= 6 && (Start[i] % DayDuration) < DayDuration; 		
   
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

{Course} timetable[t in Time][c in Class] = {
  <p,d,r,i,n> 
  | d in Discipline
  , r in Room
  , x in InstanceSet
  , n in x.repetition..x.repetition
  , p in Teacher 
  , i in x.id..x.id
  : (t >= Start[x])
  && (t < End[x])
  && (x.Class == c)
  && (room[x] == ord(Room, r))
  && (ord(Teacher,p) == teacher[x])
  && (d == x.discipline) 
};
   
// force execution of postprocessing expressions
execute POST_PROCESS {

  timetable;
  for(var c in Class) {
	    writeln("Class ", c);
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
			                //x.id, "/", 
			                //x.repetition, "\t", 
			                x.teacher);			             
	      	}
	    if(activity == 0){
	        writeln("Free time");
	    }
	    }
	 writeln("---------------------------------------------");
	}
}