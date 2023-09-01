## Background - Database concepts

Before starting this tutorials, spend some time to get familiar with how (single instance) databases work. If you already have some knowledge and experience with Oracle, MySQL or especially Postgres - this is great.

Databases (relational databases) are pieces of software that are used to store and manage/process data. Usually these databases are built with the client/server concept - the database is implemented as a server and multiple clients can connect and read or update the data.

The clients usually use SQL language to access the data (or some dialect of the SQL language specification). The clients can be different implementations - proprietary client libraries or ODBC/JDBC compliant.

Database data is usually stored in objects called tables. Tables have predefined structure (columns) and have zero or multiple rows.

Tables can be grouped in logical entities called 'schemas' (or namespaces).

Tables/schemas are located in a 'database' entity. Some database software supports multiple databases per instance (MySQL, Postgres), others support one database per instance (Oracle).

Along with tables there are supporting objects such as indexes, sequences, views, etc.

The database system needs to maintain some metadata - called the database catalog. The database catalog contains information about the data objects and supporting objects as well as anything else that needs to be stored on system level (user authentication, etc.).

SQL (Structured Query Language) is a descriptive language, not imperative language. Therefore it describes what the user needs, not how to get it. When the user describes what he needs, the database need to decide how to get it. This process is called query optimization. The end result from this process is a query plan, which is a step by step instruction how to get the result.

Now it's time to start the tutorial:

- [Lesson 1: Create Users and Roles](../101-cbdb-tutorials/create-users-and-roles.md)
- [Lesson 2: Create and Prepare Database](../101-cbdb-tutorials/create-and-prepare-database.md)
- [Lesson 3: Create Tables](../101-cbdb-tutorials/create-tables.md)
- [Lesson 4: Data Loading](../101-cbdb-tutorials/data-loading.md)
- [Lesson 5: Queries and Performance Tuning](../101-cbdb-tutorials/queries-and-performance-tuning.md)
- [Lesson 6: Backup and Recovery Operations](../101-cbdb-tutorials/backup-and-recovery-operations.md)
