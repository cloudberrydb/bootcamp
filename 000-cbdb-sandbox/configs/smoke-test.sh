set -e

TUTORIALDB="tutorial"

lesson1(){
    echo "################################"
    echo "         LESSON 1 TESTS         "
    echo "################################"

    psql -c 'SELECT VERSION()'

    psql -c "CREATE USER lily WITH PASSWORD 'changeme'"

    CREATE_LILY=$(psql -c "\du" | grep lily)

    if [[ -z $CREATE_LILY ]]; then
        echo "Create user Lily failed"
        exit 1
    fi

    createuser --interactive lucy -s

    CREATE_LUCY=$(psql -c "\du" | grep lucy)

    if [[ -z $CREATE_LUCY ]]; then
        echo "Create user Lily failed"
        exit 1
    fi

    psql -c "CREATE ROLE users"

    psql -c "GRANT users TO lily, lucy"

    LUCY_USERS=$(psql -c "\du" | grep lucy | grep "{users}")
    LILY_USERS=$(psql -c "\du" | grep lily | grep "{users}")

    if [[ -z $LUCY_USERS || -z $LILY_USERS ]]; then
        echo "Create user Lily failed"
        exit 1
    fi

    LILY_LOGIN_FAIL=$(psql -U lily -d gpadmin -c "SELECT version()" 2>&1 || true)

    if [[ $LILY_LOGIN_FAIL != *"no pg_hba.conf entry for host"* ]]; then
        echo "Command failed"
        exit 1
    fi

    LUCY_LOGIN_FAIL=$(psql -U lucy -d gpadmin -c "SELECT version()" 2>&1 || true)

    if [[ $LUCY_LOGIN_FAIL != *"no pg_hba.conf entry for host"* ]]; then
        echo "Command failed"
        exit 1
    fi

    echo "local gpadmin lily md5" >> /data0/database/master/gpseg-1/pg_hba.conf
    echo "local gpadmin lucy trust" >> /data0/database/master/gpseg-1/pg_hba.conf

    gpstop -u

    PGPASSWORD=changeme psql -d gpadmin -U lily -c 'SELECT VERSION()'

    psql -d gpadmin -U lucy -c 'SELECT VERSION()'
}

lesson2(){
    echo "################################"
    echo "         LESSON 2 TESTS         "
    echo "################################"

    DROPDB=$(dropdb $TUTORIALDB 2>&1 || true)
    
    if [[ $DROPDB != *"database \"$TUTORIALDB\" does not exist"* ]]; then
        echo "Command failed"
        exit 1
    fi

    createdb $TUTORIALDB

    CREATEDB=$(psql -l | grep $TUTORIALDB)
    
    if [[ -z $CREATEDB ]]; then
        echo "Database $TUTORIALDB not found, exiting"
        exit 1
    fi

    echo "local $TUTORIALDB lily md5" >> /data0/database/master/gpseg-1/pg_hba.conf

    gpstop -u

    PGPASSWORD=changeme psql -d $TUTORIALDB -U lily -c 'SELECT VERSION()'

    psql -U gpadmin -d tutorial -c "GRANT ALL PRIVILEGES ON DATABASE tutorial TO lily"

    PGPASSWORD=changeme psql -d $TUTORIALDB -U lily -c "DROP SCHEMA IF EXISTS faa CASCADE"
    PGPASSWORD=changeme psql -d $TUTORIALDB -U lily -c "CREATE SCHEMA faa"
    PGPASSWORD=changeme psql -d $TUTORIALDB -U lily -c "ALTER ROLE lily SET search_path TO faa, public, pg_catalog, gp_toolkit"
    LILY_SEARCH_PATH=$(PGPASSWORD=changeme psql -d $TUTORIALDB -U lily -c "SHOW search_path")

    if [[ $LILY_SEARCH_PATH != *"faa, public, pg_catalog, gp_toolkit"* ]]; then
        echo "Lily search path not set correctly, exiting"
        exit 1
    fi 
}

lesson3(){
    echo "################################"
    echo "         LESSON 3 TESTS         "
    echo "################################"

    cd /tmp
    tar xzf faa.tar.gz
    cd faa

    PGPASSWORD=changeme psql -d $TUTORIALDB -U lily -c "\i create_dim_tables.sql"

    CREATED_TABLES=$(PGPASSWORD=changeme psql -d $TUTORIALDB -U lily -c "\dt")

    TABLELIST=("d_airlines" "d_airports" "d_cancellation_codes" "d_delay_groups" "d_distance_groups" "d_wac")

    for TABLE in ${TABLELIST[@]}; do
        if [[ $CREATED_TABLES != *"$TABLE"* ]]; then
            echo "Some tables did not get created in the faa dimension tables, exiting"
            exit 1
        fi 
    done
}

