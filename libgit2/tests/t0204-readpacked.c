#include "test_lib.h"
#include <git/odb.h>
#include "fileops.h"

#include "object-data.h"
#include "pack-data.h"

static char *odb_dir = "test-objects";
static char *odb_pack_dir = "test-objects/pack";

typedef struct {
	char *id;     /* oid to read from pack         */
	git_obj *obj; /* the corresponding object data */
} object_data;

static object_data objects[] = {
	{ "3d7f8a6af076c8c3f20071a8935cdbe8228594d1", &commit_obj    },
	{ "dff2da90b254e1beb889d1f1f1288be1803782df", &tree_obj      },
	{ "09d373e1dfdc16b129ceec6dd649739911541e05", &tag_obj       },
	{ "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391", &zero_obj      },
	{ "8b137891791fe96927ad78e64b0aad7bded08bdc", &one_obj       },
	{ "78981922613b2afb6025042ff6bd878ac1994e85", &two_obj       },
	{ "fd8430bc864cfcd5f10e5590f8a447e01b942bfe", &some_obj      },
	{ "a2f9e3ffbc8296c55df56dbabef9f4c8e2cffbeb", &commit_v2_obj },
	{ "ac02680885e0b2d6c6a13a9f82746840d357322f", &tree_v2_obj   },
	{ "3fb360e0ef6099c791414204843a8a405c6db2d6", &some_v2_obj   },
	{ NULL,                                       NULL           }
};

/* oid's of "fencepost" missing objects */
static char *missing[] = {
	"09d373e1dfdc16b129ceec6dd649739911541e04",
	"3d7f8a6af076c8c3f20071a8935cdbe8228594d0",
	"3fb360e0ef6099c791414204843a8a405c6db2d5",
	"78981922613b2afb6025042ff6bd878ac1994e84",
	"8b137891791fe96927ad78e64b0aad7bded08bdb",
	"a2f9e3ffbc8296c55df56dbabef9f4c8e2cffbea",
	"ac02680885e0b2d6c6a13a9f82746840d357322e",
	"dff2da90b254e1beb889d1f1f1288be1803782de",
	"e69de29bb2d1d6434b8b29ae775ad8c2e48c5390",
	"fd8430bc864cfcd5f10e5590f8a447e01b942bfd",
	"fd8430bc864cfcd5f10e5590f8a447e01b942bff",
	NULL
};

typedef struct {
	char *name;      /* pack file name minus suffix */
	void *idx_data;  /* content of '.idx' file      */
	size_t idx_len;  /* length of '.idx' content    */
	void *pack_data; /* content of '.pack' file     */
	size_t pack_len; /* length of '.pack' content   */
} pack_data;

/*
 * pack-0d993cfb6f9dc386cc06f99a2d0995fa59b49f7a.{idx,pack}
 * --- version 2 index, 32-bit offsets; ref delta objects ---
*/
static pack_data v2_32_ref = {
	"pack-0d993cfb6f9dc386cc06f99a2d0995fa59b49f7a",
	v2_32_ref_idx,
	sizeof(v2_32_ref_idx),
	v2_32_ref_pack,
	sizeof(v2_32_ref_pack)
};

/*
 * pack-0d993cfb6f9dc386cc06f99a2d0995fa59b49f7a.{idx,pack}
 * --- version 1 index, 32-bit offsets; ofs delta objects ---
*/
static pack_data v1_32_ofs = {
	"pack-0d993cfb6f9dc386cc06f99a2d0995fa59b49f7a",
	v1_32_ofs_idx,
	sizeof(v1_32_ofs_idx),
	v1_32_ofs_pack,
	sizeof(v1_32_ofs_pack)
};

/*
 * pack-0d993cfb6f9dc386cc06f99a2d0995fa59b49f7a.{idx,pack}
 * --- version 2 index, some 64-bit offsets; ofs delta objects ---
*/
static pack_data v2_64_ofs = {
	"pack-0d993cfb6f9dc386cc06f99a2d0995fa59b49f7a",
	v2_64_ofs_idx,
	sizeof(v2_64_ofs_idx),
	v2_64_ofs_pack,
	sizeof(v2_64_ofs_pack)
};

static int create_dir(char *dir)
{
	if (gitfo_mkdir(dir, 0755) < 0) {
		int err = errno;
		fprintf(stderr, "can't make directory \"%s\"", dir);
		if (err == EEXIST)
			fprintf(stderr, " (already exists)");
		fprintf(stderr, "\n");
		return -1;
	}
	return 0;
}

static int write_data(char *file, void *data, size_t len)
{
	git_file fd;
	int ret;

	if ((fd = gitfo_creat(file, S_IREAD | S_IWRITE)) < 0)
		return -1;
	ret = gitfo_write(fd, data, len);
	gitfo_close(fd);

	return ret;
}

static int write_pack_data(char *dir, pack_data *p)
{
	char pf[1024];
	int r;

	r = snprintf(pf, sizeof(pf), "%s/%s.idx", dir, p->name);
	if (r < 0 || ((size_t) r) >= sizeof(pf))
		return -1;
	if (write_data(pf, p->idx_data, p->idx_len) < 0)
	       return -1;

	r = snprintf(pf, sizeof(pf), "%s/%s.pack", dir, p->name);
	if (r < 0 || ((size_t) r) >= sizeof(pf))
		return -1;
	if (write_data(pf, p->pack_data, p->pack_len) < 0)
	       return -1;

	return 0;
}

