#!/bin/bash

atomType="ATOM"
env=
classification=TEST
atomName=


# for shared web URL
sharedWebURL="https:\/\/url.com"
apiType=advanced
apiAuth=basic

# for cloud molecule
cloudId=

maxMem=4g

# 5 mins = 300000ms
forceRestartMillisec=300000
roleName=Administrator
purgeHistoryDays=14
TMP_DIR=/usr/local/boomi/tmp
WORK_DIR=/usr/local/boomi/work
JAVA_HOME=/usr/bin/java
JRE_HOME=/usr/lib/jvm/jre
INSTALL_DIR=/mnt/efs/boomi/

# optional leave blank
proxyHost=
proxyPort=
proxyUser=
proxyPassword=


if [[ "$atomType" = "ATOM" ]]
	then
		# install atom on the local drive 
		INSTALL_DIR=/usr/local/boomi/
		ATOM_HOME=${INSTALL_DIR}/Atom_${atomName}
		if [[ -d "${ATOM_HOME}" ]]
		then
			echo "${ATOM_HOME} exits. Will stop installation."
			exit 0
        fi
			
		source bin/installerToken.sh atomType=${atomType}
		./bin/installAtom.sh atomName="${atomName}" tokenId="${tokenId}" INSTALL_DIR="${INSTALL_DIR}" JRE_HOME="${JRE_HOME}" JAVA_HOME="${JAVA_HOME}" proxyHost="${proxyHost}" proxyPort="${proxyPort}" proxyUser="${proxyUser}" proxyPassword="${proxyPassword}"
		source bin/createEnvAndAttachRoleAndAtom.sh env="${env}" classification=${classification} atomName="${atomName}" roleName="${roleName}" purgeHistoryDays="${purgeHistoryDays}" 
		source bin/updateSharedServer.sh atomName="${atomName}" overrideUrl=true url="${sharedWebURL}" apiType="${apiType}" auth="${apiAuth}"

	elif [[ "$atomType" = "CLOUD" ]]
	then
		ATOM_HOME=${INSTALL_DIR}/Cloud_${atomName}
		if [[ -d "${ATOM_HOME}" ]]
		then
			echo "${ATOM_HOME} exits. Will stop installation."
			exit 0
        fi
		
		source bin/installerToken.sh atomType=${atomType} cloudId=$cloudId
		./bin/installCloud.sh atomName="${atomName}" tokenId="${tokenId}" INSTALL_DIR="${INSTALL_DIR}" WORK_DIR="${WORK_DIR}" TMP_DIR="${TMP_DIR}" JRE_HOME="${JRE_HOME}" JAVA_HOME="${JAVA_HOME}" proxyHost="${proxyHost}" proxyPort="${proxyPort}" proxyUser="${proxyUser}" proxyPassword="${proxyPassword}"
		source bin/updateSharedServer.sh atomName="${atomName}" overrideUrl=true url="${sharedWebURL}" apiType="${apiType}" auth="${apiAuth}"		
		
	elif [[ "$atomType" = "BROKER" ]]
	then
		ATOM_HOME=${INSTALL_DIR}/Broker_${atomName}
		if [[ -d "${ATOM_HOME}" ]]
		then
			echo "${ATOM_HOME} exits. Will stop installation."
			exit 0
        fi
		
		source bin/installerToken.sh atomType=${atomType}
		./bin/installBroker.sh atomName="${atomName}" tokenId="${tokenId}" INSTALL_DIR="${INSTALL_DIR}" WORK_DIR="${WORK_DIR}" TMP_DIR="${TMP_DIR}" JRE_HOME="${JRE_HOME}" JAVA_HOME="${JAVA_HOME}" proxyHost="${proxyHost}" proxyPort="${proxyPort}" proxyUser="${proxyUser}" proxyPassword="${proxyPassword}"
		
	elif [[ "$atomType" = "GATEWAY" ]]
	then
		ATOM_HOME=${INSTALL_DIR}/Gateway_${atomName}
		if [[ -d "${ATOM_HOME}" ]]
		then
			echo "${ATOM_HOME} exits. Will stop installation."
			exit 0
        fi
		
		source bin/installerToken.sh atomType=${atomType}
		./bin/installGateway.sh atomName="${atomName}" tokenId="${tokenId}" INSTALL_DIR="${INSTALL_DIR}" WORK_DIR="${WORK_DIR}" TMP_DIR="${TMP_DIR}" JRE_HOME="${JRE_HOME}" JAVA_HOME="${JAVA_HOME}" proxyHost="${proxyHost}" proxyPort="${proxyPort}" proxyUser="${proxyUser}" proxyPassword="${proxyPassword}"

	elif [[ "$atomType" = "MOLECULE" ]]
	then	
		ATOM_HOME=${INSTALL_DIR}/Molecule_${atomName}
		if [[ -d "${ATOM_HOME}" ]]
		then
			echo "${ATOM_HOME} exits. Will stop installation."
			exit 0
        fi

		source bin/installerToken.sh atomType=${atomType}
		./bin/installMolecule.sh atomName="${atomName}" tokenId="${tokenId}" INSTALL_DIR="${INSTALL_DIR}" WORK_DIR="${WORK_DIR}" TMP_DIR="${TMP_DIR}" JRE_HOME="${JRE_HOME}" JAVA_HOME="${JAVA_HOME}" proxyHost="${proxyHost}" proxyPort="${proxyPort}" proxyUser="${proxyUser}" proxyPassword="${proxyPassword}"
		source bin/createEnvAndAttachRoleAndAtom.sh env="${env}" classification=${classification} atomName="${atomName}" roleName="${roleName}" purgeHistoryDays="${purgeHistoryDays}" 
		source bin/updateSharedServer.sh atomName="${atomName}" overrideUrl=true url="${sharedWebURL}" apiType="${apiType}" auth="${apiAuth}"
	else
		echo "Invalid AtomType"
		exit 255
fi

echo "$JRE_HOME" > "${ATOM_HOME}"/.install4j/inst_jre.cfg
echo "$JRE_HOME" > "${ATOM_HOME}"/.install4j/pref_jre.cfg
sed -i "s/-Xmx.*$/-Xmx${maxMem}/" "$ATOM_HOME/bin/atom.vmoptions"
echo "-XX:+UseG1GC" >> "$ATOM_HOME/bin/atom.vmoptions"
echo "-XX:+ParallelRefProcEnabled" >> "$ATOM_HOME/bin/atom.vmoptions"
echo "-XX:+UseStringDeduplication" >> "$ATOM_HOME/bin/atom.vmoptions"

sed -i "s/com\.boomi\.container\.purgeDays.*$/com\.boomi\.container\.purgeDays=${purgeHistoryDays}/" "$ATOM_HOME/conf/container.properties"
	
${ATOM_HOME}/bin/atom restart
