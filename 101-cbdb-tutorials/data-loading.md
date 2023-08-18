
# Lesson 4: Data Loading

This tutorial briefly introduces 3 methods to load the example data `FAA` into Cloudberry Database tables you have created in the previous tutorial [Lesson 3: Create Tables](../101-cbdb-tutorials/create-tables.md). Before continuing, make sure you have completed the previous tutorial.

- Method 1: Use the `INSERT` statement. This is the easiest way to load data. You can execute `INSERT` directly in psql, run scripts that have `INSERT` statements, or run a client-side application with database connection. It is not recommended to use `INSERT` to load a large amount of data, because the efficiency is low.

- Method 2: Use the SQL statement `COPY` to load data into database. The `COPY` syntax allows you to define the format of the text file so that data can be parsed into rows and columns. This method is faster than the `INSERT` statement. But, like `INSERT` statement, `COPY` is not a parallel data loading process.

    The `COPY` statement requires that external files be accessible to the host where the master process is running. On a multi-node Cloudberry Database system, data files might reside on a file system that is not accessible from master node. In this case, you need to use the psql command `\copy meta-command` that streams data to Cloudberry master node over `psql` connection. Some example scripts in this tutorial use the `\copy meta-command`.

- Method 3: Use Cloudberry Database utilities to load external data into tables. When you are working with a large-scale data warehouse, you might often face the challenge of loading vast amounts of data in a short time. Cloudberry's utilities, `gpfdist` and `gpload`, are tailored for this purpose, enabling you to achieve rapid, parallel data transfers.

    During your data loading process, if any rows run into issues, they  will be noted. You can set an error threshold that fits your needs. If the number of problematic rows exceeds this limit, Cloudberry will stop the loading process.

    For optimal speed, combine the use of external tables with Cloudberry's parallel file server (`gpfdist`). This approach will help you maximize efficiency, making your data loading tasks smoother and more efficient.

    Figure 1. External Tables Using Cloudberry Parallel File Server (gpfdist) 

    <img src="https://raw.githubusercontent.com/greenplum-db/gpdb-sandbox-tutorials/gh-pages/images/ext_tables.jpg" width="500" alt="External Tables Using Cloudberry Parallel File Server">

    Another Cloudberry utility `gpload` is a batch job. When using this utility, you should specify a YAML-formatted control file, describe source data locations, format, transformations required, participating hosts, database destinations and other particulars in the file. `gpload` will parse the control file and use `gpfdsit` to execute the task. This allows you to describe a complex task and execute it in a controlled and repeatable way.

## Quick-start operations

In the following exercise, you will load sample data into the `tutorial` database using each of these above methods.

### Load data using `INSERT`

In [Lesson 3: Create Tables](../101-cbdb-tutorials/create-tables.md), you have created 6 tables in the `tutorial` database, one of which is `d_cancellation_codes` in the `faa` directory.

The `faa.d_cancellation_codes` table is a simple 2-column look-up table. You will load data into the using the `INSERT` statement.

<!-- You change to directory faa, containing FAA data and scripts, take a look at table faa.d_cancellation_codes, insert data into table.  -->

1. Log into Cloudberry Database in Docker as `gpadmin`, and change to the `faa` directory. This directory contains `faa` data and scripts.

    ```shell
    [gpadmin@mdw ~]$ cd /tmp/faa
    ```

2. Log into the `tutorial` database as `lily`.

    ```shell
    [gpadmin@mdw faa]$ psql -U lily -d tutorial
    ```

    ```shell
    Password for user lily:  # changeme

    psql (14.4, server 14.4)
    Type "help" for help.

    tutorial=>
    ```

3. Check the `faa.d_cancellation_codes` table.

    ```sql
    tutorial=> \d d_cancellation_codes
    ```

    Output:

    ```sql
              Table "faa.d_cancellation_codes"
       Column    | Type | Collation | Nullable | Default
    -------------+------+-----------+----------+---------
     cancel_code | text |           |          |
     cancel_desc | text |           |          |
    Distributed by: (cancel_code)
    ```

4. Insert data into the `faa.d_cancellation_codes` table.

    ```sql
    tutorial=> INSERT INTO faa.d_cancellation_codes
    tutorial-> VALUES ('A', 'Carrier'),
    tutorial-> ('B', 'Weather'),
    tutorial-> ('C', 'NAS'),
    tutorial-> ('D', 'Security'),
    tutorial-> ('', 'none');
    ```

    Output:

    ```sql
    INSERT 0 5
    tutorial=>
    ```

