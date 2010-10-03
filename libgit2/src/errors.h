#ifndef INCLUDE_errors_h__
#define INCLUDE_errors_h__
#include "git/errors.h"

/* convenience functions */
static inline int git_int_error(int code)
{
#ifdef GIT_PTHREAD_TLS
	git_tls_set_int(git_errno_key, code);
#else
	git_errno = code;
#endif
	return code;
}

static inline void *git_ptr_error(int code)
{
#ifdef GIT_PTHREAD_TLS
	git_tls_set_int(git_errno_key, code);
#else
	git_errno = code;
#endif
	return NULL;
}

#endif
