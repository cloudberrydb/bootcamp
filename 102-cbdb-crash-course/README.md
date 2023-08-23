**CBDB Crash Course**

This course will guide you through some extensive features that Cloudberry database holds as MPP database.

# **0. Prerequisite** :

Before starting this crash course, spend some time to go trough [CBDB Tourials](https://github.com/cloudberrydb/bootcamp/blob/main/101-cbdb-tutorials/README.md) to get falmiliar with what is Cloudberry database and how it works. 

# 1. Documentation

Here is a link to the documentation [CBDB Documentation](https://cloudberrydb.org/docs/cbdb-overview). Now is the time to do a quick read of the documentation. No need to worry if you don't understand everything.


# 2. Installing CBDB

- You can get a sandbox environment as refer to [CBDB Sandbox](https://github.com/cloudberrydb/bootcamp/blob/main/000-cbdb-sandbox/README.md).

- Read up the [CBDB Deploy Guide](https://cloudberrydb.org/docs/cbdb-op-deploy-guide). The guide has some conceptual information about CBDB and the steps to install the software and create your own cluster in your preferred environment.


# 3. Cluster description

Cluster has one master host and many segment hosts. These are usually named "mdw" and "sdwXX" respectively. Therefore if somebody is referring to "mdw" he is referring to the "master host".

Similarly when somebody is referring to "sdw10" he is referring to the 10th segment host. Master host usually contains only one instance - the master instance. The segment hosts can contain

many worker instances.

Every instance has its own set of processes, own data directory and own listening port. For example usually the listening port of the master instance (where all clients will connect) is 5432.

Every segment instance has its own listening port (the base port is specified in the cluster configuration file).

Instances can have 2 roles - primary and mirror. Primary instances serve database queries. Mirror instances simply track and record data changes in primary instances, but do not serve database queries. If the primary instance goes down for some reason, then the corresponding mirror instance transitions to primary role and starts serving queries (the original primary instance, currently down, is marked as mirror). We will talk later how to recover failed instances.

The cluster information is stored in the "gp\_segment\_configuration" table. It looks like this (use the "psql" command to connect to the database in order to execute queries):

```
[gpadmin@mdw ~]$ psql
psql (14.4, server 14.4)
Type "help" for help.

gpadmin=# select * from gp_segment_configuration ;
 dbid | content | role | preferred_role | mode | status | port  | hostname | address |            datadir
------+---------+------+----------------+------+--------+-------+----------+---------+--------------------------------
    1 |      -1 | p    | p              | n    | u      |  5432 | mdw      | mdw     | /data0/database/master/gpseg-1
    2 |       0 | p    | p              | n    | u      | 40000 | mdw      | mdw     | /data0/database/primary/gpseg0
    3 |       1 | p    | p              | n    | u      | 40001 | mdw      | mdw     | /data0/database/primary/gpseg1
(3 rows)

```

Columns:

- dbid - uniquely identifies a segment

- content - uniquely identifies segment pair (primary and mirror). The primary and corresponding mirror will have the same content id, but different dbid.

The master has content of -1. The worker instances have content 0,1,2,3...

- role - the current role of the segment

- preferred\_role - the role of the segment in the original configuration (if an instance that was originally mirror has taken over and became primary now - these will be different)

- mode - 's' (in-sync), 'c' (in-changetracking), 'r'(in-recovery)

- status - 'u' (up), 'd' (down)

- port - segment listening port. For clients only the listening port of the master is important. The segment listening ports are important for the master to communicate with them.

- hostname - hostname of this segment

- address - each host can have different network controllers with different IP addresses and different names associated with them

- datadir - data directory where data is stored for each segment

Exercise: Connect to the CBDB cluster that you created and take a look at the "gp\_segment\_configuration" table. Try to make sense of the rows and columns and connect it to the cluster configuration file that you used to create the cluster.

# 4. Management utilities

- gpstop - stops database cluster

- gpstart - starts database cluster

- psql - command line client

- gpconfig - show/change configuration parameters

- gpdeletesystem - deletes a cluster

- pg\_dump, gpbackup, gprestore - backup and restore utilities

- gpinitstanby, gpactivatestandby - standby master instance management

- gprecoverseg - segment recovery

- gpfdist, gpload - external tables

- gpssh, gpscp, gpssh-exkeys - cluster navigation

- Logging - all utilities write log files under ~/gpAdminLogs/ - one file per day

Exercise: Read the help for these tools (\<tool\> --help)

# 5. Starting and stopping cluster

- gpstart

```
[gpadmin@mdw ~]$ gpstart -a
20230823:16:14:23:004256 gpstart:mdw:gpadmin-[INFO]:-Starting gpstart with args: -a
20230823:16:14:23:004256 gpstart:mdw:gpadmin-[INFO]:-Gathering information and validating the environment...
20230823:16:14:23:004256 gpstart:mdw:gpadmin-[INFO]:-Cloudberry Binary Version: 'postgres (Cloudberry Database) 1.0.0 build dev'
20230823:16:14:23:004256 gpstart:mdw:gpadmin-[INFO]:-Cloudberry Catalog Version: '302206171'
20230823:16:14:23:004256 gpstart:mdw:gpadmin-[INFO]:-Starting Coordinator instance in admin mode
20230823:16:14:23:004256 gpstart:mdw:gpadmin-[INFO]:-CoordinatorStart pg_ctl cmd is env GPSESSID=0000000000 GPERA=None $GPHOME/bin/pg_ctl -D /data0/database/master/gpseg-1 -l /data0/database/master/gpseg-1/log/startup.log -w -t 600 -o " -p 5432 -c gp_role=utility " start
20230823:16:14:23:004256 gpstart:mdw:gpadmin-[INFO]:-Obtaining Cloudberry Coordinator catalog information
20230823:16:14:23:004256 gpstart:mdw:gpadmin-[INFO]:-Obtaining Segment details from coordinator...
20230823:16:14:23:004256 gpstart:mdw:gpadmin-[INFO]:-Setting new coordinator era
20230823:16:14:23:004256 gpstart:mdw:gpadmin-[INFO]:-Coordinator Started...
20230823:16:14:23:004256 gpstart:mdw:gpadmin-[INFO]:-Shutting down coordinator
20230823:16:14:23:004256 gpstart:mdw:gpadmin-[INFO]:-Commencing parallel primary and mirror segment instance startup, please wait...
20230823:16:14:24:004256 gpstart:mdw:gpadmin-[INFO]:-Process results...
20230823:16:14:24:004256 gpstart:mdw:gpadmin-[INFO]:-
20230823:16:14:24:004256 gpstart:mdw:gpadmin-[INFO]:-----------------------------------------------------
20230823:16:14:24:004256 gpstart:mdw:gpadmin-[INFO]:-   Successful segment starts                                            = 4
20230823:16:14:24:004256 gpstart:mdw:gpadmin-[INFO]:-   Failed segment starts                                                = 0
20230823:16:14:24:004256 gpstart:mdw:gpadmin-[INFO]:-   Skipped segment starts (segments are marked down in configuration)   = 0
20230823:16:14:24:004256 gpstart:mdw:gpadmin-[INFO]:-----------------------------------------------------
20230823:16:14:24:004256 gpstart:mdw:gpadmin-[INFO]:-Successfully started 4 of 4 segment instances
20230823:16:14:24:004256 gpstart:mdw:gpadmin-[INFO]:-----------------------------------------------------
20230823:16:14:24:004256 gpstart:mdw:gpadmin-[INFO]:-Starting Coordinator instance mdw directory /data0/database/master/gpseg-1
20230823:16:14:24:004256 gpstart:mdw:gpadmin-[INFO]:-CoordinatorStart pg_ctl cmd is env GPSESSID=0000000000 GPERA=45b5ca734de32094_230823161423 $GPHOME/bin/pg_ctl -D /data0/database/master/gpseg-1 -l /data0/database/master/gpseg-1/log/startup.log -w -t 600 -o " -p 5432 -c gp_role=dispatch " start
20230823:16:14:24:004256 gpstart:mdw:gpadmin-[INFO]:-Command pg_ctl reports Coordinator mdw instance active
20230823:16:14:24:004256 gpstart:mdw:gpadmin-[INFO]:-Connecting to db template1 on host localhost
20230823:16:14:24:004256 gpstart:mdw:gpadmin-[INFO]:-No standby coordinator configured.  skipping...
20230823:16:14:24:004256 gpstart:mdw:gpadmin-[INFO]:-Database successfully started
```

- gpstop
``` 
[gpadmin@mdw ~]$ gpstop -a
20230823:16:14:18:004143 gpstop:mdw:gpadmin-[INFO]:-Starting gpstop with args: -a
20230823:16:14:18:004143 gpstop:mdw:gpadmin-[INFO]:-Gathering information and validating the environment...
20230823:16:14:18:004143 gpstop:mdw:gpadmin-[INFO]:-Obtaining Cloudberry Coordinator catalog information
20230823:16:14:18:004143 gpstop:mdw:gpadmin-[INFO]:-Obtaining Segment details from coordinator...
20230823:16:14:18:004143 gpstop:mdw:gpadmin-[INFO]:-Cloudberry Version: 'postgres (Cloudberry Database) 1.0.0 build dev'
20230823:16:14:18:004143 gpstop:mdw:gpadmin-[INFO]:-Commencing Coordinator instance shutdown with mode='smart'
20230823:16:14:18:004143 gpstop:mdw:gpadmin-[INFO]:-Coordinator segment instance directory=/data0/database/master/gpseg-1
20230823:16:14:18:004143 gpstop:mdw:gpadmin-[INFO]:-Stopping coordinator segment and waiting for user connections to finish ...
server shutting down
20230823:16:14:19:004143 gpstop:mdw:gpadmin-[INFO]:-Attempting forceful termination of any leftover coordinator process
20230823:16:14:19:004143 gpstop:mdw:gpadmin-[INFO]:-Terminating processes for segment /data0/database/master/gpseg-1
20230823:16:14:19:004143 gpstop:mdw:gpadmin-[INFO]:-No standby coordinator host configured
20230823:16:14:19:004143 gpstop:mdw:gpadmin-[INFO]:-Targeting dbid [2, 4, 3, 5] for shutdown
20230823:16:14:19:004143 gpstop:mdw:gpadmin-[INFO]:-Commencing parallel primary segment instance shutdown, please wait...
20230823:16:14:19:004143 gpstop:mdw:gpadmin-[INFO]:-0.00% of jobs completed
20230823:16:14:19:004143 gpstop:mdw:gpadmin-[INFO]:-100.00% of jobs completed
20230823:16:14:19:004143 gpstop:mdw:gpadmin-[INFO]:-Commencing parallel mirror segment instance shutdown, please wait...
20230823:16:14:19:004143 gpstop:mdw:gpadmin-[INFO]:-0.00% of jobs completed
20230823:16:14:20:004143 gpstop:mdw:gpadmin-[INFO]:-100.00% of jobs completed
20230823:16:14:20:004143 gpstop:mdw:gpadmin-[INFO]:-----------------------------------------------------
20230823:16:14:20:004143 gpstop:mdw:gpadmin-[INFO]:-   Segments stopped successfully      = 4
20230823:16:14:20:004143 gpstop:mdw:gpadmin-[INFO]:-   Segments with errors during stop   = 0
20230823:16:14:20:004143 gpstop:mdw:gpadmin-[INFO]:-----------------------------------------------------
20230823:16:14:20:004143 gpstop:mdw:gpadmin-[INFO]:-Successfully shutdown 4 of 4 segment instances
20230823:16:14:20:004143 gpstop:mdw:gpadmin-[INFO]:-Database successfully shutdown with no errors reported
```

Exercise: Read the log entries for gpstop and gpstart and try to understand what they mean. Read and exercise the different options for gpstart/gpstop.

# 6. Cluster state

- gpstate

gpstate is the utility that can give you information about the state of the cluster. It has different arguments to show different aspects of the state.

``` 
[gpadmin@mdw ~]$ gpstate
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-Starting gpstate with args:
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-local Cloudberry Version: 'postgres (Cloudberry Database) 1.0.0 build dev'
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-coordinator Cloudberry Version: 'PostgreSQL 14.4 (Cloudberry Database 1.0.0 build dev) on aarch64-unknown-linux-gnu, compiled by gcc (GCC) 10.2.1 20210130 (Red Hat 10.2.1-11), 64-bit compiled on Aug  9 2023 14:45:43'
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-Obtaining Segment details from coordinator...
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-Gathering data from segments...
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-Cloudberry instance status summary
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-----------------------------------------------------
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Coordinator instance                                      = Active
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Coordinator standby                                       = No coordinator standby configured
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Total segment instance count from metadata                = 4
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-----------------------------------------------------
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Primary Segment Status
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-----------------------------------------------------
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Total primary segments                                    = 2
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Total primary segment valid (at coordinator)              = 2
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Total primary segment failures (at coordinator)           = 0
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Total number of postmaster.pid files missing              = 0
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Total number of postmaster.pid files found                = 2
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs missing               = 0
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs found                 = 2
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Total number of /tmp lock files missing                   = 0
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Total number of /tmp lock files found                     = 2
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Total number postmaster processes missing                 = 0
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Total number postmaster processes found                   = 2
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-----------------------------------------------------
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Mirror Segment Status
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-----------------------------------------------------
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Total mirror segments                                     = 2
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Total mirror segment valid (at coordinator)               = 2
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Total mirror segment failures (at coordinator)            = 0
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Total number of postmaster.pid files missing              = 0
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Total number of postmaster.pid files found                = 2
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs missing               = 0
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs found                 = 2
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Total number of /tmp lock files missing                   = 0
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Total number of /tmp lock files found                     = 2
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Total number postmaster processes missing                 = 0
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Total number postmaster processes found                   = 2
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Total number mirror segments acting as primary segments   = 0
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-   Total number mirror segments acting as mirror segments    = 2
20230823:16:17:41:004530 gpstate:mdw:gpadmin-[INFO]:-----------------------------------------------------

```
- gp\_segment\_configuration

gp\_segment\_configuration expresses the 'master instance' knowledge about the state of the cluster.

Exercise: Look at the cluster state and try to connect the information from gpstate and gp\_segment\_configuration.

# 7. Adding mirrors

How CBDB mirroring works

Each segment can be in two roles - primary or mirror. Primary role - servers user queries. Mirror role - tracks changes via WAL replication from primary, does not serve user queries.

The normal state of primary and mirror is both are Up and In-sync (P:u/s, M:u/s)

- possibility 1 - mirror instance goes down
  - at this point primary is transitioned into special state with changetracking (all changes to data are recorded and stored) -\> P:u/c M:d/s
  - at some point the DBA will notice this, investigate the failure and attempt to recover the mirror (see gprecoverseg)
  - as soon as recovery starts both segments will go in recovery mode -\> P:u/r M:u/r
  - when recovery finishes both segments will go in sync mode -\> P:u/s M:u/s
  - note that as primary is never down in this case, this situation is transparent to user - queries run and never stop running
- possibility 2 - primary instance goes down
  - at this point primary instance is down and all running sessions are terminated
  - database transitions the primary to down and promotes the mirror to primary with changetracking -\> M:d/s P:u/c
  - at some point the DBA will notice this, investigate the failure and attempt to recover the mirror (see gprecoverseg)
  - as soon as recovery starts both segments will go in recovery mode -\> M:u/r P:u/r
  - when recovery finishes both segments will go in sync mode -\> M:u/s P:u/s
  - note that at this point the instances still have switched roles (original primary is now mirror). To fix this segments need to be rebalanced: 1) gpstop/gpstart or 2) gprecoverseg -r (rebalance)

- gpaddmirrors

- if the cluster was initially created without mirrors, "gpaddmirrors" is the utility to add mirrors to existing cluster

``` 
[gpadmin@mdw ~]$ gpaddmirrors
20230823:16:02:50:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-Starting gpaddmirrors with args:
20230823:16:02:50:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-local Cloudberry Version: 'postgres (Cloudberry Database) 1.0.0 build dev'
20230823:16:02:50:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-coordinator Cloudberry Version: 'PostgreSQL 14.4 (Cloudberry Database 1.0.0 build dev) on aarch64-unknown-linux-gnu, compiled by gcc (GCC) 10.2.1 20210130 (Red Hat 10.2.1-11), 64-bit compiled on Aug  9 2023 14:45:43'
20230823:16:02:50:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-Obtaining Segment details from coordinator...
20230823:16:02:50:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-Successfully finished pg_controldata /data0/database/primary/gpseg0 for dbid 2:
stdout: pg_control version number:            13000700
Catalog version number:               302206171
Database system identifier:           7270424369249924934
Database cluster state:               in production
pg_control last modified:             Wed 23 Aug 2023 03:59:52 PM CST
Latest checkpoint location:           0/50EBA18
Latest checkpoint's REDO location:    0/50EB9E0
Latest checkpoint's REDO WAL file:    000000010000000000000001
Latest checkpoint's TimeLineID:       1
Latest checkpoint's PrevTimeLineID:   1
Latest checkpoint's full_page_writes: on
Latest checkpoint's NextXID:          0:762
Latest checkpoint's NextGxid:         1
Latest checkpoint's NextOID:          13266
Latest checkpoint's NextRelfilenode:  12002
Latest checkpoint's NextMultiXactId:  1
Latest checkpoint's NextMultiOffset:  0
Latest checkpoint's oldestXID:        752
Latest checkpoint's oldestXID's DB:   1
Latest checkpoint's oldestActiveXID:  761
Latest checkpoint's oldestMultiXid:   1
Latest checkpoint's oldestMulti's DB: 1
Latest checkpoint's oldestCommitTsXid:0
Latest checkpoint's newestCommitTsXid:0
Time of latest checkpoint:            Wed 23 Aug 2023 03:59:52 PM CST
Fake LSN counter for unlogged rels:   0/3E8
Minimum recovery ending location:     0/0
Min recovery ending loc's timeline:   0
Backup start location:                0/0
Backup end location:                  0/0
End-of-backup record required:        no
wal_level setting:                    replica
wal_log_hints setting:                off
max_connections setting:              60
max_worker_processes setting:         13
max_wal_senders setting:              10
max_prepared_xacts setting:           250
max_locks_per_xact setting:           128
track_commit_timestamp setting:       off
Maximum data alignment:               8
Database block size:                  32768
Blocks per segment of large relation: 32768
WAL block size:                       32768
Bytes per WAL segment:                67108864
Maximum length of identifiers:        64
Maximum columns in an index:          32
Maximum size of a TOAST chunk:        8140
Size of a large-object chunk:         8192
Date/time type storage:               64-bit integers
Float8 argument passing:              by value
Data page checksum version:           1
Mock authentication nonce:            94edd2a762753f7d12faff1737ffb338dec6e01a90eb3d509c6afc67e78bf58e
File encryption method:

stderr:
20230823:16:02:50:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-Successfully finished pg_controldata /data0/database/primary/gpseg1 for dbid 3:
stdout: pg_control version number:            13000700
Catalog version number:               302206171
Database system identifier:           7270424369087874885
Database cluster state:               in production
pg_control last modified:             Wed 23 Aug 2023 03:59:52 PM CST
Latest checkpoint location:           0/50EBA18
Latest checkpoint's REDO location:    0/50EB9E0
Latest checkpoint's REDO WAL file:    000000010000000000000001
Latest checkpoint's TimeLineID:       1
Latest checkpoint's PrevTimeLineID:   1
Latest checkpoint's full_page_writes: on
Latest checkpoint's NextXID:          0:762
Latest checkpoint's NextGxid:         1
Latest checkpoint's NextOID:          13266
Latest checkpoint's NextRelfilenode:  12002
Latest checkpoint's NextMultiXactId:  1
Latest checkpoint's NextMultiOffset:  0
Latest checkpoint's oldestXID:        752
Latest checkpoint's oldestXID's DB:   1
Latest checkpoint's oldestActiveXID:  761
Latest checkpoint's oldestMultiXid:   1
Latest checkpoint's oldestMulti's DB: 1
Latest checkpoint's oldestCommitTsXid:0
Latest checkpoint's newestCommitTsXid:0
Time of latest checkpoint:            Wed 23 Aug 2023 03:59:52 PM CST
Fake LSN counter for unlogged rels:   0/3E8
Minimum recovery ending location:     0/0
Min recovery ending loc's timeline:   0
Backup start location:                0/0
Backup end location:                  0/0
End-of-backup record required:        no
wal_level setting:                    replica
wal_log_hints setting:                off
max_connections setting:              60
max_worker_processes setting:         13
max_wal_senders setting:              10
max_prepared_xacts setting:           250
max_locks_per_xact setting:           128
track_commit_timestamp setting:       off
Maximum data alignment:               8
Database block size:                  32768
Blocks per segment of large relation: 32768
WAL block size:                       32768
Bytes per WAL segment:                67108864
Maximum length of identifiers:        64
Maximum columns in an index:          32
Maximum size of a TOAST chunk:        8140
Size of a large-object chunk:         8192
Date/time type storage:               64-bit integers
Float8 argument passing:              by value
Data page checksum version:           1
Mock authentication nonce:            baf9fb0b44c5cc558357b266024336445d958e35f8896fcd94b5ef2143ad052d
File encryption method:

stderr:
20230823:16:02:50:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-Heap checksum setting consistent across cluster
Enter mirror segment data directory location 1 of 2 >
/data0/database/mirror
Enter mirror segment data directory location 2 of 2 >
/data0/database/mirror
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-Cloudberry Add Mirrors Parameters
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:---------------------------------------------
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-Cloudberry coordinator data directory    = /data0/database/master/gpseg-1
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-Cloudberry coordinator port              = 5432
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-Batch size                              = 16
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-Segment batch size                      = 64
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:---------------------------------------------
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-Mirror 1 of 2
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:---------------------------------------------
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-   Primary instance host        = mdw
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-   Primary instance address     = mdw
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-   Primary instance directory   = /data0/database/primary/gpseg0
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-   Primary instance port        = 40000
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-   Mirror instance host         = mdw
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-   Mirror instance address      = mdw
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-   Mirror instance directory    = /data0/database/mirror/gpseg0
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-   Mirror instance port         = 41000
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:---------------------------------------------
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-Mirror 2 of 2
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:---------------------------------------------
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-   Primary instance host        = mdw
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-   Primary instance address     = mdw
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-   Primary instance directory   = /data0/database/primary/gpseg1
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-   Primary instance port        = 40001
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-   Mirror instance host         = mdw
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-   Mirror instance address      = mdw
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-   Mirror instance directory    = /data0/database/mirror/gpseg1
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-   Mirror instance port         = 41001
20230823:16:03:16:003517 gpaddmirrors:mdw:gpadmin-[INFO]:---------------------------------------------

Continue with add mirrors procedure Yy|Nn (default=N):
> y
20230823:16:03:30:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-Starting to create new pg_hba.conf on primary segments
20230823:16:03:31:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-Successfully modified pg_hba.conf on primary segments to allow replication connections
20230823:16:03:31:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-2 segment(s) to add
20230823:16:03:31:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-Setting up the required segments for recovery
20230823:16:03:31:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-Running recovery for the required segments
mdw (dbid 4): pg_basebackup: base backup completed
mdw (dbid 5): pg_basebackup: base backup completed
20230823:16:03:33:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-Updating configuration with new mirrors
20230823:16:03:33:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-Starting mirrors
20230823:16:03:33:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-era is 45b5ca734de32094_230823155950
20230823:16:03:33:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-Commencing parallel segment instance startup, please wait...
20230823:16:03:34:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-Process results...
20230823:16:03:34:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-
20230823:16:03:34:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-******************************************************************
20230823:16:03:34:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-Mirror segments have been added; data synchronization is in progress.
20230823:16:03:34:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-Data synchronization will continue in the background.
20230823:16:03:34:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-Use  gpstate -s  to check the resynchronization progress.
20230823:16:03:34:003517 gpaddmirrors:mdw:gpadmin-[INFO]:-******************************************************************
```

Exercise: Add mirrors to your cluster. If your cluster already have mirrors - delete the cluster and recreate without mirrors (removing mirror segments is not supported).

# 8. FTS, segment failures and recovering mirrors

- CBDB has a Fault Tolerant Service that monitors the cluster and makes sure that work continues with working segments. When segment does down, it performs transitions to always have available primary instance for every content. If both instances for one content go down (primary does down, mirror goes down) - this is known as "double fault" and database is non-operable.

- FTS service runs on master in the "ftsprober" process. At certain intervals the prober will scan segments and if there is difference with the last known configuration, it will perform transitions accordingly.

Information about the transition event is recorded in the master log file and in "gp\_configuration\_history" and the instance status is updated in "gp\_segment\_configuration"

```
gpadmin=# select * from gp_configuration_history ;
             time              | dbid |                                      desc
-------------------------------+------+--------------------------------------------------------------------------------
 2023-08-23 16:03:33.917057+08 |    4 | gpaddmirrors: segment config for resync: inserted mirror segment configuration
 2023-08-23 16:03:33.917057+08 |    5 | gpaddmirrors: segment config for resync: inserted mirror segment configuration
 2023-08-23 16:03:52.784083+08 |    2 | FTS: update role, status, and mode for dbid 2 with contentid 0 to p, u, and s
 2023-08-23 16:03:52.78515+08  |    4 | FTS: update role, status, and mode for dbid 4 with contentid 0 to m, u, and s
 2023-08-23 16:03:52.794198+08 |    3 | FTS: update role, status, and mode for dbid 3 with contentid 1 to p, u, and s
 2023-08-23 16:03:52.794214+08 |    5 | FTS: update role, status, and mode for dbid 5 with contentid 1 to m, u, and s
(6 rows)
```

To recover a segment which is down, use the "gprecoverseg" utility. it will inspect "gp\_segment\_configuration" table, will find out the segment marked "down" and will attempt to recover them

from the corresponding "primary" segment (which of course needs to be up and running).

Investigating segment failures:

- look at "gp\_segment\_configuration" to identify the failed segments and their mirrors

- look at the master log file to find out when did the event happen (FTS log entries are prefixed with "FTS:")

- look at the "gp\_configuration\_history" table to see the recorded events

- look at the primary and mirror log files to find out the reason for the segment failure

- once the failure has been understood, run "gprecoverseg" to recover the segments

- you can monitor the recovery progress with "gpstate -e"

Exercise: Identify the processes for one of your database instances and terminate it. Track gp\_segment\_configuration to see the change. Follow up with the master log file and gp\_segment\_configuration.

Recover the failed segment. Verify in gp\_segment\_configuration that everything is recovered.

# 9. Standby master

Master instance is a single point of failure. This is why it is recommended to configure and maintain a 'standby master' instance. This instance is usually created on a special server - standby master server ("smdw").

The command to create standby master is "gpinitstandby" (executed from the master server).

- gpinitstandby -s smdw

The command to resync standby master that is out-of-sync is:

- gpinitstandby -n

The command to remove standby master is:

- gpinitstandby -r

After standby instance creation, you can observe the new instance in "gp\_segment\_configuration" with content=-1 and role='m'.

If master server is down or master instance is down, then the standby master instance can be promoted to master instance with the command:

- gpactivatestandby (executed from the standby server)

At this point the standby master transitions to master and the original master is transitioned to standby instance (but is down). Changes can be observed in "gp\_segment\_configuration".

Exercise: Initialize standby master. Remove it. Initialize it again. Activate the standby master. Initialize another standby master at the original master. Activate the standby master.

Track gp\_segment\_configuration to understand the changes.

# 10. Expansion

If the cluster needs to be expanded, the "gpexpand" tool can be used.

The cluster can be expanded both with new hosts and more segments per host.

gpexpand utility workflow

- phasee I: Interview (gpexpand)

Run "gpexpand" without parameters. It will go through interview and will ask you questions about your intentions. Once all questions have been answered it will create a "configuration file" and exit. The configuraiton file contains information about the new segments that are about to be created. At this point you should review the configuration file to make sure that the actions are what you want intent to do.

- phase II: Expand cluster (gpexpand -i \<config\_file\>)

During this phase the utility will create the new instances. The new instances will become part of the cluster and will be recorded in "gp\_segment\_configuration". From this point on the cluster has grown with the new instances, but the new instances still do not contain user data. gpexpand will also create the "gpexpand" schema in the requested directory, which contains a list of tables to be redistributed in the next step.

- phase III: Redsitribute data (gpexpand)

At this phase the user data, stored until now only on original instances, is redistributed across the new larger cluster. Expansion can be done in many runs with setting timeout for the current run (see the -d parameter). Once the redistribution is finished (all the tables are redistributed across all instances), gpexpand will exit.

- phase IV: Clean up

At this point cluster is expanded and data is redistributed. Everything is done. The "gpexpand" schema though is still there for you to review if necessary. This schema does not harm anything.

The only side effect is that if you need to start another expansion, "gpexpand" will ask you to remove it with "gpexpand -c" before it can continue.

Exercise: Run gpexpand and add segments to the existing servers. Run gpexpand to add segments on new servers to the cluster.

Observe gp\_segment\_configuration and connect the changes to the actions.

# 11. Performance check

"gpcheckperf" utility checks performance on a set of hosts (cluster):

- IO performance per host (-r d) - gpcheckperf will use "dd" to perform

- read test

- write test

- network performance (-r n|N|M)

- n = sequential

- N = parallel (must use even number of hosts)

- M = full matrix mode

- memory bandwidth test per host (-r s) - the utility uses the STREAM benchmark program to measure sustainable memory bandwidth (in MB/s).

Exercise: Run gpcheckcat with the various options and interpret the results.


# 12. User data and table distribution

- master does not have user data

- segments have user data

- data is not shared

- create table (...) distributed by (...)

- create table (...) distributed randomly

- gp\_segment\_id

```
gpadmin=# create table test(a int, b int) distributed by (a);
CREATE TABLE
gpadmin=# \d+ test
                                          Table "public.test"
 Column |  Type   | Collation | Nullable | Default | Storage | Compression | Stats target | Description
--------+---------+-----------+----------+---------+---------+-------------+--------------+-------------
 a      | integer |           |          |         | plain   |             |              |
 b      | integer |           |          |         | plain   |             |              |
Distributed by: (a)
Access method: heap

gpadmin=# select * from test;
 a | b
---+---
(0 rows)

gpadmin=# insert into test values (1,100);
INSERT 0 1
gpadmin=# select gp_segment_id, * from test;
 gp_segment_id | a |  b
---------------+---+-----
             1 | 1 | 100
(1 row)

gpadmin=# insert into test values (2,100);
INSERT 0 1
gpadmin=# select gp_segment_id, * from test;
 gp_segment_id | a |  b
---------------+---+-----
             0 | 2 | 100
             1 | 1 | 100
(2 rows)

gpadmin=# insert into test values (1,300);
INSERT 0 1
gpadmin=# select gp_segment_id, * from test;
 gp_segment_id | a |  b
---------------+---+-----
             1 | 1 | 100
             1 | 1 | 300
             0 | 2 | 100
(3 rows)

gpadmin=# create table test(a int, b int) distributed randomly;
CREATE TABLE
gpadmin=# \d+ test
                                          Table "public.test"
 Column |  Type   | Collation | Nullable | Default | Storage | Compression | Stats target | Description
--------+---------+-----------+----------+---------+---------+-------------+--------------+-------------
 a      | integer |           |          |         | plain   |             |              |
 b      | integer |           |          |         | plain   |             |              |
Distributed randomly
Access method: heap

gpadmin=# insert into test values (1,100);
INSERT 0 1
gpadmin=# select gp_segment_id, * from test;
 gp_segment_id | a |  b
---------------+---+-----
             1 | 1 | 100
(1 row)

gpadmin=# insert into test values (1,200);
INSERT 0 1
gpadmin=# select gp_segment_id, * from test;
 gp_segment_id | a |  b
---------------+---+-----
             0 | 1 | 200
             1 | 1 | 100
(2 rows)

gpadmin=#

```

Exercise: Reproduce the above with your own table and observe the effects.

# 13. Database catalog

- located on master and segments

- pg_catalog schema

- tables, views, indexes

- object description - pg_class, pg_attribute, pg_type, etc...

- functions - pg_class

- segment data (master only tables) - gp_segment_configuration, gp_configuration_history

- distribution data - gp_distribution_policy

- gpcheckcat

Exercise: Run gpcheckcat on your cluster and attempt to make sense of the results.

# 14. Data directories

Contents of a data directory:

Coordinator data directory:

```
[gpadmin@mdw gpseg-1]$ ls -tlr
total 156
-rw------- 1 gpadmin gpadmin     3 Aug 23 15:59 PG_VERSION
drwx------ 2 gpadmin gpadmin  4096 Aug 23 15:59 pg_twophase
drwx------ 2 gpadmin gpadmin  4096 Aug 23 15:59 pg_tblspc
drwx------ 2 gpadmin gpadmin  4096 Aug 23 15:59 pg_snapshots
drwx------ 2 gpadmin gpadmin  4096 Aug 23 15:59 pg_serial
drwx------ 2 gpadmin gpadmin  4096 Aug 23 15:59 pg_replslot
drwx------ 2 gpadmin gpadmin  4096 Aug 23 15:59 pg_notify
drwx------ 4 gpadmin gpadmin  4096 Aug 23 15:59 pg_multixact
drwx------ 2 gpadmin gpadmin  4096 Aug 23 15:59 pg_dynshmem
drwx------ 2 gpadmin gpadmin  4096 Aug 23 15:59 pg_cryptokeys
drwx------ 2 gpadmin gpadmin  4096 Aug 23 15:59 pg_commit_ts
-rw------- 1 gpadmin gpadmin    88 Aug 23 15:59 postgresql.auto.conf
-rw------- 1 gpadmin gpadmin  1636 Aug 23 15:59 pg_ident.conf
drwx------ 2 gpadmin gpadmin  4096 Aug 23 15:59 pg_xact
drwx------ 3 gpadmin gpadmin  4096 Aug 23 15:59 pg_wal
drwx------ 2 gpadmin gpadmin  4096 Aug 23 15:59 pg_subtrans
drwx------ 2 gpadmin gpadmin  4096 Aug 23 15:59 pg_distributedlog
-rw------- 1 gpadmin gpadmin 31760 Aug 23 15:59 postgresql.conf
-rw------- 1 gpadmin gpadmin    10 Aug 23 15:59 internal.auto.conf
-rw-rw-r-- 1 gpadmin gpadmin   860 Aug 23 15:59 gpssh.conf
drwx------ 6 gpadmin gpadmin  4096 Aug 23 15:59 base
-rw-rw-r-- 1 gpadmin gpadmin  4723 Aug 23 15:59 pg_hba.conf
-rw------- 1 gpadmin gpadmin    38 Aug 23 16:14 current_logfiles
-rw------- 1 gpadmin gpadmin   112 Aug 23 16:14 postmaster.opts
drwx------ 2 gpadmin gpadmin  4096 Aug 23 16:14 pg_stat
-rw------- 1 gpadmin gpadmin   130 Aug 23 16:14 gpsegconfig_dump
-rw------- 1 gpadmin gpadmin    88 Aug 23 16:14 postmaster.pid
drwx------ 2 gpadmin gpadmin  4096 Aug 23 16:14 log
drwx------ 2 gpadmin gpadmin  4096 Aug 23 16:14 global
drwx------ 4 gpadmin gpadmin  4096 Aug 23 16:39 pg_logical
drwx------ 2 gpadmin gpadmin  4096 Aug 23 16:44 pg_stat_tmp
```
Segment data directory:

```
[gpadmin@mdw gpseg-1]$ cd /data0/database/primary/gpseg0
[gpadmin@mdw gpseg0]$ ls -ltr
total 180
drwx------ 2 gpadmin gpadmin  4096 Aug 23 15:59 pg_twophase
drwx------ 2 gpadmin gpadmin  4096 Aug 23 15:59 pg_tblspc
drwx------ 2 gpadmin gpadmin  4096 Aug 23 15:59 pg_snapshots
drwx------ 2 gpadmin gpadmin  4096 Aug 23 15:59 pg_serial
drwx------ 2 gpadmin gpadmin  4096 Aug 23 15:59 pg_notify
drwx------ 4 gpadmin gpadmin  4096 Aug 23 15:59 pg_multixact
drwx------ 2 gpadmin gpadmin  4096 Aug 23 15:59 pg_dynshmem
drwx------ 2 gpadmin gpadmin  4096 Aug 23 15:59 pg_cryptokeys
drwx------ 2 gpadmin gpadmin  4096 Aug 23 15:59 pg_commit_ts
-rw------- 1 gpadmin gpadmin     3 Aug 23 15:59 PG_VERSION
-rw------- 1 gpadmin gpadmin  1636 Aug 23 15:59 pg_ident.conf
drwx------ 2 gpadmin gpadmin  4096 Aug 23 15:59 pg_xact
drwx------ 2 gpadmin gpadmin  4096 Aug 23 15:59 pg_subtrans
drwx------ 2 gpadmin gpadmin  4096 Aug 23 15:59 pg_distributedlog
-rw------- 1 gpadmin gpadmin 31637 Aug 23 15:59 postgresql.conf
-rw------- 1 gpadmin gpadmin    10 Aug 23 15:59 internal.auto.conf
-rw------- 1 gpadmin gpadmin  4915 Aug 23 16:03 pg_hba.conf
drwx------ 7 gpadmin gpadmin  4096 Aug 23 16:03 base
drwx------ 3 gpadmin gpadmin  4096 Aug 23 16:03 pg_replslot
drwx------ 3 gpadmin gpadmin  4096 Aug 23 16:03 pg_wal
-rw------- 1 gpadmin gpadmin   120 Aug 23 16:03 postgresql.auto.conf
drwx------ 2 gpadmin gpadmin  4096 Aug 23 16:14 log
-rw------- 1 gpadmin gpadmin    38 Aug 23 16:14 current_logfiles
-rw------- 1 gpadmin gpadmin   112 Aug 23 16:14 postmaster.opts
-rw------- 1 gpadmin gpadmin    89 Aug 23 16:14 postmaster.pid
drwx------ 2 gpadmin gpadmin  4096 Aug 23 16:14 pg_stat
drwx------ 2 gpadmin gpadmin  4096 Aug 23 16:29 global
drwx------ 4 gpadmin gpadmin  4096 Aug 23 16:44 pg_logical
-rw------- 1 gpadmin gpadmin 32768 Aug 23 16:44 fts_probe_file.bak
drwx------ 2 gpadmin gpadmin  4096 Aug 23 16:44 pg_stat_tmp
```

Exercise: Explore the data directory and subdirectories. Take a look at the configuration files.

# 15. Instance processes

======================

- postmaster process - the process with the data directory in its name (-D ...) - this process is the parent for all other database processes and it handles connections to this instance

- logger process - writes log entries in the log file

- stats collector process - statistics collector

- writer process - background database writer

- sweeper process - related to workload management and prioritization

- checkpoint process - performs checkpoints

- WAL Send Server - sends data to standby server

- seqserver - sequence server

- ftsprobe - FTS

- conXXX - connection worker process

- primary ... - primary communication processes

- mirror ... - mirror communication processes

- master

```
[gpadmin@mdw ~]$ ps aux|grep 5432
gpadmin   4409  0.0  0.4 209960 39776 ?        Ss   16:14   0:00 /usr/local/cloudberry-db/bin/postgres -D /data0/database/master/gpseg-1 -p 5432 -c gp_role=dispatch
gpadmin   4410  0.0  0.0  45544  5160 ?        Ss   16:14   0:00 postgres:  5432, master logger process
gpadmin   4412  0.0  0.1 210256  9484 ?        Ss   16:14   0:00 postgres:  5432, checkpointer
gpadmin   4413  0.0  0.0 210124  7440 ?        Ss   16:14   0:00 postgres:  5432, background writer
gpadmin   4414  0.0  0.1 210124 10304 ?        Ss   16:14   0:00 postgres:  5432, walwriter
gpadmin   4415  0.0  0.1 211544 12068 ?        Ss   16:14   0:00 postgres:  5432, autovacuum launcher
gpadmin   4416  0.0  0.0  45768  5672 ?        Ss   16:14   0:00 postgres:  5432, stats collector
gpadmin   4417  0.0  0.2 278596 22164 ?        Ssl  16:14   0:00 postgres:  5432, dtx recovery process
gpadmin   4418  0.0  0.2 278416 21624 ?        Ssl  16:14   0:00 postgres:  5432, ftsprobe process
gpadmin   4427  0.0  0.1 211492 11244 ?        Ss   16:14   0:00 postgres:  5432, logical replication launcher
gpadmin   4428  0.0  0.2 277792 17748 ?        Ssl  16:14   0:00 postgres:  5432, pg_cron launcher
gpadmin   4429  0.0  0.0 210124  5316 ?        Ss   16:14   0:00 postgres:  5432, sweeper process
gpadmin   4846  0.0  0.5 294692 48516 ?        Ssl  16:25   0:00 postgres:  5432, gpadmin gpadmin [local] con46 cmd172 idle
```

- primary

```
[gpadmin@mdw ~]$ ps aux|grep 40000
gpadmin   4373  0.0  0.5 212912 41404 ?        Ss   16:14   0:00 /usr/local/cloudberry-db/bin/postgres -D /data0/database/primary/gpseg0 -p 40000 -c gp_role=execute
gpadmin   4377  0.0  0.0  45540  5272 ?        Ss   16:14   0:00 postgres: 40000, logger process
gpadmin   4390  0.0  0.1 213212  9328 ?        Ss   16:14   0:00 postgres: 40000, checkpointer
gpadmin   4391  0.0  0.0 213076  7856 ?        Ss   16:14   0:00 postgres: 40000, background writer
gpadmin   4392  0.0  0.1 213076 10428 ?        Ss   16:14   0:00 postgres: 40000, walwriter
gpadmin   4393  0.0  0.1 213784  9948 ?        Ss   16:14   0:00 postgres: 40000, autovacuum launcher
gpadmin   4394  0.0  0.0  45768  5816 ?        Ss   16:14   0:00 postgres: 40000, stats collector
gpadmin   4395  0.0  0.0 213624  7984 ?        Ss   16:14   0:00 postgres: 40000, logical replication launcher
gpadmin   4396  0.0  0.0 212912  4480 ?        Ss   16:14   0:00 postgres: 40000, sweeper process
gpadmin   4400  0.0  0.1 214868 12432 ?        Ss   16:14   0:00 postgres: 40000, walsender gpadmin 172.17.0.2(37278) streaming 0/100F9088
```

- mirror
```
[gpadmin@mdw ~]$ ps aux|grep 41000
gpadmin   4375  0.0  0.5 212912 41196 ?        Ss   16:14   0:00 /usr/local/cloudberry-db/bin/postgres -D /data0/database/mirror/gpseg0 -p 41000 -c gp_role=execute
gpadmin   4379  0.0  0.0  45540  5160 ?        Ss   16:14   0:00 postgres: 41000, logger process
gpadmin   4383  0.0  0.1 213344 10908 ?        Ss   16:14   0:00 postgres: 41000, startup recovering 000000010000000000000004
gpadmin   4385  0.0  0.1 212912  8352 ?        Ss   16:14   0:00 postgres: 41000, checkpointer
gpadmin   4386  0.0  0.0 212912  6260 ?        Ss   16:14   0:00 postgres: 41000, background writer
gpadmin   4387  0.1  0.1 213788  9740 ?        Ss   16:14   0:04 postgres: 41000, walreceiver streaming 0/100F9088
```

Exercise: Try to identify the processes for the instances in your cluster.

# 16. Database log files

Each instance has its own log files, which are located under <data_directory>/log directory.
```
[gpadmin@mdw log]$ pwd
/data0/database/primary/gpseg0/log
[gpadmin@mdw log]$ ls -ltr
total 20
-rw------- 1 gpadmin gpadmin 8842 Aug 23 16:14 gpdb-2023-08-23_155951.csv
-rw------- 1 gpadmin gpadmin  468 Aug 23 16:14 startup.log
-rw------- 1 gpadmin gpadmin 3269 Aug 23 16:17 gpdb-2023-08-23_161424.csv
```

The standard log file name is gpdb_\<date\>-\<time\>.csv

Exercise: Look at the log file and do different things in the database (create table, run queries, etc.)

# 17. AO/AOCO Tables

- Heap Tables

The default table type in CBDB is 'heap'. In heap tables rows are stored in pages and a data file can have many pages. Heap tables support all SQL operations - SELECT, INSERT, UPDATE, DELETE, TRUNCATE.

To support this functionality rows in CBDB have row header. Heap tables do not support compression.

- AO tables do not have row header and support compression. This makes them appropriate choice for huge fact tables.

- AO CO (Column Oriented) tables

Row oriented storage is not optimal when executing queries on single columns (avg, sum, etc.).

Column oriented tables store data by column, so querying one column does not depend on the number and size of other columns.

AOCO tables also support compression, which is even better than AO because of the homogenity of the data in single file (single column all data of same type)

Exercise: Create heap table, AO table, AOCO table. Use the \d+ psql command to see the result.

# 18. External tables

CBDB supports external tables. These are tables that have the table structure in the database, but point to data outside of the database:

- data can be in file on the local filesystem

- data can be in file on a remote host (gpfdist server used)

- data can be in HDFS (gphdfs type)

- data can be generated on the fly via command

External tables are useful when importing data into CBDB (insert into table select \* from ext\_table) because the data ingestion happens in parallel from segments as opposed to serial ingestion from master.

Exercise: Create external tables of different kinds and work with them to get comfortable.


# 19. Workload management

Resource queues - CBDB has a concept of RQ. RQ is a set of sessions that have similar requirements and use common pool of resources. Every user can be assigned to a RQ.

Priority - each resource queue can be assigned a priority. Every session which is assigned to this RQ will have the specified priority. Priority can be assigned to a single session also with

gp\_adjust\_priority() function.

Exercise: create user, create RQ, assign the user to the RQ, run query and observe the RQ state.