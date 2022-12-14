#!/bin/bash

source bin/common.sh
ARGUMENTS=(atomName serviceUserName atomHome mountPoint)
inputs "$@"
echo "create $atomName.service ..."
cat <<EOF >/etc/systemd/system/$atomName.service
[Unit]
Description= Boomi $atomName
After=network.target
RequiresMountsFor="${mountPoint}"
[Service]
Type=forking
User=$serviceUserName
Restart=always
ExecStart="${atomHome}/bin/atom" start
ExecStop="${atomHome}/bin/atom" stop
ExecReload="${atomHome}/bin/atom" restart
[Install]
WantedBy=multi-user.target
EOF

echo "setup $atomname JMX integration..."
mkdir -vp /etc/jmxremote
cat <<EOF >/etc/jmxremote/jmxremote.password
monitorRole Password
EOF
cat <<EOF >/etc/jmxremote/jmxremote.access
monitorRole readonly
EOF
# change the permissions on both files so only owner can edit and view them.
chmod -R 0600 /etc/jmxremote
chown -R $serviceUserName:$serviceUserName /etc/jmxremote/jmxremote.*

echo "setup $atomName.service ..."
systemctl enable $atomName
systemctl start $atomName
systemctl is-active --quiet $atomName && echo Service is running




