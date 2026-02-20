# Secure Mobile Biometric Voting System

A fully mobile-based election management application designed to conduct secure digital voting using mobile fingerprint authentication. Built with **Flutter** (Frontend) and **Django REST Framework** (Backend).

## 🏗 Architecture

```
voter/
├── application.txt           # Project specification
├── voting_backend/           # Django REST API Backend
│   ├── api/                  # Main API app
│   │   ├── models.py         # Database models (Voter, Election, Party, Candidate, Vote)
│   │   ├── views.py          # API views & business logic
│   │   ├── serializers.py    # DRF serializers
│   │   ├── urls.py           # API URL routing
│   │   └── admin.py          # Django admin configuration
│   ├── voting_backend/       # Django project settings
│   ├── manage.py
│   ├── db.sqlite3            # SQLite database
│   └── requirements.txt      # Python dependencies
└── voting_app/               # Flutter Mobile Application
    ├── lib/
    │   ├── main.dart          # App entry point + Splash Screen
    │   ├── utils/
    │   │   ├── constants.dart # App-wide constants & API URL
    │   │   └── theme.dart     # Premium theme configuration
    │   ├── services/
    │   │   └── api_service.dart # HTTP API client
    │   ├── providers/
    │   │   └── auth_provider.dart # Authentication state management
    │   └── screens/
    │       ├── auth/
    │       │   ├── login_screen.dart    # Unified Admin/Voter login
    │       │   └── register_screen.dart # Voter self-registration
    │       ├── admin/
    │       │   ├── admin_dashboard_screen.dart     # Admin dashboard
    │       │   ├── voter_management_screen.dart     # Voter CRUD & approval
    │       │   ├── election_management_screen.dart  # Election CRUD
    │       │   ├── party_management_screen.dart     # Party management
    │       │   ├── candidate_management_screen.dart # Candidate management
    │       │   └── result_management_screen.dart    # Results & analytics
    │       └── voter/
    │           ├── voter_home_screen.dart   # Voter dashboard
    │           ├── vote_casting_screen.dart  # 3-step voting flow
    │           └── voter_results_screen.dart # View election results
    └── pubspec.yaml
```

## 🛠 Technology Stack

| Component | Technology |
|-----------|-----------|
| **Backend** | Python Django + Django REST Framework |
| **Frontend** | Flutter (Single app for Admin & Voter) |
| **Database** | SQLite3 (upgradeable to PostgreSQL) |
| **Biometric Auth** | Native Mobile Fingerprint (local_auth) |
| **State Management** | Provider |
| **Security** | Token Authentication, Hashed Passcodes |

## 🚀 Setup & Run

### Backend Setup

```bash
cd voting_backend

# Install dependencies
pip install -r requirements.txt

# Run migrations
python3 manage.py makemigrations api
python3 manage.py migrate

# Create admin superuser (already created: admin / admin123)
python3 manage.py createsuperuser

# Start server
python3 manage.py runserver 0.0.0.0:8000
```

### Frontend Setup

```bash
cd voting_app

# Install dependencies
flutter pub get

# Update API URL in lib/utils/constants.dart
# - Android Emulator: http://10.0.2.2:8000/api
# - iOS Simulator: http://localhost:8000/api
# - Physical Device: http://YOUR_PC_IP:8000/api

# Run the app
flutter run
```

## 🔐 Default Credentials

| Role | Username | Password |
|------|----------|----------|
| Admin | `admin` | `admin123` |

## 📱 Features

### Admin Portal
- ✅ Dashboard with live statistics
- ✅ Voter Management (Add, Approve, Reject, Block, Unblock, Remove Duplicates)
- ✅ Voter Self-Registration with approval workflow
- ✅ Election Management (Create, Start, Stop, Extend)
- ✅ Party Management (Add with symbol upload)
- ✅ Candidate Management (per election)
- ✅ Real-time vote monitoring
- ✅ Result publishing with analytics & pie charts

### Voter Portal
- ✅ Login with Voter ID + Passcode
- ✅ Login with Fingerprint (biometric)
- ✅ View active elections
- ✅ 3-step voting: Fingerprint verify → Select candidate → Submit
- ✅ One vote per election enforcement
- ✅ View published results with charts

### Security
- ✅ Device-level fingerprint authentication (no fingerprint stored in DB)
- ✅ Encrypted passcode storage (Django password hashing)
- ✅ Token-based API authentication
- ✅ One vote per voter per election constraint
- ✅ Admin approval required before voting
- ✅ Duplicate Voter ID prevention
- ✅ Session management

## 📊 API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/health/` | GET | Health check |
| `/api/auth/admin/login/` | POST | Admin login |
| `/api/auth/voter/login/` | POST | Voter login (ID + Passcode) |
| `/api/auth/voter/biometric-login/` | POST | Biometric login |
| `/api/auth/voter/register/` | POST | Voter self-registration |
| `/api/auth/logout/` | POST | Logout |
| `/api/admin/dashboard/` | GET | Dashboard stats |
| `/api/voters/` | GET/POST | Voter list / create |
| `/api/voters/{id}/approve/` | POST | Approve voter |
| `/api/voters/{id}/reject/` | POST | Reject voter |
| `/api/voters/{id}/block/` | POST | Block voter |
| `/api/voters/{id}/unblock/` | POST | Unblock voter |
| `/api/elections/` | GET/POST | Election list / create |
| `/api/elections/{id}/start/` | POST | Start election |
| `/api/elections/{id}/stop/` | POST | Stop election |
| `/api/elections/{id}/results/` | GET | Get results |
| `/api/elections/{id}/publish_results/` | POST | Publish results |
| `/api/parties/` | GET/POST | Party list / create |
| `/api/candidates/` | GET/POST | Candidate list / create |
| `/api/vote/cast/` | POST | Cast vote |
| `/api/vote/status/{election_id}/` | GET | Check vote status |
| `/api/voter/profile/` | GET | Voter profile |
| `/api/voter/elections/` | GET | Available elections |
| `/api/voter/results/{election_id}/` | GET | View results |
