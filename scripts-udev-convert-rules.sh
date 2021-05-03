#!/bin/sh

for rule in /etc/udev/rules.d/*.rules; do
        CHANNEL=$(sed -n '/IMPORT{program}="collect/{s/.*collect \([[:graph:]]*\).*/\1/p;q}' $rule)
        DEVICE=$(sed -n '/IMPORT{program}="collect/{s/.* //p;q}' $rule)
        DEVICE="${DEVICE%\"}"

        if [ ! -z "$CHANNEL" ]; then
                echo "updating udev rule $rule for device $DEVICE channel $CHANNEL"
                if [ "$DEVICE" == "dasd-eckd" ]; then
                        echo "running: /sbin/chzdev -e -p $DEVICE --no-root-update $CHANNEL"
                        /sbin/chzdev -e -p $DEVICE --no-root-update $CHANNEL
                else
                        GROUP=$(sed -n '/SUBSYSTEM=="ccw"/s/.*group}=" *\([[:graph:]]*\),\([[:graph:]]*\),\([[:graph:]]*\)"/\1:\2:\3/p' $rule)
                        LAYER2=$(sed -n 's/.*layer2}="\([[:digit:]]\)"/layer2=\1/p' $rule)
                        PORTNO=$(chzdev --quiet --all $DEVICE --export - | grep portno)
                        echo "running: /sbin/chzdev -e -p $DEVICE --no-root-update ${PORTNO:=portno=0} $LAYER2 $GROUP"
                        /sbin/chzdev -e -p $DEVICE --no-root-update ${PORTNO:=portno=0} $LAYER2 $GROUP
                fi
                [ $? == 0 ] && mv $rule $rule.legacy
        fi
done
