#include <stdlib.h>
#include <string.h>
#include <lua.h>

#include <sys/time.h>
#include <time.h>

static void
_my_strncat( char** buffer, int* bufferlen, const char * item, int itemlen )
{
  char *p;

  if( strlen(*buffer) + itemlen >= *bufferlen ) {
    *buffer = realloc( *buffer, (*bufferlen)+itemlen+1024 );
    *bufferlen += itemlen+1024;
  }
  p=*buffer;
  while( *p ) {
    p++;
  }
  
  while( itemlen-- ) {
    *(p++) = *(item++);
  }
  *p=0;
}

#define safencat(X,L) _my_strncat( &buffer, &bufferlen, X, L )
#define safecat(X) safencat(X,strlen(X))

/* If we ever need more spaces than that, I'm a monkey's uncle */
static const char * 
SPACES = "                                                                       ";

#define nextloop ++Text; ++linelen; if( linelen == wrapwidth ) newline=1; continue

static void
_my_word_examine( const char * Text, int * len, int * important )
{
  const char *s=Text;
  *important = 0;
  *len = 0;
  while( *s && *s != ' ' ) {
    if( *s == '@' || *s == '/' )
      *important=1;
    s++;
  }
  *len = s-Text;
}

#define EXAMINE_WORD _my_word_examine( Text, &w_len, &w_imp )

#define SPLIT_WORD w_len=wrapwidth-linelen; safencat(Text,w_len); Text+=w_len; newline=1; continue

#define AVAIL_SPACE (wrapwidth-linelen)

char *
WordWrap( const char * Text, int Indent, 
          const char * Prefix, const int wrapwidth, const int splitforce )
{
  static char * buffer = NULL;
  static int bufferlen = 0;
    
  int linelen = 0;
  int newline = 0;
  int w_len, w_imp, w_max;;
  
  if( buffer == NULL ) {
    buffer = (char*)(malloc( 1024 ));
    bufferlen=1024;
  }
  
  *buffer = 0;
  
  /* Handle special cases */
  if( Indent != -1 ) {
    safencat( "\r", 1 );
  }
  
  
  if( Prefix != NULL && *Prefix ) {
    safecat( Prefix );
    safencat( " ", 1 );
  }
  
  if( Indent == -1 ) {
    safecat( Text );
    return buffer;
  }
  
  /* End of special cases */
  
  if( strlen(Text) + strlen(buffer) <= wrapwidth ) {
    safecat (Text);
    return buffer;
  }
  
  /* Okay, we have to actually make an effort to wordwrap... */
  
  w_max = wrapwidth-( ( Prefix?strlen( Prefix ):0 ) + Indent);
  
  linelen = strlen(buffer)-1; /* Start as we mean to go on... (minus the \r)*/
  while( *Text ) {
    /* We have a char *Text */
    if (newline) {
      /* Remove any waiting spaces */
      {
        char * b = buffer;
        while( *b ) { ++b; } /* Scan to end of buffer */
        while( *b == ' ' ) { --b; } /* Trim spaces */
        *(b+1) = 0; /* Terminate it before the spaces */
      }
      /* Skip any new spaces... */
      while( *Text && *Text == ' ' ) { 
        ++Text; 
      }
      if( *Text == 0 ) {
        /* We ran out of input trying to find the next starter */
        /* Therefore we skip this newline and break... */
        break;
      }
      safencat( "\n\r", 2 ); /* Lines appear to have to start with \r */
      if( Prefix != NULL && *Prefix) 
        safecat( Prefix );
      safencat( SPACES, Indent );
      linelen = (Prefix?strlen(Prefix):0)+Indent;
      newline = 0;
      
      continue;
    }
    if( *Text == ' ' || *Text == '\t' ) {
      safencat( Text, 1 );
      nextloop;
    }
    /* It's a character we're interested in... speculate... */
    EXAMINE_WORD;
    /* w_len is the words length, w_imp is its importance */
    if( (w_len+linelen) <= wrapwidth ) {
      safencat( Text, w_len );
      linelen += w_len;
      if( linelen == wrapwidth ) newline=1;
      Text += w_len;
      continue;
    }
    /* Okay, we can't fit the word on this line. */
    if( w_len <= w_max ) {
      /* Can be fitted, without wrapping, on the next line.
         At what threshold do we consider this bad? */
      if( (AVAIL_SPACE > splitforce) && !w_imp ) {
        /* Nope, we want to split... */
        SPLIT_WORD;
      }
      /* We want to wrap the word, so set newline and return */
      newline=1;
      continue; /* We're going to reconsider the word next time */
    }
    /* word is more than a line's space big, decision time.. */
    if( w_imp ) {
      /* word is 'important' so we want as much as possible together */
      if (AVAIL_SPACE >= splitforce) {
        SPLIT_WORD;
      }
      newline=1;
      continue;
    }
    /* word is not important, and too big, so just split it */
    SPLIT_WORD;
  }
  
  /* return -- regardless of the 'newline' settings */
  
  return buffer;
}

/* char *
WordWrap( const char * Text, int Indent, const char * Prefix )
*/

int
lua_wrap( lua_State *L )
{
  if( lua_gettop(L) < 5 ) {
    lua_error(L, "WordWrap(text,indent,prefix,wrapwidth,splitforce)" );
    return 0;
  }

  if( ! lua_isstring(L, 1) ) { 
    lua_error(L, "WordWrap(text,indent,prefix,wrapwidth,splitforce)" );
    return 0;
  }

  if( ! lua_isnumber(L, 2) ) { 
    lua_error(L, "WordWrap(text,indent,prefix,wrapwidth,splitforce)" );
    return 0;
  }

  if( ! lua_isstring(L, 3) ) { 
    lua_error(L, "WordWrap(text,indent,prefix,wrapwidth,splitforce)" );
    return 0;
  }

  if( ! lua_isnumber(L, 4) ) { 
    lua_error(L, "WordWrap(text,indent,prefix,wrapwidth,splitforce)" );
    return 0;
  }

  if( ! lua_isnumber(L, 5) ) { 
    lua_error(L, "WordWrap(text,indent,prefix,wrapwidth,splitforce)" );
    return 0;
  }

  {
    const char * Text = lua_tostring(L, 1);
    const int Indent = (int)(lua_tonumber(L, 2));
    const char * Prefix = lua_tostring(L, 3);
    const int wrapwidth = (int)(lua_tonumber(L,4));
    const int splitforce = (int)(lua_tonumber(L,5));

    char * wrapped = WordWrap( Text, Indent, Prefix, wrapwidth, splitforce );
    lua_settop(L, 0);
    lua_pushstring(L, wrapped);
    return 1;
  }
}

int lua_epoch_time( lua_State *L )
{
   lua_settop(L, 0);
   lua_pushnumber(L, time( NULL ) );
   return 1;
}

void
wrap_register( lua_State *L )
{
  lua_pushcclosure( L, lua_wrap, 0 );
  lua_setglobal( L, "WordWrap" );
  lua_pushcclosure( L, lua_epoch_time, 0 );
  lua_setglobal( L, "getSecs" );
}
