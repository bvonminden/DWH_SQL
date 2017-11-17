USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_AGENCIES_UPDATE]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_AGENCIES_UPDATE
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_AGENCIES_UPDATE]
 (@p_datasource      nvarchar(10) = null
 ,@p_no_delete_opt   nvarchar(2)  = null
 ,@p_no_exec_flag    nvarchar(10) = 'N')
AS
--
-- This script controls the update of DW Teams from the AgencyDB Agencies Table
--
-- Data coming in from the AgencyDB will go through an approval process prior to actually updating the DW Table.
-- When data columns are compared and found to be different, the change before/after is logged for the approval process.
-- No change to the actual DW Table will occur until the change has been approved.
--
-- Approved:
-- When the logged change has been approved, the data will move to the actual DW table, and the logged record marked as completed.
--
-- Not Approved:
-- If within the approval process the logged records are flagged as 'not approved', then the AgencyDB table record will be reset  
-- to what is recorded within the DW Table. The logged change will be marked as completed.
--
-- Instant Approval:
-- These columns are marked for instant approval and will flow directly into the DW Table, showing the logged record as completed.
--  Address1, Address2, City, State, ZipCode, County, Phone1,
--  Site_Address1, Site_Address2, Site_City, Site_State, Site_ZipCode, Site_County, Site_Phone1,
--  AGENCY_INFO_1_COUNTY, AGENCY_INFO_1_LOWINCOME_PERCENT,
--  AGENCY_INFO_1_LOWINCOME_DESCRIPTION, AGENCY_INFO_1_WEBSITE
--
--
-- IDs translated via DW/AgencyDB Non_ETO_Xref mapping:
--
-- History:
--   20160205 - New Procedure.


DECLARE @count          smallint
DECLARE @stop_flag      nvarchar(2)
DECLARE @Process        nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)
DECLARE @Agency_TableName   nvarchar(50)
DECLARE @Agency_Full_TableName   nvarchar(100)

set @process          = 'SP_AGENCYDB_AGENCIES_UPDATE'
set @DW_Tablename     = 'TEAMS'
set @Agency_Tablename = 'TEAMS'
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

declare @transaction_nbr int
declare @column_ctr int
declare @changelog_rec_id int
DECLARE @changelog_after_value nvarchar(200)
DECLARE @changelog_approval_status nvarchar(50)
declare @lov_item_id int
DECLARE @Field_Changed nvarchar(50)
DECLARE @Before_Value  nvarchar(200)
DECLARE @After_Value   nvarchar(200)
DECLARE @Approval_Status   nvarchar(50)
DECLARE @approval_comment  nvarchar(100)
DECLARE @last_Entity_ID    int
DECLARE @Rec_ids_to_complete  nvarchar(100)

-- AgencyDB Columns
DECLARE @Atbl_Entity_Id int
DECLARE @Atbl_AGENCY_INFO_0_NAME nvarchar(200)
DECLARE @Atbl_Site_ID int
DECLARE @Atbl_Site_Alias nvarchar(200)
DECLARE @Atbl_Agency_Status smallint
DECLARE @Atbl_Program_ID int
DECLARE @Atbl_Address1 nvarchar(100)
DECLARE @Atbl_Address2 nvarchar(100)
DECLARE @Atbl_City nvarchar(30)
DECLARE @Atbl_State char(2)
DECLARE @Atbl_ZipCode nvarchar(10)
DECLARE @Atbl_county nvarchar(50)
DECLARE @Atbl_Phone1 nvarchar(20)
DECLARE @Atbl_Site_Address1 nvarchar(100)
DECLARE @Atbl_Site_Address2 nvarchar(100)
DECLARE @Atbl_Site_City nvarchar(30)
DECLARE @Atbl_Site_State char(2)
DECLARE @Atbl_Site_ZipCode nvarchar(10)
DECLARE @Atbl_Site_County nvarchar(50)
DECLARE @Atbl_Site_Phone1 nvarchar(20)
DECLARE @Atbl_Audit_Date datetime
DECLARE @Atbl_Site_Audit_Date datetime
DECLARE @Atbl_Audit_Staff_ID int
DECLARE @Atbl_Entity_Disabled bit
DECLARE @Atbl_Site_Disabled bit
DECLARE @Atbl_AGENCY_INFO_1_COUNTY nvarchar(2000)
DECLARE @Atbl_AGENCY_INFO_1_TYPE nvarchar(2000)
DECLARE @Atbl_AGENCY_INFO_1_LOWINCOME_CRITERA nvarchar(2000)
DECLARE @Atbl_AGENCY_INFO_1_LOWINCOME_PERCENT numeric(15, 5)
DECLARE @Atbl_AGENCY_INFO_1_LOWINCOME_DESCRIPTION nvarchar(2000)
DECLARE @Atbl_AGENCY_INFO_1_WEBSITE nvarchar(2000)
DECLARE @Atbl_AGENCY_INFO_1_INITIATION_DATE datetime
DECLARE @Atbl_AGENCY_DATE_FIRST_HOME_VISIT datetime
DECLARE @Atbl_AGENCY_INFO_1_MILEAGE_RATE numeric(15, 5)
DECLARE @Atbl_SERVICE_LEVEL_COVERED nvarchar(2000)
DECLARE @Atbl_Start_Date date
DECLARE @Atbl_End_Date date

