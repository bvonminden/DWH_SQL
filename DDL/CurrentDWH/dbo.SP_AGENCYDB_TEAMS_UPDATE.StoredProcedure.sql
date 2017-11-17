USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_TEAMS_UPDATE]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_TEAMS_UPDATE
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_TEAMS_UPDATE]
 (@p_datasource      nvarchar(10) = null
 ,@p_no_delete_opt   nvarchar(2)  = null
 ,@p_no_exec_flag    nvarchar(10) = 'N')
AS
--
-- This script controls the update of DW Teams from the AgencyDB Teams Table
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
--   Primary_Supervisor, Secondary_Supervisor 
--   Address1, Address2, City, State, ZipCode, County, Phone1
--
--
-- IDs translated via DW/AgencyDB Non_ETO_Xref mapping:
--    Primary_Supervisor      (lookup, using DW.Entity_ID)
--    Secondary_Supervisor    (lookup, using DW.Entity_ID)
--
-- History:
--   20151029 - New Procedure.
--   20160204 - Updates to log proposed changes and to utilize an approval process.
--   20160216 - Removed the use of Disabled, to us instead the existing column of 'Entity_Disabled'.
--   20160418 - Added 3 update columns for program_id to staff, nhv, referral.


DECLARE @count          smallint
DECLARE @stop_flag      nvarchar(2)
DECLARE @Process        nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)
DECLARE @Agency_TableName   nvarchar(50)
DECLARE @Agency_Full_TableName   nvarchar(100)

set @process          = 'SP_AGENCYDB_TEAMS_UPDATE'
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
DECLARE @last_team_id    int
DECLARE @Rec_ids_to_complete  nvarchar(100)

-- AgencyDB Columns
DECLARE @Atbl_Team_Id int
DECLARE @Atbl_Team_Name nvarchar(200)
DECLARE @Atbl_Team_Effective_Date datetime
DECLARE @Atbl_Team_End_Date varchar(10)
DECLARE @Atbl_Site_ID int
DECLARE @Atbl_Site_Alias nvarchar(200)
DECLARE @Atbl_Team_Status smallint
DECLARE @Atbl_Address_Name nvarchar(100)
DECLARE @Atbl_Address1 nvarchar(100)
DECLARE @Atbl_Address2 nvarchar(100)
DECLARE @Atbl_City nvarchar(30)
DECLARE @Atbl_State char(2)
DECLARE @Atbl_ZipCode nvarchar(10)
DECLARE @Atbl_county nvarchar(50)
DECLARE @Atbl_Phone1 nvarchar(20)
DECLARE @Atbl_Entity_Disabled bit
DECLARE @Atbl_PRIMARY_SUPERVISOR int
DECLARE @Atbl_SECONDARY_SUPERVISOR int
DECLARE @Atbl_NUMERIC_FIELD_1 numeric(15, 5)
DECLARE @Atbl_TEXT_FIELD_1 nvarchar(2000)
DECLARE @Atbl_State_ID int
DECLARE @Atbl_Start_Date date
DECLARE @Atbl_End_Date date
DECLARE @atbl_Program_ID_Staff_Supervision int
DECLARE @atbl_Program_ID_NHV int
DECLARE @atbl_Program_ID_Referrals int

