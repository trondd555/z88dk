#!/usr/bin/perl

# Copyright (C) Paulo Custodio, 2011-2014
#
# $Header: /home/dom/z88dk-git/cvs/z88dk/src/z80asm/lib/t/fileutil.t,v 1.18 2014-09-01 21:09:08 pauloscustodio Exp $
#
# Test fileutil.c

use Modern::Perl;
use Test::More;
use File::Slurp;
use File::Path qw(make_path remove_tree);
use Capture::Tiny 'capture';
use Test::Differences; 

my $compile = "cc -Wall -Wno-overflow -otest test.c fileutil.c strutil.c xmalloc.c dlist.c class.c list.c strpool.c";

#------------------------------------------------------------------------------
# create directories and files
make_path('test.x1', 'test.x2', 'test.x3');
write_file('test.f0', "");
write_file('test.x1/test.f0', "");
write_file('test.x1/test.f1', "");
write_file('test.x2/test.f1', "");
write_file('test.x2/test.f2', "");
write_file('test.x3/test.f2', "");
write_file('test.x3/test.f3', "");


#------------------------------------------------------------------------------
write_file("test.c", <<'END');
#include "fileutil.h"
#include "strpool.h"

#define ERROR die("Test failed at line %d\n", __LINE__)

#define T_REMOVE_EXT(init, result) \
		p = path_remove_ext( init ); \
		if ( strcmp( p, result ) ) ERROR;

#define T_REPLACE_EXT(init, ext, result) \
		p = path_replace_ext( init, ext ); \
		if ( strcmp( p, result ) ) ERROR;

#define T_BASENAME(init, result) \
		p = path_basename( init ); \
		if ( strcmp( p, result ) ) ERROR;

#define T_DIRNAME(init, result) \
		p = path_dirname( init ); \
		if ( strcmp( p, result ) ) ERROR;

#define T_SEARCH(file, path, result) \
		path_search( s, file, path ); \
		if ( strcmp( s->str, result ) ) ERROR; \
		p = search_file( file, path ); \
		if ( strcmp( p, result ) ) ERROR;

int main()
{
	DEFINE_FILE_STR( s );
	char *p;
	List *path = NULL;
	
	/* path_remove_ext */
	T_REMOVE_EXT("abc", 			"abc");
	T_REMOVE_EXT("abc.", 			"abc");
	T_REMOVE_EXT("abc.xpt", 		"abc");
	T_REMOVE_EXT("abc.xpt.obj", 	"abc.xpt");
	T_REMOVE_EXT("./abc", 			"./abc");
	T_REMOVE_EXT(".\\abc",			".\\abc");
	T_REMOVE_EXT("./abc.", 			"./abc");
	T_REMOVE_EXT(".\\abc.",			".\\abc");
	T_REMOVE_EXT("./abc.xpt", 		"./abc");
	T_REMOVE_EXT(".\\abc.xpt",		".\\abc");
	T_REMOVE_EXT("./abc.xpt.obj", 	"./abc.xpt");
	T_REMOVE_EXT(".\\abc.xpt.obj",	".\\abc.xpt");

	/* path_replace_ext */
	T_REPLACE_EXT("abc", 		NULL,	"abc");
	T_REPLACE_EXT("abc.", 		NULL,	"abc");
	T_REPLACE_EXT("abc", 		"",		"abc");
	T_REPLACE_EXT("abc.", 		"",		"abc");
	T_REPLACE_EXT("abc", 		".obj",	"abc.obj");
	T_REPLACE_EXT("abc.", 		".obj",	"abc.obj");
	T_REPLACE_EXT("abc.xpt.zz",	".obj",	"abc.xpt.obj");
	T_REPLACE_EXT("./abc", 		".obj",	"./abc.obj");
	T_REPLACE_EXT(".\\abc", 	".obj",	".\\abc.obj");
	T_REPLACE_EXT("./abc.", 	".obj",	"./abc.obj");
	T_REPLACE_EXT(".\\abc.", 	".obj",	".\\abc.obj");
	T_REPLACE_EXT("./abc.xpt", 	".obj",	"./abc.obj");
	T_REPLACE_EXT(".\\abc.xpt", ".obj",	".\\abc.obj");

	/* path_basename */
	T_BASENAME("abc",			"abc");
	T_BASENAME("abc.zz",		"abc.zz");
	T_BASENAME("./abc",			"abc");
	T_BASENAME(".\\abc",		"abc");
	T_BASENAME("/a/b/c/abc",	"abc");
	T_BASENAME("\\a\\b\\c\\abc","abc");
	
	/* path_dirname */
	T_DIRNAME("abc",			"");
	T_DIRNAME("abc.zz",			"");
	T_DIRNAME("./abc",			"./");
	T_DIRNAME(".\\abc",			".\\");
	T_DIRNAME("/a/b/c/abc",		"/a/b/c/");
	T_DIRNAME("\\a\\b\\c\\abc",	"\\a\\b\\c\\");
	
	/* path_search */
	List_push(&path, strpool_add("test.x1"));
	List_push(&path, strpool_add("test.x2"));
	List_push(&path, strpool_add("test.x3"));
	
	T_SEARCH("test.f0", NULL, "test.f0");
	T_SEARCH("test.f1", NULL, "test.f1");
	T_SEARCH("test.f2", NULL, "test.f2");
	T_SEARCH("test.f3", NULL, "test.f3");
	T_SEARCH("test.f4", NULL, "test.f4");
	T_SEARCH("test.f0", path, "test.f0");
	T_SEARCH("test.f1", path, "test.x1/test.f1");
	T_SEARCH("test.f2", path, "test.x2/test.f2");
	T_SEARCH("test.f3", path, "test.x3/test.f3");
	T_SEARCH("test.f4", path, "test.f4");
	
	return 0;
}
END

