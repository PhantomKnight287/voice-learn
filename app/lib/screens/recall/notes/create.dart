import 'dart:convert';

import 'package:app/components/input.dart';
import 'package:app/constants/main.dart';
import 'package:app/main.dart';
import 'package:app/utils/error.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:toastification/toastification.dart';

class CreateNoteScreen extends StatefulWidget {
  final String? title;
  final String? description;
  const CreateNoteScreen({
    super.key,
    this.description,
    this.title,
  });

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<List<dynamic>> _fetchStacks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final uri = Uri.parse("$API_URL/recalls/stacks/all");
    logger.d("Requesting ${uri.toString()}");
    final req = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
      },
    );
    final body = jsonDecode(req.body);
    if (req.statusCode != 200) {
      final message = ApiResponseHelper.getErrorMessage(body);
      logger.e("Failed to fetch all stacks: $message");
      throw message;
    }
    logger.d("Loaded ${body.length} stacks for dropdown");
    return (body as List);
  }

  String _stackId = "";

  bool _loading = false;

  Future<void> _createNote() async {
    if (_loading) return;
    if (_stackId.isEmpty) {
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        title: const Text("An Error Occurred"),
        description: Text("Please select a stack"),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
      return;
    }
    if (_formKey.currentState!.validate() == false) return;
    setState(() {
      _loading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final uri = Uri.parse(
      "$API_URL/recalls/$_stackId/notes",
    );
    logger.d("Requesting ${uri.toString()}");
    final req = await http.post(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(
        {
          "title": _titleController.text,
          "description": _descriptionController.text,
        },
      ),
    );
    final body = jsonDecode(req.body);
    setState(() {
      _loading = false;
    });
    if (req.statusCode != 201) {
      final message = ApiResponseHelper.getErrorMessage(body);
      logger.e("Failed to create note: $message");
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        title: const Text("An Error Occurred"),
        description: Text(message),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
      return;
    }
    logger.i("Created Note with id: ${body['id']}");
    setState(() {
      _loading = false;
    });
    toastification.show(
      type: ToastificationType.success,
      style: ToastificationStyle.minimal,
      autoCloseDuration: const Duration(seconds: 5),
      title: const Text("Note Created"),
      alignment: Alignment.topCenter,
      showProgressBar: false,
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.title != null) {
      _titleController.text = widget.title!;
    }
    if (widget.description != null) {
      _descriptionController.text = widget.description!;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Create Note",
        ),
        centerTitle: true,
        bottom: BOTTOM,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(BASE_MARGIN * 3),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Title",
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(
                    height: BASE_MARGIN * 2,
                  ),
                  InputField(
                    hintText: "KrankenWagen",
                    keyboardType: TextInputType.text,
                    controller: _titleController,
                    minLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter title of your note.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: BASE_MARGIN * 3,
                  ),
                  Center(
                    child: IconButton(
                      onPressed: () {
                        final title = _titleController.text;
                        _titleController.text = _descriptionController.text;
                        _descriptionController.text = title;
                      },
                      icon: const HeroIcon(
                        HeroIcons.arrowsUpDown,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: BASE_MARGIN * 3,
                  ),
                  Text(
                    "Description",
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(
                    height: BASE_MARGIN * 2,
                  ),
                  InputField(
                    hintMaxLines: 3,
                    hintText: "Ambulance",
                    keyboardType: TextInputType.text,
                    minLines: 5,
                    controller: _descriptionController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter description of your note.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: BASE_MARGIN * 6,
                  ),
                  Text(
                    "Stack",
                    style: TextStyle(
                      fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(
                    height: BASE_MARGIN * 2,
                  ),
                  QueryBuilder(
                    "all_stacks",
                    _fetchStacks,
                    builder: (context, query) {
                      if (query.isLoading) return const CupertinoActivityIndicator();
                      if (query.hasError) return Text(query.error.toString());
                      final data = query.data;
                      if (data == null || data.isEmpty) return Container();
                      return DropdownButtonFormField(
                        hint: Center(
                          child: Text(
                            "Select a stack",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleSmall?.fontSize,
                            ),
                          ),
                        ),
                        decoration: InputDecoration(
                          hintText: "Select a stack",
                          contentPadding: const EdgeInsets.all(8.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide.none,
                          ),
                          prefixIconColor: Colors.black,
                          filled: true,
                          hintStyle: TextStyle(
                            fontSize: Theme.of(context).textTheme.titleSmall?.fontSize,
                          ),
                          errorStyle: TextStyle(
                            color: Colors.red,
                            fontSize: Theme.of(context).textTheme.titleSmall?.fontSize,
                          ),
                        ),
                        items: data
                            .map(
                              (item) => DropdownMenuItem(
                                value: item['id'],
                                child: Text(
                                  item['name'],
                                  style: TextStyle(
                                    fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _stackId = value as String;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || (value as String).isEmpty) {
                            return 'Please select a stack.';
                          }
                          return null;
                        },
                      );
                    },
                    refreshConfig: RefreshConfig.withDefaults(
                      context,
                      refreshOnMount: true,
                      refreshInterval: const Duration(
                        minutes: 1,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: BASE_MARGIN * 4,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await _createNote();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    style: ButtonStyle(
                      alignment: Alignment.center,
                      foregroundColor: WidgetStateProperty.all(Colors.black),
                      padding: WidgetStateProperty.resolveWith<EdgeInsetsGeometry>(
                        (Set<WidgetState> states) {
                          return const EdgeInsets.all(15);
                        },
                      ),
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    child: _loading
                        ? Center(
                            child: CupertinoActivityIndicator(),
                          )
                        : Text(
                            "Create",
                            style: TextStyle(
                              fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
