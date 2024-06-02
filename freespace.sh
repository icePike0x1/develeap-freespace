#!/bin/bash

OPTSTRING=":rht:"
RECURSIVE=0
TIMEOUT=48
POS_ARGS=
COMPRESSION=( zip gz bzip gzip compress )

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
	zip "${file_dir}/fc-${file_name}.zip" "${file_dir}/${file_name}"
}

rename_file() {
	local mv_file="$1"
	local file_name="$(basename $mv_file)"
	local file_dir="$(dirname $mv_file)"
	local new_file_name="fc-${file_name}"
	
	echo "file to move: $mv_file"
	mv -v "${file_dir}/${file_name}" "${file_dir}/${new_file_name}"
	touch "${file_dir}/${new_file_name}"
}

check_file_or_dir() {
	if [[ -f "$1" ]]; then
		echo "file"
	fi
	
	if [[ -d "$1" ]]; then
		echo "dir"
	fi
}

iterate_files() {
	local cur_file
	local comp_metod
	
	for cur_file in $@; do
		if [[ -f "$cur_file" ]]; then
			comp_metod="$(file ${cur_file} | cut -d" " -f2)"
			if [[ ${COMPRESSION[@]} =~ ${comp_metod} ]]; then
				echo "compression method: $comp_metod"
				rename_file "$cur_file"
			else
				compress_file "$cur_file"
			fi
		elif [[ -d "$cur_file" ]]; then
			echo "$cur_file is a dir"
			for c_file in $(find "${cur_file}" -maxdepth 1 -type f); do
				echo "proccessing file: $c_file"
				comp_metod="$(file ${c_file} | cut -d" " -f2)"
				if [[ ${COMPRESSION[@]} =~ ${comp_metod} ]]; then
					echo "compression method: $comp_metod"
					rename_file "$c_file"
				else
					compress_file "$c_file"
				fi
			done
		fi
	done
}


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

iterate_files "$@"



exit 0