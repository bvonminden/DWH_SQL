

set nocount on;
go


declare @tb as table
(
	dbname varchar(150),
	table_name varchar(150),
	c_name varchar(150),
	c_type varchar(100),
	c_max varchar(100)
)

insert into @tb (dbname, table_name,c_name,c_type,c_max) select  TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH from AgencyDB_CA_OrangeCounty_139.INFORMATION_SCHEMA.COLUMNS  where table_name not in (select table_name from AgencyDB_CA_OrangeCounty_139.information_schema.views)
insert into @tb (dbname, table_name,c_name,c_type,c_max) select  TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH from AgencyDB_SC_315.INFORMATION_SCHEMA.COLUMNS  where table_name not in (select table_name from AgencyDB_SC_315.information_schema.views)
insert into @tb (dbname, table_name,c_name,c_type,c_max) select  TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH from AgencyDB_SC_165.INFORMATION_SCHEMA.COLUMNS  where table_name not in (select table_name from AgencyDB_SC_165.information_schema.views)
insert into @tb (dbname, table_name,c_name,c_type,c_max) select  TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH from Agency_CA_SanLuisObispo_138.INFORMATION_SCHEMA.COLUMNS  where table_name not in (select table_name from Agency_CA_SanLuisObispo_138.information_schema.views)
insert into @tb (dbname, table_name,c_name,c_type,c_max) select  TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH from AgencyDB_CA_SantaCruz_423.INFORMATION_SCHEMA.COLUMNS  where table_name not in (select table_name from AgencyDB_CA_SantaCruz_423.information_schema.views)
insert into @tb (dbname, table_name,c_name,c_type,c_max) select  TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH from AgencyDB_SC_176.INFORMATION_SCHEMA.COLUMNS  where table_name not in (select table_name from AgencyDB_SC_176.information_schema.views)
insert into @tb (dbname, table_name,c_name,c_type,c_max) select  TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH from AgencyDB_SC_382.INFORMATION_SCHEMA.COLUMNS  where table_name not in (select table_name from AgencyDB_SC_382.information_schema.views)
insert into @tb (dbname, table_name,c_name,c_type,c_max) select  TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH from AgencyDB_SC_383.INFORMATION_SCHEMA.COLUMNS  where table_name not in (select table_name from AgencyDB_SC_383.information_schema.views)
insert into @tb (dbname, table_name,c_name,c_type,c_max) select  TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH from AgencyDB_SC_346.INFORMATION_SCHEMA.COLUMNS  where table_name not in (select table_name from AgencyDB_SC_346.information_schema.views)
insert into @tb (dbname, table_name,c_name,c_type,c_max) select  TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH from Agency_CA_Sonoma_106.INFORMATION_SCHEMA.COLUMNS  where table_name not in (select table_name from Agency_CA_Sonoma_106.information_schema.views)
insert into @tb (dbname, table_name,c_name,c_type,c_max) select  TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH from AgencyDB_SC_170.INFORMATION_SCHEMA.COLUMNS  where table_name not in (select table_name from AgencyDB_SC_170.information_schema.views)
insert into @tb (dbname, table_name,c_name,c_type,c_max) select  TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH from AgencyDB_SC_289.INFORMATION_SCHEMA.COLUMNS  where table_name not in (select table_name from AgencyDB_SC_289.information_schema.views)
insert into @tb (dbname, table_name,c_name,c_type,c_max) select  TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH from AgencyDB_SC_169.INFORMATION_SCHEMA.COLUMNS  where table_name not in (select table_name from AgencyDB_SC_169.information_schema.views)
insert into @tb (dbname, table_name,c_name,c_type,c_max) select  TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH from Agency_CA_LosAngeles_257.INFORMATION_SCHEMA.COLUMNS  where table_name not in (select table_name from Agency_CA_LosAngeles_257.information_schema.views)
insert into @tb (dbname, table_name,c_name,c_type,c_max) select  TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH from AgencyDB_SC_323.INFORMATION_SCHEMA.COLUMNS  where table_name not in (select table_name from AgencyDB_SC_323.information_schema.views)
insert into @tb (dbname, table_name,c_name,c_type,c_max) select  TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH from AgencyDB_SC_385.INFORMATION_SCHEMA.COLUMNS  where table_name not in (select table_name from AgencyDB_SC_385.information_schema.views)
insert into @tb (dbname, table_name,c_name,c_type,c_max) select  TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH from AgencyDB_SC_192.INFORMATION_SCHEMA.COLUMNS  where table_name not in (select table_name from AgencyDB_SC_192.information_schema.views)
insert into @tb (dbname, table_name,c_name,c_type,c_max) select  TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH from AgencyDB_SC.INFORMATION_SCHEMA.COLUMNS  where table_name not in (select table_name from AgencyDB_SC.information_schema.views)
insert into @tb (dbname, table_name,c_name,c_type,c_max) select  TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH from Agency_CA_Stanislaus_325.INFORMATION_SCHEMA.COLUMNS  where table_name not in (select table_name from Agency_CA_Stanislaus_325.information_schema.views)
insert into @tb (dbname, table_name,c_name,c_type,c_max) select  TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH from AgencyDB_Template.INFORMATION_SCHEMA.COLUMNS  where table_name not in (select table_name from AgencyDB_Template.information_schema.views)
insert into @tb (dbname, table_name,c_name,c_type,c_max) select  TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH from AgencyDB_SC_219.INFORMATION_SCHEMA.COLUMNS  where table_name not in (select table_name from AgencyDB_SC_219.information_schema.views)
insert into @tb (dbname, table_name,c_name,c_type,c_max) select  TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH from AgencyDB_CA_SanDiego.INFORMATION_SCHEMA.COLUMNS  where table_name not in (select table_name from AgencyDB_CA_SanDiego.information_schema.views)
insert into @tb (dbname, table_name,c_name,c_type,c_max) select  TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH from AgencyDB_SC_164.INFORMATION_SCHEMA.COLUMNS  where table_name not in (select table_name from AgencyDB_SC_164.information_schema.views)
insert into @tb (dbname, table_name,c_name,c_type,c_max) select  TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH from AgencyDB_CA_99_Extract.INFORMATION_SCHEMA.COLUMNS  where table_name not in (select table_name from AgencyDB_CA_99_Extract.information_schema.views)
insert into @tb (dbname, table_name,c_name,c_type,c_max) select  TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH from AgencyDB_SC_312.INFORMATION_SCHEMA.COLUMNS  where table_name not in (select table_name from AgencyDB_SC_312.information_schema.views)
insert into @tb (dbname, table_name,c_name,c_type,c_max) select  TABLE_CATALOG, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH from AgencyDB_SC_413.INFORMATION_SCHEMA.COLUMNS  where table_name not in (select table_name from AgencyDB_SC_413.information_schema.views)


select * from @tb;



