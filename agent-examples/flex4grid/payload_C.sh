while true
do
	sleep $(echo $RANDOM % 20 + 60 | bc)
	timestamp=$(date --iso-8601="minutes")
	echo "{\"timestamp\" : \"$timestamp\",\"id\" : \"X1020102-12f\",\"errorCode\" : \"404\",\"errorMessage\" : \"device not found\"}"
done
