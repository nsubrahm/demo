# Introduction

This project documents steps to launch a demo with `10` machines.

- [Introduction](#introduction)
  - [Pre-requisites](#pre-requisites)
  - [Steps - Demo](#steps---demo)
  - [Steps - Simulator](#steps---simulator)

## Pre-requisites

1. EC2 instance - `r8g.xlarge` and additional volume of 16 GiB
2. EC2 instance - `t4g.medium` to host the simulators.

## Steps - Demo

These steps are to be hosted on `r8g.large` instance to install the demo.

1. Clone repo.

```bash
git clone https://github.com/nsubrahm/demo.git
export PROJECT_HOME=$HOME/demo
cd demo
```

2. Set-up volume for PostgreSQL. Check `lsblk` output to confirm secondary volume exists.

```bash
cd ${PROJECT_HOME}/setup
for i in $(seq -w 1 10); do
  ./pg-vol-setup.sh org1 m0$i
done
```

3. Install Docker

```bash
cd ${PROJECT_HOME}/setup
sudo ./install-docker.sh
```

4. Generate general configuration.

```bash
export PROJECT_HOME=$HOME/demo
alias python=python3
cd ${PROJECT_HOME}
mkdir -p launch/conf/general
python scripts/main.py -f configs/config.json
```

5. Generate configuration for machines.

```bash
cd ${PROJECT_HOME}
for i in $(seq -w 1 10); do
  mkdir -p launch/conf/m0$i
  tools/config-gen.sh m0$i
  python scripts/main.py -f configs/m0$i.json -m m0$i
done
```

6. Login to GHCR.

```bash
docker login ghcr.io -u USERNAME
```

7. Launch infra-structure.

```bash
export CONF_DIR=general
source launch/conf/${CONF_DIR}/core.env && docker compose --env-file launch/conf/${CONF_DIR}/core.env -f launch/stacks/core.yaml up -d
source launch/conf/${CONF_DIR}/machines.env && docker compose --env-file launch/conf/${CONF_DIR}/machines.env -f launch/stacks/machines.yaml up -d
source launch/conf/${CONF_DIR}/base.env && docker compose --env-file launch/conf/${CONF_DIR}/base.env -f launch/stacks/base.yaml up -d
source launch/conf/${CONF_DIR}/gateway.env && docker compose --env-file launch/conf/${CONF_DIR}/gateway.env -f launch/stacks/gateway.yaml up -d
```

8. Launch applications for machines.

```bash
for i in $(seq -w 1 10); do
  export CONF_DIR=m0$i
  source launch/conf/${CONF_DIR}/init.env && docker compose --env-file launch/conf/${CONF_DIR}/init.env -f launch/stacks/init.yaml up -d
  source launch/conf/${CONF_DIR}/apps.env && docker compose --env-file launch/conf/${CONF_DIR}/apps.env -f launch/stacks/apps.yaml up -d
  sleep 5
done
```

## Steps - Simulator

These steps are to be hosted on `t4g.medium` instance to host the simulator.

1. Clone repo.

```bash
git clone https://github.com/nsubrahm/demo.git
export PROJECT_HOME=$HOME/demo
cd demo
```

2. Install Docker

```bash
cd ${PROJECT_HOME}/setup
sudo ./install-docker.sh
```

3. Login to GHCR.

```bash
docker login ghcr.io -u USERNAME
```

4. Generate client configuration. Set `HOST` to public IP address of EC2 instance that hosts the demo. The third argument is frequency and is set to 100ms by default.

```bash
cd ${PROJECT_HOME}
for i in $(seq -w 1 10); do
 tools/client-config.sh ${HOST} m0$i 100
done
```

5. Start simulators.

```bash
cd ${PROJECT_HOME}
for i in $(seq -w 1 10); do
 export MACHINE_ID=m0$i
 docker run --rm -d --name m0$i-simulator --env-file configs/m0$i.env ghcr.io/nsubrahm/restsim:latest
done
```

6. Stop simulators

```bash
for i in $(seq -w 1 10); do
 export MACHINE_ID=m0$i
 docker stop m0$i-simulator
done
```
