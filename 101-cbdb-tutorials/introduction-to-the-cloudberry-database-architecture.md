---
layout: default
title:  "Introduction to the Cloudberry Database Architecture"
permalink: /introduction-to-the-cloudberry-database-architecture
---

## Background - Database concepts

Before starting this tutorials, spend some time to get familiar with how (single instance) databases work. If you already have some knowledge and experience with Oracle, MySQL or especially Postgres - this is great.

Databases (relational databases) are pieces of software that are used to store and manage/process data. Usually these databases are built with the client/server concept - the database is implemented as a server and multiple clients can connect and read or update the data.

The clients usually use SQL language to access the data (or some dialect of the SQL language specification). The clients can be different implementations - proprietary client libraries or ODBC/JDBC compliant.

Database data is usually stored in objects called tables. Tables have predefined structure (columns) and have zero or multiple rows.

Tables can be grouped in logical entities called 'schemas' (or namespaces).

Tables/schemas are located in a 'database' entity. Some database software supports multiple databases per instance (MySQL, Postgres), others support one database per instance (Oracle).

Along with tables there are supporting objects such as indexes, sequences, views, etc.

The database system needs to maintain some metadata - called the database catalog. The database catalog contains information about the data objects and supporting objects as well as anything else that needs to be stored on system level (user authentication, etc.).

SQL (Structured Query Language) is a descriptive language, not imperative language. Therefore it describes what the user needs, not how to get it. When the user describes what he needs, the database need to decide how to get it. This process is called query optimization. The end result from this process is a query plan, which is a step by step instruction how to get the result.

<h2 class='inline-header'>Introduction to the Cloudberry Database Architecture</h2>

<p><a href="https://cloudberrydb.org/">Cloudberry Database</a> is a massively parallel processing (MPP) database server with an architecture specially designed to manage large-scale analytic data warehouses and business intelligence workloads.</p>

<p>MPP (also known as a shared nothing architecture) refers to systems with two or more processors that cooperate to carry out an operation, each processor with its own memory, operating system and disks. Cloudberry uses this high-performance system architecture to distribute the load of multi-terabyte data warehouses and all of a system's resources in parallel to process a query.</p>

<p>Cloudberry Database is based on open-source PostgreSQL open-source. It is essentially several PostgreSQL database instances working together as one cohesive database management system (DBMS). It is based on PostgreSQL 14.4 kernel and in most cases it is very similar to PostgreSQL. Database users interact with Cloudberry Database as a regular PostgreSQL DBMS.</p>

<p>In Cloudberry, internals of PostgreSQL have been modified and optimized to support parallel structure of Cloudberry Database. For instance, system catalog, optimizer, query executor and transaction manager components have been modified and enhanced to be able to execute queries simultaneously across the parallel PostgreSQL database instances. Cloudberry interconnect (the networking layer) enables communication between distinct PostgreSQL instances and allows the system to behave as one logical database.</p>

<p>Cloudberry Database also includes features designed to optimize PostgreSQL for business intelligence (BI) workloads. For example, Cloudberry has added parallel data loading (external tables), resource management, query optimizations and storage enhancements,.</p>

<p>Figure 1. High-Level Cloudberry Database Architecture<br>
<img src="https://raw.githubusercontent.com/greenplum-db/gpdb-sandbox-tutorials/gh-pages/images/highlevel_arch.jpg" width="400" alt="High-Level Cloudberry Database Architecture">  </p>

<p>The following topics describe the components that make up a Cloudberry Database system and how they work together. </p>

<h3>
<a id="cloudberry-master" class="anchor" href="#cloudberry-master" aria-hidden="true"><span class="octicon octicon-link"></span></a>Cloudberry Master</h3>

<p>The Cloudberry Database master is the entry to the Cloudberry Database system, it accepts client connections, handle SQL queries and then distributs workload to the segment instances.</p>