static int create_odb(pack_data *p)
{
	if (create_dir(odb_dir) < 0)
		return -1;
	if (create_dir(odb_pack_dir) < 0)
		return -1;
	if (write_pack_data(odb_pack_dir, p) < 0)
		return -1;
	return 0;
}

static int remove_pack_files(char *dir, pack_data *p)
{
	char pf[1024];
	int r;

	r = snprintf(pf, sizeof(pf), "%s/%s.idx", dir, p->name);
	if (r < 0 || ((size_t) r) >= sizeof(pf))
		return -1;
	if (gitfo_unlink(pf) < 0) {
		fprintf(stderr, "can't delete file \"%s\"\n", pf);
		return -1;
	}

	r = snprintf(pf, sizeof(pf), "%s/%s.pack", dir, p->name);
	if (r < 0 || ((size_t) r) >= sizeof(pf))
		return -1;
	if (gitfo_unlink(pf) < 0) {
		fprintf(stderr, "can't delete file \"%s\"\n", pf);
		return -1;
	}

	return 0;
}

static int remove_odb(pack_data *p)
{
	if (remove_pack_files(odb_pack_dir, p) < 0)
		return -1;

	if ((gitfo_rmdir(odb_pack_dir) < 0) && (errno != ENOTEMPTY)) {
		fprintf(stderr, "can't remove directory \"%s\"\n", odb_pack_dir);
		return -1;
	}

	if (gitfo_rmdir(odb_dir) < 0) {
		fprintf(stderr, "can't remove directory \"%s\"\n", odb_dir);
		return -1;
	}

	return 0;
}

static int cmp_objects(git_obj *o1, git_obj *o2)
{
	if (o1->type != o2->type)
		return -1;
	if (o1->len != o2->len)
		return -1;
	if ((o1->len > 0) && (memcmp(o1->data, o2->data, o1->len) != 0))
		return -1;
	return 0;
}

BEGIN_TEST(read_pack__v2_32_ref)
	git_odb *db;
	git_oid id;
	git_obj obj;
	size_t i;

	must_pass(create_odb(&v2_32_ref));
	must_pass(git_odb_open(&db, odb_dir));

	for (i = 0; objects[i].id; i++) {
		must_pass(git_oid_mkstr(&id, objects[i].id));

		must_pass(git_odb__read_packed(&obj, db, &id));
		must_pass(cmp_objects(&obj, objects[i].obj));

		git_obj_close(&obj);
	}

	git_odb_close(db);
	must_pass(remove_odb(&v2_32_ref));
END_TEST

BEGIN_TEST(read_pack__v2_32_ref__missing)
	git_odb *db;
	git_oid id;
	git_obj obj;
	size_t i;

	must_pass(create_odb(&v2_32_ref));
	must_pass(git_odb_open(&db, odb_dir));

	for (i = 0; missing[i]; i++) {
		must_pass(git_oid_mkstr(&id, missing[i]));

		must_fail(git_odb__read_packed(&obj, db, &id));

		git_obj_close(&obj);
	}

	git_odb_close(db);
	must_pass(remove_odb(&v2_32_ref));
END_TEST

BEGIN_TEST(read_pack__v1_32_ofs)
	git_odb *db;
	git_oid id;
	git_obj obj;
	size_t i;

	must_pass(create_odb(&v1_32_ofs));
	must_pass(git_odb_open(&db, odb_dir));

	for (i = 0; objects[i].id; i++) {
		must_pass(git_oid_mkstr(&id, objects[i].id));

		must_pass(git_odb__read_packed(&obj, db, &id));
		must_pass(cmp_objects(&obj, objects[i].obj));

		git_obj_close(&obj);
	}

	git_odb_close(db);
	must_pass(remove_odb(&v1_32_ofs));
END_TEST

BEGIN_TEST(read_pack__v1_32_ofs__missing)
	git_odb *db;
	git_oid id;
	git_obj obj;
	size_t i;

	must_pass(create_odb(&v1_32_ofs));
	must_pass(git_odb_open(&db, odb_dir));

	for (i = 0; missing[i]; i++) {
		must_pass(git_oid_mkstr(&id, missing[i]));

		must_fail(git_odb__read_packed(&obj, db, &id));

		git_obj_close(&obj);
	}

	git_odb_close(db);
	must_pass(remove_odb(&v1_32_ofs));
END_TEST

BEGIN_TEST(read_pack__v2_64_ofs)
	git_odb *db;
	git_oid id;
	git_obj obj;
	size_t i;

	must_pass(create_odb(&v2_64_ofs));
	must_pass(git_odb_open(&db, odb_dir));

	for (i = 0; objects[i].id; i++) {
		must_pass(git_oid_mkstr(&id, objects[i].id));

		must_pass(git_odb__read_packed(&obj, db, &id));
		must_pass(cmp_objects(&obj, objects[i].obj));

		git_obj_close(&obj);
	}

	git_odb_close(db);
	must_pass(remove_odb(&v2_64_ofs));
END_TEST

BEGIN_TEST(read_pack__v2_64_ofs__missing)
	git_odb *db;
	git_oid id;
	git_obj obj;
	size_t i;

	must_pass(create_odb(&v2_64_ofs));
	must_pass(git_odb_open(&db, odb_dir));

	for (i = 0; missing[i]; i++) {
		must_pass(git_oid_mkstr(&id, missing[i]));

		must_fail(git_odb__read_packed(&obj, db, &id));

		git_obj_close(&obj);
	}

	git_odb_close(db);
	must_pass(remove_odb(&v2_64_ofs));
END_TEST
