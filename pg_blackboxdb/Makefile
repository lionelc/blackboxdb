EXTENSION = blackboxdb
MODULE_big = pg_$(EXTENSION)

SQL_DEPDIR=.deps/sql
SQL_BUILDDIR=build/sql

template_sql_files = $(wildcard sql/*.sql)
generated_sql_files = $(patsubst %,build/%,$(template_sql_files))
DATA_built = $(generated_sql_files)
sql_file_inputs = $(wildcard sql/**/*.sql)

BUILD_SCRIPT_DIR = ../
OSS_SRC_DIR = ../
OSS_COMMON_SQL_HEADER = $(wildcard $(OSS_SRC_DIR)/common_header.sql)

# Prefixes
API_GUC_PREFIX=blackboxdb
API_GUC_PREFIX_V2=blackboxdb
EXTENSION_OBJECT_PREFIX=blackboxdb

# Schema Names
API_CATALOG_SCHEMA_NAME=blackboxdb_api_catalog
API_CATALOG_SCHEMA_NAME_V2=blackboxdb_api_catalog
API_DATA_SCHEMA_NAME=blackboxdb_data
API_SCHEMA_INTERNAL_NAME=blackboxdb_api_internal
API_SCHEMA_INTERNAL_NAME_V2=blackboxdb_api_internal
API_SCHEMA_NAME=blackboxdb_api
API_SCHEMA_NAME_V2=blackboxdb_api
CORE_SCHEMA_NAME=blackboxdb_core
POSTGIS_SCHEMA_NAME=public
ENABLE_RBAC_SCHEMA=1

# Built-in roles
API_ADMIN_ROLE=blackboxdb_admin_role
API_BG_WORKER_ROLE=blackboxdb_bg_worker_role
API_READONLY_ROLE=blackboxdb_readonly_role

# TODO: Need to remove this with PG16 and expose only valid exports
ALLOW_DEFAULT_VISIBILITY=yes

USE_BLACKBOXDB_CORE = 1
include $(OSS_SRC_DIR)/Makefile.cflags
SOURCES = $(wildcard src/*.c) $(wildcard src/**/*.c)

OBJS = $(patsubst %.c,%.o,$(SOURCES))

# Update to notify roaring to use the C atomics implementation (as opposed to c++): See roaring.h CROARING_ATOMIC_IMPL_C
PG_CFLAGS += -DCROARING_ATOMIC_IMPL=3
PG_CPPFLAGS += -DCROARING_ATOMIC_IMPL=3

DEBUG ?= no
ifeq ($(DEBUG),yes)
  PG_CPPFLAGS += -ggdb -O0 -g
  PG_CFLAGS += -ggdb -O0 -g
  override CFLAGS += -O0
  override CPPFLAGS += -O0
endif

SHLIB_LINK = $(libpq)

include $(OSS_SRC_DIR)/Makefile.global

clean-sql:
	rm -rf .deps/ build/

check:
	$(MAKE) -C src/test all

installcheck:
	$(MAKE) -C src/test installcheck

check-extended-rum:
	$(MAKE) -C src/test/extended_rum_tests all

check-minimal:
	$(MAKE) -C src/test/regress check-minimal

check-blackboxdb-minimal: check-minimal

check-extended-rum-minimal:
	$(MAKE) -C src/test/extended_rum_tests check-minimal

check-extended-rum-recovery:
	$(MAKE) -C src/test/extended_rum_recovery_tests all

check-isolation:
	$(MAKE) -C src/test/regress check-isolation

check-isolation-minimal:
	$(MAKE) -C src/test/regress check-isolation-minimal

check-valgrind:
	mkdir -p $(CURDIR)/src/test/regress/log/
	echo >$(CURDIR)/src/test/regress/log/pglog.log
	$(OSS_SRC_DIR)/scripts/start_oss_server.sh -c -u "" -v -p 58070 -f $(CURDIR)/src/test/regress/regression_opts.conf -l $(CURDIR)/src/test/regress/log/pglog.log
	$(MAKE) INSTALL_PG_PORT=58070 -C src/test installcheck
	$(OSS_SRC_DIR)/scripts/start_oss_server.sh -s -v

check-start-oss-server:
	mkdir -p $(CURDIR)/src/test/regress/log/
	echo >$(CURDIR)/src/test/regress/log/pglog.log
	$(OSS_SRC_DIR)/scripts/start_oss_server.sh -c -u "" -p 58070 -f $(CURDIR)/src/test/regress/regression_opts.conf -l $(CURDIR)/src/test/regress/log/pglog.log
	$(MAKE) INSTALL_PG_PORT=58070 -C src/test installcheck

citus-indent:
	citus_indent

analysis: citus-indent

check-regress:
	$(MAKE) -C src/test check-regress

# Before installing, trim any files extension*.sql files in the target install directory
install: trim_installed_data_files

trim_installed_data_files:
	rm -f $(DESTDIR)$(datadir)/$(datamoduledir)/$(EXTENSION)--*.sql

build-sql: $(generated_sql_files)

$(generated_sql_files): build/%: %
	@mkdir -p $(SQL_DEPDIR) $(SQL_BUILDDIR)
	@# -MF is used to store dependency files(.Po) in another directory for separation
	@# -MT is used to change the target of the rule emitted by dependency generation.
	@# -P is used to inhibit generation of linemarkers in the output from the preprocessor.
	@# -undef is used to not predefine any system-specific or GCC-specific macros.
	@# -imacros is used to specify a file that defines macros for the global context but its output is thrown away.
	@# `man cpp` for further information
	cpp -undef -w $(SQL_DEFINES) -imacros $(OSS_COMMON_SQL_HEADER) -P -MMD -MP -MF$(SQL_DEPDIR)/$(*F).Po -MT$@ $< > $@

include $(OSS_SRC_DIR)/Makefile.versions

src/blackboxdb_extension_version.o : build/include/metadata/blackboxdb_extension_version.h