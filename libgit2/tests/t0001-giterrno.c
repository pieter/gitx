#include "test_lib.h"
#include <errors.h>

BEGIN_TEST(errno_setting)
	git_int_error(20);
	must_be_true(git_errno == 20);
END_TEST

void *start_test(void *arg)
{
	int n = (int)arg;
	git_int_error(n);
	must_be_true(git_errno == n);

	return NULL;
}
BEGIN_TEST(errno_multiple)
	git_int_error(1);
	pthread_t threads[20];
	int i;

	for (i = 0; i < 20; ++i)
		pthread_create(threads + i, NULL, start_test, (void *)i);

	for (i = 0; i < 20; ++i)
		pthread_join(threads[i], NULL);

	must_be_true(git_errno == 1);
END_TEST