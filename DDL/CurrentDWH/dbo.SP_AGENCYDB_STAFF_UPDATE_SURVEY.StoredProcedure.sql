USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_STAFF_UPDATE_SURVEY]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_STAFF_UPDATE_SURVEY
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_STAFF_UPDATE_SURVEY]
 (@p_datasource      nvarchar(10) = null
 ,@p_no_delete_opt   nvarchar(2)  = null
 ,@p_no_exec_flag    nvarchar(10) = 'N')
AS
--
-- This script controls integration of AgencyDB Surveys to the Data Warehouse 
-- Staff_Update_Survey table.
--
-- Will exclude from DW if Site Does not exist in dbo.agencies
--
-- Table effected - dbo.Clients
--
-- Insert: select and insert when record is found to be missing in the DW.
-- Update: select and update when record exists in DW and has been changed but has been changed flagged by Audit_Date.
--
-- IDs translated via DW/AgencyDB Non_ETO_Xref mapping:
--    CL_EN_GEN_ID (lookup, using DW.Entity_ID)
--
-- History:
--   20130325 - New Procedure.
--   20131206 - removed population of Entity_ID_Mapped field.  Will get populated after it's processed 
--              by the CRM push procedure.
--   20140326 - Added Site_ID qualifier by datasource, to allow multiple datasources to share the same AgencyDB.
--              Added database trigger to inhibit the processing of this procedure (defaulting as always process).
--                This trigger is used to bypass the process w/o having to modify the SSIS integration packages.
--              Added site_id to non-ETO_Xref.  This will allow the site_id to represent uniqueness between companies,
--                thus allowing the same source id to be utilized by different Agencydb sites (company).
--  20140327 - Activated the Deleteion of DW survey records which no longer exist in the AgencyDB.
--  20140626 - Removed IA_StaffID (was being populated with non_eto data).
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
--   20150604 - Added new table columns to the integration process.
--   20160706 - Added additional conditional logic to match siteid when looking up xrefs to entities and clients,
--              to accommodate multiple sites within the same AgencyDB, using same numbering scheme between sites.
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

set @process          = 'SP_AGENCYDB_STAFF_UPDATE_SURVEY'
set @DW_Tablename     = 'STAFF_UPDATE_SURVEY'
set @Agency_Tablename = 'STAFF_UPDATE_SURVEY'
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)
DECLARE @SQL1            varchar(MAX)
DECLARE @SQL2            varchar(MAX)

print 'Processing SP_AGENCYDB_STAFF_UPDATE_SURVEY: Datasource = ' +isnull(@p_datasource,'NULL')
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



