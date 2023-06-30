import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String gptApiUrl = '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';

void main() {
  runApp(QuizApp());
}

class QuizApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: QuizScreen(),
    );
  }
}

class QuizScreen extends StatefulWidget {
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestion = 0;
  int score = 0;
  bool isLoading = true;
  List<Question> questions = [];

  Timer? _timer;
  int _timeRemaining = 60;

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchQuestions() async {
    final response = await http.get(Uri.parse(
        'https://opentdb.com/api.php?amount=10&category=18&type=multiple'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'] as List<dynamic>;
      setState(() {
        questions = results.map((q) => Question.fromMap(q)).toList();
        isLoading = false;
      });
      startTimer();
    } else {
      // Handle error
      setState(() {
        isLoading = false;
      });
    }
  }

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 2), (_) {
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          nextQuestion();
        }
      });
    });
  }

  void nextQuestion() {
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
        _timeRemaining = 60;
      });
    } else {
      showScore();
    }
  }

  void showScore() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Quiz Completed'),
          content: Text('Score: $score'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  currentQuestion = 0;
                  score = 0;
                  isLoading = true;
                  questions = [];
                });
                fetchQuestions();
              },
            ),
          ],
        );
      },
    );
  }

  void answerQuestion(int answerIndex) {
    if (questions[currentQuestion].correctAnswerIndex == answerIndex) {
      setState(() {
        score++;
      });
    }
    nextQuestion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 245, 225, 225),
      appBar: AppBar(
        title: Text('Quiz App'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Question ${currentQuestion + 1}/${questions.length}',
                    style: TextStyle(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'Timer: $_timeRemaining',
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32.0),
                  Text(
                    questions[currentQuestion].question,
                    style: TextStyle(fontSize: 28),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32.0),
                  ...questions[currentQuestion]
                      .answers
                      .asMap()
                      .entries
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ElevatedButton(
                            onPressed: () => answerQuestion(entry.key),
                            style: ElevatedButton.styleFrom(
                              primary: Color.fromARGB(255, 174, 189, 201),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              padding: EdgeInsets.all(16.0),
                            ),
                            child: Text(
                              entry.value,
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
    );
  }
}

class Question {
  final String question;
  final List<String> answers;
  final int correctAnswerIndex;

  Question({
    required this.question,
    required this.answers,
    required this.correctAnswerIndex,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    final correctAnswer = map['correct_answer'] as String;
    final incorrectAnswers = map['incorrect_answers'] as List<dynamic>;
    final answers = [...incorrectAnswers, correctAnswer];
    answers.shuffle();

    return Question(
      question: map['question'] as String,
      answers: answers.map((a) => a.toString()).toList(),
      correctAnswerIndex: answers.indexOf(correctAnswer),
    );
  }
}
