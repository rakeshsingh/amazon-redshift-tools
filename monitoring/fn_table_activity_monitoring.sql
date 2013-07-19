/*
* @author: Justin Leto
* @date: July 19, 2013
*
* description:
*   Table activity monitoring functions
*/

/* usage:
		select * from _monitoring.fn_table_activity()
	
*/

/* check if the _monitoring schema exists */
do $$
begin
	if not (select exists(select * from information_schema.schemata where schema_name = '_monitoring'))
	then
		create Schema _monitoring;
	end if;
end $$;

drop type if exists _monitoring.fileinfo cascade;

/* Type to support table_file_info function */
create type _monitoring.fileinfo as (
	file_name text,
	file_size bigint,
	ctime abstime,
	mtime abstime,
	atime abstime
);

comment on type _monitoring.fileinfo is 'Type to support _monitoring.fn_table_activity';

/* Function to show last table activity by querying table files. */
create or replace function _monitoring.fn_table_activity(schemaname text, tablename text)
returns setof _monitoring.fileinfo
as $BODY$
    import datetime, glob, os
    db_info = plpy.execute("""
                           select datname as db_name,
                           current_setting('data_directory') || '/base/' || db.oid as data_directory
                           from pg_database db
                           where datname = current_database()
                           """)
    #return db_info[0]['data_directory']
    table_info_plan = plpy.prepare("""
    select nspname as schemaname,
           relname as tablename,
           relfilenode as filename
     from pg_class c
     join pg_namespace ns on c.relnamespace=ns.oid
    where nspname=$1
      and relname=$2
    """, ['text','text'])
    table_info = plpy.execute(table_info_plan,[schemaname,tablename])
    filemask = '%s/%s*' % (db_info[0]['data_directory'], table_info[0] ['filename'])
    res=[]
    for filename in glob.glob(filemask):
        fstat = os.stat(filename)
        res.append((filename, fstat.st_size, datetime.datetime.fromtimestamp(fstat.st_ctime).isoformat(), datetime.datetime.fromtimestamp(fstat.st_mtime).isoformat(), datetime.datetime.fromtimestamp(fstat.st_atime).isoformat()))
    return res
$BODY$ language plpythonu;

comment on function _monitoring.fn_table_activity(schemaname text, tablename text) is 'Function to show last table activity by querying table files.';


/* Function to report table activity - latest modification and read access.*/
create or replace function _monitoring.fn_table_activity()
returns table (
	table_schema text,
	table_name text,
	latest_mod abstime,
	latest_read abstime
) as $$
begin
	return query
	select t.table_schema::text,
	t.table_name::text,
	(select max(mtime) as latest_mod from (select * from _monitoring.fn_active_tables(t.table_schema, t.table_name)) table_file) as latest_mod,
	(select max(atime) as latest_read from (select * from _monitoring.fn_active_tables(t.table_schema, t.table_name)) table_file) as latest_read
	from information_schema.tables t
	where t.table_schema not in ('pg_catalog', 'information_schema')
	and t.table_type = 'BASE TABLE';
end; $$ language plpgsql;

comment on function _monitoring.fn_table_activity() is 'Function to report table activity - latest modification and read access.';