set @SQL1 = 'set nocount off'
    +' insert into dbo.STAFF_UPDATE_Survey'
    +' ([SurveyResponseID],[DataSource],[ElementsProcessed]'
    +', [SurveyID]'
    +', [SurveyDate]'
    +', [AuditDate]'
    +', [CL_EN_GEN_ID]'
    +', [SiteID]'
    +', [ProgramID]'
    --+', [IA_StaffID]'
    +', [ClientID]'
    +', [RespondentID]'
    --+', [Entity_ID_Mapped]'
    +', [NURSE_STATUS_0_CHANGE_START_DATE]'
    +', [NURSE_STATUS_0_CHANGE_LEAVE_START]'
    +', [NURSE_STATUS_0_CHANGE_LEAVE_END]'
    +', [NURSE_STATUS_0_CHANGE_TERMINATE_DATE]'
    +', [NURSE_PROFESSIONAL_1_NEW_ROLE]'
    +', [NURSE_PROFESSIONAL_1_HOME_VISITOR_FTE]'
    +', [NURSE_PROFESSIONAL_1_SUPERVISOR_FTE]'
    +', [NURSE_PROFESSIONAL_1_ADMIN_ASST_FTE]'
    +', [NURSE_STATUS_0_CHANGE_SPECIFIC]'
    +', [NURSE_EDUCATION_0_NURSING_DEGREES]'
    +', [NURSE_EDUCATION_1_OTHER_DEGREES]'
    +', [DISPOSITION_CODE_0]'
    +', [ETO_LOGIN_DISABLED]'
    +', [ETO_LOGIN_DISABLED_BY]'
    +', [ETO_UPDATED]'
    +', [ETO_UPDATED_BY]'
    +', [CMS_UPDATED]'
    +', [CMS_UPDATED_BY]'
    +', [GEN_COMMENTS_0]'
    +', [NURSE_PROFESSIONAL_1_OTHER_FTE]'
    +', [NURSE_PROFESSIONAL_1_TOTAL_FTE]'
    +', [NURSE_STATUS_0_CHANGE_TRANSFER]'
    +' ,[Master_SurveyID]'
    +' ,[NURSE_STATUS_TERM_REASON]'
    +' ,[NURSE_PRIMARY_ROLE]'
    +' ,[NURSE_SECONDARY_ROLE]'
    +' ,[NURSE_STATUS_TERM_REASON_OTHER]'
    +' ,[NURSE_PRIMARY_ROLE_FTE]'
    +' ,[NURSE_SECONDARY_ROLE_FTE]'
    +' ,[NURSE_TEAM_START_DATE]'
    +' ,[NURSE_TEAM_NAME]'


    +', [DW_AuditDate])'
