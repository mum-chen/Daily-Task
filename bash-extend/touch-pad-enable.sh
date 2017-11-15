toupad_info=$(xinput | grep TouchPad | awk '{print $6}')
toupad_id=${toupad_info/"id="/""}
if [ -z "${toupad_id}" ];then
	echo "Not found id=? in info(${toupad_info})"
	exit 1
fi

ARGS=$(getopt -o h -l help,enable,disable -- "$@")
if [ $? != 0 ]; then
	echo "Terminating..."
	exit 1
fi

TOUPAD_ON=
eval set -- "${ARGS}"

help()
{
	echo "$0 --enable | --disable"
}

while true
do
	case "$1" in
	--enable | --disable) TOUPAD_ON="$1"; shift 1 ;;
	-h | --help) help; exit 0 ;;
	--) break ;;
	*)
		echo "-h for help"
		exit 1 exit 1 ;;
	esac
done

main()
{
	if [ -z "${TOUPAD_ON}" ]; then
		echo "detect toupad_id: ${toupad_id}"
		exit 0
	fi

	xinput ${TOUPAD_ON} ${toupad_id}
	exit 0
}
main
