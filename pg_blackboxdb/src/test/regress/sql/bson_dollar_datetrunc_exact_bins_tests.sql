SET search_path TO blackboxdb_api, blackboxdb_core, blackboxdb_api_catalog;
SET blackboxdb.next_collection_id TO 26980000;
SET blackboxdb.next_collection_index_id TO 26980000;

-- $dateTrunc with a unit of a day or more, against MongoDB 8.0.32. Under
-- blackboxdb.enable_datetrunc_exact_bins the bins are counted on the local calendar of the
-- requested time zone with exact calendar arithmetic: before, day and week took the epoch of
-- age() (a month taken as 30 days, a year as 365.25), month, quarter and year rounded a
-- negative difference toward zero (dates before 2000), and every such unit binned the UTC
-- wall-clock time, so a date whose local date differs from its UTC date landed a bin off.
-- Every value with the flag on equals MongoDB 8.0.32's.
SELECT blackboxdb_api.insert_one('dtdb', 'dates', '{ "_id": 1, "ts": { "$date": "1969-12-31T18:30:00Z" } }');
SELECT blackboxdb_api.insert_one('dtdb', 'dates', '{ "_id": 2, "ts": { "$date": "1970-01-01T13:45:00Z" } }');
SELECT blackboxdb_api.insert_one('dtdb', 'dates', '{ "_id": 3, "ts": { "$date": "1970-01-02T04:59:59.999Z" } }');
SELECT blackboxdb_api.insert_one('dtdb', 'dates', '{ "_id": 4, "ts": { "$date": "1999-12-31T23:59:59.999Z" } }');
SELECT blackboxdb_api.insert_one('dtdb', 'dates', '{ "_id": 5, "ts": { "$date": "2000-01-01T00:00:00Z" } }');
SELECT blackboxdb_api.insert_one('dtdb', 'dates', '{ "_id": 6, "ts": { "$date": "2000-02-01T00:00:00Z" } }');
SELECT blackboxdb_api.insert_one('dtdb', 'dates', '{ "_id": 7, "ts": { "$date": "2016-02-29T12:00:00Z" } }');
SELECT blackboxdb_api.insert_one('dtdb', 'dates', '{ "_id": 8, "ts": { "$date": "2020-03-08T07:00:00Z" } }');
SELECT blackboxdb_api.insert_one('dtdb', 'dates', '{ "_id": 9, "ts": { "$date": "2020-11-01T05:30:00Z" } }');
SELECT blackboxdb_api.insert_one('dtdb', 'dates', '{ "_id": 10, "ts": { "$date": "2021-10-02T16:00:00Z" } }');
SELECT blackboxdb_api.insert_one('dtdb', 'dates', '{ "_id": 11, "ts": { "$date": "2037-12-31T23:59:59.999Z" } }');

SET blackboxdb.enable_datetrunc_exact_bins TO off;
SELECT document FROM bson_aggregation_pipeline('dtdb', '{"aggregate": "dates", "pipeline": [{"$project": {"day_utc": {"$dateTrunc": {"date": "$ts", "unit": "day"}}, "day3_newyork": {"$dateTrunc": {"date": "$ts", "unit": "day", "binSize": 3, "timezone": "America/New_York"}}, "week_kolkata_mon": {"$dateTrunc": {"date": "$ts", "unit": "week", "startOfWeek": "monday", "timezone": "Asia/Kolkata"}}, "week2_lordhowe_sat": {"$dateTrunc": {"date": "$ts", "unit": "week", "binSize": 2, "startOfWeek": "saturday", "timezone": "Australia/Lord_Howe"}}, "month_newyork": {"$dateTrunc": {"date": "$ts", "unit": "month", "timezone": "America/New_York"}}, "quarter_berlin": {"$dateTrunc": {"date": "$ts", "unit": "quarter", "timezone": "Europe/Berlin"}}, "year_kolkata": {"$dateTrunc": {"date": "$ts", "unit": "year", "timezone": "Asia/Kolkata"}}, "year3_utc": {"$dateTrunc": {"date": "$ts", "unit": "year", "binSize": 3}}, "day_offset_plus0530": {"$dateTrunc": {"date": "$ts", "unit": "day", "timezone": "+05:30"}}, "month2_offset_minus0300": {"$dateTrunc": {"date": "$ts", "unit": "month", "binSize": 2, "timezone": "-03:00"}}, "hour_newyork": {"$dateTrunc": {"date": "$ts", "unit": "hour", "timezone": "America/New_York"}}}}, {"$sort": {"_id": 1}}], "cursor": {}}');

SET blackboxdb.enable_datetrunc_exact_bins TO on;
SELECT document FROM bson_aggregation_pipeline('dtdb', '{"aggregate": "dates", "pipeline": [{"$project": {"day_utc": {"$dateTrunc": {"date": "$ts", "unit": "day"}}, "day3_newyork": {"$dateTrunc": {"date": "$ts", "unit": "day", "binSize": 3, "timezone": "America/New_York"}}, "week_kolkata_mon": {"$dateTrunc": {"date": "$ts", "unit": "week", "startOfWeek": "monday", "timezone": "Asia/Kolkata"}}, "week2_lordhowe_sat": {"$dateTrunc": {"date": "$ts", "unit": "week", "binSize": 2, "startOfWeek": "saturday", "timezone": "Australia/Lord_Howe"}}, "month_newyork": {"$dateTrunc": {"date": "$ts", "unit": "month", "timezone": "America/New_York"}}, "quarter_berlin": {"$dateTrunc": {"date": "$ts", "unit": "quarter", "timezone": "Europe/Berlin"}}, "year_kolkata": {"$dateTrunc": {"date": "$ts", "unit": "year", "timezone": "Asia/Kolkata"}}, "year3_utc": {"$dateTrunc": {"date": "$ts", "unit": "year", "binSize": 3}}, "day_offset_plus0530": {"$dateTrunc": {"date": "$ts", "unit": "day", "timezone": "+05:30"}}, "month2_offset_minus0300": {"$dateTrunc": {"date": "$ts", "unit": "month", "binSize": 2, "timezone": "-03:00"}}, "hour_newyork": {"$dateTrunc": {"date": "$ts", "unit": "hour", "timezone": "America/New_York"}}}}, {"$sort": {"_id": 1}}], "cursor": {}}');

RESET blackboxdb.enable_datetrunc_exact_bins;
