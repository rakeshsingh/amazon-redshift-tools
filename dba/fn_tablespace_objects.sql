/*
* @author: Justin Leto
* @date: July 8th, 2013
*
* Description:
* 	DBA functions that report various information about tablespaces.
*
*/

/* usage:

	select * from _dba.fn_tablespace_objects()
	select * from _dba.fn_tablespace_parentless_indexes()

*/

/* Check for _dba schema. If it doesn't exist, create it. */
do $$
begin
	if not (SELECT exists(select schema_name FROM information_schema.schemata WHERE schema_name = '_dba'))
	then
		create Schema _dba;
	end if;
end $$;

/* Function to view tablespaces and objects */
create or replace function _dba.fn_tablespace_objects()
returns table (
	spacename name,
	relname name,
	objtype text
	)
as $BODY$
begin
	return query
	select ts.spcname,
			 c.relname,
			case when relpersistence <> 'p' then 'temp ' else '' end ||
			case
				when relkind = 'r' then 'table'
				when relkind = 'v' then 'view'
				when relkind = 'S' then 'sequence'
				when relkind = 'c' then 'type'
			else 'index' end as objtype	
	from pg_class c join pg_tablespace ts
	on (case when c.reltablespace = 0 then
			(select dattablespace
			from pg_database
			where datname = current_database())
		else c.reltablespace end) = ts.oid
	where  c.relname not like 'pg_toast%'
	and relnamespace not in (select oid from pg_namespace where nspname in ('pg_catalog', 'information_schema'));
end; $BODY$ language plpgsql;

comment on function _dba.fn_tablespace_objects() is 'DBA function to view tablespaces and their corresponding objects.';

/* Function to view indexes in different tablespaces than their parent objects */
create or replace function _dba.fn_tablespace_parentless_indexes()
returns table (
	indexname name,
	index_tablespace name,
	tablename name,
	table_tablespace name
	)
as $BODY$
begin
	return query
	select i.relname as indexname,
			tsi.spcname as index_tablespace,
			t.relname as tablename,
			tst.spcname as table_tablespace
	from (((pg_class t
			join pg_tablespace tst
				on t.reltablespace = tst.oid)
			join pg_index pgi
				on pgi.indexrelid = t.oid)
			join pg_class i
				on pgi.indexrelid = i.oid)
			join pg_tablespace tsi
				on i.reltablespace = tsi.oid
	where i.relname not like 'pg_toast%'
	and	i.reltablespace != t.reltablespace;
end; $BODY$ language plpgsql;

comment on function _dba.fn_tablespace_parentless_indexes() is 'DBA function view indexes in different tablespaces than their parent objects.';