lesson4(){
    echo "################################"
    echo "         LESSON 4 TESTS         "
    echo "################################"

    cd /tmp/faa

    PGPASSWORD=changeme psql -d $TUTORIALDB -U lily -c "INSERT INTO faa.d_cancellation_codes \
           VALUES ('A', 'Carrier'), \
           ('B', 'Weather'), \
           ('C', 'NAS'), \
           ('D', 'Security'), \
           ('', 'none');" 

    PGPASSWORD=changeme psql -d $TUTORIALDB -U lily -c "\i copy_into_airlines.sql"
    PGPASSWORD=changeme psql -d $TUTORIALDB -U lily -c "\i copy_into_airports.sql"
    PGPASSWORD=changeme psql -d $TUTORIALDB -U lily -c "\i copy_into_delay_groups.sql"
    PGPASSWORD=changeme psql -d $TUTORIALDB -U lily -c "\i copy_into_distance_groups.sql"
    PGPASSWORD=changeme psql -d $TUTORIALDB -U lily -c "\i copy_into_wac.sql"

    gpfdist -d /tmp/faa -p 8081 > /tmp/gpfdist.log 2>&1 &
    GPFDIST_PID=$(echo $!)
    ps -p $GPFDIST_PID

    psql -d $TUTORIALDB -c "\i create_load_tables.sql"
    psql -d $TUTORIALDB -c "\i create_ext_table.sql"
    psql -d $TUTORIALDB -c "INSERT INTO faa.faa_otp_load SELECT * FROM faa.ext_load_otp;"

    pkill gpfdist

    # Using "|| true" here because if gpload loads successfully but has rejected rows it will throw a non 0 exit code
    GPLOAD_STATUS=$(gpload -f gpload.yaml -l gpload.log 2>&1 || true)

    if [[ $GPLOAD_STATUS != *"gpload succeeded with warnings"* ]]; then
        echo "gpload failed with status $GPLOAD_STATUS, exiting"
        exit 1
    fi 

    psql -d $TUTORIALDB -c "\i create_fact_tables.sql"
    psql -d $TUTORIALDB -c "\i load_into_fact_table.sql"
}

lesson5(){
    echo "################################"
    echo "         LESSON 5 TESTS         "
    echo "################################"
    psql -d $TUTORIALDB -c "ANALYZE faa.d_airports"
    psql -d $TUTORIALDB -c "ANALYZE faa.d_airlines"
    psql -d $TUTORIALDB -c "ANALYZE faa.d_wac"
    psql -d $TUTORIALDB -c "ANALYZE faa.d_cancellation_codes"
    psql -d $TUTORIALDB -c "ANALYZE faa.faa_otp_load"
    psql -d $TUTORIALDB -c "ANALYZE faa.otp_r"
    psql -d $TUTORIALDB -c "ANALYZE faa.otp_c"
    
    cd /tmp/faa

    psql -d $TUTORIALDB -c "\i create_sample_table.sql"

    psql -d $TUTORIALDB -c "EXPLAIN SELECT COUNT(*) FROM faa.sample WHERE id > 100"
    psql -d $TUTORIALDB -c "EXPLAIN ANALYZE SELECT COUNT(*) FROM faa.sample WHERE id > 100"

    gpconfig -s optimizer
    gpconfig -c optimizer -v off --masteronly
    gpstop -u

    psql -d $TUTORIALDB -c "DROP TABLE IF EXISTS faa.otp_c"
    
    psql -d $TUTORIALDB -c "CREATE TABLE faa.otp_c (LIKE faa.otp_r) WITH (appendonly=true, \
                            orientation=column) \
                            DISTRIBUTED BY (UniqueCarrier, FlightNum) PARTITION BY RANGE(FlightDate) \
                            ( PARTITION mth START('2009-06-01'::date) END ('2010-10-31'::date) \
                            EVERY ('1 mon'::interval))"

    psql -d $TUTORIALDB -c "INSERT INTO faa.otp_c SELECT * FROM faa.otp_r"
}

success(){
    echo "#################################"
    echo "  ALL TESTS SUCCESSFULLY PASSED  "
    echo "#################################"
}

lesson1
lesson2
lesson3
lesson4
lesson5
success
