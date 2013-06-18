/*
* @author: Justin Leto
* @date: June 16, 2013
*
* description:
* 	This function goes to the data files on disk to estimate table size
*	to avoid instances where tables are locked and cannot be read.
*   
*/

/* usage:
		select * from _monitoring.fn_table_size_nolock('meetupusers');
	
*/

/* check if the _monitoring schema exists */
do $$
begin
	if not (select exists(select * from information_schema.schemata where schema_name = '_monitoring'))
	then
		create Schema _monitoring;
	end if;
end $$;

create or replace function _monitoring.fn_table_size_nolock(tablename regclass)
returns bigint
as $BODY$
declare
	classoutput record;
	tsid int;
	rid int;
	dbid int;
	filepath text;
	filename text;
	datadir text;
	i int:=0;
	tablesize bigint;
begin
	/* get data directory */
	execute 'show data_directory' into datadir;

	/* get relfilenode and reltablespace */
	select reltablespace as tsid,
		   relfilenode as rid into classoutput
	from pg_class
	where oid = tablename
	and relkind = 'r';

	/* throw an error if we can't find the tablename specified */
	if not found then
		raise exception 'tablename % not found', tablename;
	end if;

	tsid := classoutput.tsid;
	rid := classoutput.rid;

	/* get the database object identifier (oid) */
	select oid into dbid
	from pg_database
	where datname = current_database();

	/* use some internals knowledge to set the filepath */
	if tsid = 0 then
		filepath := datadir || '/base/' || dbid || '/' || rid;
	else
		filepath := datadir || '/pg_tblspc/'
							|| tsid || '/'
							|| dbid || '/'
							|| rid;
	end if;

	/* look for the first file report if missing */
	select (pg_stat_file(filepath)).size into tablesize;

	/* sum the sizes of additional files, if any */
	while found loop
		i:=i + 1;
		filename := filepath || '.' || i;

		/* pg_stat_file returns ERROR if it cannot see file
		   we trap error and exit loop */
		begin
			select tablesize + (pg_stat_file(filename)).size into tablesize;
		exception
			when others then
				exit;
		end;
	end loop;
	return tablesize;
end; $BODY$ language plpgsql;