# DevOps Node Sample — CI/CD Pipeline Project

A hands-on sample project for DevOps students. It demonstrates a complete
GitHub Actions pipeline that:

- runs on a **self-hosted runner**
- is triggered manually via **`workflow_dispatch`** with a **dev / prod** choice
- runs **tests + coverage**
- performs **SonarQube** static analysis with a quality gate
- publishes the build artifact to **Nexus**
- **deploys to an EC2** instance over SSH and restarts the service

Students should fork this repo, wire up their own secrets, push a change, and
watch the pipeline run.

---

## 1. What's in the repo

```
devops-node-sample/
├── src/                       # the Node.js app
│   ├── server.js              # Express server + routes
│   └── utils.js               # pure functions (unit tested)
├── test/
│   └── app.test.js            # Jest + supertest tests
├── scripts/
│   ├── deploy-remote.sh       # runs ON EC2: unpack, install, restart
│   ├── start-app.sh           # loads .env and starts the app
│   └── setup-runner.md        # how to register the self-hosted runner
├── deploy/
│   └── devops-node-sample.service   # systemd unit for the app
├── .github/workflows/
│   └── cicd.yml               # THE PIPELINE
├── sonar-project.properties   # SonarQube config
├── package.json
└── README.md
```

---

## 2. The pipeline at a glance

```
 workflow_dispatch (choose dev/prod)  ── or ──  push to main
                       │
                       ▼
        ┌──────────────────────────────┐
        │ JOB 1: build (self-hosted)    │
        │  1. checkout                  │
        │  2. setup-node                │
        │  3. npm ci                    │
        │  4. lint                      │
        │  5. npm test (coverage)       │
        │  6. SonarQube scan + gate     │
        │  7. package .tgz              │
        │  8. upload to Nexus           │
        └──────────────┬───────────────┘
                       │ needs: build
                       ▼
        ┌──────────────────────────────┐
        │ JOB 2: deploy (self-hosted)   │
        │  runs only if run_deploy=true │
        │  environment: dev | prod      │
        │  1. download artifact         │
        │  2. scp to EC2                │
        │  3. run deploy-remote.sh      │
        │  4. smoke test /health        │
        └──────────────────────────────┘
```

- **CI** (build + test + scan + publish) runs on **every push to main**.
- **CD** (deploy) only runs when you start the workflow manually and tick
  `run_deploy`, choosing `dev` or `prod`.

---

## 3. One-time setup

### 3a. Register a self-hosted runner
Follow `scripts/setup-runner.md`. The runner needs labels `self-hosted,linux`
and must have `git`, `curl`, `tar`, and Node 18 available.

### 3b. Prepare the EC2 instance (the deploy target)
```bash
# On the EC2 box, once:
sudo mkdir -p /opt/devops-node-sample/releases
sudo cp deploy/devops-node-sample.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable devops-node-sample
# (the service will fail until the first deploy creates "current" — that's fine)
```
Make sure the EC2 security group allows SSH (port 22) from your runner, and
Node 18 is installed on the EC2 box.

### 3c. Set up SonarQube and Nexus
- **SonarQube**: create a project with key `devops-node-sample` and generate a
  token. You can run SonarQube in Docker for class:
  `docker run -d -p 9000:9000 sonarqube:lts-community`
- **Nexus**: create a **raw (hosted)** repository named `node-artifacts`, and a
  user with upload rights.

### 3d. Add GitHub Secrets
Repo → **Settings → Secrets and variables → Actions → New repository secret**:

| Secret | Example / meaning |
|---|---|
| `SONAR_HOST_URL` | `http://your-sonar:9000` |
| `SONAR_TOKEN` | SonarQube analysis token |
| `NEXUS_URL` | `http://your-nexus:8081` |
| `NEXUS_USERNAME` | Nexus upload user |
| `NEXUS_PASSWORD` | Nexus password |
| `EC2_USER` | `ubuntu` (SSH user) |
| `EC2_SSH_KEY` | the **private** key (PEM contents) |
| `EC2_HOST_DEV` | dev instance public DNS/IP |
| `EC2_HOST_PROD` | prod instance public DNS/IP |

### 3e. (Recommended) Add a prod approval gate
Repo → **Settings → Environments → New environment → `prod`** → add yourself as a
**required reviewer**. Now every prod deploy pauses for manual approval.

---

## 4. How students run it

### Run CI only
Just push a commit to `main`. Job 1 runs automatically.

### Run a deployment
1. Go to the **Actions** tab.
2. Select **CI-CD Pipeline** → **Run workflow**.
3. Choose `environment` = `dev` or `prod`, keep `run_deploy` checked.
4. Click **Run workflow** and watch the logs.

---

## 5. Make a change (student exercise ideas)

1. Add a new route in `src/server.js` and a test for it in `test/app.test.js`.
2. Break a test on purpose and watch CI go red.
3. Add a code smell (e.g. an unused variable) and see SonarQube flag it.
4. Deploy to `dev`, verify `/health`, then promote to `prod` with approval.
5. Lower the SonarQube quality gate threshold and observe the gate failing.

---

## 6. Run locally

```bash
npm install
npm test          # run tests + coverage
npm start         # http://localhost:3000/health
```

---

## 7. Troubleshooting

- **Job stuck on "Waiting for a runner"** → your self-hosted runner is offline;
  check `sudo ./svc.sh status` on the runner machine.
- **SonarQube step fails** → confirm `SONAR_HOST_URL`/`SONAR_TOKEN` and that the
  runner can reach the Sonar server.
- **Nexus upload 401** → wrong `NEXUS_USERNAME`/`NEXUS_PASSWORD` or the repo isn't
  a *raw hosted* repo named `node-artifacts`.
- **SSH deploy fails** → check `EC2_SSH_KEY` is the full PEM, the security group
  allows port 22, and `EC2_USER` matches the AMI (`ubuntu`, `ec2-user`, etc.).
- **Service won't start** → `sudo journalctl -u devops-node-sample -n 50` on EC2.

---

## License
MIT — free to use for teaching and learning.
