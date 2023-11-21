# Cloudberry Database Bootcamp

These tutorials showcase how Cloudberry Database can address day-to-day tasks
performed in typical DW, BI and data science environments. It is designed to
be used with the Cloudberry Database Sandbox, which is based on the Docker
with the CentOS 7.9 OS.

![CloudberryDB Sandbox](./images/cbdb-sandbox.png)

## Bootcamp Outline

### 1. [CloudberryDB Sandbox](./cbdb-sandbox)

This document guides you on how to quickly set up and connect to a single-node
Cloudberry Database in a Docker environment. You can try out Cloudberry
Database by performing some basic operations and running SQL commands.

### 2. 101-CloudberryDB Tourials

This part contains a series of tutorials for quickly trying out Cloudberry
Database based on the CloudberryDB Sandbox.

Before starting to read the tutorials, you are expected to finish installing
the single-node Cloudberry Database by following the [CloudberryDB Sandbox](./cbdb-sandbox).

The series includes the following tutorials. Follow them in sequence.

- [Lesson 0: Introduction to Database and CloudberryDB Architecture](./101-0-introduction-to-database-and-cloudberrydb-architecture)
- [Lesson 1: Create Users and Roles](./101-1-create-users-and-roles)
- [Lesson 2: Create and Prepare Database](./101-2-create-and-prepare-database)
- [Lesson 3: Create Tables](./101-3-create-tables)
- [Lesson 4: Data Loading](./101-4-data-loading)
- [Lesson 5: Queries and Performance Tuning](./101-5-queries-and-performance-tuning)
- [Lesson 6: Backup and Recovery Operations](./101-6-backup-and-recovery-operations)

### 3. [102-CloudberryDB Crash Course](./102-cbdb-crash-course)

This crash course provides an extensive overview of Cloudberry Database, an
open-source Massively Parallel Processing (MPP) database. It covers key
concepts, features, utilities, and hands-on exercises to become proficient
with CBDB.

### 4. 103-CloudberryDB Performance Benchmark

This tutorial will show you how to perform a CloudberryDB performance
benchmark in the CloudberryDB Sandbox Docker image. The benchmark process
consists of two parts:

- [103-1: TPC-H benchmark](./103-cbdb-performance-benchmark-tpch)
- [103-2: TPC-DS benchmark](./103-cbdb-performance-benchmark-tpcds)

These benchmarks are designed to simulate real-world scenarios and measure the
performance of decision support systems under various conditions.

By completing this tutorial, you will gain a comprehensive understanding of
CloudberryDB's performance capabilities and how to effectively benchmark its
performance using industry-standard tools and techniques.

### 5. 104-CloudberryDB for Data Science

- [104-1: Introduction to CloudberryDB In-Database Analytics](./104-1-introduction-to-cloudberrydb-in-database-analytics)
- [104-2: HashML for Data Science](./104-2-hashml-for-datascience)

## Get the Source

You can get the whole Bootcamp source code from the GitHub repo
[cloudberrydb/bootcamp](https://github.com/cloudberrydb/bootcamp).
