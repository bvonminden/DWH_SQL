USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_PROGRAMS_UPDATE]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_PROGRAMS_UPDATE
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_PROGRAMS_UPDATE]
 (@p_datasource      nvarchar(10) = null
 ,@p_no_delete_opt   nvarchar(2)  = null
 ,@p_no_exec_flag    nvarchar(10) = 'N')
AS
--
-- This script controls the update of DW Programs from the AgencyDB Programs Table
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
--   ?? Supervisor_ID
--
--
-- IDs translated via DW/AgencyDB Non_ETO_Xref mapping:
--    Primary_Supervisor      (lookup, using DW.Entity_ID)
--    Secondary_Supervisor    (lookup, using DW.Entity_ID)
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

set @process          = 'SP_AGENCYDB_PROGRAMS_UPDATE'
set @DW_Tablename     = 'PROGRAMS'
set @Agency_Tablename = 'PROGRAMS'
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
DECLARE @last_program_id    int
DECLARE @Rec_ids_to_complete  nvarchar(100)

-- AgencyDB Columns
DECLARE @Atbl_Team_Id int
DECLARE @Atbl_Program_Id int
DECLARE @Atbl_Program_Name nvarchar(200)
DECLARE @Atbl_Site_ID int
DECLARE @Atbl_SUPERVISOR_ID int
DECLARE @Atbl_Team_Group_Name nvarchar(50)
DECLARE @Atbl_CRM_new_nfpagencylocationid uniqueidentifier
DECLARE @Atbl_Disabled bit

-- DataWarehouse columns:
DECLARE @DWTbl_Team_Id int
DECLARE @DWTbl_Program_Id int
DECLARE @DWTbl_Program_Name nvarchar(200)
DECLARE @DWTbl_Site_ID int
DECLARE @DWTbl_SUPERVISOR_ID int
DECLARE @DWTbl_Team_Group_Name nvarchar(50)
DECLARE @DWTbl_CRM_new_nfpagencylocationid uniqueidentifier
DECLARE @DWTbl_Disabled bit

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)
DECLARE @SQL1           varchar(MAX)
DECLARE @SQL2           varchar(MAX)
DECLARE @SQL3           varchar(MAX)
DECLARE @SQL4           varchar(MAX)

print 'Processing SP_AGENCYDB_PROGRAMS_UPDATE: Datasource = ' +isnull(@p_datasource,'NULL')
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
print 'Preparing Comparison records - Programs_AgencyDB_Records'
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
    +' delete from dbo.Programs_AgencyDB_Records'
    +' where Program_ID in ('
    +' select dwtbl.Program_ID'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Programs Atbl'
    +' inner join dbo.Programs_AgencyDB_Records dwtbl'
    +'   on Atbl.Program_ID = dwtbl.Program_ID
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
    +' insert into dbo.Programs_AgencyDB_Records '
    +'([Program_Id]'
    +',[Team_Id]'
    +',[Program_Name]'
    +',[Site_ID]'
    +',[SUPERVISOR_ID]'
    +',[AuditDate]'
    +',[Team_Group_Name]'
    +',[CRM_new_nfpagencylocationid]'
    +',[Disabled])'
set @SQL2 = ' select Atbl.[Program_Id]'
    +',Atbl.[Team_ID]'
    +',Atbl.[Program_Name]'
    +',dwtbl.[Site_ID]'
    +',Atbl.[SUPERVISOR_ID]'
    +',Atbl.[AuditDate]'
    +',Atbl.[Team_Group_Name]'
    +',Atbl.[CRM_new_nfpagencylocationid]'
    +',Atbl.[Disabled]
 from  ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Programs Atbl'
    +' inner join dbo.Programs dwtbl'
    +'   on Atbl.Program_ID = dwtbl.Program_ID
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
select temptbl.Program_ID
,temptbl.Team_ID
,temptbl.Site_ID
,temptbl.[Program_Name]
,exref1.Entity_ID
,temptbl.[Team_Group_Name]
,temptbl.[CRM_new_nfpagencylocationid]
,temptbl.[Disabled]
,dwtbl.Team_ID
,dwtbl.Site_ID
,dwtbl.[Program_Name]
,dwtbl.[SUPERVISOR_ID]
,dwtbl.[Team_Group_Name]
,dwtbl.[CRM_new_nfpagencylocationid]
,dwtbl.[Disabled]
from dbo.AgencyDB_Sites_By_DataSource asbd
inner join dbo.Programs_AgencyDB_Records temptbl
      on asbd.Site_ID = temptbl.site_id
inner join dbo.Programs dwtbl on temptbl.Program_ID = dwtbl.Program_ID
left join dbo.Non_ETO_Entity_Xref exref1 
     on exref1.Source =  @p_datasource   
     and exref1.Non_ETO_ID = temptbl.Supervisor_ID 
where asbd.DataSource = @p_datasource 
  and dbo.FN_Check_Process_Inhibitor ('SP_AGENCYDB_PROGRAMS_UPDATE', @p_datasource, asbd.Site_ID) is null

open CompareCursor