system($compile) and die "compile failed: $compile\n";
t_capture("./test", "", "", 0);


#------------------------------------------------------------------------------
# error callback
write_file("test.c", <<'END');
#include "fileutil.h"

#define ERROR die("Test failed at line %d\n", __LINE__)

void error(char *filename, Bool writing)
{
	die("captured error %s %d\n", filename, writing );
}

void null_error(char *filename, Bool writing)
{
	warn("captured error %s %d\n", filename, writing );
}

int main(int argc, char *argv[])
{
	ferr_callback_t old;
	
	old = set_ferr_callback( error );
	if (old != NULL) ERROR;
	
	old = set_ferr_callback( error );
	if (old != error) ERROR;

	switch (*argv[1]) 
	{
		case '0':	xfopen("test.1xxxx.bin", 		"rb"); break;
		case '1':	xfopen("x/x/x/x/test.1.bin", 	"wb"); break;
		case '2': 	set_ferr_callback( null_error );
					xfopen("test.1xxxx.bin",		"rb");
					break;
		case '3': 	set_ferr_callback( null_error );
					xfopen("x/x/x/x/test.1.bin", "wb"); 
					break;
	}
							
	return 0;
}
END

system($compile) and die "compile failed: $compile\n";
t_capture("./test 0", "", "captured error test.1xxxx.bin 0\n", 1);
t_capture("./test 1", "", "captured error x/x/x/x/test.1.bin 1\n", 1);
t_capture("./test 2", "", "captured error test.1xxxx.bin 0\n".
						"Error: cannot read file 'test.1xxxx.bin'\n", 1);
t_capture("./test 3", "", "captured error x/x/x/x/test.1.bin 1\n".
						"Error: cannot write file 'x/x/x/x/test.1.bin'\n", 1);


#------------------------------------------------------------------------------
# file io
write_file("test.c", <<'END');
#include "fileutil.h"

#define ERROR die("Test failed at line %d\n", __LINE__)

/* 256 characters */
#define BIG_STR "1234567890" "1234567890" "1234567890" "1234567890" "1234567890" \
				"1234567890" "1234567890" "1234567890" "1234567890" "1234567890" \
				"1234567890" "1234567890" "1234567890" "1234567890" "1234567890" \
				"1234567890" "1234567890" "1234567890" "1234567890" "1234567890" \
				"1234567890" "1234567890" "1234567890" "1234567890" "1234567890" \
				"123456" 

