# Introduction

This project documents steps to launch a demo with `NUM_MACHINES` machines.

- [Introduction](#introduction)
  - [Pre-requisites](#pre-requisites)
  - [Steps - Demo](#steps---demo)
  - [Configure machines and limits](#configure-machines-and-limits)
  - [Steps - Simulator](#steps---simulator)
  - [Clean-up - Simulators](#clean-up---simulators)
  - [Clean-up - Demo](#clean-up---demo)

## Pre-requisites

1. EC2 instance - `m7g.4xlarge` and additional volume of 16 GiB.
2. EC2 instance - `t4g.medium` to host the simulators.

## Steps - Demo

These steps are to be hosted on `r8g.large` instance to install the demo.

1. Clone repo.

```bash
git clone https://github.com/nsubrahm/demo.git
cd demo
chmod +x setup/*.sh
chmod +x tools/*.sh
# Set-up
alias python=python3
export NUM_MACHINES=10
export PROJECT_HOME=$HOME/demo
echo "alias python=python3" >> $HOME/.bashrc
echo "export NUM_MACHINES=10" >> $HOME/.bashrc
echo "export PROJECT_HOME=$HOME/demo" >> $HOME/.bashrc
```

2. Set-up volume for PostgreSQL. Check `lsblk` output to confirm secondary volume exists.

```bash
cd ${PROJECT_HOME}/setup
for i in $(seq -w 1 ${NUM_MACHINES}); do
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
cd ${PROJECT_HOME}
mkdir -p launch/conf/general
python scripts/main.py -f configs/config.json
```

5. Generate configuration for machines.

```bash
cd ${PROJECT_HOME}
for i in $(seq -w 1 ${NUM_MACHINES}); do
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
# Sleep so that KSQLDB is ready to accept connections
sleep 10
source launch/conf/${CONF_DIR}/machines.env && docker compose --env-file launch/conf/${CONF_DIR}/machines.env -f launch/stacks/machines.yaml up -d
source launch/conf/${CONF_DIR}/base.env && docker compose --env-file launch/conf/${CONF_DIR}/base.env -f launch/stacks/base.yaml up -d
source launch/conf/${CONF_DIR}/gateway.env && docker compose --env-file launch/conf/${CONF_DIR}/gateway.env -f launch/stacks/gateway.yaml up -d
```

8. Launch applications for machines.

```bash
for i in $(seq -w 1 ${NUM_MACHINES}); do
  export CONF_DIR=m0$i
  source launch/conf/${CONF_DIR}/init.env && docker compose --env-file launch/conf/${CONF_DIR}/init.env -f launch/stacks/init.yaml up -d
  source launch/conf/${CONF_DIR}/apps.env && docker compose --env-file launch/conf/${CONF_DIR}/apps.env -f launch/stacks/apps.yaml up -d
  sleep 5
done
```

9. Set-up folder for logs of ML jobs.

```bash
mkdir -p launch/batch/logs
```

10. Add the following `cron` entry for as many machines that were launched.

```bash
0 */8 * * * $HOME/launcher/launch/batch/mljobs.sh m001 latest
0 */8 * * * $HOME/launcher/launch/batch/mljobs.sh m002 latest
0 */8 * * * $HOME/launcher/launch/batch/mljobs.sh m003 latest
0 */8 * * * $HOME/launcher/launch/batch/mljobs.sh m004 latest
0 */8 * * * $HOME/launcher/launch/batch/mljobs.sh m005 latest
0 */8 * * * $HOME/launcher/launch/batch/mljobs.sh m006 latest
0 */8 * * * $HOME/launcher/launch/batch/mljobs.sh m007 latest
0 */8 * * * $HOME/launcher/launch/batch/mljobs.sh m008 latest
0 */8 * * * $HOME/launcher/launch/batch/mljobs.sh m009 latest
0 */8 * * * $HOME/launcher/launch/batch/mljobs.sh m010 latest
```

## Configure machines and limits

1. Launch a container with `alpine` image.

```bash
docker run --name kcat -it --network mitra alpine
```

2. Install Kafka CLI.

```bash
apk add kcat
```

3. Add machines.

```bash
kcat -b broker:29092 -t machines_master -K: -P <<EOF
m001:{"meta":{"id":"7693f39a-7898-466f-968e-7868db1b3bd2","ts":"2025-07-10T18:44:28.235","type":"machine"},"machine":{"machineId":"m002","label":"LINE01-MILL02","description":"Milling Machine 1 - Line 1"}}
m002:{"meta":{"id":"7693f39a-7898-466f-968e-7868db1b3bd2","ts":"2025-07-10T18:44:28.235","type":"machine"},"machine":{"machineId":"m002","label":"LINE01-MILL02","description":"Milling Machine 2 - Line 1"}}
m003:{"meta":{"id":"6b346b7e-a56a-40b1-866b-b5144bce890b","ts":"2025-07-10T18:44:29.235","type":"machine"},"machine":{"machineId":"m003","label":"LINE01-MILL03","description":"Milling Machine 3 - Line 1"}}
m004:{"meta":{"id":"128f0e34-ab91-49ad-b6df-557d5fa34ff1","ts":"2025-07-10T18:44:30.235","type":"machine"},"machine":{"machineId":"m004","label":"LINE01-MILL04","description":"Milling Machine 4 - Line 1"}}
m005:{"meta":{"id":"17163219-09fe-4ef0-849a-6974997d72aa","ts":"2025-07-10T18:44:31.235","type":"machine"},"machine":{"machineId":"m005","label":"LINE01-MILL05","description":"Milling Machine 5 - Line 1"}}
m006:{"meta":{"id":"c4a78e28-f62c-4386-aba6-81660c68e9ef","ts":"2025-07-10T18:44:32.235","type":"machine"},"machine":{"machineId":"m006","label":"LINE01-MILL06","description":"Milling Machine 6 - Line 1"}}
m007:{"meta":{"id":"da9348a5-3556-41b6-98d1-696dfac8e379","ts":"2025-07-10T18:44:33.235","type":"machine"},"machine":{"machineId":"m007","label":"LINE01-MILL07","description":"Milling Machine 7 - Line 1"}}
m008:{"meta":{"id":"9c16910e-46c7-41f5-a47a-9a472bd2dc8d","ts":"2025-07-10T18:44:34.235","type":"machine"},"machine":{"machineId":"m008","label":"LINE01-MILL08","description":"Milling Machine 8 - Line 1"}}
m009:{"meta":{"id":"6028cf32-21e8-4189-90cb-aa8e13651635","ts":"2025-07-10T18:44:35.235","type":"machine"},"machine":{"machineId":"m009","label":"LINE01-MILL09","description":"Milling Machine 9 - Line 1"}}
m010:{"meta":{"id":"bc66aa49-435a-4967-8269-2c47966b2eb5","ts":"2025-07-10T18:44:36.235","type":"machine"},"machine":{"machineId":"m010","label":"LINE01-MILL10","description":"Milling Machine 10 - Line 1"}}
EOF
```

4. Configure limits for each machine by changing `machineId` from `m001` to `m010`.

```bash
kcat -b broker:29092 -t machineId_limits -K: -P <<EOF
spindleLoad:{"meta":{"id":"1","ts":"2023-12-27T22:53:00.000"}, "limits":[{"key":"spindleLoad", "lo":0, "hi":50}]}
spindleTemperature:{"meta":{"id":"2","ts":"2023-12-27T22:53:00.000"}, "limits":[{"key":"spindleTemperature", "lo":1,"hi":150}]}
spindleMotorCurrent:{"meta":{"id":"3","ts":"2023-12-27T22:53:00.000"}, "limits":[{"key":"spindleMotorCurrent", "lo":2,"hi":8}]}
spindleMotorVoltage:{"meta":{"id":"4","ts":"2023-12-27T22:53:00.000"}, "limits":[{"key":"spindleMotorVoltage", "lo":10,"hi":25}]}
spindleSpeed:{"meta":{"id":"5","ts":"2023-12-27T22:53:00.000"}, "limits":[{"key":"spindleSpeed", "lo":0,"hi":20000}]}
EOF
```

## Steps - Simulator

These steps are to be hosted on `t4g.medium` instance to host the simulator.

1. Clone repo.

```bash
git clone https://github.com/nsubrahm/demo.git
cd demo
chmod +x setup/*.sh
chmod +x tools/*.sh
# Set-up
export NUM_MACHINES=10
export PROJECT_HOME=$HOME/demo
echo "export NUM_MACHINES=10" >> $HOME/.bashrc
echo "export PROJECT_HOME=$HOME/demo" >> $HOME/.bashrc
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

4. Generate client configuration. Set `HOST` to public IP address of EC2 instance that hosts the demo. The third argument is frequency and is set to `1000ms` by default.

```bash
cd ${PROJECT_HOME}
for i in $(seq -w 1 ${NUM_MACHINES}); do
  tools/client-config.sh ${HOST} m0$i 1000
done
```

5. Start simulators.

```bash
cd ${PROJECT_HOME}
for i in $(seq -w 1 ${NUM_MACHINES}); do
  export MACHINE_ID=m0$i
  docker run --rm -d --name m0$i-simulator --env-file configs/m0$i.env ghcr.io/nsubrahm/restsim:latest
  sleep 5
done
```

## Clean-up - Simulators

1. Stop all running simulators.

```bash
for i in $(seq -w 1 ${NUM_MACHINES}); do
  export MACHINE_ID=m0$i
  docker stop m0$i-simulator
done
```

## Clean-up - Demo

1. Stop all running applications.

```bash
for i in $(seq -w 1 ${NUM_MACHINES}); do
  export CONF_DIR=m0$i
  source launch/conf/${CONF_DIR}/init.env && docker compose --env-file launch/conf/${CONF_DIR}/init.env -f launch/stacks/init.yaml down
  source launch/conf/${CONF_DIR}/apps.env && docker compose --env-file launch/conf/${CONF_DIR}/apps.env -f launch/stacks/apps.yaml down
done
```

2. Shut-down infra-structure.

```bash
export CONF_DIR=general
source launch/conf/${CONF_DIR}/core.env && docker compose --env-file launch/conf/${CONF_DIR}/core.env -f launch/stacks/core.yaml down
source launch/conf/${CONF_DIR}/machines.env && docker compose --env-file launch/conf/${CONF_DIR}/machines.env -f launch/stacks/machines.yaml down
source launch/conf/${CONF_DIR}/base.env && docker compose --env-file launch/conf/${CONF_DIR}/base.env -f launch/stacks/base.yaml down
source launch/conf/${CONF_DIR}/gateway.env && docker compose --env-file launch/conf/${CONF_DIR}/gateway.env -f launch/stacks/gateway.yaml down
# Remove network
docker network rm mitra
```
