# Decision Support Benchmark for HashData database.

This tool is based on the benchmark tool [pivotal TPC-DS](https://github.com/pivotal/TPC-DS).
This repo contains automation of running the DS benchmark on an existing Hashdata cluster.

## Context


### Supported TPC-DS Versions

TPC has published the following TPC-DS standards over time:
| TPC-DS Benchmark Version | Published Date | Standard Specification |
|-|-|-|
| 3.2.0 (latest) | 2021/06/15 | http://www.tpc.org/tpc_documents_current_versions/pdf/tpc-ds_v3.2.0.pdf |
| 2.1.0 | 2015/11/12 | http://www.tpc.org/tpc_documents_current_versions/pdf/tpc-ds_v2.1.0.pdf |
| 1.3.1 (earliest) | 2015/02/19 | http://www.tpc.org/tpc_documents_current_versions/pdf/tpc-ds_v1.3.1.pdf |

As of version 1.2 of this tool TPC-DS 3.2.0 is used.

## Setup
### Prerequisites

This is following up tutorial for previous bootcamp steps. Make sure env for Cloudberry Database is up and running.

All the following examples are using standard host name convention of HashData using `mdw` for master node, and `sdw1..n` for the segment nodes.

### TPC-DS Tools Dependencies

Install the dependencies on `mdw` for compiling the `dsdgen` (data generation) and `dsqgen` (query generation).

```bash
docker exec -it <container-id>  /bin/bash
yum -y install gcc make byacc
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

```
docker exec -it <container-id>  /bin/bash
su - gpadmin
tar xzf TPC-DS-CBDB.tar.gz
cd ~/TPC-DS-CBDB
./run.sh
```

You may check tpch execution result log information under the same directory with similar name like below.

```
tpch_20230727_176233.log
```
