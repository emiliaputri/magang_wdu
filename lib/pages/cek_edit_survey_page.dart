import 'package:flutter/material.dart';
import '../service/dummy_survey.dart';
import '../models/survey_question.dart';

class CekEditSurveyPage extends StatefulWidget {
  final String surveyId;
  final String clientSlug;
  final String projectSlug;

  const CekEditSurveyPage({
    super.key,
    required this.surveyId,
    required this.clientSlug,
    required this.projectSlug,
  });

  @override
  State<CekEditSurveyPage> createState() => _CekEditSurveyPageState();
}

class _CekEditSurveyPageState extends State<CekEditSurveyPage> {

  Map<String, dynamic> answers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cek / Edit Survey"),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: dummySurvey.length,
        itemBuilder: (context, index) {

          SurveyQuestion q = dummySurvey[index];

          if (q.type == "radio") {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(q.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),

                ...q.options.map((opt) {
                  return RadioListTile(
                    value: opt,
                    groupValue: answers[q.id],
                    onChanged: (val) {
                      setState(() {
                        answers[q.id] = val;
                      });
                    },
                    title: Text(opt),
                  );
                }).toList(),

                const SizedBox(height: 20),
              ],
            );
          }

          if (q.type == "dropdown") {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(q.title),

                const SizedBox(height: 6),

                DropdownButtonFormField(
                  value: answers[q.id],
                  items: q.options
                      .map((opt) => DropdownMenuItem(
                            value: opt,
                            child: Text(opt),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      answers[q.id] = val;
                    });
                  },
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                ),

                const SizedBox(height: 20),
              ],
            );
          }

          if (q.type == "checkbox") {

            answers[q.id] ??= [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(q.title),

                ...q.options.map((opt) {
                  return CheckboxListTile(
                    value: answers[q.id].contains(opt),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          answers[q.id].add(opt);
                        } else {
                          answers[q.id].remove(opt);
                        }
                      });
                    },
                    title: Text(opt),
                  );
                }).toList(),

                const SizedBox(height: 20),
              ],
            );
          }

          return const SizedBox();
        },
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: () {

            print(answers);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Survey disimpan")),
            );
          },
          child: const Text("Submit Survey"),
        ),
      ),
    );
  }
}