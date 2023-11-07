---
title: "101 - Introduction to the Cloudberry Database Architecture"
---
# Introduction to the Cloudberry Database Architecture

[https://cloudberrydb.org](Cloudberry Database) is a massively parallel processing (MPP) database server with an architecture specially designed to manage large-scale analytic data warehouses and business intelligence workloads.

MPP (also known as a shared nothing architecture) refers to systems with two or more processors that cooperate to carry out an operation, each processor with its own memory, operating system and disks. Cloudberry uses this high-performance system architecture to distribute the load of multi-terabyte data warehouses and all of a system's resources in parallel to process a query.

Cloudberry Database is based on open-source PostgreSQL open-source. It is essentially several PostgreSQL database instances working together as one cohesive database management system (DBMS). It is based on PostgreSQL 14.4 kernel and in most cases it is very similar to PostgreSQL. Database users interact with Cloudberry Database as a regular PostgreSQL DBMS.

In Cloudberry, internals of PostgreSQL have been modified and optimized to support parallel structure of Cloudberry Database. For instance, system catalog, optimizer, query executor and transaction manager components have been modified and enhanced to be able to execute queries simultaneously across the parallel PostgreSQL database instances. Cloudberry interconnect (the networking layer) enables communication between distinct PostgreSQL instances and allows the system to behave as one logical database.

Cloudberry Database also includes features designed to optimize PostgreSQL for business intelligence (BI) workloads. For example, Cloudberry has added parallel data loading (external tables), resource management, query optimizations and storage enhancements,.

_Figure 1. High-Level Cloudberry Database Architecture_
![High-Level Cloudberry Database Architecture](../images/highlevel_arch.jpg)  

The following topics describe the components that make up a Cloudberry Database system and how they work together. 

## CloudberryDB Master

The Cloudberry Database master is the entry to the Cloudberry Database system, it accepts client connections, handle SQL queries and then distributs workload to the segment instances.

Cloudberry Database end-users only interact with Cloudberry Database through master node as a typical PostgreSQL database. They connect to database using client such as psql or drivers like JDBC or ODBC.

The master stores global system catalog. Global system catalog is set of system tables that contain metadata for Cloudberry Database itself. Master node does not contain any user table data; user table data resides only on segments. Master node would authenticate client connections, processe incoming SQL commands, distribute workloads among segments, collect the results returned by each segment and return the final results to the client.

## CloudberryDB Segments

Cloudberry Database segment instances are independent PostgreSQL databases that each of them store a portion of the data and perform the majority of query execution work.

When a user connects to the database via the Cloudberry master and issues queries, accordingly execution plan would be distributed to each segment instance. For more information about query processes, see About Cloudberry Query Processing.

The server that has segments running on it is called segment host. A segment host usually has two to eight Cloudberry segments running on it, the number depends on serveral factors, CPU cores, memory, disk, network interfaces or workloads. To get better performance from Cloudberry Database, it is suggested to distribute data and workloads evenly across segments so that execution plan could be finished across all segments and with no bottleneck.

## CloudberryDB Interconnect

The interconnect is the networking layer of the Cloudberry Database architecture.

The interconnect refers to the inter-process communication mechanism in-between segments. By default, interconnect uses User Datagram Protocol (UDP) to send/receive messages over the network. Interconnect provide datagram verification and retransmission mechanism. Reliability is equivalent to Transmission Control Protocol (TCP), performance and scalability exceeds TCP. If user choose TCP in interconnect, Cloudberry would have limit around 1000 segment instances. With UDP and interconncet the limit does not exit.