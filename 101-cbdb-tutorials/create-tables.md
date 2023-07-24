---
layout: default
title:  "Create Tables"
permalink: /create-tables
---

<h2 class='inline-header'>Create Tables</h2>

<p>The CREATE TABLE SQL statement creates a table in the database.</p>

<h4>
<a id="about-the-distribution-policy" class="anchor" href="#about-the-distribution-policy" aria-hidden="true"><span class="octicon octicon-link"></span></a>About the distribution policy</h4>

<p>The definition of a table includes the distribution policy for the data, which is critial for query performance. The goals for the distribution policy are to:  </p>

<ul>
<li>Distribute the volume of data and query execution work evenly among segments.<br>
</li>
<li>Enable segments to accomplish complicated query processing steps locally.<br>
</li>
</ul>

<p>The distribution policy determines how data is distributed among segments. To get an effective distribution policy requires understanding of the data’s characteristics, what kind of queries that would be executed on the data and what distribution strategy would best utilize the parallel execution capacity among segments.</p>

<p>Use the DISTRIBUTED clause in CREATE TABLE statement to define the
distribution policy for a table. Ideally, each segment would possess an equal volume of data and perform equal share of work when  queries run. There are two kinds of distribution policies grammar:</p>

<ul>
<li>DISTRIBUTED BY (column, ...) defines a distribution key from one or more columns. A hash function applied to the distribution key determines which segment would store accordingly row. Rows that have same distribution key are stored on the same segment. If the distribution keys are unique, the hash function would ensure that data is distributed evenly. The default distribution policy is a hash on the primary key of the table or the first column of table if no primary key is specified.</li>
<li>DISTRIBUTED RANDOMLY distributes rows in round-robin fashion among segments.</li>
</ul>

<p>When different tables that have the same/similar columns as distribution key are about to be joined, join action could be accomplished on segments, which will be much faster than re-distributing rows across segments and then joining. The random distribution policy can not make it happen, so it is definitely better to have a distribution key for a table.</p>

<h3>
<a id="exercises-2" class="anchor" href="#exercises-2" aria-hidden="true"><span class="octicon octicon-link"></span></a>Exercises</h3>

<h4>
<a id="execute-the-create-table-script-in-psql" class="anchor" href="#execute-the-create-table-script-in-psql" aria-hidden="true"><span class="octicon octicon-link"></span></a>Execute the CREATE TABLE script in psql</h4>

<p>The CREATE TABLE statements for the faa database are in the faa create_dim_tables.sql script. You may go to faa directory, take a look at create_dim_tables.sql script, use user lily to create tables.</p>

<ol>
<blockquote>
<pre><code>[gpadmin@mdw tmp]$ cd faa
[gpadmin@mdw faa]$
[gpadmin@mdw faa]$ more create_dim_tables.sql
drop table if exists faa.d_airports;
create table faa.d_airports (
    AirportID      integer,
    Name           text,
    City           text,
    Country        text,
    airport_code   text,
    ICOA_code      text,
    Latitude       float8,
    Longitude      float8,
    Altitude       float8,
    TimeZoneOffset float,
    DST_Flag       text ,
    TZ             text
)
distributed by (airport_code);

drop table if exists faa.d_wac;
create table faa.d_wac (wac smallint, area_desc text)
distributed by (wac);

drop table if exists faa.d_airlines;
create table faa.d_airlines (airlineid integer, airline_desc text)
distributed by (airlineid);

drop table if exists faa.d_cancellation_codes;
create table faa.d_cancellation_codes (cancel_code text, cancel_desc text)
distributed by (cancel_code);

drop table if exists faa.d_delay_groups;
create table faa.d_delay_groups (delay_group_code text, delay_group_desc text)
distributed by (delay_group_code);

drop table if exists faa.d_distance_groups;
create table faa.d_distance_groups (distance_group_code text, distance_group_desc text)
distributed by (distance_group_code);
[gpadmin@mdw faa]$
[gpadmin@mdw faa]$ psql -U lily tutorial
Password for user lily:
psql (14.4, server 14.4)
Type "help" for help.

tutorial=>
tutorial=> \i create_dim_tables.sql
psql:create_dim_tables.sql:1: NOTICE:  table "d_airports" does not exist, skipping
DROP TABLE
CREATE TABLE
psql:create_dim_tables.sql:18: NOTICE:  table "d_wac" does not exist, skipping
DROP TABLE
CREATE TABLE
psql:create_dim_tables.sql:22: NOTICE:  table "d_airlines" does not exist, skipping
DROP TABLE
CREATE TABLE
psql:create_dim_tables.sql:26: NOTICE:  table "d_cancellation_codes" does not exist, skipping
DROP TABLE
CREATE TABLE
psql:create_dim_tables.sql:30: NOTICE:  table "d_delay_groups" does not exist, skipping
DROP TABLE
CREATE TABLE
psql:create_dim_tables.sql:34: NOTICE:  table "d_distance_groups" does not exist, skipping
DROP TABLE
CREATE TABLE
tutorial=>
tutorial=> \dt
                    List of relations
 Schema |         Name         | Type  | Owner | Storage
--------+----------------------+-------+-------+---------
 faa    | d_airlines           | table | lily  | heap
 faa    | d_airports           | table | lily  | heap
 faa    | d_cancellation_codes | table | lily  | heap
 faa    | d_delay_groups       | table | lily  | heap
 faa    | d_distance_groups    | table | lily  | heap
 faa    | d_wac                | table | lily  | heap
(6 rows)

tutorial=>
tutorial=> \q
[gpadmin@mdw faa]$
</code></pre>
</blockquote>
</ol>
