USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_HOME_VISIT_ENCOUNTER_SURVEY]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_HOME_VISIT_ENCOUNTER_SURVEY
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_HOME_VISIT_ENCOUNTER_SURVEY]
 (@p_datasource      nvarchar(10) = null
 ,@p_no_delete_opt   nvarchar(2)  = null
 ,@p_no_exec_flag    nvarchar(10) = 'N')
AS
--
-- This script controls integration of AgencyDB Surveys to the Data Warehouse 
-- HOME_VISIT_ENCOUNTER_Survey table.
--
-- Will exclude from DW if Site Does not exist in dbo.agencies
--
-- Table effected - dbo.Clients
--
-- Insert: select and insert when record is found to be missing in the DW.
-- Update: select and update when record exists in DW and has been changed but has been changed flagged by Audit_Date.
--
-- IDs translated via DW/AgencyDB Non_ETO_Xref mapping:
--    CL_EN_GEN_ID (lookup, using DW.Client_ID)
--    ClientID     (lookup, using DW.Client_ID)
--    NurseID      (lookup, using DW.Entity_ID)
--
-- History:
--   20130325 - New Procedure.
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
--   20150618 - Added processing for new form fields and start/end time segments.
--   20151010 - Added additionall logging write statements.
--   20160706 - Added additional conditional logic to match siteid when looking up xrefs to entities and clients,
--              to accommodate multiple sites within the same AgencyDB, using same numbering scheme between sites.
--              Rework of delete statement for survey responses no longer existing in AgencyDB (now indexed lookup).
--   20161021 - Setup new pseudonyms for the Oct 2016 ETO release.  Retired columns will still be applied for history.
--   20161114 - Moved the preliminary Non_ETO_SurveyResponse_xref processing to a common sub procedure for AgencyDB processing
--              named: dbo.SP_AGENCYDB_Survey_Non_ETO_Xref_Process.


DECLARE @count        smallint
DECLARE @stop_flag  nvarchar(2)
DECLARE @Process      nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)
DECLARE @Agency_TableName   nvarchar(50)
DECLARE @Agency_Full_TableName   nvarchar(100)

set @process          = 'SP_AGENCYDB_HOME_VISIT_ENCOUNTER_SURVEY'
set @DW_Tablename     = 'HOME_VISIT_ENCOUNTER_SURVEY'
set @Agency_Tablename = 'HOME_VISIT_ENCOUNTER_SURVEY'
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)
DECLARE @SQL1            varchar(MAX)
DECLARE @SQL2            varchar(MAX)
DECLARE @SQL3            varchar(MAX)

print 'Processing SP_AGENCYDB_HOME_VISIT_ENCOUNTER_SURVEY: Datasource = ' +isnull(@p_datasource,'NULL')
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
    +' insert into dbo.HOME_VISIT_ENCOUNTER_Survey'
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
    +', [CLIENT_0_ID_NSO]'
    +', [CLIENT_PERSONAL_0_NAME_FIRST]'
    +', [CLIENT_PERSONAL_0_NAME_LAST]'
    +', [CLIENT_PERSONAL_0_DOB_INTAKE]'
    +', [CLIENT_TIME_0_START_VISIT]'
    +', [CLIENT_TIME_1_END_VISIT]'
    +', [NURSE_MILEAGE_0_VIS]'
    +', [NURSE_PERSONAL_0_NAME]'
    +', [CLIENT_COMPLETE_0_VISIT]'
    +', [CLIENT_LOCATION_0_VISIT]'
    +', [CLIENT_ATTENDEES_0_AT_VISIT]'
    +', [CLIENT_INVOLVE_0_CLIENT_VISIT]'
    +', [CLIENT_INVOLVE_1_GRNDMTHR_VISIT]'
    +', [CLIENT_INVOLVE_1_PARTNER_VISIT]'
    +', [CLIENT_CONFLICT_0_CLIENT_VISIT]'
    +', [CLIENT_CONFLICT_1_GRNDMTHR_VISIT]'
    +', [CLIENT_CONFLICT_1_PARTNER_VISIT]'
    +', [CLIENT_UNDERSTAND_0_CLIENT_VISIT]'
    +', [CLIENT_UNDERSTAND_1_GRNDMTHR_VISIT]'
    +', [CLIENT_UNDERSTAND_1_PARTNER_VISIT]'
    +', [CLIENT_DOMAIN_0_PERSHLTH_VISIT]'
    +', [CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT]'
    +', [CLIENT_DOMAIN_0_LIFECOURSE_VISIT]'
    +', [CLIENT_DOMAIN_0_MATERNAL_VISIT]'
    +', [CLIENT_DOMAIN_0_FRNDFAM_VISIT]'
    +', [CLIENT_DOMAIN_0_TOTAL_VISIT]'
    +', [CLIENT_CONTENT_0_PERCENT_VISIT]'
    +', [CLIENT_ATTENDEES_0_OTHER_VISIT_DESC]'
    +', [CLIENT_TIME_1_DURATION_VISIT]'
    +', [CLIENT_0_ID_AGENCY]'
    +', [CLIENT_CHILD_INJURY_0_PREVENTION]'
    +', [CLIENT_IPV_0_SAFETY_PLAN]'
    +', [CLIENT_PRENATAL_VISITS_WEEKS]'
    +', [CLIENT_NO_REFERRAL]'
    +', [CLIENT_PRENATAL_VISITS]'
    +', [CLIENT_SCREENED_SRVCS]'
    +', [CLIENT_VISIT_SCHEDULE]'
    +' ,[CLIENT_PLANNED_VISIT_SCH]'
    +' ,[CLIENT_TIME_FROM_AMPM]'
    +' ,[CLIENT_TIME_FROM_HR]'
    +' ,[CLIENT_TIME_FROM_MIN]'
    +' ,[CLIENT_TIME_TO_AMPM]'
    +' ,[CLIENT_TIME_TO_HR]'
    +' ,[CLIENT_TIME_TO_MIN]'
