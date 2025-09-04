# Appointment Scheduler

A Flutter web application for managing clients and appointments with a modern Material 3 UI.

## Features

- **Client Management**: Add, edit, delete client details
- **Appointment Booking**: Schedule meetings with date, time, and description
- **Calendar Integration**: View appointments in calendar format
- **Local Storage**: Data persistence using SharedPreferences
- **Modern UI**: Material 3 design with bottom navigation

## Deployment on Render

### Prerequisites

- Flutter SDK installed
- Render account
- GitHub repository

### Steps to Deploy

1. **Push your code to GitHub**

2. **Connect to Render**:

   - Go to [Render Dashboard](https://dashboard.render.com)
   - Click "New +" → "Static Site"
   - Connect your GitHub repository

3. **Configure the deployment**:

   - **Name**: `appointment-scheduler` (or your preferred name)
   - **Build Command**: `chmod +x build.sh && ./build.sh`
   - **Publish Directory**: `build/web`
   - **Environment**: Static Site

4. **Deploy**:
   - Click "Create Static Site"
   - Render will automatically build and deploy your app

### Alternative Manual Deployment

If you prefer to deploy manually:

1. **Build the app**:

   ```bash
   flutter build web --release
   ```

2. **Upload the `build/web` folder** to your web hosting service

## Local Development

```bash
# Install dependencies
flutter pub get

# Run in development mode
flutter run -d chrome

# Build for production
flutter build web --release
```

## Tech Stack

- **Framework**: Flutter
- **State Management**: Provider
- **Storage**: SharedPreferences
- **UI**: Material 3
- **Calendar**: table_calendar
- **Notifications**: flutter_local_notifications

## Project Structure

```
lib/
├── models/          # Data models
├── providers/       # State management
├── screens/         # UI screens
├── services/        # Business logic
└── main.dart        # App entry point
```

## License

MIT License
