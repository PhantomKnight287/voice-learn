import 'package:flutter/cupertino.dart';

class MoreModules extends StatefulWidget {
  final Function onMoreModulesFetch;
  const MoreModules({
    super.key,
    required this.onMoreModulesFetch,
  });

  @override
  State<MoreModules> createState() => _MoreModulesState();
}

class _MoreModulesState extends State<MoreModules> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