set @SQL2 = '
     SELECT  DW_SurveyResponseID as SurveyResponseID, ''' +@p_datasource +''''
    +' ,1'
    +', Atbl.[SurveyID]'
    +', Atbl.[SurveyDate]'
    +', Atbl.[AuditDate]'
    +' ,exref1.Entity_ID'
    +', Atbl.[SiteID]'
    +', Atbl.[ProgramID]'
    --+', Atbl.[IA_StaffID]'
    +', Atbl.[ClientID]'
    +', Atbl.[RespondentID]'
    --+', Atbl.[Entity_ID_Mapped]'
    +', Atbl.[NURSE_STATUS_0_CHANGE_START_DATE]'
    +', Atbl.[NURSE_STATUS_0_CHANGE_LEAVE_START]'
    +', Atbl.[NURSE_STATUS_0_CHANGE_LEAVE_END]'
    +', Atbl.[NURSE_STATUS_0_CHANGE_TERMINATE_DATE]'
    +', Atbl.[NURSE_PROFESSIONAL_1_NEW_ROLE]'
    +', Atbl.[NURSE_PROFESSIONAL_1_HOME_VISITOR_FTE]'
    +', Atbl.[NURSE_PROFESSIONAL_1_SUPERVISOR_FTE]'
    +', Atbl.[NURSE_PROFESSIONAL_1_ADMIN_ASST_FTE]'
    +', Atbl.[NURSE_STATUS_0_CHANGE_SPECIFIC]'
    +', Atbl.[NURSE_EDUCATION_0_NURSING_DEGREES]'
    +', Atbl.[NURSE_EDUCATION_1_OTHER_DEGREES]'
    +', Atbl.[DISPOSITION_CODE_0]'
    +', Atbl.[ETO_LOGIN_DISABLED]'
    +', Atbl.[ETO_LOGIN_DISABLED_BY]'
    +', Atbl.[ETO_UPDATED]'
    +', Atbl.[ETO_UPDATED_BY]'
    +', Atbl.[CMS_UPDATED]'
    +', Atbl.[CMS_UPDATED_BY]'
    +', Atbl.[GEN_COMMENTS_0]'
    +', Atbl.[NURSE_PROFESSIONAL_1_OTHER_FTE]'
    +', Atbl.[NURSE_PROFESSIONAL_1_TOTAL_FTE]'
    +', Atbl.[NURSE_STATUS_0_CHANGE_TRANSFER]'
    +', ms.SourceSurveyID'
    +' ,Atbl.[NURSE_STATUS_TERM_REASON]'
    +' ,Atbl.[NURSE_PRIMARY_ROLE]'
    +' ,Atbl.[NURSE_SECONDARY_ROLE]'
    +' ,Atbl.[NURSE_STATUS_TERM_REASON_OTHER]'
    +' ,Atbl.[NURSE_PRIMARY_ROLE_FTE]'
    +' ,Atbl.[NURSE_SECONDARY_ROLE_FTE]'
    +' ,Atbl.[NURSE_TEAM_START_DATE]'
    +' ,Atbl.[NURSE_TEAM_NAME]'
    +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Staff_Update_Survey Atbl' 
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' left join dbo.Non_ETO_Entity_Xref exref1 on exref1.Source =  ''' +@p_datasource +''''
    +'   and exref1.Non_ETO_ID = Atbl.CL_EN_GEN_ID'  
    +'   and exref1.Non_ETO_Site_ID = Atbl.SiteID'
    +' left join dbo.Mstr_Surveys ms on Atbl.SurveyID = ms.SurveyID'
    +' where Atbl.DW_SurveyResponseID is not null'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'
    +' and not exists (select dwsurvey.SurveyResponseID'
    +' from dbo.STAFF_UPDATE_Survey dwsurvey'
    +' where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and dwsurvey.SurveyResponseID = Atbl.DW_SurveyResponseID)'
     

    print @SQL1
    print @SQL2
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL1+@SQL2)

--   and exists (select nfpagencies.Site_ID
--                     from dbo.Agencies nfpagencies
--                    where nfpagencies.Site_Id = Sites.SiteId);

----------------------------------------------------------------------------------------
print 'Cont: Update changes'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL1 = 'set nocount off'
    +' update dbo.STAFF_UPDATE_Survey'
    +' Set [ElementsProcessed] = 1'    +', [SurveyID] = Atbl.[SurveyID]'
    +', [SurveyDate] = Atbl.[SurveyDate]'
    +', [AuditDate] = Atbl.[AuditDate]'
    +', [CL_EN_GEN_ID] = exref1.Entity_ID'
    +', [SiteID] = Atbl.[SiteID]'
    +', [ProgramID] = Atbl.[ProgramID]'
    --+', [IA_StaffID] = Atbl.[IA_StaffID]'
    +', [ClientID] = Atbl.[ClientID]'
    +', [RespondentID] = Atbl.[RespondentID]'
    +', [Entity_ID_Mapped] = Atbl.[Entity_ID_Mapped]'
    +', [NURSE_STATUS_0_CHANGE_START_DATE] = Atbl.[NURSE_STATUS_0_CHANGE_START_DATE]'
    +', [NURSE_STATUS_0_CHANGE_LEAVE_START] = Atbl.[NURSE_STATUS_0_CHANGE_LEAVE_START]'
    +', [NURSE_STATUS_0_CHANGE_LEAVE_END] = Atbl.[NURSE_STATUS_0_CHANGE_LEAVE_END]'
    +', [NURSE_STATUS_0_CHANGE_TERMINATE_DATE] = Atbl.[NURSE_STATUS_0_CHANGE_TERMINATE_DATE]'
    +', [NURSE_PROFESSIONAL_1_NEW_ROLE] = Atbl.[NURSE_PROFESSIONAL_1_NEW_ROLE]'
    +', [NURSE_PROFESSIONAL_1_HOME_VISITOR_FTE] = Atbl.[NURSE_PROFESSIONAL_1_HOME_VISITOR_FTE]'
    +', [NURSE_PROFESSIONAL_1_SUPERVISOR_FTE] = Atbl.[NURSE_PROFESSIONAL_1_SUPERVISOR_FTE]'
    +', [NURSE_PROFESSIONAL_1_ADMIN_ASST_FTE] = Atbl.[NURSE_PROFESSIONAL_1_ADMIN_ASST_FTE]'
    +', [NURSE_STATUS_0_CHANGE_SPECIFIC] = Atbl.[NURSE_STATUS_0_CHANGE_SPECIFIC]'
    +', [NURSE_EDUCATION_0_NURSING_DEGREES] = Atbl.[NURSE_EDUCATION_0_NURSING_DEGREES]'
    +', [NURSE_EDUCATION_1_OTHER_DEGREES] = Atbl.[NURSE_EDUCATION_1_OTHER_DEGREES]'
    +', [DISPOSITION_CODE_0] = Atbl.[DISPOSITION_CODE_0]'
    +', [ETO_LOGIN_DISABLED] = Atbl.[ETO_LOGIN_DISABLED]'
    +', [ETO_LOGIN_DISABLED_BY] = Atbl.[ETO_LOGIN_DISABLED_BY]'
    +', [ETO_UPDATED] = Atbl.[ETO_UPDATED]'
    +', [ETO_UPDATED_BY] = Atbl.[ETO_UPDATED_BY]'
    +', [CMS_UPDATED] = Atbl.[CMS_UPDATED]'
    +', [CMS_UPDATED_BY] = Atbl.[CMS_UPDATED_BY]'
    +', [GEN_COMMENTS_0] = Atbl.[GEN_COMMENTS_0]'
    +', [NURSE_PROFESSIONAL_1_OTHER_FTE] = Atbl.[NURSE_PROFESSIONAL_1_OTHER_FTE]'
    +', [NURSE_PROFESSIONAL_1_TOTAL_FTE] = Atbl.[NURSE_PROFESSIONAL_1_TOTAL_FTE]'
    +', [NURSE_STATUS_0_CHANGE_TRANSFER] = Atbl.[NURSE_STATUS_0_CHANGE_TRANSFER]'
    +', [Master_SurveyID] = ms.SourceSurveyID'
    +' ,[NURSE_STATUS_TERM_REASON] = Atbl.[NURSE_STATUS_TERM_REASON]'
    +' ,[NURSE_PRIMARY_ROLE] = Atbl.[NURSE_PRIMARY_ROLE]'
    +' ,[NURSE_SECONDARY_ROLE] = Atbl.[NURSE_SECONDARY_ROLE]'
    +' ,[NURSE_STATUS_TERM_REASON_OTHER] =Atbl.[NURSE_STATUS_TERM_REASON_OTHER]'
    +' ,[NURSE_PRIMARY_ROLE_FTE] = Atbl.[NURSE_PRIMARY_ROLE_FTE]'
    +' ,[NURSE_SECONDARY_ROLE_FTE] = Atbl.[NURSE_SECONDARY_ROLE_FTE]'
    +' ,[NURSE_TEAM_START_DATE] = Atbl.[NURSE_TEAM_START_DATE]'
    +' ,[NURSE_TEAM_NAME] = Atbl.[NURSE_TEAM_NAME]'
    +', [DW_AuditDate] = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from dbo.STAFF_UPDATE_Survey dwsurvey'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Staff_Update_Survey Atbl'
    +'   on dwsurvey.SurveyResponseID = Atbl.DW_SurveyResponseID'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' left join dbo.Non_ETO_Entity_Xref exref1 on exref1.Source =  ''' +@p_datasource +''''
    +'   and exref1.Non_ETO_ID = Atbl.CL_EN_GEN_ID'  
    +'   and exref1.Non_ETO_Site_ID = Atbl.SiteID'
    +' left join dbo.Mstr_Surveys ms on Atbl.SurveyID = ms.SurveyID'
    +'
     where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'
    +' and isnull(dwsurvey.AuditDate,convert(datetime,''19700101'',112)) <'
    +' isnull(Atbl.AuditDate,convert(datetime,''19700101'',112))'


    print @SQL1
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL1)



----------------------------------------------------------------------------------------
print 'Cont: Delete Contacts that no longer exist in AgencyDB'
print '  ** commented out due to historical tracking **'

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
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)


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

print 'End of Process: SP_AGENCYDB_STAFF_UPDATE_SURVEY'
GO
