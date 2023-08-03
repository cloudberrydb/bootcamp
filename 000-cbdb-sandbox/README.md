---
title: Install a Single-Node Cloudberry Database
---

# Install a Single-Node Cloudberry Database

This guide introduces how to quickly install and connect to a single-node Cloudberry Database. Following this guide, you can start trying out Cloudberry Database by performing some simple operations or running SQL commands on it.

> Note: This guide is intended for testing or development purposes, not for production deployments.

This guide introduces single-node installation on the following architectures:

- A standalone machine
- A pseudo-distributed cluster
- A fully-distributed cluster

## Prerequisites

Before moving on to the installation steps, make sure that your environment meets the following requirements:

Operating systems: CentOS 7.6, macOS

Required software: Docker Desktop

Other dependencies: Git, SSH, internet connection

## Install on a standalone machine

This section introduces how to install a single-node Cloudberry Database on a standalone machine, with one master node and two segments in a Docker container. In the Docker image, the binary source code of Cloudberry Database v1.3 is compiled. This process can run on either x86 or arm (including Mac M1) chips.

Following the steps below, Cloudberry Database v1.3 is installed by default. If you want to install a different version, replace the source code package in `./configs/cbdb-<XXX>.zip` with your desired one.

Installation steps:

1. Start Docker Desktop and make sure it is running properly on the target standalone machine.

2. Download this repository (which is [cloudberry/bootcamp](https://github.com/cloudberrydb/bootcamp)) to the target machine.

    ```shell
    git clone https://github.com/cloudberrydb/bootcamp.git
    ```

3. Enter the repository and run the `run.sh` script to start the Docker container. This will start the automatic installation process.

    ```shell
    cd <repo directory on the machine>/000-cbdb-sandbox
    chmod +x ./run.sh
    ./run.sh
    ```

    > Note: The `run.sh` script will have Cloudberry Database installed on CentOS 7.x. To use CentOS 8, run the `run_centos8.sh` script instead.

After the script finishes without error, the Cloudberry Database is installed successfully. You can now connect to the database and get ready to perform some simple operations on it.


1. Connect to the Docker container from hosting machine:

    ```shell
    ssh gpadmin@localhost # Password: Hashdata@123
    ```

    Alternatively, you can also use the following command. The `<container_id>` can be found by running `docker ps`:

    ```shell
    docker exec -it <container_id> /bin/bash
    ```

    If it is successful, you will see the following prompt:

    ```shell
    [gpadmin@mdw ~]$
    ```

2. Log into Cloudberry Database in Docker. See the following commands and example outputs:

    ```shell
    [root@mdw /] su - gpadmin  # Switches to the gpadmin user.

    # Last login: Wed Nov 16 17:04:08 CST 2022 on pts/1

    [gpadmin@mdw ~]$ psql  # Connects to the database with the default database name "gpadmin".

    # psql (14.4, server 14.4)
    # Type "help" for help.
    ```

    ```sql
    gpadmin=# SELECT VERSION();  -- Checks the database version.
                                                                                            version

    -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -----
    PostgreSQL 14.4 (Cloudberry Database 1.0.0 build dev) on aarch64-unknown-linux-gnu, compiled by gcc (GCC) 10.2.1 20210130 (Red Hat 10.2.1-11), 64-bit compiled on Dec  1 2022 11:3
    8:02
    (1 row)
    ```

Now you have got a Cloudberry Database for testing, enjoy!

## Pseudo-Distributed-Operation

## Fully-Distributed-Operation
