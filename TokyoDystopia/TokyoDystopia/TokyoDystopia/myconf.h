/*************************************************************************************************
 * System-dependent configurations of Tokyo Dystopia
 *                                                               Copyright (C) 2007-2010 FAL Labs
 * This file is part of Tokyo Dystopia.
 * Tokyo Dystopia is free software; you can redistribute it and/or modify it under the terms of
 * the GNU Lesser General Public License as published by the Free Software Foundation; either
 * version 2.1 of the License or any later version.  Tokyo Dystopia is distributed in the hope
 * that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
 * License for more details.
 * You should have received a copy of the GNU Lesser General Public License along with Tokyo
 * Dystopia; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA 02111-1307 USA.
 *************************************************************************************************/


#ifndef _MYCONF_H                        // duplication check
#define _MYCONF_H



/*************************************************************************************************
 * system discrimination
 *************************************************************************************************/


#if defined(__linux__)

#define _SYS_LINUX_
#define TDSYSNAME   "Linux"

#elif defined(__FreeBSD__)

#define _SYS_FREEBSD_
#define TDSYSNAME   "FreeBSD"

#elif defined(__NetBSD__)

#define _SYS_NETBSD_
#define TDSYSNAME   "NetBSD"

#elif defined(__OpenBSD__)

#define _SYS_OPENBSD_
#define TDSYSNAME   "OpenBSD"

#elif defined(__sun__) || defined(__sun)

#define _SYS_SUNOS_
#define TDSYSNAME   "SunOS"

#elif defined(__hpux)

#define _SYS_HPUX_
#define TDSYSNAME   "HP-UX"

#elif defined(__osf)

#define _SYS_TRU64_
#define TDSYSNAME   "Tru64"

#elif defined(_AIX)

#define _SYS_AIX_
#define TDSYSNAME   "AIX"

#elif defined(__APPLE__) && defined(__MACH__)

#define _SYS_MACOSX_
#define TDSYSNAME   "Mac OS X"

#elif defined(_MSC_VER)

#define _SYS_MSVC_
#define TDSYSNAME   "Windows (VC++)"

#elif defined(_WIN32)

#define _SYS_MINGW_
#define TDSYSNAME   "Windows (MinGW)"

#elif defined(__CYGWIN__)

#define _SYS_CYGWIN_
#define TDSYSNAME   "Windows (Cygwin)"

#else

#define _SYS_GENERIC_
#define TDSYSNAME   "Generic"

#endif



/*************************************************************************************************
 * common settings
 *************************************************************************************************/


#if defined(NDEBUG)
#define TDDODEBUG(TD_expr) \
  do { \
  } while(false)
#else
#define TDDODEBUG(TD_expr) \
  do { \
    TD_expr; \
  } while(false)
#endif

#define TDSWAB16(TD_num) \
  ( \
   ((TD_num & 0x00ffU) << 8) | \
   ((TD_num & 0xff00U) >> 8) \
  )

#define TDSWAB32(TD_num) \
  ( \
   ((TD_num & 0x000000ffUL) << 24) | \
   ((TD_num & 0x0000ff00UL) << 8) | \
   ((TD_num & 0x00ff0000UL) >> 8) | \
   ((TD_num & 0xff000000UL) >> 24) \
  )

#define TDSWAB64(TD_num) \
  ( \
   ((TD_num & 0x00000000000000ffULL) << 56) | \
   ((TD_num & 0x000000000000ff00ULL) << 40) | \
   ((TD_num & 0x0000000000ff0000ULL) << 24) | \
   ((TD_num & 0x00000000ff000000ULL) << 8) | \
   ((TD_num & 0x000000ff00000000ULL) >> 8) | \
   ((TD_num & 0x0000ff0000000000ULL) >> 24) | \
   ((TD_num & 0x00ff000000000000ULL) >> 40) | \
   ((TD_num & 0xff00000000000000ULL) >> 56) \
  )

#if defined(_MYBIGEND) || defined(_MYSWAB)
#define TDBIGEND       1
#define TDHTOIS(TD_num)   TDSWAB16(TD_num)
#define TDHTOIL(TD_num)   TDSWAB32(TD_num)
#define TDHTOILL(TD_num)  TDSWAB64(TD_num)
#define TDITOHS(TD_num)   TDSWAB16(TD_num)
#define TDITOHL(TD_num)   TDSWAB32(TD_num)
#define TDITOHLL(TD_num)  TDSWAB64(TD_num)
#else
#define TDBIGEND       0
#define TDHTOIS(TD_num)   (TD_num)
#define TDHTOIL(TD_num)   (TD_num)
#define TDHTOILL(TD_num)  (TD_num)
#define TDITOHS(TD_num)   (TD_num)
#define TDITOHL(TD_num)   (TD_num)
#define TDITOHLL(TD_num)  (TD_num)
#endif