-- DataWarehouse columns:
DECLARE @DWTbl_Entity_Id int
DECLARE @DWTbl_AGENCY_INFO_0_NAME nvarchar(200)
DECLARE @DWTbl_Site_ID int
DECLARE @DWTbl_Site_Alias nvarchar(200)
DECLARE @DWTbl_Agency_Status smallint
DECLARE @DWTbl_Program_ID int
DECLARE @DWTbl_Address1 nvarchar(100)
DECLARE @DWTbl_Address2 nvarchar(100)
DECLARE @DWTbl_City nvarchar(30)
DECLARE @DWTbl_State char(2)
DECLARE @DWTbl_ZipCode nvarchar(10)
DECLARE @DWTbl_county nvarchar(50)
DECLARE @DWTbl_Phone1 nvarchar(20)
DECLARE @DWTbl_Site_Address1 nvarchar(100)
DECLARE @DWTbl_Site_Address2 nvarchar(100)
DECLARE @DWTbl_Site_City nvarchar(30)
DECLARE @DWTbl_Site_State char(2)
DECLARE @DWTbl_Site_ZipCode nvarchar(10)
DECLARE @DWTbl_Site_County nvarchar(50)
DECLARE @DWTbl_Site_Phone1 nvarchar(20)
DECLARE @DWTbl_Audit_Date datetime
DECLARE @DWTbl_Site_Audit_Date datetime
DECLARE @DWTbl_Audit_Staff_ID int
DECLARE @DWTbl_Entity_Disabled bit
DECLARE @DWTbl_Site_Disabled bit
DECLARE @DWTbl_AGENCY_INFO_1_COUNTY nvarchar(2000)
DECLARE @DWTbl_AGENCY_INFO_1_TYPE nvarchar(2000)
DECLARE @DWTbl_AGENCY_INFO_1_LOWINCOME_CRITERA nvarchar(2000)
DECLARE @DWTbl_AGENCY_INFO_1_LOWINCOME_PERCENT numeric(15, 5)
DECLARE @DWTbl_AGENCY_INFO_1_LOWINCOME_DESCRIPTION nvarchar(2000)
DECLARE @DWTbl_AGENCY_INFO_1_WEBSITE nvarchar(2000)
DECLARE @DWTbl_AGENCY_INFO_1_INITIATION_DATE datetime
DECLARE @DWTbl_AGENCY_DATE_FIRST_HOME_VISIT datetime
DECLARE @DWTbl_AGENCY_INFO_1_MILEAGE_RATE numeric(15, 5)
DECLARE @DWTbl_SERVICE_LEVEL_COVERED nvarchar(2000)
DECLARE @DWTbl_Start_Date date
DECLARE @DWTbl_End_Date date

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)
DECLARE @SQL1           varchar(MAX)
DECLARE @SQL2           varchar(MAX)
DECLARE @SQL3           varchar(MAX)
DECLARE @SQL4           varchar(MAX)

print 'Processing SP_AGENCYDB_AGENCIES_UPDATE: Datasource = ' +isnull(@p_datasource,'NULL')
----------------------------------------------------------------------------------------
-- Initiate the Process Log
----------------------------------------------------------------------------------------

-- Check for existance for this process, if not found, add one:
select @count = count(*) from dbo.process_log where Process = @Process

set nocount on

IF @count = 0 
   insert into dbo.process_log (Process, LogDate, BegDate, EndDate, Action, Phase, Comment)
      Values (@Process, getdate(),getdate(),null,'Starting',null,null)
ELSE
   update dbo.process_log 
      set BegDate = getdate()
         ,EndDate = null
         ,LogDate = getdate()
         ,Action = 'Start Validation AgencyDB'
         ,Phase = null
         ,Comment = null
         ,index_1 = null
         ,index_2 = null
         ,index_3 = null
    where Process = @process

----------------------------------------------------------------------------------------
print ' '
print 'Check for run inhibit trigger'

IF dbo.FN_Check_Process_Inhibitor (@process, @p_datasource, null) is not null 

BEGIN
   set @stop_flag = 'X';
   print 'Process Inhibited via Process_Inhibitor Table, job stopped'
   set nocount on
   update dbo.process_log 
   set Comment = 'Process Inhibited via Process_Inhibitor Table, job stopped'
      ,LogDate = getdate()
 where Process = @process
END

IF @stop_flag is null
BEGIN
   print 'Validate datasource DBSrvr from LOV tables'

   set @AgencyDB = null;
   select @AgencyDB = Value
     from dbo.View_LOV
    where Name = 'AGENCYDB_BY_DATASOURCE'
      and lOV_Item = @p_datasource

   IF @AgencyDB is null
   BEGIN
      set @stop_flag = 'X';
      print 'Unable to retrieve LOV AgencyDB for datasource=' +isnull(@AgencyDB,'') +', job stopped'
      set nocount on
      update dbo.process_log 
      set Comment = 'failed, can''t retrieve LOV AgencyDB for datasource'
         ,LogDate = getdate()
    where Process = @process
   END
END 

IF @stop_flag is null 
BEGIN


-- format full table name with network path:
SET @Agency_Full_Tablename = @AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Agency_Tablename 

----------------------------------------------------------------------------------------
print ' '
print 'Preparing Comparison records - Teams_AgencyDB_Records'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Prepare for Comparisons'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- remove the temporary records for the AgencyDB being processed:
print ' '
print ' '
print 'clear out temporary Table'
set @SQL = 'set nocount off'
    +' delete from dbo.Agencies_AgencyDB_Records'
    +' where Entity_ID in ('
    +' select dwtbl.Entity_ID'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Agencies Atbl'
    +' inner join dbo.Agencies_AgencyDB_Records dwtbl'
    +'   on Atbl.Entity_ID = dwtbl.Entity_ID
 where dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'
    +')'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
      EXEC (@SQL)


-- Bring a local copy of the AgencyDB records for comparison:
print ' '
print ' '
print 'Build temporary copy of AgencyDB Record'
set @SQL1 = 'set nocount off'
    +' insert into dbo.Agencies_AgencyDB_Records '
    +'(Entity_Id'
    +',AGENCY_INFO_0_NAME'
    +',SiteID'
    +',Site_Alias'
    +',Agency_Status'
    +',Program_ID'
    +',Address1'
    +',Address2'
    +',City'
    +',State'
    +',ZipCode'
    +',county'
    +',Phone1'
    +',Site_Address1'
    +',Site_Address2'
    +',Site_City'
    +',Site_State'
    +',Site_ZipCode'
    +',Site_County'
    +',Site_Phone1'
    +',Audit_Date'
    +',Site_Audit_Date'
    +',Entity_Disabled'
    +',Site_Disabled'
    +',AGENCY_INFO_1_COUNTY'
    +',AGENCY_INFO_1_TYPE'
    +',AGENCY_INFO_1_LOWINCOME_CRITERA'
    +',AGENCY_INFO_1_LOWINCOME_PERCENT'
    +',AGENCY_INFO_1_LOWINCOME_DESCRIPTION'
    +',AGENCY_INFO_1_WEBSITE'
    +',AGENCY_INFO_1_INITIATION_DATE'
    +',AGENCY_DATE_FIRST_HOME_VISIT'
    +',AGENCY_INFO_1_MILEAGE_RATE'
    +',last_attribute_update'
    +',SERVICE_LEVEL_COVERED'
    +',Start_Date'
    +',End_Date)'
