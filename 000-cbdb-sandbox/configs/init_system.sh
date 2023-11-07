#!/bin/bash

/usr/sbin/sshd

INSATALL_PATH="/usr/local/cloudberry-db"
rm -rf /run/nologin
echo $(grep $(hostname) /etc/hosts | cut -f1) mdw  >> /etc/hosts 
echo "127.0.0.1 $(cat ~/orig_hostname)" >> /etc/hosts 
chown -R gpadmin.gpadmin ${INSATALL_PATH} /tmp/gpinitsystem_singlenode /tmp/gpdb-hosts /tmp/gpdb-master
su gpadmin -l -c "source ${INSATALL_PATH}/greenplum_path.sh;gpssh-exkeys -f /tmp/gpdb-hosts"  
su gpadmin -l -c "source ${INSATALL_PATH}/greenplum_path.sh;gpinitsystem -a -c  /tmp/gpinitsystem_singlenode -h /tmp/gpdb-hosts --max_connections=100" 
su gpadmin -l -c "export COORDINATOR_DATA_DIRECTORY=/data0/database/master/gpseg-1;source ${INSATALL_PATH}/greenplum_path.sh;psql -d template1 -c \"alter user gpadmin password 'cbdb@123'\""
echo "host all all 0.0.0.0/0 trust" >> /data0/database/master/gpseg-1/pg_hba.conf
su gpadmin -l -c "source ${INSATALL_PATH}/greenplum_path.sh;gpstop -u"
/bin/bash