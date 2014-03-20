# expects database name as argument
# run
# sh ./slow_running_query.sh database_name &
# tail -f query_stats.log

while psql $1 -qt -c "select current_query(), now()-query_start as running_for from pg_stat_activity" >> query_stats.log ; do sleep 1; done