-- DataWarehouse columns:
DECLARE @DWTbl_Team_Id int
DECLARE @DWTbl_Team_Name nvarchar(200)
DECLARE @DWTbl_Team_Effective_Date datetime
DECLARE @DWTbl_Team_End_Date varchar(10)
DECLARE @DWTbl_Site_ID int
DECLARE @DWTbl_Site_Alias nvarchar(200)
DECLARE @DWTbl_Team_Status smallint
DECLARE @DWTbl_Address_Name nvarchar(100)
DECLARE @DWTbl_Address1 nvarchar(100)
DECLARE @DWTbl_Address2 nvarchar(100)
DECLARE @DWTbl_City nvarchar(30)
DECLARE @DWTbl_State char(2)
DECLARE @DWTbl_ZipCode nvarchar(10)
DECLARE @DWTbl_county nvarchar(50)
DECLARE @DWTbl_Phone1 nvarchar(20)
DECLARE @DWTbl_Entity_Disabled bit
DECLARE @DWTbl_PRIMARY_SUPERVISOR int
DECLARE @DWTbl_SECONDARY_SUPERVISOR int
DECLARE @DWTbl_NUMERIC_FIELD_1 numeric(15, 5)
DECLARE @DWTbl_TEXT_FIELD_1 nvarchar(2000)
DECLARE @DWTbl_State_ID int
DECLARE @DWTbl_Start_Date date
DECLARE @DWTbl_End_Date date
DECLARE @dwtbl_Program_ID_Staff_Supervision int
DECLARE @dwtbl_Program_ID_NHV int
DECLARE @dwtbl_Program_ID_Referrals int

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)
DECLARE @SQL1           varchar(MAX)
DECLARE @SQL2           varchar(MAX)
DECLARE @SQL3           varchar(MAX)
DECLARE @SQL4           varchar(MAX)

print 'Processing SP_AGENCYDB_TEAMS_UPDATE: Datasource = ' +isnull(@p_datasource,'NULL')
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
----------------------------------------------------------------------------------------
print ' '
print 'Preparing Comparison records - Teams_AgencyDB_Records'
----------------------------------------------------------------------------------------

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
    +' delete from dbo.Teams_AgencyDB_Records'
    +' where Team_ID in ('
    +' select dwtbl.Team_ID'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Teams Atbl'
    +' inner join dbo.Teams_AgencyDB_Records dwtbl'
    +'   on Atbl.Team_ID = dwtbl.Team_ID
 where dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.Site_ID) is null'
    +')'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
      EXEC (@SQL)


-- Bring a local copy of the AgencyDB records for comparison:
-- ** replace the Site_ID coming from the AgencDB with the DW Site_Id (resolves data removal by Agency)
print ' '
print ' '
print 'Build temporary copy of AgencyDB Record'
set @SQL1 = 'set nocount off'
    +' insert into dbo.Teams_AgencyDB_Records '
    +'([Team_Id]'
    +',[Team_Name]'
    +',[Team_Effective_Date]'
    +',[Team_End_Date]'
    +',[NC_ID_NSO_1]'
    +',[NC_ID_NSO_2]'
    +',[NC_ID_SNC_1]'
    +',[NC_ID_SNC_2]'
    +',[Site_ID]'
    +',[Site_Alias]'
    +',[Entity_Type_ID]'
    +',[Entity_Type]'
    +',[Entity_Subtype]'
    +',[Entity_Subtype_ID]'
    +',[Team_Status]'
    +',[Address_Name]'
    +',[Address1]'
    +',[Address2]'
    +',[City]'
    +',[State]'
    +',[ZipCode]'
    +',[county]'
    +',[Phone1]'
    +',[Date_Created]'
    +',[Audit_Date]'
    +',[Audit_Staff_ID]'
    +',[Entity_Disabled]'
    +',[Last_CRM_Update]'
    +',[flag_update_crm]'
    +',[CRM_ID]'
    +',[DataSource]'
    +',[Last_attribute_Update]'
    +',[PRIMARY_SUPERVISOR]'
    +',[SECONDARY_SUPERVISOR]'
    +',[NUMERIC_FIELD_1]'
    +',[TEXT_FIELD_1]'
    +',[Program_ID_Staff_Supervision]'
    +',[Program_ID_NHV]'
    +',[Program_ID_Referrals]'
    +',[Programs_Audit_Date]'
    +',[State_ID])'
