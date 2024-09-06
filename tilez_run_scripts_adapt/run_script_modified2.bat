
# ohup pupsh "hostname ~ 'adaptlight[0-16]'" "bash $NOBACKUP/tilez2/run_tiles.sh &> $NOBACKUP/tilez2/logs/run_tiles_%h.log" &
nohup pupsh "hostname ~ 'adaptlight109'" "bash $NOBACKUP/tilez2/run_tiles.sh &> $NOBACKUP/tilez2/logs/run_tiles_%h.log" &


