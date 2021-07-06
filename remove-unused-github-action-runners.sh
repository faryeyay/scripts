#/bin/bash 

set -e 

runner_scope=${1}

echo "Deleting runner @ ${runner_scope}"

function fatal()
{
   echo "error: $1" >&2
   exit 1
}

if [ -z "${runner_scope}" ]; then fatal "supply scope as argument 1"; fi
if [ -z "${RUNNER_CFG_PAT}" ]; then fatal "RUNNER_CFG_PAT must be set before calling"; fi

which curl || fatal "curl required.  Please install in PATH with apt-get, brew, etc"
which jq || fatal "jq required.  Please install in PATH with apt-get, brew, etc"

base_api_url="https://api.github.com/orgs"
if [[ "$runner_scope" == *\/* ]]; then
    base_api_url="https://api.github.com/repos"
fi

RUNNER_INSTANCES=$(curl -X GET -s -H "Authorization: Bearer $RUNNER_CFG_PAT" -H "Accept: application/vnd.github.v3+json" ${base_api_url}/${runner_scope}/actions/runners | jq '.runners[] | select( .status | contains("offline")) | @base64' | tr -d '" ')

#--------------------------------------
# Cycle through the instances to remove them
#--------------------------------------
for instance in $RUNNER_INSTANCES; do 
	INSTANCE_ID=$(echo $instance | base64 --decode | jq -r '.id')
	INSTANCE_NAME=$(echo $instance | base64 --decode | jq -r '.name')

	echo "Removing $INSTANCE_NAME with id $INSTANCE_ID"
	#--------------------------------------
	# Remove the runner
	#--------------------------------------
	curl -s -X DELETE ${base_api_url}/${runner_scope}/actions/runners/${INSTANCE_ID} -H "authorization: token ${RUNNER_CFG_PAT}"
done

echo "The script is complete. Done."
