#!/bin/bash
source bin/common.sh

# No verbose for this script
saveVerbose=${VERBOSE}
unset VERBOSE

# mandatory arguments
ARGUMENTS=(type)
inputs "$@"
if [ "$?" -gt "0" ]
then
        return 255;
fi

URL=$baseURL/ComponentMetadata/query
JSON_FILE=json/queryComponentMetadataComponentType.json
REPORT_TITLE="List of $type Components"
REPORT_HEADERS=("#" "Name" "Component" "Component Type" "Created By" "Modified By" "FolderName" "Communication Option" "Contact Email")
queryToken="new"
createJSON

h=0;

printReportHead
while [ null != "${queryToken}" ] 
do
	callAPI
	if [ "$ERROR" -gt "0" ]
	then
  	break; 
	fi
	i=0;
	extractMap componentId ids
	extractMap name names
	extractMap type ctypes
	extractMap createdBy cbys
	extractMap modifiedBy mbys
	extractMap folderName fnames 

	while [ "$i" -lt "${#ids[@]}" ]; 
	do 
		h=$(( $h + 1 ));
                _id=${ids[$i]}
		bin/getComponent.sh componentId=${_id}
		sed -i 's/bns://g' out.xml
		email=$(cat out.xml | xmllint -xpath 'string(//ContactInfo/@email)' -)
		commOpt=$(cat out.xml | xmllint -xpath 'string(//CommunicationOption/@method)' -)
		printReportRow  "${h}" "${names[$i]}" "${ids[$i]}" "${ctypes[$i]}" "${cbys[$i]}" "${mbys[$i]}" "${fnames[$i]}" "$commOpt" "$email"	
		i=$(( $i + 1 )); 
	done
  	extract queryToken queryToken 	
	URL=$baseURL/Process/queryMore
done

printReportTail
clean
export VERBOSE=${saveVerbose}
if [ "$ERROR" -gt "0" ]
then
   return 255;
fi
