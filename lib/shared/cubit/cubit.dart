import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';
import 'package:todo/modules/archived_tasks/archived_tasks.dart';
import 'package:todo/modules/done_tasks/done_tasks.dart';
import 'package:todo/modules/new_tasks/new_tasks.dart';
import 'package:todo/shared/cubit/states.dart';

class AppCubit extends Cubit<AppStates>{
  AppCubit() : super(AppInitialState());

  static AppCubit get(context) => BlocProvider.of(context);

  int currentIndex = 0;
  late Database database;

  List<Map> newTasks = [];
  List<Map> doneTasks = [];
  List<Map> archivedTasks = [];


  List<Widget> screens = [
    const NewTasksScreen(),
    const DoneTasksScreen(),
    const ArchivedTasksScreen(),
  ];
  List<String> titles = [
    'New Tasks',
    'Done Tasks',
    'Archived Tasks',
  ];

  void changeIndex (int index) {
    currentIndex = index;
    emit(AppChangeBottomNavBarState());
  }

  void createDatabase()  {
     openDatabase(
         'todo.db',
         version: 1,
        onCreate: (database, version) {
          // ignore: avoid_print
           print('database created');
          database
              .execute(
              'CREATE TABLE tasks(id INTEGER PRIMARY KEY, title TEXT, date TEXT, time TEXT, status TEXT)')
              .then((value) {
            // ignore: avoid_print
            print('table created');
          }).catchError((error) {
            // ignore: avoid_print
            print('error when table creating table ${error.toString()}');
          });
          // ignore: avoid_print
          print('database created');
        },
         onOpen: (database) {
          getDataFromDatabase(database);
          // ignore: avoid_print
          print('database opened');
        }).then((value) {
          database = value;
          emit(AppCreateDatabaseState());
    });
  }

   Future insertDatabase({
    required String title,
    required String time,
    required String date,
  }) async {
     await database.transaction((txn) {
      return txn
          .rawInsert(
          'INSERT INTO tasks(title, date, time, status) VALUES("$title","$date","$time","new")')
          .then((value) {
        // ignore: avoid_print
        print('$value inserted successfully');
        emit(AppInsertDatabaseState());

        getDataFromDatabase(database);
      }).catchError((error) {
        // ignore: avoid_print
        print('error when inserting New Record ${error.toString()}');
      });
    });
  }

  void getDataFromDatabase(database)  {
    // علشان وانا ببدأ يصفر
    newTasks = [];
    doneTasks = [];
    archivedTasks = [];

    emit(AppGetDatabaseLoadingState());
     database.rawQuery('SELECT * FROM tasks').then((value) {

       value.forEach((element){
         if(element['status'] == 'new') {
           newTasks.add(element);
         }else if(element['status'] == 'done'){
           doneTasks.add(element);
         }else {
           archivedTasks.add(element);
         }
       });
       emit(AppGetDatabaseState());
     });
  }

  void updateData ({
    required String status,
    required int id,
    }) async
    {
      database.rawUpdate(
        'UPDATE tasks SET status = ? WHERE id = ?',
        [status, id],
        ).then((value) {
        getDataFromDatabase(database);
        emit(AppUpdateDatabaseState());
          });
      }

   void deleteData({
      required int id
    }) async {
     database.rawDelete('DELETE FROM tasks WHERE id = ?', [id]).then((value) {
       getDataFromDatabase(database);
       emit(AppDeleteDatabaseState());
     });
   }

  bool isBottomSheetShown = false;
  IconData fabIcon = Icons.edit;

  void changeBottomSheetState({
    required bool isShow,
    required IconData icon,
    }){
      isBottomSheetShown = isShow;
      fabIcon = icon;
      emit(AppChangeBottomSheetBarState());
    }
  }