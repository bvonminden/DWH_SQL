USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_EDUCATION_REGISTRATION_SURVEY]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_EDUCATION_REGISTRATION_SURVEY
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_EDUCATION_REGISTRATION_SURVEY]
 (@p_datasource      nvarchar(10) = null
 ,@p_no_delete_opt   nvarchar(2)  = null
 ,@p_no_exec_flag    nvarchar(10) = 'N')
AS
--
-- This script controls integration of AgencyDB Surveys to the Data Warehouse 
-- EDUCATION_REGISTRATION_SURVEY table.
--
-- This process will receive data from the AgencyDB, and either insert or update the Education_Registration_Survey table.
-- Additionally, data which has been updated back into the DW record outsise of normal integration, will be sent to the AgencyDB.
-- These updates to the AgencyDB will be used as informational back to the Agency concerning enrollment confirmatoins 
-- and delivery of suplemental information.
-- ** Once written from to the DW, the record will not be deleted even if it was deleted from the AgencyDB.
--    This is to preserve historical references used between multiple systems (DW/CRM/LMS).
--
--
-- Table effected - dbo.Eductation_Registration_Survey
--
-- IDs translated via DW/AgencyDB Non_ETO_Xref mapping:
--    CL_EN_GEN_ID (lookup, using DW.Entity_ID)
--
-- History:
--   20160201 - New Procedure.
--   20160407 - When updating back into the AgencyDB, set the AgencyDB.DW_AuditDate = DW.LastModified. 
--              This LastModified along with the DW.validation_ind set, will be the trigger for new changes that have occurred.
--   20160408 - Added the actual classdescription into the ClassName_Changed_To column.
--              Also added will be setting the SurveyID to the original surveyid setup from ETO.
--   20160706 - Added additional conditional logic to match siteid when looking up xrefs to entities and clients,
--              to accommodate multiple sites within the same AgencyDB, using same numbering scheme between sites.

DECLARE @count          smallint
DECLARE @stop_flag      nvarchar(2)
DECLARE @Process        nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)
DECLARE @Agency_TableName   nvarchar(50)
DECLARE @Agency_Full_TableName   nvarchar(100)

set @process          = 'SP_AGENCYDB_EDUCATION_REGISTRATION_SURVEY'
set @DW_Tablename     = 'EDUCATION_REGISTRATION_SURVEY'
set @Agency_Tablename = 'EDUCATION_REGISTRATION_SURVEY'
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)

print 'Processing SP_AGENCYDB_EDUCATION_REGISTRATION_SURVEY: Datasource = ' +isnull(@p_datasource,'NULL')
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
         ,Action = 'Start'
         ,Phase = null
         ,Comment = null
         ,index_1 = null
         ,index_2 = null
         ,index_3 = null
    where Process = @process

----------------------------------------------------------------------------------------
print 'Cont: Check for run inhibit trigger'

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
print 'Preliminary clearout for DB sync'
print 'AgencyDB Server=' +@AgencyDB_Srvr

-- Extraction for Client:

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

----------------------------------------------------------------------------------------
-- clearout secondary replicated ETO_SurveyResponseID from the AgencyDB Survey table:
-- If the ETO_SureveyResponseID is not cleared for the secondary records,
-- then the next process which creates the Non_ETO_SurveyResponse_Xref will fail
-- due to the unique constraint on SurveyResponseID (coming from the mapped ETO_SurveyResponseID)

set @SQL = ''
set @SQL = 'set nocount off 
 Declare DupsCursor cursor for
 select distinct(dups.ETO_SurveyResponseID) 
 from  ' +@Agency_Full_TableName +' dups
  where (select COUNT(*) from ' +@Agency_Full_TableName +' dups2
  where dups2.ETO_SurveyResponseID = dups.ETO_SurveyResponseID) > 1
 Declare @Dup_ETO_SurveyResponseID int
 Open DupsCursor
 Fetch next from DupsCursor into @Dup_ETO_SurveyResponseID
 While @@FETCH_STATUS = 0
 Begin 
 update ' +@Agency_Full_TableName +'
 set ETO_SurveyResponseID = null
 where SurveyResponseID in 
 (select SurveyResponseID
  from (
 select ROW_NUMBER() OVER (ORDER BY atbl.ETO_SurveyResponseID) AS Row
      ,atbl.SurveyResponseID, atbl.SurveyDate, atbl.ETO_SurveyResponseID
 from ' +@Agency_Full_TableName +' atbl
 where atbl.ETO_SurveyResponseID = @Dup_ETO_SurveyResponseID) duprecs
 where ROW > 1)
 Fetch next from DupsCursor into @Dup_ETO_SurveyResponseID
 End				
 CLOSE DupsCursor
 DEALLOCATE DupsCursor'


    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)