set @SQL2 = ' select Atbl.Entity_Id'
    +',Atbl.AGENCY_INFO_0_NAME'
    +',Atbl.SiteID'
    +',Atbl.Site_Alias'
    +',Atbl.Agency_Status'
    +',Atbl.Program_ID'
    +',Atbl.Address1'
    +',Atbl.Address2'
    +',Atbl.City'
    +',Atbl.State'
    +',Atbl.ZipCode'
    +',Atbl.county'
    +',Atbl.Phone1'
    +',Atbl.Site_Address1'
    +',Atbl.Site_Address2'
    +',Atbl.Site_City'
    +',Atbl.Site_State'
    +',Atbl.Site_ZipCode'
    +',Atbl.Site_County'
    +',Atbl.Site_Phone1'
    +',Atbl.Audit_Date'
    +',Atbl.Site_Audit_Date'
    +',Atbl.Entity_Disabled'
    +',Atbl.Site_Disabled'
    +',Atbl.AGENCY_INFO_1_COUNTY'
    +',Atbl.AGENCY_INFO_1_TYPE'
    +',Atbl.AGENCY_INFO_1_LOWINCOME_CRITERA'
    +',Atbl.AGENCY_INFO_1_LOWINCOME_PERCENT'
    +',Atbl.AGENCY_INFO_1_LOWINCOME_DESCRIPTION'
    +',Atbl.AGENCY_INFO_1_WEBSITE'
    +',Atbl.AGENCY_INFO_1_INITIATION_DATE'
    +',Atbl.AGENCY_DATE_FIRST_HOME_VISIT'
    +',Atbl.AGENCY_INFO_1_MILEAGE_RATE'
    +',Atbl.last_attribute_update'
    +',Atbl.SERVICE_LEVEL_COVERED'
    +',Atbl.Start_Date'
    +',Atbl.End_Date
 from  ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Agencies Atbl'
    +' inner join dbo.Agencies dwtbl'
    +'   on Atbl.Entity_ID = dwtbl.Entity_ID
 where dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'


    print @SQL1
    print @SQL2
    --print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
       EXEC (@SQL1+@SQL2)


----------------------------------------------------------------------------------------
-- Log changes'
----------------------------------------------------------------------------------------

print ' '
print ' '
print 'Evaluating records for Changes, logging changes'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Logging Changes'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------


Declare CompareCursor Cursor for
-- select both the DW record and the temporarily loaded AgencyDB record, for comparison:
select temptbl.Entity_Id
,temptbl.AGENCY_INFO_0_NAME
,temptbl.SiteID
,temptbl.Site_Alias
,temptbl.Agency_Status
,temptbl.Program_ID
,temptbl.Address1
,temptbl.Address2
,temptbl.City
,temptbl.State
,temptbl.ZipCode
,temptbl.county
,temptbl.Phone1
,temptbl.Site_Address1
,temptbl.Site_Address2
,temptbl.Site_City
,temptbl.Site_State
,temptbl.Site_ZipCode
,temptbl.Site_County
,temptbl.Site_Phone1
,temptbl.Audit_Date
,temptbl.Site_Audit_Date
,temptbl.Entity_Disabled
,temptbl.Site_Disabled
,temptbl.AGENCY_INFO_1_COUNTY
,temptbl.AGENCY_INFO_1_TYPE
--,dbo.FN_Entity_Attribute_Lookup ('AGENCY_INFO_1_TYPE','SequenceOrder',temptbl.AGENCY_INFO_1_TYPE,'TextValue')
,temptbl.AGENCY_INFO_1_LOWINCOME_CRITERA
--,dbo.FN_Entity_Attribute_Lookup ('AGENCY_INFO_1_LOWINCOME_CRITERA','SequenceOrder',temptbl.AGENCY_INFO_1_LOWINCOME_CRITERA,'TextValue')
,temptbl.AGENCY_INFO_1_LOWINCOME_PERCENT
,temptbl.AGENCY_INFO_1_LOWINCOME_DESCRIPTION
,temptbl.AGENCY_INFO_1_WEBSITE
,temptbl.AGENCY_INFO_1_INITIATION_DATE
,temptbl.AGENCY_DATE_FIRST_HOME_VISIT
,temptbl.AGENCY_INFO_1_MILEAGE_RATE
,temptbl.SERVICE_LEVEL_COVERED
,temptbl.Start_Date
,temptbl.End_Date

,dwtbl.Entity_Id
,dwtbl.AGENCY_INFO_0_NAME
,dwtbl.Site_ID
,dwtbl.Site_Alias
,dwtbl.Agency_Status
,dwtbl.Program_ID
,dwtbl.Address1
,dwtbl.Address2
,dwtbl.City
,dwtbl.State
,dwtbl.ZipCode
,dwtbl.county
,dwtbl.Phone1
,dwtbl.Site_Address1
,dwtbl.Site_Address2
,dwtbl.Site_City
,dwtbl.Site_State
,dwtbl.Site_ZipCode
,dwtbl.Site_County
,dwtbl.Site_Phone1
,dwtbl.Audit_Date
,dwtbl.Site_Audit_Date
,dwtbl.Entity_Disabled
,dwtbl.Site_Disabled
,dwtbl.AGENCY_INFO_1_COUNTY
,dwtbl.AGENCY_INFO_1_TYPE
,dwtbl.AGENCY_INFO_1_LOWINCOME_CRITERA
,dwtbl.AGENCY_INFO_1_LOWINCOME_PERCENT
,dwtbl.AGENCY_INFO_1_LOWINCOME_DESCRIPTION
,dwtbl.AGENCY_INFO_1_WEBSITE
,dwtbl.AGENCY_INFO_1_INITIATION_DATE
,dwtbl.AGENCY_DATE_FIRST_HOME_VISIT
,dwtbl.AGENCY_INFO_1_MILEAGE_RATE
,dwtbl.SERVICE_LEVEL_COVERED
,dwtbl.Start_Date
,dwtbl.End_Date

from dbo.AgencyDB_Sites_By_DataSource asbd
inner join dbo.Agencies_AgencyDB_Records temptbl
      on asbd.Site_ID = temptbl.siteid
inner join dbo.Agencies dwtbl on temptbl.Entity_ID = dwtbl.Entity_ID
where asbd.DataSource = @p_datasource 
  and dbo.FN_Check_Process_Inhibitor ('SP_AGENCYDB_AGENCIES_UPDATE', @p_datasource, asbd.Site_ID) is null
  

