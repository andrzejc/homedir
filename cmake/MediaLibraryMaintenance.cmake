# FILE GLOB_RECURSE calls should not follow symlinks by default
cmake_policy(SET CMP0009 NEW)

# write suffix of filename pth into variable named res
function(path_suffix pth res)
	string(RANDOM LENGTH 16 suffix)
	set("${res}" "${pth}.${suffix}" PARENT_SCOPE)
endfunction()

function(path_suffix_new pth res)
	path_suffix("${pth}" res_loc)
	while(EXISTS "${res_loc}")
		path_suffix("${pth}" res_loc)
	endwhile()
	set("${res}" "${res_loc}" PARENT_SCOPE)
endfunction()

function(log_or_fail level message)
	string(TIMESTAMP ts "%Y%m%dT%H%M%S")
	file(APPEND "${log}" "${ts} ${message}\n")
	if(NOT ("${level}" STREQUAL DEBUG))
		message("${level}" "${message}")
	endif()
endfunction()

macro(log_info message)
	log_or_fail(STATUS "${message}")
endmacro()

macro(log_warn message)
	# this is not a developer warning - avoid stacktrace & debugging info
	log_or_fail("" "${message}")
endmacro()

macro(log_fail message)
	log_or_fail(FATAL_ERROR "${message}")
endmacro()

macro(log_debug message)
	log_or_fail(DEBUG "${message}")
endmacro()

macro(norm_val var)
	string(TOLOWER "${${var}}" "${var}")
	string(REGEX REPLACE "[-_ \t\r\n]" "" "${var}" "${${var}}")
endmacro(norm_val var)

function(strjoin var glue)
	set(res)
	set(_glue "")
	foreach(arg ${ARGN})
		set(res "${res}${_glue}${arg}")
		set(_glue "${glue}")
	endforeach()
	set("${var}" "${res}" PARENT_SCOPE)
endfunction()

function(stamp_file stamp)
	string(TIMESTAMP time UTC)
	file(WRITE "${stamp}" "${time}")
endfunction(stamp_file)

function(force_reconfigure)
	# touch CMake cache to force reconfigure
	# CMAKE_CACHE_FILE is set by add_media_library_maintenance_targets()
	file(READ "${CMAKE_CACHE_FILE}" code)
	string(RANDOM LENGTH 8 token)
	string(REGEX REPLACE "_MEDIA_LIBRARY_MAINTENANCE_TOKEN:INTERNAL=T........\n"
		"_MEDIA_LIBRARY_MAINTENANCE_TOKEN:INTERNAL=T${token}\n" code "${code}")
	file(WRITE "${CMAKE_CACHE_FILE}" "${code}")
endfunction(force_reconfigure)

