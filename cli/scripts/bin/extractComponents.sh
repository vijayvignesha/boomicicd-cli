#!/bin/bash
source bin/common.sh

# mandatory arguments
ARGUMENTS=(extractComponentXmlFolder) 
OPT_ARGUMENTS=(componentIds componentNames componentType)
inputs "$@"
if [ "$?" -gt "0" ]
then
    return 255;
fi

folder="${WORKSPACE}/${extractComponentXmlFolder}"
rm -rf "${folder}"
mkdir -p "${folder}"
saveExtractComponentXmlFolder="${extractComponentXmlFolder}"


if [[ -z "${componentIds}" ]] && [[ -z "${componentNames}" ]]
then
    echoe "Component Ids or Component Names must be preset"
    exit 255;
fi

if [[ -z "${componentType}" ]]
then
    componentType="process"
fi
saveComponentType="${componentType}"


if [ -z "${componentIds}" ]
then
	IFS=',' ;for componentName in `echo "${componentNames}"`; 
	do 
        saveComponentName="${componentName}"
		componentType="${saveComponentType}"
		source bin/queryComponentMetadata.sh componentType="$componentType" componentName="$componentName"
		bin/getComponent.sh 
		mv "${WORKSPACE}/${componentId}.xml" "${folder}/${componentId}.xml"
    done   
else    
	IFS=',' ;for componentId in `echo "${componentIds}"`; 
	do 
		componentId=`echo "${componentId}" | xargs`
        saveComponentId="${componentId}"
		componentType="${saveComponentType}"
		source bin/queryComponentMetadata.sh componentType="$componentType" componentName="$componentName"
		bin/getComponent.sh 
		mv "${WORKSPACE}/${componentId}.xml" "${folder}/${componentId}.xml"

 	done   
fi  

find "$saveExtractComponentXmlFolder" -type f -name "*.xml" -exec sed -i 's/bns://g' {} \;

clean

if [ "$ERROR" -gt 0 ]
then
   return 255;
fi
