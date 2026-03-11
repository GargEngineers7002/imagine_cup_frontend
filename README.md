# 🥗 EatWell - AI-Powered Personalized Diet Planner

EatWell is a modern Flutter application designed to help users achieve their dietary goals through personalized, AI-generated meal plans. Whether you want to lose weight, build muscle, or follow a specific diet like Keto, EatWell leverages advanced AI models to create a comprehensive 7-day nutrition strategy tailored just for you.

## 🔗 Live Demo
Check out the live application here: [https://lively-sand-0132ab71e.1.azurestaticapps.net/](https://lively-sand-0132ab71e.1.azurestaticapps.net/)

## 🚀 Features

- **Goal-Oriented Planning:** Enter any dietary goal (e.g., "Build muscle", "Keto diet", "Low carb") and receive a custom plan.
- **7-Day Weekly Schedule:** A full week of nutrition with 3 balanced meals per day (Breakfast, Lunch, Dinner).
- **Nutritional Insights:** Each meal includes calorie counts to help you stay on track.
- **Detailed Recipes:** Access concise, easy-to-follow instructions for preparing every meal in your plan.
- **Cost Estimation:** Provides estimated prices for meals to help with budget planning.
- **Seamless Ordering:** Integrated "Buy" simulation to visualize the transition from planning to eating.
- **Cross-Platform:** Built with Flutter, optimized for Web, and ready for Android/iOS.

## 🛠️ Tech Stack

- **Frontend:** [Flutter](https://flutter.dev/) (Material 3)
- **AI Engine:** [Azure OpenAI Service](https://azure.microsoft.com/en-us/products/ai-services/openai-service) (GPT models)
- **Deployment:** [Azure Static Web Apps](https://azure.microsoft.com/en-us/products/static-web-apps)
- **CI/CD:** GitHub Actions
- **Networking:** `http` package
- **Environment Management:** `flutter_dotenv` & `--dart-define`

## 💻 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable version)
- An Azure OpenAI API Key and Endpoint

### Local Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/imagine_cup_frontend.git
   cd imagine_cup_frontend
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables:**
   Create a `.env` file in the root directory:
   ```env
   AZURE_KEY=your_azure_openai_api_key_here
   ```

4. **Run the application:**
   ```bash
   flutter run
   ```

## 🌐 Deployment

The project is fully deployed using **Azure Static Web Apps**.

### CI/CD Workflow
The deployment is automated via GitHub Actions. On every push to the `main` branch:
1. Flutter is installed.
2. The project is built for the web.
3. The `AZURE_KEY` is injected during the build process using `--dart-define`.
4. The production-ready assets are uploaded to Azure.

### Environment Secrets
For production deployments, ensure the following secrets are configured in your GitHub repository:
- `AZURE_KEY`: Your Azure OpenAI API Key.
- `AZURE_STATIC_WEB_APPS_API_TOKEN_...`: The deployment token provided by Azure.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
*Built for the Imagine Cup.*