/*************************************************************************************************
 * general headers
 *************************************************************************************************/


#include <assert.h>
#include <ctype.h>
#include <errno.h>
#include <float.h>
#include <limits.h>
#include <locale.h>
#include <math.h>
#include <setjmp.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>
#include <time.h>

#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>

#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <sys/time.h>
#include <sys/times.h>
#include <fcntl.h>
#include <dirent.h>

#include <pthread.h>

#include <tcutil.h>
#include <tchdb.h>
#include <tcbdb.h>
#include <tcadb.h>



/*************************************************************************************************
 * miscellaneous hacks
 *************************************************************************************************/


#if defined(_MYNOZLIB)
#define HDBTDEFLATE    0
#define BDBTDEFLATE    0
#endif

#if defined(_MYNOBZIP)
#define HDBTBZIP       0
#define BDBTBZIP       0
#endif

int _td_dummyfunc(void);
int _td_dummyfuncv(int a, ...);



/*************************************************************************************************
 * notation of filesystems
 *************************************************************************************************/


#define MYPATHCHR       '/'
#define MYPATHSTR       "/"
#define MYEXTCHR        '.'
#define MYEXTSTR        "."
#define MYCDIRSTR       "."
#define MYPDIRSTR       ".."



/*************************************************************************************************
 * utilities for implementation
 *************************************************************************************************/


#define TDNUMBUFSIZ    32                // size of a buffer for a number

/* set a buffer for a variable length number */
#define TDSETVNUMBUF(TD_len, TD_buf, TD_num) \
  do { \
    int _TD_num = (TD_num); \
    if(_TD_num == 0){ \
      ((signed char *)(TD_buf))[0] = 0; \
      (TD_len) = 1; \
    } else { \
      (TD_len) = 0; \
      while(_TD_num > 0){ \
        int _TD_rem = _TD_num & 0x7f; \
        _TD_num >>= 7; \
        if(_TD_num > 0){ \
          ((signed char *)(TD_buf))[(TD_len)] = -_TD_rem - 1; \
        } else { \
          ((signed char *)(TD_buf))[(TD_len)] = _TD_rem; \
        } \
        (TD_len)++; \
      } \
    } \
  } while(false)

/* set a buffer for a variable length number of 64-bit */
#define TDSETVNUMBUF64(TD_len, TD_buf, TD_num) \
  do { \
    long long int _TD_num = (TD_num); \
    if(_TD_num == 0){ \
      ((signed char *)(TD_buf))[0] = 0; \
      (TD_len) = 1; \
    } else { \
      (TD_len) = 0; \
      while(_TD_num > 0){ \
        int _TD_rem = _TD_num & 0x7f; \
        _TD_num >>= 7; \
        if(_TD_num > 0){ \
          ((signed char *)(TD_buf))[(TD_len)] = -_TD_rem - 1; \
        } else { \
          ((signed char *)(TD_buf))[(TD_len)] = _TD_rem; \
        } \
        (TD_len)++; \
      } \
    } \
  } while(false)

/* read a variable length buffer */
#define TDREADVNUMBUF(TD_buf, TD_num, TD_step) \
  do { \
    TD_num = 0; \
    int _TD_base = 1; \
    int _TD_i = 0; \
    while(true){ \
      if(((signed char *)(TD_buf))[_TD_i] >= 0){ \
        TD_num += ((signed char *)(TD_buf))[_TD_i] * _TD_base; \
        break; \
      } \
      TD_num += _TD_base * (((signed char *)(TD_buf))[_TD_i] + 1) * -1; \
      _TD_base <<= 7; \
      _TD_i++; \
    } \
    (TD_step) = _TD_i + 1; \
  } while(false)

/* read a variable length buffer */
#define TDREADVNUMBUF64(TD_buf, TD_num, TD_step) \
  do { \
    TD_num = 0; \
    long long int _TD_base = 1; \
    int _TD_i = 0; \
    while(true){ \
      if(((signed char *)(TD_buf))[_TD_i] >= 0){ \
        TD_num += ((signed char *)(TD_buf))[_TD_i] * _TD_base; \
        break; \
      } \
      TD_num += _TD_base * (((signed char *)(TD_buf))[_TD_i] + 1) * -1; \
      _TD_base <<= 7; \
      _TD_i++; \
    } \
    (TD_step) = _TD_i + 1; \
  } while(false)



#endif                                   // duplication check


// END OF FILE
