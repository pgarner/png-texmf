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
#
# Notes:
# http://www.luatex.org/roadmap.html#tbp
# There are three possible LaTeX engines:
#  pdflatex is an established standard, and is fast
#  xelatex adds utf8 and better font support; it is marginally slower
#  lualatex further adds scripting; it is noticeably slower
# So here we default to xelatex, being the best compromise between up to date
# and practical

find_package(LATEX COMPONENTS XELATEX PDFLATEX LUALATEX BIBER BIBTEX)

# The main call to LaTeX, with the actual compiler named in TEX_CMD.  The
# dep on $BASENAME._ (which is never generated) makes the command
# unconditional; it will always be out of date
function(add_latex_command BASENAME AUX)
  message(STATUS "Adding ${BASENAME}")
  add_custom_command(
    OUTPUT    ${BASENAME}.log ${BASENAME}.aux ${BASENAME}.bcf ${BASENAME}._
    COMMAND   ${TEX_CMD}
    ARGS      -shell-escape -interaction=batchmode
              "${CMAKE_CURRENT_SOURCE_DIR}/${BASENAME}"
    BYPRODUCTS texput.log ${AUX} ${BASENAME}.out ${BASENAME}.toc
               ${BASENAME}.run.xml
    COMMENT   "${TEX_STR} ${BASENAME}"
    )
endfunction()

# The main call to BibTeX/Biber.  Biber actually looks for the .bcf from LaTeX
# and generates a .bbl file; BibTeX looks for the .aux file.  The .bcm is
# artificial, effectively causing a dependency on differences in the auxiliary
# file according to cmake's copy_if_different
function(add_bib_command BASENAME)
  message(STATUS "Adding ${BASENAME}.bbl")
  add_custom_command(
    OUTPUT    ${BASENAME}.bcm
    DEPENDS   "${CMAKE_CURRENT_BINARY_DIR}/${BASENAME}.${BIB_EXT}"
    COMMAND   ${CMAKE_COMMAND}
    ARGS      -E copy_if_different
              ${CMAKE_CURRENT_BINARY_DIR}/${BASENAME}.${BIB_EXT}
	      ${CMAKE_CURRENT_BINARY_DIR}/${BASENAME}.bcm
    COMMENT   "Bibliography update check ${BASENAME}"
    )
  add_custom_command(
    OUTPUT    ${BASENAME}.bbl
    DEPENDS   "${CMAKE_CURRENT_BINARY_DIR}/${BASENAME}.bcm"
    COMMAND   ${BIB_CMD}
    ARGS      ${BASENAME}
    BYPRODUCTS ${BASENAME}.blg
    COMMENT   "${BIB_STR} ${BASENAME}"
    )
endfunction()

# The main call from the application's CMakeLists.txt.  Adds a document to be
# compiled with latex with options:
#
#  BIBTEX: Include a bibliography managed using BibTeX
#  BIBER: Include a bibliography managed using BibLaTeX
#  GLOB: Include all .tex files in the directory; this makes `make clean` work
#  PDFLATEX: Use pdflatex compiler instead of xelatex
#  LUALATEX: Use lualatex compiler instead of xelatex
function(add_document BASENAME)

  # Options
  set(options BIBER BIBTEX GLOB PDFLATEX LUALATEX)
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
    set(TEX_CMD ${PDFLATEX_COMPILER})
    set(TEX_STR "PDFLaTeX")
  elseif(${OPT_LUALATEX})
    set(TEX_CMD ${LUALATEX_COMPILER})
    set(TEX_STR "LuaLaTeX")
  else()
    set(TEX_CMD ${XELATEX_COMPILER})
    set(TEX_STR "XeLaTeX")
  endif()
  add_latex_command(${BASENAME} "${aux}")

  # Add the target, either as a dep of the bibliography or alone
  if(${OPT_BIBER})
    set(BIB_CMD ${BIBER_COMPILER})
    set(BIB_STR "Biber")
    set(BIB_EXT "bcf")
    add_bib_command(${BASENAME})
    add_custom_target(${BASENAME}-bbl ALL DEPENDS
      "${CMAKE_CURRENT_BINARY_DIR}/${BASENAME}.bbl"
      )
  elseif(${OPT_BIBTEX})
    set(BIB_CMD ${BIBTEX_COMPILER})
    set(BIB_STR "BibTeX")
    set(BIB_EXT "aux")
    add_bib_command(${BASENAME})
    add_custom_target(${BASENAME}-bbl ALL DEPENDS
      "${CMAKE_CURRENT_BINARY_DIR}/${BASENAME}.bbl"
      )
  else()
    message(STATUS "Skipping ${BASENAME}.bbl")
    add_custom_target(${BASENAME} ALL DEPENDS ${BASENAME}._)
  endif()

endfunction()