int main(int argc, char *argv[])
{
	DEFINE_STR( small, 5 );
	DEFINE_STR( large, 1024 );
	Str *huge;
	char buffer[1024];
	FILE *file;
	int ivalue;
	unsigned uvalue;
	long ilvalue;
	unsigned long ulvalue;
	
	switch (*argv[1]) 
	{
		case '0':	xfopen("test.1xxxx.bin", "rb");
					ERROR; /* not reached */

		case '1':	xfopen("x/x/x/x/test.1.bin", "wb"); 
					ERROR; /* not reached */
		
		case '2':	file = xfopen("test.1.bin", "wb"); if ( ! file ) ERROR;
					xfclose(file);
					break;
					
		case '4':	Str_set( small, BIG_STR );
					file = xfopen("test.1.bin", "wb"); if ( ! file ) ERROR;
					xfwrite( small->str, sizeof(char), small->len, file );
					xfclose(file);
					break;
					
		case '5':	Str_set( small, BIG_STR );
					file = xfopen("test.1.bin", "rb"); if ( ! file ) ERROR;
					xfwrite( small->str, sizeof(char), small->len, file );
					ERROR; /* not reached */

		case '6':	Str_set( small, BIG_STR );
					memset(buffer, 0, sizeof(buffer));
					file = xfopen("test.1.bin", "rb"); if ( ! file ) ERROR;
					xfread( buffer, sizeof(char), small->len, file );
					if (memcmp(buffer, small->str, small->len)) ERROR;
					
					fseek(file, 1, SEEK_SET);
					xfread( buffer, sizeof(char), small->len, file );
					ERROR; /* not reached */
		
		case '7':	Str_set( small, BIG_STR );
					file = xfopen("test.1.bin", "wb"); if ( ! file ) ERROR;
					xfput_chars( file, small->str, small->len );
					xfput_chars( file, small->str, small->len - 1 );
					xfclose(file);
					
					memset(buffer, 0, sizeof(buffer));
					file = xfopen("test.1.bin", "rb"); if ( ! file ) ERROR;
					xfget_chars( file, buffer, 4 );
					xfget_chars( file, buffer+4, 3 );
					xfclose(file);
					if (memcmp(buffer, "1234123", 7)) ERROR;
					break;
					
		case '8':	Str_set( small, BIG_STR );
					file = xfopen("test.1.bin", "wb"); if ( ! file ) ERROR;
					xfput_chars( file, small->str, small->len );
					xfclose(file);
					
					memset(buffer, 0, sizeof(buffer));
					file = xfopen("test.1.bin", "rb"); if ( ! file ) ERROR;
					xfget_chars( file, buffer, small->len+1 );
					ERROR; /* not reached */
					
		case '9':	Str_set( small, BIG_STR );
					file = xfopen("test.1.bin", "wb"); if ( ! file ) ERROR;
					xfput_Str(  file, small );
					xfput_strz( file, "abc" );
					xfclose(file);
		
					memset( large->str, 0, large->size );
					file = xfopen("test.1.bin", "rb"); if ( ! file ) ERROR;
					xfget_Str( file, large, 7 );
					xfclose(file);
					if (large->len != 7) ERROR;
					if (memcmp( large->str, "1234abc", 7)) ERROR;
					break;
					
		case 'A':	Str_set( small, BIG_STR );
					file = xfopen("test.1.bin", "wb"); if ( ! file ) ERROR;
					xfput_Str( file, small );
					xfclose(file);
		
					file = xfopen("test.1.bin", "rb"); if ( ! file ) ERROR;
					xfget_Str( file, large, small->len+1 );
					ERROR; /* not reached */
					
		case 'B':	Str_set_bytes( small, "\0\1\2\3", 4 );
					file = xfopen("test.1.bin", "wb"); if ( ! file ) ERROR;
					xfput_Str( file, small );
					xfclose(file);
		
					memset( large->str, 0, large->size );
					file = xfopen("test.1.bin", "rb"); if ( ! file ) ERROR;
					xfget_Str( file, large, small->len );
					xfclose(file);
					if (large->len != 4) ERROR;
					if (memcmp( large->str, "\0\1\2\3", 4)) ERROR;
					break;
					
		case 'C':	file = xfopen("test.1.bin", "wb"); if ( ! file ) ERROR;
		
					Str_clear( small );			xfput_count_byte_Str( file, small );
					Str_set( small, BIG_STR );	xfput_count_byte_Str( file, small );
												xfput_count_byte_strz( file, "hello world" );
					Str_clear( large );			xfput_count_word_Str( file, large );
					Str_set( large, BIG_STR );	xfput_count_word_Str( file, large );
												xfput_count_word_strz( file, "hello world" );
					xfclose(file);
		
					file = xfopen("test.1.bin", "rb"); if ( ! file ) ERROR;
					
					memset( large->str, 0, large->size );
					xfget_count_byte_Str( file, large );
					if (large->len != 0) ERROR;
					if (memcmp( large->str, "", 0)) ERROR;
					
					memset( large->str, 0, large->size );
					xfget_count_byte_Str( file, large );
					if (large->len != 4) ERROR;
					if (memcmp( large->str, "1234", 4)) ERROR;
					
					memset( large->str, 0, large->size );
					xfget_count_byte_Str( file, large );
					if (large->len != 11) ERROR;
					if (memcmp( large->str, "hello world", 11)) ERROR;
					
					memset( large->str, 0, large->size );
					xfget_count_word_Str( file, large );
					if (large->len != 0) ERROR;
					if (memcmp( large->str, "", 0)) ERROR;
					
					memset( large->str, 0, large->size );
					xfget_count_word_Str( file, large );
					if (large->len != 256) ERROR;
					if (memcmp( large->str, BIG_STR, 256)) ERROR;
					
					memset( large->str, 0, large->size );
					xfget_count_word_Str( file, large );
					if (large->len != 11) ERROR;
					if (memcmp( large->str, "hello world", 11)) ERROR;
					
					xfclose(file);
					break;

		case 'D':	Str_set( large, BIG_STR );
					file = xfopen("test.1.bin", "wb"); if ( ! file ) ERROR;
					xfput_count_byte_Str( file, large );
					ERROR; /* not reached */
								
		case 'E':	huge = OBJ_NEW(Str);
					Str_reserve( huge, 0x10000 );
					huge->len = 0x10000;
					
					file = xfopen("test.1.bin", "wb"); if ( ! file ) ERROR;
					xfput_count_word_Str( file, huge );
					ERROR; /* not reached */

		case 'F':	file = xfopen("test.1.bin", "wb"); if ( ! file ) ERROR;
					xfput_int8(   file,        -128 );
					xfput_uint8(  file,        -128 );
					xfput_int8(   file,        -127 );
					xfput_uint8(  file,        -127 );
					xfput_int8(   file,           0 );
					xfput_uint8(  file,           0 );
					xfput_int8(   file,         127 );
					xfput_uint8(  file,         127 );
					xfput_int8(   file,         128 );
					xfput_uint8(  file,         128 );
					xfput_int8(   file,         255 );
					xfput_uint8(  file,         255 );
					xfput_int8(   file,         256 );
					xfput_uint8(  file,         256 );
					xfput_int16(  file,      -32768 );
					xfput_uint16( file,      -32768 );
					xfput_int16(  file,      -32767 );
					xfput_uint16( file,      -32767 );
					xfput_int16(  file,           0 );
					xfput_uint16( file,           0 );
					xfput_int16(  file,       32767 );
					xfput_uint16( file,       32767 );
					xfput_int16(  file,       32768 );
					xfput_uint16( file,       32768 );
					xfput_int16(  file,       65535 );
					xfput_uint16( file,       65535 );
					xfput_int16(  file,       65536 );
					xfput_uint16( file,       65536 );
					xfput_int32(  file,  0x80000000 ); /* -2,147,483,648 */
					xfput_uint32( file,  0x80000000 ); /*  2,147,483,648 */
					xfput_int32(  file,  0x80000001 ); /* -2,147,483,647 */
					xfput_uint32( file,  0x80000001 ); /*  2,147,483,649 */
					xfput_int32(  file,           0 );
					xfput_uint32( file,           0 );
					xfput_int32(  file,           1 );
					xfput_uint32( file,           1 );
					xfput_int32(  file,         256 );
					xfput_uint32( file,         256 );
					xfput_int32(  file,       65536 );
					xfput_uint32( file,       65536 );
					xfput_int32(  file,    16777216 );
					xfput_uint32( file,    16777216 );
					xfput_int32(  file,  0x7FFFFFFF ); /*  2,147,483,647 */
					xfput_uint32( file,  0x7FFFFFFF ); /*  2,147,483,647 */
					xfput_int32(  file,  0x80000000 ); /* -2,147,483,648 */
					xfput_uint32( file,  0x80000000 ); /*  2,147,483,648 */
					xfput_int32(  file,          -1 ); /*  4,294,967,295 */
					xfput_uint32( file,  0xFFFFFFFF ); /*  4,294,967,295 */
					xfclose(file);

					file = xfopen("test.1.bin", "rb"); if ( ! file ) ERROR;
					ivalue = xfget_int8(   file ); if ( ivalue !=        -128 ) ERROR;
					uvalue = xfget_uint8(  file ); if ( uvalue !=         128 ) ERROR;
					ivalue = xfget_int8(   file ); if ( ivalue !=        -127 ) ERROR;
					uvalue = xfget_uint8(  file ); if ( uvalue !=         129 ) ERROR;
					ivalue = xfget_int8(   file ); if ( ivalue !=           0 ) ERROR;
					uvalue = xfget_uint8(  file ); if ( uvalue !=           0 ) ERROR;
					ivalue = xfget_int8(   file ); if ( ivalue !=         127 ) ERROR;
					uvalue = xfget_uint8(  file ); if ( uvalue !=         127 ) ERROR;
					ivalue = xfget_int8(   file ); if ( ivalue !=        -128 ) ERROR;
					uvalue = xfget_uint8(  file ); if ( uvalue !=         128 ) ERROR;
					ivalue = xfget_int8(   file ); if ( ivalue !=          -1 ) ERROR;
					uvalue = xfget_uint8(  file ); if ( uvalue !=         255 ) ERROR;
					ivalue = xfget_int8(   file ); if ( ivalue !=           0 ) ERROR;
					uvalue = xfget_uint8(  file ); if ( uvalue !=           0 ) ERROR;
					ivalue = xfget_int16(  file ); if ( ivalue !=      -32768 ) ERROR;
					uvalue = xfget_uint16( file ); if ( uvalue !=       32768 ) ERROR;
					ivalue = xfget_int16(  file ); if ( ivalue !=      -32767 ) ERROR;
					uvalue = xfget_uint16( file ); if ( uvalue !=       32769 ) ERROR;
					ivalue = xfget_int16(  file ); if ( ivalue !=           0 ) ERROR;
					uvalue = xfget_uint16( file ); if ( uvalue !=           0 ) ERROR;
					ivalue = xfget_int16(  file ); if ( ivalue !=       32767 ) ERROR;
					uvalue = xfget_uint16( file ); if ( uvalue !=       32767 ) ERROR;
					ivalue = xfget_int16(  file ); if ( ivalue !=      -32768 ) ERROR;
					uvalue = xfget_uint16( file ); if ( uvalue !=       32768 ) ERROR;
					ivalue = xfget_int16(  file ); if ( ivalue !=          -1 ) ERROR;
					uvalue = xfget_uint16( file ); if ( uvalue !=       65535 ) ERROR;
					ivalue = xfget_int16(  file ); if ( ivalue !=           0 ) ERROR;
					uvalue = xfget_uint16( file ); if ( uvalue !=           0 ) ERROR;
					ilvalue = xfget_int32( file ); if ((ilvalue &  0xFFFFFFFF)
															   !=  0x80000000 
													   || ilvalue >= 0        ) ERROR;
					ulvalue = xfget_uint32(file ); if (ulvalue !=  0x80000000 ) ERROR;
					ilvalue = xfget_int32( file ); if ((ilvalue &  0xFFFFFFFF)
															   !=  0x80000001 
													   || ilvalue >= 0        ) ERROR;
					ulvalue = xfget_uint32(file ); if (ulvalue !=  0x80000001 ) ERROR;
					ilvalue = xfget_int32( file ); if (ilvalue !=           0 ) ERROR;
					ulvalue = xfget_uint32(file ); if (ulvalue !=           0 ) ERROR;
					ilvalue = xfget_int32( file ); if (ilvalue !=           1 ) ERROR;
					ulvalue = xfget_uint32(file ); if (ulvalue !=           1 ) ERROR;
					ilvalue = xfget_int32( file ); if (ilvalue !=         256 ) ERROR;
					ulvalue = xfget_uint32(file ); if (ulvalue !=         256 ) ERROR;
					ilvalue = xfget_int32( file ); if (ilvalue !=       65536 ) ERROR;
					ulvalue = xfget_uint32(file ); if (ulvalue !=       65536 ) ERROR;
					ilvalue = xfget_int32( file ); if (ilvalue !=    16777216 ) ERROR;
					ulvalue = xfget_uint32(file ); if (ulvalue !=    16777216 ) ERROR;
					ilvalue = xfget_int32( file ); if (ilvalue !=  2147483647 ) ERROR;
					ulvalue = xfget_uint32(file ); if (ulvalue !=  2147483647 ) ERROR;
					ilvalue = xfget_int32( file ); if ((ilvalue &  0xFFFFFFFF)
															   !=  0x80000000 
													   || ilvalue >= 0        ) ERROR;
					ulvalue = xfget_uint32(file ); if (ulvalue !=  0x80000000 ) ERROR;
					ilvalue = xfget_int32( file ); if (ilvalue !=          -1 ) ERROR;
					ulvalue = xfget_uint32(file ); if (ulvalue !=  0xFFFFFFFF ) ERROR;
					xfclose(file);
					break;

#define T_TEMP_FILENAME(name,temp) \
					if (strcmp(temp, temp_filename(name))) ERROR;	\
					file = xfopen(temp, "w"); if ( ! file ) ERROR;	\
					fputs("hello", file);	\
					xfclose(file);
					
		case 'G':	T_TEMP_FILENAME("test.1.c",		"~$1$test.1.c");
					T_TEMP_FILENAME("test.1.c",		"~$2$test.1.c");
					T_TEMP_FILENAME("test.2.c",		"~$3$test.2.c");
					T_TEMP_FILENAME("test.x1\\x.c",	"test.x1\\~$4$x.c");
					break;

		case 'H':	/* without existing target file */
					remove("test.1.bin");
					file = xfopen_atomic("test.1.bin", "wb"); 
					if ( ! file ) ERROR;
					xfput_strz( file, "123" );
					xfclose(file);

					/* with existing target file */
					file = xfopen_atomic("test.1.bin", "wb"); 
					if ( ! file ) ERROR;
					xfput_strz( file, "123" );
					xfclose(file);

					memset(buffer, 0, sizeof(buffer));
					file = xfopen_atomic("test.1.bin", "rb"); 
					if ( ! file ) ERROR;
					xfget_chars( file, buffer, 3 );
					xfclose(file);
					if (memcmp(buffer, "123", 3)) ERROR;
					break;
					
		case 'I':	remove("test.1.bin");
					file = xfopen_atomic("test.1.bin", "wb"); 
					if ( ! file ) ERROR;
					xfput_strz( file, "123" );
					break;
					
		case 'J':	remove("test.1.bin");
					file = xfopen_atomic("test.1.bin", "wb"); 
					if ( ! file ) ERROR;
					xfput_strz( file, "123" );
					xfclose_remove( file );
					break;
					
	}

	return 0;
}
END