FETCH next from CompareCursor
      into @Atbl_Program_ID
          ,@Atbl_Team_ID
          ,@Atbl_Site_ID
          ,@Atbl_Program_Name
          ,@Atbl_SUPERVISOR_ID
          ,@Atbl_Team_Group_Name
          ,@Atbl_CRM_new_nfpagencylocationid
          ,@Atbl_Disabled
          ,@dwtbl_Team_ID
          ,@dwtbl_Site_ID
          ,@dwtbl_Program_Name
          ,@dwtbl_SUPERVISOR_ID
          ,@dwtbl_Team_Group_Name
          ,@dwtbl_CRM_new_nfpagencylocationid
          ,@dwtbl_Disabled

WHILE @@FETCH_STATUS = 0
BEGIN
  
-- Evaluate each column, looking for changes

set @column_ctr = 0
set @transaction_nbr = null
WHILE @column_ctr < 3
BEGIN

 set @column_ctr = @column_ctr + 1
 set @Field_Changed = null
 set @Approval_Status = null
 set @approval_comment = null

   
  IF @column_ctr = 1 and 
     isnull(@Atbl_Program_Name,'xxnull') != isnull(@DWTbl_Program_Name,'xxnull') 
     BEGIN
     set @Field_Changed = 'Program_Name'
     set @Before_Value = @DWTbl_Program_Name
     set @After_Value = @Atbl_Program_Name
     END
  IF @column_ctr = 2 and 
     isnull(@Atbl_SUPERVISOR_ID,999999999) != isnull(@DWTbl_SUPERVISOR_ID,999999999)  
     BEGIN
     set @Field_Changed = 'Supervisor_ID'
     set @Before_Value = @DWTbl_SUPERVISOR_ID
     set @After_Value = @Atbl_SUPERVISOR_ID
     --set @Approval_Status = 'APPROVED'
     --set @approval_comment = 'Automatic'
     END
  IF @column_ctr = 3 and 
     isnull(@Atbl_Disabled,0) != isnull(@DWTbl_Disabled,0)  
     BEGIN
     set @Field_Changed = 'Disabled'
     set @Before_Value = @DWTbl_Disabled
     set @After_Value = @Atbl_Disabled
     END

 -- look for an existing open changelog record:
 set @changelog_rec_id = null
 set @changelog_approval_status = null
 
 select  @changelog_rec_id = cl.rec_id 
        ,@changelog_after_value = cl.After_value
        ,@changelog_approval_status = cl.approval_status
   from dbo.Programs_ChangeLogs cl 
  where cl.Program_id = @Atbl_Program_ID 
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
           and lovv.LOV_Item = 'TRANSACTION_NBR_PROGRAMS_CHANGELOG'     

        set @transaction_nbr = isnull(@transaction_nbr,0) + 1
        update dbo.LOV_Values set Value = @transaction_nbr where LOV_Value_ID = @lov_item_id
      END
  
      insert into dbo.Programs_Changelogs (Transaction_Nbr, Program_ID, Team_ID,  Site_ID, LogDate, Field_changed
                                       ,Before_Value, After_Value, Agency_DataSource
                                       ,Approval_Status, Approval_Comment)
        values (@Transaction_Nbr, @Atbl_Program_ID, @Atbl_Team_ID,  @Atbl_Site_ID, getdate(), @Field_Changed
               ,@Before_Value, @After_Value, @p_DataSource
               ,@Approval_Status, @Approval_Comment)
    END 
    
    IF @changelog_rec_id is not null and
     @changelog_after_value != @After_value 
     -- AgencyDB has changed since last change, and has not yet been approved, update changelog record:
    BEGIN
       update dbo.Programs_Changelogs
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
      into @Atbl_Program_ID
          ,@Atbl_Team_ID
          ,@Atbl_Site_ID
          ,@Atbl_Program_Name
          ,@Atbl_SUPERVISOR_ID
          ,@Atbl_Team_Group_Name
          ,@Atbl_CRM_new_nfpagencylocationid
          ,@Atbl_Disabled
          ,@dwtbl_Team_ID
          ,@dwtbl_Site_ID
          ,@dwtbl_Program_Name
          ,@dwtbl_SUPERVISOR_ID
          ,@dwtbl_Team_Group_Name
          ,@dwtbl_CRM_new_nfpagencylocationid
          ,@dwtbl_Disabled

END -- End of CompareCursor loop

CLOSE CompareCursor
DEALLOCATE CompareCursor


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- process APPROVED changes'
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

set @last_program_id = null
set @Rec_ids_to_complete = ' '

Declare ChangesCursor Cursor for
select Rec_ID
      ,Program_ID
      ,Team_ID
      ,Site_ID
      ,Field_Changed
      ,Before_value
      ,After_Value
      ,Approval_Status
  from dbo.Programs_Changelogs
 where Agency_Datasource = @p_Datasource
   and completion_Status is null
   and Approval_status like 'APPROVED%'
 order by Program_id

open ChangesCursor

