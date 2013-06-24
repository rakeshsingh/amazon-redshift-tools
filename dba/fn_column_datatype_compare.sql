/*
*
* @author: Justin Leto
* @date: June 24th, 2013
*
* function: _dba.fn_column_datatype_compare()
*
* description: Compares the data types of identically-named columns between multiple tables (and schemas)
* 			   to discover possible data type mismatches.
*
*
* usage:
*/

/*

select * from _dba.fn_column_datatype_compare();

*/

/* Check for _dba schema, if it doesn't exist create it. */
do $$
begin
	if not (SELECT exists(select schema_name FROM information_schema.schemata WHERE schema_name = '_dba'))
	then
		create Schema _dba;
	end if;
end $$;

create or replace function _dba.fn_column_datatype_compare()
returns table
(
	table_schema text,
	table_name text,
	column_name text,
	data_type text
)
as
$BODY$
begin
	return query
	select columns.table_schema::text,
		   columns.table_name::text,
		   columns.column_name::text,
		   columns.data_type
		    || coalesce(' ' || text(columns.character_maximum_length), '')
		    || coalesce(' ' || text(columns.numeric_precision), '')
		    || coalesce(' ' || text(columns.numeric_scale), '')
		   as data_type
	from information_schema.columns
	/* Only pull out records with column names that match the criteria of the sub query */
	where columns.column_name in
	(
		select derived.column_name
		from (
			select columns.column_name,
				   columns.data_type,
				   columns.character_maximum_length,
				   columns.numeric_precision,
				   columns.numeric_scale
			from information_schema.columns
			group by columns.column_name,
					 columns.data_type,
					 columns.character_maximum_length,
					 columns.numeric_precision,
					 columns.numeric_scale
			) derived
			group by derived.column_name
			/* Only include columns that appear more than once. */
			having count(*) > 1
			/* Exclude pg_catalog tables and columns */
			and columns.table_schema not in ('information_schema', 'pg_catalog')
			order by derived.column_name
	)
	order by columns.column_name, columns.table_schema, columns.table_name, columns.data_type;
	
end; $BODY$ language plpgsql;

comment on function _dba.fn_column_datatype_compare() IS 'Compares the data types of identically-named columns between multiple tables (and schemas) to discover potential data type mismatches that could compromise data integrity.';