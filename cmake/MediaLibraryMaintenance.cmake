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
	log_debug("importing '${file}' to iTunes Library")
	string(REPLACE "\"" "\\\"" esc_file "${file}")
	set(osascript_log)
	set(osascript_cmd "${osascript_EXECUTABLE}" -e "tell application \"iTunes\" to add POSIX file \"${esc_file}\"")
	execute_process(COMMAND ${osascript_cmd} 
		RESULT_VARIABLE res 
		OUTPUT_VARIABLE osascript_log 
		ERROR_VARIABLE osascript_log)
	strjoin(osascript_cmd " " ${osascript_cmd})
	log_debug("${osascript_cmd}: ${res}\n${osascript_log}\n")
	if(res)
		message(FATAL_ERROR "iTunes import failed: ${res} (see '${log}')")
	endif()
	return()
elseif("${MEDIA_LIBRARY_MAINTENANCE_JOB}" STREQUAL "glob_dir")
	# FILE GLOB_RECURSE calls should not follow symlinks by default
	cmake_policy(SET CMP0009 NEW)
	log_debug("Globbing '${CMAKE_SOURCE_DIR}' for pattern '${pattern}'")
	file(GLOB_RECURSE files RELATIVE "${CMAKE_SOURCE_DIR}" ${pattern})
	if(DEFINED out AND EXISTS "${out}")
		file(REMOVE "${out}")
	endif()
	foreach(file IN LISTS files)
		if(DEFINED out)
			file(APPEND "${out}" "${file}\n")
		else()
			message(STATUS "${file}")
		endif()
	endforeach(file)
	return()
endif()

function(media_file_ext ext_var format codec)
	set("${ext_var}" .m4a PARENT_SCOPE)
endfunction()

function(export_vars res_var)
	set(res)
	foreach(var ${ARGN})
		string(REPLACE ";" "$<SEMICOLON>" val "${${var}}")
		list(APPEND res "-D${var}=${val}")
	endforeach()
	set("${res_var}" ${res} PARENT_SCOPE)
endfunction()

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

function(create_job target job dir vars depends comment)
	add_custom_target("${target}"
		COMMAND "${CMAKE_COMMAND}"
			"-DMEDIA_LIBRARY_MAINTENANCE_JOB=${job}"
			${vars}
			-P "${MEDIA_LIBRARY_MAINTENANCE_MODULE_PATH}"
		DEPENDS ${depends}
		COMMENT "${comment}"
		WORKING_DIRECTORY "${dir}"
		VERBATIM)
endfunction()

function(recode_impl_ffmpeg target in out log)
	export_vars(vars in out log Existing_Files Original_Cleanup Audio_Format Audio_Codec Audio_Bitrate ffmpeg_EXECUTABLE)
	string(REGEX MATCH "\\.[^.]*\$" out_ext "${out}")
	file(RELATIVE_PATH in_rel "${CMAKE_SOURCE_DIR}" "${in}")
	create_job("${target}" ffmpeg "" "${vars}" "${in}" "Recoding '${in_rel}' -> '${out_ext}' using ffmpeg")
endfunction()

function(iTunes_import target file log)
	export_vars(vars file log osascript_EXECUTABLE)
	file(RELATIVE_PATH file_rel "${CMAKE_SOURCE_DIR}" "${file}")
	create_job("${target}" iTunes_import "" "${vars}" "" "Importing '${file_rel}' to iTunes Library")
endfunction()

function(split_base_ext base_var ext_var in)
	string(REGEX MATCH "\\.[^.]*\$" in_ext "${in}")
	string(LENGTH "${in_ext}" ext_len)
	string(LENGTH "${in}" in_len)
	math(EXPR in_len "${in_len} - ${ext_len}")

	string(SUBSTRING "${in}" 0 ${in_len} base)
	set(${base_var} "${base}" PARENT_SCOPE)
	set(${ext_var} "${in_ext}" PARENT_SCOPE)