### Load data using `COPY`

The `COPY` statement moves data from the file system to database tables. Data for 5 of the `faa` tables is in the following CSV-formatted text files:

1. In a text editor, open and check the following `.csv` data files. 

    - `L_AIRLINE_ID.csv`
    - `L_AIRPORTS.csv`
    - `L_DISTANCE_GROUP_250.csv`
    - `L_ONTIME_DELAY_GROUPS.csv`
    - `L_WORLD_AREA_CODES.csv`

    Note that the first line of each file contains the column names, and that the last line of each file contains the characters `.`, which signals the end of the input data.

2. In a text editor, open and check the following SQL scripts:

    - `copy_into_airlines.sql`
    - `copy_into_airports.sql`
    - `copy_into_delay_groups.sql`
    - `copy_into_distance_groups.sql`
    - `copy_into_wac.sql`


3. Log into the `tutorial` database as `lily`.

    ```shell
    [gpadmin@mdw faa]$ psql -U lily -d tutorial
    ```

    ```shell
    Password for user lily:  # changeme

    psql (14.4, server 14.4)
    Type "help" for help.

    tutorial=>
    ```

4. Run the following psql `\i` commands to load data into the `faa` tables.

    ```sql
    tutorial=> \i copy_into_airlines.sql
    tutorial=> \i copy_into_airports.sql
    tutorial=> \i copy_into_delay_groups.sql
    tutorial=> \i copy_into_distance_groups.sql
    tutorial=> \i copy_into_wac.sql
    ```

    Output:

    ```sql
    COPY 1514
    COPY 1697
    COPY 15
    COPY 11
    COPY 342
    tutorial=>
    ```

### Load data using the `gpdist` utility

For the `faa` fact table, you will use an ETL (Extract, Transform, Load) process to load data from the source gzip files into a data table. For the best loading speed, use the `gpfdist` utility to distribute rows to segments. 

In production system, `gpfdist` runs on file servers that external data located in. However, for a single-node Cloudberry Database instance, there is only one logical host, so you run `gpfdist` on it as well. Starting `gpfdist` is similar as a file server, no data movement will occur until SQL query request has been kicked off.

> **Note:**
>
> This exercise loads data using `gpfdsit` to move data from external data files into Cloudberry Database. Moving data between the database and external tables also needs security request. Therefore, only superusers are permitted to use this feature and you will complete this exercise as `gpadmin` user.


Execute `gpfdist`. Use the `–d` switch to set the "home" directory used to search for files in the `faa` directory. Use `–p` to set the port and background the process. You might also check the process and log information.  

<blockquote>
<code>[gpadmin@mdw tmp]$ gpfdist -d /tmp/faa -p 8081 > /tmp/gpfdist.log 2>&1 &
[1] 6581
[gpadmin@mdw tmp]$
[gpadmin@mdw tmp]$ ps -ef  |grep gpfdist
gpadmin   6581  6552  0 16:02 pts/8    00:00:00 gpfdist -d /tmp/faa -p 8081
gpadmin   6585  6552  0 16:02 pts/8    00:00:00 grep --color=auto gpfdist
[gpadmin@mdw tmp]$
[gpadmin@mdw tmp]$ more /tmp/gpfdist.log
2023-07-25 16:02:41 6581 INFO Before opening listening sockets - following listening sockets are available:
2023-07-25 16:02:41 6581 INFO IPV6 socket: [::]:8081
2023-07-25 16:02:41 6581 INFO IPV4 socket: 0.0.0.0:8081
2023-07-25 16:02:41 6581 INFO Trying to open listening socket:
2023-07-25 16:02:41 6581 INFO IPV6 socket: [::]:8081
2023-07-25 16:02:41 6581 INFO Opening listening socket succeeded
2023-07-25 16:02:41 6581 INFO Trying to open listening socket:
2023-07-25 16:02:41 6581 INFO IPV4 socket: 0.0.0.0:8081
2023-07-25 16:02:41 6581 INFO Opening listening socket succeeded
Serving HTTP on port 8081, directory /tmp/faa
[gpadmin@mdw tmp]$</code>
</blockquote>


