# ----------------------------------------------------------------------------
#
# Ubpa_QtInstall()
# - call it before adding Qt target
#
# ----------------------------------------------------------------------------
#
# QtEnd()
# - call it after adding Qt target
#
# ----------------------------------------------------------------------------

message(STATUS "include UbpaQt.cmake")

include(UbpaBasic)

# must use macro
macro(Ubpa_QtInit)
	message(STATUS "----------")
	cmake_parse_arguments("ARG" "" "" "COMPONENTS" ${ARGN})
	Ubpa_List_Print(TITLE "Qt Components" PREFIX "  - " STRS ${ARG_COMPONENTS})
	find_package(Qt5 COMPONENTS REQUIRED ${ARG_COMPONENTS})
	set(CMAKE_INCLUDE_CURRENT_DIR ON)
	if(WIN32)
		Ubpa_Path_Back(_QtRoot ${Qt5_DIR} 3)
		foreach(_cmpt ${ARG_COMPONENTS})
			set(_dllPathR "${_QtRoot}/bin/Qt5${_cmpt}.dll")
			set(_dllPathD "${_QtRoot}/bin/Qt5${_cmpt}d.dll")
			if(EXISTS ${_dllPathD} AND EXISTS ${_dllPathR})
				install(FILES ${_dllPathD} TYPE BIN CONFIGURATIONS Debug)
				install(FILES ${_dllPathR} TYPE BIN CONFIGURATIONS Release)
			else()
				STATUS(WARNING "file not exist: ${_dllPath}(d).dll")
			endif()
		endforeach()
	endif()
endmacro()

function(Ubpa_QtBegin)
	set(CMAKE_AUTOMOC ON PARENT_SCOPE)
	set(CMAKE_AUTOUIC ON PARENT_SCOPE)
	set(CMAKE_AUTORCC ON PARENT_SCOPE)
endfunction()

function(Ubpa_QtEnd)
	set(CMAKE_AUTOMOC OFF PARENT_SCOPE)
	set(CMAKE_AUTOUIC OFF PARENT_SCOPE)
	set(CMAKE_AUTORCC OFF PARENT_SCOPE)
endfunction()