<p>Cloudberry Database end-users only interact with Cloudberry Database through master node as a typical PostgreSQL database. They connect to database using client such as psql or drivers like JDBC or ODBC.</p>

<p>The master stores global system catalog. Global system catalog is set of system tables that contain metadata for Cloudberry Database itself. Master node does not contain any user table data; user table data resides only on segments. Master node would authenticate client connections, processe incoming SQL commands, distribute workloads among segments, collect the results returned by each segment and return the final results to the client.</p>

<h3>
<a id="cloudberry-segments" class="anchor" href="#cloudberry-segments" aria-hidden="true"><span class="octicon octicon-link"></span></a>Cloudberry Segments</h3>

<p>Cloudberry Database segment instances are independent PostgreSQL databases that each of them store a portion of the data and perform the majority of query execution work.</p>

<p>When a user connects to the database via the Cloudberry master and issues queries, accordingly execution plan would be distributed to each segment instance. For more information about query processes, see About Cloudberry Query Processing.</p>

<p>The server that has segments running on it is called segment host. A segment host usually has two to eight Cloudberry segments running on it, the number depends on serveral factors, CPU cores, memory, disk, network interfaces or workloads. To get better performance from Cloudberry Database, it is suggested to distribute data and workloads evenly across segments so that execution plan could be finished across all segments and with no bottleneck.</p>

<h3>
<a id="cloudberry-interconnect" class="anchor" href="#cloudberry-interconnect" aria-hidden="true"><span class="octicon octicon-link"></span></a>Cloudberry Interconnect</h3>

<p>The interconnect is the networking layer of the Cloudberry Database architecture.</p>

<p>The interconnect refers to the inter-process communication mechanism in-between segments. By default, interconnect uses User Datagram Protocol (UDP) to send/receive messages over the network. Interconnect provide datagram verification and retransmission mechanism. Reliability is equivalent to Transmission Control Protocol (TCP), performance and scalability exceeds TCP. If user choose TCP in interconnect, Cloudberry would have limit around 1000 segment instances. With UDP and interconncet the limit does not exit.</p>

<h3>
<a id="pivotal-query-optimizer" class="anchor" href="#pivotal-query-optimizer" aria-hidden="true"><span class="octicon octicon-link"></span></a>Pivotal Query Optimizer</h3>

<p>The Pivotal Query Optimizer brings a state of the art query optimization framework to Cloudberry Database that is distinguished from other optimizers in several ways:</p>

<ul>
<li><p><strong>Modularity.</strong>  Pivotal Query Optimizer is not confined inside a single RDBMS. It is currently not only leveraged in Cloudberry Database, Greenplum and Pivotal HAWQ, but it can also be run as a standalone component. It has greater flexibility to adopt new backend systems. This also enables the capability to test query optimizer without touching other components inside database.</p></li>
  
<li><p><strong>Extensibility.</strong>  The Pivotal Query Optimizer has been designed as a collection of independent components that can be replaced, configured or extended separately. This has significantly reduced development costs when adding new features and allows rapid adoption of emerging technologies. Within Pivotal Query Optimizer, representation of the elements of a query has been separated from how the query is optimized. This enables the optimizer to treat all elements equally and to avoid the issues with the imposed order of optimization steps of multi-phase optimizers.</p></li>

<li><p><strong>Performance.</strong>  The Pivotal Query Optimizer leverages a multi-core scheduler that could distribute individual optimization task across multiple cores to speed up optimization processes. This allows the Query Optimizer to apply all possible optimizations at the same time, which brings up more plan alternatives and wider range of queries that could be optimized. For instance, when the Pivotal Query Optimizer was used to run TPC-H Query 21, it generates 1.2 billion possible plans in 250 ms. This is especially important for Big Data Analytics where performance challenge becomes critical for high volume of data that needs to be processed. A sub-optimal optimization choice sometimes lead to a query that just runs forever.</p></li>
</ul>