-- October 2016 ETO Release:
    +' ,[INFANT_HEALTH_ER_1_TYPE]'
    +' ,[INFANT_HEALTH_HOSP_1_TYPE]'
    +' ,[INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2]'
    +' ,[CLIENT_CHILD_DEVELOPMENT_CONCERN]'
    +' ,[CLIENT_CONT_HLTH_INS]'
    +' ,[INFANT_HEALTH_ER_0_HAD_VISIT]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_ERvsUC1]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_ERvsUC2]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_ERvsUC3]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_TREAT1]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_TREAT2]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_TREAT3]'
    +' ,[INFANT_HEALTH_ER_1_INJ_ERvsUC1]'
    +' ,[INFANT_HEALTH_ER_1_INJ_ERvsUC2]'
    +' ,[INFANT_HEALTH_ER_1_INJ_ERvsUC3]'
    +' ,[INFANT_HEALTH_ER_1_INJ_TREAT1]'
    +' ,[INFANT_HEALTH_ER_1_INJ_TREAT2]'
    +' ,[INFANT_HEALTH_ER_1_INJ_TREAT3]'
    +' ,[INFANT_HEALTH_ER_1_OTHER]'
    +' ,[INFANT_HEALTH_ER_1_OTHER_ERvsUC1]'
    +' ,[INFANT_HEALTH_ER_1_OTHER_ERvsUC2]'
    +' ,[INFANT_HEALTH_ER_1_OTHER_ERvsUC3]'
    +' ,[INFANT_HEALTH_HOSP_0_HAD_VISIT]'
    +' ,[INFANT_HEALTH_PROVIDER_0_APPT_R2]'
    +' ,[INFANT_HEALTH_ER_1_OTHER_REASON1]'
    +' ,[INFANT_HEALTH_ER_1_OTHER_REASON2]'
    +' ,[INFANT_HEALTH_ER_1_OTHER_REASON3]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_DAYS1]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_DAYS2]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_DAYS3]'
    +' ,[INFANT_HEALTH_ER_1_INJ_DAYS1]'
    +' ,[INFANT_HEALTH_ER_1_INJ_DAYS2]'
    +' ,[INFANT_HEALTH_ER_1_INJ_DAYS3]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_DATE1]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_DATE2]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_DATE3]'
    +' ,[INFANT_HEALTH_ER_1_INJ_DATE1]'
    +' ,[INFANT_HEALTH_ER_1_INJ_DATE2]'
    +' ,[INFANT_HEALTH_ER_1_INJ_DATE3]'
    +' ,[INFANT_HEALTH_ER_1_OTHERDT1]'
    +' ,[INFANT_HEALTH_ER_1_OTHERDT2]'
    +' ,[INFANT_HEALTH_ER_1_OTHERDT3]'
    +' ,[INFANT_HEALTH_HOSP_1_INGEST_DATE1]'
    +' ,[INFANT_HEALTH_HOSP_1_INGEST_DATE2]'
    +' ,[INFANT_HEALTH_HOSP_1_INGEST_DATE3]'
    +' ,[INFANT_HEALTH_HOSP_1_INJ_DATE1]'
    +' ,[INFANT_HEALTH_HOSP_1_INJ_DATE2]'
    +' ,[INFANT_HEALTH_HOSP_1_INJ_DATE3]'
