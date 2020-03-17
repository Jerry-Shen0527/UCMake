# [ Interface ]
#
# ----------------------------------------------------------------------------
#
# Ubpa_AddSubDirsRec(<path>)
# - add all subdirectories recursively in <path>
#
# ----------------------------------------------------------------------------
#
# Ubpa_GroupSrcs(PATH <path> SOURCES <sources-list>
# - create filters (relative to <path>) for sources
#
# ----------------------------------------------------------------------------
#
# Ubpa_GlobGroupSrcs(RST <rst> PATHS <paths-list>)
# - recursively glob all sources in <paths-list>
#   and call Ubpa_GroupSrcs(PATH <path> SOURCES <rst>) for each path in <paths-list>
# - regex : .+\.(h|hpp|inl|in|c|cc|cpp|cxx)
#
# ----------------------------------------------------------------------------
#
# Ubpa_GetTargetName(<rst> <targetPath>)
# - get target name at <targetPath>
#
# ----------------------------------------------------------------------------
#
# Ubpa_AddTarget_GDR(MODE <mode> [QT <qt>] [SOURCES <sources-list>] [TEST <test>]
#     [LIBS_GENERAL <libsG-list>] [LIBS_DEBUG <libsD-list>] [LIBS_RELEASE <libsR-list>])
# - mode         : EXE / LIB / DLL
# - qt           : default OFF, for moc, uic, qrc
# - test         : default OFF, test won't install
# - libsG-list   : auto add DEBUG_POSTFIX for debug mode
# - sources-list : if sources is empty, call Ubpa_GlobGroupSrcs for currunt path
# - auto set target name, folder, target prefix and some properties
#
# ----------------------------------------------------------------------------
#
# Ubpa_AddTarget(MODE <mode> [QT <qt>] [TEST <test>] [SOURCES <sources-list>] [LIBS <libs-list>])
# - call Ubpa_AddTarget(MODE <mode> QT <qt> TEST <test> SOURCES <sources-list> LIBS_GENERAL <libs-list>)
#
# ----------------------------------------------------------------------------
#
# Ubpa_Export([INC <inc>])
# - export some files
# - inc: default ON, install include/
#
# ----------------------------------------------------------------------------
#
# Ubpa_InitInstallPrefix()
#
# ----------------------------------------------------------------------------

message(STATUS "include UbpaBuild.cmake")

include("${CMAKE_CURRENT_LIST_DIR}/UbpaQt.cmake")

macro(Ubpa_InitInstallPrefix)
	if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
	  Ubpa_Path_Back(root ${CMAKE_INSTALL_PREFIX} 1)
	  set(CMAKE_INSTALL_PREFIX "${root}/Ubpa" CACHE PATH "install prefix" FORCE)
	endif()
endmacro()

