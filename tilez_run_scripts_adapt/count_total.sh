out_file="./counts_tm5_010416.txt"
## touch the file to create it
#cat > $out_file << fin
#fin


db_name="tilezilla.db"

tot_ingest=`sqlite3 -init  <(echo .timeout 2000) $db_name "select t.horizontal, t.vertical, count(p.timeseries_id), p.instrument from tile t, product p where t.id=p.tile_id and p.instrument='TM' group by t.id order by t.horizontal, t.vertical;"`

echo $tot_ingest >> $out_file