FETCH next from ChangesCursor
      into @Changelog_Rec_ID
          ,@DwTbl_Program_ID
          ,@DwTbl_Team_ID
          ,@DwTbl_Site_ID
          ,@Field_Changed
          ,@Before_value
          ,@After_Value
          ,@Approval_Status

WHILE @@FETCH_STATUS = 0
BEGIN

   IF @dwtbl_Program_id != isnull(@last_program_id,99999999)
   BEGIN
      IF @last_program_id is not null

      -- wrapup and execute sql statement
      BEGIN
         set @SQL4 = ' where Program_id = ' +convert(char,@last_program_id)
         print @SQL1
         print @SQL2
         print @SQL3
         print @SQL4
         --print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
         --print 'SQL3 Length = ' +CAST(LEN(@SQL3) as varchar) +', SQL4 Length = ' +CAST(LEN(@SQL4) as varchar)
         IF upper(@p_no_exec_flag) != 'Y'
            EXEC (@SQL1+@SQL2+@SQL3+@SQL4)

         -- update changelog as completed
         set @SQL = 'update dbo.Programs_Changelogs set completion_status = ''COMPLETED'' where Rec_ID in (' +rtrim(@Rec_ids_to_complete) +')'
         print @SQL
         IF upper(@p_no_exec_flag) != 'Y'
            EXEC (@SQL)

      END

      -- reset the SQL statement for next record:
      set @SQL1 = 'set nocount off update dbo.Programs set auditdate = getdate()'
      set @SQL2 = ' '
      set @SQL3 = ' '
      set @SQL4 = ' '
      set @column_ctr = 0
      set @last_program_id = @DwTbl_Program_ID
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
          ,@DwTbl_Program_ID
          ,@DwTbl_Team_ID
          ,@DwTbl_Site_ID
          ,@Field_Changed
          ,@Before_value
          ,@After_Value
          ,@Approval_Status

END -- End of ChangesCursor loop

CLOSE ChangesCursor
DEALLOCATE ChangesCursor

IF @last_program_id is not null
   -- wrapup and execute sql statement
   BEGIN
      set @SQL4 = ' where Program_id = ' +rtrim(convert(char,@last_program_id))
      print @SQL1
      print @SQL2
      print @SQL3
      print @SQL4
      --print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
      --print 'SQL3 Length = ' +CAST(LEN(@SQL3) as varchar) +', SQL4 Length = ' +CAST(LEN(@SQL4) as varchar)
      IF upper(@p_no_exec_flag) != 'Y'
         EXEC (@SQL1+@SQL2+@SQL3+@SQL4)

      -- update changelog as completed
      set @SQL = 'update dbo.Programs_Changelogs set completion_status = ''COMPLETED'' where Rec_ID in (' +rtrim(@Rec_ids_to_complete) +')'
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

set @last_Program_id = null
set @Rec_ids_to_complete = ' '

Declare RejectedCursor Cursor for
select Rec_ID
      ,Program_ID
      ,Site_ID
      ,Field_Changed
      ,Before_value
      ,After_Value
      ,Approval_Status
  from dbo.Programs_Changelogs
 where Agency_Datasource = @p_Datasource
   and completion_Status is null
   and Approval_status like 'REJECTED%'
 order by Program_id

open RejectedCursor

FETCH next from RejectedCursor
      into @Changelog_Rec_ID
          ,@DwTbl_Program_ID
          ,@DwTbl_Site_ID
          ,@Field_Changed
          ,@Before_value
          ,@After_Value
          ,@Approval_Status

WHILE @@FETCH_STATUS = 0
BEGIN


   set @SQL1 = 'set nocount off update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Programs'
      +' set audit_date = getdate()'

   IF @before_Value is null
      set @SQL1 = @SQL1 + ',' +@Field_Changed +' = NULL'
   ELSE
      set @SQL1 = @SQL1 + ',' +@Field_Changed +' = ''' +rtrim(convert(char(200),@before_Value)) +''''

   set @SQL1 = @SQL1 + ' where Program_ID = ' +rtrim(convert(char,@DwTbl_Program_ID))


   print @SQL1
   IF upper(@p_no_exec_flag) != 'Y'
      EXEC (@SQL1)

   -- update changelog as completed
   set @SQL = 'update dbo.Programs_Changelogs set completion_status = ''COMPLETED'' where Rec_ID = ' +rtrim(convert(char,@Changelog_Rec_ID))
   print @SQL
   IF upper(@p_no_exec_flag) != 'Y'
      EXEC (@SQL)


----------------------------------------------------------------------------------------
-- continue in cursor
----------------------------------------------------------------------------------------

   FETCH next from RejectedCursor
      into @Changelog_Rec_ID
          ,@DwTbl_Program_ID
          ,@DwTbl_Site_ID
          ,@Field_Changed
          ,@Before_value
          ,@After_Value
          ,@Approval_Status

END -- End of RejectedCursor loop

CLOSE RejectedCursor
DEALLOCATE RejectedCursor


----------------------------------------------------------------------------------------
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
print 'End of Process: SP_AGENCYDB_PROGRAMS_UPDATE'
GO
