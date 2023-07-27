Cloudberry: Setting up a Single Node Cluster.
=================

<!--ts-->
   * [Purpose](#purpose)
   * [Prerequisites](#prerequisites)
      * [Supported Platforms](#Supported-Platforms)
      * [Required Software](#Required-Software)
      * [Installing Software](#Installing-Software)
   * [Standalone Operation](#Standalone-Operation)
   * [Pseudo-Distributed Operation](#Pseudo-Distributed-Operation)
      * [Configuration](#Configuration)
      * [Setup ssh](#Setup-ssh)
   * [Fully-Distributed Operation](#Fully-Distributed-Operation)
<!--te-->

Purpose
============

This document describes how to set up and configure a single-node Cloudberry installation so that you can quickly perform simple operations and SQL command using Cloudberry database.

Prerequisites
============

Supported-Platforms
-----
* GNU/Linux is supported as a development and production platform.

Required-Software
-----
* GNU/Linux is supported as a development and production platform.

Installing-Software
-----
* GNU/Linux is supported as a development and production platform.

Standalone-Operation
============

In this scenario, it would deply a single node Cloudberry Database with one master and two segments inside one docker container.

This image using one of the main branch of Cloudberry source code and compiling the binary, which runs on both x86 and arm (Including Mac M1) chips. 
If you want to use a different version of CBDB, replace the CBDB source code package in "./configs/cbdb-<XXX>.zip" with the latest.
This version includes CBDB 1.2.0


Deploy steps:

1. Install Docker Desktop
2. Download this repo
3. execute run.sh

```
unzip cbdb-docker.zip
cd cbdb-docker
chmod +x ./run.sh
./run.sh
```

4. If you want to use Centos8 OS, execute run_centos8.sh

To use:

1. Connect to container from hosting machine:
```
ssh gpadmin@localhost (Password：Hashdata@123)
```
OR
```
docker exec -it <container-id> /bin/bash
```
If success, it will be like this:
```
[gpadmin@mdw ~]$
```
2. Log in database within the docker:

```
[root@mdw /]# su - gpadmin
Last login: Wed Nov 16 17:04:08 CST 2022 on pts/1
[gpadmin@mdw ~]$ psql
psql (14.4, server 14.4)
Type "help" for help.

gpadmin=# select version();
                                                                                        version

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----
 PostgreSQL 14.4 (Cloudberry Database 1.0.0 build dev) on aarch64-unknown-linux-gnu, compiled by gcc (GCC) 10.2.1 20210130 (Red Hat 10.2.1-11), 64-bit compiled on Dec  1 2022 11:3
8:02
(1 row)
```

Now you got a Cloudberry database for testing, enjoy!



Pseudo-Distributed-Operation
============

Fully-Distributed-Operation
============