open CompareCursor

FETCH next from CompareCursor
      into @Atbl_Entity_ID
          ,@Atbl_AGENCY_INFO_0_NAME
          ,@Atbl_Site_ID
          ,@Atbl_Site_Alias
          ,@Atbl_Agency_Status
          ,@Atbl_Program_ID
          ,@Atbl_Address1
          ,@Atbl_Address2
          ,@Atbl_City
          ,@Atbl_State
          ,@Atbl_ZipCode
          ,@Atbl_county
          ,@Atbl_Phone1
          ,@Atbl_Site_Address1
          ,@Atbl_Site_Address2
          ,@Atbl_Site_City
          ,@Atbl_Site_State
          ,@Atbl_Site_ZipCode
          ,@Atbl_Site_County
          ,@Atbl_Site_Phone1
          ,@Atbl_Audit_Date
          ,@Atbl_Site_Audit_Date
          ,@Atbl_Entity_Disabled
          ,@Atbl_Site_Disabled
          ,@Atbl_AGENCY_INFO_1_COUNTY
          ,@Atbl_AGENCY_INFO_1_TYPE
          ,@Atbl_AGENCY_INFO_1_LOWINCOME_CRITERA
          ,@Atbl_AGENCY_INFO_1_LOWINCOME_PERCENT
          ,@Atbl_AGENCY_INFO_1_LOWINCOME_DESCRIPTION
          ,@Atbl_AGENCY_INFO_1_WEBSITE
          ,@Atbl_AGENCY_INFO_1_INITIATION_DATE
          ,@Atbl_AGENCY_DATE_FIRST_HOME_VISIT
          ,@Atbl_AGENCY_INFO_1_MILEAGE_RATE
          ,@Atbl_SERVICE_LEVEL_COVERED
          ,@Atbl_Start_Date
          ,@Atbl_End_Date
          ,@dwtbl_Entity_Id
          ,@dwtbl_AGENCY_INFO_0_NAME
          ,@dwtbl_Site_ID
          ,@dwtbl_Site_Alias
          ,@dwtbl_Agency_Status
          ,@dwtbl_Program_ID
          ,@dwtbl_Address1
          ,@dwtbl_Address2
          ,@dwtbl_City
          ,@dwtbl_State
          ,@dwtbl_ZipCode
          ,@dwtbl_county
          ,@dwtbl_Phone1
          ,@dwtbl_Site_Address1
          ,@dwtbl_Site_Address2
          ,@dwtbl_Site_City
          ,@dwtbl_Site_State
          ,@dwtbl_Site_ZipCode
          ,@dwtbl_Site_County
          ,@dwtbl_Site_Phone1
          ,@dwtbl_Audit_Date
          ,@dwtbl_Site_Audit_Date
          ,@dwtbl_Entity_Disabled
          ,@dwtbl_Site_Disabled
          ,@dwtbl_AGENCY_INFO_1_COUNTY
          ,@dwtbl_AGENCY_INFO_1_TYPE
          ,@dwtbl_AGENCY_INFO_1_LOWINCOME_CRITERA
          ,@dwtbl_AGENCY_INFO_1_LOWINCOME_PERCENT
          ,@dwtbl_AGENCY_INFO_1_LOWINCOME_DESCRIPTION
          ,@dwtbl_AGENCY_INFO_1_WEBSITE
          ,@dwtbl_AGENCY_INFO_1_INITIATION_DATE
          ,@dwtbl_AGENCY_DATE_FIRST_HOME_VISIT
          ,@dwtbl_AGENCY_INFO_1_MILEAGE_RATE
          ,@dwtbl_SERVICE_LEVEL_COVERED
          ,@dwtbl_Start_Date
          ,@dwtbl_End_Date

WHILE @@FETCH_STATUS = 0
BEGIN

-- Evaluate each column, looking for changes

