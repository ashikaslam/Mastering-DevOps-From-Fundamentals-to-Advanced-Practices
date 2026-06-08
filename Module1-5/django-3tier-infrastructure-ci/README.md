# Django CI Lab — GitHub Actions Fundamentals (Module 5)

A minimal, production-style **Python Django** application wired to a **GitHub Actions CI pipeline** running on a **self-hosted Ubuntu EC2 runner**. Built as a hands-on assignment for Module 5: GitHub Actions Fundamentals.

---

## What This Project Demonstrates

- A working Django app that renders an HTML page using a context dictionary
- A GitHub Actions CI pipeline that automatically runs on every push to `main`
- A self-hosted runner registered on an AWS EC2 Ubuntu instance
- How to debug a failing pipeline by intentionally breaking a test

---

## Project Structure

```
django-3tier-infrastructure-ci/
├── .github/
│   └── workflows/
│       └── ci.yml              # GitHub Actions CI pipeline
├── app/
│   ├── migrations/
│   │   └── __init__.py
│   ├── templates/
│   │   └── index.html          # Dark-theme HTML template
│   ├── __init__.py
│   ├── apps.py
│   ├── tests.py                # Unit tests (SimpleTestCase)
│   └── views.py                # home_view with context dictionary
├── core/
│   ├── __init__.py
│   ├── settings.py             # SQLite, DEBUG=True, ALLOWED_HOSTS=*
│   ├── urls.py                 # Root URL → home_view
│   └── wsgi.py
├── .gitignore
├── manage.py
├── requirements.txt            # Django==5.2
└── README.md
```

---

## CI Pipeline Overview

**File:** `.github/workflows/ci.yml`

| Trigger | Branch |
|---|---|
| `push` | `main` |
| `pull_request` | `main` |

**Runner:** `self-hosted` (Ubuntu EC2)

### Pipeline Steps

```
1. Checkout code          → actions/checkout@v4
2. Set up virtual env     → python3 -m venv .venv
3. Install dependencies   → .venv/bin/pip install -r requirements.txt
4. Django system check    → .venv/bin/python manage.py check
5. Run unit tests         → .venv/bin/python manage.py test
```

> A Python `venv` is used instead of `actions/setup-python` because the EC2 runner runs Ubuntu 26.04 with Python 3.14, which enforces PEP 668 and blocks system-wide `pip install`.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Python 3.14 |
| Framework | Django 5.2 |
| Database | SQLite (`db.sqlite3`) |
| CI Platform | GitHub Actions |
| Runner | Self-Hosted (AWS EC2 Ubuntu 26.04) |
| Template Engine | Django Templates (context-based) |

---

## Local Setup

### Prerequisites
- Python 3.10+ installed
- Git

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/ashikaslam/django-actions-ci-lab.git
cd django-actions-ci-lab

# 2. Create and activate a virtual environment
python3 -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Run Django system check
python manage.py check

# 5. Run the development server
python manage.py runserver
```

Open `http://127.0.0.1:8000` in your browser.

---

## Running Tests Locally

```bash
python manage.py test --verbosity=2
```

Expected output:
```
Found 3 test(s).
test_basic_assertion ... ok
test_url_resolves_to_home_view ... ok
test_view_module_importable ... ok

Ran 3 tests in 0.00s
OK
```

---

## Self-Hosted Runner Setup (EC2)

### 1. Prepare the EC2 instance

```bash
sudo apt-get update -y
sudo apt-get install -y python3 python3-venv python3-full
```

### 2. Register the runner

```bash
mkdir actions-runner && cd actions-runner

# Download the runner (check https://github.com/actions/runner/releases for latest)
curl -o actions-runner-linux-x64-2.334.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.334.0/actions-runner-linux-x64-2.334.0.tar.gz

tar xzf ./actions-runner-linux-x64-2.334.0.tar.gz

# Configure (replace TOKEN with your repo's runner token)
./config.sh --url https://github.com/ashikaslam/django-actions-ci-lab --token YOUR_TOKEN
```

### 3. Start the runner

```bash
./run.sh
```

The runner will print `Listening for Jobs` when ready. Every push to `main` will trigger the pipeline automatically.

---

## Demonstrating Pipeline Failure (Debugging Practice)

This project includes a built-in way to intentionally break the pipeline to practice reading CI failure logs.

Open `app/tests.py` and change line 8:

```python
# PASSING (default)
self.assertEqual(1, 1)

# FAILING — change to this to break the pipeline
self.assertEqual(1, 2)
```

Commit and push. The pipeline will fail with:
```
AssertionError: 1 != 2
```

Revert the change and push again to restore the green pipeline.

---

## Context Variables Rendered in the UI

The `home_view` passes the following context to `index.html`:

| Key | Example Value |
|---|---|
| `project_name` | Django 3-Tier Infrastructure CI |
| `developer_status` | Active |
| `current_time` | 2026-05-20 11:30:00 |
| `pipeline_status` | Passing ✅ |

---

## Key Design Decisions

- **No Django REST Framework** — pure Django with function-based views and template rendering
- **SQLite only** — no external database required, zero infrastructure dependencies
- **venv in workflow** — bypasses PEP 668 (`externally-managed-environment`) on modern Ubuntu
- **Django 5.2** — required for Python 3.14 compatibility (fixes `super().__copy__()` bug in template context)
- **`SimpleTestCase`** — used instead of `TestCase` since no database operations are needed