endfunction(split_base_ext)

function(recode_pipeline in)
	split_base_ext(base in_ext "${in}")
	get_filename_component(base_abs "${base}" ABSOLUTE)
	file(RELATIVE_PATH base_rel "${CMAKE_SOURCE_DIR}" "${base_abs}")

	media_file_ext(out_ext "${Audio_Format}" "${Audio_Codec}")

	set(in  "${base_abs}${in_ext}")
	set(out "${base_abs}${out_ext}")
	set(log "${CMAKE_BINARY_DIR}/${base_rel}.log")
	set(target "${base_rel}${out_ext}")
	make_target_name(pipeline_target pipeline_ "${target}")
	add_custom_target("${pipeline_target}"
		COMMENT "Executing recoding pipeline for target '${target}'")

	make_target_name(recode_target recode_ "${target}")
	recode_impl_ffmpeg("${recode_target}" "${in}" "${out}" "${log}")
	add_dependencies("${pipeline_target}" "${recode_target}")

	if(iTunes_Import)
		make_target_name(itunes_import_target iTunes_import_ "${target}")
		iTunes_import("${itunes_import_target}" "${out}" "${log}")
		add_dependencies("${itunes_import_target}" "${recode_target}")
		add_dependencies("${pipeline_target}" "${itunes_import_target}")
	endif()
	if(TARGET recode_all)
		add_dependencies(recode_all "${pipeline_target}")
	endif()
endfunction(recode_pipeline)

set(Log_Files_Cleanup Success CACHE STRING "Whether to clean log files after recode (Success, Always, Never)")

function(glob_dir result_var dir pattern log)
	execute_process(COMMAND "${CMAKE_COMMAND}"
			"-DMEDIA_LIBRARY_MAINTENANCE_JOB=glob_dir"
			"-Dpattern=${pattern}"
			"-Dlog=${log}"
			-P "${MEDIA_LIBRARY_MAINTENANCE_MODULE_PATH}"
		WORKING_DIRECTORY "${dir}"
		RESULT_VARIABLE res
		ERROR_VARIABLE err
		OUTPUT_VARIABLE paths
		ERROR_STRIP_TRAILING_WHITESPACE)
	if(res)
		log_warn("glob_dir('${dir}', '${pattern}'): ${res} (${err})")
	endif(res)
	string(REGEX REPLACE "^-- " "" paths "${paths}")
	string(REGEX REPLACE "\n-- " ";" paths "${paths}")
	string(REGEX REPLACE "\n\$" "" paths "${paths}")
	set("${result_var}" "${paths}" PARENT_SCOPE)
endfunction(glob_dir)

function(recode_all)
	find_package(ffmpeg REQUIRED)
	find_package(osascript)
	find_package(iTunes)

	set(iTunes_Import "${iTunes_FOUND}" CACHE BOOL "Import recoded files to iTunes?")
	set(Existing_Files Skip_Warn CACHE STRING "How to treat existing files (Overwrite_Backup, Overwrite_Delete, Skip_Silent, Skip_Warn, Error)")
	set(Original_Cleanup Never CACHE STRING "Whether to clean original input files after recode (Success, Always, Never)")
	set(Audio_Format mp4 CACHE STRING "Format (container) to encode to")
	set(Audio_Codec libfdk_aac CACHE STRING "Audio codec to encode to")
	set(Audio_Bitrate 192k CACHE STRING "Audio bitrate to encode to")
	set(Recode_Pattern "*.flac;*.ape;*.ogg;*.oga" CACHE STRING "File patterns to recode (separate glob patterns with semicolons)")
	set(log "${CMAKE_BINARY_DIR}/recode.log")

	add_custom_target(recode_all ALL)
	log_info("Indexing files to recode in '${CMAKE_SOURCE_DIR}'...")
	glob_dir(files "${CMAKE_SOURCE_DIR}" "${Recode_Pattern}" "${log}")
	log_info("Creating targets...")
	foreach(f IN LISTS files)
		recode_pipeline("${CMAKE_SOURCE_DIR}/${f}")
	endforeach(f)
