**CBDB Crash Course**

[0. Background - Database concepts:](#_m7j4d8j1mhe3)

[1. What is CBDB](#_oc6ibh8u8lma)

[2. Documentation](#_6i3dkqtdh5q4)

[3. Installing CBDB](#_cwum3qrnlhdp)

[4. Creating a cluster](#_jk1ne6o532a4)

[5. Cluster description](#_flzvjzjb9sm9)

[6. Management utilities](#_q79ghv348wah)

[7. Starting and stopping cluster](#_33nsed5h4gdd)

[8. Cluster state](#_2sh0leiruqt4)

[9. Adding mirrors](#_9pvb695obybl)

[10. FTS, segment failures and recovering mirrors](#_vagg1jllzap1)

[11. Standby Coordinator](#_m6f2ypn9cdd1)

[12. Expansion](#_2vnkde86ahiy)

[15. Performance check](#_genafrtxo08y)

[16. Backup and Restore](#_44193hvob3dw)

[17. User data and table distribution](#_jo95xq56xzyt)

[18. Database catalog](#_gugbybnjciy9)

[19. Data directories](#_fykbh8p2sa96)

[20. Instance processes](#_7dlt4dz86owi)

[21. Database log files](#_ox2006q3tahh)

[22. AO/AOCO Tables](#_dayp44ncnoul)

[23. External tables](#_486vxlfw5sax)

[24. CBDB Versioning and Upgrades](#_u5271ivjchgy)

[25. Workload management](#_gkgh6qq0z0xl)

Immersion link (highly recommended)

1. [cbdb standbox](https://github.com/cloudberrydb/bootcamp/tree/main/000-cbdb-sandbox)
2. [cbdb tutorials](https://github.com/cloudberrydb/bootcamp/tree/main/101-cbdb-tutorials)

# **0. Background - Database concepts** :

Before starting this crash course, spend some time go get familiar with how (single instance) databases work. If you already have some knowledge and experience with Oracle, MySQL or especially Postgres - this is great.

Databases (relational databases) are pieces of software that are used to store and manage/process data. Usually these databases are built with the client/server concept - the database is implemented as a server and multiple clients can connect and read or update the data.

The clients usually use SQL language to access the data (or some dialect of the SQL language specification). The clients can be different implementations - proprietary client libraries or ODBC/JDBC compliant.

Database data is usually stored in objects called tables. Tables have predefined structure (columns) and have zero or multiple rows.

Tables can be grouped in logical entities called 'schemas' (or namespaces).

Tables/schemas are located in a 'database' entity. Some database software supports multiple databases per instance (MySQL, Postgres), others support one database per instance (Oracle).

Along with tables there are supporting objects such as indexes, sequences, views, etc.

The database system needs to maintain some metadata - called the database catalog. The database catalog contains information about the data objects and supporting objects as well as anything else that needs to be stored on system level (user authentication, etc.).

SQL (Structured Query Language) is a descriptive language, not imperative language. Therefore it describes what the user needs, not how to get it. When the user describes what he needs, the database need to decide how to get it. This process is called query optimization. The end result from this process is a query plan, which is a step by step instruction how to get the result.

# 1. What is CBDB

Cloudberry Database is Massively Parallel Database. This means that unlike usual database systems, which have one instance to manage the data and connections, Cloudberry can have many instances.One of the instances is called the 'coordinator instance' it handles user connections and query parsing/planning. The rest of the segments are 'worker segments' or segments. They store the data and execute the query plan.

Cloudberry originally started from Postgres (14.4) and therefore is very similar in some aspects. It is also very different in other aspects. The SQL language dialect and client connectivity is almost the same, while the query processing and some of the data storage is completely different. There are also many new additions that are missing in Postgres.

One important thing to remember is that data in CBDB is stored in the segment instances and segment instances do not share their data. Coordinator does not store any user data.

# 2. Documentation

Here is a link to the documentation \<https://hashdata.feishu.cn/docx/CzxgdsynyoHnqWx0GNUcSuwYn0d>. Now is the time to do a quick read of the documentation. No need to worry if you don't understand everything.

Exercise: Download CBDB guides and review them quickly to find out what does each guide contain. Read the beginning of the Installation Guide to understand the concepts in CBDB cluster.

# 3. Installing CBDB

- Read up the CBDB Installation Guide. The guide has some conceptual information about CBDB and the steps to install the software.

Exercise: Install the CBDB software:

- Check the system requirements

- Set the OS parameters

- Exchange keys

- Run the installer on the Coordinator host

- Install on all hosts

- Validate system

# 4. Creating a cluster

Read the rest of the CBDB Installation Guide.

Exercise: Create CBDB cluster

- Initialization Host file

- Cluster configuration file

- gpinitsystem

- Explore environment variables:

- Coordinator\_DATA\_DIRECTORY

- GPHOME

# 5. Cluster description

Cluster has one Coordinator host and many segment hosts. These are usually named "mdw" and "sdwXX" respectively. Therefore if somebody is referring to "mdw" he is referring to the "Coordinator host".

Similarly when somebody is referring to "sdw10" he is referring to the 10th segment host. Coordinator host usually contains only one instance - the Coordinator instance. The segment hosts can contain many worker instances.

Every instance has its own set of processes, own data directory and own listening port. For example usually the listening port of the Coordinator instance (where all clients will connect) is 5432.

Every segment instance has its own listening port (the base port is specified in the cluster configuration file).

Instances can have 2 roles - primary and mirror. Primary instances serve database queries. Mirror instances simply track and record data changes in primary instances, but do not serve database queries. If the primary instance goes down for some reason, then the corresponding mirror instance transitions to primary role and starts serving queries (the original primary instance, currently down, is marked as mirror). We will talk later how to recover failed instances.

The cluster information is stored in the "gp\_segment\_configuration" table. It looks like this (use the "psql" command to connect to the database in order to execute queries):

<blockquote>
<pre><code>
test=# select * from gp_segment_configuration ;

 dbid | content | role | preferred_role | mode | status | port |  hostname  |  address   |       datadir
------+---------+------+----------------+------+--------+------+------------+------------+----------------------
    1 |      -1 | p    | p              | n    | u      | 5432 | mdw | mdw | /data/master/gpseg-1
    2 |       0 | p    | p              | s    | u      | 6000 | mdw | mdw | /data/primary/gpseg0
    4 |       0 | m    | m              | s    | u      | 7000 | mdw | mdw | /data/mirror/gpseg0
    3 |       1 | p    | p              | s    | u      | 6001 | mdw | mdw | /data/primary/gpseg1
    5 |       1 | m    | m              | s    | u      | 7001 | mdw | mdw | /data/mirror/gpseg1
(5 rows)

</pre></code>
</blockquote>

Columns:

- dbid - uniquely identifies a segment

- content - uniquely identifies segment pair (primary and mirror). The primary and corresponding mirror will have the same content id, but different dbid. The Coordinator has content of -1. The worker instances have content 0,1,2,3...

- role - the current role of the segment

- preferred\_role - the role of the segment in the original configuration (if an instance that was originally mirror has taken over and became primary now - these will be different)

- mode - 's' (in-sync), 'c' (in-changetracking), 'r'(in-recovery)

- status - 'u' (up), 'd' (down)

- port - segment listening port. For clients only the listening port of the Coordinator is important. The segment listening ports are important for the Coordinator to communicate with them.

- hostname - hostname of this segment

- address - each host can have different network controllers with different IP addresses and different names associated with them

- datadir - Segment instance data directory.

Exercise: Connect to the CBDB cluster that you created and take a look at the "gp\_segment\_configuration" table. Try to make sense of the rows and columns and connect it to the cluster configuration file that you used to run gpinitsystem.

# 6. Management utilities

- gpstop - stops database cluster

- gpstart - starts database cluster

- psql - command line client

- gpconfig - show/change configuration parameters

- gpdeletesystem - deletes a cluster

- pg\_dump, gp\_dumpall, gpbackup, gprestore - backup and restore utilities

- gpinitstanby, gpactivatestandby - standby Coordinator instance management

- gprecoverseg - segment recovery

- gplogfilter - segment log collection

- gpfdist, gpload - external tables

- gpssh, gpscp, gpssh-exkeys - cluster navigation

- Logging - all utilities write log files under ~/gpAdminLogs/ - one file per day

Exercise: Read the help for these tools (\<tool\> --help)

# 7. Starting and stopping cluster

- gpstart

<blockquote>
<pre><code>

[gpadmin@mdw ~]$ gpstart
20230814:14:55:06:010519 gpstart:mdw:gpadmin-[INFO]:-Starting gpstart with args:
20230814:14:55:06:010519 gpstart:mdw:gpadmin-[INFO]:-Gathering information and validating the environment...
20230814:14:55:06:010519 gpstart:mdw:gpadmin-[INFO]:-Cloudberry Binary Version: 'postgres (Cloudberry Database) 1.4.0 build commit:e83e3ffc22d538deb2dbceeeae0138ca2de064e6'
20230814:14:55:06:010519 gpstart:mdw:gpadmin-[INFO]:-Cloudberry Catalog Version: '302206171'
20230814:14:55:06:010519 gpstart:mdw:gpadmin-[INFO]:-Starting Coordinator instance in admin mode
20230814:14:55:06:010519 gpstart:mdw:gpadmin-[INFO]:-CoordinatorStart pg_ctl cmd is env GPSESSID=0000000000 GPERA=None $GPHOME/bin/pg_ctl -D /data/master/gpseg-1 -l /data/master/gpseg-1/log/startup.log -w -t 600 -o " -p 5432 -c gp_role=utility " start
20230814:14:55:06:010519 gpstart:mdw:gpadmin-[INFO]:-Obtaining Cloudberry Coordinator catalog information
20230814:14:55:06:010519 gpstart:mdw:gpadmin-[INFO]:-Obtaining Segment details from coordinator...
20230814:14:55:06:010519 gpstart:mdw:gpadmin-[INFO]:-Setting new coordinator era
20230814:14:55:06:010519 gpstart:mdw:gpadmin-[INFO]:-Coordinator Started...
20230814:14:55:06:010519 gpstart:mdw:gpadmin-[INFO]:-Shutting down coordinator
20230814:14:55:07:010519 gpstart:mdw:gpadmin-[INFO]:---------------------------
20230814:14:55:07:010519 gpstart:mdw:gpadmin-[INFO]:-Coordinator instance parameters
20230814:14:55:07:010519 gpstart:mdw:gpadmin-[INFO]:---------------------------
20230814:14:55:07:010519 gpstart:mdw:gpadmin-[INFO]:-Database                 = template1
20230814:14:55:07:010519 gpstart:mdw:gpadmin-[INFO]:-Coordinator Port              = 5432
20230814:14:55:07:010519 gpstart:mdw:gpadmin-[INFO]:-Coordinator directory         = /data/master/gpseg-1
20230814:14:55:07:010519 gpstart:mdw:gpadmin-[INFO]:-Timeout                  = 600 seconds
20230814:14:55:07:010519 gpstart:mdw:gpadmin-[INFO]:-Coordinator standby           = Off
20230814:14:55:07:010519 gpstart:mdw:gpadmin-[INFO]:---------------------------------------
20230814:14:55:07:010519 gpstart:mdw:gpadmin-[INFO]:-Segment instances that will be started
20230814:14:55:07:010519 gpstart:mdw:gpadmin-[INFO]:---------------------------------------
20230814:14:55:07:010519 gpstart:mdw:gpadmin-[INFO]:-   Host         Datadir                Port   Role
20230814:14:55:07:010519 gpstart:mdw:gpadmin-[INFO]:-   mdw   /data/primary/gpseg0   6000   Primary
20230814:14:55:07:010519 gpstart:mdw:gpadmin-[INFO]:-   mdw   /data/mirror/gpseg0    7000   Mirror
20230814:14:55:07:010519 gpstart:mdw:gpadmin-[INFO]:-   mdw   /data/primary/gpseg1   6001   Primary
20230814:14:55:07:010519 gpstart:mdw:gpadmin-[INFO]:-   mdw   /data/mirror/gpseg1    7001   Mirror

Continue with Cloudberry instance startup Yy|Nn (default=N):
> y
20230814:14:55:09:010519 gpstart:mdw:gpadmin-[INFO]:-Commencing parallel primary and mirror segment instance startup, please wait...
20230814:14:55:10:010519 gpstart:mdw:gpadmin-[INFO]:-Process results...
20230814:14:55:10:010519 gpstart:mdw:gpadmin-[INFO]:-Warning: Permanently added 'mdw,192.168.178.113' (ECDSA) to the list of known hosts.

20230814:14:55:10:010519 gpstart:mdw:gpadmin-[INFO]:-----------------------------------------------------
20230814:14:55:10:010519 gpstart:mdw:gpadmin-[INFO]:-   Successful segment starts                                            = 4
20230814:14:55:10:010519 gpstart:mdw:gpadmin-[INFO]:-   Failed segment starts                                                = 0
20230814:14:55:10:010519 gpstart:mdw:gpadmin-[INFO]:-   Skipped segment starts (segments are marked down in configuration)   = 0
20230814:14:55:10:010519 gpstart:mdw:gpadmin-[INFO]:-----------------------------------------------------
20230814:14:55:10:010519 gpstart:mdw:gpadmin-[INFO]:-Successfully started 4 of 4 segment instances
20230814:14:55:10:010519 gpstart:mdw:gpadmin-[INFO]:-----------------------------------------------------
20230814:14:55:10:010519 gpstart:mdw:gpadmin-[INFO]:-Starting Coordinator instance mdw directory /data/master/gpseg-1
20230814:14:55:10:010519 gpstart:mdw:gpadmin-[INFO]:-CoordinatorStart pg_ctl cmd is env GPSESSID=0000000000 GPERA=801570645e44e510_230814145506 $GPHOME/bin/pg_ctl -D /data/master/gpseg-1 -l /data/master/gpseg-1/log/startup.log -w -t 600 -o " -p 5432 -c gp_role=dispatch " start
20230814:14:55:10:010519 gpstart:mdw:gpadmin-[INFO]:-Command pg_ctl reports Coordinator mdw instance active
20230814:14:55:10:010519 gpstart:mdw:gpadmin-[INFO]:-Connecting to db template1 on host localhost
20230814:14:55:10:010519 gpstart:mdw:gpadmin-[INFO]:-No standby coordinator configured.  skipping...
20230814:14:55:10:010519 gpstart:mdw:gpadmin-[INFO]:-Database successfully started

</pre></code>
</blockquote>

- gpstop

<blockquote>
<pre><code>
[gpadmin@mdw ~]$ gpstop
20230814:16:02:32:015699 gpstop:mdw:gpadmin-[INFO]:-Starting gpstop with args:
20230814:16:02:32:015699 gpstop:mdw:gpadmin-[INFO]:-Gathering information and validating the environment...
20230814:16:02:32:015699 gpstop:mdw:gpadmin-[INFO]:-Obtaining Cloudberry Coordinator catalog information
20230814:16:02:32:015699 gpstop:mdw:gpadmin-[INFO]:-Obtaining Segment details from coordinator...
20230814:16:02:32:015699 gpstop:mdw:gpadmin-[INFO]:-Cloudberry Version: 'postgres (Cloudberry Database) 1.4.0 build commit:e83e3ffc22d538deb2dbceeeae0138ca2de064e6'
20230814:16:02:32:015699 gpstop:mdw:gpadmin-[INFO]:---------------------------------------------
20230814:16:02:32:015699 gpstop:mdw:gpadmin-[INFO]:-Coordinator instance parameters
20230814:16:02:32:015699 gpstop:mdw:gpadmin-[INFO]:---------------------------------------------
20230814:16:02:32:015699 gpstop:mdw:gpadmin-[INFO]:-   Coordinator Cloudberry instance process active PID   = 10694
20230814:16:02:32:015699 gpstop:mdw:gpadmin-[INFO]:-   Database                                             = template1
20230814:16:02:32:015699 gpstop:mdw:gpadmin-[INFO]:-   Coordinator port                                     = 5432
20230814:16:02:32:015699 gpstop:mdw:gpadmin-[INFO]:-   Coordinator directory                                = /data/master/gpseg-1
20230814:16:02:32:015699 gpstop:mdw:gpadmin-[INFO]:-   Shutdown mode                                        = smart
20230814:16:02:32:015699 gpstop:mdw:gpadmin-[INFO]:-   Timeout                                              = 120
20230814:16:02:32:015699 gpstop:mdw:gpadmin-[INFO]:-   Shutdown Coordinator standby host                    = Off
20230814:16:02:32:015699 gpstop:mdw:gpadmin-[INFO]:---------------------------------------------
20230814:16:02:32:015699 gpstop:mdw:gpadmin-[INFO]:-Segment instances that will be shutdown:
20230814:16:02:32:015699 gpstop:mdw:gpadmin-[INFO]:---------------------------------------------
20230814:16:02:32:015699 gpstop:mdw:gpadmin-[INFO]:-   Host         Datadir                Port   Status
20230814:16:02:32:015699 gpstop:mdw:gpadmin-[INFO]:-   mdw   /data/primary/gpseg0   6000   u
20230814:16:02:32:015699 gpstop:mdw:gpadmin-[INFO]:-   mdw   /data/mirror/gpseg0    7000   u
20230814:16:02:32:015699 gpstop:mdw:gpadmin-[INFO]:-   mdw   /data/primary/gpseg1   6001   u
20230814:16:02:32:015699 gpstop:mdw:gpadmin-[INFO]:-   mdw   /data/mirror/gpseg1    7001   u

Continue with Cloudberry instance shutdown Yy|Nn (default=N):
> y
20230814:16:02:34:015699 gpstop:mdw:gpadmin-[INFO]:-Commencing Coordinator instance shutdown with mode='smart'
20230814:16:02:34:015699 gpstop:mdw:gpadmin-[INFO]:-Coordinator segment instance directory=/data/master/gpseg-1
20230814:16:02:34:015699 gpstop:mdw:gpadmin-[INFO]:-Stopping coordinator segment and waiting for user connections to finish ...
server shutting down
20230814:16:02:35:015699 gpstop:mdw:gpadmin-[INFO]:-Attempting forceful termination of any leftover coordinator process
20230814:16:02:35:015699 gpstop:mdw:gpadmin-[INFO]:-Terminating processes for segment /data/master/gpseg-1
20230814:16:02:35:015699 gpstop:mdw:gpadmin-[INFO]:-No standby coordinator host configured
20230814:16:02:35:015699 gpstop:mdw:gpadmin-[INFO]:-Targeting dbid [2, 4, 3, 5] for shutdown
20230814:16:02:35:015699 gpstop:mdw:gpadmin-[INFO]:-Commencing parallel primary segment instance shutdown, please wait...
20230814:16:02:35:015699 gpstop:mdw:gpadmin-[INFO]:-0.00% of jobs completed
20230814:16:02:36:015699 gpstop:mdw:gpadmin-[INFO]:-100.00% of jobs completed
20230814:16:02:36:015699 gpstop:mdw:gpadmin-[INFO]:-Commencing parallel mirror segment instance shutdown, please wait...
20230814:16:02:36:015699 gpstop:mdw:gpadmin-[INFO]:-0.00% of jobs completed
20230814:16:02:36:015699 gpstop:mdw:gpadmin-[INFO]:-100.00% of jobs completed
20230814:16:02:36:015699 gpstop:mdw:gpadmin-[INFO]:-----------------------------------------------------
20230814:16:02:36:015699 gpstop:mdw:gpadmin-[INFO]:-   Segments stopped successfully      = 4
20230814:16:02:36:015699 gpstop:mdw:gpadmin-[INFO]:-   Segments with errors during stop   = 0
20230814:16:02:36:015699 gpstop:mdw:gpadmin-[INFO]:-----------------------------------------------------
20230814:16:02:36:015699 gpstop:mdw:gpadmin-[INFO]:-Successfully shutdown 4 of 4 segment instances
20230814:16:02:36:015699 gpstop:mdw:gpadmin-[INFO]:-Database successfully shutdown with no errors reported
</pre></code>
</blockquote>

Exercise: Read the log entries for gpstop and gpstart and try to understand what they mean. Read and exercise the different options for gpstart/gpstop.

# 8. Cluster state

- gpstate

gpstate is the utility that can give you information about the state of the cluster. It has different arguments to show different aspects of the state.

<pre><code>
<blockquote>

[gpadmin@mdw ~]$ gpstate
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-Starting gpstate with args:
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-local Cloudberry Version: 'postgres (Cloudberry Database) 1.4.0 build commit:e83e3ffc22d538deb2dbceeeae0138ca2de064e6'
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-coordinator Cloudberry Version: 'PostgreSQL 14.4 (Cloudberry Database 1.4.0 build commit:e83e3ffc22d538deb2dbceeeae0138ca2de064e6) on x86_64-pc-linux-gnu, compiled by gcc (GCC) 10.2.1 20210130 (Red Hat 10.2.1-11), 64-bit compiled on Aug  3 2023 10:15:47'
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-Obtaining Segment details from coordinator...
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-Gathering data from segments...
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-Cloudberry instance status summary
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-----------------------------------------------------
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Coordinator instance                                      = Active
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Coordinator standby                                       = No coordinator standby configured
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Total segment instance count from metadata                = 4
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-----------------------------------------------------
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Primary Segment Status
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-----------------------------------------------------
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Total primary segments                                    = 2
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Total primary segment valid (at coordinator)              = 2
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Total primary segment failures (at coordinator)           = 0
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Total number of postmaster.pid files missing              = 0
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Total number of postmaster.pid files found                = 2
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs missing               = 0
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs found                 = 2
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Total number of /tmp lock files missing                   = 0
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Total number of /tmp lock files found                     = 2
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Total number postmaster processes missing                 = 0
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Total number postmaster processes found                   = 2
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-----------------------------------------------------
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Mirror Segment Status
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-----------------------------------------------------
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Total mirror segments                                     = 2
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Total mirror segment valid (at coordinator)               = 2
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Total mirror segment failures (at coordinator)            = 0
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Total number of postmaster.pid files missing              = 0
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Total number of postmaster.pid files found                = 2
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs missing               = 0
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs found                 = 2
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Total number of /tmp lock files missing                   = 0
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Total number of /tmp lock files found                     = 2
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Total number postmaster processes missing                 = 0
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Total number postmaster processes found                   = 2
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Total number mirror segments acting as primary segments   = 0
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-   Total number mirror segments acting as mirror segments    = 2
20230814:16:23:34:017256 gpstate:mdw:gpadmin-[INFO]:-----------------------------------------------------
</pre></code>
</blockquote>

- gp_segment_configuration

gp\_segment\_configuration expresses the 'Coordinator instance' knowledge about the state of the cluster.

Exercise: Look at the cluster state and try to connect the information from gpstate and gp\_segment\_configuration.

# 9. Adding mirrors

How CBDB mirroring works

Each segment can be in two roles - primary or mirror. Primary role - servers user queries. Mirror role - tracks changes on primary, does not serve user queries.

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

Exercise: Add mirrors to your cluster. If your cluster already have mirrors - delete the cluster and recreate without mirrors (removing mirror segments is not supported).

# 10. FTS, segment failures and recovering mirrors

- CBDB has a Fault Tolerant Service that monitors the cluster and makes sure that work continues with working segments. When segment does down, it performs transitions to always have available primary instance for every content. If both instances for one content go down (primary does down, mirror goes down) - this is known as "double fault" and database is non-operable.

- FTS service runs on Coordinator in the "ftsprober" process. At certain intervals the prober will scan segments and if there is difference with the last known configuration, it will perform transitions accordingly.

Information about the transition event is recorded in the Coordinator log file and in "gp\_configuration\_history" and the instance status is updated in "gp\_segment\_configuration"

To recover a segment which is down, use the "gprecoverseg" utility. It will inspect "gp\_segment\_configuration" table, will find out the segment marked "down" and will attempt to recover them from the corresponding "primary" segment (which of course needs to be up and running).

Investigating segment failures:

- look at "gp\_segment\_configuration" to identify the failed segments and their mirrors

- look at the Coordinator log file to find out when did the event happen (FTS log entries are prefixed with "FTS:")

- look at the "gp\_configuration\_history" table to see the recorded events

- look at the primary and mirror log files to find out the reason for the segment failure

- once the failure has been understood, run "gprecoverseg" to recover the segments

- you can monitor the recovery progress with "gpstate -e"

Exercise: Identify the processes for one of your database instances and terminate it. Track gp\_segment\_configuration to see the change. Follow up with the Coordinator log file and gp\_segment\_configuration.

Recover the failed segment. Verify in gp\_segment\_configuration that everything is recovered.

# 11. Standby Coordinator

Coordinator instance is a single point of failure. This is why it is recommended to configure and maintain a 'standby Coordinator' instance. This instance is usually created on a special server - standby Coordinator server ("smdw").

The command to create standby Coordinator is "gpinitstandby" (executed from the Coordinator server).

- gpinitstandby -s smdw

The command to resync standby Coordinator that is out-of-sync is:

- gpinitstandby -n

The command to remove standby Coordinator is:

- gpinitstandby -r

After standby instance creation, you can observe the new instance in "gp\_segment\_configuration" with content=-1 and role='m'.

If Coordinator server is down or Coordinator instance is down, then the standby Coordinator instance can be promoted to Coordinator instance with the command:

- gpactivatestandby (executed from the standby server)

At this point the standby Coordinator transitions to Coordinator and the original Coordinator is transitioned to standby instance (but is down). Changes can be observed in "gp\_segment\_configuration".

Exercise: Initialize standby Coordinator. Remove it. Initialize it again. Activate the standby Coordinator. Initialize another standby Coordinator at the original Coordinator. Activate the standby Coordinator.

Track gp\_segment\_configuration to understand the changes.

# 12. Expansion

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

# 13. Performance check

"gpcheckperf" utility checks performance on a set of hosts (cluster):

- IO performance per host (-r d) - gpcheckperf will use "dd" to perform

- read test

- write test

- network performance (-r n|N|M)

- n = sequential

- N = parallel (must use even number of hosts)

- M = full matrix mode

- memory bandwidth test per host (-r s) - the utility uses the STREAM benchmark program to measure sustainable memory bandwidth (in MB/s).

Exercise: Run gpcheckperf with the various options and interpret the results.

# 14. Backup and Restore

- pg\_dump - connects to Coordinator and does the requested backup (see parameters)

- gpbackup, gprestore - parallel backup into segment data directories, parallel restore

Exercise:

- Use pg\_dump to backup a single table. Use pg\_dump to backup DDL for a single table and the entire database.

- Use gpbackup to backup your database. Analyze gpbackup output and find the backup log files on Coordinator and on segments.


# 15. User data and table distribution

- Coordinator does not have user data

- segments have user data

- data is not shared

- create table (...) distributed by (...)

- create table (...) distributed randomly

- gp\_segment\_id

<pre><code>
<blockquote>

test=# create table test(a int, b int) distributed by (a);

CREATE TABLE

Time: 392.716 ms

test=#

test=# \d+ test

Table "public.test"

Column | Type | Modifiers | Storage | Description

--------+---------+-----------+---------+-------------

a | integer | | plain |

b | integer | | plain |

Has OIDs: no

Distributed by: (a)

test=# select \* from test;

a | b

---+---

(0 rows)

Time: 49.058 ms

test=# insert into test values (1,100);

INSERT 0 1

Time: 211.875 ms

test=# select gp\_segment\_id, \* from test;

gp\_segment\_id | a | b

---------------+---+-----

0 | 1 | 100

(1 row)

Time: 16.190 ms

test=# insert into test values (2,100);

INSERT 0 1

Time: 97.471 ms

test=# select gp\_segment\_id, \* from test;

gp\_segment\_id | a | b

---------------+---+-----

0 | 1 | 100

1 | 2 | 100

(2 rows)

Time: 18.732 ms

test=# insert into test values (1,300);

INSERT 0 1

Time: 66.567 ms

test=# select gp\_segment\_id, \* from test;

gp\_segment\_id | a | b

---------------+---+-----

0 | 1 | 100

0 | 1 | 300

1 | 2 | 100

(3 rows)

test=# create table test(a int, b int) distributed randomly;

CREATE TABLE

Time: 257.044 ms

test=# \d+ test

Table "public.test"

Column | Type | Modifiers | Storage | Description

--------+---------+-----------+---------+-------------

a | integer | | plain |

b | integer | | plain |

Has OIDs: no

Distributed randomly

test=# select \* from test;

a | b

---+---

(0 rows)

Time: 1.491 ms

test=# insert into test values (1,100);

INSERT 0 1

Time: 192.817 ms

test=# select gp\_segment\_id, \* from test;

gp\_segment\_id | a | b

---------------+---+-----

1 | 1 | 100

(1 row)

Time: 25.568 ms

test=# insert into test values (1,100);

INSERT 0 1

Time: 102.292 ms

test=# select gp\_segment\_id, \* from test;

gp\_segment\_id | a | b

---------------+---+-----

0 | 1 | 100

1 | 1 | 100

(2 rows)

Time: 20.445 ms

</pre></code>
</blockquote>

Exercise: Reproduce the above with your own table and observe the effects.

# 16. Database catalog

- located on Coordinator and segments

- pg\_catalog schema

- tables, views, indexes

- object description - pg\_class, pg\_attribute, pg\_type, etc...

- functions

- segment data (Coordinator only tables) - gp\_segment\_configuration, gp\_configuration\_history

- distribution data - gp\_distribution\_policy


# 17. Data directories

Contents of a data directory:

<pre><code>
<blockquote>

drwx------ 7 gpadmin gpadmin    67 Aug 18 17:22 base                        --> Database data storage
-rw------- 1 gpadmin gpadmin    38 Aug 23 00:00 current_logfiles
drwxrwxr-x 3 gpadmin gpadmin    21 Aug 14 13:27 db_analyze
drwx------ 2 gpadmin gpadmin  4096 Aug 22 16:49 global                      --> Global tables and control file
-rw------- 1 gpadmin gpadmin   196 Aug 22 16:49 gpsegconfig_dump
-rw-rw-r-- 1 gpadmin gpadmin   860 Aug 10 17:56 gpssh.conf
-rw------- 1 gpadmin gpadmin    10 Aug 10 17:56 internal.auto.conf
drwx------ 2 gpadmin gpadmin  4096 Aug 23 00:00 log                         --> Database log files
drwx------ 2 gpadmin gpadmin     6 Aug 10 17:56 pg_commit_ts
drwx------ 2 gpadmin gpadmin     6 Aug 10 17:56 pg_cryptokeys
drwx------ 2 gpadmin gpadmin    18 Aug 10 17:56 pg_distributedlog
drwx------ 2 gpadmin gpadmin     6 Aug 10 17:56 pg_dynshmem
-rw-rw-r-- 1 gpadmin gpadmin  4840 Aug 10 17:56 pg_hba.conf                 --> Host based authentication file
-rw------- 1 gpadmin gpadmin  1636 Aug 10 17:56 pg_ident.conf
drwx------ 4 gpadmin gpadmin    68 Aug 22 17:59 pg_logical
drwx------ 4 gpadmin gpadmin    36 Aug 10 17:56 pg_multixact
drwx------ 2 gpadmin gpadmin     6 Aug 10 17:56 pg_notify
drwx------ 2 gpadmin gpadmin     6 Aug 10 17:56 pg_replslot
drwx------ 2 gpadmin gpadmin     6 Aug 10 17:56 pg_serial
drwx------ 2 gpadmin gpadmin     6 Aug 10 17:56 pg_snapshots
drwx------ 2 gpadmin gpadmin     6 Aug 22 16:49 pg_stat
drwx------ 2 gpadmin gpadmin   101 Aug 23 10:21 pg_stat_tmp
drwx------ 2 gpadmin gpadmin    18 Aug 10 17:56 pg_subtrans
drwx------ 2 gpadmin gpadmin     6 Aug 10 17:56 pg_tblspc
drwx------ 2 gpadmin gpadmin     6 Aug 10 17:56 pg_twophase
-rw------- 1 gpadmin gpadmin     3 Aug 10 17:56 PG_VERSION
drwx------ 3 gpadmin gpadmin    60 Aug 10 17:56 pg_wal                      --> Transaction logs
drwx------ 2 gpadmin gpadmin    18 Aug 10 17:56 pg_xact
-rw------- 1 gpadmin gpadmin    88 Aug 10 17:56 postgresql.auto.conf
-rw------- 1 gpadmin gpadmin 32297 Aug 22 16:49 postgresql.conf             --> Database configuration file
-rw------- 1 gpadmin gpadmin   108 Aug 22 16:49 postmaster.opts
-rw------- 1 gpadmin gpadmin    79 Aug 22 16:49 postmaster.pid


</pre></code>
</blockquote>

Exercise: Explore the data directory and subdirectories. Take a look at the configuration files.

# 20. Instance processes

======================

- postgres process - the process with the data directory in its name (-D ...) - this process is the parent for all other database processes and it handles connections to this instance

- logger process - writes log entries in the log file

- stats collector process - statistics collector

- background writer process - background database writer

- sweeper process - related to workload management and prioritization

- checkpointer process - performs checkpoints

- walsender process - sends data to standby server

- ftsprobe - FTS

- conXXX - connection worker process

<pre><code>
<blockquote>

- coordinator

gpadmin  13849     1  0 Aug22 ?        00:00:01 /usr/local/cloudberry-db-1.4.0/bin/postgres -D /data/master/gpseg-1 -p 5432 -c gp_role=dispatch
gpadmin  13850 13849  0 Aug22 ?        00:00:00 postgres:  5432, master logger process
gpadmin  13852 13849  0 Aug22 ?        00:00:00 postgres:  5432, checkpointer
gpadmin  13853 13849  0 Aug22 ?        00:00:00 postgres:  5432, background writer
gpadmin  13854 13849  0 Aug22 ?        00:00:00 postgres:  5432, walwriter
gpadmin  13855 13849  0 Aug22 ?        00:00:00 postgres:  5432, autovacuum launcher
gpadmin  13856 13849  0 Aug22 ?        00:00:01 postgres:  5432, stats collector
gpadmin  13857 13849  0 Aug22 ?        00:00:04 postgres:  5432, dtx recovery process
gpadmin  13858 13849  0 Aug22 ?        00:00:08 postgres:  5432, ftsprobe process
gpadmin  13867 13849  0 Aug22 ?        00:00:00 postgres:  5432, logical replication launcher
gpadmin  13868 13849  0 Aug22 ?        00:00:01 postgres:  5432, ic proxy process
gpadmin  13869 13849  0 Aug22 ?        00:00:04 postgres:  5432, pg_cron launcher
gpadmin  13870 13849  0 Aug22 ?        00:00:01 postgres:  5432, sweeper process

- primary

gpadmin  13734     1  0 Aug22 ?        00:00:02 /usr/local/cloudberry-db-1.4.0/bin/postgres -D /data/primary/gpseg0 -p 6000 -c gp_role=execute
gpadmin  13742 13734  0 Aug22 ?        00:00:00 postgres:  6000, logger process
gpadmin  13748 13734  0 Aug22 ?        00:00:51 postgres:  6000, WAL proposer
gpadmin  13829 13734  0 Aug22 ?        00:00:00 postgres:  6000, checkpointer
gpadmin  13830 13734  0 Aug22 ?        00:00:00 postgres:  6000, background writer
gpadmin  13831 13734  0 Aug22 ?        00:00:00 postgres:  6000, walwriter
gpadmin  13832 13734  0 Aug22 ?        00:00:00 postgres:  6000, autovacuum launcher
gpadmin  13833 13734  0 Aug22 ?        00:00:01 postgres:  6000, stats collector
gpadmin  13834 13734  0 Aug22 ?        00:00:00 postgres:  6000, logical replication launcher
gpadmin  13835 13734  0 Aug22 ?        00:00:01 postgres:  6000, ic proxy process
gpadmin  13836 13734  0 Aug22 ?        00:00:01 postgres:  6000, sweeper process
gpadmin  13886 13734  0 Aug22 ?        00:00:00 postgres:  6000, walsender gpadmin 192.168.178.113(41626) streaming 0/23F67FB8

- mirror

gpadmin  13735     1  0 Aug22 ?        00:00:00 /usr/local/cloudberry-db-1.4.0/bin/postgres -D /data/mirror/gpseg0 -p 7000 -c gp_role=execute
gpadmin  13743 13735  0 Aug22 ?        00:00:00 postgres:  7000, logger process
gpadmin  13745 13735  0 Aug22 ?        00:00:00 postgres:  7000, startup recovering 000000010000000000000008
gpadmin  13751 13735  0 Aug22 ?        00:00:00 postgres:  7000, checkpointer
gpadmin  13753 13735  0 Aug22 ?        00:00:00 postgres:  7000, background writer
gpadmin  13885 13735  0 Aug22 ?        00:00:13 postgres:  7000, walreceiver streaming 0/23F67FB8

</pre></code>
</blockquote>

Exercise: Try to identify the processes for the instances in your cluster.

# 21. Database log files

Each instance has its own log files, which are located under \<data\_directory\>/log directory.

The standard log file name is gpdb\_\<date\>-\<time\>.csv

Log line format:

logtime | timestamp with time zone |

loguser | text |

logdatabase | text |

logpid | text |

logthread | text |

loghost | text |

logport | text |

logsessiontime | timestamp with time zone |

logtransaction | integer |

logsession | text |

logcmdcount | text |

logsegment | text |

logslice | text |

logdistxact | text |

loglocalxact | text |

logsubxact | text |

logseverity | text |

logstate | text |

logmessage | text |

logdetail | text |

loghint | text |

logquery | text |

logquerypos | integer |

logcontext | text |

logdebug | text |

logcursorpos | integer |

logfunction | text |

logfile | text |

logline | integer |

logstack | text |

Exercise: Look at the log file and do different things in the database (create table, run queries, etc.)

# 22. AO/AOCO Tables

- Heap Tables

The default table type in CBDB is 'heap'. In heap tables rows are stored in pages and a data file can have many pages. Heap tables support all SQL operations - SELECT, INSERT, UPDATE, DELETE, TRUNCATE.

To support this functionality rows in CBDB have row header. Heap tables do not support compression.

```
gpadmin=# create table test_heap (c1 text);
NOTICE:  Table doesn't have 'DISTRIBUTED BY' clause -- Using column named 'c1' as the Cloudberry Database data distribution key for this table.
HINT:  The 'DISTRIBUTED BY' clause determines the distribution of data. Make sure column(s) chosen are the optimal data distribution key to minimize skew.
CREATE TABLE
gpadmin=# \d+ test_heap
                                       Table "public.test_heap"
 Column | Type | Collation | Nullable | Default | Storage  | Compression | Stats target | Description
--------+------+-----------+----------+---------+----------+-------------+--------------+-------------
 c1     | text |           |          |         | extended |             |              |
Distributed by: (c1)
Access method: heap
```

- AO tables do not have row header and support compression. This makes them appropriate choice for huge fact tables.

```
gpadmin=# create table test_ao (c1 text) with (appendoptimized=true, compresstype=zstd, compresslevel=9);
NOTICE:  Table doesn't have 'DISTRIBUTED BY' clause -- Using column named 'c1' as the Cloudberry Database data distribution key for this table.
HINT:  The 'DISTRIBUTED BY' clause determines the distribution of data. Make sure column(s) chosen are the optimal data distribution key to minimize skew.
CREATE TABLE
gpadmin=# \d+ test_ao
                                        Table "public.test_ao"
 Column | Type | Collation | Nullable | Default | Storage  | Compression | Stats target | Description
--------+------+-----------+----------+---------+----------+-------------+--------------+-------------
 c1     | text |           |          |         | extended |             |              |
Compression Type: zstd
Compression Level: 9
Block Size: 32768
Checksum: t
Distributed by: (c1)
Access method: ao_row
Options: compresstype=zstd, compresslevel=9
```

- AO CO (Column Oriented) tables

Row oriented storage is not optimal when executing queries on single columns (avg, sum, etc.).

Column oriented tables store data by column, so querying one column does not depend on the number and size of other columns.

AOCO tables also support compression, which is even better than AO because of the homogenity of the data in single file (single column all data of same type)

```
gpadmin=# create table test_aoco (c1 text) with (appendoptimized=true, orientation=column, compresstype=zstd, compresslevel=9);
NOTICE:  Table doesn't have 'DISTRIBUTED BY' clause -- Using column named 'c1' as the Cloudberry Database data distribution key for this table.
HINT:  The 'DISTRIBUTED BY' clause determines the distribution of data. Make sure column(s) chosen are the optimal data distribution key to minimize skew.
CREATE TABLE
gpadmin=# \d+ test_aoco
                                                                 Table "public.test_aoco"
 Column | Type | Collation | Nullable | Default | Storage  | Compression | Stats target | Compression Type | Compression Level | Block Size | Description
--------+------+-----------+----------+---------+----------+-------------+--------------+------------------+-------------------+------------+-------------
 c1     | text |           |          |         | extended |             |              | zstd             | 9                 | 32768      |
Checksum: t
Distributed by: (c1)
Access method: ao_column
Options: compresstype=zstd, compresslevel=9
```

Exercise: Create heap table, AO table, AOCO table. Use the \d+ psql command to see the result.

# 23. External tables

CBDB supports external tables. These are tables that have the table structure in the database, but point to data outside of the database:

- data can be in file on the local filesystem

- data can be in file on a remote host (gpfdist server used)

- data can be in HDFS (gphdfs type)

- data can be generated on the fly via command

External tables are useful when importing data into CBDB (insert into table select \* from ext\_table) because the data ingestion happens in parallel from segments as opposed to serial ingestion from Coordinator.

Exercise: Create external tables of different kinds and work with them to get comfortable.

# 24. CBDB Versioning and Upgrades

CBDB Versioning: A.B.C.DE

- A - major release version number (changed rarely for big functionality/feature changes)

- B - major release version number (feature/functionality changes)

- C - minor release version number (minor changes)

Major software changes - A or B is changed (ex: 1.3.0 -\> 1.4.0)

Minor software changes - C is changed (ex. 1.3.0 -\> 1.3.1)

Major upgrades - install new software + hashcopy should be used to migrate the database. These upgrades take time (hours) as they contain catalog changes and/or data format changes.

Minor upgrades - install new software + stop database + start database with new software (GPHOME change)

Exercise:

- perform minor upgrade

- prepare and perform major upgrade

# 25. Workload management

Resource queues - CBDB has a concept of RQ. RQ is a set of sessions that have similar requirements and use common pool of resources. Every user can be assigned to a RQ.

Priority - each resource queue can be assigned a priority. Every session which is assigned to this RQ will have the specified priority. Priority can be assigned to a single session also with gp\_adjust\_priority() function.

Exercise: create user, create RQ, assign the user to the RQ, run query and observe the RQ state.