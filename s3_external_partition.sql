-- 1 create table
create table src.gp_tbl_230417_part
	(id int8 NULL,
	dt timestamp NULL,
	summa numeric NULL)
distributed by (id)
PARTITION BY RANGE(dt) (
PARTITION before_2020 END (date '2020-01-01') EXCLUSIVE, 
PARTITION monthly START (date '2020-01-01') INCLUSIVE 
END (date '2023-01-01') EXCLUSIVE EVERY (INTERVAL '1 month'),
PARTITION recent START (date '2023-01-01') INCLUSIVE);


-- 2 insert
insert into src.gp_tbl_230417_part 
select * from src.gp_tbl_230417
;

-- 3 check
select 
(select count(1) from src.gp_tbl_230417_part ) as all_tbl,
(select count(1) from src.gp_tbl_230417_part_1_prt_before_2020) as partition_for_s3 
;

-- 4 s3 external tables
CREATE WRITABLE EXTERNAL TABLE 
src.before_2020_from_s3_archive_write ( LIKE src.gp_tbl_230417_part_1_prt_before_2020 )
LOCATION ('pxf://archive_bucket/before_2020/before_2020.parquet?PROFILE=s3:parquet&SERVER=minio')
FORMAT 'CUSTOM' (FORMATTER='pxfwritable_export');

CREATE READABLE EXTERNAL TABLE
src.before_2020_from_s3_archive_read ( LIKE src.gp_tbl_230417_part_1_prt_before_2020 )
LOCATION ('pxf://archive_bucket/before_2020/before_2020.parquet?PROFILE=s3:parquet&SERVER=minio')
FORMAT 'CUSTOM' (FORMATTER='pxfwritable_import');

INSERT INTO src.before_2020_from_s3_archive_write SELECT * FROM src.gp_tbl_230417_part_1_prt_before_2020 ;

-- 5 change partition and table
ALTER TABLE src.gp_tbl_230417_part
alter partition before_2020
EXCHANGE PARTITION before_2020
WITH TABLE src.before_2020_from_s3_archive_read
WITHOUT VALIDATION;

DROP TABLE src.before_2020_from_s3_archive_read ;
