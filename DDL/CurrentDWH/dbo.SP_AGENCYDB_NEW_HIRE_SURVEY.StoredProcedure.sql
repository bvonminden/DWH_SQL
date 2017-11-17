USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_NEW_HIRE_SURVEY]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_NEW_HIRE_SURVEY
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_NEW_HIRE_SURVEY]
 (@p_datasource      nvarchar(10) = null
 ,@p_no_delete_opt   nvarchar(2)  = null
 ,@p_no_exec_flag    nvarchar(10) = 'N')
AS
--
-- This script controls integration of AgencyDB Surveys to the Data Warehouse 
-- NEW_HIRE_SURVEY table.
--
-- Will exclude from DW if Site Does not exist in dbo.agencies
--
--
-- History:
--   20130820 - New Procedure.
--   20140326 - Added Site_ID qualifier by datasource, to allow multiple datasources to share the same AgencyDB.
--              Added database trigger to inhibit the processing of this procedure (defaulting as always process).
--                This trigger is used to bypass the process w/o having to modify the SSIS integration packages.
--              Added site_id to non-ETO_Xref.  This will allow the site_id to represent uniqueness between companies,
--                thus allowing the same source id to be utilized by different Agencydb sites (company).
--  20140327 - Activated the Deleteion of DW survey records which no longer exist in the AgencyDB.
--  20140626 - Removed IA_StaffID (was being populated with non_eto data).
--  20140812 - Added xref lookup for New_Hire_Sup_0_Name back to Non_ETO_Entity_Xref.
--  20140917 - Added population of Master_SurveyID colummn.
--   20140930 - Changed to utilize the ETO SurveyResponse record if found, 
--              creating the xref from the client-defined ID mapping to the orig ETO_SurveyResponseID
--              Else if not identified: create new xref record with next available Non_Entity_ID in sequence.
--   20140930 - Added option to not delete records.  This is to accommodate initial AgencyDB loads 
--              of smaller incremented batches while Agecncy is cleaning up data.  Option is 'Y' to inhibit delete.
--   20150218 - Added validation to re-mapping to ensure that the eto_surveyresponseid actually exists in the DW
--              for the site id, else will bypass re-mapping (thus creating new record to DW).
--              Added update to DW. Survey table's datasource for positive re-mappings.
--              Added option to not actually execute the SQL statements, used for validation/troubleshooting purposes.
--   20160519 - Amended to never delete DW New Hire records that no longer exist within the AgencyDB.
--              These are to be retained as historical reference of actions done by NFP.
--   20161114 - Moved the preliminary Non_ETO_SurveyResponse_xref processing to a common sub procedure for AgencyDB processing
--              named: dbo.SP_AGENCYDB_Survey_Non_ETO_Xref_Process.

DECLARE @count          smallint
DECLARE @stop_flag      nvarchar(2)
DECLARE @Process        nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)
DECLARE @Agency_TableName        nvarchar(50)
DECLARE @Agency_Full_TableName   nvarchar(100)

set @process          = 'SP_AGENCYDB_NEW_HIRE_SURVEY'
set @DW_Tablename     = 'NEW_HIRE_SURVEY'
set @Agency_Tablename = 'NEW_HIRE_SURVEY'
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)

print 'Processing SP_AGENCYDB_NEW_HIRE_SURVEY: Datasource = ' +isnull(@p_datasource,'NULL')
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
print 'Process Non_ETO_SurveyResponse_Xref maintenance'
print 'AgencyDB Server=' +@AgencyDB_Srvr

-- Extraction for Client:

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Non_ETO_SurveyResponse_Xref maintenance'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- Call sub procedure to process the non_ETO_Xref maintenance (remapping, ID changes, New xrefs, etc)
-- Parameters: process, datasource, DW_Tablename, Agency_Full_TableName, no_exec_flag

exec dbo.SP_AGENCYDB_Survey_Non_ETO_Xref_Process @process, @p_datasource, @DW_TableName, @Agency_Full_TableName, @p_no_exec_flag


----------------------------------------------------------------------------------------
print 'Cont: Insert new Records - AgencyDB=' + @AgencyDB
print 'AgencyDB Server=' +@AgencyDB_Srvr

-- Extraction for Client:

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------