system($compile) and die "compile failed: $compile\n";

t_capture("./test 0", "", "Error: cannot read file 'test.1xxxx.bin'\n", 1);
t_capture("./test 1", "", "Error: cannot write file 'x/x/x/x/test.1.bin'\n", 1);
t_capture("./test 2", "", "", 0); is read_binfile("test.1.bin"), "";
t_capture("./test 4", "", "", 0); is read_binfile("test.1.bin"), "1234";
t_capture("./test 5", "", "Error: cannot write file 'test.1.bin'\n", 1);
t_capture("./test 6", "", "Error: cannot read file 'test.1.bin'\n", 1);
t_capture("./test 7", "", "", 0); is read_binfile("test.1.bin"), "1234123";
t_capture("./test 8", "", "Error: cannot read file 'test.1.bin'\n", 1);
t_capture("./test 9", "", "", 0); is read_binfile("test.1.bin"), "1234abc";
t_capture("./test A", "", "Error: cannot read file 'test.1.bin'\n", 1);
t_capture("./test B", "", "", 0); is read_binfile("test.1.bin"), "\0\1\2\3";
t_capture("./test C", "", "", 0); is read_binfile("test.1.bin"), 
									pack("C",   0)."".
									pack("C",   4)."1234".
									pack("C",  11)."hello world".
									pack("v",   0)."".
									pack("v", 256).("1234567890" x 25)."123456".
									pack("v",  11)."hello world";
