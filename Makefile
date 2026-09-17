# Delegate all rules to sub directories.

Makefile:;

.DEFAULT_GOAL := .DEFAULT

.PHONY: %

notice:
	$(MAKE) -C pg_blackboxdb_gw notice

check-no-distributed:
	$(MAKE) -C pg_blackboxdb_core check
	$(MAKE) -C pg_blackboxdb check

install-no-distributed: install-blackboxdb

install-blackboxdb:
	$(MAKE) -C pg_blackboxdb_core install
	$(MAKE) -C pg_blackboxdb install
	$(MAKE) -C pg_blackboxdb_extended_rum install

.DEFAULT:
	$(MAKE) -C pg_blackboxdb_core
	$(MAKE) -C pg_blackboxdb
	$(MAKE) -C pg_blackboxdb_extended_rum
	$(MAKE) -C internal/pg_blackboxdb_distributed

%:
	$(MAKE) -C pg_blackboxdb_core $@
	$(MAKE) -C pg_blackboxdb $@
	$(MAKE) -C pg_blackboxdb_extended_rum $@
	$(MAKE) -C internal/pg_blackboxdb_distributed $@