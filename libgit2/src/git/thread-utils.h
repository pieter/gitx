#ifndef INCLUDE_git_thread_utils_h__
#define INCLUDE_git_thread_utils_h__
#include "common.h"
/*
 * How TLS works is compiler+platform dependant
 * Sources: http://en.wikipedia.org/wiki/Thread-Specific_Storage
 *          http://predef.sourceforge.net/precomp.html
 */
#define GIT_HAS_TLS 1
#if defined(__APPLE__)
# define GIT_PTHREAD_TLS /* nothing: Darwin doesn't support tls, even with GNUC */
#elif defined(__GNUC__) || defined(__SUNPRO_C) || defined(__SUNPRO_CC) || \
	defined(__xlc__) || defined(__xlC__)
# define GIT_TLS __thread
#elif defined(__INTEL_COMPILER)
# if defined(_WIN32) || defined(_WIN32_CE)
#  define GIT_TLS __declspec(thread)
# else
#  define GIT_TLS __thread
# endif
#elif defined(_WIN32) || defined(_WIN32_CE) || defined(__BORLANDC__)
# define GIT_TLS __declspec(thread)
#else
# undef GIT_HAS_TLS
# define GIT_PTHREAD_TLS /* nothing: tls vars are thread-global */
#endif

#if defined(GIT_PTHREAD_TLS)
#include <pthread.h>
GIT_EXTERN(int) git_tls_get_int(pthread_key_t key);
GIT_EXTERN(void) git_tls_set_int(pthread_key_t key, int value);
#endif

/* sparse doesn't grok thread-local variables */
#ifdef SPARSE_IS_RUNNING
# undef GIT_HAS_TLS
# undef GIT_TLS
# define GIT_TLS
#endif

#endif /* INCLUDE_git_thread_utils_h__ */
