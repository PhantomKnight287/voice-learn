import 'dart:convert';

import 'package:app/components/input.dart';
import 'package:app/constants/main.dart';
import 'package:app/utils/error.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:toastification/toastification.dart';

class ReportScreen extends StatefulWidget {
  final String questionId;
  const ReportScreen({
    super.key,
    required this.questionId,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  void _report() async {
    if (_formKey.currentState?.validate() == false) return;
    setState(() {
      _loading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final req = await http.post(
      Uri.parse(
        "$API_URL/reports/question/${widget.questionId}",
      ),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(
        {
          "title": _titleController.text,
          "content": _descriptionController.text,
        },
      ),
    );
    final body = jsonDecode(req.body);
    setState(() {
      _loading = false;
    });
    if (req.statusCode != 201) {
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        title: const Text("An Error Occurred"),
        description: Text(
          ApiResponseHelper.getErrorMessage(body),
        ),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
      return;
    } else {
      toastification.show(
        type: ToastificationType.success,
        style: ToastificationStyle.minimal,
        autoCloseDuration: const Duration(seconds: 5),
        title: const Text("Question Reported"),
        description: const Text("Please keep an eye on in app reports page for updates."),
        alignment: Alignment.topCenter,
        showProgressBar: false,
      );
      _titleController.text = "";
      _descriptionController.text = "";
      return;
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
        bottom: BOTTOM,
        title: Text("Report"),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(
            BASE_MARGIN * 4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Form(
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
                      hintText: "Enter a concise title for your report",
                      keyboardType: TextInputType.emailAddress,
                      controller: _titleController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter title of your report.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height: BASE_MARGIN * 6,
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
                      hintText: "Explain your issue in detail like what you expected to happen and what happened.",
                      keyboardType: TextInputType.emailAddress,
                      minLines: 5,
                      controller: _descriptionController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter description of your report';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _report,
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
                    ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CupertinoActivityIndicator(
                          color: Colors.black,
                          animating: true,
                        ),
                      )
                    : Text(
                        "Report",
                        style: TextStyle(
                          fontSize: Theme.of(context).textTheme.titleSmall!.fontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