set @SQL2 = ' select Atbl.[Team_Id]'
    +',Atbl.[Team_Name]'
    +',Atbl.[Team_Effective_Date]'
    +',Atbl.[Team_End_Date]'
    +',Atbl.[NC_ID_NSO_1]'
    +',Atbl.[NC_ID_NSO_2]'
    +',Atbl.[NC_ID_SNC_1]'
    +',Atbl.[NC_ID_SNC_2]'
    +',dwtbl.[Site_ID]'
    +',Atbl.[Site_Alias]'
    +',Atbl.[Entity_Type_ID]'
    +',Atbl.[Entity_Type]'
    +',Atbl.[Entity_Subtype]'
    +',Atbl.[Entity_Subtype_ID]'
    +',Atbl.[Team_Status]'
    +',Atbl.[Address_Name]'
    +',Atbl.[Address1]'
    +',Atbl.[Address2]'
    +',Atbl.[City]'
    +',Atbl.[State]'
    +',Atbl.[ZipCode]'
    +',Atbl.[county]'
    +',Atbl.[Phone1]'
    +',Atbl.[Date_Created]'
    +',Atbl.[Audit_Date]'
    +',Atbl.[Audit_Staff_ID]'
    +',Atbl.[Entity_Disabled]'
    +',Atbl.[Last_CRM_Update]'
    +',Atbl.[flag_update_crm]'
    +',Atbl.[CRM_ID]'
    +',Atbl.[DataSource]'
    +',Atbl.[Last_attribute_Update]'
    +',Atbl.[PRIMARY_SUPERVISOR]'
    +',Atbl.[SECONDARY_SUPERVISOR]'
    +',Atbl.[NUMERIC_FIELD_1]'
    +',Atbl.[TEXT_FIELD_1]'
    +',Atbl.[Program_ID_Staff_Supervision]'
    +',Atbl.[Program_ID_NHV]'
    +',Atbl.[Program_ID_Referrals]'
    +',Atbl.[Programs_Audit_Date]'
    +',Atbl.[State_ID]
 from  ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Teams Atbl'
    +' inner join dbo.Teams dwtbl'
    +'   on Atbl.Team_ID = dwtbl.Team_ID
 where dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', dwtbl.Site_ID) is null'


    print @SQL1
    print @SQL2
    --print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
       EXEC (@SQL1+@SQL2)


----------------------------------------------------------------------------------------
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

select 
 temptbl.Team_ID
,temptbl.Site_ID
,temptbl.Team_Name
,temptbl.Team_Effective_Date
,temptbl.Team_End_Date
,temptbl.Address_Name
,temptbl.Address1
,temptbl.Address2
,temptbl.City
,temptbl.State
,temptbl.ZipCode
,temptbl.county
,temptbl.Phone1
,temptbl.Entity_Disabled
,exref1.Entity_Id
,exref2.Entity_ID
,temptbl.NUMERIC_FIELD_1
,temptbl.TEXT_FIELD_1
,temptbl.State_ID
,temptbl.[Program_ID_Staff_Supervision]
,temptbl.[Program_ID_NHV]
,temptbl.[Program_ID_Referrals]

,dwtbl.Site_ID
,dwtbl.Team_Name
,dwtbl.Team_Effective_Date
,dwtbl.Team_End_Date
,dwtbl.Address_Name
,dwtbl.Address1
,dwtbl.Address2
,dwtbl.City
,dwtbl.State
,dwtbl.ZipCode
,dwtbl.county
,dwtbl.Phone1
,dwtbl.Entity_Disabled
,dwtbl.PRIMARY_SUPERVISOR
,dwtbl.SECONDARY_SUPERVISOR
,dwtbl.NUMERIC_FIELD_1
,dwtbl.TEXT_FIELD_1
,dwtbl.State_ID
,dwtbl.[Program_ID_Staff_Supervision]
,dwtbl.[Program_ID_NHV]
,dwtbl.[Program_ID_Referrals]
from dbo.AgencyDB_Sites_By_DataSource asbd
inner join dbo.Teams_AgencyDB_Records temptbl
      on asbd.Site_ID = temptbl.site_id
inner join dbo.Teams dwtbl on temptbl.Team_ID = dwtbl.Team_ID
left join dbo.Non_ETO_Entity_Xref exref1 
     on exref1.Source =  @p_datasource   
     and exref1.Non_ETO_ID = temptbl.Primary_Supervisor 
left join dbo.Non_ETO_Entity_Xref exref2 
     on exref2.Source =  @p_datasource   and exref1.Non_ETO_ID = temptbl.Secondary_Supervisor
where asbd.DataSource = @p_datasource 
  and dbo.FN_Check_Process_Inhibitor ('SP_AGENCYDB_TEAMS_UPDATE', @p_datasource, asbd.Site_ID) is null
  

