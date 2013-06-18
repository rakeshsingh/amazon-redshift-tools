/*
* @author: Justin Leto
* @date: June 16, 2013
*
* description:
* 	Returns table(tablename, tablesize) showing size of tables in descending order.
*/

/* usage:
		select * from _monitoring.fn_size_of_tables();
	
*/

/* check if the _monitoring schema exists */
do $$
begin
	if not (select exists(select * from information_schema.schemata where schema_name = '_monitoring'))
	then
		create Schema _monitoring;
	end if;
end $$;

create or replace function _monitoring.fn_size_of_tables()
returns table (
	tablename text,
	tablesize bigint
) as
$BODY$
begin
	return query
	select table_name::text as tablename,
		   pg_relation_size(table_name) as tablesize
	from information_schema.tables
	where table_schema not in ('information_schema','pg_catalog')
	order by tablesize desc;
end; $BODY$ language plpgsql;