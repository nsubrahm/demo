# Usage: ./client-config.sh <host> <machineId>
# Example: ./client-config.sh 13.203.65.68 m001

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <host> <machineId> <frequency>"
  exit 1
fi

HOST="$1"
MACHINE_ID="$2"
FREQUENCY="$3"

cat <<EOF >"configs/${MACHINE_ID}.env"
FREQUENCY=$FREQUENCY
BASE_URL=http://$HOST:80
MACHINE_ID=$MACHINE_ID
API_ENDPOINT=/data
TZ=Asia/Kolkata
EOF
echo "Config written to configs/${MACHINE_ID}.env"
