/*********************************************
 * OPL 12.7.0.0 Model
 * Author: Dimitri
 * Creation Date: 07/02/2017 at 20:19:53
 *********************************************/

 using CP;
 
 execute{ 
	
}

tuple Pair {
  string a;
  string b;
};

tuple Pair1 {
  string a;
  {string} b;
};

tuple SalaCapacidade {
  string a;
  int b;
};

tuple Oferta {
	int semester;
	string Discipline;
	int numberOfStudents;
};

tuple Preferencia{
	string Teacher;
	string Discipline;
	int startHour;
	int firstDay;
};

int NumberOfDaysInWeek =...;
range days = 1.. NumberOfDaysInWeek;
int DayDuration = ...;
range hours = 1..DayDuration;

{SalaCapacidade} Room = ...;
int countRooms = card(Room);
range roomIdx = 1..countRooms;
{string} Discipline = ...;
int countDisciplines = card(Discipline);
range disciplineIdx = 1..countDisciplines;
{string} Teacher =...;
int countTeachers = card(Teacher);
range teacherIdx = 1..countTeachers;
{Pair1} TeacherSkills = ...;
{Preferencia} TeacherChoices = ...;
{Pair} DedicatedRoomSet = ...;
{Oferta} ClassesBySemester = ...;
int countClasses = card(ClassesBySemester); //contador de classes
range classIdx = 1..countClasses;




  
                 



