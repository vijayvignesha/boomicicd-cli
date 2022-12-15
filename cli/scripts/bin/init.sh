#!/bin/bash

source bin/common.sh
# get atom id of the by atom name
# mandatory arguments

ARGUMENTS=(atomName env accountId)
OPT_ARGUMENTS=(proxyHost proxyPort proxyUser proxyPassword installDir workDir tmpDir javaHome jreHome atomType purgeHistoryDays roleName forceRestartMillisec maxMem apiType apiAuth sharedWebURL classification serviceUserName mountPoint)

inputs "$@"

if [ "$?" -gt "0" ]
then
       return 255;
fi

export h1="Content-Type: application/json"
export h2="Accept: application/json"
export WORKSPACE=`pwd`
# Keys that can change
export VERBOSE="false" # Bash verbose output; set to true only for testing, will slow execution.
export SLEEP_TIMER=0.2 # Delays curl request to the platform to set the rate under 5 requests/second
# Derived keys
export baseURL=https://api.boomi.com/api/rest/v1/$accountId

if [ -z "${installDir}" ]
then
      export installDir=/mnt/boomi 
fi

if [ -z "${workDir}" ]
then
     export workDir=/usr/local/boomi/work 
fi

if [ -z "${jreHome}" ]
then
     export jreHome=/usr/lib/jvm/jre 
fi

if [ -z "${javaHome}" ]
then
     export javaHome=/usr/bin/java 
fi

if [ -z "${tmpDir}" ]
then
     export tmpDir=/usr/local/boomi/tmp 
fi

if [ -z "${atomType}" ]
then
     export atomType="ATOM" # ATOM, MOLECULE, CLOUD 
fi

if [ -z "${purgeHistoryDays}" ]
then
     export purgeHistoryDays="14"  
fi

if [ -z "${roleName}" ]
then
     export roleName="Administrator" 
fi

if [ -z "${forceRestartMillisec}" ]
then
   export forceRestartMillisec=300000	
fi

if [ -z "${maxMex}" ]
then
     export maxMem=4g 
fi

if [ -z "${apiType}" ]
then
     export apiType="advanced" 
fi

if [ -z "${apiAuth}" ]
then
     export apiAuth=basic 
fi

if [ -z "${sharedWebURL}" ]
then
     export sharedWebURL="https:\/\/not-set\.com"
fi

if [ -z "${classification}" ]
then
     export classification="TEST" # Env classification TEST, PRODD 
fi

if [ -z "${serviceUserName}" ]
then
     export serviceUserName="boomi"  
fi

if [ -z "${mountPoint}" ]
then
     export mountPoint="/mnt/efs" # Env classification TEST, PRODD 
fi

if [ "$?" -gt "0" ]
then
       return 255;
fi

source bin/installBoomi.sh
sudo bin/installBoomiService.sh atomName=${atomName} atomHome=${ATOM_HOME} serviceUserName=${serviceUserName} mountPoint=${mountPoint}

