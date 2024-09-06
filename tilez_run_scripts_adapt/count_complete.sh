


out_file="./counts_112916.txt"
## touch the file to create it
#cat > $out_file << fin
#fin
db_name="tilezilla_cp_112516.db"
for(( v=0; v<21; v++ )); do
	for (( h=0; h<30; h++ )); do
		
		test_val=`sqlite3 $db_name "select count(p.timeseries_id) from product p, tile t where t.vertical=$v and t.horizontal=$h and p.tile_id=t.id;"`
		if [ $test_val -gt "0" ]; then
			tot_ingest=`sqlite3 $db_name "select count(p.timeseries_id), t.vertical, t.horizontal from product p, tile t where p.tile_id=t.id and t.vertical=$v and t.horizontal=$h;"`
			echo $tot_ingest
			echo $tot_ingest >> $out_file
		fi
	done
done