function(Ubpa_AddSubDirsRec path)
	message(STATUS "----------")
	file(GLOB_RECURSE children LIST_DIRECTORIES true ${CMAKE_CURRENT_SOURCE_DIR}/${path}/*)
	set(dirs "")
	foreach(item ${children})
		if(IS_DIRECTORY ${item} AND EXISTS "${item}/CMakeLists.txt")
			list(APPEND dirs ${item})
		endif()
	endforeach()
	Ubpa_List_Print(TITLE "directories:" PREFIX "- " STRS ${dirs})
	foreach(dir ${dirs})
		add_subdirectory(${dir})
	endforeach()
endfunction()

function(Ubpa_GroupSrcs)
	cmake_parse_arguments("ARG" "" "PATH" "SOURCES" ${ARGN})
	
	set(headerFiles ${ARG_SOURCES})
	list(FILTER headerFiles INCLUDE REGEX ".+\.(h|hpp|inl|in)$")
	
	set(sourceFiles ${ARG_SOURCES})
	list(FILTER sourceFiles INCLUDE REGEX ".+\.(c|cc|cpp|cxx)$")
	
	set(qtFiles ${ARG_SOURCES})
	list(FILTER qtFiles INCLUDE REGEX ".+\.(qrc|ui)$")
	
	foreach(header ${headerFiles})
		get_filename_component(headerPath "${header}" PATH)
		file(RELATIVE_PATH headerPathRel ${ARG_PATH} "${headerPath}")
		if(MSVC)
			string(REPLACE "/" "\\" headerPathRelMSVC "${headerPathRel}")
			set(headerPathRel "Header Files\\${headerPathRelMSVC}")
		endif()
		source_group("${headerPathRel}" FILES "${header}")
	endforeach()
	
	foreach(source ${sourceFiles})
		get_filename_component(sourcePath "${source}" PATH)
		file(RELATIVE_PATH sourcePathRel ${ARG_PATH} "${sourcePath}")
		if(MSVC)
			string(REPLACE "/" "\\" sourcePathRelMSVC "${sourcePathRel}")
			set(sourcePathRel "Source Files\\${sourcePathRelMSVC}")
		endif()
		source_group("${sourcePathRel}" FILES "${source}")
	endforeach()
	
	foreach(qtFile ${qtFiles})
		get_filename_component(qtFilePath "${qtFile}" PATH)
		file(RELATIVE_PATH qtFilePathRel ${ARG_PATH} "${qtFilePath}")
		if(MSVC)
			string(REPLACE "/" "\\" qtFilePathRelMSVC "${qtFilePathRel}")
			set(qtFilePathRel "Qt Files\\${qtFilePathRelMSVC}")
		endif()
		source_group("${qtFilePathRel}" FILES "${qtFile}")
	endforeach()
endfunction()

function(Ubpa_GlobGroupSrcs)
	cmake_parse_arguments("ARG" "" "RST" "PATHS" ${ARGN})
	set(sources "")
	foreach(path ${ARG_PATHS})
		file(GLOB_RECURSE pathSources
			"${path}/*.h"
			"${path}/*.hpp"
			"${path}/*.inl"
			"${path}/*.in"
			"${path}/*.c"
			"${path}/*.cc"
			"${path}/*.cpp"
			"${path}/*.cxx"
			"${path}/*.qrc"
			"${path}/*.ui"
		)
		list(APPEND sources ${pathSources})
		Ubpa_GroupSrcs(PATH ${path} SOURCES ${pathSources})
	endforeach()
	set(${ARG_RST} ${sources} PARENT_SCOPE)
endfunction()

function(Ubpa_GetTargetName rst targetPath)
	file(RELATIVE_PATH targetRelPath "${PROJECT_SOURCE_DIR}/src" "${targetPath}")
	string(REPLACE "/" "_" targetName "${PROJECT_NAME}/${targetRelPath}")
	set(${rst} ${targetName} PARENT_SCOPE) 
endfunction()

function(Ubpa_AddTarget_GDR)
    # https://www.cnblogs.com/cynchanpin/p/7354864.html
	# https://blog.csdn.net/fuyajun01/article/details/9036443
	cmake_parse_arguments("ARG" "" "MODE;QT;TEST" "SOURCES;LIBS_GENERAL;LIBS_DEBUG;LIBS_RELEASE" ${ARGN})
	file(RELATIVE_PATH targetRelPath "${PROJECT_SOURCE_DIR}/src" "${CMAKE_CURRENT_SOURCE_DIR}/..")
	set(folderPath "${PROJECT_NAME}/${targetRelPath}")
	Ubpa_GetTargetName(targetName ${CMAKE_CURRENT_SOURCE_DIR})
	
	list(LENGTH ARG_SOURCES sourceNum)
	if(${sourceNum} EQUAL 0)
		Ubpa_GlobGroupSrcs(RST ARG_SOURCES PATHS ${CMAKE_CURRENT_SOURCE_DIR})
		list(LENGTH ARG_SOURCES sourceNum)
		if(sourcesNum EQUAL 0)
			message(WARNING "Target [${targetName}] has no source")
			return()
		endif()
	endif()
	
	message(STATUS "----------")
	message(STATUS "- name: ${targetName}")
	message(STATUS "- folder : ${folderPath}")
	message(STATUS "- mode: ${ARG_MODE}")
	Ubpa_List_Print(STRS ${ARG_SOURCES}
		TITLE  "- sources:"
		PREFIX "    ")
	
	list(LENGTH ARG_LIBS_GENERAL generalLibNum)
	list(LENGTH ARG_LIBS_DEBUG debugLibNum)
	list(LENGTH ARG_LIBS_RELEASE releaseLibNum)
	if(${debugLibNum} EQUAL 0 AND ${releaseLibNum} EQUAL 0)
		if(NOT ${generalLibNum} EQUAL 0)
		Ubpa_List_Print(STRS ${ARG_LIBS_GENERAL}
			TITLE  "- lib:"
			PREFIX "    ")
		endif()
	else()
		message(STATUS "- libs:")
		Ubpa_List_Print(STRS ${ARG_LIBS_GENERAL}
			TITLE  "  - general:"
			PREFIX "      ")
		Ubpa_List_Print(STRS ${ARG_LIBS_DEBUG}
			TITLE  "  - debug:"
			PREFIX "      ")
		Ubpa_List_Print(STRS ${ARG_LIBS_RELEASE}
			TITLE  "  - release:"
			PREFIX "      ")
	endif()
	
	# add target
	
	if(${ARG_QT})
		Ubpa_QtBegin()
	endif()
	
	if(${ARG_MODE} STREQUAL "EXE")
		add_executable(${targetName} ${ARG_SOURCES})
		if(MSVC)
			set_target_properties(${targetName} PROPERTIES VS_DEBUGGER_WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}/bin")
		endif()
		set_target_properties(${targetName} PROPERTIES DEBUG_POSTFIX ${CMAKE_DEBUG_POSTFIX})
		set(targets ${targetName})
	elseif(${ARG_MODE} STREQUAL "LIB")
		add_library(${targetName} ${ARG_SOURCES})
		add_library("Ubpa::${targetName}" ALIAS ${targetName})
		# 无需手动设置
		#set_target_properties(${targetName} PROPERTIES DEBUG_POSTFIX ${CMAKE_DEBUG_POSTFIX})
		set(targets ${targetName})
	elseif(${ARG_MODE} STREQUAL "DLL")
		add_library(${targetName} SHARED ${ARG_SOURCES})
		add_library("Ubpa::${targetName}" ALIAS ${targetName})
		set(targets ${targetName})
	elseif(${ARG_MODE} STREQUAL "DS")
		add_library("${targetName}_shared" SHARED ${ARG_SOURCES})
		add_library("Ubpa::${targetName}_shared" ALIAS "${targetName}_shared")
		add_library("${targetName}_static" STATIC ${ARG_SOURCES})
		add_library("Ubpa::${targetName}_static" ALIAS "${targetName}_static")
		target_compile_definitions("${targetName}_static" PUBLIC -DUBPA_STATIC)
		set(targets "${targetName}_shared;${targetName}_static")
	else()
		message(FATAL_ERROR "mode [${ARG_MODE}] is not supported")
		return()
	endif()
	
	foreach(target ${targets})
		set_target_properties(${target} PROPERTIES FOLDER ${folderPath})
	
		foreach(lib ${ARG_LIBS_GENERAL})
			target_link_libraries(${target} general ${lib})
		endforeach()
		foreach(lib ${ARG_LIBS_DEBUG})
			target_link_libraries(${target} debug ${lib})
		endforeach()
		foreach(lib ${ARG_LIBS_RELEASE})
			target_link_libraries(${target} optimized ${lib})
		endforeach()
		if(NOT "${ARG_TEST}" STREQUAL "ON")
			install(TARGETS ${target}
				EXPORT "${PROJECT_NAME}Targets"
				RUNTIME DESTINATION "bin"
				ARCHIVE DESTINATION "lib"
				LIBRARY DESTINATION "lib")
		endif()
	endforeach()
	
	if(${ARG_QT})
		Ubpa_QtEnd()
	endif()
endfunction()

function(Ubpa_AddTarget)
    # https://www.cnblogs.com/cynchanpin/p/7354864.html
	# https://blog.csdn.net/fuyajun01/article/details/9036443
	cmake_parse_arguments("ARG" "" "MODE;QT;TEST" "SOURCES;LIBS" ${ARGN})
	Ubpa_AddTarget_GDR(MODE ${ARG_MODE} QT ${ARG_QT} TEST ${ARG_TEST} SOURCES ${ARG_SOURCES} LIBS_GENERAL ${ARG_LIBS})
endfunction()

macro(Ubpa_Export)
	cmake_parse_arguments("ARG" "" "INC" "" ${ARGN})
	
	# install the configuration targets
	install(EXPORT "${PROJECT_NAME}Targets"
		FILE "${PROJECT_NAME}Targets.cmake"
		DESTINATION "lib/${PROJECT_NAME}/cmake"
	)
	
	include(CMakePackageConfigHelpers)
	
	# generate the config file that is includes the exports
	configure_package_config_file(${PROJECT_SOURCE_DIR}/config/Config.cmake.in
		"${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
		INSTALL_DESTINATION "lib/${PROJECT_NAME}/cmake"
		NO_SET_AND_CHECK_MACRO
		NO_CHECK_REQUIRED_COMPONENTS_MACRO
	)
	
	# generate the version file for the config file
	write_basic_package_version_file(
		"${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
		VERSION "${Tutorial_VERSION_MAJOR}.${Tutorial_VERSION_MINOR}"
		COMPATIBILITY AnyNewerVersion
	)

	# install the configuration file
	install(FILES
		"${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
		DESTINATION "lib/${PROJECT_NAME}/cmake"
	)

	# generate the export targets for the build tree
	# needs to be after the install(TARGETS ) command
	export(EXPORT "${PROJECT_NAME}Targets"
		NAMESPACE "${PROJECT_NAME}::"
		FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Targets.cmake"
	)

	install(FILES
		"${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Targets.cmake"
		DESTINATION "lib/${PROJECT_NAME}/cmake"
	)
	
	if(NOT "${ARG_INC}" STREQUAL "OFF")
		install(DIRECTORY "include" DESTINATION ${CMAKE_INSTALL_PREFIX})
	endif()
endmacro()
