#
# Copyright 2023 by Philip N. Garner
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, January 2023
#

# Ref: https://gitlab.kitware.com/cmake/community/-/wikis/FAQ#how-do-i-use-cmake-to-build-latex-documents

find_package(LATEX COMPONENTS PDFLATEX LUALATEX BIBER)

function(add_lualatex_command BASENAME AUX)
  message(STATUS "Adding ${BASENAME}")
  add_custom_command(
    OUTPUT    ${BASENAME}.log ${BASENAME}.aux ${BASENAME}.bcf ${BASENAME}._
    COMMAND   ${LUALATEX_COMPILER}
    ARGS      -shell-escape -interaction=batchmode
              "${CMAKE_CURRENT_SOURCE_DIR}/${BASENAME}"
    BYPRODUCTS texput.log ${AUX} ${BASENAME}.out ${BASENAME}.toc
               ${BASENAME}.run.xml
    COMMENT   "LuaLaTeX ${BASENAME}"
    )
endfunction()

function(add_pdflatex_command BASENAME AUX)
  message(STATUS "Adding ${BASENAME}")
  add_custom_command(
    OUTPUT    ${BASENAME}.log ${BASENAME}.aux ${BASENAME}.bcf ${BASENAME}._
    COMMAND   ${PDFLATEX_COMPILER}
    ARGS      -shell-escape -interaction=batchmode
              "${CMAKE_CURRENT_SOURCE_DIR}/${BASENAME}"
    BYPRODUCTS texput.log ${AUX} ${BASENAME}.out ${BASENAME}.toc
               ${BASENAME}.run.xml
    COMMENT   "PDFLaTeX ${BASENAME}"
    )
endfunction()

function(add_biber_command BASENAME)
  message(STATUS "Adding ${BASENAME}.bbl")
  add_custom_command(
    OUTPUT    ${BASENAME}.bcm
    DEPENDS   "${CMAKE_CURRENT_BINARY_DIR}/${BASENAME}.bcf"
    COMMAND   ${CMAKE_COMMAND}
    ARGS      -E copy_if_different
              ${CMAKE_CURRENT_BINARY_DIR}/${BASENAME}.bcf
	      ${CMAKE_CURRENT_BINARY_DIR}/${BASENAME}.bcm
    COMMENT   "Bibliography update check ${BASENAME}"
    )
  add_custom_command(
    OUTPUT    ${BASENAME}.bbl
    DEPENDS   "${CMAKE_CURRENT_BINARY_DIR}/${BASENAME}.bcm"
    COMMAND   ${BIBER_COMPILER}
    ARGS      ${BASENAME}
    BYPRODUCTS ${BASENAME}.blg
    COMMENT   "Biber ${BASENAME}"
    )
endfunction()

function(add_document BASENAME)

  # Options
  set(options BIBER GLOB PDFLATEX)
  cmake_parse_arguments(PARSE_ARGV 1 OPT "${options}" "" "")

  # Build a list of the auxiliary files
  if (${OPT_GLOB})
    file(GLOB aux RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "*.tex")
    list(TRANSFORM aux REPLACE ".tex$" ".aux")
  else()
    set(aux "${BASENAME}.aux")
  endif()

  # This is the main LaTeX command, but without a target.  Default to lualatex,
  # with a fallback to pdflatex if requested
  if (${OPT_PDFLATEX})
    add_pdflatex_command(${BASENAME} "${aux}")
  else()
    add_lualatex_command(${BASENAME} "${aux}")
  endif()

  # Add the target, either as a dep of the bibliography or unconditionally
  if(${OPT_BIBER})
    add_biber_command(${BASENAME})
    add_custom_target(${BASENAME}-bbl ALL DEPENDS
      "${CMAKE_CURRENT_BINARY_DIR}/${BASENAME}.bbl"
      )
  else()
    message(STATUS "Skipping ${BASENAME}.bbl")
    add_custom_target(${BASENAME} ALL DEPENDS ${BASENAME}._)
  endif()

endfunction()
