**GPDB Crash Course**

[0. Background - Database concepts:](#_m7j4d8j1mhe3)

[1. What is GPDB](#_oc6ibh8u8lma)

[2. Documentation](#_6i3dkqtdh5q4)

[3. Installing GPDB](#_cwum3qrnlhdp)

[4. Creating a cluster](#_jk1ne6o532a4)

[5. Cluster description](#_flzvjzjb9sm9)

[6. Management utilities](#_q79ghv348wah)

[7. Starting and stopping cluster](#_33nsed5h4gdd)

[8. Cluster state](#_2sh0leiruqt4)

[9. Adding mirrors](#_9pvb695obybl)

[10. FTS, segment failures and recovering mirrors](#_vagg1jllzap1)

[11. Standby master](#_m6f2ypn9cdd1)

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

[24. GPDB Versioning and Upgrades](#_u5271ivjchgy)

[25. Workload management](#_gkgh6qq0z0xl)

Immersion link ( highly recommended)

1. [Link for PDB immersion training](https://docs.google.com/a/pivotal.io/presentation/d/1-tcvzoGZHhYlCdueOqs4zX4wmCHWD8TpNI_ZzcbAQmA/edit#slide=id.p21)
2. [GPDB Performance and optimization whitepaper](https://docs.google.com/a/pivotal.io/document/d/1_e2APwwvrb_oSOTMY1gAkWBVDCmItHMqpPDkr651q7E/edit)
3. [Boot camp links](https://drive.google.com/a/pivotal.io/folderview?id=0B_rb6msCq2WfRERScDNhMS1Wb3M&usp=sharing)
4. [GPDB Best practice](https://drive.google.com/a/pivotal.io/file/d/0B7hTrbm0lHftQU5JemNxVWR6R00/view)

# **0. Background - Database concepts** :

Before starting this crash course, spend some time go get familiar with how (single instance) databases work. If you already have some knowledge and experience with Oracle, MySQL or especially Postgres - this is great.

Databases (relational databases) are pieces of software that are used to store and manage/process data. Usually these databases are built with the client/server concept - the database is implemented as a server and multiple clients can connect and read or update the data.

The clients usually use SQL language to access the data (or some dialect of the SQL language specification). The clients can be different implementations - proprietary client libraries or ODBC/JDBC compliant.

Database data is usually stored in objects called tables. Tables have predefined structure (columns) and have zero or multiple rows.

Tables can be grouped in logical entities called 'schemas' (or namespaces).

Tables/schemas are located in a 'database' entity. Some database software supports multiple databases per instance (MySQL, Postgres), others support one database per instance (Oracle).

Along with tables there are supporting objects such as indexes, sequences, views, etc.

The database system needs to maintain some metadata - called the database catalog. The database catalog contains information about the data objects and supporting objects as well as anything else that needs to be stored on system level (user authentication, etc.).

SQL (Structured Query Language) is a descriptive language, not imperative language. Therefore it describes what the user needs, not how to get it. When the user describes what he needs,

the database need to decide how to get it. This process is called query optimization. The end result from this process is a query plan, which is a step by step instruction how to get

the result.

# 1. What is GPDB

Greenplum Database is Massively Parallel Database. This means that unlike usual database systems, which have one instance to manage the data and connections, Greenplum can have many instances.

One of the instances is called the 'master instance' it handles user connections and query parsing/planning. The rest of the segments are 'worker segments' or segments. They store the data and execute the query plan.

Greenplum originally started from Postgres (around 8.1/8.2) and therefore is very similar in some aspects. It is also very different in other aspects. The SQL language dialect and client

connectivity is almost the same, while the query processing and some of the data storage is completely different. There are also many new additions that are missing in Postgres.

One important thing to remember is that data in GPDB is stored in the segment instances and segment instances do not share their data. Master does not store any user data.

# 2. Documentation

Here is a link to the documentation \<http://docs.gopivotal.com/gpdb/index.html\>. Now is the time to do a quick read of the documentation. No need to worry if you don't understand everything.

Greenplum Database Installation Guide - A10 pdf

Greenplum Database System Administrator Guide - A11 pdf

Greenplum Database Database Administrator Guide - A07 pdf

Greenplum Database Reference Guide - A11 pdf

Greenplum Database Utility Guide - A11 pdf

Exercise: Download GPDB guides and review them quickly to find out what does each guide contain. Read the beginning of the Installation Guide to understand the concepts in GPDB cluster.

# 3. Installing GPDB

- Read up the GPDB Installation Guide. The guide has some conceptual information about GPDB and the steps to install the software.

Exercise: Install the GPDB software:

- Check the system requirements

- Set the OS parameters

- Exchange keys

- Run the installer on the master host

- Install on all hosts

- Validate system

# 4. Creating a cluster

Read the rest of the GPDB Installation Guide.

Exercise: Create GPDB cluster

- Initialization Host file

- Cluster configuration file

- gpinitsystem

- Explore environment variables:

- MASTER\_DATA\_DIRECTORY

- GPHOME

# 5. Cluster description

Cluster has one master host and many segment hosts. These are usually named "mdw" and "sdwXX" respectively. Therefore if somebody is referring to "mdw" he is referring to the "master host".

Similarly when somebody is referring to "sdw10" he is referring to the 10th segment host. Master host usually contains only one instance - the master instance. The segment hosts can contain

many worker instances.

Every instance has its own set of processes, own data directory and own listening port. For example usually the listening port of the master instance (where all clients will connect) is 5432.

Every segment instance has its own listening port (the base port is specified in the cluster configuration file).

Instances can have 2 roles - primary and mirror. Primary instances serve database queries. Mirror instances simply track and record data changes in primary instances, but do not serve

database queries. If the primary instance goes down for some reason, then the corresponding mirror instance transitions to primary role and starts serving queries (the original primary instance, currently down, is marked as mirror). We will talk later how to recover failed instances.

The cluster information is stored in the "gp\_segment\_configuration" table. It looks like this (use the "psql" command to connect to the database in order to execute queries):

<blockquote>
<pre><code>
test=# select * from gp_segment_configuration ;

dbid | content | role | preferred_role | mode | status | port | hostname | address | replication_port | san_mounts

------+---------+------+----------------+------+--------+-------+----------+---------+------------------+------------

1 | -1 | p | p | s | u | 54321 | mdw | mdw | |

2 | 1 | p | p | s | u | 50001 | mdw | mdw | |

3 | 0 | p | p | s | u | 50000 | mdw | mdw | |

(3 rows)
</pre></code>
</blockquote>

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

- replication\_port - related to replication (mirroring) functionality

- san\_mounts - related to different configuration of the system where SAN is used

Exercise: Connect to the GPDB cluster that you created and take a look at the "gp\_segment\_configuration" table. Try to make sense of the rows and columns and connect it to the cluster configuration

file that you used to run gpinitsystem.

# 6. Management utilities

- gpstop - stops database cluster

- gpstart - starts database cluster

- psql - command line client

- gpconfig - show/change configuration parameters

- gpdeletesystem - deletes a cluster

- pg\_dump, gp\_dumpall, gp\_restore, gpcrondump, gpdbrestore - backup and restore utilities

- gpinitstanby, gpactivatestandby - standby master instance management

- gprecoverseg - segment recovery

- gp\_log\_collector - segment log collection

- gpmigrator, gpmigrator\_mirror - major upgrades

- gpfdist, gpload - external tables

- gpssh, gpscp, gpssh-exkeys - cluster navigation

- Logging - all utilities write log files under ~/gpAdminLogs/ - one file per day

Exercise: Read the help for these tools (\<tool\> --help)

# 7. Starting and stopping cluster

- gpstart

<blockquote>
<pre><code>

gpadmin:Fullrack@mdw $ gpstart

20140502:13:53:33:023128 gpstart:mdw:gpadmin-[INFO]:-Starting gpstart with args:

20140502:13:53:33:023128 gpstart:mdw:gpadmin-[INFO]:-Gathering information and validating the environment...

20140502:13:53:33:023128 gpstart:mdw:gpadmin-[INFO]:-Greenplum Binary Version: 'postgres (Greenplum Database) 4.2.6.1 build 1'

20140502:13:53:33:023128 gpstart:mdw:gpadmin-[INFO]:-Greenplum Catalog Version: '201109210'

20140502:13:53:33:023128 gpstart:mdw:gpadmin-[INFO]:-Starting Master instance in admin mode

20140502:13:53:34:023128 gpstart:mdw:gpadmin-[INFO]:-Obtaining Greenplum Master catalog information

20140502:13:53:34:023128 gpstart:mdw:gpadmin-[INFO]:-Obtaining Segment details from master...

20140502:13:53:34:023128 gpstart:mdw:gpadmin-[INFO]:-Setting new master era

20140502:13:53:34:023128 gpstart:mdw:gpadmin-[INFO]:-Master Started...

20140502:13:53:34:023128 gpstart:mdw:gpadmin-[INFO]:-Shutting down master

20140502:13:53:35:023128 gpstart:mdw:gpadmin-[INFO]:---------------------------

20140502:13:53:35:023128 gpstart:mdw:gpadmin-[INFO]:-Master instance parameters

20140502:13:53:35:023128 gpstart:mdw:gpadmin-[INFO]:---------------------------

20140502:13:53:35:023128 gpstart:mdw:gpadmin-[INFO]:-Database = template1

20140502:13:53:35:023128 gpstart:mdw:gpadmin-[INFO]:-Master Port = 54321

20140502:13:53:35:023128 gpstart:mdw:gpadmin-[INFO]:-Master directory = /data/lubo/42/gpseg-1

20140502:13:53:35:023128 gpstart:mdw:gpadmin-[INFO]:-Timeout = 600 seconds

20140502:13:53:35:023128 gpstart:mdw:gpadmin-[INFO]:-Master standby = Off

20140502:13:53:35:023128 gpstart:mdw:gpadmin-[INFO]:---------------------------------------

20140502:13:53:35:023128 gpstart:mdw:gpadmin-[INFO]:-Segment instances that will be started

20140502:13:53:35:023128 gpstart:mdw:gpadmin-[INFO]:---------------------------------------

20140502:13:53:35:023128 gpstart:mdw:gpadmin-[INFO]:- Host Datadir Port

20140502:13:53:35:023128 gpstart:mdw:gpadmin-[INFO]:- mdw /data/lubo/42/gpseg0 50000

20140502:13:53:35:023128 gpstart:mdw:gpadmin-[INFO]:- mdw /data/lubo/42/gpseg1 50001

Continue with Greenplum instance startup Yy|Nn (default=N):

\> y

20140502:13:53:37:023128 gpstart:mdw:gpadmin-[INFO]:-No standby master configured. skipping...

20140502:13:53:37:023128 gpstart:mdw:gpadmin-[INFO]:-Commencing parallel segment instance startup, please wait...

..

20140502:13:53:39:023128 gpstart:mdw:gpadmin-[INFO]:-Process results...

20140502:13:53:39:023128 gpstart:mdw:gpadmin-[INFO]:-----------------------------------------------------

20140502:13:53:39:023128 gpstart:mdw:gpadmin-[INFO]:- Successful segment starts = 2

20140502:13:53:39:023128 gpstart:mdw:gpadmin-[INFO]:- Failed segment starts = 0

20140502:13:53:39:023128 gpstart:mdw:gpadmin-[INFO]:- Skipped segment starts (segments are marked down in configuration) = 0

20140502:13:53:39:023128 gpstart:mdw:gpadmin-[INFO]:-----------------------------------------------------

20140502:13:53:39:023128 gpstart:mdw:gpadmin-[INFO]:-

20140502:13:53:39:023128 gpstart:mdw:gpadmin-[INFO]:-Successfully started 2 of 2 segment instances

20140502:13:53:39:023128 gpstart:mdw:gpadmin-[INFO]:-----------------------------------------------------

20140502:13:53:39:023128 gpstart:mdw:gpadmin-[INFO]:-Starting Master instance mdw directory /data/lubo/42/gpseg-1

20140502:13:53:40:023128 gpstart:mdw:gpadmin-[INFO]:-Command pg\_ctl reports Master mdw instance active

20140502:13:53:40:023128 gpstart:mdw:gpadmin-[INFO]:-Database successfully started

20140502:13:53:40:023128 gpstart:mdw:gpadmin-[INFO]:-Initializing DCA settings

20140502:13:53:40:023128 gpstart:mdw:gpadmin-[INFO]:-DCA settings initialized

gpadmin:Fullrack@mdw $

- gpstop

gpadmin:Fullrack@mdw $ gpstop

20140502:13:53:15:020232 gpstop:mdw:gpadmin-[INFO]:-Starting gpstop with args:

20140502:13:53:15:020232 gpstop:mdw:gpadmin-[INFO]:-Gathering information and validating the environment...

20140502:13:53:15:020232 gpstop:mdw:gpadmin-[INFO]:-Obtaining Greenplum Master catalog information

20140502:13:53:15:020232 gpstop:mdw:gpadmin-[INFO]:-Obtaining Segment details from master...

20140502:13:53:15:020232 gpstop:mdw:gpadmin-[INFO]:-Greenplum Version: 'postgres (Greenplum Database) 4.2.6.1 build 1'

20140502:13:53:15:020232 gpstop:mdw:gpadmin-[INFO]:---------------------------------------------

20140502:13:53:15:020232 gpstop:mdw:gpadmin-[INFO]:-Master instance parameters

20140502:13:53:15:020232 gpstop:mdw:gpadmin-[INFO]:---------------------------------------------

20140502:13:53:15:020232 gpstop:mdw:gpadmin-[INFO]:- Master Greenplum instance process active PID = 15376

20140502:13:53:15:020232 gpstop:mdw:gpadmin-[INFO]:- Database = template1

20140502:13:53:15:020232 gpstop:mdw:gpadmin-[INFO]:- Master port = 54321

20140502:13:53:15:020232 gpstop:mdw:gpadmin-[INFO]:- Master directory = /data/lubo/42/gpseg-1

20140502:13:53:15:020232 gpstop:mdw:gpadmin-[INFO]:- Shutdown mode = smart

20140502:13:53:15:020232 gpstop:mdw:gpadmin-[INFO]:- Timeout = 600

20140502:13:53:15:020232 gpstop:mdw:gpadmin-[INFO]:- Shutdown Master standby host = Off

20140502:13:53:15:020232 gpstop:mdw:gpadmin-[INFO]:---------------------------------------------

20140502:13:53:15:020232 gpstop:mdw:gpadmin-[INFO]:-Segment instances that will be shutdown:

20140502:13:53:15:020232 gpstop:mdw:gpadmin-[INFO]:---------------------------------------------

20140502:13:53:15:020232 gpstop:mdw:gpadmin-[INFO]:- Host Datadir Port Status

20140502:13:53:15:020232 gpstop:mdw:gpadmin-[INFO]:- mdw /data/lubo/42/gpseg0 50000 u

20140502:13:53:15:020232 gpstop:mdw:gpadmin-[INFO]:- mdw /data/lubo/42/gpseg1 50001 u

Continue with Greenplum instance shutdown Yy|Nn (default=N):

\> y

20140502:13:53:16:020232 gpstop:mdw:gpadmin-[INFO]:-There are 0 connections to the database

20140502:13:53:16:020232 gpstop:mdw:gpadmin-[INFO]:-Commencing Master instance shutdown with mode='smart'

20140502:13:53:16:020232 gpstop:mdw:gpadmin-[INFO]:-Master host=mdw

20140502:13:53:16:020232 gpstop:mdw:gpadmin-[INFO]:-Commencing Master instance shutdown with mode=smart

20140502:13:53:16:020232 gpstop:mdw:gpadmin-[INFO]:-Master segment instance directory=/data/lubo/42/gpseg-1

20140502:13:53:17:020232 gpstop:mdw:gpadmin-[INFO]:-No standby master host configured

20140502:13:53:17:020232 gpstop:mdw:gpadmin-[INFO]:-Commencing parallel segment instance shutdown, please wait...

...

20140502:13:53:20:020232 gpstop:mdw:gpadmin-[INFO]:-----------------------------------------------------

20140502:13:53:20:020232 gpstop:mdw:gpadmin-[INFO]:- Segments stopped successfully = 2

20140502:13:53:20:020232 gpstop:mdw:gpadmin-[INFO]:- Segments with errors during stop = 0

20140502:13:53:20:020232 gpstop:mdw:gpadmin-[INFO]:-----------------------------------------------------

20140502:13:53:20:020232 gpstop:mdw:gpadmin-[INFO]:-Successfully shutdown 2 of 2 segment instances

20140502:13:53:20:020232 gpstop:mdw:gpadmin-[INFO]:-Database successfully shutdown with no errors reported

20140502:13:53:20:020232 gpstop:mdw:gpadmin-[INFO]:-Unregistering with DCA

20140502:13:53:20:020232 gpstop:mdw:gpadmin-[INFO]:-Unregistered with DCA
</pre></code>
</blockquote>

Exercise: Read the log entries for gpstop and gpstart and try to understand what they mean. Read and exercise the different options for gpstart/gpstop.

# 8. Cluster state

- gpstate

gpstate is the utility that can give you information about the state of the cluster. It has different arguments to show different aspects of the state.

<pre><code>
<blockquote>

gpadmin:Fullrack@mdw $ gpstate

20140502:13:54:06:028345 gpstate:mdw:gpadmin-[INFO]:-Starting gpstate with args:

20140502:13:54:06:028345 gpstate:mdw:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 4.2.6.1 build 1'

20140502:13:54:06:028345 gpstate:mdw:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 8.2.15 (Greenplum Database 4.2.6.1 build 1) on x86\_64-unknown-linux-gnu, compiled by GCC gcc (GCC) 4.4.2 compiled on Jul 16 2013 22:20:28'

20140502:13:54:06:028345 gpstate:mdw:gpadmin-[INFO]:-Obtaining Segment details from master...

20140502:13:54:06:028345 gpstate:mdw:gpadmin-[INFO]:-Gathering data from segments...

.........................................................................................

20140502:13:55:35:028345 gpstate:mdw:gpadmin-[INFO]:-Greenplum instance status summary

20140502:13:55:35:028345 gpstate:mdw:gpadmin-[INFO]:-----------------------------------------------------

20140502:13:55:35:028345 gpstate:mdw:gpadmin-[INFO]:- Master instance = Active

20140502:13:55:35:028345 gpstate:mdw:gpadmin-[INFO]:- Master standby = No master standby configured

20140502:13:55:35:028345 gpstate:mdw:gpadmin-[INFO]:- Total segment instance count from metadata = 2

20140502:13:55:35:028345 gpstate:mdw:gpadmin-[INFO]:-----------------------------------------------------

20140502:13:55:35:028345 gpstate:mdw:gpadmin-[INFO]:- Primary Segment Status

20140502:13:55:35:028345 gpstate:mdw:gpadmin-[INFO]:-----------------------------------------------------

20140502:13:55:35:028345 gpstate:mdw:gpadmin-[INFO]:- Total primary segments = 2

20140502:13:55:35:028345 gpstate:mdw:gpadmin-[INFO]:- Total primary segment valid (at master) = 2

20140502:13:55:35:028345 gpstate:mdw:gpadmin-[INFO]:- Total primary segment failures (at master) = 0

20140502:13:55:35:028345 gpstate:mdw:gpadmin-[INFO]:- Total number of postmaster.pid files missing = 0

20140502:13:55:35:028345 gpstate:mdw:gpadmin-[INFO]:- Total number of postmaster.pid files found = 2

20140502:13:55:35:028345 gpstate:mdw:gpadmin-[INFO]:- Total number of postmaster.pid PIDs missing = 0

20140502:13:55:35:028345 gpstate:mdw:gpadmin-[INFO]:- Total number of postmaster.pid PIDs found = 2

20140502:13:55:35:028345 gpstate:mdw:gpadmin-[INFO]:- Total number of /tmp lock files missing = 0

20140502:13:55:35:028345 gpstate:mdw:gpadmin-[INFO]:- Total number of /tmp lock files found = 2

20140502:13:55:35:028345 gpstate:mdw:gpadmin-[INFO]:- Total number postmaster processes missing = 0

20140502:13:55:35:028345 gpstate:mdw:gpadmin-[INFO]:- Total number postmaster processes found = 2

20140502:13:55:35:028345 gpstate:mdw:gpadmin-[INFO]:-----------------------------------------------------

20140502:13:55:35:028345 gpstate:mdw:gpadmin-[INFO]:- Mirror Segment Status

20140502:13:55:35:028345 gpstate:mdw:gpadmin-[INFO]:-----------------------------------------------------

20140502:13:55:35:028345 gpstate:mdw:gpadmin-[INFO]:- Mirrors not configured on this array

20140502:13:55:35:028345 gpstate:mdw:gpadmin-[INFO]:-----------------------------------------------------
</pre></code>
</blockquote>
- gp\_segment\_configuration

gp\_segment\_configuration expresses the 'master instance' knowledge about the state of the cluster.

Exercise: Look at the cluster state and try to connect the information from gpstate and gp\_segment\_configuration.

# 9. Adding mirrors

How GPDB mirroring works

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

- GPDB has a Fault Tolerant Service that monitors the cluster and makes sure that work continues with working segments. When segment does down, it performs transitions to always have available

primary instance for every content. If both instances for one content go down (primary does down, mirror goes down) - this is known as "double fault" and database is non-operable.

- FTS service runs on master in the "ftsprober" process. At certain intervals the prober will scan segments and if there is difference with the last known configuration, it will perform transitions

accordingly.

Information about the transition event is recorded in the master log file and in "gp\_configuration\_history" and the instance status is updated in "gp\_segment\_configuration"

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

# 11. Standby master

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

# 12. Expansion

If the cluster needs to be expanded, the "gpexpand" tool can be used.

The cluster can be expanded both with new hosts and more segments per host.

gpexpand utility workflow

- phasee I: Interview (gpexpand)

Run "gpexpand" without parameters. It will go through interview and will ask you questions about your intentions. Once all questions have been answered it will create a "configuration file" and

exit. The configuraiton file contains information about the new segments that are about to be created. At this point you should review the configuration file to make sure that the actions are what

you want intent to do.

- phase II: Expand cluster (gpexpand -i \<config\_file\>)

During this phase the utility will create the new instances. The new instances will become part of the cluster and will be recorded in "gp\_segment\_configuration". From this point on the cluster

has grown with the new instances, but the new instances still do not contain user data. gpexpand will also create the "gpexpand" schema in the requested directory, which contains a list of tables

to be redistributed in the next step.

- phase III: Redsitribute data (gpexpand)

At this phase the user data, stored until now only on original instances, is redistributed across the new larger cluster. Expansion can be done in many runs with setting timeout for the

current run (see the -d parameter). Once the redistribution is finished (all the tables are redistributed across all instances), gpexpand will exit.

- phase IV: Clean up

At this point cluster is expanded and data is redistributed. Everything is done. The "gpexpand" schema though is still there for you to review if necessary. This schema does not harm anything.

The only side effect is that if you need to start another expansion, "gpexpand" will ask you to remove it with "gpexpand -c" before it can continue.

Exercise: Run gpexpand and add segments to the existing servers. Run gpexpand to add segments on new servers to the cluster.

Observe gp\_segment\_configuration and connect the changes to the actions.

# 15. Performance check

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

# 16. Backup and Restore

- pg\_dump - connects to master and does the requested backup (see parameters)

- gp\_dump, gp\_restore - parallel backup into segment data directories, parallel restore

- gpcrondump, gpdbrestore - enhanced parallel backup into segment data directories, parallel restore

Exercise:

- Use pg\_dump to backup a single table. Use pg\_dump to backup DDL for a single table and the entire database.

- Use gp\_dump to backup your database. Analyze gp\_dump output and find the backup log files on master and on segments.

- Use gpcrondump to backup your database. Drop the database and restore it from backup.

# 17. User data and table distribution

- master does not have user data

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

# 18. Database catalog

- located on master and segments

- pg\_catalog schema

- tables, views, indexes

- object description - pg\_class, pg\_attribute, pg\_type, etc...

- functions - pg\_class

- segment data (master only tables) - gp\_segment\_configuration, gp\_configuration\_history

- distribution data - gp\_distribution\_policy

- gpcheckcat

Exercise: Run gpcheckcat on your cluster and attempt to make sense of the results.

# 19. Data directories

Contents of a data directory:

<pre><code>
<blockquote>

drwx------ 2 gpadmin root 16384 May 2 13:53 pg\_log -\> Database log files

drwx------ 6 gpadmin root 71 Apr 26 17:40 base -\> Database data storage

drwx------ 2 gpadmin root 4096 May 2 13:53 global -\> Global tables and control file

drwx------ 3 gpadmin gpadmin 105 Apr 26 19:32 pg\_xlog -\> Transaction logs

drwx------ 2 gpadmin gpadmin 10 Apr 26 19:26 pg\_distributedxidmap

drwx------ 2 gpadmin gpadmin 25 Jan 28 15:12 pg\_clog

drwx------ 2 gpadmin gpadmin 25 Jan 28 15:12 pg\_distributedlog

drwx------ 2 gpadmin gpadmin 25 Jan 28 15:12 pg\_subtrans

drwx------ 2 gpadmin root 10 Jan 28 15:12 pg\_changetracking

drwx------ 2 gpadmin root 10 Jan 28 15:12 pg\_tblspc

drwx------ 2 gpadmin root 10 Jan 28 15:12 pg\_twophase

drwx------ 2 gpadmin root 10 May 2 13:53 pg\_utilitymodedtmredo

drwx------ 2 gpadmin root 32 May 2 13:53 pg\_stat\_tmp

drwx------ 4 gpadmin gpadmin 46 Jan 28 15:12 pg\_multixact

drwxr-xr-x 5 gpadmin root 55 Jan 28 15:12 gpperfmon

-r-------- 1 gpadmin gpadmin 109 Jan 28 15:12 gp\_dbid

-rw------- 1 gpadmin gpadmin 19275 Apr 26 19:08 postgresql.conf -\> Database configuration file

-rw------- 1 gpadmin gpadmin 42 Jan 28 15:12 gp\_transaction\_files\_filespace.old

-rw------- 1 gpadmin root 1650 Jan 28 15:12 pg\_ident.conf

-rw------- 1 gpadmin root 4 Jan 28 15:12 PG\_VERSION

-rw-r--r-- 1 gpadmin root 4372 Mar 25 13:32 pg\_hba.conf -\> Host based authentication file


</pre></code>
</blockquote>

Exercise: Explore the data directory and subdirectories. Take a look at the configuration files.

# 20. Instance processes

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

<pre><code>
<blockquote>

gpadmin 30143 2.1 0.3 312848 165348 ? Ss 14:47 0:00 /usr/local/greenplum-db-4.2.6.1/bin/postgres -D /data/lubo/42/gpseg-1 -p 54321 -b 1 -z 2 --silent-mode=true -i -M master -C -1 -x 0 -E

gpadmin:Fullrack@mdw $ ps aux | grep 54321

gpadmin 30143 1.3 0.3 312848 165348 ? Ss 14:47 0:00 /usr/local/greenplum-db-4.2.6.1/bin/postgres -D /data/lubo/42/gpseg-1 -p 54321 -b 1 -z 2 --silent-mode=true -i -M master -C -1 -x 0 -E

gpadmin 30166 0.0 0.0 129352 3604 ? Ss 14:47 0:00 postgres: port 54321, master logger process

gpadmin 30254 0.0 0.0 131440 1884 ? Ss 14:47 0:00 postgres: port 54321, stats collector process

gpadmin 30255 0.0 0.0 312848 1780 ? Ss 14:47 0:00 postgres: port 54321, writer process

gpadmin 30260 0.0 0.0 312848 1484 ? S 14:47 0:00 postgres: port 54321, sweeper process

gpadmin 30256 0.0 0.0 312848 1684 ? Ss 14:47 0:00 postgres: port 54321, checkpoint process

gpadmin 30258 0.0 0.0 312848 1540 ? S 14:47 0:00 postgres: port 54321, WAL Send Server process

gpadmin 30257 0.0 0.0 313688 3080 ? S 14:47 0:00 postgres: port 54321, seqserver process

gpadmin 30259 0.0 0.0 317956 4796 ? S 14:47 0:00 postgres: port 54321, ftsprobe process

gpadmin 27366 0.1 0.0 316640 14276 ? Ssl 15:12 0:07 postgres: port 54321, gpadmin test [local] con9 [local] cmd28 idle

- primary

(mirrorless)

gpadmin 29879 0.4 0.3 343600 185336 ? Ss 14:47 0:00 /usr/local/greenplum-db-4.2.6.1/bin/postgres -D /data/lubo/42/gpseg0 -p 50000 -b 3 -z 2 --silent-mode=true -i -M mirrorless -C 0

gpadmin 29920 0.0 0.0 129352 3292 ? Ss 14:47 0:00 postgres: port 50000, logger process

gpadmin 30008 0.0 0.0 131440 1880 ? Ss 14:47 0:00 postgres: port 50000, stats collector process

gpadmin 30009 0.0 0.0 343600 1868 ? Ss 14:47 0:00 postgres: port 50000, writer process

gpadmin 30011 0.0 0.0 343600 1676 ? Ss 14:47 0:00 postgres: port 50000, checkpoint process

gpadmin 30012 0.0 0.0 343772 1532 ? S 14:47 0:00 postgres: port 50000, sweeper process

(with mirroring)

gpadmin 15726 0.0 0.4 425536 226504 ? Ss May01 0:01 /usr/local/GP-4.3.0.0/bin/postgres -D /data1/db\_kroberts/primary/gpseg0 -p 37000 -b 2 -z 4 --silent-mode=true -i -M quiescent -C 0

gpadmin 15777 0.0 0.0 160760 4856 ? Ss May01 0:00 postgres: port 37000, logger process

gpadmin 17447 0.0 0.0 162848 3452 ? Ss May01 0:00 postgres: port 37000, stats collector process

gpadmin 17448 0.0 0.0 425692 15512 ? Ss May01 0:00 postgres: port 37000, writer process

gpadmin 17449 0.0 0.0 425668 4912 ? Ss May01 0:00 postgres: port 37000, checkpoint process

gpadmin 17450 0.0 0.0 425676 3088 ? S May01 0:00 postgres: port 37000, sweeper process

gpadmin 17420 0.0 0.0 423444 14212 ? S May01 0:00 postgres: port 37000, primary process

gpadmin 17422 0.0 0.0 425536 5472 ? S May01 0:00 postgres: port 37000, primary receiver ack process

gpadmin 17424 0.0 0.0 425876 13648 ? S May01 0:01 postgres: port 37000, primary sender process

gpadmin 17426 0.0 0.0 423444 4276 ? S May01 0:00 postgres: port 37000, primary consumer ack process

gpadmin 17428 0.0 0.0 424608 15660 ? S May01 0:00 postgres: port 37000, primary recovery process

gpadmin 17429 0.0 0.0 424536 7036 ? S May01 0:00 postgres: port 37000, primary verification process

- mirror

gpadmin 15727 0.0 0.4 423508 226120 ? Ss May01 0:00 /usr/local/GP-4.3.0.0/bin/postgres -D /data1/db\_kroberts/mirror/gpseg1 -p 47000 -b 5 -z 4 --silent-mode=true -i -M quiescent -C 1

gpadmin 15776 0.0 0.0 160680 4844 ? Ss May01 0:00 postgres: port 47000, logger process

gpadmin 17421 0.0 0.0 423460 14220 ? S May01 0:00 postgres: port 47000, mirror process

gpadmin 17423 0.0 0.0 425552 13148 ? S May01 0:00 postgres: port 47000, mirror receiver process

gpadmin 17425 0.0 0.0 423556 7440 ? S May01 0:00 postgres: port 47000, mirror consumer process

gpadmin 17427 0.0 0.0 423652 6900 ? S May01 0:00 postgres: port 47000, mirror consumer writer process

gpadmin 17430 0.0 0.0 423460 6036 ? S May01 0:00 postgres: port 47000, mirror consumer append only process

gpadmin 17431 0.0 0.0 425552 6124 ? S May01 0:00 postgres: port 47000, mirror sender ack process

gpadmin 17432 0.0 0.0 423460 6056 ? S May01 0:00 postgres: port 47000, mirror verification process

</pre></code>
</blockquote>

Exercise: Try to identify the processes for the instances in your cluster.

# 21. Database log files

Each instance has its own log files, which are located under \<data\_directory\>/pg\_log directory.

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

The default table type in GPDB is 'heap'. In heap tables rows are stored in pages and a data file can have many pages. Heap tables support all SQL operations - SELECT, INSERT, UPDATE, DELETE, TRUNCATE.

To support this functionality rows in GPDB have row header. Heap tables do not support compression.

- AO tables do not have row header and support compression. This makes them appropriate choice for huge fact tables.

- AO CO (Column Oriented) tables

Row oriented storage is not optimal when executing queries on single columns (avg, sum, etc.).

Column oriented tables store data by column, so querying one column does not depend on the number and size of other columns.

AOCO tables also support compression, which is even better than AO because of the homogenity of the data in single file (single column all data of same type)

Exercise: Create heap table, AO table, AOCO table. Use the \d+ psql command to see the result.

# 23. External tables

GPDB supports external tables. These are tables that have the table structure in the database, but point to data outside of the database:

- data can be in file on the local filesystem

- data can be in file on a remote host (gpfdist server used)

- data can be in HDFS (gphdfs type)

- data can be generated on the fly via command

External tables are useful when importing data into GPDB (insert into table select \* from ext\_table) because the data ingestion happens in parallel from segments as opposed to serial

ingestion from master.

Exercise: Create external tables of different kinds and work with them to get comfortable.

# 24. GPDB Versioning and Upgrades

GPDB Versioning: A.B.C.DE

- A - major release version number (changed rarely for big functionality/feature changes)

- B - major release version number (feature/functionality changes)

- C - minor release version number (minor changes)

- D - service pack set version number (GA set of fixes)

- E - patch/hotfix (escalations)

Major software changes - A or B is changed (ex: 4.1.0.0 -\> 4.2.3.4)

Minor software changes - C or D is changed (ex. 4.1.0.0 -\> 4.1.2.3)

Major upgrades - install new software + gpmigrator should be used to migrate the database. These upgrades take time (hours) as they contain catalog changes and/or data format changes.

Minor upgrades - install new software + stop database + start database with new software (GPHOME change)

Exercise:

- perform minor upgrade

- prepare and perform major upgrade

# 25. Workload management

Resource queues - GPDB has a concept of RQ. RQ is a set of sessions that have similar requirements and use common pool of resources. Every user can be assigned to a RQ.

Priority - each resource queue can be assigned a priority. Every session which is assigned to this RQ will have the specified priority. Priority can be assigned to a single session also with

gp\_adjust\_priority() function.

Exercise: create user, create RQ, assign the user to the RQ, run query and observe the RQ state.

[Old links for ref only - they don't work ( will be removed in future) :](https://docs.google.com/a/gopivotal.com/document/d/1E9CGrpZfWLaKGs0mhkxg4C6vbbVYuufVDR4zfSjoSKA/edit?usp=drive_web)

[https://docs.google.com/a/gopivotal.com/presentation/d/1LBCav1Xw7xmgDCWa1OcKfCf73XXVWcdOwUCCnDbsQXA/edit](https://docs.google.com/a/gopivotal.com/presentation/d/1LBCav1Xw7xmgDCWa1OcKfCf73XXVWcdOwUCCnDbsQXA/edit)

[https://docs.google.com/a/gopivotal.com/presentation/d/1kxiBGeRYa294vTcQLmvhAWROEn7UguTu2Y76gRpE3Lw/edit](https://docs.google.com/a/gopivotal.com/presentation/d/1kxiBGeRYa294vTcQLmvhAWROEn7UguTu2Y76gRpE3Lw/edit)

[https://docs.google.com/a/gopivotal.com/document/d/1E9CGrpZfWLaKGs0mhkxg4C6vbbVYuufVDR4zfSjoSKA/edit?usp=drive\_web](https://docs.google.com/a/gopivotal.com/document/d/1E9CGrpZfWLaKGs0mhkxg4C6vbbVYuufVDR4zfSjoSKA/edit?usp=drive_web)