open CompareCursor

FETCH next from CompareCursor
      into @Atbl_Team_ID
          ,@Atbl_Site_ID
          ,@Atbl_Team_Name
          ,@Atbl_Team_Effective_Date
          ,@Atbl_Team_End_Date
          ,@Atbl_Address_Name
          ,@Atbl_Address1
          ,@Atbl_Address2
          ,@Atbl_City
          ,@Atbl_State
          ,@Atbl_ZipCode
          ,@Atbl_county
          ,@Atbl_Phone1
          ,@Atbl_Entity_Disabled
          ,@Atbl_PRIMARY_SUPERVISOR
          ,@Atbl_SECONDARY_SUPERVISOR
          ,@Atbl_NUMERIC_FIELD_1
          ,@Atbl_TEXT_FIELD_1
          ,@Atbl_State_ID
          ,@Atbl_Program_ID_Staff_Supervision
          ,@Atbl_Program_ID_NHV
          ,@Atbl_Program_ID_Referrals
          ,@dwtbl_Site_ID
          ,@dwtbl_Team_Name
          ,@dwtbl_Team_Effective_Date
          ,@dwtbl_Team_End_Date
          ,@dwtbl_Address_Name
          ,@dwtbl_Address1
          ,@dwtbl_Address2
          ,@dwtbl_City
          ,@dwtbl_State
          ,@dwtbl_ZipCode
          ,@dwtbl_county
          ,@dwtbl_Phone1
          ,@dwtbl_Entity_Disabled
          ,@dwtbl_PRIMARY_SUPERVISOR
          ,@dwtbl_SECONDARY_SUPERVISOR
          ,@dwtbl_NUMERIC_FIELD_1
          ,@dwtbl_TEXT_FIELD_1
          ,@dwtbl_State_ID
          ,@dwtbl_Program_ID_Staff_Supervision
          ,@dwtbl_Program_ID_NHV
          ,@dwtbl_Program_ID_Referrals

WHILE @@FETCH_STATUS = 0
BEGIN
  
-- Evaluate each column, looking for changes

