#
# Copyright 2023 by Philip N. Garner
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, January 2023
#

# Refs:
# https://gitlab.kitware.com/cmake/community/-/wikis/FAQ#how-do-i-use-cmake-to-build-latex-documents
# http://www.luatex.org/roadmap.html#tbp

find_package(LATEX COMPONENTS XELATEX PDFLATEX LUALATEX BIBER)

function(add_latex_command BASENAME AUX)
  message(STATUS "Adding ${BASENAME}")
  add_custom_command(
    OUTPUT    ${BASENAME}.log ${BASENAME}.aux ${BASENAME}.bcf ${BASENAME}._
    COMMAND   ${COMPILER_CMD}
    ARGS      -shell-escape -interaction=batchmode
              "${CMAKE_CURRENT_SOURCE_DIR}/${BASENAME}"
    BYPRODUCTS texput.log ${AUX} ${BASENAME}.out ${BASENAME}.toc
               ${BASENAME}.run.xml
    COMMENT   "${COMPILER_STR} ${BASENAME}"
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

  # This is the main LaTeX command, but without a target.  Default to xelatex,
  # with fallbacks to pdflatex or lualatex if requested
  if (${OPT_PDFLATEX})
    set(COMPILER_CMD ${PDFLATEX_COMPILER})
    set(COMPILER_STR "PDFLaTeX")
  elseif(${OPT_LUALATEX})
    set(COMPILER_CMD ${LUALATEX_COMPILER})
    set(COMPILER_STR "LuaLaTeX")
  else()
    set(COMPILER_CMD ${XELATEX_COMPILER})
    set(COMPILER_STR "XELaTeX")
  endif()
  add_latex_command(${BASENAME} "${aux}")

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