Start a psql session as gpadmin and execute the create_load_tables.sql script.  This script creates two tables: the faa_otp_load table, into which gpdist will load data, and the faa_load_errors table, where load errors will be logged. (The faa_load_errors table may already exist. Ignore the error message.) The faa_otp_load table is structured to match the format of the input data from the FAA Web site. This is a pure metadata operation. No data has moved from the data files on the host to the database yet. The external table definition references files in the faa directory that match the pattern otp*.gz. There are two matching files, one containing data for December 2009, the other for January 2010.
Then, you move data from the external table to the faa_otp_load table. 



<blockquote>
<pre><code>[gpadmin@mdw tmp]$ cd faa
[gpadmin@mdw faa]$
[gpadmin@mdw faa]$
[gpadmin@mdw faa]$ psql -U gpadmin tutorial
psql (14.4, server 14.4)
Type "help" for help.

tutorial=#
tutorial=# \i create_load_tables.sql
CREATE TABLE
CREATE TABLE
tutorial=# \i create_ext_table.sql
psql:create_ext_table.sql:5: NOTICE:  HEADER means that each one of the data files has a header row
CREATE EXTERNAL TABLE
tutorial=#
tutorial=# INSERT INTO faa.faa_otp_load SELECT * FROM faa.ext_load_otp;
NOTICE:  HEADER means that each one of the data files has a header row
NOTICE:  found 26526 data formatting errors (26526 or more input rows), rejected related input data
INSERT 0 1024552
tutorial=#
</code></pre>
</blockquote>

Cloudberry moves data from the gzip files into the load table in the database. In a production environment, you could have many gpfdist processes running, one on each host or several on one host, each on a separate port number. 

Examine the errors briefly. (The \x on psql meta-command changes the display of the results to one line per column, which is easier to read for some result sets.)

<blockquote>
<pre><code>
tutorial=# \x
Expanded display is on.
tutorial=#
tutorial=#  select DISTINCT relname, errmsg, count(*) from gp_read_error_log('faa.ext_load_otp') GROUP BY 1,2;
-[ RECORD 1 ]------------------------------------------------------
relname | ext_load_otp
errmsg  | invalid input syntax for type integer: "", column deptime
count   | 26526

tutorial=#
tutorial=# \q
[gpadmin@mdw faa]$
[gpadmin@mdw faa]$
</code></pre>
</blockquote>
</ol>

<h4>
<a id="load-data-with-gpload" class="anchor" href="#load-data-with-gpload" aria-hidden="true"><span class="octicon octicon-link"></span></a>Load data with gpload</h4>

Cloudberry provides a wrapper program for gpfdist called gpload that does much
of the work to set up external table and data movement.  In this exercise, you will reload the faa_otp_load table using the gpload utility.  

<ol>

Because gpload use gpfdist in the backend, you must first kill gpfdist processes you started in the previous exercise. Edit and customize the gpload.yaml input file. Be sure to set the correct path about faa directory. Notice the "TRUNCATE: true" preload instruction ensures that the data loaded in the previous exercise will be removed before the load in this exercise starts.  You then execute gpload with gpload.yaml input file. (Include the -v flag if you want to see details of the loading process.) 

<blockquote>
<pre><code>[gpadmin@mdw faa]$
[gpadmin@cbdb14-master faa]$ ps -ef|grep gpfdist
gpadmin  119294 117148  0 16:10 pts/0    00:00:01 gpfdist -d /tmp/faa -p 8081
gpadmin  119484 117148  0 16:25 pts/0    00:00:00 grep --color=auto gpfdist
[gpadmin@mdw faa]$ pkill gpfdist
[gpadmin@mdw faa]$ ps -ef|grep gpfdist
gpadmin  119489 117148  0 16:25 pts/0    00:00:00 grep --color=auto gpfdist
[1]+  Exit 1                  gpfdist -d /tmp/faa -p 8081 > /tmp/gpfdist.log 2>&1
[gpadmin@mdw faa]$
[gpadmin@mdw faa]$ cat ./gpload.yaml
---
VERSION: 1.0.0.1
# describe the Greenplum database parameters
DATABASE: tutorial
USER: gpadmin
HOST: mdw
PORT: 5432
# describe the location of the source files
# in this example, the database master lives on the same host as the source files
GPLOAD:
   INPUT:
    - SOURCE:
         LOCAL_HOSTNAME:
           - mdw
         PORT: 8081
         FILE:
           - /tmp/faa/otp*.gz
    - FORMAT: csv
    - QUOTE: '"'
    - ERROR_LIMIT: 50000
    - ERROR_TABLE: faa.faa_load_errors
   OUTPUT:
    - TABLE: faa.faa_otp_load
    - MODE: INSERT
   PRELOAD:
    - TRUNCATE: true
