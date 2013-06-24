/*
* @author: Justin Leto
* @date: June 23, 2013
*
* function: _dba.fn_disconnect_nonsuperusers()
*
* description:
* 	DBA utility script to disconnect all non superusers from the database.
*
* usage:
*/
/*
	do $$
	begin
		perform _dba.fn_disconnect_nonsuperusers(false);
	end $$;
	
	--disconnecting users:
	do $$
	begin
		perform _dba.fn_disconnect_nonsuperusers(true);
	end $$;
*/

/* Check for _utility schema. If it doesn't exist, create it. */
do $$
begin
	if not (SELECT exists(select schema_name FROM information_schema.schemata WHERE schema_name = '_dba'))
	then
		create Schema _dba;
	end if;
end $$;

create or replace function _dba.fn_disconnect_nonsuperusers(disconnect_users boolean)
returns boolean as
$BODY$
declare rec record;
		result boolean;
begin
	--users will be disconnected
	if disconnect_users then
		--store the result of the query
		select count(pg_terminate_backend(procid)) into result
		from pg_stat_activity
		where usename not in
		(
			--exclude all superusers
			select usename
			from pg_user
			where usesuper
		);		
		return result;		
	else
		--list of non superusers will be reported, along with connection counts
		for rec in
			(
				select usename, count(*) as conn_count
				from pg_stat_activity
				where usename not in (
					--exclude all superusers
					select usename
					from pg_user
					where usesuper
				)
				group by usename
			)
		loop
			raise notice '%				% connections', rec.usename, rec.conn_count;     
		end loop;

		--report success
		return true;
		
	end if;


end;
$BODY$ language plpgsql;
