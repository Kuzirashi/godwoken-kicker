#!/bin/bash

set -o errexit
set -o xtrace
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ "$MANUAL_BUILD_WEB3" = true ] ; then 
  echo "manual mode.."
  cd /code/godwoken-web3
else
  echo "prebuild mode.."
  cd /godwoken-web3
fi

# read eth_lock_hash from json config file
LOCKSCRIPTS=${PROJECT_DIR}/godwoken/deploy/scripts-deploy-result.json

# wait for godwoken finished its deployment
while true; do
    sleep 3;
    if [[ -f "$LOCKSCRIPTS" ]]; then
      echo 'scripts-deploy-result.json file exits. continue.'
      break
    else
      echo 'scripts-deploy-result.json file not exits, keep waitting for godwoken deployment.'
    fi
done
EthAccountLockCodeHash=$(jq -r '.eth_account_lock.script_type_hash' $LOCKSCRIPTS)

# read rollup type hash from config.toml file
CONFIGTOML=${PROJECT_DIR}/godwoken/config.toml
# wait for godwoken finished generating config.toml file
while true; do
    sleep 3;
    if [[ -f "$CONFIGTOML" ]]; then
      echo 'config.toml file exits. continue.'
      break
    else
      echo 'config.toml file not exits, keep waitting for godwoken generating config.'
    fi
done
RollupTypeHash=$(awk -F'[ ="]+' '$1 == "rollup_type_hash" { print $2 }' $CONFIGTOML | sed 's/\x27//g')

cat > ./packages/api-server/.env <<EOF
DATABASE_URL=postgres://user:password@postgres:5432/lumos
GODWOKEN_JSON_RPC=http://godwoken:8119
ETH_ACCOUNT_LOCK_HASH=$EthAccountLockCodeHash
ROLLUP_TYPE_HASH=$RollupTypeHash
PORT=8024
CREATOR_ACCOUNT_ID=3
EOF

# start web3 server
yarn workspace @godwoken-web3/api-server start