t_capture("./test D", "", "Error: cannot write file 'test.1.bin'\n", 1);
t_capture("./test E", "", "Error: cannot write file 'test.1.bin'\n", 1);
t_capture("./test F", "", "", 0); is read_binfile("test.1.bin"), 
									pack("C*", 
										 128, 128, 129, 129, 0, 0, 127, 127, 
										 128, 128, 255, 255, 0, 0).
									pack("v*",
										 32768, 32768, 32769, 32769, 0, 0,
										 32767, 32767, 32768, 32768, 
										 65535, 65535, 0, 0).
									pack("V*",
									     2147483648, 2147483648, 
										 2147483649, 2147483649, 0, 0, 1, 1,
										 256, 256, 65536, 65536,
										 16777216, 16777216, 
										 2147483647, 2147483647,
										 2147483648, 2147483648,
										 4294967295, 4294967295);
t_capture("./test G", "", "", 0); 
	ok ! -f '~$1$test.1.c';
	ok ! -f '~$2$test.1.c';
	ok ! -f '~$3$test.2.c';
	ok ! -f 'test.x1\\~$4$x.c';
t_capture("./test H", "", "", 0); is read_binfile("test.1.bin"), "123";
t_capture("./test I", "", "", 0); 
	ok ! -f 'test.bin';
	ok ! -f '~$1$test.bin';
	ok ! -f '~$2$test.bin';
