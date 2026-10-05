# Great Minds Group - Backend API (FastAPI)

Serveur d'API moderne, sécurisé et performant pour la gestion du Back-Office et des contenus du site web Great Minds Group.

---

## 🚀 Fonctionnalités Clés

- **Authentification & Sécurité JWT** :
  - Connexion sécurisée avec hachage de mot de passe Bcrypt.
  - Gestion des tokens d'accès JWT (`Bearer token`).
- **Contrôle d'Accès Basé sur les Rôles (RBAC)** :
  - `super_admin` : Accès total, gestion des rôles, suppression d'utilisateurs.
  - `admin` : Gestion des utilisateurs, validation et publication de contenus.
  - `agent` : Création et édition de contenus et offres.
- **Gestion Complète des Données (CRUD)** :
  - **Utilisateurs** : création, modification, suspension, suppression.
  - **Contenus & Offres** : publication d'offres d'emploi, actualités, services.
  - **Dashboard & KPIs** : indicateurs clés et activités récentes.
  - **Logs d'Audit** : traçabilité de toutes les actions administratives.
- **Documentation OpenAPI Intégrée** :
  - Swagger UI interactif : [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
  - Redoc : [http://127.0.0.1:8000/redoc](http://127.0.0.1:8000/redoc)

---

## 🛠️ Démarrage Rapide

### 1. Avec le script automatique (Windows)
Double-cliquez sur `run_server.bat` ou sur le raccourci sur le Bureau.

### 2. Manuellement
```bash
cd backend
py -m venv .venv
.venv\Scripts\pip install -r requirements.txt
.venv\Scripts\uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

---

## 🔐 Identifiants par Défaut (Premier démarrage)

- **Email** : `admin@greatminds.com`
- **Mot de passe** : `Admin@GM2026!`
- **Rôle** : `super_admin`

*(À modifier dès la première connexion dans l'espace administration).*
