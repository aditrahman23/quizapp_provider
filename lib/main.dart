import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => QuestionProvider(),
      child: const QuizApp(),
    ),
  );
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trivia Quiz')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Play'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlayerScreen()),
            );
          },
        ),
      ),
    );
  }
}

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QuestionProvider>(context);

    if (provider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Question')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Question')),
        body: const Center(child: Text('No questions available')),
      );
    }

    final question = provider.currentQuestion;

    return Scaffold(
      appBar: AppBar(title: const Text('Question')),
      body: ListView(
        children: <Widget>[
          ListTile(title: Text(question.question)),
          ...question.answers
              .map(
                (answer) => ListTile(
                  title: Text(answer),
                  onTap: () => provider.checkAnswer(answer, context),
                ),
              )
              .toList(),
        ],
      ),
    );
  }
}

class ScoreScreen extends StatelessWidget {
  final int score;

  const ScoreScreen({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Score')),
      body: Center(
        child: Text('Your score is: $score', style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}

class QuestionProvider extends ChangeNotifier {
  List<Question> questions = [];
  int currentQuestionIndex = 0;
  int score = 0;
  bool isLoading = true;

  QuestionProvider() {
    fetchQuestions();
  }

  Question get currentQuestion => questions[currentQuestionIndex];

  Future<void> fetchQuestions() async {
    try {
      final response = await http.get(Uri.parse(
          'https://opentdb.com/api.php?amount=2&category=18&difficulty=easy&type=multiple'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        questions = List<Question>.from(
            data['results'].map((question) => Question.fromJson(question)));
      } else {
        throw Exception('Failed to load questions');
      }
    } catch (e) {
      questions = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void checkAnswer(String selectedAnswer, BuildContext context) {
    if (currentQuestion.correctAnswer == selectedAnswer) {
      score++;
    }

    if (currentQuestionIndex < questions.length - 1) {
      currentQuestionIndex++;
      notifyListeners();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScoreScreen(score: score),
        ),
      );
    }
  }
}

class Question {
  final String question;
  final List<String> answers;
  final String correctAnswer;

  Question({
    required this.question,
    required this.answers,
    required this.correctAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    var incorrectAnswers = List<String>.from(json['incorrect_answers']);
    var correctAnswer = json['correct_answer'];
    incorrectAnswers.add(correctAnswer);
    incorrectAnswers.shuffle();
    return Question(
      question: json['question'],
      answers: incorrectAnswers,
      correctAnswer: correctAnswer,
    );
  }
}