set @SQL = 'set nocount off'
    +' insert into dbo.NEW_HIRE_SURVEY'
    +' ([SurveyResponseID],[DataSource],[ElementsProcessed]'
    +' ,[SurveyID]'
    +' ,[SurveyDate]'
    +' ,[AuditDate]'
    --+' ,[CL_EN_GEN_ID]'
    +' ,[SiteID]'
    +' ,[ProgramID]'
    --+' ,[IA_StaffID]'
    --+' ,[ClientID]'
    --+' ,[RespondentID]'
    +' ,[Validation_Ind]'
    +' ,[Validation_Comment]'
    +' ,[Entity_ID_Mapped]'
    +' ,[NEW_HIRE_0_HIRE_DATE]'
    +' ,[NEW_HIRE_1_NAME_FIRST]'
    +' ,[NEW_HIRE_0_NAME_LAST]'
    +' ,[NEW_HIRE_1_ROLE]'
    +' ,[NEW_HIRE_ADDRESS_1_STREET]'
    +' ,[NEW_HIRE_ADDRESS_1_CITY]'
    +' ,[NEW_HIRE_ADDRESS_1_STATE]'
    +' ,[NEW_HIRE_ADDRESS_0_ZIP]'
    +' ,[NEW_HIRE_0_PHONE]'
    +' ,[NEW_HIRE_0_EMAIL]'
    +' ,[NEW_HIRE_SUP_0_PHONE]'
    +' ,[NEW_HIRE_SUP_0_EMAIL]'
    +' ,[NEW_HIRE_0_REASON_FOR_HIRE]'
    +' ,[NEW_HIRE_0_REASON_FOR_HIRE_REPLACE]'
    +' ,[NEW_HIRE_0_FTE]'
    +' ,[NEW_HIRE_0_PREVIOUS_NFP_WORK]'
    +' ,[NEW_HIRE_0_REASON_NFP_WORK_DESC]'
    +' ,[NEW_HIRE_0_EDUC_COMPLETED]'
    +' ,[NEW_HIRE_0_START_DATE]'
    +' ,[NEW_HIRE_SUP_0_NAME]'
    +' ,[NEW_HIRE_0_TEAM_NAME]'
    +' ,[NEW_HIRE_0_ACCESS_LEVEL]'
    +' ,[DISP_CODE]'
    +' ,[REVIEWED_BY]'
    +' ,[REVIEWED_DATE]'
    +' ,[ADDED_TO_ETO]'
    +' ,[ADDED_TO_ETO_BY]'
    +' ,[ETO_LOGIN_EMAILED]'
    +' ,[ETO_LOGIN_EMAILED_BY]'
    +' ,[ADDED_TO_CMS]'
    +' ,[ADDED_TO_CMS_BY]'
    +' ,[GEN_COMMENTS]'
    +' ,[CHANGE_STATUS_COMPLETED]'
    +' ,[NEW_HIRE_1_DOB]'
    +' ,[NEW_HIRE_1_PREVIOUS_WORK_AGENCY]'
    +' ,[NEW_HIRE_1_PREVIOUS_WORK_CITY]'
    +' ,[NEW_HIRE_1_PREVIOUS_WORK_DATE1]'
    +' ,[NEW_HIRE_1_PREVIOUS_WORK_DATE2]'
    +' ,[NEW_HIRE_1_PREVIOUS_WORK_NAME]'
    +' ,[NEW_HIRE_1_PREVIOUS_WORK_STATE]'
    +' ,[NEW_HIRE_1_REPLACE_STAFF_TERM]'
    +' ,[NEW_HIRE_ER_0_LNAME]'
    +' ,[NEW_HIRE_ER_1_FNAME]'
    +' ,[NEW_HIRE_ER_1_PHONE]'
    +' ,[NEW_HIRE_ADDRESS_1_STATE_OTHR]'
    +' ,[NEW_HIRE_SUP_0_NAME_OTHR]'
    +' ,[NEW_HIRE_ADDITIONAL_INFO]'
    +' ,[Master_SurveyID]'
    +' ,[DW_AuditDate])'
    +'
     SELECT  DW_SurveyResponseID as SurveyResponseID, ''' +@p_datasource +''''
    +' ,1'
    +' ,Atbl.[SurveyID]'
    +' ,Atbl.[SurveyDate]'
    +' ,Atbl.[AuditDate]'
    --+' ,Atbl.[CL_EN_GEN_ID]'
    +' ,Atbl.[SiteID]'
    +' ,Atbl.[ProgramID]'
    --+' ,Atbl.[IA_StaffID]'
    --+' ,Atbl.[ClientID]'
    --+' ,Atbl.[RespondentID]'
    +' ,Atbl.[Validation_Ind]'
    +' ,Atbl.[Validation_Comment]'
    +' ,Atbl.[Entity_ID_Mapped]'
    +' ,Atbl.[NEW_HIRE_0_HIRE_DATE]'
    +' ,Atbl.[NEW_HIRE_1_NAME_FIRST]'
    +' ,Atbl.[NEW_HIRE_0_NAME_LAST]'
    +' ,Atbl.[NEW_HIRE_1_ROLE]'
    +' ,Atbl.[NEW_HIRE_ADDRESS_1_STREET]'
    +' ,Atbl.[NEW_HIRE_ADDRESS_1_CITY]'
    +' ,Atbl.[NEW_HIRE_ADDRESS_1_STATE]'
    +' ,Atbl.[NEW_HIRE_ADDRESS_0_ZIP]'
    +' ,Atbl.[NEW_HIRE_0_PHONE]'
    +' ,Atbl.[NEW_HIRE_0_EMAIL]'
    +' ,Atbl.[NEW_HIRE_SUP_0_PHONE]'
    +' ,Atbl.[NEW_HIRE_SUP_0_EMAIL]'
    +' ,Atbl.[NEW_HIRE_0_REASON_FOR_HIRE]'
    +' ,Atbl.[NEW_HIRE_0_REASON_FOR_HIRE_REPLACE]'
    +' ,Atbl.[NEW_HIRE_0_FTE]'
    +' ,Atbl.[NEW_HIRE_0_PREVIOUS_NFP_WORK]'
    +' ,Atbl.[NEW_HIRE_0_REASON_NFP_WORK_DESC]'
    +' ,Atbl.[NEW_HIRE_0_EDUC_COMPLETED]'
    +' ,Atbl.[NEW_HIRE_0_START_DATE]'
    +' ,dwxref1.Entity_ID'                    --Atbl.[NEW_HIRE_SUP_0_NAME]'
    +' ,Atbl.[NEW_HIRE_0_TEAM_NAME]'
    +' ,Atbl.[NEW_HIRE_0_ACCESS_LEVEL]'
    +' ,Atbl.[DISP_CODE]'
    +' ,Atbl.[REVIEWED_BY]'
    +' ,Atbl.[REVIEWED_DATE]'
    +' ,Atbl.[ADDED_TO_ETO]'
    +' ,Atbl.[ADDED_TO_ETO_BY]'
    +' ,Atbl.[ETO_LOGIN_EMAILED]'
    +' ,Atbl.[ETO_LOGIN_EMAILED_BY]'
    +' ,Atbl.[ADDED_TO_CMS]'
    +' ,Atbl.[ADDED_TO_CMS_BY]'
    +' ,Atbl.[GEN_COMMENTS]'
    +' ,Atbl.[CHANGE_STATUS_COMPLETED]'
    +' ,Atbl.[NEW_HIRE_1_DOB]'
    +' ,Atbl.[NEW_HIRE_1_PREVIOUS_WORK_AGENCY]'
    +' ,Atbl.[NEW_HIRE_1_PREVIOUS_WORK_CITY]'
    +' ,Atbl.[NEW_HIRE_1_PREVIOUS_WORK_DATE1]'
    +' ,Atbl.[NEW_HIRE_1_PREVIOUS_WORK_DATE2]'
    +' ,Atbl.[NEW_HIRE_1_PREVIOUS_WORK_NAME]'
    +' ,Atbl.[NEW_HIRE_1_PREVIOUS_WORK_STATE]'
    +' ,Atbl.[NEW_HIRE_1_REPLACE_STAFF_TERM]'
    +' ,Atbl.[NEW_HIRE_ER_0_LNAME]'
    +' ,Atbl.[NEW_HIRE_ER_1_FNAME]'
    +' ,Atbl.[NEW_HIRE_ER_1_PHONE]'
    +' ,Atbl.[NEW_HIRE_ADDRESS_1_STATE_OTHR]'
    +' ,Atbl.[NEW_HIRE_SUP_0_NAME_OTHR]'
    +' ,Atbl.[NEW_HIRE_ADDITIONAL_INFO]'
    +', ms.SourceSurveyID'
    +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.NEW_HIRE_SURVEY Atbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' left join dbo.Non_ETO_Entity_Xref dwxref1 on Atbl.NEW_HIRE_SUP_0_NAME = dwxref1.Non_ETO_ID'
    +' left join dbo.Mstr_Surveys ms on Atbl.SurveyID = ms.SurveyID'
    +' where Atbl.DW_SurveyResponseID is not null'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'
    +' and not exists (select dwsurvey.SurveyResponseID'
    +' from dbo.NEW_HIRE_SURVEY dwsurvey'
    +' where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and dwsurvey.SurveyResponseID = Atbl.DW_SurveyResponseID)'
     
    print @SQL
    print 'Length = ' +CAST(LEN(@SQL) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)


