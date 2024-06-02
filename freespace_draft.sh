#!/bin/bash

help_func() {
	cat <<-EOF
	this utility is used to compress log files, prepending 'fc' prefix. example: fc-<filename>
	regular files passed as arguments are compressed and the original file is then deleted.
	compressed files passed as arguments are remaned to fc-<filename>.
	
	OPTIONS:
	-r	recursive mode, used with directories
	-t	set your own timeout time.
	-h	invoke this help menu
EOF
}

compress_file() {
	local file="$1"
	local file_dir="$(dirname $file)"
	local file_name="$(basename $file)"
	zip "fc-${file_name}.zip" ${file_name}
}

rename_file() {
	local mv_file="$1"
	local new_file_name="fc-${mv_file}"
	echo "file to move: $mv_file"
	mv -v "${mv_file}" "${new_file_name}"
	touch "${new_file_name}"
}

OPTSTRING=":rht:"
RECURSIVE=0
TIMEOUT=48
POS_ARGS=
COMPRESSION=( zip gz bzip gzip compress )

while getopts ${OPTSTRING} opt; do
	case ${opt} in
		r)
			RECURSIVE=1;
			;;
		t)	if [[ "${OPTARG}" =~ ^([0-9]+)$ ]]; then
				TIMEOUT=${OPTARG};
			else
				echo "timeout (using the -t option) must be an integer value" >&2
				exit 1
			fi
			;;
		h) help_func
			exit 0
			;;
			
		:)	
			echo "option passed without argument" >&2
			exit 1
			;;
		*) echo "unknown option passed ${OPTARG}" >&2
			exit 1
			;;		
	esac	
done

shift $((OPTIND -1))

echo "timeout: ${TIMEOUT}"
echo "recursive: ${RECURSIVE}"
echo "args: $@"


for cur_file in $@; do 
	comp_metod="$(file ${cur_file} | cut -d" " -f2)"
	if [[ ${COMPRESSION[@]} =~ ${comp_metod} ]]; then
		echo "present, compression method: $comp_metod"
		rename_file "$cur_file"
	else
		compress_file "$cur_file"
	fi
done

# for cur_file in $@; do
	# if [[ $(file $cur_file | cut -d" " -f2)
# done



exit 0