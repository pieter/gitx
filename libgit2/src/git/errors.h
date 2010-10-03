#ifndef INCLUDE_git_errors_h__
#define INCLUDE_git_errors_h__
/**
 * @file git/errors.h
 * @brief Git error handling routines and variables
 * @ingroup Git
 * @{
 */

#include "common.h"
#include "thread-utils.h"
GIT_BEGIN_DECL

/** The git errno. */
#ifndef GIT_PTHREAD_TLS
GIT_EXTERN(int) GIT_TLS git_errno;
#else
GIT_EXTERN(pthread_key_t) git_errno_key;
#define git_errno git_tls_get_int(git_errno_key)
#endif

/**
 * strerror() for the Git library
 * @param num The error code to explain
 * @return a string explaining the error code
 */
GIT_EXTERN(const char *) git_strerror(int num);
/** @} */
GIT_END_DECL
#endif
