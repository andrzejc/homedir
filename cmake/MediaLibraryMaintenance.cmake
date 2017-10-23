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
	set(ffmpeg_cmd "${ffmpeg_EXECUTABLE}" -i "${in}" -vn -acodec "${Audio_Codec}" -b:a "${Audio_Bitrate}" -f "${Audio_Format}" -n -nostats -nostdin "${tmp_out}")
	execute_process(COMMAND ${ffmpeg_cmd} RESULT_VARIABLE res OUTPUT_VARIABLE ffmpeg_log ERROR_VARIABLE ffmpeg_log)
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
elseif("${MEDIA_LIBRARY_MAINTENANCE_JOB}" STREQUAL "itunes_import")
	log_debug("importing '${file}' to iTunes Library")
	set(osascript_log)
	set(osascript_cmd "${osascript_EXECUTABLE}" -e "tell application \"iTunes\" to add POSIX file \"${file}\"")
	execute_process(COMMAND ${osascript_cmd} RESULT_VARIABLE res OUTPUT_VARIABLE osascript_log ERROR_VARIABLE osascript_log)
	strjoin(osascript_cmd " " ${osascript_cmd})
	log_debug("${osascript_cmd}: ${res}\n${osascript_log}\n")
	if(res)
		message(FATAL_ERROR "iTunes import failed: ${res} (see '${log}')")
	endif()
	return()
endif()

function(media_file_ext ext_var format codec)
	set("${ext_var}" .m4a PARENT_SCOPE)
endfunction()

find_package(ffmpeg REQUIRED)
find_package(osascript)
find_package(iTunes)

set(iTunes_Import "${iTunes_FOUND}" CACHE BOOL "Import recoded files to iTunes?")
set(Existing_Files Skip_Warn CACHE STRING "How to treat existing files (Overwrite_Backup, Overwrite_Delete, Skip_Silent, Skip_Warn, Error)")
set(Log_Files_Cleanup Success CACHE STRING "Whether to clean log files after recode (Success, Always, Never)")
set(Original_Cleanup Never CACHE STRING "Whether to clean original input files after recode (Success, Always, Never)")
set(Audio_Format mp4 CACHE STRING "Format (container) to encode to")
set(Audio_Codec aac CACHE STRING "Audio codec to encode to")
set(Audio_Bitrate 192k CACHE STRING "Audio bitrate to encode to")
set(Recode_Pattern "*.flac;*.ape" CACHE STRING "File patterns to recode (separate glob patterns with semicolons)")

function(export_vars res_var)
	set(res)
	foreach(var ${ARGN})
		list(APPEND res "-D${var}:STRING=${${var}}")
	endforeach()
	set("${res_var}" ${res} PARENT_SCOPE)
endfunction()

function(create_job target job vars depends comment)
	add_custom_target("${target}"
		COMMAND "${CMAKE_COMMAND}"
			"-DMEDIA_LIBRARY_MAINTENANCE_JOB:STRING=${job}"
			${vars}
			-P "$ENV{HOMEDIR}/cmake/MediaLibraryMaintenance.cmake"
		DEPENDS ${depends}
		COMMENT "${comment}"
		VERBATIM)
endfunction()

function(recode_impl_ffmpeg target in out log)
	export_vars(vars in out log Existing_Files Original_Cleanup Audio_Format Audio_Codec Audio_Bitrate ffmpeg_EXECUTABLE)
	string(REGEX MATCH "\\.[^.]*\$" out_ext "${out}")
	file(RELATIVE_PATH in_rel "${CMAKE_SOURCE_DIR}" "${in}")
	create_job("${target}" ffmpeg "${vars}" "${in}" "Recoding '${in_rel}' -> '${out_ext}' using ffmpeg")
endfunction()

function(itunes_import target file log)
	export_vars(vars file log osascript_EXECUTABLE)
	file(RELATIVE_PATH file_rel "${CMAKE_SOURCE_DIR}" "${file}")
	create_job("${target}" itunes_import "${vars}" "" "Importing '${file_rel}' to iTunes Library")
endfunction()

function(recode_pipeline in)
	string(REGEX MATCH "\\.[^.]*\$" in_ext "${in}")
	string(LENGTH "${in_ext}" ext_len)
	string(LENGTH "${in}" in_len)
	math(EXPR in_len "${in_len} - ${ext_len}")

	string(SUBSTRING "${in}" 0 ${in_len} base)
	get_filename_component(base_abs "${base}" ABSOLUTE)
	file(RELATIVE_PATH base_rel "${CMAKE_SOURCE_DIR}" "${base_abs}")

	media_file_ext(out_ext "${Audio_Format}" "${Audio_Codec}")

	set(in  "${base_abs}${in_ext}")
	set(out "${base_abs}${out_ext}")
	set(log "${CMAKE_BINARY_DIR}/${base_rel}.log")
	set(target "${base_rel}${out_ext}")
	string(MAKE_C_IDENTIFIER "${target}" target_suffix)

	set(pipeline_target "pipeline_${target_suffix}")
	add_custom_target("${pipeline_target}" ALL
		COMMENT "Executing recoding pipeline for target '${target}'"
		SOURCES "${in}")

	set(recode_target "recode_${target_suffix}")
	recode_impl_ffmpeg("${recode_target}" "${in}" "${out}" "${log}")
	add_dependencies("${pipeline_target}" "${recode_target}")

	if(iTunes_Import)
		set(itunes_import_target "itunes_import_${target_suffix}")
		itunes_import("${itunes_import_target}" "${out}" "${log}")
		add_dependencies("${itunes_import_target}" "${recode_target}")
		add_dependencies("${pipeline_target}" "${itunes_import_target}")
	endif()
endfunction()

function(recode_all in)
	if(IS_DIRECTORY "${in}")
		file(GLOB_RECURSE files RELATIVE "${in}" ${Recode_Pattern})
		foreach(f IN LISTS files)
			recode_pipeline("${in}/${f}")
		endforeach(f IN LISTS files)
	else()
		recode_pipeline("${in}")
	endif()
endfunction()