trace_input() {
	# Usage: trace_input <pid>
	sudo strace -f -e 'trace=write,read' -e write=all -e read=all -p "$1" 2>&1 | grep -v EAGAIN
}
