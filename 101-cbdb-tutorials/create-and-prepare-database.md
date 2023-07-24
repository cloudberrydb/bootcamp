---
layout: default
title:  "Create and Prepare Database"
permalink: /create-and-prepare-database
---

<h2 class='inline-header'>Create and Prepare Database</h2>

<p>Create a new database using the CREATE DATABASE SQL command in psql client or using createdb utility. Unless you specify a different one, the newly created database is a copy of template1 database.
To use the CREATE DATABASE command, you need to connect to a database. For Cloudberry Database system, you may connect to template1 database. The createdb utility is a wrapper around the CREATE DATABASE command. In this exercise you will create a new database with createdb utility, create schema and search path for schemas. You will connect to the tutorial databse as user1 with password set up before.</p>

<h3>
<a id="exercises-1" class="anchor" href="#exercises-1" aria-hidden="true"><span class="octicon octicon-link"></span></a>Exercises</h3>

<h4>
<a id="create-database" class="anchor" href="#create-database" aria-hidden="true"><span class="octicon octicon-link"></span></a>Create Database</h4>

<ol>

<blockquote>
<p><code>[gpadmin@mdw ~]$ dropdb tutorial
dropdb: error: database removal failed: ERROR:  database "tutorial" does not exist
[gpadmin@mdw ~]$ createdb tutorial
[gpadmin@mdw ~]$
[gpadmin@mdw ~]$ psql -l
                                List of databases
   Name    |  Owner  | Encoding |   Collate   |    Ctype    |  Access privileges
-----------+---------+----------+-------------+-------------+---------------------
 gpadmin   | gpadmin | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 postgres  | gpadmin | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 template0 | gpadmin | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/gpadmin         +
           |         |          |             |             | gpadmin=CTc/gpadmin
 template1 | gpadmin | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/gpadmin         +
           |         |          |             |             | gpadmin=CTc/gpadmin
 tutorial  | gpadmin | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
(5 rows)
[gpadmin@mdw ~]$</code></p>
</blockquote>

<p>Create entry in pg_hba.conf, connect to the tutorial database as lily, use the same password you set previously.</p>

<blockquote>
<p><code>[gpadmin@mdw ~]$ echo "local tutorial lily md5" >> /data0/database/master/gpseg-1/pg_hba.conf
[gpadmin@mdw ~]$
[gpadmin@mdw ~]$ gpstop -u
20230724:13:32:42:006438 gpstop:mdw:gpadmin-[INFO]:-Starting gpstop with args: -u
20230724:13:32:42:006438 gpstop:mdw:gpadmin-[INFO]:-Gathering information and validating the environment...
20230724:13:32:42:006438 gpstop:mdw:gpadmin-[INFO]:-Obtaining Cloudberry Coordinator catalog information
20230724:13:32:42:006438 gpstop:mdw:gpadmin-[INFO]:-Obtaining Segment details from coordinator...
20230724:13:32:42:006438 gpstop:mdw:gpadmin-[INFO]:-Cloudberry Version: 'postgres (Cloudberry Database) 1.0.0 build dev'
20230724:13:32:42:006438 gpstop:mdw:gpadmin-[INFO]:-Signalling all postmaster processes to reload
[gpadmin@mdw ~]$
[gpadmin@mdw ~]$
[gpadmin@mdw ~]$ psql -U lily tutorial
Password for user lily:
psql (14.4, server 14.4)
Type "help" for help.

tutorial=>
</code></p>
</blockquote>
</ol>

<h4>
<a id="grant-database-privileges-to-users" class="anchor" href="#grant-database-privileges-to-users" aria-hidden="true"><span class="octicon octicon-link"></span></a>Grant database privileges to users</h4>

<p>In a production database, you should grant users the minimum permissions required to do their work. For example, a user may need SELECT permissions on a table to view data, but UPDATE, INSERT, or DELETE to modify the data.  To complete the exercises in this guide, the database users will require permissions to create and manipulate objects in tutorial database.  </p>

<ol>
<p>You connect to the tutorial database as gpadmin, grant lily all privileges on the tutorial database.</p>

<blockquote>
<p><code>[gpadmin@mdw ~]$
[gpadmin@mdw ~]$ psql -U gpadmin tutorial
psql (14.4, server 14.4)
Type "help" for help.

tutorial=# GRANT ALL PRIVILEGES ON DATABASE tutorial TO lily;
GRANT
tutorial=# \q
[gpadmin@mdw ~]$</code></p>
</blockquote>

</ol>

<h4>
<a id="create-a-schema-and-set-a-search-path" class="anchor" href="#create-a-schema-and-set-a-search-path" aria-hidden="true"><span class="octicon octicon-link"></span></a>Create schema and set search path</h4>

<p>Database schema is a named container for a set of database objects, including tables, data types, and functions. One database can have multiple schemas. Objects in the schema are referenced by prefixing the object name with the schema name, separated with a period. For example, the person table in the employee schema is written employee.person.</p>

<p>The schema provides a namespace for the objects it contains. If the database is used for multiple applications, each with its own schema, the same table name can be used in each schema employee.person is a different table than customer.person. Both tables could be accessed in the same query as long as they are with accordingly schema name.</p>

<p>The database contains a schema search path including a list of schema names. The first schema in the search path is also the schema where new objects are created when no schema is specified. The default search path is user,public, so by default, each object you create belongs to a schema associated with your login name.  In this exercise, you will create a faa schema and set the search path to make faa the default schema.</p>

<p>The search path you set above is not persistent; you have to set it each time you connect to the database. You can associate a search path with the user role by using the ALTER ROLE command, so that each time you connect to the database with that role, the search path is restored:  </p>

<ol>

<p>Change to the directory containing the FAA data and scripts:</p>

<blockquote>
<p><code>[gpadmin@mdw faa]$ psql -U lily tutorial
Password for user lily:
psql (14.4, server 14.4)
Type "help" for help.

tutorial=>
tutorial=> DROP SCHEMA IF EXISTS faa CASCADE;
NOTICE:  schema "faa" does not exist, skipping
DROP SCHEMA
tutorial=> CREATE SCHEMA faa;
CREATE SCHEMA
tutorial=>
tutorial=> SET SEARCH_PATH TO faa, public, pg_catalog, gp_toolkit;
SET
tutorial=>
tutorial=> SHOW search_path;
            search_path
    -------------------------------------
 faa, public, pg_catalog, gp_toolkit
(1 row)
tutorial=> ALTER ROLE lily SET search_path TO faa, public, pg_catalog, gp_toolkit;
ALTER ROLE
tutorial=> \du
                             List of roles
 Role name |                   Attributes                   | Member of
-----------+------------------------------------------------+-----------
 gpadmin   | Superuser, Create role, Create DB, Replication | {}
 lily      |                                                | {}
tutorial=>
</code></p>
</blockquote>
</ol>
