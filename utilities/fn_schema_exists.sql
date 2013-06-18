/*
* @author: Justin Leto
* @date: June 16, 2013
*
* description:
* 	Returns boolean indicating if the schema name exists.
*/


/* usage:

do $$
declare schemaname text = '_utility';
begin
	if _utility.fn_schema_exists(schemaname)
	then
		raise notice 'Schema % exists.', _utility.fn_schema_exists(schemaname);
	else
		raise notice 'Schema % does not exist.', _utility.fn_schema_exists(schemaname);
	end if;
end $$;

*/

/* Check for _utility schema. If it doesn't exist, create it. */
do $$
begin
	if not (SELECT exists(select schema_name FROM information_schema.schemata WHERE schema_name = '_utility'))
	then
		create Schema _utility;
	end if;
end $$;

/* function takes schema name as parameter to test for existance */
create or replace function _utility.fn_schema_exists(schemaname text)
returns boolean as
$BODY$
begin
	if not (SELECT exists(select schema_name FROM information_schema.schemata WHERE schema_name = schemaname))
	then
		/* Schema does not exist */
		return false;
	end if;

	/* Schema exist */
	return true;
end; $BODY$ language plpgsql;

