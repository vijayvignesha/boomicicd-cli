#!/bin/bash
source /home/boomi/.profile
sed -ci "s/^\-Djava.endorsed.dirs=/#&/" "${ATOM_HOME}/bin/atom.vmoptions"
atom start
atom status
exit 0
