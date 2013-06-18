/*
* @author: Justin Leto
* @date: June 16, 2013
*
* description:
* 	Returns an estimate of the number of rows in a table
*/

/* usage:
		select * from _monitoring.fn_estimate_row_count('tablename');
	
*/

/* check if the _monitoring schema exists */
do $$
begin
	if not (select exists(select * from information_schema.schemata where schema_name = '_monitoring'))
	then
		create Schema _monitoring;
	end if;
end $$;

/* function takes table name as parameter to get row count estimate */
create or replace function _monitoring.fn_estimate_row_count(tablename text)
returns bigint as
$BODY$
declare estimated_row_count bigint;
begin

	select (case when reltuples > 0 then
			pg_relation_size(tablename)/(8192*relpages/reltuples)
			else 0
			end)::bigint into estimated_row_count 
	from pg_class
	where oid = tablename::regclass;
	return estimated_row_count;
	
end; $BODY$ language plpgsql;