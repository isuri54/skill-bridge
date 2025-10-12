## SkillBridge

SkillBridge is a Flutter-based mobile application designed to connect users for skill-sharing and mentorship. With a clean and intuitive interface, users can engage in real-time chats, manage their profiles with detailed statistics and achievements, and schedule mentorship sessions seamlessly. Built with Firebase for robust backend support, SkillBridge empowers users to collaborate, learn, and grow their skills in a vibrant community.

## Features

Chat System: View a list of active conversations, initiate new chats with other users, and stay connected with a sleek messaging interface.
User Profiles: Display comprehensive user information, including:
  Personal details (name, bio, email, mobile).
  Karma points with a history of contributions.
  Statistics (sessions mentored, learned, hours mentored, profile creation date).
  Achievements based on mentorship and skill-sharing milestones.
  Offered and wanted skills for easy discovery.
Schedule Management: Manage mentorship sessions with:
  A tabbed interface for upcoming schedules and pending requests.
  Detailed schedule information (skill, time, role as mentor/learner).
  Options to confirm session completion, accept/decline requests, and delete schedules.


Firebase Integration: Leverages Firebase Authentication for secure user management and Firestore for real-time data storage and retrieval.

## Screenshots

### Home Screen
![Home Screen](https://github.com/user-attachments/assets/0b537ff6-d952-484d-8548-38f460baf7ea)

### Login Screen
![Login Screen](https://github.com/user-attachments/assets/4a822676-2a79-4ede-a18f-18e0bef74556)

### Signup Screen
![Signup Screen](https://github.com/user-attachments/assets/66afeb82-1fb6-472e-ad2b-122369c2d578)

### Chats Home Screen
![Chats Home Screen](https://github.com/user-attachments/assets/b8d8d7c6-d90a-4c6f-8868-863ce7886349)

### Chat Screen
![Chat Screen](https://github.com/user-attachments/assets/bb85a235-f02b-4ef3-878c-2549a1d2fb03)

### Profile Screen
![Profile Screen](https://github.com/user-attachments/assets/1d983a0e-424c-473c-bb79-6a17053171f4)

### Edit Profile Screen
![Edit Profile Screen](https://github.com/user-attachments/assets/0e557b73-4d76-4c9c-9fa6-b4c7f5c43283)

### Mentor Profile Screen
![Mentor Profile Screen](https://github.com/user-attachments/assets/8218b46a-2d1f-4de1-9cc8-22b6ba002fd8)

### Upcoming Schedules Screen
![Upcoming Schedules Screen](https://github.com/user-attachments/assets/598ccc6c-199a-40cf-805d-8fc9b7539f1e)

### Schedule Requests Screen
![Schedule Requests Screen](https://github.com/user-attachments/assets/ac86f60d-41e3-4548-8c94-cd599d609ade)

### Make Schedule Screen
![Make Schedule Screen](https://github.com/user-attachments/assets/a4ab3e31-f223-40ca-9383-ec0dc915583b)

### Skill Selection Screen
![Skill Selection Screen](https://github.com/user-attachments/assets/0be45a68-1ece-45dc-8fac-e41dd80254b6)

### Skill Categories Screen
![Skill Categories Screen](https://github.com/user-attachments/assets/38e46f0e-60a0-49f5-8a5d-5f83cf59e8f6)

### Settings Screen
![Settings Screen](https://github.com/user-attachments/assets/ea7d501b-795c-4fd9-b6c6-708ca1c631b3)


## Getting Started
Prerequisites

Flutter SDK: Version 3.0.0 or higher.
Dart: Included with Flutter.
Firebase Account: Set up a Firebase project for authentication and Firestore.
IDE: Android Studio, VS Code, or any Flutter-compatible IDE.
Emulator/Device: For testing the app.

Installation

Clone the Repository:
git clone https://github.com/isuri54/skill-bridge.git
cd skillbridge


Install Dependencies:Run the following command to install required packages:
flutter pub get


Set Up Firebase:

Create a Firebase project at console.firebase.google.com.
Enable Firebase Authentication (Email/Password) and Firestore Database.
Download the google-services.json (Android) or GoogleService-Info.plist (iOS) and place it in the appropriate directory (android/app/ or ios/Runner/).
Update android/build.gradle and android/app/build.gradle with Firebase dependencies as per the FlutterFire documentation.


Configure Assets:Ensure assets (e.g., profile images) are included in pubspec.yaml:
flutter:
  assets:
    - assets/images/


Run the App:Connect a device or emulator and run:
flutter run



Project Structure
skillbridge/
├── lib/
│   ├── screens/
│   │   ├── chatsscreen.dart      # Individual chat screen
│   │   ├── editprofile.dart      # Profile editing screen
│   │   ├── mentorprofilescreen.dart # Mentor profile viewing screen
│   │   ├── profilescreen.dart    # User profile screen with stats and achievements
│   │   ├── schedulesscreen.dart # Schedule and request management
│   │   └── chatshomescreen.dart # Chat list and new chat initiation
│   │   ├── categoryscreen.dart      # List of skills
│   │   ├── homescreen.dart      # Home screen
│   │   ├── loginscreen.dart # User login screen
│   │   ├── signupscreen.dart    # User signup screen
│   │   ├── makeschedulescreen.dart # Make schedule and send request
│   │   └── skillselectionscreen.dart # Select offered and wanted skills
│   │   └── settingsscreen.dart # Settings screen
│   │   └── splashscreen.dart # Splash screen
│   │   └── bottomnavbar.dart # Bottom navigation bar
│   ├── main.dart                 # App entry point
├── assets/
│   ├── images/
│   │   └── userpng.png          # Default profile image
├── pubspec.yaml                 # Dependencies and assets configuration

Dependencies

flutter: For building the UI.
firebase_auth: For user authentication.
cloud_firestore: For real-time data storage.
get: For state management and navigation.
intl: For date and time formatting.

Usage

Sign In: Log in using your email and password via Firebase Authentication.
Chats:
View all active conversations on the Chats Home Screen.
Start a new chat by searching for users and selecting a recipient.


Profile:
View your profile details, karma, statistics, achievements, and skills.
Edit your profile via the edit button in the app bar.


Schedules:
Check upcoming sessions and pending requests in separate tabs.
Confirm session completion, accept/decline requests, or delete schedules as needed.



Contributing
Contributions are welcome! To contribute:

Fork the repository.
Create a feature branch (git checkout -b feature/your-feature).
Commit your changes (git commit -m 'Add your feature').
Push to the branch (git push origin feature/your-feature).
Open a pull request.

Please ensure your code follows the Flutter style guide and includes relevant tests.
License
This project is licensed under the MIT License - see the LICENSE file for details.
Contact
For questions or feedback, reach out via GitHub Issues or email at [your-email@example.com].
