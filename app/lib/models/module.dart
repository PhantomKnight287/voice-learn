import 'package:app/models/lesson.dart';

class Module {
  final String id;
  final String name;
  final String description;
  List<Lesson> lessons = [];

  Module({
    required this.id,
    required this.name,
    required this.description,
    required this.lessons,
  });
  factory Module.fromJSON(Map<String, dynamic> json) {
    var lessonsFromJson = json['lessons'] as List;
    List<Lesson> lessonList = lessonsFromJson.map((lessonJson) => Lesson.fromJSON(lessonJson)).toList();

    return Module(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      lessons: lessonList,
    );
  }
}
