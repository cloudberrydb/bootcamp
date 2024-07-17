---
title: Sandbox of Single-Node Cloudberry Database
---

# Install Single-Node Cloudberry Database in a Docker Container

This document guides you on how to quickly set up and connect to a single-node Cloudberry Database in a Docker environment. You can try out Cloudberry Database by performing some basic operations and running SQL commands.

> [!WARNING]
> This guide is intended for testing or development. DO NOT use it for production.


## Prerequisites

Make sure that your environment meets the following requirements:

- Platform requirement: Any platform with Docker runtime. For details, refer to [Get Started with Docker](https://www.docker.com/get-started/).
- Other dependencies: Git, SSH, and internet connection

## Build the Sandbox

This section introduces two methods to set up the Docker container. The container will host a CBDB single-node cluster intialized with one coordinator and three primary and mirror segments. Both x86 and ARM CPUs (including Apple chips) are supported.

> [!CAUTION]
> The CentOS Linux 7 the reached end of life (EOL) on June 30, 2024. The software source mirror (vault) only supports x86_64, the `altarch` source (like ARM) has been deprecated. So you cannot run the CentOS 7 sandbox on your macBook with M1/2. 

- Method 1 - Compile with the source code of the latest Cloudberry Database (released in [Cloudberry Database Release Page](https://github.com/cloudberrydb/cloudberrydb/releases)). The base OS will use CentOS 7.9 Docker container.
- Method 2 - Compile with the latest Cloudberry Database [main](https://github.com/cloudberrydb/cloudberrydb/tree/main) branch. The base OS will use Rocky Linux 9 Docker container.

Build steps:

1. Start Docker Desktop and make sure it is running properly on your host platform.

2. Download this repository (which is [cloudberrydb/bootcamp](https://github.com/cloudberrydb/bootcamp)) to the target machine.

    ```shell
    git clone https://github.com/cloudberrydb/bootcamp.git
    ```

3. Enter the repository and run the `run.sh` script to start the Docker container. This will start the automatic installation process. Depending on your environment, you may need to run this with 'sudo' command.

    - For latest Cloudberry DB release

    ```shell
    cd bootcamp/000-cbdb-sandbox
    ./run.sh
    ```

    - For latest main branch

    ```shell
    cd bootcamp/000-cbdb-sandbox
    ./run.sh -c main -o rockylinux9
    ```

    Once the script finishes without error, the sandbox is built and running successfully. The `docker run` command uses --detach option allowing you to ssh or access the running CBDB instance remotely.

    Please review run.sh script for additional options (e.g. setting Timezone in running container, only building container)

## Connect to the database

You can now connect to the database and try some basic operations.

1. Connect to the Docker container from the host machine:

    ```shell
    docker exec -it $(docker ps -q) /bin/bash
    ```

    If it is successful, you will see the following prompt:

    ```shell
    [root@mdw /]$
    ```

2. Log into Cloudberry Database in Docker. See the following commands and example outputs:

    ```shell
    [root@mdw /] su - gpadmin  # Switches to the gpadmin user.
    
    # Last login: Tue Oct 24 10:26:14 CST 2023 on pts/1
    
    [gpadmin@mdw ~]$ psql  # Connects to the database with the default database name "gpadmin".
    
    # psql (14.4, server 14.4)
    # Type "help" for help.
    ```

    ```sql
    gpadmin=# SELECT VERSION();  -- Checks the database version.
                                                                                            version
    
    -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -----
    PostgreSQL 14.4 (Cloudberry Database 1.0.0 build dev) on aarch64-unknown-linux-gnu, compiled by gcc (GCC) 10.2.1 20210130 (Red Hat 10.2.1-11), 64-bit compiled on Oct 24 2023 10:24:28
    (1 row)
    ```

In addition to using the `docker exec` command, you can also use the `ssh` command. This command will connect to the database with the default database name `gpadmin`:

```shell
ssh gpadmin@localhost # Password: cbdb@123
```

Now you have a Cloudberry Database and can continue with [Cloudberry Database Tutorials Based on Single-Node Installation](https://github.com/cloudberrydb/bootcamp/blob/main/101-cbdb-tutorials/README.md)! Enjoy!

