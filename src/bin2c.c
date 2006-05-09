/* Rob's lua bin2c
 * This program is not disimilar to the one in the original Lua distribution, however,
 * it can perform zlib compression on the data first.
 */

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>

#ifdef COLLOQUY_ZLIB
#include <zlib.h>
#endif

int main( int argc, char ** argv ) {
  FILE * input;
  unsigned long size, csize, i, n = 0;
  unsigned char * data, * cdata;
  int usezlib = 0;

#ifdef COLLOQUY_ZLIB
  usezlib = 1;
#else
  usezlib = 0;
#endif

  if ( argc < 2 ) {
    fprintf( stderr, "Usage: bin2c <input> [--no-zlib] > output\n" );
    exit( 1 );
  }

  if ( (input = fopen( argv[1], "rb" )) == NULL) {
    fprintf(stderr, "Unable to open input file '%s'\n", argv[1]);
    exit( 2 );
  }

  if ( fseek( input, 0, SEEK_END ) != 0 ) {
    fprintf( stderr, "Unable to seek to end of file\n" );
    fclose( input );
    exit( 3 );
  }

  if (argc > 2 && !(strcmp( argv[2], "--no-zlib" ) ) )
    usezlib = 0;

  size = ftell( input );
  fseek( input, 0, SEEK_SET );

  data = ( unsigned char * ) malloc( size );
  cdata = ( unsigned char * ) malloc( size );
  
  fread( data, size, 1, input );
  fclose( input );

  csize = size;
#ifdef COLLOQUY_ZLIB
  if ( usezlib )
    compress2( cdata, &csize, data, size, 9 );
  else
    memcpy( cdata, data, size );
#else
  memcpy( cdata, data, size );
#endif

  printf( "{\nstatic unsigned char __LUA_CDATA[] = {\n" );
  for ( i = 0; i <= csize; i ++ ) {
    printf( "%3d, ", cdata[i] );
    if ( n++ == 20) {
      putchar( '\n' );
      n = 0;
    }
  }

  printf( "\n};\n\n" );
#ifdef COLLOQUY_ZLIB
  if ( usezlib ) {
    printf( "unsigned char *__LUA_DATA = (unsigned char*)malloc(%d);\n", size );
    printf( "unsigned long dsize = %d;\n", size );
    printf( "uncompress( __LUA_DATA, &dsize, __LUA_CDATA, %d );\n", csize );
    printf( "lua_dobuffer( L, (const char *)__LUA_DATA, %d, \"%s\" );\n", size, argv[1] );
    printf( "free(__LUA_DATA);\n" );
  } else
    printf( "lua_dobuffer( L, (const char *)__LUA_CDATA, %d, \"%s\" );\n", size, argv[1] );
#else
  printf( "lua_dobuffer( L, (const char *)__LUA_CDATA, %d, \"%s\" );\n", size, argv[1] );
#endif
  printf( "}\n");
  return 0;
}
