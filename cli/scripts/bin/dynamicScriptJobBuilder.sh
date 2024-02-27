#!/bin/bash
set -xe
# Sample code to recursively invoke Boomi scripts based on a configuration file 
source bin/common.sh
# Get the file name and the job envirnoment.

ARGUMENTS=(file env)
inputs "$@"
if [ "$?" -gt "0" ]
then
        return 255;
fi


# This is the name of the stage or environment for this script. This is required to prevent a job in Development stage run in production
JOB_ENV="${env}"
unset env

fileName=$(echo "${file}" | sed -e 's/^.*\///g' -e 's/\.conf.*$//g')
echoi "Executing configurations for file ${file}."

count=1
 for row in $(cat "${file}" | jq -r '.pipelines[] | @base64');
  do
   
   json=$(echo ${row} | base64 --decode | jq -r 'to_entries' | jq --arg count "$count" '. + [{"key": "count", "value": $count}]') 
   echoi "Json is $json."
   job=$(echo $json | jq -r '.[] |  select(.key | contains("job")).value')
    echoi "Job is $job."
	 
	  # Automatically tag azure build info in Boomi deployment notes 
	   if [[ ! -z "${BUILD_BUILDNUMBER}" ]]
	   then
	    notes=$(echo $json | jq -r '.[] |  select(.key | contains("notes")).value')
     	notes="${BUILD_PROJECTNAME}_${RELEASE_RELEASENAME}_${BUILD_BUILDNUMBER}: ${notes}"
     	json=$(echo ${json} | jq --arg notes "$notes" '. + [{"key": "notes", "value": $notes}]')
	   fi
 
     env="${JOB_ENV}"
     json=$(echo ${json} | jq --arg env "$env" '. + [{"key": "env", "value": $env}]')
     call_script "${job}" "${json}"
     count=$(( count + 1 ))
 done
