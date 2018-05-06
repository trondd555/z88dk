/*
Z88DK Z80 Macro Assembler

Utilities working files.

Copyright (C) Gunther Strube, InterLogic 1993-99
Copyright (C) Paulo Custodio, 2011-2017
License: The Artistic License 2.0, http://www.perlfoundation.org/artistic_license_2_0
Repository: https://github.com/pauloscustodio/z88dk-z80asm
*/

#include "alloc.h"
#include "class.h"
#include "fileutil.h"
#include "zfileutil.h"
#include "str.h"
#include "strutil.h"
#include "uthash.h"

#include <assert.h>
#include <stdarg.h>
#include <sys/stat.h>
#ifdef _WIN32
#include <direct.h>
#endif

#ifdef _MSC_VER
#define snprintf _snprintf
#endif

/*-----------------------------------------------------------------------------
*   Pathname manipulation
*   All filenames are returned in fixed length Str defined by
*	STR_DEFINE( dest, FILENAME_MAX )
*	Input string is unchanged.
*	Basename is file name removing all directories.
*	Extension is the final "." followed by sequence of letters or digits
*----------------------------------------------------------------------------*/

/* search for a file on the given directory list, return full path name */
static void path_search_1(Str *dest, const char *filename, argv_t *dir_list, Str *pathname)
{
    Str_set( dest, filename );		/* default return: input file name */

    /* if no dir_list, return file */
    if ( dir_list == NULL )
        return;

    /* check if file exists in current directory */
	if (file_exists(filename))
		return;

    /* search in dir_list */
	for (char **pdir = argv_front(dir_list); *pdir; pdir++)
    {
		Str_sprintf(pathname, "%s/%s", *pdir, filename);

		if (file_exists(Str_data(pathname))) {
            Str_set( dest, Str_data(pathname) );
            return;
        }
    }

    /* return unchanged pathname if not found */
    return;
}

void path_search(Str *dest, const char *filename, argv_t *dir_list)
{
	STR_DEFINE(pathname, FILENAME_MAX);
	path_search_1(dest, filename, dir_list, pathname);
	STR_DELETE(pathname);
}

const char *search_file(const char *filename, argv_t *dir_list )
{
	STR_DEFINE(dest, FILENAME_MAX);
	const char *ret;

    path_search( dest, filename, dir_list );
	ret = spool_add(Str_data(dest));

	STR_DELETE(dest);
	return ret;
}