-- Integration set columns:
    +' ,[Master_SurveyID]'
    +' ,[DW_AuditDate])'
set @SQL2 = '
     SELECT  DW_SurveyResponseID as SurveyResponseID, ''' +@p_datasource +''''
    +' ,1'
    +', Atbl.[SurveyID]'
    +', Atbl.[SurveyDate]'
    +', Atbl.[AuditDate]'
    +' ,cxref1.Client_ID'
    +', Atbl.[SiteID]'
    +', Atbl.[ProgramID]'
    --+', Atbl.[IA_StaffID]'
    +' ,cxref2.Client_ID'
    +', Atbl.[RespondentID]'
    +', Atbl.[CLIENT_0_ID_NSO]'
    +', Atbl.[CLIENT_PERSONAL_0_NAME_FIRST]'
    +', Atbl.[CLIENT_PERSONAL_0_NAME_LAST]'
    +', Atbl.[CLIENT_PERSONAL_0_DOB_INTAKE]'
    +', Atbl.[CLIENT_TIME_0_START_VISIT]'
    +', Atbl.[CLIENT_TIME_1_END_VISIT]'
    +', Atbl.[NURSE_MILEAGE_0_VIS]'
    +' ,exref1.Entity_ID'
    +', Atbl.[CLIENT_COMPLETE_0_VISIT]'
    +', Atbl.[CLIENT_LOCATION_0_VISIT]'
    +', Atbl.[CLIENT_ATTENDEES_0_AT_VISIT]'
    +', Atbl.[CLIENT_INVOLVE_0_CLIENT_VISIT]'
    +', Atbl.[CLIENT_INVOLVE_1_GRNDMTHR_VISIT]'
    +', Atbl.[CLIENT_INVOLVE_1_PARTNER_VISIT]'
    +', Atbl.[CLIENT_CONFLICT_0_CLIENT_VISIT]'
    +', Atbl.[CLIENT_CONFLICT_1_GRNDMTHR_VISIT]'
    +', Atbl.[CLIENT_CONFLICT_1_PARTNER_VISIT]'
    +', Atbl.[CLIENT_UNDERSTAND_0_CLIENT_VISIT]'
    +', Atbl.[CLIENT_UNDERSTAND_1_GRNDMTHR_VISIT]'
    +', Atbl.[CLIENT_UNDERSTAND_1_PARTNER_VISIT]'
    +', Atbl.[CLIENT_DOMAIN_0_PERSHLTH_VISIT]'
    +', Atbl.[CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT]'
    +', Atbl.[CLIENT_DOMAIN_0_LIFECOURSE_VISIT]'
    +', Atbl.[CLIENT_DOMAIN_0_MATERNAL_VISIT]'
    +', Atbl.[CLIENT_DOMAIN_0_FRNDFAM_VISIT]'
    +', Atbl.[CLIENT_DOMAIN_0_TOTAL_VISIT]'
    +', Atbl.[CLIENT_CONTENT_0_PERCENT_VISIT]'
    +', Atbl.[CLIENT_ATTENDEES_0_OTHER_VISIT_DESC]'
    +', Atbl.[CLIENT_TIME_1_DURATION_VISIT]'
    +', Atbl.[CLIENT_0_ID_AGENCY]'
    +', Atbl.[CLIENT_CHILD_INJURY_0_PREVENTION]'
    +', Atbl.[CLIENT_IPV_0_SAFETY_PLAN]'
    +', Atbl.[CLIENT_PRENATAL_VISITS_WEEKS]'
    +', Atbl.[CLIENT_NO_REFERRAL]'
    +', Atbl.[CLIENT_PRENATAL_VISITS]'
    +', Atbl.[CLIENT_SCREENED_SRVCS]'
    +', Atbl.[CLIENT_VISIT_SCHEDULE]'
    +' ,Atbl.[CLIENT_PLANNED_VISIT_SCH]'
    +' ,Atbl.[CLIENT_TIME_FROM_AMPM]'
    +' ,Atbl.[CLIENT_TIME_FROM_HR]'
    +' ,Atbl.[CLIENT_TIME_FROM_MIN]'
    +' ,Atbl.[CLIENT_TIME_TO_AMPM]'
    +' ,Atbl.[CLIENT_TIME_TO_HR]'
    +' ,Atbl.[CLIENT_TIME_TO_MIN]'