set @column_ctr = 0
set @transaction_nbr = null
WHILE @column_ctr < 20
BEGIN

 set @column_ctr = @column_ctr + 1
 set @Field_Changed = null
 set @Approval_Status = null
 set @approval_comment = null

   
  IF @column_ctr = 1 and 
     isnull(@Atbl_Team_Name,'xxnull') != isnull(@DWTbl_Team_Name,'xxnull') 
     BEGIN
     set @Field_Changed = 'Team_Name'
     set @Before_Value = @DWTbl_Team_Name
     set @After_Value = @Atbl_Team_Name
     END
  IF @column_ctr = 2 and 
     isnull(@Atbl_Team_Effective_Date,@runtime) != isnull(@DWTbl_Team_Effective_Date,@runtime)  
     BEGIN
     set @Field_Changed = 'Team_Effective_Date'
     set @Before_Value = @DWTbl_Team_Effective_Date
     set @After_Value = @Atbl_Team_Effective_Date
     END
  IF @column_ctr = 3 and 
     isnull(@Atbl_Team_End_Date,@runtime) != isnull(@DWTbl_Team_End_Date,@runtime)  
     BEGIN
     set @Field_Changed = 'Team_End_Date'
     set @Before_Value = @DWTbl_Team_End_Date
     set @After_Value = @Atbl_Team_End_Date
     END
  IF @column_ctr = 4 and 
     isnull(@Atbl_Address_Name,'xxnull') != isnull(@DWTbl_Address_Name,'xxnull') 
     BEGIN
     set @Field_Changed = 'Address_Name'
     set @Before_Value = @DWTbl_Address_Name
     set @After_Value = @Atbl_Address_Name
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
     isnull(@Atbl_Entity_Disabled,0) != isnull(@DWTbl_Entity_Disabled,0)  
     BEGIN
     set @Field_Changed = 'Entity_Disabled'
     set @Before_Value = @DWTbl_Entity_Disabled
     set @After_Value = @Atbl_Entity_Disabled
     END
  IF @column_ctr = 13 and 
     isnull(@Atbl_PRIMARY_SUPERVISOR,999999999) != isnull(@DWTbl_PRIMARY_SUPERVISOR,999999999)  
     BEGIN
     set @Field_Changed = 'PRIMARY_SUPERVISOR'
     set @Before_Value = @DWTbl_PRIMARY_SUPERVISOR
     set @After_Value = @Atbl_PRIMARY_SUPERVISOR
     set @Approval_Status = 'APPROVED'
     set @approval_comment = 'Automatic'
     END
  IF @column_ctr = 14 and 
     isnull(@Atbl_SECONDARY_SUPERVISOR,9999999) != isnull(@DWTbl_SECONDARY_SUPERVISOR,9999999)  
     BEGIN
     set @Field_Changed = 'SECONDARY_SUPERVISOR'
     set @Before_Value = @DWTbl_SECONDARY_SUPERVISOR
     set @After_Value = @Atbl_SECONDARY_SUPERVISOR
     set @Approval_Status = 'APPROVED'
     set @approval_comment = 'Automatic'
     END
  IF @column_ctr = 15 and 
     isnull(@Atbl_NUMERIC_FIELD_1,999999999) != isnull(@DWTbl_NUMERIC_FIELD_1,999999999)  
     BEGIN
     set @Field_Changed = 'NUMERIC_FIELD_1'
     set @Before_Value = @DWTbl_NUMERIC_FIELD_1
     set @After_Value = @Atbl_NUMERIC_FIELD_1 
     END
  IF @column_ctr = 16 and 
     isnull(@Atbl_TEXT_FIELD_1,'xxnull') != isnull(@DWTbl_TEXT_FIELD_1,'xxnull')  
     BEGIN
     set @Field_Changed = 'TEXT_FIELD_1'
     set @Before_Value = @DWTbl_TEXT_FIELD_1
     set @After_Value = @Atbl_TEXT_FIELD_1
     END
  IF @column_ctr = 17 and 
     isnull(@Atbl_State_ID,999999999) != isnull(@DWTbl_State_ID,999999999)  
     BEGIN
     set @Field_Changed = 'State_ID'
     set @Before_Value = @DWTbl_State_ID
     set @After_Value = @Atbl_State_ID
     END
  IF @column_ctr = 18 and 
     isnull(@Atbl_Program_ID_Staff_Supervision,999999999) != isnull(@DWTbl_Program_ID_Staff_Supervision,999999999)  
     BEGIN
     set @Field_Changed = 'Program_ID_Staff_Supervision'
     set @Before_Value = @DWTbl_Program_ID_Staff_Supervision
     set @After_Value = @Atbl_Program_ID_Staff_Supervision
     --set @Approval_Status = 'APPROVED'
     --set @approval_comment = 'Automatic'
     END
  IF @column_ctr = 19 and 
     isnull(@Atbl_Program_ID_NHV,999999999) != isnull(@DWTbl_Program_ID_NHV,999999999)  
     BEGIN
     set @Field_Changed = 'Program_ID_NHV'
     set @Before_Value = @DWTbl_Program_ID_NHV
     set @After_Value = @Atbl_Program_ID_NHV
     --set @Approval_Status = 'APPROVED'
     --set @approval_comment = 'Automatic'
     END
  IF @column_ctr = 20 and 
     isnull(@Atbl_Program_ID_Referrals,999999999) != isnull(@DWTbl_Program_ID_Referrals,999999999)  
     BEGIN
     set @Field_Changed = 'Program_ID_Referrals'
     set @Before_Value = @DWTbl_Program_ID_Referrals
     set @After_Value = @Atbl_Program_ID_Referrals
     --set @Approval_Status = 'APPROVED'
     --set @approval_comment = 'Automatic'
     END

 -- look for an existing open changelog record:
 set @changelog_rec_id = null
 set @changelog_approval_status = null
 
 select  @changelog_rec_id = cl.rec_id 
        ,@changelog_after_value = cl.After_value
        ,@changelog_approval_status = cl.approval_status
   from dbo.Teams_ChangeLogs cl 
  where cl.team_id = @Atbl_Team_ID 
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
           and lovv.LOV_Item = 'TRANSACTION_NBR_TEAMS_CHANGELOG'     

        set @transaction_nbr = isnull(@transaction_nbr,0) + 1
        update dbo.LOV_Values set Value = @transaction_nbr where LOV_Value_ID = @lov_item_id
      END
  
      insert into dbo.Teams_Changelogs (Transaction_Nbr, Team_ID, Site_ID, LogDate, Field_changed
                                       ,Before_Value, After_Value, Agency_DataSource
                                       ,Approval_Status, Approval_Comment)
        values (@Transaction_Nbr, @Atbl_Team_ID, @Atbl_Site_ID, getdate(), @Field_Changed
               ,@Before_Value, @After_Value, @p_DataSource
               ,@Approval_Status, @Approval_Comment)
    END 
    
    IF @changelog_rec_id is not null and
     @changelog_after_value != @After_value 
     -- AgencyDB has changed since last change, and has not yet been approved, update changelog record:
    BEGIN
       update dbo.Teams_Changelogs
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
      into @Atbl_Team_ID
          ,@Atbl_Site_ID
          ,@Atbl_Team_Name
          ,@Atbl_Team_Effective_Date
          ,@Atbl_Team_End_Date
          ,@Atbl_Address_Name
          ,@Atbl_Address1
          ,@Atbl_Address2
          ,@Atbl_City
          ,@Atbl_State
          ,@Atbl_ZipCode
          ,@Atbl_county
          ,@Atbl_Phone1
          ,@Atbl_Entity_Disabled
          ,@Atbl_PRIMARY_SUPERVISOR
          ,@Atbl_SECONDARY_SUPERVISOR
          ,@Atbl_NUMERIC_FIELD_1
          ,@Atbl_TEXT_FIELD_1
          ,@Atbl_State_ID
          ,@Atbl_Program_ID_Staff_Supervision
          ,@Atbl_Program_ID_NHV
          ,@Atbl_Program_ID_Referrals
          ,@dwtbl_Site_ID
          ,@dwtbl_Team_Name
          ,@dwtbl_Team_Effective_Date
          ,@dwtbl_Team_End_Date
          ,@dwtbl_Address_Name
          ,@dwtbl_Address1
          ,@dwtbl_Address2
          ,@dwtbl_City
          ,@dwtbl_State
          ,@dwtbl_ZipCode
          ,@dwtbl_county
          ,@dwtbl_Phone1
          ,@dwtbl_Entity_Disabled
          ,@dwtbl_PRIMARY_SUPERVISOR
          ,@dwtbl_SECONDARY_SUPERVISOR
          ,@dwtbl_NUMERIC_FIELD_1
          ,@dwtbl_TEXT_FIELD_1
          ,@dwtbl_State_ID
          ,@dwtbl_Program_ID_Staff_Supervision
          ,@dwtbl_Program_ID_NHV
          ,@dwtbl_Program_ID_Referrals