if(MEDIA_LIBRARY_MAINTENANCE_JOB STREQUAL ffmpeg)
	# script mode interface
	norm_val(Existing_Files)
	norm_val(Original_Cleanup)
	set(prev_bak)
	if(EXISTS "${out}")
		path_suffix_new("${out}" prev_bak)
		if(Existing_Files STREQUAL overwritebackup)
			log_info("file '${out}' already exists, backing up to '${prev_bak}' (Existing_Files==Overwrite_Backup)")
		elseif(Existing_Files STREQUAL overwritedelete)
			log_info("file '${out}' already exists, will be deleted after recoding (Existing_Files==Overwrite_Delete)")
		elseif(Existing_Files STREQUAL skipsilent)
			return()
		elseif(Existing_Files STREQUAL skipwarn)
			log_warn("file '${out}' already exists, skipping (Existing_Files==Skip_Warn)")
			return()
		elseif(Existing_Files STREQUAL error)
			log_fail("file '${out}' already exists, failing (Existing_Files==Error)")
		else()
			log_fail("Existing_Files value is invalid, can't continue")
		endif()
	endif()
	path_suffix_new("${out}" tmp_out)
	log_debug("encoding '${in}' to '${tmp_out}' using ffmpeg")

	set(ffmpeg_log)
	set(ffmpeg_cmd "${ffmpeg_EXECUTABLE}" -i "${in}" -vn -c:a "${Audio_Codec}" -b:a "${Audio_Bitrate}" -f "${Audio_Format}" -n -nostats -nostdin "${tmp_out}")
	execute_process(COMMAND ${ffmpeg_cmd}
		RESULT_VARIABLE res
		OUTPUT_VARIABLE ffmpeg_log
		ERROR_VARIABLE ffmpeg_log)
	strjoin(ffmpeg_cmd " " ${ffmpeg_cmd})
	log_debug("${ffmpeg_cmd}: ${res}\n${ffmpeg_log}\n")

	if((Original_Cleanup STREQUAL always) OR ((NOT res) AND (Original_Cleanup STREQUAL success)))
		log_debug("deleting original file '${in}' due to policy")
		execute_process(COMMAND "${CMAKE_COMMAND}" -E remove "${in}")
	endif()

	if(res)
		if(EXISTS "${tmp_out}")
			# delete incomplete output
			# TODO add policy regarding this
			log_debug("deleting temporary '${tmp_out}'")
			execute_process(COMMAND "${CMAKE_COMMAND}" -E remove "${tmp_out}")
		endif()
		# no point logging obvious to the logfile
		message(FATAL_ERROR "ffmpeg failed: ${res} (see '${log}')")
	endif()

	# create backup of existing file, if needed
	if(prev_bak)
		execute_process(COMMAND "${CMAKE_COMMAND}" -E rename "${out}" "${prev_bak}" RESULT_VARIABLE res)
		if(res)
			log_fail("unable to backup existing file '${out} to '${prev_bak}' (${res})")
		endif()
	endif()

	# move recoding output to the final place
	execute_process(COMMAND "${CMAKE_COMMAND}" -E rename "${tmp_out}" "${out}" RESULT_VARIABLE res)
	if(res)
		# delete incomplete output
		log_debug("failed to rename temporary '${tmp_out}' to '${out}' (${res}), deleting temporary")
		execute_process(COMMAND "${CMAKE_COMMAND}" -E remove "${tmp_out}")
		# restore backed up previous version
		if((EXISTS "${prev_bak}") AND (NOT (EXISTS "${out}")))
			log_debug("restoring backup '${prev_bak}' as '${out}'")
			execute_process(COMMAND "${CMAKE_COMMAND}" -E rename "${prev_bak}" "${out}")
		endif()
		message(FATAL_ERROR "unable to rename (already deleted) temporary '${tmp_out}' to '${out}' (${res})")
	endif()

	# delete old backup on success if requested
	if(prev_bak AND (Existing_Files STREQUAL overwritedelete))
		log_debug("deleting backup '${prev_bak}' due to policy")
		execute_process(COMMAND "${CMAKE_COMMAND}" -E remove "${prev_bak}")
	endif()
	return()
elseif("${MEDIA_LIBRARY_MAINTENANCE_JOB}" STREQUAL "iTunes_import")
	log_debug("Importing '${file}' to iTunes Library")
	string(REPLACE "\"" "\\\"" esc_file "${file}")
	set(osascript_log)
	set(osascript_cmd "${osascript_EXECUTABLE}" -e "with timeout 240 seconds" -e "tell application \"iTunes\" to add POSIX file \"${esc_file}\"" -e "end timeout")
	execute_process(COMMAND ${osascript_cmd}
		RESULT_VARIABLE res
		OUTPUT_VARIABLE osascript_log
		ERROR_VARIABLE osascript_log)
	strjoin(osascript_cmd " " ${osascript_cmd})
	log_debug("${osascript_cmd}: ${res}\n${osascript_log}\n")
	if(res)
		message(FATAL_ERROR "iTunes import failed: ${res} (see '${log}')")
	else()
		log_debug("stamping file '${stamp}'")
		stamp_file("${stamp}")
	endif()
	return()
