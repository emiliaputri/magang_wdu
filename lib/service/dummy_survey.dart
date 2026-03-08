import '../models/survey_question.dart';

List<SurveyQuestion> dummySurvey = [

  SurveyQuestion(
    id: "q1",
    title: "showing if choosing b",
    type: "radio",
    options: ["a", "b"],
  ),

  SurveyQuestion(
    id: "q2",
    title: "cinta",
    type: "dropdown",
    options: ["Option 1", "Option 2"],
  ),

  SurveyQuestion(
    id: "q3",
    title: "numba",
    type: "radio",
    options: ["heehe", "heeee"],
  ),

  SurveyQuestion(
    id: "q4",
    title: "( Pilihlah Minimal 1 pilihan )",
    type: "checkbox",
    options: ["fuuc", "ha"],
  ),

];