END -- End of CompareCursor loop

CLOSE CompareCursor
DEALLOCATE CompareCursor



----------------------------------------------------------------------------------------
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

set @last_team_id = null
set @Rec_ids_to_complete = ' '

Declare ChangesCursor Cursor for
select Rec_ID
      ,Team_ID
      ,Site_ID
      ,Field_Changed
      ,Before_value
      ,After_Value
      ,Approval_Status
  from dbo.Teams_Changelogs
 where Agency_Datasource = @p_Datasource
   and completion_Status is null
   and Approval_status like 'APPROVED%'
 order by team_id, Rec_ID

open ChangesCursor

FETCH next from ChangesCursor
      into @Changelog_Rec_ID
          ,@DwTbl_Team_ID
          ,@DwTbl_Site_ID
          ,@Field_Changed
          ,@Before_value
          ,@After_Value
          ,@Approval_Status

WHILE @@FETCH_STATUS = 0
BEGIN

   IF @dwtbl_team_id != isnull(@last_team_ID,99999999)
   BEGIN
      IF @last_team_ID is not null

      -- wrapup and execute sql statement
      BEGIN
         set @SQL4 = ' where team_id = ' +convert(char,@last_team_ID)
         print @SQL1
         print @SQL2
         print @SQL3
         print @SQL4
         --print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
         --print 'SQL3 Length = ' +CAST(LEN(@SQL3) as varchar) +', SQL4 Length = ' +CAST(LEN(@SQL4) as varchar)
         IF upper(@p_no_exec_flag) != 'Y'
            EXEC (@SQL1+@SQL2+@SQL3+@SQL4)

         -- update changelog as completed
         set @SQL = 'update dbo.Teams_Changelogs set completion_status = ''COMPLETED'' where Rec_ID in (' +rtrim(@Rec_ids_to_complete) +')'
         print @SQL
         IF upper(@p_no_exec_flag) != 'Y'
            EXEC (@SQL)

      END

      -- reset the SQL statement for next Team record:
      set @SQL1 = 'set nocount off update dbo.Teams set audit_date = getdate()'
      set @SQL2 = ' '
      set @SQL3 = ' '
      set @SQL4 = ' '
      set @column_ctr = 0
      set @last_team_ID = @DwTbl_Team_ID
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
          ,@DwTbl_Team_ID
          ,@DwTbl_Site_ID
          ,@Field_Changed
          ,@Before_value
          ,@After_Value
          ,@Approval_Status

