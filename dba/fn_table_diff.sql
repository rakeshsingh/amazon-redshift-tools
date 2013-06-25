/*
*
* @author: Justin Leto
* @date: June 25th, 2013
*
* function: _dba.fn_table_diff
*	(
*	table1_schemaname text,
*	table1_tablename text,
*	table2_schemaname text,
*	table2_tablename text
*	)
*
* description: function shows the difference in table definition of two tables
* 			   specified through four parameters
*
* parameters
* 	table1_schemaname: schema of the first table to compare.
*	table1_tablename: table name of the first table to compare.
*	table2_schemaname: schema of the second table to compare.
*	table2_tablename: table name of the second table to compare.
*
* usage:
*/

/*
select * from _dba.fn_table_diff
(
	'public'::text,
	'meetupusers'::text,
	'public'::text,
	'mailing_lists'::text
)
*/

/* Check for _dba schema, if it doesn't exist create it. */
do $$
begin
	if not (SELECT exists(select schema_name FROM information_schema.schemata WHERE schema_name = '_dba'))
	then
		create Schema _dba;
	end if;
end $$;

create or replace function _dba.fn_table_diff
(
	table1_schemaname text,
	table1_tablename text,
	table2_schemaname text,
	table2_tablename text
)
returns table (
	table1_column_name text,
	table1_data_type text,
	table2_column_name text,
	table2_data_type text
)
as $BODY$
begin

	return query
	select t1.column_name::text,
		   t1.data_type::text,
		   t2.column_name::text,
		   t2.data_type::text
	from (
		/* pull meta data for table 1 */
		select column_name,
			   data_type
		from information_schema.columns
		where table_schema = $1
			and table_name = $2
	) t1
	full outer join
	(
		/* pull meta data for table 2 */
		select column_name,
			   data_type
		from information_schema.columns
		where table_schema = $3
		and table_name = $4
	) t2
	/* match column names between the two tables */
	on (t1.column_name = t2.column_name)
	/* return columns where there is no match */
	where t1.column_name is null or t2.column_name is null;

end; $BODY$ language plpgsql;

comment on function _dba.fn_table_diff(text, text, text, text) is 'Compares columns and datatypes of two tables.'
			