[gpadmin@mdw faa]$
[gpadmin@mdw faa]$ gpload -f gpload.yaml -l gpload.log
2023-08-09 16:48:35|INFO|gpload session started 2023-08-09 16:48:35
2023-08-09 16:48:35|INFO|started gpfdist -p 8081 -P 8082 -f "/tmp/faa/otp*.gz" -t 30
2023-08-09 16:48:35|INFO|reusing external table ext_gpload_reusable_a7ac9df2_3690_11ee_bcb5_fa163eed75ee
2023-08-09 16:48:37|WARN|26528 bad rows
2023-08-09 16:48:37|WARN|Please use following query to access the detailed error
2023-08-09 16:48:37|WARN|select * from gp_read_error_log('ext_gpload_reusable_a7ac9df2_3690_11ee_bcb5_fa163eed75ee') where cmdtime > to_timestamp('1691570915.7685921')
2023-08-09 16:48:37|INFO|running time: 1.96 seconds
2023-08-09 16:48:37|INFO|rows Inserted          = 1024552
2023-08-09 16:48:37|INFO|rows Updated           = 0
2023-08-09 16:48:37|INFO|data formatting errors = 26528
2023-08-09 16:48:37|INFO|gpload succeeded with warnings
[gpadmin@mdw faa]$
</code></pre>
</blockquote>
</ol>

<h4>
<a id="create-and-load-fact-tables" class="anchor" href="#create-and-load-fact-tables" aria-hidden="true"><span class="octicon octicon-link"></span></a>Create and Load fact tables</h4>

The final step of the ELT process is to move data from the load table to the fact table.  For the FAA example, you create two fact tables. The faa.otp_r table is a row-oriented table, which will be loaded with data from the faa.faa_otp_load table. The faa.otp_c table has the same structure as the faa.otp_r table, but is column-oriented and partitioned. You will load it with data from the faa.otp_r table.  The two tables will contain identical data and allow you to experiment with a column-oriented and partitioned table in addition to a traditional row-oriented table. Then you create the faa.otp_r and faa.otp_c tables by executing the create_fact_tables.sql script.  Load the data from the faa_otp_load table into the faa.otp_r table using the SQL INSERT FROM statement. Load the faa.otp_c table from the faa.otp_r table. Both of these loads can be accomplished by running the load_into_fact_table.sql script. 

<ol>
<blockquote>
<code>[gpadmin@mdw faa]$ psql -U gpadmin tutorial
psql (14.4, server 14.4)
Type "help" for help.

tutorial=# \i create_fact_tables.sql
CREATE TABLE
CREATE TABLE
tutorial=#
tutorial=# \i load_into_fact_table.sql
INSERT 0 1024552
INSERT 0 1024552
tutorial=#</code>
</blockquote>
</ol>

<h3>
<a id="data-loading-summary" class="anchor" href="#data-loading-summary" aria-hidden="true"><span class="octicon octicon-link"></span></a>Data loading summary</h3>

The ability to load billions of rows quickly into the Cloudberry database is one of its key features. Using “Extract, Load and Transform” (ELT) allows load processes to make use of the massive parallelism of the Cloudberry system by staging the data (perhaps just the use of external tables) and then applying data transformations within Cloudberry Database. Set-based operations can be done in parallel, maximizing performance.

With other loading mechanisms such as COPY, data is loaded through the master in a single process. This does not take advantage of the parallel processing power of Cloudberry segments. External tables provide a way of leveraging the parallel processing power of segments for data loading. Also, unlike other loading mechanisms, you can access multiple data sources with one SELECT of an external table.

External tables make static data available inside the database. External tables can be defined with file:// or gpfdist:// protocols. gpfdist is a file server program that loads files in parallel. Since the data is static, external tables can be rescanned during a query execution.

External Web tables allow http:// protocol or an EXECUTE clause to execute an operating system command or script. That data is assumed to be dynamic—query plans involving Web tables do not allow rescanning because the data could change during query execution. Execution plans may be slower, as data must be materialized (I/O) if it cannot fit in memory.

The script or process to populate a table with external Web tables may be executed on every segment host. It is possible, therefore, to have duplication of data. This is something to be aware of and check for when using Web tables, particularly with SQL extract calls to another database.