END -- End of ChangesCursor loop

CLOSE ChangesCursor
DEALLOCATE ChangesCursor

IF @last_team_ID is not null
   -- wrapup and execute sql statement
   BEGIN
      set @SQL4 = ' where team_id = ' +rtrim(convert(char,@last_team_ID))
      print @SQL1
      print @SQL2
      print @SQL3
      print @SQL4
      --print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
      --print 'SQL3 Length = ' +CAST(LEN(@SQL3) as varchar) +', SQL4 Length = ' +CAST(LEN(@SQL4) as varchar)
      IF upper(@p_no_exec_flag) != 'Y'
         EXEC (@SQL1+@SQL2+@SQL3+@SQL4)

      -- update changelog as completed
      set @SQL = 'update dbo.Teams_Changelogs set completion_status = ''COMPLETED'' where Rec_ID in (' +rtrim(@Rec_ids_to_complete) +')'
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

set @last_team_id = null
set @Rec_ids_to_complete = ' '

Declare RejectedCursor Cursor for
select Rec_ID
      ,Team_ID
      ,Site_ID
      ,Field_Changed
      ,Before_value
      ,After_Value
      ,Approval_Status
  from dbo.Teams_Changelogs
 where Agency_Datasource = @p_Datasource
   and completion_Status is null
   and Approval_status like 'REJECTED%'
 order by team_id

open RejectedCursor

FETCH next from RejectedCursor
      into @Changelog_Rec_ID
          ,@DwTbl_Team_ID
          ,@DwTbl_Site_ID
          ,@Field_Changed
          ,@Before_value
          ,@After_Value
          ,@Approval_Status

WHILE @@FETCH_STATUS = 0
BEGIN


   set @SQL1 = 'set nocount off update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Teams'
      +' set audit_date = getdate()'

   IF @before_Value is null
      set @SQL1 = @SQL1 + ',' +@Field_Changed +' = NULL'
   ELSE
      set @SQL1 = @SQL1 + ',' +@Field_Changed +' = ''' +rtrim(convert(char(200),@before_Value)) +''''

   set @SQL1 = @SQL1 + ' where Team_ID = ' +rtrim(convert(char,@DwTbl_Team_ID))


   print @SQL1
   IF upper(@p_no_exec_flag) != 'Y'
      EXEC (@SQL1)

   -- update changelog as completed
   set @SQL = 'update dbo.Teams_Changelogs set completion_status = ''COMPLETED'' where Rec_ID = ' +rtrim(convert(char,@Changelog_Rec_ID))
   print @SQL
   IF upper(@p_no_exec_flag) != 'Y'
      EXEC (@SQL)


----------------------------------------------------------------------------------------
-- continue in cursor
----------------------------------------------------------------------------------------

   FETCH next from RejectedCursor
      into @Changelog_Rec_ID
          ,@DwTbl_Team_ID
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
print 'End of Process: SP_AGENCYDB_TEAMS_UPDATE'
GO
