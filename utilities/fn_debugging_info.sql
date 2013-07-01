/*
* @author: Justin Leto
* @date: June 15, 2013
*
* function: _utility.fn_debugging_info_on()
*
* description: Allows developers to turn logging on through a defined function
*              with execute permissions set accordingly rather than requiring
*              each user have superuser priviledges.
*
* usage:
*/
/*

do $$
begin
	perform _utility.fn_debugging_info_on();

end$$;

do $$
begin
	perform _utility.fn_debugging_info_off();
end$$;
	
*/

/* Check for _utility schema. If it doesn't exist, create it. */
do $$
begin
	if not (SELECT exists(select schema_name FROM information_schema.schemata WHERE schema_name = '_utility'))
	then
		create Schema _utility;
	end if;
end $$;

create or replace function _utility.fn_debugging_info_on()
returns void
as $BODY$
begin
	set client_min_messages to 'DEBUG1';
	set log_min_messages to 'DEBUG1';
	set log_error_verbosity to 'VERBOSE';
	set log_min_duration_statement to 0;
end; $BODY$ language plpgsql;

revoke all on function _utility.fn_debugging_info_on() from public;
/* Add execute permissions to users or roles. */

comment on function _utility.fn_debugging_info_on() IS 'Utility for developers to turn debugging and logging information on.';

/* Function to turn debugging info off */
create or replace function _utility.fn_debugging_info_off()
returns void
as $BODY$
begin
	set client_min_messages to DEFAULT;
	set log_min_messages to DEFAULT;
	set log_error_verbosity to DEFAULT;
	set log_min_duration_statement to DEFAULT;
end; $BODY$ language plpgsql;

revoke all on function _utility.fn_debugging_info_off() from public;
/* Add execute permissions to users or roles. */

comment on function _utility.fn_debugging_info_off() IS 'Utility for developers to turn debugging and logging information off.';