/*
* @author: Justin Leto
* @date: July 18, 2013
*
* description:
* 	Query monitoring functions
*/

/* usage:
		select * from _monitoring.fn_connected_clients();
		select * from _monitoring.fn_users_blocking_queries();
		select * from _monitoring.fn_waiting_queries();
*/

/* check if the _monitoring schema exists */
do $$
begin
	if not (select exists(select * from information_schema.schemata where schema_name = '_monitoring'))
	then
		create Schema _monitoring;
	end if;
end $$;

/* Function lists queries being blocked and which users are blocking them. */
create or replace function _monitoring.fn_users_blocking_queries()
returns table (
	waiting_query text,
	waiting_pid int,
	waiting_user name,
	locking_query text,
	locking_pid int,
	locking_user name,
	tablename text
) as $BODY$
begin
	return query
	select w.current_query as waiting_query,
		   w.procpid as waiting_pid,
		   w.usename as waiting_user,
		   l.current_query as locking_query,
		   l.procpid as locking_pid,
		   l.usename as locking_user,
		   t.schemaname || '.' || t.relname as tablename
	from pg_stat_activity w
	join pg_locks l1 on w.procpid = l1.pid and not l1.granted
	join pg_locks l2 on l1.relation = l2.relation and l2.granted
	join pg_stat_activity l on l2.pid = l.procpid
	join pg_stat_user_tables t on l1.relation = t.relid
	where w.waiting;
end; $BODY$ language plpgsql security definer;

comment on function _monitoring.fn_users_blocking_queries() is 'Lists queries being blocked and which users are blocking them.';

/* Function lists queries run by all users. */
create or replace function _monitoring.fn_active_queries()
returns table (
	db_name name,
	user_name name,
	current_query text
) as $BODY$
begin
	return query
	select datname as db_name,
		   usename as user_name,
		   current_query
	from pg_stat_activity
	where current_query != '<IDLE>';	
end; $BODY$ language plpgsql security definer;

/* Function to view connected clients */
create or replace function _monitoring.fn_connected_clients()
returns table (
	db_name name,
	user_name name,
	client_ip inet,
	client_port int
) as $BODY$
begin
	return query
	select act.datname,
		   act.usename,
		   act.client_addr,
		   act.client_port
	from pg_stat_activity act;
end; $BODY$ language plpgsql security definer;

comment on function _monitoring.fn_active_queries() is 'Lists queries run by all users.';

/* Function to show queries waiting on locks. */
create or replace function _monitoring.fn_waiting_queries()
returns table (
	db_name name,
	user_name name,
	current_query text
) as $BODY$
begin
	return query
	select act.datname as db_name,
		   act.usename as user_name,
		   act.current_query
	from pg_stat_activity act
	where waiting;
end; $BODY$ language plpgsql security definer;

comment on function _monitoring.fn_waiting_queries() is 'Show queries waiting on locks.';

