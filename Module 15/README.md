# Module 15 Assignment - Simple Express App

A minimal Node.js Express application used to practice DevOps tools:
testing, code quality, load testing, policy-as-code, Kubernetes, and CI/CD.

## Project Structure

```
├── src/app.js                 # Express server (2 routes)
├── tests/app.test.js          # Jest tests
├── load-tests/k6-test.js      # k6 load test script
├── policies/k8s-policy.rego   # OPA policy (no :latest tags)
├── k8s/deployment.yaml        # Kubernetes Deployment
├── sonar-project.properties   # SonarCloud/SonarQube config
└── .github/workflows/ci-cd.yml # GitHub Actions pipeline
```

## Local Setup

```bash
# 1. Install dependencies
npm install

# 2. Set environment variables (secrets are never hardcoded)
export DB_PASS=my-db-password
export API_KEY=my-api-key

# 3. Start the server
npm start
```

The server runs at `http://localhost:3000`.

## Routes

| Method | Path       | Description                          |
|--------|------------|--------------------------------------|
| GET    | `/`        | Health check, returns HTTP 200       |
| POST   | `/api/data`| Accepts JSON `{ "name": "..." }`     |

## Running Tests

```bash
npm test
```

## Tools Used

| Tool       | Purpose                                                        | Command / Usage                              |
|------------|----------------------------------------------------------------|----------------------------------------------|
| **Jest**   | Unit testing for Node.js                                       | `npm test`                                   |
| **Supertest** | HTTP assertions for Express apps                            | Used inside Jest tests                       |
| **SonarQube** | Static code quality analysis                                | `sonar-scanner` (config in `sonar-project.properties`) |
| **k6**     | Load / performance testing                                     | `k6 run load-tests/k6-test.js` (50 VUs)      |
| **OPA / Conftest** | Policy-as-code for Kubernetes manifests                    | `conftest test k8s/deployment.yaml -p policies` |
| **Trivy**  | Container image vulnerability scanning                         | `trivy image your-image:1.0.0`               |
| **GitHub Actions** | CI/CD pipeline (tests, Trivy, Conftest)                    | Runs automatically on push / PR              |

## Notes

- Replace `your-dockerhub-username` and `your-org-name` with your own values.
- The OPA policy rejects any image tag ending in `:latest`.
- Secrets (`DB_PASS`, `API_KEY`) are read from environment variables only.