t_capture("./test J", "", "", 0); 
	ok ! -f 'test.bin';
	ok ! -f '~$1$test.bin';
	ok ! -f '~$2$test.bin';

#------------------------------------------------------------------------------
# order of execution of fini() actions
write_file("test.c", <<'END');
#include "fileutil.h"
#include "init.h"

#define ERROR die("Test failed at line %d\n", __LINE__)

FILE *file;

DEFINE_init() { }
DEFINE_fini() 
{
	assert(file);
	xfclose(file);	/* dummy, file is closed by class atexit() */
}

int main()
{
	/* call main fini() after fileutil fini() */
	init();	
	file = xfopen("test.1.bin", "wb"); assert(file);
	
	xfput_strz( file, "123" );
	
	return 0;
}
END

system($compile) and die "compile failed: $compile\n";

t_capture("./test", "", "", 0); is read_binfile("test.1.bin"), "123";

#------------------------------------------------------------------------------
# cleanup and exit
remove_tree(<test.x*>);
unlink <test.*>;
done_testing;

#------------------------------------------------------------------------------
# util
sub t_capture {
	my($cmd, $exp_out, $exp_err, $exp_exit) = @_;
	my $line = "[line ".((caller)[2])."]";
	ok 1, "$line command: $cmd";
	
	my($out, $err, $exit) = capture { system $cmd; };
	eq_or_diff_text $out, $exp_out, "$line out";
	eq_or_diff_text $err, $exp_err, "$line err";
	ok !!$exit == !!$exp_exit, "$line exit";
}

sub read_binfile { scalar(read_file($_[0], { binmode => ':raw' })) }
