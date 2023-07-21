---
layout: default
title:  "Create Users and Roles"
permalink: /create-users-and-roles
---


<h2 class='inline-header'>Create Users and Roles</h2>

<p>Cloudberry Database manages database access using roles. Initially, there is one superuser role—the role associated with the OS user who initialized the database instance, usually gpadmin. This user owns all of the Cloudberry Database files and OS processes, so it is important to reserve the gpadmin role for system tasks only.  </p>

<p>A role can be a user or a group. A user role can log in to a database; that is, it has the LOGIN attribute. A user or group role can become a member of a group.</p>

<p>Permissions can be granted to users or groups. Initially, of course, only the gpadmin role is able to create roles. You can add roles with the createuser utility command, CREATE ROLE SQL command, or the CREATE USER SQL command. The CREATE USER command is the same as the CREATE ROLE command except that it automatically assigns the role the LOGIN attribute. </p>

<h3>
<a id="exercises" class="anchor" href="#exercises" aria-hidden="true"><span class="octicon octicon-link"></span></a>Exercises</h3>

<h4>
<a id="create-a-user-with-the-create-user-command" class="anchor" href="#create-a-user-with-the-create-user-command" aria-hidden="true"><span class="octicon octicon-link"></span></a>Create a user with the CREATE USER command</h4>

<blockquote>
<pre><code>[gpadmin@mdw ~]$ psql
psql (14.4, server 14.4)
Type "help" for help.

gpadmin=#
gpadmin=# CREATE USER lily;
NOTICE:  resource queue required -- using default resource queue "pg_default"
CREATE ROLE
gpadmin=#
gpadmin=#
gpadmin=# \du
                             List of roles
 Role name |                   Attributes                   | Member of
-----------+------------------------------------------------+-----------
 gpadmin   | Superuser, Create role, Create DB, Replication | {}
 lily      |                                                | {}

gpadmin=#
gpadmin=#
</code></pre>
</blockquote>


<h4>
<a id="create-a-user-with-the-createuser-utility-command" class="anchor" href="#create-a-user-with-the-createuser-utility-command" aria-hidden="true"><span class="octicon octicon-link"></span></a>Create a user with the createuser utility command</h4>

<blockquote>

<pre><code>[gpadmin@mdw ~]$ createuser --interactive lucy
Shall the new role be a superuser? (y/n) y
[gpadmin@mdw ~]$
[gpadmin@mdw ~]$ psql
psql (14.4, server 14.4)
Type "help" for help.

gpadmin=# \du
                             List of roles
 Role name |                   Attributes                   | Member of
-----------+------------------------------------------------+-----------
 gpadmin   | Superuser, Create role, Create DB, Replication | {}
 lily      |                                                | {}
 lucy      | Superuser, Create role, Create DB              | {}

gpadmin=#
</code></pre>
</blockquote>



<h4>
<a id="create-a-users-group-and-add-the-users-to-it" class="anchor" href="#create-a-users-group-and-add-the-users-to-it" aria-hidden="true"><span class="octicon octicon-link"></span></a>Create a users group and add the users to it</h4>

<blockquote>
<pre><code>gpadmin=# CREATE ROLE users;
NOTICE:  resource queue required -- using default resource queue "pg_default"
CREATE ROLE
gpadmin=#
gpadmin=# GRANT users TO lily, lucy;
GRANT ROLE
gpadmin=#
gpadmin=# \du
                             List of roles
 Role name |                   Attributes                   | Member of
-----------+------------------------------------------------+-----------
 gpadmin   | Superuser, Create role, Create DB, Replication | {}
 lily      |                                                | {users}
 lucy      | Superuser, Create role, Create DB              | {users}
 users     | Cannot login                                   | {}

gpadmin=#
</code></pre>
</blockquote>

<p>After creating users, we could not login to Cloudberry database yet. </p>
<blockquote>
<pre><code>[gpadmin@mdw ~]$ psql -U lily -d gpadmin
psql: error: connection to server on socket "/tmp/.s.PGSQL.5432" failed: FATAL:  no pg_hba.conf entry for host "[local]", user "lily", database "gpadmin", no encryption
[gpadmin@mdw ~]$ psql -U lucy -d gpadmin
psql: error: connection to server on socket "/tmp/.s.PGSQL.5432" failed: FATAL:  no pg_hba.conf entry for host "[local]", user "lucy", database "gpadmin", no encryption
</code></pre>
</blockquote>

  
<p>There are one more step to perform to make user(lily, lucy) able to login to database. We need to adjust pg_hba.conf config file and use gpstop to populate the change.</p>

<blockquote>
<pre><code>[gpadmin@mdw ~]$ echo "local gpadmin lily trust" >> /data0/database/master/gpseg-1/pg_hba.conf
[gpadmin@mdw ~]$
[gpadmin@mdw ~]$ echo "local gpadmin lucy trust" >> /data0/database/master/gpseg-1/pg_hba.conf
[gpadmin@mdw ~]$
[gpadmin@mdw ~]$ gpstop -u
20230721:16:14:55:029695 gpstop:mdw:gpadmin-[INFO]:-Starting gpstop with args: -u
20230721:16:14:55:029695 gpstop:mdw:gpadmin-[INFO]:-Gathering information and validating the environment...
20230721:16:14:55:029695 gpstop:mdw:gpadmin-[INFO]:-Obtaining Cloudberry Coordinator catalog information
20230721:16:14:55:029695 gpstop:mdw:gpadmin-[INFO]:-Obtaining Segment details from coordinator...
20230721:16:14:55:029695 gpstop:mdw:gpadmin-[INFO]:-Cloudberry Version: 'postgres (Cloudberry Database) 1.0.0 build dev'
20230721:16:14:55:029695 gpstop:mdw:gpadmin-[INFO]:-Signalling all postmaster processes to reload
[gpadmin@mdw ~]$
[gpadmin@mdw ~]$
[gpadmin@mdw ~]$ psql -U lily -d gpadmin
psql (14.4, server 14.4)
Type "help" for help.

gpadmin=> \q
[gpadmin@mdw ~]$
[gpadmin@mdw ~]$ psql -U lucy -d gpadmin
psql (14.4, server 14.4)
Type "help" for help.

gpadmin=# \q
[gpadmin@mdw ~]$
</code></pre>
</blockquote>

<p>User lily and user lucy have had different privileges.</p>