-- October 2016 ETO Release:
    +' ,Atbl.[INFANT_HEALTH_ER_1_TYPE]'
    +' ,Atbl.[INFANT_HEALTH_HOSP_1_TYPE]'
    +' ,Atbl.[INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2]'
    +' ,Atbl.[CLIENT_CHILD_DEVELOPMENT_CONCERN]'
    +' ,Atbl.[CLIENT_CONT_HLTH_INS]'
    +' ,Atbl.[INFANT_HEALTH_ER_0_HAD_VISIT]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INGEST_ERvsUC1]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INGEST_ERvsUC2]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INGEST_ERvsUC3]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INGEST_TREAT1]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INGEST_TREAT2]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INGEST_TREAT3]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INJ_ERvsUC1]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INJ_ERvsUC2]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INJ_ERvsUC3]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INJ_TREAT1]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INJ_TREAT2]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INJ_TREAT3]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_OTHER]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_OTHER_ERvsUC1]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_OTHER_ERvsUC2]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_OTHER_ERvsUC3]'
    +' ,Atbl.[INFANT_HEALTH_HOSP_0_HAD_VISIT]'
    +' ,Atbl.[INFANT_HEALTH_PROVIDER_0_APPT_R2]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_OTHER_REASON1]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_OTHER_REASON2]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_OTHER_REASON3]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INGEST_DAYS1]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INGEST_DAYS2]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INGEST_DAYS3]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INJ_DAYS1]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INJ_DAYS2]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INJ_DAYS3]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INGEST_DATE1]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INGEST_DATE2]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INGEST_DATE3]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INJ_DATE1]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INJ_DATE2]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_INJ_DATE3]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_OTHERDT1]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_OTHERDT2]'
    +' ,Atbl.[INFANT_HEALTH_ER_1_OTHERDT3]'
    +' ,Atbl.[INFANT_HEALTH_HOSP_1_INGEST_DATE1]'
    +' ,Atbl.[INFANT_HEALTH_HOSP_1_INGEST_DATE2]'
    +' ,Atbl.[INFANT_HEALTH_HOSP_1_INGEST_DATE3]'
    +' ,Atbl.[INFANT_HEALTH_HOSP_1_INJ_DATE1]'
    +' ,Atbl.[INFANT_HEALTH_HOSP_1_INJ_DATE2]'
    +' ,Atbl.[INFANT_HEALTH_HOSP_1_INJ_DATE3]'
-- Integration set columns:
    +', ms.SourceSurveyID'
    +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
