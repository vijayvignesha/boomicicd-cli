#!/bin/bash
source bin/common.sh
# No verbose of this script
saveVerbose=${VERBOSE}
unset VERBOSE
unset ERROR
# mandatory arguments
ARGUMENTS=(atomNames)
inputs "$@"

if [ "$?" -gt "0" ]
then
        return 255;
fi


h=0;
REPORT_TITLE="Summary of process schedule status."
REPORT_HEADERS=("#" "Atom Name" "Process Name" "Enabled" "Schedule")
printReportHead

IFS=',' ; for _atomName in $(echo "$atomNames");
do
	# get atomId from atomName
	atomName1="${_atomName}"
	source bin/queryAtom.sh atomName="${_atomName}"
	URL=$baseURL/ProcessScheduleStatus/query
	JSON_FILE=json/publishScheduleStatus.json

	
	ARGUMENTS=(atomId)
	createJSON
	queryToken="new"


	while [ null != "${queryToken}" ];
	do
		callAPI
		if [ "$ERROR" -gt "0" ]
			then
  		break;
		fi
		ii=0;
  		extractMap processId processIds	
  		extractMap enabled statuses
		extractMap id ids	
		extract queryToken queryToken 
		while [ "$ii" -lt "${#processIds[@]}" ];
		do 
			h=$(( $h + 1 ))
			componentId=${processIds[$ii]}
			source bin/queryComponentMetadata.sh componentId=${componentId}
			id=${ids[$ii]}
			schedule=$(curl -s -X GET -u $authToken -H "${h1}" -H "${h2}" $baseURL/ProcessSchedules/$id | jq -r .Schedule)		
			printReportRow  "${h}" "${atomName1}" "${componentName}" "${statuses[$ii]}" "$schedule" 
			ii=$(( $ii + 1 )); 
  		done
		URL=$baseURL/ProcessScheduleStatus/queryMore
	done
done
printReportTail
clean
export VERBOSE=${saveVerbose}
