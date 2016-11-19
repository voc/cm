kill_children() {
	pkill -P $$
}

trap kill_children EXIT
