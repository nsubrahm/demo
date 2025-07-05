# Usage: ./client-config.sh <host> <machineId>
# Example: ./client-config.sh 13.203.65.68 m001

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <host> <machineId>"
  exit 1
fi

HOST="$1"
MACHINE_ID="$2"

cat <<EOF >"../configs/${MACHINE_ID}.env"
FREQUENCY=1000
BASE_URL=http://$HOST:80
MACHINE_ID=$MACHINE_ID
API_ENDPOINT=/data
TZ=Asia/Kolkata
EOF
echo "Config written to ../configs/${MACHINE_ID}.env"