----------------------------------------------------------------------------------------

-- create non_ETO xref entries for new SurveyResponse records from AgencyDB (that originated from ETO):
print ' '
print 'creating non_ETO_Xref for AgencyDB surveys that have been mapped to existing DW surveys'
set @SQL = 'set nocount off '+
    ' set identity_insert dbo.non_eto_SurveyResponse_xref on '
    +' insert into dbo.Non_ETO_SurveyResponse_Xref'
    +' (SurveyResponseID, Non_ETO_ID, Non_ETO_Site_ID, Source, DW_TableName)'
    +'
     select ETO_SurveyResponseID, SurveyResponseID, Atbl.SiteID, ''' +@p_datasource +''''  +',''' +@DW_TableName +''''
    +'
     from ' +@Agency_Full_TableName +' Atbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' where isnull(Atbl.ETO_SurveyResponseID,0) != 0'
    +' and not exists (select dwxref.SurveyResponseID'
                      +' from dbo.Non_ETO_SurveyResponse_Xref dwxref'
                     +' where dwxref.source = ''' +@p_datasource +''''
                     +' and dwxref.Non_ETO_ID = Atbl.SurveyResponseID'
                     +' and dwxref.DW_tableName = ''' +@DW_TableName +''''
                     +' and dwxref.Non_ETO_Site_ID = atbl.SiteID)'
    +' and exists (select SurveyResponseID from dbo.' +@DW_TableName 
                     +' dtbl where dtbl.SurveyResponseID = ETO_SurveyResponseID'
                     +' and dtbl.siteid = Atbl.SiteID)'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)


-- update the DW Survey's datasource for any new re-mapping of non-eto-exref records to an existing ETO record:
print ' '
print 'updating dw Survey table datasource for remapped surveys'
set @SQL = 'set nocount off '+
     ' update dbo.' +@DW_TableName 
       +' set DataSource = dwxref.source'
      +' from dbo.Non_ETO_SurveyResponse_Xref dwxref'
      +' inner join ' +@DW_TableName +' dwtbl on dwxref.SurveyResponseID = dwtbl.SurveyResponseID'
            +' and dwxref.Source != isnull(dwtbl.DataSource,''ETO'')'
      +' where dwxref.source = ''' +@p_datasource +''''

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    exec (@SQL)



-- update the DW SurveyResponses table datasource for any new re-mapping of non-eto-exref records to an existing ETO record:
print ' '
print 'updating dw.surveyresponses datasource for remapped surveys'
set @SQL = 'set nocount off '+
     ' update dbo.SurveyResponses'
       +' set DataSource = dwxref.source'
      +' from dbo.Non_ETO_SurveyResponse_Xref dwxref'
      +' inner join dbo.SurveyResponses dwtbl on dwxref.SurveyResponseID = dwtbl.SurveyResponseID'
            +' and dwxref.Source != isnull(dwtbl.DataSource,''ETO'')'
      +' where dwxref.source = ''' +@p_datasource +''''

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    exec (@SQL)


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

-- For AgencyDB records that DO NOT originate from ETO:
-- create non_ETO xref entries for new SurveyResponse records from AgencyDB:
print ' '
print 'Creating xref for surveys not yet existing in DW'
set @SQL = 'set nocount off '+
    ' set identity_insert dbo.non_eto_SurveyResponse_xref off '
    +' insert into dbo.Non_ETO_SurveyResponse_Xref'
    +' (Non_ETO_ID, Non_ETO_Site_ID, Source, DW_TableName)'
    +'
     select SurveyResponseID, Atbl.SiteID, ''' +@p_datasource +''''  +',''' +@DW_TableName +''''
    +'
     from ' +@Agency_Full_TableName +' Atbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' where not exists (select dwxref.SurveyResponseID'
    +' from dbo.Non_ETO_SurveyResponse_Xref dwxref'
    +' where dwxref.source = ''' +@p_datasource +''''
    +'   and dwxref.Non_ETO_ID = Atbl.SurveyResponseID'
    +'   and dwxref.DW_tableName = ''' +@DW_TableName +''''
    +'   and dwxref.Non_ETO_Site_ID = atbl.SiteID)'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)


-- Assign new NON-ETO xref ID to new records from AgencyDB:
print ' '
print 'Updating AgencyDB source table with DW xref indexes'
set @SQL = 'set nocount off '+
    'update ' +@Agency_Full_TableName
    +' Set [DW_SurveyResponseID] = dwxref.[SurveyResponseID]'
    +'
     from ' +@Agency_Full_TableName +' Atbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' inner join dbo.Non_ETO_SurveyResponse_Xref dwxref'
       +' on dwxref.Non_ETO_ID = Atbl.SurveyResponseID and dwxref.source = ''' +@p_datasource +''''
      +' and dwxref.DW_tableName = ''' +@DW_TableName +''''
    +' Where dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)



set @SQL = 'set nocount off'
    +' insert into dbo.EDUCATION_REGISTRATION_SURVEY'
    +' ([SurveyResponseID],[DataSource],[ElementsProcessed]'
    +' ,[SurveyID]'
    +' ,[SurveyDate]'
    +' ,[AuditDate]'
    +' ,[CL_EN_GEN_ID]'
    +' ,[SiteID]'
    +' ,[ProgramID]'
    +' ,[ClassName]'
    +' ,[LMS_ClassID]'
    +', [ClassName_Changed_To]'
    +' ,[EDUC_REGISTER_0_REASON]'
    +' ,[Master_SurveyID]'
    +' ,[DW_AuditDate]'
    +')
     SELECT  DW_SurveyResponseID as SurveyResponseID, ''' +@p_datasource +''''
    +' ,1'
    +' ,isnull(ams.SurveyID,Atbl.SurveyID)'
    +' ,Atbl.[SurveyDate]'
    +' ,Atbl.[AuditDate]'
    +' ,exref1.Entity_ID'
    +' ,Atbl.[SiteID]'
    +' ,Atbl.[ProgramID]'
    +' ,Atbl.[ClassName]'
    +' ,Atbl.[LMS_ClassID]'
    +', tc.ClassDescription'
    +' ,Atbl.[EDUC_REGISTER_0_REASON]'
    +', isnull(ams.Mstr_SurveyID,ms.SourceSurveyID)'
    +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.EDUCATION_REGISTRATION_SURVEY Atbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' left join dbo.Non_ETO_Entity_Xref exref1 on exref1.Source =  ''' +@p_datasource +''''
    +'   and exref1.Non_ETO_ID = Atbl.CL_EN_GEN_ID' 
    +'   and exref1.Non_ETO_Site_ID = Atbl.SiteID' 
    +' left join dbo.Mstr_Surveys ms on Atbl.SurveyID = ms.SurveyID'
    +' left join LMSSRVR.Tracker3.dbo.Tracker_Classes tc on Atbl.LMS_ClassID = tc.classid'
    +' left join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Classes ams on Atbl.LMS_ClassID = ams.ClassID'
    +' where Atbl.DW_SurveyResponseID is not null'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'
    +' and not exists (select dwsurvey.SurveyResponseID'
    +' from dbo.EDUCATION_REGISTRATION_SURVEY dwsurvey'
    +' where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and dwsurvey.SurveyResponseID = Atbl.DW_SurveyResponseID)'
     

    print @SQL
    print 'Length = ' +CAST(LEN(@SQL) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)

--   and exists (select nfpagencies.Site_ID
--                     from dbo.Agencies nfpagencies
--                    where nfpagencies.Site_Id = Sites.SiteId);

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
print 'Update DW with changes'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL = 'set nocount off'
    +' update dbo.EDUCATION_REGISTRATION_SURVEY'
    +' Set [SurveyID] = isnull(ams.SurveyID,Atbl.SurveyID)'
    +' ,[SurveyDate] = Atbl.[SurveyDate]'
    +' ,[AuditDate] = Atbl.[AuditDate]'
    +' ,[CL_EN_GEN_ID] = exref1.Entity_ID'
    +' ,[SiteID] = Atbl.[SiteID]'
    +' ,[ProgramID] = Atbl.[ProgramID]'
    +' ,[ClassName] = Atbl.[ClassName]'
    +' ,[LMS_ClassID] = Atbl.[LMS_ClassID]'
    +' ,[EDUC_REGISTER_0_REASON] = Atbl.[EDUC_REGISTER_0_REASON]'
    +', [Master_SurveyID] =  isnull(ams.Mstr_SurveyID,ms.SourceSurveyID)'
    +', [DW_AuditDate] = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from dbo.EDUCATION_REGISTRATION_SURVEY dwsurvey'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.EDUCATION_REGISTRATION_SURVEY Atbl'
    +'   on dwsurvey.SurveyResponseID = Atbl.DW_SurveyResponseID'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' left join dbo.Non_ETO_Entity_Xref exref1 on exref1.Source =  ''' +@p_datasource +''''
    +'   and exref1.Non_ETO_ID = Atbl.CL_EN_GEN_ID'
    +'   and exref1.Non_ETO_Site_ID = Atbl.SiteID' 
    +' left join dbo.Mstr_Surveys ms on Atbl.SurveyID = ms.SurveyID' 
    +' left join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Mstr_Classes ams on Atbl.LMS_ClassID = ams.ClassID'
    +'
     where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'
    +' and isnull(dwsurvey.AuditDate,convert(datetime,''19700101'',112)) < '
    +' isnull(Atbl.AuditDate,convert(datetime,''19700101'',112))'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
print 'Update AgencyDB for information fields'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating AgencyDB Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL = 'set nocount off'
    +' update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.EDUCATION_REGISTRATION_SURVEY'
    +' Set [AuditDate] = dwsurvey.[AuditDate]'
    +' ,[Validation_Ind] = dwsurvey.[Validation_Ind]'
    +' ,[Validation_Comment] = dwsurvey.[Validation_Comment]'
    +' ,[First_Confirmation_Sent] = dwsurvey.[First_Confirmation_Sent]'
    +' ,[First_Confirmation_Sent_By] = dwsurvey.[First_Confirmation_Sent_By]'
    +' ,[Second_Confirmation_Sent] = dwsurvey.[Second_Confirmation_Sent]'
    +' ,[Second_Confirmation_Sent_By] = dwsurvey.[Second_Confirmation_Sent_By]'
    +' ,[Third_Confirmation_Sent] = dwsurvey.[Third_Confirmation_Sent]'
    +' ,[Third_Confirmation_Sent_By] = dwsurvey.[Third_Confirmation_Sent_By]'
    +' ,[Materials_Shipped] = dwsurvey.[Materials_Shipped]'
    +' ,[Materials_Shipped_By] = dwsurvey.[Materials_Shipped_By]'
    +' ,[Disposition] = dwsurvey.[Disposition]'
    +' ,[Disposition_Text] = dwsurvey.[Disposition_Text]'
    +' ,[Comments] = dwsurvey.[Comments]'
    +' ,[ClassName_Changed_To] = dwsurvey.[ClassName_Changed_To]'
    +' ,[Invoice_Nbr] = dwsurvey.[Invoice_Nbr]'
    +' ,[DW_AuditDate] = dwsurvey.LastModified'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.EDUCATION_REGISTRATION_SURVEY Atbl'
    +' inner join dbo.EDUCATION_REGISTRATION_SURVEY dwsurvey'
    +'   on dwsurvey.SurveyResponseID = Atbl.DW_SurveyResponseID'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +'
     where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'
    +' and isnull(dwsurvey.LastModified,convert(datetime,''19700101'',112)) > '
    +' isnull(Atbl.DW_AuditDate,convert(datetime,''19700101'',112))'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
       EXEC (@SQL)



----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- comment execution statements to retain historical trail between systems
-- (Code segment remains for future referece)
-- print 'Delete Survey records that no longer exist in AgencyDB'

--------- update Process Log ----------------
/*
set nocount on
update dbo.process_log 
   set Phase = 'Deleting ETO Deletions'
      ,LogDate = getdate()
 where Process = @process
*/
---------------------------------------------

if upper(isnull(@p_no_delete_opt,'n')) != 'Y'
BEGIN

set @SQL ='set nocount off '+
   ' delete dbo.' +@DW_TableName
    +' from dbo.' +@DW_TableName +' dwsurvey'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = dwsurvey.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' where dwsurvey.DataSource = ''' +@p_datasource +''''
      +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', dwsurvey.SiteID) is null'
      +' and not exists (select Atbl.DW_SurveyResponseID'
                        +' from ' +@Agency_Full_TableName +' Atbl'
                       +' where DW_SurveyResponseID = dwsurvey.SurveyResponseID)'

 --   print @SQL
 --   IF upper(@p_no_exec_flag) != 'Y'
 --   EXEC (@SQL)


-- housecleaning of xref table
print 'Cont: Delete unreferrenced xref records'
set @SQL ='set nocount off '+
   ' delete dbo.Non_ETO_SurveyResponse_Xref'
    +' from dbo.Non_ETO_SurveyResponse_Xref dwxref'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = dwxref.Non_ETO_Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''

    +' where dwxref.source = ''' +@p_datasource +''''
      +' and dwxref.DW_tableName = ''' +@DW_TableName +''''
      +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', dwxref.Non_ETO_Site_ID) is null'

    +' and not exists (select Atbl.SurveyResponseID'
                      +' from ' +@Agency_Full_TableName +' Atbl'
                     +' where SurveyResponseID = dwxref.Non_ETO_ID)'

    +' and not exists (select dwsurvey.SurveyResponseID'
                      +' from ' +@DW_TableName +' dwsurvey'
                     +' where dwsurvey.SurveyResponseID = dwxref.SurveyResponseID)'

 --   print @SQL
 --   IF upper(@p_no_exec_flag) != 'Y'
 --   EXEC (@SQL)

END

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

print 'End of Process: SP_AGENCYDB_EDUCATION_REGISTRATION_SURVEY'
GO
