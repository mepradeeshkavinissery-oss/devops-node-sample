# Setting up the self-hosted runner

The pipeline uses `runs-on: [ self-hosted, linux ]`, so you must register at
least one self-hosted runner on a machine (an EC2 instance works well).

## 1. Get the registration commands
In your repository: **Settings → Actions → Runners → New self-hosted runner**.
Choose **Linux / x64**. GitHub shows you exact commands with a one-time token.

## 2. Install (example — use the commands GitHub shows YOU)
```bash
# On the runner machine (e.g. an Ubuntu EC2 instance)
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64.tar.gz -L \
  https://github.com/actions/runner/releases/download/vX.Y.Z/actions-runner-linux-x64-X.Y.Z.tar.gz
tar xzf actions-runner-linux-x64.tar.gz

# Register with the token from the settings page
./config.sh --url https://github.com/<you>/<repo> --token <TOKEN> --labels self-hosted,linux
```

## 3. Run it as a service (so it survives reboots)
```bash
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

## 4. Install the tools the pipeline needs on the runner
```bash
# Node.js 18 (actions/setup-node will also manage versions, but git/curl/tar are needed)
sudo apt-get update
sudo apt-get install -y git curl tar unzip
# Node 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

The runner and the SonarQube/Nexus servers must be reachable from this machine.
```
```
