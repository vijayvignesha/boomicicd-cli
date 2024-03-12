#!/bin/bash
source bin/common.sh

# mandatory arguments
ARGUMENTS=(packageVersion notes) 
OPT_ARGUMENTS=(componentIds processNames extractComponentXmlFolder tag componentType)
inputs "$@"
if [ "$?" -gt "0" ]
then
    return 255;
fi

if [ ! -z "${extractComponentXmlFolder}" ]
then
 folder="${WORKSPACE}/${extractComponentXmlFolder}"
 rm -rf ${folder}
 unset extensionJson
 saveExtractComponentXmlFolder="${extractComponentXmlFolder}"
fi

saveNotes="${notes}"
savePackageVersion="${packageVersion}"
saveComponentType="${componentType}"

packageIds=""
saveTag="${tag}"
unset tag
if [ -z "${componentIds}" ]
then
	IFS=',' ;for processName in `echo "${processNames}"`; 
	do 
	notes="${saveNotes}"
    packageVersion="${savePackageVersion}"
    processName=`echo "${processName}" | xargs`
    saveProcessName="${processName}"
	componentType="${saveComponentType}"
	source bin/createSinglePackage.sh processName="${processName}" componentType="${componentType}" packageVersion="${packageVersion}" notes="${notes}" extractComponentXmlFolder="${extractComponentXmlFolder}"  componentVersion=""
	if [ -z "$packageId" ]
	then
		echoe "Create package component for ${saveProcessName} is not successful aborting mission."
	 	exit 255;
	fi
 	done   
else    
	IFS=',' ;for componentId in `echo "${componentIds}"`; 
	do 
	notes="${saveNotes}"
   	packageVersion="${savePackageVersion}"
    componentId=`echo "${componentId}" | xargs`
    saveComponentId="${componentId}"
	componentType="${saveComponentType}"
	source bin/createSinglePackage.sh componentId=${componentId} componentType="${componentType}" packageVersion="${packageVersion}" notes="${notes}" extractComponentXmlFolder="${extractComponentXmlFolder}"  componentVersion=""
	if [ -z "$packageId" ]
	then
		echoe "Create package component for ${saveComponentId} is not successful aborting mission."
		exit 255;
	fi	
 	done   
fi  



# Tag all the packages of the release together
handleXmlComponents "${saveExtractComponentXmlFolder}" "${saveTag}" "${saveNotes}"

clean

if [ "$ERROR" -gt 0 ]
then
   return 255;
fi