set @column_ctr = 0
set @transaction_nbr = null
WHILE @column_ctr < 31
BEGIN

 set @column_ctr = @column_ctr + 1
 set @Field_Changed = null
 set @Approval_Status = null
 set @approval_comment = null

   
  IF @column_ctr = 1 and 
     isnull(@Atbl_AGENCY_INFO_0_NAME,'xxnull') != isnull(@DWTbl_AGENCY_INFO_0_NAME,'xxnull') 
     BEGIN
     set @Field_Changed = 'AGENCY_INFO_0_NAME'
     set @Before_Value = @DWTbl_AGENCY_INFO_0_NAME
     set @After_Value = @Atbl_AGENCY_INFO_0_NAME
     END
  IF @column_ctr = 2 and 
     isnull(@Atbl_Start_Date,@runtime) != isnull(@DWTbl_Start_Date,@runtime)  
     BEGIN
     set @Field_Changed = 'Start_Date date'
     set @Before_Value = @DWTbl_Start_Date
     set @After_Value = @Atbl_Start_Date
     END
  IF @column_ctr = 3 and 
     isnull(@Atbl_End_Date,@runtime) != isnull(@DWTbl_End_Date,@runtime)  
     BEGIN
     set @Field_Changed = 'End_Date date'
     set @Before_Value = @DWTbl_End_Date
     set @After_Value = @Atbl_End_Date
     END
  IF @column_ctr = 4 and 
     isnull(@Atbl_Agency_Status,9999) != isnull(@DWTbl_Agency_Status,9999) 
     BEGIN
     set @Field_Changed = 'Agency_Status'
     set @Before_Value = @DWTbl_Agency_Status
     set @After_Value = @Atbl_Agency_Status
     END

  IF @column_ctr = 5 and 
     isnull(@Atbl_Address1,'xxnull') != isnull(@DWTbl_Address1,'xxnull') 
     BEGIN
     set @Field_Changed = 'Address1'
     set @Before_Value = @DWTbl_Address1
     set @After_Value = @Atbl_Address1
     set @Approval_Status = 'APPROVED'
     set @approval_comment = 'Automatic'
     END
  IF @column_ctr = 6 and 
     isnull(@Atbl_Address2,'xxnull') != isnull(@DWTbl_Address2,'xxnull')  
     BEGIN
     set @Field_Changed = 'Address2'
     set @Before_Value = @DWTbl_Address2
     set @After_Value = @Atbl_Address2
     set @Approval_Status = 'APPROVED'
     set @approval_comment = 'Automatic'
     END
  IF @column_ctr = 7 and 
     isnull(@Atbl_City,'xxnull') != isnull(@DWTbl_City,'xxnull')  
     BEGIN
     set @Field_Changed = 'City'
     set @Before_Value = @DWTbl_City
     set @After_Value = @Atbl_City
     set @Approval_Status = 'APPROVED'
     set @approval_comment = 'Automatic'
     END
  IF @column_ctr = 8 and 
     isnull(@Atbl_State,'xxnull') != isnull(@DWTbl_State,'xxnull')  
     BEGIN
     set @Field_Changed = 'State'
     set @Before_Value = @DWTbl_State
     set @After_Value = @Atbl_State
     set @Approval_Status = 'APPROVED'
     set @approval_comment = 'Automatic'
     END
  IF @column_ctr = 9 and 
     isnull(@Atbl_ZipCode,'xxnull') != isnull(@DWTbl_ZipCode,'xxnull')  
     BEGIN
     set @Field_Changed = 'ZipCode'
     set @Before_Value = @DWTbl_ZipCode
     set @After_Value = @Atbl_ZipCode
     set @Approval_Status = 'APPROVED'
     set @approval_comment = 'Automatic'
     END
  IF @column_ctr = 10 and 
     isnull(@Atbl_county,'xxnull') != isnull(@DWTbl_county,'xxnull')  
     BEGIN
     set @Field_Changed = 'County'
     set @Before_Value = @DWTbl_county
     set @After_Value = @Atbl_county
     set @Approval_Status = 'APPROVED'
     set @approval_comment = 'Automatic'
     END
  IF @column_ctr = 11 and 
     isnull(@Atbl_Phone1,'xxnull') != isnull(@DWTbl_Phone1,'xxnull')  
     BEGIN
     set @Field_Changed = 'Phone1'
     set @Before_Value = @DWTbl_Phone1
     set @After_Value = @Atbl_Phone1
     set @Approval_Status = 'APPROVED'
     set @approval_comment = 'Automatic'
     END

  IF @column_ctr = 12 and 
     isnull(@Atbl_Site_Address1,'xxnull') != isnull(@DWTbl_Site_Address1,'xxnull') 
     BEGIN
     set @Field_Changed = 'Site_Address1'
     set @Before_Value = @DWTbl_Site_Address1
     set @After_Value = @Atbl_Site_Address1
     set @Approval_Status = 'APPROVED'
     set @approval_comment = 'Automatic'
     END
  IF @column_ctr = 13 and 
     isnull(@Atbl_Site_Address2,'xxnull') != isnull(@DWTbl_Site_Address2,'xxnull')  
     BEGIN
     set @Field_Changed = 'Site_Address2'
     set @Before_Value = @DWTbl_Site_Address2
     set @After_Value = @Atbl_Site_Address2
     set @Approval_Status = 'APPROVED'
     set @approval_comment = 'Automatic'
     END
  IF @column_ctr = 14 and 
     isnull(@Atbl_Site_City,'xxnull') != isnull(@DWTbl_Site_City,'xxnull')  
     BEGIN
     set @Field_Changed = 'Site_City'
     set @Before_Value = @DWTbl_Site_City
     set @After_Value = @Atbl_Site_City
     set @Approval_Status = 'APPROVED'
     set @approval_comment = 'Automatic'
     END
  IF @column_ctr = 14 and 
     isnull(@Atbl_Site_State,'xxnull') != isnull(@DWTbl_Site_State,'xxnull')  
     BEGIN
     set @Field_Changed = 'Site_State'
     set @Before_Value = @DWTbl_Site_State
     set @After_Value = @Atbl_Site_State
     set @Approval_Status = 'APPROVED'
     set @approval_comment = 'Automatic'
     END
  IF @column_ctr = 16 and 
     isnull(@Atbl_Site_ZipCode,'xxnull') != isnull(@DWTbl_Site_ZipCode,'xxnull')  
     BEGIN
     set @Field_Changed = 'Site_ZipCode'
     set @Before_Value = @DWTbl_Site_ZipCode
     set @After_Value = @Atbl_Site_ZipCode
     set @Approval_Status = 'APPROVED'
     set @approval_comment = 'Automatic'
     END
  IF @column_ctr = 17 and 
     isnull(@Atbl_Site_County,'xxnull') != isnull(@DWTbl_Site_County,'xxnull')  
     BEGIN
     set @Field_Changed = 'Site_County'
     set @Before_Value = @DWTbl_Site_County
     set @After_Value = @Atbl_Site_County
     set @Approval_Status = 'APPROVED'
     set @approval_comment = 'Automatic'
     END
  IF @column_ctr = 18 and 
     isnull(@Atbl_Site_Phone1,'xxnull') != isnull(@DWTbl_Site_Phone1,'xxnull')  
     BEGIN
     set @Field_Changed = 'Site_Phone1'
     set @Before_Value = @DWTbl_Site_Phone1
     set @After_Value = @Atbl_Site_Phone1
     set @Approval_Status = 'APPROVED'
     set @approval_comment = 'Automatic'
     END

  IF @column_ctr = 19 and 
     isnull(@Atbl_Entity_Disabled,0) != isnull(@DWTbl_Entity_Disabled,0)  
     BEGIN
     set @Field_Changed = 'Entity_Disabled'
     set @Before_Value = @DWTbl_Entity_Disabled
     set @After_Value = @Atbl_Entity_Disabled
     END
  IF @column_ctr = 20 and 
     isnull(@Atbl_Site_Disabled,0) != isnull(@DWTbl_Site_Disabled,0) 
     BEGIN
     set @Field_Changed = 'Site_Disabled'
     set @Before_Value = @DWTbl_Site_Disabled
     set @After_Value = @Atbl_Site_Disabled
     END
  IF @column_ctr = 21 and 
     isnull(@Atbl_AGENCY_INFO_1_COUNTY,'xxnull') != isnull(@DWTbl_AGENCY_INFO_1_COUNTY,'xxnull')  
     BEGIN
     set @Field_Changed = 'AGENCY_INFO_1_COUNTY'
     set @Before_Value = @DWTbl_AGENCY_INFO_1_COUNTY
     set @After_Value = @Atbl_AGENCY_INFO_1_COUNTY
     set @Approval_Status = 'APPROVED'
     set @approval_comment = 'Automatic'
     END
  IF @column_ctr = 22 and 
     isnull(@Atbl_AGENCY_INFO_1_TYPE,'xxnull') != isnull(@DWTbl_AGENCY_INFO_1_TYPE,'xxnull')  
     BEGIN
     set @Field_Changed = 'AGENCY_INFO_1_TYPE'
     set @Before_Value = @DWTbl_AGENCY_INFO_1_TYPE
     set @After_Value = @Atbl_AGENCY_INFO_1_TYPE
     END
  IF @column_ctr = 23 and 
     isnull(@Atbl_AGENCY_INFO_1_LOWINCOME_CRITERA,'xxnull') != isnull(@DWTbl_AGENCY_INFO_1_LOWINCOME_CRITERA,'xxnull')  
     BEGIN
     set @Field_Changed = 'AGENCY_INFO_1_LOWINCOME_CRITERA'
     set @Before_Value = @DWTbl_AGENCY_INFO_1_LOWINCOME_CRITERA
     set @After_Value = @Atbl_AGENCY_INFO_1_LOWINCOME_CRITERA
     END
  IF @column_ctr = 24 and 
     isnull(@Atbl_AGENCY_INFO_1_LOWINCOME_PERCENT,99999999) != isnull(@DWTbl_AGENCY_INFO_1_LOWINCOME_PERCENT,99999999) 
     BEGIN
     set @Field_Changed = 'AGENCY_INFO_1_LOWINCOME_PERCENT'
     set @Before_Value = @DWTbl_AGENCY_INFO_1_LOWINCOME_PERCENT
     set @After_Value = @Atbl_AGENCY_INFO_1_LOWINCOME_PERCENT
     set @Approval_Status = 'APPROVED'
     set @approval_comment = 'Automatic'
     END
  IF @column_ctr = 26 and 
     isnull(@Atbl_AGENCY_INFO_1_LOWINCOME_DESCRIPTION,'xxnull') != isnull(@DWTbl_AGENCY_INFO_1_LOWINCOME_DESCRIPTION,'xxnull')  
     BEGIN
     set @Field_Changed = 'AGENCY_INFO_1_LOWINCOME_DESCRIPTION'
     set @Before_Value = @DWTbl_AGENCY_INFO_1_LOWINCOME_DESCRIPTION
     set @After_Value = @Atbl_AGENCY_INFO_1_LOWINCOME_DESCRIPTION
     set @Approval_Status = 'APPROVED'
     set @approval_comment = 'Automatic'
     END
  IF @column_ctr = 27 and 
     isnull(@Atbl_AGENCY_INFO_1_WEBSITE,'xxnull') != isnull(@DWTbl_AGENCY_INFO_1_WEBSITE,'xxnull')  
     BEGIN
     set @Field_Changed = 'AGENCY_INFO_1_WEBSITE'
     set @Before_Value = @DWTbl_AGENCY_INFO_1_WEBSITE
     set @After_Value = @Atbl_AGENCY_INFO_1_WEBSITE
     set @Approval_Status = 'APPROVED'
     set @approval_comment = 'Automatic'
     END
  IF @column_ctr = 28 and 
     isnull(@Atbl_AGENCY_INFO_1_INITIATION_DATE,@runtime) != isnull(@DWTbl_AGENCY_INFO_1_INITIATION_DATE,@runtime) 
     BEGIN
     set @Field_Changed = 'AGENCY_INFO_1_INITIATION_DATE'
     set @Before_Value = @DWTbl_AGENCY_INFO_1_INITIATION_DATE
     set @After_Value = @Atbl_AGENCY_INFO_1_INITIATION_DATE
     END
  IF @column_ctr = 29 and 
     isnull(@Atbl_AGENCY_DATE_FIRST_HOME_VISIT,@runtime) != isnull(@DWTbl_AGENCY_DATE_FIRST_HOME_VISIT,@runtime)  
     BEGIN
     set @Field_Changed = 'AGENCY_DATE_FIRST_HOME_VISIT'
     set @Before_Value = @DWTbl_AGENCY_DATE_FIRST_HOME_VISIT
     set @After_Value = @Atbl_AGENCY_DATE_FIRST_HOME_VISIT
     END
  IF @column_ctr = 30 and 
     isnull(@Atbl_AGENCY_INFO_1_MILEAGE_RATE,99999999) != isnull(@DWTbl_AGENCY_INFO_1_MILEAGE_RATE,99999999)  
     BEGIN
     set @Field_Changed = 'AGENCY_INFO_1_MILEAGE_RATE'
     set @Before_Value = @DWTbl_AGENCY_INFO_1_MILEAGE_RATE
     set @After_Value = @Atbl_AGENCY_INFO_1_MILEAGE_RATE
     END
  IF @column_ctr = 31 and 
     isnull(@Atbl_SERVICE_LEVEL_COVERED,'xxnull') != isnull(@DWTbl_SERVICE_LEVEL_COVERED,'xxnull')  
     BEGIN
     set @Field_Changed = 'SERVICE_LEVEL_COVERED'
     set @Before_Value = @DWTbl_SERVICE_LEVEL_COVERED
     set @After_Value = @Atbl_SERVICE_LEVEL_COVERED
     END

 -- look for an existing open changelog record:
 set @changelog_rec_id = null
 set @changelog_approval_status = null
 
 select  @changelog_rec_id = cl.rec_id 
        ,@changelog_after_value = cl.After_value
        ,@changelog_approval_status = cl.approval_status
   from dbo.Agencies_ChangeLogs cl 
  where cl.Entity_ID = @Atbl_Entity_ID 
   and Field_changed = @Field_Changed
   --and Approval_Status is null 
   and Completion_Status is null
 
  IF @Field_Changed is not null and
     @changelog_rec_id is not null
     BEGIN
        IF @After_Value = @Changelog_after_value
           -- disregard since change has already been logged:
           set @Field_Changed = null
        ELSE IF @changelog_approval_status is not null
        -- AgencyDB changed since approval status set, flag as a re-submittal:
           BEGIN
           set @Approval_Comment = 'Agency Re-submit after Approval status had been set to: ' +@Changelog_Approval_Status
           set @approval_Status = null
           END
     END

  IF @Field_Changed is not null 
  BEGIN
  
    IF @changelog_rec_id is null 
    BEGIN
      IF @transaction_nbr is null 
      BEGIN
        -- get next transaction number to log for entire change
        select @transaction_nbr = lovv.Value
              ,@lov_item_id = lovv.lov_value_id
          from dbo.LOV_names lovn
          inner join dbo.LOV_Values lovv on lovv.LOV_Name_ID = lovn.LOV_Name_ID
         where lovn.Name = 'INTEGRATION_PARMS' 
           and lovv.LOV_Item = 'TRANSACTION_NBR_AGENCIES_CHANGELOG'     

        set @transaction_nbr = isnull(@transaction_nbr,0) + 1
        update dbo.LOV_Values set Value = @transaction_nbr where LOV_Value_ID = @lov_item_id
      END
  
      insert into dbo.Agencies_Changelogs (Transaction_Nbr, Entity_ID, Site_ID, LogDate, Field_changed
                                       ,Before_Value, After_Value, Agency_DataSource
                                       ,Approval_Status, Approval_Comment)
        values (@Transaction_Nbr, @Atbl_Entity_ID, @Atbl_Site_ID, getdate(), @Field_Changed
               ,@Before_Value, @After_Value, @p_DataSource
               ,@Approval_Status, @Approval_Comment)
    END 
    
    IF @changelog_rec_id is not null and
     @changelog_after_value != @After_value 
     -- AgencyDB has changed since last change, and has not yet been approved, update changelog record:
    BEGIN
       update dbo.Agencies_Changelogs
          set After_value = @After_Value
             ,LogDate = GETDATE()
        where Rec_ID = @changelog_rec_id
    END
  END
