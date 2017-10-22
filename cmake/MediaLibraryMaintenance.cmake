function(path_suffix pth res)
	string(RANDOM LENGTH 16 suffix)
	set(${res} "${pth}.${suffix}" PARENT_SCOPE)
endfunction()

function(path_suffix_new pth res)
	path_suffix("${pth}" res_loc)
	while(EXISTS "${res_loc}")
		path_suffix("${pth}" res_loc)
	endwhile()
	set(${res} "${res_loc}" PARENT_SCOPE)
endfunction()

if(DEFINED MEDIA_LIBRARY_MAINTENANCE_RECODE_FFMPEG)
	# script mode interface
	string(TOLOWER ${Existing_Files} Existing_Files)
	if((EXISTS "${out}") AND (NOT (${Existing_Files} STREQUAL overwrite)))
		if(${Existing_Files} STREQUAL skip)
			return()
		endif()
		if(${Existing_Files} STREQUAL error)
			message(FATAL_ERROR "file '${out}' already exists")
		else()
			message(WARNING "file '${out}' already exists")
		endif()
		return()
	endif()
	path_suffix_new("${out}" tmp_out)
	set(prev_bak)
	execute_process(
		COMMAND ffmpeg -i "${in}" -vn -acodec "${Audio_Codec}" -b:a "${Audio_Bitrate}" -f "${Audio_Format}" -n -nostats -nostdin "${tmp_out}"
		RESULT_VARIABLE res
		OUTPUT_FILE "${log}"
		ERROR_FILE "${log}")
	if(NOT (res EQUAL 0))
		if(EXISTS "$(tmp_out}")
			# delete incomplete output
			execute_process(COMMAND "${CMAKE_COMMAND}" -E remove "$(tmp_out}")
		endif()
		message(FATAL_ERROR "ffmpeg failed (${res}), see '${log}'")
	endif()
	if(EXISTS "${out}")
		path_suffix_new("${out}" prev_bak)
		execute_process(COMMAND "${CMAKE_COMMAND}" -E rename "${out}" "${prev_bak}"
			RESULT_VARIABLE res)
		message(FATAL_ERROR "unable to rename existing file '${out}' ($res)")
	endif()
	execute_process(COMMAND "${CMAKE_COMMAND}" -E rename "${tmp_out}" "${out}"
		RESULT_VARIABLE res)
	if(NOT (res EQUAL 0))
		# delete incomplete output
		execute_process(COMMAND "${CMAKE_COMMAND}" -E remove "$(tmp_out}")
		if((EXISTS "${prev_bak}") AND (NOT (EXISTS "${out}")))
			execute_process(COMMAND "${CMAKE_COMMAND}" -E rename "${prev_bak}" "${out}")
		endif()
		message(FATAL_ERROR "unable to rename temporary to '${out}' ($res)")
	endif()
	if(prev_bak AND (EXISTS "${prev_bak}"))
		# delete old backup on success
		execute_process(COMMAND "${CMAKE_COMMAND}" -E remove "${prev_bak}")
	endif()
	return()
endif()

function(media_file_ext ext_var format codec)
	set(${ext_var} .m4a PARENT_SCOPE)
endfunction()

option(iTunes_Import "Import recoded files to iTunes?" ON)
set(Existing_Files Warn CACHE STRING "How to treat existing files (Overwrite, Skip, Warn, Error)")
set(Log_Files_Cleanup Success CACHE STRING "Whether to clean log files after recode (Success, Always, Never)")
set(Original_Cleanup Never CACHE STRING "Whether to clean original input files after recode (Success, Always, Never)")
set(Audio_Format mp4 CACHE STRING "Format (container) to encode to")
set(Audio_Codec aac CACHE STRING "Audio codec to encode to")
set(Audio_Bitrate 192k CACHE STRING "Audio bitrate to encode to")

function(export_vars res_var)
	set(res)
	foreach(var ${ARGN})
		list(APPEND res "-D${var}:STRING=${${var}}")
	endforeach()
	set(${res_var} ${res} PARENT_SCOPE)
endfunction()

function(recode_impl_ffmpeg in out log)
	export_vars(vars in out log Existing_Files Audio_Format Audio_Codec Audio_Bitrate)
	add_custom_command(OUTPUT "${out}"
		COMMAND ${CMAKE_COMMAND}
			-DMEDIA_LIBRARY_MAINTENANCE_RECODE_FFMPEG:BOOL=TRUE 
			${vars}
			-P "$ENV{HOMEDIR}/cmake/MediaLibraryMaintenance.cmake"
		MAIN_DEPENDENCY "${in}"
		BYPRODUCTS "${log}"
		COMMENT "Recoding '${in}' -> '${out}' using ffmpeg"
		VERBATIM)
endfunction()

function(itunes_import file log)
	# TODO
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
	
	recode_impl_ffmpeg("${in}" "${out}" "${log}")

	if(iTunes_Import)
		itunes_import("${out}" "${log}")
	endif()

	set(target "${base_rel}${out_ext}")
	string(MAKE_C_IDENTIFIER "${target}" target_id)
	add_custom_target(${target_id} ALL
		DEPENDS "${out}" "${log}"
		COMMENT "Executing recoding pipeline for target '${target}'"
		SOURCES "${in}")
endfunction()

function(recode_all in pattern)
	if(IS_DIRECTORY "${in}")
		file(GLOB_RECURSE files RELATIVE "${in}" "${pattern}")
		foreach(f IN LISTS files)
			recode_pipeline("${in}/${f}")
		endforeach(f IN LISTS files)
	else()
		recode_pipeline("${in}")
	endif()
endfunction()