/*
* @author: Justin Leto
* @date: June 16, 2013
*
* description:
* 	Returns server uptime as interval datatype.
*/

/* usage:

	do $$
	begin
		raise notice '%', _monitoring.fn_server_uptime();
	end $$;
	
*/

/* Check for _monitoring schema. If it doesn't exist, create it. */
do $$
begin
	if not (SELECT exists(select schema_name FROM information_schema.schemata WHERE schema_name = '_monitoring'))
	then
		create Schema _monitoring;
	end if;
end $$;

create or replace function _monitoring.fn_server_uptime()
returns interval as
$BODY$
declare uptime interval;
begin
	select date_trunc('second', current_timestamp - pg_postmaster_start_time()) into uptime;
	return uptime;
end; $BODY$ language plpgsql;