END

----------------------------------------------------------------------------------------
-- continue in compare cursor
----------------------------------------------------------------------------------------

   FETCH next from CompareCursor
      into @Atbl_Entity_ID
          ,@Atbl_AGENCY_INFO_0_NAME
          ,@Atbl_Site_ID
          ,@Atbl_Site_Alias
          ,@Atbl_Agency_Status
          ,@Atbl_Program_ID
          ,@Atbl_Address1
          ,@Atbl_Address2
          ,@Atbl_City
          ,@Atbl_State
          ,@Atbl_ZipCode
          ,@Atbl_county
          ,@Atbl_Phone1
          ,@Atbl_Site_Address1
          ,@Atbl_Site_Address2
          ,@Atbl_Site_City
          ,@Atbl_Site_State
          ,@Atbl_Site_ZipCode
          ,@Atbl_Site_County
          ,@Atbl_Site_Phone1
          ,@Atbl_Audit_Date
          ,@Atbl_Site_Audit_Date
          ,@Atbl_Entity_Disabled
          ,@Atbl_Site_Disabled
          ,@Atbl_AGENCY_INFO_1_COUNTY
          ,@Atbl_AGENCY_INFO_1_TYPE
          ,@Atbl_AGENCY_INFO_1_LOWINCOME_CRITERA
          ,@Atbl_AGENCY_INFO_1_LOWINCOME_PERCENT
          ,@Atbl_AGENCY_INFO_1_LOWINCOME_DESCRIPTION
          ,@Atbl_AGENCY_INFO_1_WEBSITE
          ,@Atbl_AGENCY_INFO_1_INITIATION_DATE
          ,@Atbl_AGENCY_DATE_FIRST_HOME_VISIT
          ,@Atbl_AGENCY_INFO_1_MILEAGE_RATE
          ,@Atbl_SERVICE_LEVEL_COVERED
          ,@Atbl_Start_Date
          ,@Atbl_End_Date
          ,@dwtbl_Entity_Id
          ,@dwtbl_AGENCY_INFO_0_NAME
          ,@dwtbl_Site_ID
          ,@dwtbl_Site_Alias
          ,@dwtbl_Agency_Status
          ,@dwtbl_Program_ID
          ,@dwtbl_Address1
          ,@dwtbl_Address2
          ,@dwtbl_City
          ,@dwtbl_State
          ,@dwtbl_ZipCode
          ,@dwtbl_county
          ,@dwtbl_Phone1
          ,@dwtbl_Site_Address1
          ,@dwtbl_Site_Address2
          ,@dwtbl_Site_City
          ,@dwtbl_Site_State
          ,@dwtbl_Site_ZipCode
          ,@dwtbl_Site_County
          ,@dwtbl_Site_Phone1
          ,@dwtbl_Audit_Date
          ,@dwtbl_Site_Audit_Date
          ,@dwtbl_Entity_Disabled
          ,@dwtbl_Site_Disabled
          ,@dwtbl_AGENCY_INFO_1_COUNTY
          ,@dwtbl_AGENCY_INFO_1_TYPE
          ,@dwtbl_AGENCY_INFO_1_LOWINCOME_CRITERA
          ,@dwtbl_AGENCY_INFO_1_LOWINCOME_PERCENT
          ,@dwtbl_AGENCY_INFO_1_LOWINCOME_DESCRIPTION
          ,@dwtbl_AGENCY_INFO_1_WEBSITE
          ,@dwtbl_AGENCY_INFO_1_INITIATION_DATE
          ,@dwtbl_AGENCY_DATE_FIRST_HOME_VISIT
          ,@dwtbl_AGENCY_INFO_1_MILEAGE_RATE
          ,@dwtbl_SERVICE_LEVEL_COVERED
          ,@dwtbl_Start_Date
          ,@dwtbl_End_Date

