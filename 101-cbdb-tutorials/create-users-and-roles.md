
# Lession 1: Create Users and Roles

Cloudberry Database manages database access using roles. Initially, there is one superuser role—the role associated with the OS user who initialized the database instance, usually `gpadmin`. This user owns all of the Cloudberry Database files and OS processes, so it is important to reserve the `gpadmin` role for system tasks only.

A role can be a user or a group. A user role can log in to a database; that is, it has the LOGIN attribute. A user or group role can become a member of a group.

Permissions can be granted to users or groups. Initially, of course, only the `gpadmin` role is able to create roles. You can add roles with the `createuser` utility command, `CREATE ROLE` SQL command, or the `CREATE USER` SQL command. The `CREATE USER` command is the same as the `CREATE ROLE` command except that it automatically assigns the role the `LOGIN` attribute.

## Quick-start operations

You can following the examples below to create users and roles.

### Prerequisites

Before moving on to the operations, make sure that you have installed Cloudberry Database by following [Install a Single-Node Cloudberry Database](../000-cbdb-sandbox/README.md).

### Create a user using the CREATE USER command

1. Connect to the database as the `gpadmin` user.

    ```shell
    [gpadmin@mdw ~]$ psql

    psql (14.4, server 14.4)
    Type "help" for help.
    ```

    ```shell
    gpadmin=#
    ```

2. Create a user named `lily` using the `CREATE USER` command, with a password `changeme`. After the creation, you need to enter the password to log in as the `lily` user.

    ```sql
    gpadmin=# CREATE USER lily WITH PASSWORD 'changeme';
    ```

    ```sql
    NOTICE:  resource queue required -- using default resource queue "pg_default"
    CREATE ROLE
    ```

3. Verify that the user was created.

    ```sql
    gpadmin=# \du
                                 List of roles
     Role name |                   Attributes                   | Member of
    -----------+------------------------------------------------+-----------
     gpadmin   | Superuser, Create role, Create DB, Replication | {}
     lily      |                                                | {}
    ```

    ```sql
    gpadmin=#
    ```

### Create a user using the createuser utility command

1. Create a user named `lucy` using the `createuser` utility command.

    ```shell
    [gpadmin@mdw ~]$ createuser --interactive lucy
    ```

    ```shell
    Shall the new role be a superuser? (y/n) y
    ```

2. Connect to the database as the `gpadmin` user.

    ```shell
    [gpadmin@mdw ~]$ psql

    psql (14.4, server 14.4)
    Type "help" for help.
    ```

3. Verify that the user was created.

    ```sql
    gpadmin=# \du
                                 List of roles
     Role name |                   Attributes                   | Member of
    -----------+------------------------------------------------+-----------
     gpadmin   | Superuser, Create role, Create DB, Replication | {}
     lily      |                                                | {}
     lucy      | Superuser, Create role, Create DB              | {}
    ```

    ```sql
    gpadmin=#
    ```

### Create a users group and add the users to it

1. Connect to the database as the `gpadmin` user.

    ```shell
    [gpadmin@mdw ~]$ psql

    psql (14.4, server 14.4)
    Type "help" for help.
    ```

    ```shell
    gpadmin=#
    ```

2. Create a group named `users` using the `CREATE ROLE` command.

    ```sql
    gpadmin=# CREATE ROLE users;
    ```

    ```sql
    NOTICE:  resource queue required -- using default resource queue "pg_default"
    CREATE ROLE
    ```
3. Add the `lily` and `lucy` users to the `users` group.

    ```sql
    gpadmin=# GRANT users TO lily, lucy;
    ```

    ```sql
    GRANT ROLE
    ```

4. Verify that the users were added to the group.

    ```sql
    gpadmin=# \du
                                 List of roles
     Role name |                   Attributes                   | Member of
    -----------+------------------------------------------------+-----------
     gpadmin   | Superuser, Create role, Create DB, Replication | {}
     lily      |                                                | {users}
     lucy      | Superuser, Create role, Create DB              | {users}
     users     | Cannot login                                   | {}
    ```

However, after creating the `users` group, `lily` and `lucy` cannot log into Cloudberry Database yet. See the following error messages.

```shell
[gpadmin@mdw ~]$ psql -U lily -d gpadmin

psql: error: connection to server on socket "/tmp/.s.PGSQL.5432" failed: FATAL:  no pg_hba.conf entry for host "[local]", user "lily", database "gpadmin", no encryption
```

```shell
[gpadmin@mdw ~]$ psql -U lucy -d gpadmin

psql: error: connection to server on socket "/tmp/.s.PGSQL.5432" failed: FATAL:  no pg_hba.conf entry for host "[local]", user "lucy", database "gpadmin", no encryption
```

To make users (`lily` and `lucy`) able to log into the database, you need to adjust the `pg_hba.conf` configuration file on the master node and use `gpstop` to populate the change.

1. Append the following lines to the `pg_hba.conf` file on the master node.

    ```shell
    [gpadmin@mdw ~]$ echo "local gpadmin lily md5" >> /data0/database/master/gpseg-1/pg_hba.conf
    [gpadmin@mdw ~]$ echo "local gpadmin lucy trust" >> /data0/database/master/gpseg-1/pg_hba.conf
    ```

    > **Tip:**
    >
    > - `pg_hba.conf` is a configuration file in Cloudberry Database to control access permissions.
    > - `md5` and `trust` are the authentication methods. `md5` means that the user needs to enter the password to log in. `trust` means that the user can log in without entering the password.

2. Use `gpstop` to populate the change.

    ```shell
    [gpadmin@mdw ~]$ gpstop -u

    20230721:16:14:55:029695 gpstop:mdw:gpadmin-[INFO]:-Starting gpstop with args: -u
    20230721:16:14:55:029695 gpstop:mdw:gpadmin-[INFO]:-Gathering information and validating the environment...
    20230721:16:14:55:029695 gpstop:mdw:gpadmin-[INFO]:-Obtaining Cloudberry Coordinator catalog information
    20230721:16:14:55:029695 gpstop:mdw:gpadmin-[INFO]:-Obtaining Segment details from coordinator...
    20230721:16:14:55:029695 gpstop:mdw:gpadmin-[INFO]:-Cloudberry Version: 'postgres (Cloudberry Database) 1.0.0 build dev'
    20230721:16:14:55:029695 gpstop:mdw:gpadmin-[INFO]:-Signalling all postmaster processes to reload
    ```

3. Verify that the users can log into the database.

    ```shell
    [gpadmin@mdw ~]$ psql -U lily -d gpadmin
    Password for user lily:

    psql (14.4, server 14.4)
    Type "help" for help.
    ```

    ```shell
    [gpadmin@mdw ~]$ psql -U lucy -d gpadmin

    psql (14.4, server 14.4)
    Type "help" for help.
    ```

    User `lily` and user `lucy` have had different privileges. You need to provide the password "changeme" for lily when login.

## What's more

- [Lesson 2: Create and Prepare Database](../101-cbdb-tutorials/create-and-prepare-database.md)

- [Lesson 3: Create Tables](../101-cbdb-tutorials/create-tables.md)

- [Lesson 4: Data Loading](../101-cbdb-tutorials/data-loading.md)

- [Lesson 5: Queries and Performance Tuning](../101-cbdb-tutorials/queries-and-performance-tuning.md)

- [Lesson 6: Backup and Recovery Operations](../101-cbdb-tutorials/backup-and-recovery-operations.md)
