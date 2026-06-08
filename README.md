# Advmobprog-app

Mobile programming project — Flutter frontend + Node.js/MongoDB backend.

## Project structure

```
estrellon_advmobprog/
├── estrellon_mobile/      ← Flutter app (frontend)
└── estrellon-back-end/    ← Node.js API (backend)
```

## Run backend

```bash
cd estrellon-back-end
npm install
npm start
```

Server runs on **port 5000**. Requires MongoDB and a `.env` file:

```env
MONGO_URI=mongodb://localhost:27017/estrellon_db
PORT=5000
JWT_SECRET=your_secret_key
```

## Run frontend

```bash
cd estrellon_mobile
flutter pub get
flutter run
```

Set `estrellon_mobile/.env`:

```env
HOST=http://localhost:5000
# Physical Android device (same Wi-Fi as PC):
ANDROID_HOST=http://YOUR_PC_LAN_IP:5000
```

## Demo login (MongoDB)

- Email: `fname@example.com`
- Password: `12345`

## Features

- Articles API (CRUD)
- User auth (MongoDB JWT + Firebase)
- Splash, login, sign up, profile, settings
- Dark neumorphic UI theme