set @SQL3 = '    
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.HOME_VISIT_ENCOUNTER_Survey Atbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' left join dbo.Non_ETO_Client_Xref cxref1 on cxref1.Source =  ''' +@p_datasource +''''
    +'   and cxref1.Non_ETO_ID = Atbl.CL_EN_GEN_ID' 
    +'   and cxref1.Non_ETO_Site_ID = Atbl.SiteID'
    +' left join dbo.Non_ETO_Client_Xref cxref2 on cxref2.Source =  ''' +@p_datasource +''''
    +'   and cxref2.Non_ETO_ID = Atbl.ClientID' 
    +'   and cxref2.Non_ETO_Site_ID = Atbl.SiteID'
    +' left join dbo.Non_ETO_Entity_Xref exref1 on exref1.Source =  ''' +@p_datasource +''''
    +'   and exref1.Non_ETO_ID = Atbl.NURSEID' 
    +'   and exref1.Non_ETO_Site_ID = Atbl.SiteID'
    +' left join dbo.Mstr_Surveys ms on Atbl.SurveyID = ms.SurveyID'
    +' where Atbl.DW_SurveyResponseID is not null'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'
    +' and not exists (select dwsurvey.SurveyResponseID'
    +' from dbo.HOME_VISIT_ENCOUNTER_Survey dwsurvey'
    +' where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and dwsurvey.SurveyResponseID = Atbl.DW_SurveyResponseID)'
     

    print @SQL1
    print @SQL2
    print @SQL3
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
           +', SQL3 Length = ' +CAST(LEN(@SQL3) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL1+@SQL2+@SQL3)

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
    +'  update dbo.HOME_VISIT_ENCOUNTER_Survey'
    +' Set [ElementsProcessed] = 1'
    +', [SurveyID] = Atbl.[SurveyID]'
    +', [SurveyDate] = Atbl.[SurveyDate]'
    +', [AuditDate] = Atbl.[AuditDate]'
    +', [CL_EN_GEN_ID] = cxref1.Client_ID'
    +', [SiteID] = Atbl.[SiteID]'
    +', [ProgramID] = Atbl.[ProgramID]'
    --+', [IA_StaffID] = Atbl.[IA_StaffID]'
    +', [ClientID] = cxref2.Client_ID'
    +', [RespondentID] = Atbl.[RespondentID]'
    +', [CLIENT_0_ID_NSO] = Atbl.[CLIENT_0_ID_NSO]'
    +', [CLIENT_PERSONAL_0_NAME_FIRST] = Atbl.[CLIENT_PERSONAL_0_NAME_FIRST]'
    +', [CLIENT_PERSONAL_0_NAME_LAST] = Atbl.[CLIENT_PERSONAL_0_NAME_LAST]'
    +', [CLIENT_PERSONAL_0_DOB_INTAKE] = Atbl.[CLIENT_PERSONAL_0_DOB_INTAKE]'
    +', [CLIENT_TIME_0_START_VISIT] = Atbl.[CLIENT_TIME_0_START_VISIT]'
    +', [CLIENT_TIME_1_END_VISIT] = Atbl.[CLIENT_TIME_1_END_VISIT]'
    +', [NURSE_MILEAGE_0_VIS] = Atbl.[NURSE_MILEAGE_0_VIS]'
    +', [NURSE_PERSONAL_0_NAME] = exref1.Entity_ID'
    +', [CLIENT_COMPLETE_0_VISIT] = Atbl.[CLIENT_COMPLETE_0_VISIT]'
    +', [CLIENT_LOCATION_0_VISIT] = Atbl.[CLIENT_LOCATION_0_VISIT]'
    +', [CLIENT_ATTENDEES_0_AT_VISIT] = Atbl.[CLIENT_ATTENDEES_0_AT_VISIT]'
    +', [CLIENT_INVOLVE_0_CLIENT_VISIT] = Atbl.[CLIENT_INVOLVE_0_CLIENT_VISIT]'
    +', [CLIENT_INVOLVE_1_GRNDMTHR_VISIT] = Atbl.[CLIENT_INVOLVE_1_GRNDMTHR_VISIT]'
    +', [CLIENT_INVOLVE_1_PARTNER_VISIT] = Atbl.[CLIENT_INVOLVE_1_PARTNER_VISIT]'
    +', [CLIENT_CONFLICT_0_CLIENT_VISIT] = Atbl.[CLIENT_CONFLICT_0_CLIENT_VISIT]'
    +', [CLIENT_CONFLICT_1_GRNDMTHR_VISIT] = Atbl.[CLIENT_CONFLICT_1_GRNDMTHR_VISIT]'
    +', [CLIENT_CONFLICT_1_PARTNER_VISIT] = Atbl.[CLIENT_CONFLICT_1_PARTNER_VISIT]'
    +', [CLIENT_UNDERSTAND_0_CLIENT_VISIT] = Atbl.[CLIENT_UNDERSTAND_0_CLIENT_VISIT]'
    +', [CLIENT_UNDERSTAND_1_GRNDMTHR_VISIT] = Atbl.[CLIENT_UNDERSTAND_1_GRNDMTHR_VISIT]'
    +', [CLIENT_UNDERSTAND_1_PARTNER_VISIT] = Atbl.[CLIENT_UNDERSTAND_1_PARTNER_VISIT]'
    +', [CLIENT_DOMAIN_0_PERSHLTH_VISIT] = Atbl.[CLIENT_DOMAIN_0_PERSHLTH_VISIT]'
    +', [CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT] = Atbl.[CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT]'
    +', [CLIENT_DOMAIN_0_LIFECOURSE_VISIT] = Atbl.[CLIENT_DOMAIN_0_LIFECOURSE_VISIT]'
    +', [CLIENT_DOMAIN_0_MATERNAL_VISIT] = Atbl.[CLIENT_DOMAIN_0_MATERNAL_VISIT]'
    +', [CLIENT_DOMAIN_0_FRNDFAM_VISIT] = Atbl.[CLIENT_DOMAIN_0_FRNDFAM_VISIT]'
    +', [CLIENT_DOMAIN_0_TOTAL_VISIT] = Atbl.[CLIENT_DOMAIN_0_TOTAL_VISIT]'
    +', [CLIENT_CONTENT_0_PERCENT_VISIT] = Atbl.[CLIENT_CONTENT_0_PERCENT_VISIT]'
    +', [CLIENT_ATTENDEES_0_OTHER_VISIT_DESC] = Atbl.[CLIENT_ATTENDEES_0_OTHER_VISIT_DESC]'
    +', [CLIENT_TIME_1_DURATION_VISIT] = Atbl.[CLIENT_TIME_1_DURATION_VISIT]'
    +', [CLIENT_0_ID_AGENCY] = Atbl.[CLIENT_0_ID_AGENCY]'
    +', [CLIENT_CHILD_INJURY_0_PREVENTION] = Atbl.[CLIENT_CHILD_INJURY_0_PREVENTION]'
    +', [CLIENT_IPV_0_SAFETY_PLAN] = Atbl.[CLIENT_IPV_0_SAFETY_PLAN]'
    +', [CLIENT_PRENATAL_VISITS_WEEKS] = Atbl.[CLIENT_PRENATAL_VISITS_WEEKS]'
    +', [CLIENT_NO_REFERRAL] = Atbl.[CLIENT_NO_REFERRAL]'
    +', [CLIENT_PRENATAL_VISITS] = Atbl.[CLIENT_PRENATAL_VISITS]'
    +', [CLIENT_SCREENED_SRVCS] = Atbl.[CLIENT_SCREENED_SRVCS]'
    +', [CLIENT_VISIT_SCHEDULE] = Atbl.[CLIENT_VISIT_SCHEDULE]'
    +' ,[CLIENT_PLANNED_VISIT_SCH] = Atbl.[CLIENT_PLANNED_VISIT_SCH]'
    +' ,[CLIENT_TIME_FROM_AMPM] = Atbl.[CLIENT_TIME_FROM_AMPM]'
    +' ,[CLIENT_TIME_FROM_HR] = Atbl.[CLIENT_TIME_FROM_HR]'
    +' ,[CLIENT_TIME_FROM_MIN] = Atbl.[CLIENT_TIME_FROM_MIN]'
    +' ,[CLIENT_TIME_TO_AMPM] = Atbl.[CLIENT_TIME_TO_AMPM]'
    +' ,[CLIENT_TIME_TO_HR] = Atbl.[CLIENT_TIME_TO_HR]'
    +'  ,[CLIENT_TIME_TO_MIN] = Atbl.[CLIENT_TIME_TO_MIN]'
-- October 2016 ETO Release:
set @SQL2 = '
     ,[INFANT_HEALTH_ER_1_TYPE] = Atbl.[INFANT_HEALTH_ER_1_TYPE]'
    +' ,[INFANT_HEALTH_HOSP_1_TYPE] = Atbl.[INFANT_HEALTH_HOSP_1_TYPE]'
    +' ,[INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2] = Atbl.[INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2]'
    +' ,[CLIENT_CHILD_DEVELOPMENT_CONCERN] = Atbl.[CLIENT_CHILD_DEVELOPMENT_CONCERN]'
    +' ,[CLIENT_CONT_HLTH_INS] = Atbl.[CLIENT_CONT_HLTH_INS]'
    +' ,[INFANT_HEALTH_ER_0_HAD_VISIT] = Atbl.[INFANT_HEALTH_ER_0_HAD_VISIT]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_ERvsUC1] = Atbl.[INFANT_HEALTH_ER_1_INGEST_ERvsUC1]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_ERvsUC2] = Atbl.[INFANT_HEALTH_ER_1_INGEST_ERvsUC2]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_ERvsUC3] = Atbl.[INFANT_HEALTH_ER_1_INGEST_ERvsUC3]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_TREAT1] = Atbl.[INFANT_HEALTH_ER_1_INGEST_TREAT1]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_TREAT2] = Atbl.[INFANT_HEALTH_ER_1_INGEST_TREAT2]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_TREAT3] = Atbl.[INFANT_HEALTH_ER_1_INGEST_TREAT3]'
    +' ,[INFANT_HEALTH_ER_1_INJ_ERvsUC1] = Atbl.[INFANT_HEALTH_ER_1_INJ_ERvsUC1]'
    +' ,[INFANT_HEALTH_ER_1_INJ_ERvsUC2] = Atbl.[INFANT_HEALTH_ER_1_INJ_ERvsUC2]'
    +' ,[INFANT_HEALTH_ER_1_INJ_ERvsUC3] = Atbl.[INFANT_HEALTH_ER_1_INJ_ERvsUC3]'
    +' ,[INFANT_HEALTH_ER_1_INJ_TREAT1] = Atbl.[INFANT_HEALTH_ER_1_INJ_TREAT1]'
    +' ,[INFANT_HEALTH_ER_1_INJ_TREAT2] = Atbl.[INFANT_HEALTH_ER_1_INJ_TREAT2]'
    +' ,[INFANT_HEALTH_ER_1_INJ_TREAT3] = Atbl.[INFANT_HEALTH_ER_1_INJ_TREAT3]'
    +' ,[INFANT_HEALTH_ER_1_OTHER] = Atbl.[INFANT_HEALTH_ER_1_OTHER]'
    +' ,[INFANT_HEALTH_ER_1_OTHER_ERvsUC1] = Atbl.[INFANT_HEALTH_ER_1_OTHER_ERvsUC1]'
    +' ,[INFANT_HEALTH_ER_1_OTHER_ERvsUC2] = Atbl.[INFANT_HEALTH_ER_1_OTHER_ERvsUC2]'
    +' ,[INFANT_HEALTH_ER_1_OTHER_ERvsUC3] = Atbl.[INFANT_HEALTH_ER_1_OTHER_ERvsUC3]'
    +' ,[INFANT_HEALTH_HOSP_0_HAD_VISIT] = Atbl.[INFANT_HEALTH_HOSP_0_HAD_VISIT]'
    +' ,[INFANT_HEALTH_PROVIDER_0_APPT_R2] = Atbl.[INFANT_HEALTH_PROVIDER_0_APPT_R2]'
    +' ,[INFANT_HEALTH_ER_1_OTHER_REASON1] = Atbl.[INFANT_HEALTH_ER_1_OTHER_REASON1]'
    +' ,[INFANT_HEALTH_ER_1_OTHER_REASON2] = Atbl.[INFANT_HEALTH_ER_1_OTHER_REASON2]'
    +' ,[INFANT_HEALTH_ER_1_OTHER_REASON3] = Atbl.[INFANT_HEALTH_ER_1_OTHER_REASON3]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_DAYS1] = Atbl.[INFANT_HEALTH_ER_1_INGEST_DAYS1]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_DAYS2] = Atbl.[INFANT_HEALTH_ER_1_INGEST_DAYS2]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_DAYS3] = Atbl.[INFANT_HEALTH_ER_1_INGEST_DAYS3]'
    +' ,[INFANT_HEALTH_ER_1_INJ_DAYS1] = Atbl.[INFANT_HEALTH_ER_1_INJ_DAYS1]'
    +' ,[INFANT_HEALTH_ER_1_INJ_DAYS2] = Atbl.[INFANT_HEALTH_ER_1_INJ_DAYS2]'
    +' ,[INFANT_HEALTH_ER_1_INJ_DAYS3] = Atbl.[INFANT_HEALTH_ER_1_INJ_DAYS3]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_DATE1] = Atbl.[INFANT_HEALTH_ER_1_INGEST_DATE1]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_DATE2] = Atbl.[INFANT_HEALTH_ER_1_INGEST_DATE2]'
    +' ,[INFANT_HEALTH_ER_1_INGEST_DATE3] = Atbl.[INFANT_HEALTH_ER_1_INGEST_DATE3]'
    +' ,[INFANT_HEALTH_ER_1_INJ_DATE1] = Atbl.[INFANT_HEALTH_ER_1_INJ_DATE1]'
    +' ,[INFANT_HEALTH_ER_1_INJ_DATE2] = Atbl.[INFANT_HEALTH_ER_1_INJ_DATE2]'
    +' ,[INFANT_HEALTH_ER_1_INJ_DATE3] = Atbl.[INFANT_HEALTH_ER_1_INJ_DATE3]'
    +' ,[INFANT_HEALTH_ER_1_OTHERDT1] = Atbl.[INFANT_HEALTH_ER_1_OTHERDT1]'
    +' ,[INFANT_HEALTH_ER_1_OTHERDT2] = Atbl.[INFANT_HEALTH_ER_1_OTHERDT2]'
    +' ,[INFANT_HEALTH_ER_1_OTHERDT3] = Atbl.[INFANT_HEALTH_ER_1_OTHERDT3]'
    +' ,[INFANT_HEALTH_HOSP_1_INGEST_DATE1] = Atbl.[INFANT_HEALTH_HOSP_1_INGEST_DATE1]'
    +' ,[INFANT_HEALTH_HOSP_1_INGEST_DATE2] = Atbl.[INFANT_HEALTH_HOSP_1_INGEST_DATE2]'
    +' ,[INFANT_HEALTH_HOSP_1_INGEST_DATE3] = Atbl.[INFANT_HEALTH_HOSP_1_INGEST_DATE3]'
    +' ,[INFANT_HEALTH_HOSP_1_INJ_DATE1] = Atbl.[INFANT_HEALTH_HOSP_1_INJ_DATE1]'
    +' ,[INFANT_HEALTH_HOSP_1_INJ_DATE2] = Atbl.[INFANT_HEALTH_HOSP_1_INJ_DATE2]'
    +' ,[INFANT_HEALTH_HOSP_1_INJ_DATE3] = Atbl.[INFANT_HEALTH_HOSP_1_INJ_DATE3]'
-- Integration set columns:
    +', [Master_SurveyID] = ms.SourceSurveyID'
    +', [DW_AuditDate] = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
set @SQL3 = '
     from dbo.HOME_VISIT_ENCOUNTER_Survey dwsurvey'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.HOME_VISIT_ENCOUNTER_Survey Atbl'
    +' on dwsurvey.SurveyResponseID = Atbl.DW_SurveyResponseID'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' left join dbo.Non_ETO_Client_Xref cxref1 on cxref1.Source =  ''' +@p_datasource +''''
    +'   and cxref1.Non_ETO_ID = Atbl.CL_EN_GEN_ID' 
    +'   and cxref1.Non_ETO_Site_ID = Atbl.SiteID'
    +' left join dbo.Non_ETO_Client_Xref cxref2 on cxref2.Source =  ''' +@p_datasource +''''
    +'   and cxref2.Non_ETO_ID = Atbl.ClientID' 
    +'   and cxref2.Non_ETO_Site_ID = Atbl.SiteID'
    +' left join dbo.Non_ETO_Entity_Xref exref1 on exref1.Source =  ''' +@p_datasource +''''
    +'   and exref1.Non_ETO_ID = Atbl.NURSEID' 
    +'   and exref1.Non_ETO_Site_ID = Atbl.SiteID'
    +' left join dbo.Mstr_Surveys ms on Atbl.SurveyID = ms.SurveyID'
    +'
     where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'
    +' and isnull(dwsurvey.AuditDate,convert(datetime,''19700101'',112)) < '
    +' isnull(Atbl.AuditDate,convert(datetime,''19700101'',112))'


    print @SQL1
    print @SQL2
    print @SQL3
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
           +', SQL3 Length = ' +CAST(LEN(@SQL3) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL1+@SQL2+@SQL3)



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
    +' left join ' +@Agency_Full_TableName +' Atbl on dwsurvey.SurveyResponseID = atbl.DW_SurveyresponseID'
    +' where dwsurvey.DataSource = ''' +@p_datasource +''''
      +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', dwsurvey.SiteID) is null'
      +' and atbl.SurveyResponseID is null'

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
    +' left join ' +@Agency_Full_TableName +' Atbl on dwxref.Non_ETO_ID = atbl.SurveyresponseID'
    +' left join dbo.' +@DW_TableName +' dwsurvey on dwxref.SurveyResponseID = dwsurvey.SurveyresponseID'

    +' where dwxref.source = ''' +@p_datasource +''''
      +' and dwxref.DW_tableName = ''' +@DW_TableName +''''
      +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', dwxref.Non_ETO_Site_ID) is null'

      +' and atbl.SurveyResponseID is null'
      +' and dwsurvey.SurveyResponseID is null'


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

print 'End of Process: SP_AGENCYDB_HOME_VISIT_ENCOUNTER_SURVEY'
GO
