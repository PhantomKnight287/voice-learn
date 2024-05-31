import 'package:app/models/language.dart';
import 'package:app/models/module.dart';

enum PathType { created, generated }

class LearningPath {
  final String id;
  final Language language;
  final PathType pathType;
  final String? reason;
  final String? knowledge;
  List<Module> modules = [];

  LearningPath({
    required this.id,
    required this.language,
    required this.pathType,
    required this.reason,
    required this.knowledge,
    required this.modules,
  });

  factory LearningPath.fromJSON(Map<String, dynamic> json) {
    var modulesFromJSON = json['modules'] as List;
    List<Module> moduleList = modulesFromJSON.map((lessonJson) => Module.fromJSON(lessonJson)).toList();
    return LearningPath(
      id: json['id'],
      language: Language.fromJSON(json['language']),
      pathType: json['type'] == "generated" ? PathType.generated : PathType.created,
      reason: json['reason'],
      knowledge: json['knowledge'],
      modules: moduleList,
    );
  }
}
