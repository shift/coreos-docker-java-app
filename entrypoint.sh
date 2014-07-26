#!/bin/bash
# Argument = -h -v -i groupId:artifactId:version -c classifier -p packaging -r repository -n nexus_base -s app_entrypoint -w user:pass
set -x 
#shopt -o -s xtrace
 
# Define Nexus Configuration
NEXUS_BASE=
REST_PATH=/service/local
ART_REDIR=/artifact/maven/redirect
 
usage()
{
cat <<EOF
 
usage: $0 options
 
This script will fetch an artifact from a Nexus server using the Nexus REST redirect service.
 
OPTIONS:
   -h      Show this message
   -v      Verbose
   -n      Nexus base URI
   -i      GAV coordinate groupId:artifactId:version
   -c      Artifact Classifier
   -p      Artifact Packaging
   -s      Entrypoint start command for your application
 
EOF
}
 
# Read in Complete Set of Coordinates from the Command Line
GROUP_ID=
ARTIFACT_ID=
VERSION=
CLASSIFIER=""
PACKAGING=war
REPO=
VERBOSE=0
 
while getopts "hvi:c:p:n:s:w:e:" OPTION
do
     case $OPTION in
         e)
             if [[ "$OPTARG" == "sure" ]]
             then
               rm -rf /opt/application
             fi
             exit 0
             ;;
         h)
             usage
             exit 1
             ;;
         n)
             NEXUS_BASE=$OPTARG
             ;;
         w)
             AUTH=$OPTARG
             ;;
         i)
	     OIFS=$IFS
             IFS=":"
	     GAV_COORD=( $OPTARG )
	     GROUP_ID=${GAV_COORD[0]}
             ARTIFACT_ID=${GAV_COORD[1]}
             VERSION=${GAV_COORD[2]}	     
	     IFS=$OIFS
             ;;
         c)
             CLASSIFIER=$OPTARG
             ;;
         p)
             PACKAGING=$OPTARG
             ;;
         s)
             APP_ENTRYPOINT=$OPTARG
             ;;
         v)
             VERBOSE=1
             ;;
         ?)
             usage
             exit
             ;;
     esac
done
 
if [[ -z $GROUP_ID ]] || [[ -z $ARTIFACT_ID ]] || [[ -z $VERSION ]]
then
     echo "BAD ARGUMENTS: Either groupId, artifactId, or version was not supplied" >&2
     usage
     exit 1
fi

if [[ -z $AUTH ]]
then
  CURL_OPTS=""
else
  CURL_OPTS="-u $AUTH"
fi
 
# Define default values for optional components
 
# If the version requested is a SNAPSHOT use snapshots, otherwise use releases
if [[ "$VERSION" =~ ".*SNAPSHOT" ]]
then
    : ${REPO:="snapshots"}
else
    : ${REPO:="releases"}
fi
 
# Construct the base URL
REDIRECT_URL=${NEXUS_BASE}${REST_PATH}${ART_REDIR}
 
# Generate the list of parameters
PARAM_KEYS=( g a v r p c s )
PARAM_VALUES=( $GROUP_ID $ARTIFACT_ID $VERSION $REPO $PACKAGING $CLASSIFIER )
PARAMS=""
for index in ${!PARAM_KEYS[*]} 
do
  if [[ ${PARAM_VALUES[$index]} != "" ]]
  then
    PARAMS="${PARAMS}${PARAM_KEYS[$index]}=${PARAM_VALUES[$index]}&"
  fi
done
 
REDIRECT_URL="${REDIRECT_URL}?${PARAMS}"

mkdir -p /opt/application/{artifact,runtime}
cd /opt/application/artifact
OUTPUT_NAME=
echo "Packaging: $PACKAGING"
case "$PACKAGING" in
    war)
        OUTPUT_NAME=artifact.war
        UNPACK=unzip 
        ;;
    tar.gz)
        OUTPUT_NAME=artifact.tar.gz
        UNPACK=tar xfvz
        ;;
    tar.bz2)
        OUTPUT_NAME=artifact.tar.gz
        UNPACK=tar xfvj
        ;;
    zip)
        OUTPUT_NAME=artifact.zip
        UNPACK=unzip
        ;;
    jar)
        OUTPUT_NAME=artifact.jar
        UNPACK="ln -s /opt/application/artifact/$OUTPUT_NAME"
esac


echo "Fetching Artifact from $REDIRECT_URL..." >&2
echo "Writing to $OUTPUT_NAME..." >&2

curl $CURL_OPTS -L ${REDIRECT_URL} -o ${OUTPUT_NAME}

cd ../runtime
echo "Unpacking Artifact with ${UNPACK}."
$UNPACK /opt/application/artifact/${OUTPUT_NAME}

echo "Starting application with ${APP_ENTRYPOINT}"
exec ${APP_ENTRYPOINT}