endfunction()

function(iTunes_import_pipeline in)
	split_base_ext(base in_ext "${in}")
	get_filename_component(base_abs "${base}" ABSOLUTE)
	file(RELATIVE_PATH base_rel "${CMAKE_SOURCE_DIR}" "${base_abs}")
	set(in     "${base_abs}${in_ext}")
	set(log    "${CMAKE_BINARY_DIR}/${base_rel}.log")
	make_target_name(itunes_import_target iTunes_import_ "${base_rel}")
	iTunes_import("${itunes_import_target}" "${in}" "${log}")
	if(TARGET iTunes_import_all)
		add_dependencies(iTunes_import_all "${itunes_import_target}")
	endif()
endfunction(iTunes_import_pipeline)

function(index_all)
	set(Import_Pattern "*.mp3;*.m4a;*.alac" CACHE STRING "File patterns to import to index (separate glob patterns with semicolons)")
	set(pattern "${Import_Pattern}")
	set(out     "${CMAKE_BINARY_DIR}/index.txt")
	set(log     "${CMAKE_BINARY_DIR}/index.log")

	add_custom_target(index_all ALL)
	if(TARGET recode_all)
		# execute always after recoding
		add_dependencies(index_all recode_all)
	endif()

	export_vars(vars pattern out log)
	create_job(index_importable glob_dir "${CMAKE_SOURCE_DIR}" "${vars}" "" "Indexing importable files in '${CMAKE_SOURCE_DIR}'")
	add_dependencies(index_all index_importable)
endfunction(index_all)

function(iTunes_import_all)
	find_package(osascript REQUIRED)
	find_package(iTunes REQUIRED)

	set(Import_Pattern "*.mp3;*.m4a;*.alac" CACHE STRING "File patterns to import to iTunes (separate glob patterns with semicolons)")
	set(Ignore_Pattern "^!WRZUTNIA/" CACHE STRING "Regex pattern to ignore specific files")
	set(log "${CMAKE_BINARY_DIR}/iTunes_import.log")

	add_custom_target(iTunes_import_all ALL)
	if(TARGET recode_all)
		# execute always after recoding
		add_dependencies(iTunes_import_all recode_all)
	endif()
	if(TARGET index_all)
		add_dependencies(iTunes_import_all index_all)
	endif()

	if(EXISTS "${CMAKE_BINARY_DIR}/index.txt")
		log_info("Using existing index for '${CMAKE_SOURCE_DIR}'...")
		file(READ "${CMAKE_BINARY_DIR}/index.txt" files)
		string(REGEX REPLACE "\r?\n" ";" files "${files}")
		# remove trailing empty line
		string(REGEX REPLACE ";\$" "" files "${files}")
	else()
		log_info("Enumerating files to import in '${CMAKE_SOURCE_DIR}'...")
		glob_dir(files "${CMAKE_SOURCE_DIR}" "${Import_Pattern}" "${log}")
	endif()
	log_info("Creating import targets...")
	foreach(f IN LISTS files)
		if(f MATCHES "${Ignore_Pattern}")
			log_debug("Skipping file matching Ignore_Pattern: '${f}'")
			continue()
		endif()
		if(EXISTS "${CMAKE_SOURCE_DIR}/${f}")
			iTunes_import_pipeline("${CMAKE_SOURCE_DIR}/${f}")
		else()
			log_warn("Indexed file '${f}' is missing")
		endif()
	endforeach(f)
endfunction(iTunes_import_all)

function(eval code)
	set(eval_temp_file "${CMAKE_CURRENT_BINARY_DIR}/_eval_temp.cmake")
	file(WRITE "${eval_temp_file}" "${code}")
  	include("${eval_temp_file}")
endfunction(eval)	
