import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  // Fix: Don't crash if .env is missing (Production mode)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("No .env file found. This is normal for Production.");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EatWell',
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: const GoalInputScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// DATA MODELS
// ---------------------------------------------------------------------------

class Meal {
  final String name;
  final String calories;
  final double price;
  final String recipe;

  Meal({
    required this.name,
    required this.calories,
    required this.price,
    required this.recipe,
  });
}

class DailyPlan {
  final String dayName;
  final List<Meal> meals; // Breakfast, Lunch, Dinner

  DailyPlan({required this.dayName, required this.meals});
}

// ---------------------------------------------------------------------------
// SCREEN 1: GOAL INPUT
// ---------------------------------------------------------------------------

class GoalInputScreen extends StatefulWidget {
  const GoalInputScreen({super.key});

  @override
  State<GoalInputScreen> createState() => _GoalInputScreenState();
}

class _GoalInputScreenState extends State<GoalInputScreen> {
  final TextEditingController _goalController = TextEditingController();

  void _generatePlan() {
    if (_goalController.text.isEmpty) return;

    // Navigate to the next screen, passing the goal
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WeeklyPlanScreen(userGoal: _goalController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set Your Goals")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              const Text(
                "What are your dietary goals?",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "E.g., Lose weight, Build muscle, Keto diet...",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _goalController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: "Enter your goal here...",
                  filled: true,
                  fillColor: Colors.green.withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _generatePlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Generate Meal Plan"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SCREEN 2: WEEKLY PLAN
// ---------------------------------------------------------------------------

class WeeklyPlanScreen extends StatefulWidget {
  final String userGoal;

  const WeeklyPlanScreen({super.key, required this.userGoal});

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  List<DailyPlan> weeklyPlan = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate AI generation delay
    _generateMealPlan();
  }

  Future<void> _generateMealPlan() async {
    setState(() {
      isLoading = true; // Show loading spinner
    });

    // 1. SETUP
    // 1. ENDPOINT: It is safe and easier to hardcode this URL here.
    // (Azure Static Web Apps won't easily read dotenv for this).
    final String azureEndpoint =
        "https://diet-planner123-resource.cognitiveservices.azure.com/openai/deployments/gpt-5-nano/chat/completions?api-version=2024-12-01-preview";

    // 2. KEY: Hybrid Logic (Production vs. Local)
    // First, check if Azure/GitHub injected the key during the build
    String azureKey = const String.fromEnvironment('AZURE_KEY');

    // If not (meaning we are on your laptop), read from .env
    if (azureKey.isEmpty) {
      azureKey = dotenv.env['AZURE_KEY'] ?? "";
    }

    try {
      final response = await http
          .post(
            Uri.parse(azureEndpoint),
            headers: {
              "Content-Type": "application/json",
              "api-key": azureKey, // Azure uses this instead of 'Authorization'
            },
            body: jsonEncode({
              "reasoning_effort": "low",

              "messages": [
                {
                  "role": "system",
                  // TRIPLE QUOTES fix the multi-line string error:
                  "content": """
You are a nutritionist.
1. Create a 7-DAY meal plan (Monday-Sunday).
2. 3 Meals per day (Breakfast, Lunch, Dinner).
3. RECIPES: Write 2-3 sentences for each recipe. Be concise but helpful.
4. Return ONLY JSON.
Structure:
{
  "days": [
    {
      "dayName": "Monday",
      "meals": [
        {
          "name": "Meal Name",
          "calories": "500 kcal",
          "price": 5.0,
          "recipe": "1. Chop veg. 2. Boil water. 3. Serve."
        }
      ]
    }
  ]
}
""",
                },
                {
                  "role": "user",
                  // Only send the user's specific input here
                  "content": "My goal is: ${widget.userGoal}",
                },
              ],
              "response_format": {"type": "json_object"},
            }),
          )
          .timeout(const Duration(seconds: 120)); // Optional: increase timeout

      // ... (Rest of your parsing code)

      if (response.statusCode == 200) {
        // 4. PARSING THE RESPONSE
        print("RAW RESPONSE: ${response.body}");
        final data;
        try {
          data = jsonDecode(response.body);
          // ... rest of logic
        } catch (e) {
          print("JSON CRASHED: $e");
          // This tells you IF it was valid JSON or half-finished text
          return;
        }
        final String content = data['choices'][0]['message']['content'];

        // Parse the inner JSON string from the AI
        final Map<String, dynamic> jsonResponse = jsonDecode(content);
        final List<dynamic> daysJson = jsonResponse['days'];

        // 5. CONVERT JSON TO YOUR DART OBJECTS
        List<DailyPlan> realPlan = daysJson.map((dayData) {
          // Map the meals list
          List<Meal> mealsList = (dayData['meals'] as List).map((mealData) {
            return Meal(
              name: mealData['name'],
              calories: mealData['calories'],
              price: (mealData['price'] as num)
                  .toDouble(), // Safely convert int/double
              recipe: mealData['recipe'],
            );
          }).toList();

          return DailyPlan(dayName: dayData['dayName'], meals: mealsList);
        }).toList();

        // 6. UPDATE UI
        setState(() {
          weeklyPlan = realPlan;
          isLoading = false;
        });
      } else {
        print("API Error: ${response.statusCode} - ${response.body}");
        setState(() => isLoading = false);
        // Optional: Show an error snackbar here
      }
    } catch (e) {
      print("Network Error: $e");
      setState(() => isLoading = false);
    }
  }
  // Future<void> _mockAIGenerator() async {
  //   await Future.delayed(const Duration(seconds: 2)); // Fake loading
  //
  //   // In a real app, you would send widget.userGoal to an OpenAI/Gemini API here.
  //   // We will generate dummy data based on the goal string.
  //   bool isMuscle = widget.userGoal.toLowerCase().contains("muscle");
  //
  //   List<String> days = [
  //     "Monday",
  //     "Tuesday",
  //     "Wednesday",
  //     "Thursday",
  //     "Friday",
  //     "Saturday",
  //     "Sunday",
  //   ];
  //
  //   List<DailyPlan> generatedPlan = days.map((day) {
  //     return DailyPlan(
  //       dayName: day,
  //       meals: [
  //         Meal(
  //           name: isMuscle ? "High Protein Omelet" : "Oatmeal & Berries",
  //           calories: isMuscle ? "500 kcal" : "300 kcal",
  //           price: 5.99,
  //           recipe: "1. Whisk eggs.\n2. Add spinach.\n3. Fry in olive oil.",
  //         ),
  //         Meal(
  //           name: isMuscle ? "Grilled Chicken & Rice" : "Quinoa Salad",
  //           calories: isMuscle ? "700 kcal" : "450 kcal",
  //           price: 12.50,
  //           recipe:
  //               "1. Season chicken.\n2. Grill for 10 mins.\n3. Serve with brown rice.",
  //         ),
  //         Meal(
  //           name: isMuscle ? "Steak & Asparagus" : "Vegetable Soup",
  //           calories: isMuscle ? "600 kcal" : "250 kcal",
  //           price: 15.00,
  //           recipe:
  //               "1. Chop veggies.\n2. Simmer in broth for 30 mins.\n3. Add spices.",
  //         ),
  //       ],
  //     );
  //   }).toList();
  //
  //   setState(() {
  //     weeklyPlan = generatedPlan;
  //     isLoading = false;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Plan: ${widget.userGoal}")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : weeklyPlan.isEmpty
          ? const Center(
              child: Text("Failed to load plan. Check console."),
            ) // Show error text if list is empty
          : SingleChildScrollView(
              child: ExpansionPanelList.radio(
                elevation: 1,
                children: weeklyPlan.asMap().entries.map<ExpansionPanelRadio>((
                  entry,
                ) {
                  int index = entry.key;
                  DailyPlan day = entry.value;

                  return ExpansionPanelRadio(
                    value: index,
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return ListTile(
                        leading: CircleAvatar(child: Text(day.dayName[0])),
                        title: Text(day.dayName),
                      );
                    },
                    body: Column(
                      children: day.meals
                          .map((meal) => MealItemWidget(meal: meal))
                          .toList(),
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// WIDGET: INDIVIDUAL MEAL ITEM
// ---------------------------------------------------------------------------

class MealItemWidget extends StatefulWidget {
  final Meal meal;

  const MealItemWidget({super.key, required this.meal});

  @override
  State<MealItemWidget> createState() => _MealItemWidgetState();
}

class _MealItemWidgetState extends State<MealItemWidget> {
  bool _showRecipe = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal Header Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.meal.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.meal.calories,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
              Text(
                "\$${widget.meal.price}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Action Buttons
          Row(
            children: [
              // Buy Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Ordered ${widget.meal.name}!")),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart, size: 18),
                  label: const Text("Buy"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Recipe Button (Toggle)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showRecipe = !_showRecipe;
                    });
                  },
                  icon: Icon(
                    _showRecipe ? Icons.expand_less : Icons.menu_book,
                    size: 18,
                  ),
                  label: Text(_showRecipe ? "Hide Recipe" : "Recipe"),
                ),
              ),
            ],
          ),

          // Conditional Recipe Display (The Dropdown effect)
          if (_showRecipe) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "INSTRUCTIONS:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(widget.meal.recipe),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
