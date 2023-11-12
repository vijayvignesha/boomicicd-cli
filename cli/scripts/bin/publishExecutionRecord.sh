#!/bin/bash
source bin/common.sh
# No verbose of this script
saveVerbose=${VERBOSE}
unset VERBOSE
unset ERROR
# mandatory arguments
ARGUMENTS=(atomNames)
OPT_ARGUMENTS=(processName from to status message)
inputs "$@"

if [ "$?" -gt "0" ]
then
        return 255;
fi

# default get 60 mins of history
export TZ='UTC'
now=`date +"%Y-%m-%d"T%H:%M:%SZ --date '+2 min'`
lag=`date +"%Y-%m-%d"T%H:%M:%SZ --date '-60 min'`

if [ -z "${to}" ]
then
	export to=$now
fi

if [ -z "${from}" ]
then
	export from=$lag
fi

if [ -z "${processName}" ]
then
	export processName="%%"
fi

# default status to fetch is ERROR to prevent overload
if [ -z "${status}" ]
then
	export status="ERROR" 
fi


h=0;
REPORT_TITLE="Summary of process executions between $from and $to."
REPORT_HEADERS=("#" "Atom Name" "Process Name" "Execution Type" "Execution Time" "NodeID" "Execution ID" "Duration(s)" "Status" "Message")
printReportHead

IFS=',' ; for _atomName in $(echo "$atomNames");
do
	# get atomId from atomName
	source bin/queryAtom.sh atomName="${_atomName}"
	URL=$baseURL/ExecutionRecord/query
	JSON_FILE=json/publishExecutionRecordWithMessage.json

	if [ -z "${message}" ]
	then
       		export message="%%"
       		JSON_FILE=json/publishExecutionRecord.json
	fi
	
	ARGUMENTS=(atomId to from processName status message)
	createJSON
	queryToken="new"


	while [ null != "${queryToken}" ];
	do
		callAPI
		if [ "$ERROR" -gt "0" ]
			then
  		break;
		fi
		i=0;
  		extractMap processName processNames	
  		extractMap atomName    atomNames	
  		extractMap nodeId    nodes	
  		extractMap executionDuration[1] durations	
		extractMap status statuses
		extractMap message messages
		extractMap executionTime times
		extractMap executionId eIds
		extractMap executionType types
		while [ "$i" -lt "${#durations[@]}" ];
		do 
			h=$(( $h + 1 ))
			time=${durations[$i]};
			printReportRow  "${h}" "${atomNames[$i]}" "${processNames[$i]}" "${types[$i]}" "${times[$i]}" "${nodes[$i]}" "${eIds[$i]}" "$((time / 1000))" "${statuses[$i]}" "${messages[$i]}"
			i=$(( $i + 1 )); 
  		done
		extract queryToken queryToken 
		URL=$baseURL/ExecutionRecord/queryMore
	done
done
printReportTail
clean
export VERBOSE=${saveVerbose}