END -- End of CompareCursor loop

CLOSE CompareCursor
DEALLOCATE CompareCursor




----------------------------------------------------------------------------------------
-- process approved changes'
----------------------------------------------------------------------------------------

print ' '
print 'Processing Approved Changes'
--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing Approved Changes'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @last_Entity_ID = null
set @Rec_ids_to_complete = ' '

Declare ChangesCursor Cursor for
select Rec_ID
      ,Entity_ID
      ,Site_ID
      ,Field_Changed
      ,Before_value
      ,After_Value
      ,Approval_Status
  from dbo.Agencies_Changelogs
 where Agency_Datasource = @p_Datasource
   and completion_Status is null
   and Approval_status like 'APPROVED%'
 order by Entity_ID

open ChangesCursor

FETCH next from ChangesCursor
      into @Changelog_Rec_ID
          ,@DwTbl_Entity_ID
          ,@DwTbl_Site_ID
          ,@Field_Changed
          ,@Before_value
          ,@After_Value
          ,@Approval_Status

WHILE @@FETCH_STATUS = 0
BEGIN

   IF @dwtbl_Entity_ID != isnull(@last_Entity_ID,99999999)
   BEGIN
      IF @last_Entity_ID is not null

      -- wrapup and execute sql statement
      BEGIN
         set @SQL4 = ' where Entity_ID = ' +convert(char,@last_Entity_ID)
         print @SQL1
         print @SQL2
         print @SQL3
         print @SQL4
         print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
         print 'SQL3 Length = ' +CAST(LEN(@SQL3) as varchar) +', SQL4 Length = ' +CAST(LEN(@SQL4) as varchar)
         IF upper(@p_no_exec_flag) != 'Y'
            EXEC (@SQL1+@SQL2+@SQL3+@SQL4)

         -- update changelog as completed
         set @SQL = 'update dbo.Agencies_Changelogs set completion_status = ''COMPLETED'' where Rec_ID in (' +rtrim(@Rec_ids_to_complete) +')'
         print @SQL
         IF upper(@p_no_exec_flag) != 'Y'
            EXEC (@SQL)

      END

      -- reset the SQL statement for next Team record:
      set @SQL1 = 'set nocount off update dbo.Agencies set audit_date = getdate()'
      set @SQL2 = ' '
      set @SQL3 = ' '
      set @SQL4 = ' '
      set @column_ctr = 0
      set @last_Entity_ID = @DwTbl_Entity_ID
   END

   -- continue to format SQL Strings with column updates:
   set @column_ctr = @column_ctr + 1

   IF @column_ctr > 1
      BEGIN
      set @SQL = ', '
      set @Rec_ids_to_complete = @Rec_ids_to_complete +',' +convert(char,@Changelog_Rec_ID)
      END
   ELSE 
      BEGIN
      set @SQL = ', '
      set @Rec_ids_to_complete = convert(char,@Changelog_Rec_ID)
      END

   IF @After_Value is null
      set @SQL = @SQL + ' ' +@Field_Changed +' = NULL'
   ELSE
      set @SQL = @SQL + ' ' +@Field_Changed +' = ''' +rtrim(convert(char(200),@After_Value)) +''''

   IF len(@SQL1) + len(@SQL) < 4000
      set @SQL1 = @SQL1 +@SQL
   ELSE IF len(@SQL2) + len(@SQL) < 4000
      set @SQL2 = @SQL2 +@SQL
   ELSE IF len(@SQL3) + len(@SQL) < 4000
      set @SQL3 = @SQL3 +@SQL
      

----------------------------------------------------------------------------------------
-- continue in cursor
----------------------------------------------------------------------------------------

   FETCH next from ChangesCursor
      into @Changelog_Rec_ID
          ,@DwTbl_Entity_ID
          ,@DwTbl_Site_ID
          ,@Field_Changed
          ,@Before_value
          ,@After_Value
          ,@Approval_Status

END -- End of ChangesCursor loop

CLOSE ChangesCursor
DEALLOCATE ChangesCursor

IF @last_Entity_ID is not null
   -- wrapup and execute sql statement
   BEGIN
      set @SQL4 = ' where Entity_ID = ' +rtrim(convert(char,@last_Entity_ID))
      print @SQL1
      print @SQL2
      print @SQL3
      print @SQL4
      print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
      print 'SQL3 Length = ' +CAST(LEN(@SQL3) as varchar) +', SQL4 Length = ' +CAST(LEN(@SQL4) as varchar)
      IF upper(@p_no_exec_flag) != 'Y'
         EXEC (@SQL1+@SQL2+@SQL3+@SQL4)

      -- update changelog as completed
      set @SQL = 'update dbo.Agencies_Changelogs set completion_status = ''COMPLETED'' where Rec_ID in (' +rtrim(@Rec_ids_to_complete) +')'
      print @SQL
      IF upper(@p_no_exec_flag) != 'Y'
         EXEC (@SQL)

   END

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- process REJECTED changes'
----------------------------------------------------------------------------------------

print ' '
print 'Processing Approved Changes'
--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing REJECTED Changes'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @last_Entity_ID = null
set @Rec_ids_to_complete = ' '

Declare RejectedCursor Cursor for
select Rec_ID
      ,Entity_ID
      ,Site_ID
      ,Field_Changed
      ,Before_value
      ,After_Value
      ,Approval_Status
  from dbo.Agencies_Changelogs
 where Agency_Datasource = @p_Datasource
   and completion_Status is null
   and Approval_status like 'REJECTED%'
 order by Entity_ID

open RejectedCursor

FETCH next from RejectedCursor
      into @Changelog_Rec_ID
          ,@DwTbl_Entity_ID
          ,@DwTbl_Site_ID
          ,@Field_Changed
          ,@Before_value
          ,@After_Value
          ,@Approval_Status

WHILE @@FETCH_STATUS = 0
BEGIN


   set @SQL1 = 'set nocount off update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Agencies'
      +' set audit_date = getdate()'

   IF @before_Value is null
      set @SQL1 = @SQL1 + ',' +@Field_Changed +' = NULL'
   ELSE
      set @SQL1 = @SQL1 + ',' +@Field_Changed +' = ''' +rtrim(convert(char(200),@before_Value)) +''''

   set @SQL1 = @SQL1 + ' where Entity_ID = ' +rtrim(convert(char,@DwTbl_Entity_ID))


   print @SQL1
   IF upper(@p_no_exec_flag) != 'Y'
      EXEC (@SQL1)

   -- update changelog as completed
   set @SQL = 'update dbo.Agencies_Changelogs set completion_status = ''COMPLETED'' where Rec_ID = ' +rtrim(convert(char,@Changelog_Rec_ID))
   print @SQL
   IF upper(@p_no_exec_flag) != 'Y'
      EXEC (@SQL)


----------------------------------------------------------------------------------------
-- continue in cursor
----------------------------------------------------------------------------------------

   FETCH next from RejectedCursor
      into @Changelog_Rec_ID
          ,@DwTbl_Entity_ID
          ,@DwTbl_Site_ID
          ,@Field_Changed
          ,@Before_value
          ,@After_Value
          ,@Approval_Status

END -- End of RejectedCursor loop

CLOSE RejectedCursor
DEALLOCATE RejectedCursor

----------------------------------------------------------------------------------------
--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

END /* end of stop validation */

print ' '
print 'End of Process: SP_AGENCYDB_AGENCIES_UPDATE'
GO