----------------------------------------------------------------------------------------
print 'Cont: Update changes'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------
/*  Bypass Updates, should be one time only
set @SQL = 'set nocount off'
    +' update dbo.NEW_HIRE_SURVEY'
    +' Set [SurveyID] = Atbl.[SurveyID]'
    +', [SurveyDate] = Atbl.[SurveyDate]'
    +', [AuditDate] = Atbl.[AuditDate]'
    --+', [CL_EN_GEN_ID] = Atbl.[CL_EN_GEN_ID]'
    +', [SiteID] = Atbl.[SiteID]'
    +', [ProgramID] = Atbl.[ProgramID]'
    --+', [IA_StaffID] = Atbl.[IA_StaffID]'
    --+', [ClientID] = Atbl.[ClientID]'
    --+', [RespondentID] = Atbl.[RespondentID]'
    +', [Validation_Ind] = Atbl.[Validation_Ind]'
    +', [Validation_Comment] = Atbl.[Validation_Comment]'
    +', [Entity_ID_Mapped] = Atbl.[Entity_ID_Mapped]'
    +', [NEW_HIRE_0_HIRE_DATE] = Atbl.[NEW_HIRE_0_HIRE_DATE]'
    +', [NEW_HIRE_1_NAME_FIRST] = Atbl.[NEW_HIRE_1_NAME_FIRST]'
    +', [NEW_HIRE_0_NAME_LAST] = Atbl.[NEW_HIRE_0_NAME_LAST]'
    +', [NEW_HIRE_1_ROLE] = Atbl.[NEW_HIRE_1_ROLE]'
    +', [NEW_HIRE_ADDRESS_1_STREET] = Atbl.[NEW_HIRE_ADDRESS_1_STREET]'
    +', [NEW_HIRE_ADDRESS_1_CITY] = Atbl.[NEW_HIRE_ADDRESS_1_CITY]'
    +', [NEW_HIRE_ADDRESS_1_STATE] = Atbl.[NEW_HIRE_ADDRESS_1_STATE]'
    +', [NEW_HIRE_ADDRESS_0_ZIP] = Atbl.[NEW_HIRE_ADDRESS_0_ZIP]'
    +', [NEW_HIRE_0_PHONE] = Atbl.[NEW_HIRE_0_PHONE]'
    +', [NEW_HIRE_0_EMAIL] = Atbl.[NEW_HIRE_0_EMAIL]'
    +', [NEW_HIRE_SUP_0_PHONE] = Atbl.[NEW_HIRE_SUP_0_PHONE]'
    +', [NEW_HIRE_SUP_0_EMAIL] = Atbl.[NEW_HIRE_SUP_0_EMAIL]'
    +', [NEW_HIRE_0_REASON_FOR_HIRE] = Atbl.[NEW_HIRE_0_REASON_FOR_HIRE]'
    +', [NEW_HIRE_0_REASON_FOR_HIRE_REPLACE] = Atbl.[NEW_HIRE_0_REASON_FOR_HIRE_REPLACE]'
    +', [NEW_HIRE_0_FTE] = Atbl.[NEW_HIRE_0_FTE]'
    +', [NEW_HIRE_0_PREVIOUS_NFP_WORK] = Atbl.[NEW_HIRE_0_PREVIOUS_NFP_WORK]'
    +', [NEW_HIRE_0_REASON_NFP_WORK_DESC] = Atbl.[NEW_HIRE_0_REASON_NFP_WORK_DESC]'
    +', [NEW_HIRE_0_EDUC_COMPLETED] = Atbl.[NEW_HIRE_0_EDUC_COMPLETED]'
    +', [NEW_HIRE_0_START_DATE] = Atbl.[NEW_HIRE_0_START_DATE]'
    +', [NEW_HIRE_SUP_0_NAME] = Atbl.[NEW_HIRE_SUP_0_NAME]'
    +', [NEW_HIRE_0_TEAM_NAME] = Atbl.[NEW_HIRE_0_TEAM_NAME]'
    +', [NEW_HIRE_0_ACCESS_LEVEL] = Atbl.[NEW_HIRE_0_ACCESS_LEVEL]'
    +', [DISP_CODE] = Atbl.[DISP_CODE]'
    +', [REVIEWED_BY] = Atbl.[REVIEWED_BY]'
    +', [REVIEWED_DATE] = Atbl.[REVIEWED_DATE]'
    +', [ADDED_TO_ETO] = Atbl.[ADDED_TO_ETO]'
    +', [ADDED_TO_ETO_BY] = Atbl.[ADDED_TO_ETO_BY]'
    +', [ETO_LOGIN_EMAILED] = Atbl.[ETO_LOGIN_EMAILED]'
    +', [ETO_LOGIN_EMAILED_BY] = Atbl.[ETO_LOGIN_EMAILED_BY]'
    +', [ADDED_TO_CMS] = Atbl.[ADDED_TO_CMS]'
    +', [ADDED_TO_CMS_BY] = Atbl.[ADDED_TO_CMS_BY]'
    +', [GEN_COMMENTS] = Atbl.[GEN_COMMENTS]'
    +', [CHANGE_STATUS_COMPLETED] = Atbl.[CHANGE_STATUS_COMPLETED]'
    +', [NEW_HIRE_1_DOB] = Atbl.[NEW_HIRE_1_DOB]'
    +', [NEW_HIRE_1_PREVIOUS_WORK_AGENCY] = Atbl.[NEW_HIRE_1_PREVIOUS_WORK_AGENCY]'
    +', [NEW_HIRE_1_PREVIOUS_WORK_CITY] = Atbl.[NEW_HIRE_1_PREVIOUS_WORK_CITY]'
    +', [NEW_HIRE_1_PREVIOUS_WORK_DATE1] = Atbl.[NEW_HIRE_1_PREVIOUS_WORK_DATE1]'
    +', [NEW_HIRE_1_PREVIOUS_WORK_DATE2] = Atbl.[NEW_HIRE_1_PREVIOUS_WORK_DATE2]'
    +', [NEW_HIRE_1_PREVIOUS_WORK_NAME] = Atbl.[NEW_HIRE_1_PREVIOUS_WORK_NAME]'
    +', [NEW_HIRE_1_PREVIOUS_WORK_STATE] = Atbl.[NEW_HIRE_1_PREVIOUS_WORK_STATE]'
    +', [NEW_HIRE_1_REPLACE_STAFF_TERM] = Atbl.[NEW_HIRE_1_REPLACE_STAFF_TERM]'
    +', [NEW_HIRE_ER_0_LNAME] = Atbl.[NEW_HIRE_ER_0_LNAME]'
    +', [NEW_HIRE_ER_1_FNAME] = Atbl.[NEW_HIRE_ER_1_FNAME]'
    +', [NEW_HIRE_ER_1_PHONE] = Atbl.[NEW_HIRE_ER_1_PHONE]'
    +', [NEW_HIRE_ADDRESS_1_STATE_OTHR] = Atbl.[NEW_HIRE_ADDRESS_1_STATE_OTHR]'
    +', [NEW_HIRE_SUP_0_NAME_OTHR] = Atbl.[NEW_HIRE_SUP_0_NAME_OTHR]'
    +', [DW_AuditDate] = Atbl.[DW_AuditDate]'
    +', [DataSource] = Atbl.[DataSource]'
    +', [NEW_HIRE_ADDITIONAL_INFO] = Atbl.[NEW_HIRE_ADDITIONAL_INFO]'
    +', [Master_SurveyID] = ms.SourceSurveyID'
    +', [DW_AuditDate] = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from dbo.NEW_HIRE_SURVEY dwsurvey'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.NEW_HIRE_SURVEY Atbl'
    +' on dwsurvey.SurveyResponseID = Atbl.DW_SurveyResponseID'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' left join dbo.Mstr_Surveys ms on Atbl.SurveyID = ms.SurveyID'
    +'
     where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'
    +' and isnull(dwsurvey.AuditDate,convert(datetime,''19700101'',112)) <'
    +' isnull(Atbl.AuditDate,convert(datetime,''19700101'',112))'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)
*/  


----------------------------------------------------------------------------------------
print 'Cont: Delete Contacts that no longer exist in AgencyDB'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Deleting ETO Deletions'
      ,LogDate = getdate()
 where Process = @process
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

    print @SQL
--    IF upper(@p_no_exec_flag) != 'Y'
--    EXEC (@SQL)


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

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)

END

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

print 'End of Process: SP_AGENCYDB_NEW_HIRE_SURVEY'
GO
