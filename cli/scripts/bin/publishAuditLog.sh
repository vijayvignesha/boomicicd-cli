#!/bin/bash
source bin/common.sh
# No verbose of this script
saveVerbose=${VERBOSE}
unset VERBOSE
unset ERROR
# mandatory arguments
ARGUMENTS=(atomNames)
OPT_ARGUMENTS=(from to)
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


# default status to fetch is ERROR to prevent overload
if [ -z "${status}" ]
then
	export status="ERROR" 
fi


h=0;
REPORT_TITLE="Audit Report  between $from and $to."
REPORT_HEADERS=("#" "Atom Name" "User Id" "Message" "Date" "Type" "Action" "Modifier" "level" "Source" "AuditLog" )
printReportHead

IFS=',' ; for _atomName in $(echo "$atomNames");
do
	# get atomId from atomName
	source bin/queryAtom.sh atomName="${_atomName}"
	URL=$baseURL/AuditLog/query
	JSON_FILE=json/queryAuditLog.json

	ARGUMENTS=(atomId to from)
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
  		extractMap userId userIds	
		extractMap message messages
  		extractMap date   dates	
		extractMap type types
		extractMap action actions
  		extractMap modifier modifiers	
  		extractMap level levels	
  		extractMap source sources	
		while [ "$i" -lt "${#userIds[@]}" ];
		do 
			h=$(( $h + 1 ))
			time=${durations[$i]};
			auditLog=$(jq -r --arg index $i '.result[$index | tonumber].AuditLogProperty[] | [.name,.value] | join(": ") | tostring + "|"' "${WORKSPACE}/out.json" | sed -e 's/</\&lt;/g'  -e 's/>/\&gt;/g' -e 's/|/<br\/>/g' | grep -v SESSION_ID)
			printReportRow  "${h}" "${_atomName}" "${userIds[$i]}" "${messages[$i]}" "${dates[$i]}" "${types[$i]}" "${actions[$i]}" "${modifiers[$i]}" "${levels[$i]}" "${sources[$i]}" "${auditLog}" 
			i=$(( $i + 1 )); 
  		done
		extract queryToken queryToken 
		URL=$baseURL/ExecutionSummaryRecord/queryMore
	done
done
printReportTail
clean
export VERBOSE=${saveVerbose}

if [ "$ERROR" -gt "0" ]
then
   return 255;
fi