elseif("${MEDIA_LIBRARY_MAINTENANCE_JOB}" STREQUAL "glob_dir")
	# FILE GLOB_RECURSE calls should not follow symlinks by default
	cmake_policy(SET CMP0009 NEW)
	log_debug("Globbing '${CMAKE_SOURCE_DIR}' for pattern '${pattern}'")
	file(GLOB_RECURSE files RELATIVE "${CMAKE_SOURCE_DIR}" ${pattern})
	string(RANDOM LENGTH 16 tmp_suff)
	set(out_tmp "${out}.${tmp_suff}")
	string(REPLACE ";" "\n" files "${files}")
	file(WRITE "${out_tmp}" "${files}")
	execute_process(COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${out_tmp}" "${out}")
	file(REMOVE "${out_tmp}")
	return()
elseif("${MEDIA_LIBRARY_MAINTENANCE_JOB}" STREQUAL "create_stamp")
	log_debug("Stamping file '${stamp}'.")
	stamp_file("${stamp}")
	return()
elseif("${MEDIA_LIBRARY_MAINTENANCE_JOB}" STREQUAL "check_reconfigure")
	if("${index}" IS_NEWER_THAN "${stamp}")
		log_debug("Stamp '${stamp}' is obsolete, forcing reconfigure on next build.")
		force_reconfigure()
	endif()
	return()
elseif("${MEDIA_LIBRARY_MAINTENANCE_JOB}" STREQUAL "force_reconfigure")
	force_reconfigure()
	return()
endif()

function(media_file_ext ext_var format codec)
	# TODO add support for other file/container formats
	set("${ext_var}" .m4a PARENT_SCOPE)
endfunction(media_file_ext)

function(export_vars res_var)
	set(res)
	foreach(var ${ARGN})
		string(REPLACE ";" "$<SEMICOLON>" val "${${var}}")
		list(APPEND res "-D${var}=${val}")
	endforeach()
	set("${res_var}" ${res} PARENT_SCOPE)
endfunction(export_vars)

set(MEDIA_LIBRARY_MAINTENANCE_MODULE_PATH "${CMAKE_CURRENT_LIST_FILE}")

function(make_target_name target_var prefix suffix)
	set(token)
	string(MAKE_C_IDENTIFIER "${prefix}" prefix)
	string(MAKE_C_IDENTIFIER "${suffix}" suffix)
	string(REGEX REPLACE "_+" "_" suffix "${suffix}")
	string(REGEX REPLACE "_\$" "" suffix "${suffix}")
	string(LENGTH "${prefix}" pre_len)
	string(LENGTH "${suffix}" suf_len)
	math(EXPR tot_len "${pre_len} + ${suf_len}")
	set(LIMIT 250)
	if(tot_len GREATER LIMIT)
		math(EXPR suf_pos "${tot_len} + 16 - ${LIMIT}")
		log_debug("Shortening target suffix '${suffix}' by ${suf_pos} chars")
		string(RANDOM LENGTH 16 token)
		string(SUBSTRING "${suffix}" ${suf_pos} -1 suffix)
	endif()
	set("${target_var}" "${prefix}${token}${suffix}" PARENT_SCOPE)
endfunction(make_target_name)

function(job_params res_var job dir vars depends comment)
	set("${res_var}"
			COMMAND "${CMAKE_COMMAND}"
				"-DMEDIA_LIBRARY_MAINTENANCE_JOB=${job}"
				${vars}
				-P "${MEDIA_LIBRARY_MAINTENANCE_MODULE_PATH}"
			DEPENDS "${depends}"
			COMMENT "${comment}"
			WORKING_DIRECTORY "${dir}"
			VERBATIM
		PARENT_SCOPE)
endfunction(job_params)

function(create_job_target target job dir vars depends comment)
	job_params(params "${job}" "${dir}" "${vars}" "${depends}" "${comment}")
	add_custom_target("${target}" ${params})
endfunction(create_job_target)

function(create_job_output output job dir vars depends comment)
	job_params(params "${job}" "${dir}" "${vars}" "${depends}" "${comment}")
	add_custom_command(OUTPUT "${output}" ${params})
endfunction(create_job_output)

function(add_recode_ffmpeg in out)
	export_vars(vars in out log Existing_Files Original_Cleanup Audio_Format Audio_Codec Audio_Bitrate ffmpeg_EXECUTABLE)
	string(REGEX MATCH "\\.[^.]*\$" out_ext "${out}")
	file(RELATIVE_PATH in_rel "${CMAKE_SOURCE_DIR}" "${in}")
	create_job_output("${out}" ffmpeg "" "${vars}" "${in}"
		"Recoding '${in_rel}' -> '${out_ext}' using ffmpeg")
endfunction(add_recode_ffmpeg)

function(split_base_ext base_var ext_var in)
	string(REGEX MATCH "\\.[^.]*\$" in_ext "${in}")
	string(LENGTH "${in_ext}" ext_len)
	string(LENGTH "${in}" in_len)
	math(EXPR in_len "${in_len} - ${ext_len}")

	string(SUBSTRING "${in}" 0 ${in_len} base)
	set(${base_var} "${base}" PARENT_SCOPE)
	set(${ext_var} "${in_ext}" PARENT_SCOPE)
endfunction(split_base_ext)

function(add_glob_job out dir pattern)
	export_vars(vars pattern out log)
	create_job_output("${out}" glob_dir "${dir}" "${vars}" ""
		"Indexing files in '${dir}'")
endfunction(add_glob_job)

function(read_lines res_var file)
		file(READ "${file}" lines)
		# string(REPLACE ";" "\\;" lines "${lines}")
		string(REPLACE "\n" ";" lines "${lines}")
		# remove trailing empty line
		set("${res_var}" "${lines}" PARENT_SCOPE)
endfunction(read_lines)

function(add_recode_file out_var in)
	split_base_ext(base in_ext "${in}")
	get_filename_component(base_abs "${base}" ABSOLUTE)
	file(RELATIVE_PATH base_rel "${CMAKE_SOURCE_DIR}" "${base_abs}")
	media_file_ext(out_ext "${Audio_Format}" "${Audio_Codec}")
	set(in  "${base_abs}${in_ext}")
	set(out "${base_abs}${out_ext}")
	add_recode_ffmpeg("${in}" "${out}")
	set("${out_var}" "${out}" PARENT_SCOPE)
endfunction(add_recode_file)

function(add_create_stamp stamp depends)
	export_vars(vars stamp log)
	create_job_output("${stamp}" create_stamp "" "${vars}" "${depends}"
		"Stamping output '${stamp}'")
endfunction(add_create_stamp)

function(add_check_reconfigure target stamp index)
	export_vars(vars stamp index CMAKE_CACHE_FILE log)
	create_job_target("${target}" check_reconfigure "" "${vars}" "${stamp};${index}"
		"Checking if index '${index}' was updated...")
endfunction(add_check_reconfigure)

function(add_force_reconfigure target before after)
	add_custom_target("${target}"
		COMMAND "${CMAKE_COMMAND}"
			"-DMEDIA_LIBRARY_MAINTENANCE_JOB=force_reconfigure"
			"-DCMAKE_CACHE_FILE=${CMAKE_CACHE_FILE}"
			-P "${MEDIA_LIBRARY_MAINTENANCE_MODULE_PATH}"
		COMMENT "Forcing reconfigure."
		VERBATIM)
	add_dependencies("${before}" "${target}")
	add_dependencies("${target}" "${after}")
endfunction(add_force_reconfigure)

set(RECODE_INDEX "${CMAKE_BINARY_DIR}/recode.index")
set(RECODE_STAMP "${CMAKE_BINARY_DIR}/recode.stamp")

function(add_recode_target)
	set(iTunes_Import "${iTunes_FOUND}" CACHE BOOL "recode: Import recoded files to iTunes?")
	set(Existing_Files Skip_Warn CACHE STRING "recode: How to treat existing files (Overwrite_Backup, Overwrite_Delete, Skip_Silent, Skip_Warn, Error)")
	set(Original_Cleanup Success CACHE STRING "recode: Whether to clean original input files after recode (Success, Always, Never)")
	set(Audio_Format mp4 CACHE STRING "recode: Format (container) to encode to")
	set(Audio_Codec libfdk_aac CACHE STRING "recode: Audio codec to encode to")
	set(Audio_Bitrate 256k CACHE STRING "recode: Audio bitrate to encode to")
	set(Recode_Pattern "*.flac;*.ape;*.ogg;*.oga;*.alac" CACHE STRING "recode: File patterns to include (separate glob patterns with semicolons)")
	set(log "${CMAKE_BINARY_DIR}/recode.log")

	if(NOT EXISTS "${RECODE_INDEX}")
		add_glob_job("${RECODE_INDEX}" "${CMAKE_SOURCE_DIR}" "${Recode_Pattern}")
		add_custom_target(recode_index
			DEPENDS "${RECODE_INDEX}"
			COMMENT "Indexing..."
			VERBATIM)
		add_custom_target(recode
			COMMENT "Indexing complete."
			VERBATIM)
		add_force_reconfigure(recode_force_reconfigure recode recode_index)
		add_dependencies(recode recode_index)
		log_info("recode: available, created indexing target")
	else()
		read_lines(files "${RECODE_INDEX}")
		set(out_files)
		foreach(f IN LISTS files)
			add_recode_file(out "${CMAKE_SOURCE_DIR}/${f}")
			list(APPEND out_files "${out}")
		endforeach(f)
		add_custom_target(recode_files
			DEPENDS "${out_files}"
			COMMENT "Recoding..."
			VERBATIM)
		add_create_stamp("${RECODE_STAMP}" "${RECODE_INDEX};${out_files}")
		add_custom_target(recode_stamp
			DEPENDS "${RECODE_STAMP}"
			COMMENT "Stamping..."
			VERBATIM)
		add_dependencies(recode_stamp recode_files)
		add_custom_target(recode
			COMMAND "${CMAKE_COMMAND}" -E remove -f "${RECODE_INDEX}"
			COMMENT "Recoding complete, removing obsolete index."
			VERBATIM)
		add_force_reconfigure(recode_force_reconfigure recode recode_stamp)
		add_dependencies(recode recode_stamp)
		log_info("recode: available, created converters from index")
	endif()
endfunction(add_recode_target)

set(IMPORT_INDEX "${CMAKE_BINARY_DIR}/import.index")
set(IMPORT_STAMP "${CMAKE_BINARY_DIR}/import.stamp")

function(add_index_target)
	set(Import_Pattern "*.mp3;*.m4a" CACHE STRING "index: File patterns to include (separate glob patterns with semicolons)")
	set(log "${CMAKE_BINARY_DIR}/index.log")
	log_info("index: available")
	add_glob_job("${IMPORT_INDEX}" "${CMAKE_SOURCE_DIR}" "${Import_Pattern}")
	add_custom_target(index
		DEPENDS "${IMPORT_INDEX}"
		COMMENT "Indexing files to import in '${CMAKE_SOURCE_DIR}'...")
endfunction(add_index_target)

function(add_iTunes_import stamp file)
	export_vars(vars stamp file log osascript_EXECUTABLE)
	file(RELATIVE_PATH file_rel "${CMAKE_SOURCE_DIR}" "${file}")
	create_job_output("${stamp}" iTunes_import "" "${vars}" "${file}"
		"Importing '${file_rel}' to iTunes library")
endfunction(add_iTunes_import)

function(iTunes_import_file stamp_var in)
	split_base_ext(base in_ext "${in}")
	get_filename_component(base_abs "${base}" ABSOLUTE)
	file(RELATIVE_PATH base_rel "${CMAKE_SOURCE_DIR}" "${base_abs}")
	set(in    "${base_abs}${in_ext}")
	set(stamp "${CMAKE_BINARY_DIR}/${base_rel}.stamp")
	# cmake output files can't contain # character
	string(REPLACE "#" "⌗" stamp "${stamp}")
	add_iTunes_import("${stamp}" "${in}")
	set("${stamp_var}" "${stamp}" PARENT_SCOPE)
endfunction(iTunes_import_file)

function(add_iTunes_import_target)
	set(Ignore_Pattern "^(.?WRZUTNIA|#Recycle)/" CACHE STRING "iTunes import: regex pattern to ignore specific files")
	set(log "${CMAKE_BINARY_DIR}/iTunes_import.log")

	if(NOT EXISTS "${IMPORT_INDEX}")
		add_custom_target(iTunes_import
			DEPENDS "${IMPORT_INDEX}"
			COMMENT "Indexing complete."
			VERBATIM)
		add_dependencies(iTunes_import index)
		add_force_reconfigure(iTunes_import_force_reconfigure iTunes_import index)
		log_info("iTunes_import: available, created indexing target")
	else()
		if("${IMPORT_INDEX}" IS_NEWER_THAN "${IMPORT_STAMP}")
			read_lines(files "${IMPORT_INDEX}")
			set(stamps)
			foreach(f IN LISTS files)
				if(f MATCHES "${Ignore_Pattern}")
					log_debug("Skipping file matching Ignore_Pattern: '${f}'")
					continue()
				endif()
				iTunes_import_file(stamp "${CMAKE_SOURCE_DIR}/${f}")
				list(APPEND stamps "${stamp}")
			endforeach(f)
			add_custom_target(iTunes_stamp_files DEPENDS "${stamp}" COMMENT "Importing...")
			add_create_stamp("${IMPORT_STAMP}" "${IMPORT_INDEX};${stamps}")
			add_custom_target(iTunes_stamp DEPENDS "${IMPORT_STAMP}" COMMENT "Stamping...")
			add_dependencies(iTunes_stamp iTunes_stamp_files)
			log_info("iTunes_import: available, created importers from index")
		else()
			log_info("iTunes_import: available, created index checker")
		endif()
		add_check_reconfigure(iTunes_check_index_updated "${IMPORT_STAMP}" "${IMPORT_INDEX}")
		if(TARGET iTunes_stamp)
			add_dependencies(iTunes_check_index_updated iTunes_stamp)
		endif()
		add_custom_target(iTunes_import)
		add_dependencies(iTunes_import iTunes_check_index_updated)
	endif()
endfunction(add_iTunes_import_target)

function(add_media_library_maintenance_targets)
	find_package(ffmpeg)
	find_package(osascript)
	find_package(iTunes)

	set(CMAKE_CACHE_FILE "${CMAKE_BINARY_DIR}/CMakeCache.txt")
	set(CMAKE_CACHE_FILE "${CMAKE_CACHE_FILE}" PARENT_SCOPE)
	set(_MEDIA_LIBRARY_MAINTENANCE_TOKEN "T00000000" CACHE INTERNAL "")

	set(Log_Files_Cleanup Never CACHE STRING "Whether to clean log files (Success, Always, Never)")

	if(ffmpeg_FOUND)
		add_recode_target()
	endif(ffmpeg_FOUND)

	add_index_target()

	if(iTunes_FOUND AND osascript_FOUND)
		add_iTunes_import_target()
	endif()
endfunction(add_media_library_maintenance_targets)
