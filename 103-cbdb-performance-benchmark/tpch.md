# Decision Support Benchmark for Cloudberry Database.

This tool is based on the benchmark tool [TPC-H](https://www.tpc.org/tpch/default5.asp).
This repo contains automation of running the TPC-H benchmark on an existing Cloudberry cluster.

## Context

### Supported TPC-H Versions

TPC has published the following TPC-H standards over time:

| TPC-H Benchmark Version | Published Date | Standard Specification |
|-|-|-|
| 3.0.0 (latest) | 2021/02/18 | https://tpc.org/TPC_Documents_Current_Versions/pdf/tpc-h_v3.0.0.pdf|

## Setup

### Prerequisites

This is following up tutorial for previous bootcamp steps. Make sure env for Cloudberry Database is up and running.

### TPC-H Tools Dependencies

Make sure that gcc and make are intalled on `mdw` for compiling the `dbgen` (data generation) and `qgen` (query generation).

You can install the dependencies on `mdw`:

```bash
docker exec -it <container-id>  /bin/bash
yum -y install gcc make
```

The original source code is from http://tpc.org/tpc_documents_current_versions/current_specifications5.asp.

### Packages

TPC-H and TPC-DS packages are already under "mdw:/tmp/" folder.

```bash
[gpadmin@mdw tmp]$ ls -rlt
-rw-rw-r--  1 root    root    24520013 Jul 27 14:18 TPC-H-CBDB.tar.gz
-rw-rw-r--  1 root    root     7096941 Jul 27 14:18 TPC-DS-CBDB.tar.gz
```

### Execution

To run the benchmark, login as `gpadmin` on `mdw`:

```bash
docker exec -it <container-id>  /bin/bash
su - gpadmin
tar xzf TPC-H-CBDB.tar.gz
cd ~/TPC-H-CBDB
./run.sh
```

You may check tpch execution result log information under the same directory with similar name like below.

```
tpch_20230727_145051.log
```
