---
layout: default
title:  "Introduction to the Cloudberry Database Architecture"
permalink: /introduction-to-the-greenplum-database-architecture
---

<h2 class='inline-header'>Introduction to the Cloudberry Database Architecture</h2>

<p><a href="http://greenplum.org">Pivotal Cloudberry Database</a> is a massively parallel processing (MPP) database server with an architecture specially designed to manage large-scale analytic data warehouses and business intelligence workloads.</p>

<p>MPP (also known as a shared nothing architecture) refers to systems with two or more processors that cooperate to carry out an operation, each processor with its own memory, operating system and disks. Cloudberry uses this high-performance system architecture to distribute the load of multi-terabyte data warehouses, and can use all of a system's resources in parallel to process a query.</p>

<p>Cloudberry Database is based on PostgreSQL open-source technology. It is essentially several PostgreSQL database instances acting together as one cohesive database management system (DBMS). It is based on PostgreSQL 8.2.15, and in most cases is very similar to PostgreSQL with regard to SQL support, features, configuration options, and end-user functionality. Database users interact with Cloudberry Database as they would a regular PostgreSQL DBMS.</p>

<p>The internals of PostgreSQL have been modified or supplemented to support the parallel structure of Cloudberry Database. For example, the system catalog, optimizer, query executor, and transaction manager components have been modified and enhanced to be able to execute queries simultaneously across all of the parallel PostgreSQL database instances. The Cloudberry interconnect (the networking layer) enables communication between the distinct PostgreSQL instances and allows the system to behave as one logical database.</p>

<p>Cloudberry Database also includes features designed to optimize PostgreSQL for business intelligence (BI) workloads. For example, Cloudberry has added parallel data loading (external tables), resource management, query optimizations, and storage enhancements, which are not found in standard PostgreSQL.</p>

<p>Cloudberry Database stores and processes large amounts of data by distributing the data and processing workload across several servers or hosts. Cloudberry Database is an array of individual databases based upon PostgreSQL 8.2 working together to present a single database image. The master is the entry point to the Cloudberry Database system. It is the database instance to which clients connect and submit SQL statements. The master coordinates its work with the other database instances in the system, called segments, which store and process the data.</p>

<p>Figure 1. High-Level Cloudberry Database Architecture<br>
<img src="https://raw.githubusercontent.com/greenplum-db/gpdb-sandbox-tutorials/gh-pages/images/highlevel_arch.jpg" width="400" alt="High-Level Cloudberry Database Architecture">  </p>

<p>The following topics describe the components that make up a Cloudberry Database system and how they work together. </p>

<h3>
<a id="greenplum-master" class="anchor" href="#greenplum-master" aria-hidden="true"><span class="octicon octicon-link"></span></a>Cloudberry Master</h3>

<p>The Cloudberry Database master is the entry to the Cloudberry Database system, accepting client connections and SQL queries, and distributing work to the segment instances.</p>

<p>Cloudberry Database end-users interact with Cloudberry Database (through the master) as they would with a typical PostgreSQL database. They connect to the database using client programs such as psql or application programming interfaces (APIs) such as JDBC or ODBC.</p>

<p>The master is where the global system catalog resides. The global system catalog is the set of system tables that contain metadata about the Cloudberry Database system itself. The master does not contain any user data; data resides only on the segments. The master authenticates client connections, processes incoming SQL commands, distributes workloads among segments, coordinates the results returned by each segment, and presents the final results to the client program.</p>

<h3>
<a id="greenplum-segments" class="anchor" href="#greenplum-segments" aria-hidden="true"><span class="octicon octicon-link"></span></a>Cloudberry Segments</h3>

<p>Cloudberry Database segment instances are independent PostgreSQL databases that each store a portion of the data and perform the majority of query processing.</p>

<p>When a user connects to the database via the Cloudberry master and issues a query, processes are created in each segment database to handle the work of that query. For more information about query processes, see About Cloudberry Query Processing.</p>

<p>User-defined tables and their indexes are distributed across the available segments in a Cloudberry Database system; each segment contains a distinct portion of data. The database server processes that serve segment data run under the corresponding segment instances. Users interact with segments in a Cloudberry Database system through the master.</p>

<p>Segments run on a servers called segment hosts. A segment host typically executes from two to eight Cloudberry segments, depending on the CPU cores, RAM, storage, network interfaces, and workloads. Segment hosts are expected to be identically configured. The key to obtaining the best performance from Cloudberry Database is to distribute data and workloads evenly across a large number of equally capable segments so that all segments begin working on a task simultaneously and complete their work at the same time.</p>

<h3>
<a id="greenplum-interconnect" class="anchor" href="#greenplum-interconnect" aria-hidden="true"><span class="octicon octicon-link"></span></a>Cloudberry Interconnect</h3>

<p>The interconnect is the networking layer of the Cloudberry Database architecture.</p>

<p>The interconnect refers to the inter-process communication between segments and the network infrastructure on which this communication relies. The Cloudberry interconnect uses a standard 10-Gigabit Ethernet switching fabric.</p>

<p>By default, the interconnect uses User Datagram Protocol (UDP) to send messages over the network. The Cloudberry software performs packet verification beyond what is provided by UDP. This means the reliability is equivalent to Transmission Control Protocol (TCP), and the performance and scalability exceeds TCP. If the interconnect used TCP, Cloudberry Database would have a scalability limit of 1000 segment instances. With UDP as the current default protocol for the interconnect, this limit is not applicable.</p>

<h3>
<a id="pivotal-query-optimizer" class="anchor" href="#pivotal-query-optimizer" aria-hidden="true"><span class="octicon octicon-link"></span></a>Pivotal Query Optimizer</h3>

<p>The Pivotal Query Optimizer brings a state of the art query optimization framework to Cloudberry Database that is distinguished from other optimizers in several ways:</p>

<ul>
<li><p><strong>Modularity.</strong>  Pivotal Query Optimizer is not confined inside a single RDBMS. It is currently leveraged in both Cloudberry Database and Pivotal HAWQ, but it can also be run as a standalone component to allow greater flexibility in adopting new backend systems and using the optimizer as a service. This also enables elaborate testing of the optimizer without going through the other components of the database stack.</p></li>
<li><p><strong>Extensibility.</strong>  The Pivotal Query Optimizer has been designed as a collection of independent components that can be replaced, configured, or extended separately. This significantly reduces the development costs of adding new features, and also allows rapid adoption of emerging technologies. Within the Query Optimizer, the representation of the elements of a query has been separated from how the query is optimized. This lets the optimizer treat all elements equally and avoids the issues with the imposed order of optimizations steps of multi-phase optimizers.</p></li>
<li><p><strong>Performance.</strong>  The Pivotal Query Optimizer leverages a multi-core scheduler that can distribute individual optimization tasks across multiple cores to speed up the optimization process. This allows the Query Optimizer to apply all possible optimizations as the same time, which results in many more plan alternatives and a wider range of queries that can be optimized. For instance, when the Pivotal Query Optimizer was used with TPC-H Query 21 it generated 1.2 Billion possible plans in 250 ms. This is especially important in Big Data Analytics where performance challenges are magnified by the volume of data that needs to be processed. A suboptimal optimization choice could very well lead to a query that just runs forever.</p></li>
</ul>

