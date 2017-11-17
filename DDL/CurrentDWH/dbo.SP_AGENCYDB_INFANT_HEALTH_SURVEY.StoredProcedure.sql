USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_INFANT_HEALTH_SURVEY]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_INFANT_HEALTH_SURVEY
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_INFANT_HEALTH_SURVEY]
 (@p_datasource      nvarchar(10) = null
 ,@p_no_delete_opt   nvarchar(2)  = null
 ,@p_no_exec_flag    nvarchar(10) = 'N')
AS
--
-- This script controls integration of AgencyDB Surveys to the Data Warehouse 
-- INFANT_HEALTH_Survey table.
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
--  20140818 - Updated for new columns added to form/table.
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
--   20150625 - Added new columns to integraion.
--   20160706 - Added additional conditional logic to match siteid when looking up xrefs to entities and clients,
--              to accommodate multiple sites within the same AgencyDB, using same numbering scheme between sites.
--   20160929 - Re-mapped the original pseudonym 'NFANT_HEALTH_ER_1_INJ_TREAT3' which was misspelled in ETO 
--              to the corrected named pseudonym in the DW (prefixed with an I)
--              Setup new pseudonyms for the Oct 2016 ETO release (commented).  Retired columns will still be applied for history.
--   20161004 - AgencyDB column rename for [NFANT_HEALTH_ER_1_INJ_TREAT3] to INFANT_HEALTH_ER_1_INJ_TREAT3 (prefixed with an I).
--              Program updated accordingly.
--   20161019 - Setup new pseudonyms for the Oct 2016 ETO release.  Retired columns will still be applied for history.
--   20161114 - Moved the preliminary Non_ETO_SurveyResponse_xref processing to a common sub procedure for AgencyDB processing
--              named: dbo.SP_AGENCYDB_Survey_Non_ETO_Xref_Process.


DECLARE @count          smallint
DECLARE @stop_flag      nvarchar(2)
DECLARE @Process        nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)
DECLARE @Agency_TableName   nvarchar(50)
DECLARE @Agency_Full_TableName   nvarchar(100)

set @process          = 'SP_AGENCYDB_INFANT_HEALTH_SURVEY'
set @DW_Tablename     = 'INFANT_HEALTH_SURVEY'
set @Agency_Tablename = 'INFANT_HEALTH_SURVEY'
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)
DECLARE @SQL1            varchar(MAX)
DECLARE @SQL2            varchar(MAX)
DECLARE @SQL3            varchar(MAX)
DECLARE @SQL4            varchar(MAX)

print 'Processing SP_AGENCYDB_INFANT_HEALTH_SURVEY: Datasource = ' +isnull(@p_datasource,'NULL')
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
    +' insert into dbo.INFANT_HEALTH_Survey'
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
    +', [INFANT_0_ID_NSO]'
    +', [INFANT_PERSONAL_0_NAME_FIRST]'
    +', [INFANT_BIRTH_0_DOB]'
    +', [CLIENT_0_ID_NSO]'
    +', [CLIENT_PERSONAL_0_NAME_FIRST]'
    +', [CLIENT_PERSONAL_0_NAME_LAST]'
    +', [NURSE_PERSONAL_0_NAME]'
    +', [INFANT_HEALTH_PROVIDER_0_PRIMARY]'
    +', [INFANT_HEALTH_IMMUNIZ_0_UPDATE]'
    +', [INFANT_HEALTH_IMMUNIZ_1_RECORD]'
    +', [INFANT_HEALTH_LEAD_0_TEST]'
    +', [INFANT_HEALTH_HEIGHT_0_INCHES]'
    +', [INFANT_HEALTH_HEIGHT_1_PERCENT]'
    +', [INFANT_HEALTH_HEAD_0_CIRC_INCHES]'
    +', [INFANT_HEALTH_ER_0_HAD_VISIT]'
    +', [INFANT_HEALTH_ER_1_TYPE]'
    +', [INFANT_HEALTH_ER_1_INJ_DATE1]'
    +', [INFANT_HEALTH_ER_1_INJ_DATE2]'
    +', [INFANT_HEALTH_ER_1_INJ_DATE3]'
    +', [INFANT_HEALTH_ER_1_INGEST_DATE1]'
    +', [INFANT_HEALTH_ER_1_INGEST_DATE2]'
    +', [INFANT_HEALTH_ER_1_INGEST_DATE3]'
    +', [INFANT_HEALTH_HOSP_0_HAD_VISIT]'
    +', [INFANT_BREASTMILK_0_EVER_IHC]'
    +', [INFANT_BREASTMILK_1_CONT]'
    +', [INFANT_HEALTH_HOSP_1_INJ_DATE1]'
    +', [INFANT_HEALTH_HOSP_1_INJ_DATE2]'
    +', [INFANT_HEALTH_HOSP_1_INJ_DATE3]'
    +', [INFANT_HEALTH_HOSP_1_INGEST_DATE1]'
    +', [INFANT_HEALTH_HOSP_1_INGEST_DATE2]'
    +', [INFANT_HEALTH_HOSP_1_INGEST_DATE3]'
    +', [INFANT_HEALTH_HOSP_1_TYPE]'
    +', [INFANT_BREASTMILK_1_AGE_STOP]'
    +', [INFANT_BREASTMILK_1_WEEK_STOP]'
    +', [INFANT_BREASTMILK_1_EXCLUSIVE_WKS]'
    +', [INFANT_SOCIAL_SERVICES_0_REFERRAL]'
    +', [INFANT_SOCIAL_SERVICES_1_REFDATE1]'
    +', [INFANT_SOCIAL_SERVICES_1_REFDATE2]'
    +', [INFANT_SOCIAL_SERVICES_1_REFDATE3]'
    +', [INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL]'
    +', [INFANT_SOCIAL_SERVICES_1_NHV_REFDATE1]'
    +', [INFANT_SOCIAL_SERVICES_1_NHV_REFDATE2]'
    +', [INFANT_SOCIAL_SERVICES_1_NHV_REFDATE3]'
    +', [INFANT_HEALTH_WEIGHT_0_POUNDS]'
    +', [INFANT_HEALTH_WEIGHT_1_OUNCES]'
    +', [INFANT_HEALTH_WEIGHT_1_OZ]'
    +', [INFANT_HEALTH_WEIGHT_1_PERCENT]'
    +', [CLIENT_0_ID_AGENCY]'
    +', [INFANT_AGES_STAGES_1_COMM]'
    +', [INFANT_AGES_STAGES_0_VERSION]'
    +', [INFANT_AGES_STAGES_1_GMOTOR]'
    +', [INFANT_AGES_STAGES_1_FMOTOR]'
    +', [INFANT_AGES_STAGES_1_PSOLVE]'
    +', [INFANT_AGES_STAGES_1_PSOCIAL]'
    +', [INFANT_AGES_STAGES_SE_0_EMOTIONAL]'
    +', [INFANT_PERSONAL_0_NAME_LAST]'
    +', [INFANT_HEALTH_HEAD_1_REPORT]'
    +', [INFANT_HEALTH_HEIGHT_1_REPORT]'
    +', [INFANT_HEALTH_PROVIDER_0_APPT]'
    +', [INFANT_HEALTH_WEIGHT_1_REPORT]'
    +', [INFANT_HEALTH_ER_1_OTHERDT1]'
    +', [INFANT_HEALTH_ER_1_INGEST_TREAT1]'
    +', [INFANT_HEALTH_ER_1_INGEST_TREAT2]'
    +', [INFANT_HEALTH_ER_1_INGEST_TREAT3]'
    +', [INFANT_HEALTH_ER_1_INJ_TREAT1]'
    +', [INFANT_HEALTH_ER_1_INJ_TREAT2]'
    +', [INFANT_HEALTH_ER_1_OTHER]'
    +', [INFANT_HEALTH_ER_1_OTHER_REASON1]'
    +', [INFANT_HEALTH_ER_1_OTHER_REASON2]'
    +', [INFANT_HEALTH_ER_1_OTHER_REASON3]'
    +', [INFANT_HEALTH_ER_1_OTHERDT2]'
    +', [INFANT_HEALTH_ER_1_OTHERDT3]'
    +', [INFANT_HOME_0_TOTAL]'
    +', [INFANT_HOME_1_ACCEPTANCE]'
    +', [INFANT_HOME_1_EXPERIENCE]'
    +', [INFANT_HOME_1_INVOLVEMENT]'
    +', [INFANT_HOME_1_LEARNING]'
    +', [INFANT_HOME_1_ORGANIZATION]'
    +', [INFANT_HOME_1_RESPONSIVITY]'
    +', [INFANT_SOCIAL_SERVICES_1_NHV_REASON1]'
    +', [INFANT_SOCIAL_SERVICES_1_NHV_REASON2]'
    +', [INFANT_SOCIAL_SERVICES_1_NHV_REASON3]'
    +', [INFANT_SOCIAL_SERVICES_1_REASON1]'
    +', [INFANT_SOCIAL_SERVICES_1_REASON2]'
    +', [INFANT_SOCIAL_SERVICES_1_REASON3]'
    +', [INFANT_HEALTH_ER_1_INJ_TREAT3]'
    +', [INFANT_HEALTH_ER_1_INJ_ERvsUC1]'
    +', [INFANT_HEALTH_PROVIDER_0_APPT_R2]'
    +', [INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2]'
    +', [INFANT_HEALTH_ER_1_INGEST_ERvsUC1]'
    +', [INFANT_HEALTH_ER_1_INGEST_ERvsUC2]'
    +', [INFANT_HEALTH_ER_1_INGEST_ERvsUC3]'
    +', [INFANT_HEALTH_ER_1_INJ_ERvsUC2]'
    +', [INFANT_HEALTH_ER_1_OTHER_ERvsUC1]'
    +', [INFANT_HEALTH_ER_1_OTHER_ERvsUC2]'
    +', [INFANT_HEALTH_NO_ASQ_COMM]'
    +', [INFANT_HEALTH_NO_ASQ_FINE]'
    +', [INFANT_HEALTH_NO_ASQ_GROSS]'
    +', [INFANT_HEALTH_NO_ASQ_PERSONAL]'
    +', [INFANT_HEALTH_NO_ASQ_PROBLEM]'
    +', [INFANT_HEALTH_NO_ASQ_TOTAL]'
    +', [INFANT_HEALTH_ER_1_INJ_ERvsUC3]'
    +', [INFANT_HEALTH_ER_1_OTHER_ERvsUC3]'
    +', [INFANT_PERSONAL_0_SSN]'
    +' ,INFANT_HEALTH_IMMUNIZ_UPDATE_YES'
    +' ,INFANT_HEALTH_IMMUNIZ_UPDATE_NO'
    +' ,INFANT_HEALTH_DENTIST'
    +' ,INFANT_HEALTH_DENTIST_STILL_EBF'
    +' ,INFANT_SOCIAL_SERVICES_1_REASON1_OTHER'
    +' ,INFANT_SOCIAL_SERVICES_1_REASON2_OTHER'
    +' ,INFANT_SOCIAL_SERVICES_1_REASON3_OTHER'
-- October 2016 Release:
    +' ,[INFANT_INSURANCE_TYPE]'
    +' ,[INFANT_AGES_STAGES_SE_VERSION]'
    +' ,[INFANT_BIRTH_COSLEEP]'
    +' ,[INFANT_BIRTH_READ]'
    +' ,[INFANT_BIRTH_SLEEP_BACK]'
    +' ,[INFANT_BIRTH_SLEEP_BEDDING]'
    +' ,[INFANT_HEALTH_DENTAL_SOURCE]'
    +' ,[INFANT_INSURANCE]'
    +' ,[INFANT_INSURANCE_OTHER]'
--  Integration set collumns:
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
    +', Atbl.[INFANT_0_ID_NSO]'
    +', Atbl.[INFANT_PERSONAL_0_NAME_FIRST]'
    +', Atbl.[INFANT_BIRTH_0_DOB]'
    +', Atbl.[CLIENT_0_ID_NSO]'
    +', Atbl.[CLIENT_PERSONAL_0_NAME_FIRST]'
    +', Atbl.[CLIENT_PERSONAL_0_NAME_LAST]'
    +' ,exref1.Entity_ID'
    +', Atbl.[INFANT_HEALTH_PROVIDER_0_PRIMARY]'
    +', Atbl.[INFANT_HEALTH_IMMUNIZ_0_UPDATE]'
    +', Atbl.[INFANT_HEALTH_IMMUNIZ_1_RECORD]'
    +', Atbl.[INFANT_HEALTH_LEAD_0_TEST]'
    +', Atbl.[INFANT_HEALTH_HEIGHT_0_INCHES]'
    +', Atbl.[INFANT_HEALTH_HEIGHT_1_PERCENT]'
    +', Atbl.[INFANT_HEALTH_HEAD_0_CIRC_INCHES]'
    +', Atbl.[INFANT_HEALTH_ER_0_HAD_VISIT]'
    +', Atbl.[INFANT_HEALTH_ER_1_TYPE]'
    +', Atbl.[INFANT_HEALTH_ER_1_INJ_DATE1]'
    +', Atbl.[INFANT_HEALTH_ER_1_INJ_DATE2]'
    +', Atbl.[INFANT_HEALTH_ER_1_INJ_DATE3]'
    +', Atbl.[INFANT_HEALTH_ER_1_INGEST_DATE1]'
    +', Atbl.[INFANT_HEALTH_ER_1_INGEST_DATE2]'
    +', Atbl.[INFANT_HEALTH_ER_1_INGEST_DATE3]'
    +', Atbl.[INFANT_HEALTH_HOSP_0_HAD_VISIT]'
    +', Atbl.[INFANT_BREASTMILK_0_EVER_IHC]'
    +', Atbl.[INFANT_BREASTMILK_1_CONT]'
    +', Atbl.[INFANT_HEALTH_HOSP_1_INJ_DATE1]'
    +', Atbl.[INFANT_HEALTH_HOSP_1_INJ_DATE2]'
    +', Atbl.[INFANT_HEALTH_HOSP_1_INJ_DATE3]'
    +', Atbl.[INFANT_HEALTH_HOSP_1_INGEST_DATE1]'
    +', Atbl.[INFANT_HEALTH_HOSP_1_INGEST_DATE2]'
    +', Atbl.[INFANT_HEALTH_HOSP_1_INGEST_DATE3]'
    +', Atbl.[INFANT_HEALTH_HOSP_1_TYPE]'
    +', Atbl.[INFANT_BREASTMILK_1_AGE_STOP]'
    +', Atbl.[INFANT_BREASTMILK_1_WEEK_STOP]'
    +', Atbl.[INFANT_BREASTMILK_1_EXCLUSIVE_WKS]'
    +', Atbl.[INFANT_SOCIAL_SERVICES_0_REFERRAL]'
    +', Atbl.[INFANT_SOCIAL_SERVICES_1_REFDATE1]'
    +', Atbl.[INFANT_SOCIAL_SERVICES_1_REFDATE2]'
    +', Atbl.[INFANT_SOCIAL_SERVICES_1_REFDATE3]'
    +', Atbl.[INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL]'
    +', Atbl.[INFANT_SOCIAL_SERVICES_1_NHV_REFDATE1]'
    +', Atbl.[INFANT_SOCIAL_SERVICES_1_NHV_REFDATE2]'
    +', Atbl.[INFANT_SOCIAL_SERVICES_1_NHV_REFDATE3]'
    +', Atbl.[INFANT_HEALTH_WEIGHT_0_POUNDS]'
    +', Atbl.[INFANT_HEALTH_WEIGHT_1_OUNCES]'
    +', Atbl.[INFANT_HEALTH_WEIGHT_1_OZ]'
    +', Atbl.[INFANT_HEALTH_WEIGHT_1_PERCENT]'
    +', Atbl.[CLIENT_0_ID_AGENCY]'
    +', Atbl.[INFANT_AGES_STAGES_1_COMM]'
    +', Atbl.[INFANT_AGES_STAGES_0_VERSION]'
    +', Atbl.[INFANT_AGES_STAGES_1_GMOTOR]'
    +', Atbl.[INFANT_AGES_STAGES_1_FMOTOR]'
    +', Atbl.[INFANT_AGES_STAGES_1_PSOLVE]'
    +', Atbl.[INFANT_AGES_STAGES_1_PSOCIAL]'
    +', Atbl.[INFANT_AGES_STAGES_SE_0_EMOTIONAL]'
    +', Atbl.[INFANT_PERSONAL_0_NAME_LAST]'
    +', Atbl.[INFANT_HEALTH_HEAD_1_REPORT]'
    +', Atbl.[INFANT_HEALTH_HEIGHT_1_REPORT]'
    +', Atbl.[INFANT_HEALTH_PROVIDER_0_APPT]'
    +', Atbl.[INFANT_HEALTH_WEIGHT_1_REPORT]'
    +', Atbl.[INFANT_HEALTH_ER_1_OTHERDT1]'
    +', Atbl.[INFANT_HEALTH_ER_1_INGEST_TREAT1]'
    +', Atbl.[INFANT_HEALTH_ER_1_INGEST_TREAT2]'
    +', Atbl.[INFANT_HEALTH_ER_1_INGEST_TREAT3]'
    +', Atbl.[INFANT_HEALTH_ER_1_INJ_TREAT1]'
    +', Atbl.[INFANT_HEALTH_ER_1_INJ_TREAT2]'
    +', Atbl.[INFANT_HEALTH_ER_1_OTHER]'
    +', Atbl.[INFANT_HEALTH_ER_1_OTHER_REASON1]'
    +', Atbl.[INFANT_HEALTH_ER_1_OTHER_REASON2]'
    +', Atbl.[INFANT_HEALTH_ER_1_OTHER_REASON3]'
    +', Atbl.[INFANT_HEALTH_ER_1_OTHERDT2]'
    +', Atbl.[INFANT_HEALTH_ER_1_OTHERDT3]'
    +', Atbl.[INFANT_HOME_0_TOTAL]'
    +', Atbl.[INFANT_HOME_1_ACCEPTANCE]'
    +', Atbl.[INFANT_HOME_1_EXPERIENCE]'
    +', Atbl.[INFANT_HOME_1_INVOLVEMENT]'
    +', Atbl.[INFANT_HOME_1_LEARNING]'
    +', Atbl.[INFANT_HOME_1_ORGANIZATION]'
    +', Atbl.[INFANT_HOME_1_RESPONSIVITY]'
set @SQL3 = ', Atbl.[INFANT_SOCIAL_SERVICES_1_NHV_REASON1]'
    +', Atbl.[INFANT_SOCIAL_SERVICES_1_NHV_REASON2]'
    +', Atbl.[INFANT_SOCIAL_SERVICES_1_NHV_REASON3]'
    +', Atbl.[INFANT_SOCIAL_SERVICES_1_REASON1]'
    +', Atbl.[INFANT_SOCIAL_SERVICES_1_REASON2]'
    +', Atbl.[INFANT_SOCIAL_SERVICES_1_REASON3]'
    +', Atbl.[INFANT_HEALTH_ER_1_INJ_TREAT3]'
    +', Atbl.[INFANT_HEALTH_ER_1_INJ_ERvsUC1]'
    +', Atbl.[INFANT_HEALTH_PROVIDER_0_APPT_R2]'
    +', Atbl.[INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2]'
    +', Atbl.[INFANT_HEALTH_ER_1_INGEST_ERvsUC1]'
    +', Atbl.[INFANT_HEALTH_ER_1_INGEST_ERvsUC2]'
    +', Atbl.[INFANT_HEALTH_ER_1_INGEST_ERvsUC3]'
    +', Atbl.[INFANT_HEALTH_ER_1_INJ_ERvsUC2]'
    +', Atbl.[INFANT_HEALTH_ER_1_OTHER_ERvsUC1]'
    +', Atbl.[INFANT_HEALTH_ER_1_OTHER_ERvsUC2]'
    +', Atbl.[INFANT_HEALTH_NO_ASQ_COMM]'
    +', Atbl.[INFANT_HEALTH_NO_ASQ_FINE]'
    +', Atbl.[INFANT_HEALTH_NO_ASQ_GROSS]'
    +', Atbl.[INFANT_HEALTH_NO_ASQ_PERSONAL]'
    +', Atbl.[INFANT_HEALTH_NO_ASQ_PROBLEM]'
    +', Atbl.[INFANT_HEALTH_NO_ASQ_TOTAL]'
    +', Atbl.[INFANT_HEALTH_ER_1_INJ_ERvsUC3]'
    +', Atbl.[INFANT_HEALTH_ER_1_OTHER_ERvsUC3]'
    +', Atbl.[INFANT_PERSONAL_0_SSN]'
    +' ,atbl.INFANT_HEALTH_IMMUNIZ_UPDATE_YES'
    +' ,atbl.INFANT_HEALTH_IMMUNIZ_UPDATE_NO'
    +' ,atbl.INFANT_HEALTH_DENTIST'
    +' ,atbl.INFANT_HEALTH_DENTIST_STILL_EBF'
    +' ,atbl.INFANT_SOCIAL_SERVICES_1_REASON1_OTHER'
    +' ,atbl.INFANT_SOCIAL_SERVICES_1_REASON2_OTHER'
    +' ,atbl.INFANT_SOCIAL_SERVICES_1_REASON3_OTHER'
-- October 2016 Release:
    +' ,atbl.[INFANT_INSURANCE_TYPE]'
    +' ,atbl.[INFANT_AGES_STAGES_SE_VERSION]'
    +' ,atbl.[INFANT_BIRTH_COSLEEP]'
    +' ,atbl.[INFANT_BIRTH_READ]'
    +' ,atbl.[INFANT_BIRTH_SLEEP_BACK]'
    +' ,atbl.[INFANT_BIRTH_SLEEP_BEDDING]'
    +' ,atbl.[INFANT_HEALTH_DENTAL_SOURCE]'
    +' ,atbl.[INFANT_INSURANCE]'
    +' ,atbl.[INFANT_INSURANCE_OTHER]'
--  Integration set collumns:
    +', ms.SourceSurveyID'
    +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
set @SQL4 = '
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.INFANT_HEALTH_Survey Atbl'
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
    +' from dbo.INFANT_HEALTH_Survey dwsurvey'
    +' where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and dwsurvey.SurveyResponseID = Atbl.DW_SurveyResponseID)'
     

    print @SQL1
    print @SQL2
    print @SQL3
    print @SQL4
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar) 
       +', SQL3 Length = ' +CAST(LEN(@SQL3) as varchar) +', SQL4 Length = ' +CAST(LEN(@SQL4) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL1+@SQL2+@SQL3+@SQL4)

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
    +' update dbo.INFANT_HEALTH_Survey'
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
    +', [INFANT_0_ID_NSO] = Atbl.[INFANT_0_ID_NSO]'
    +', [INFANT_PERSONAL_0_NAME_FIRST] = Atbl.[INFANT_PERSONAL_0_NAME_FIRST]'
    +', [INFANT_BIRTH_0_DOB] = Atbl.[INFANT_BIRTH_0_DOB]'
    +', [CLIENT_0_ID_NSO] = Atbl.[CLIENT_0_ID_NSO]'
    +', [CLIENT_PERSONAL_0_NAME_FIRST] = Atbl.[CLIENT_PERSONAL_0_NAME_FIRST]'
    +', [CLIENT_PERSONAL_0_NAME_LAST] = Atbl.[CLIENT_PERSONAL_0_NAME_LAST]'
    +', [NURSE_PERSONAL_0_NAME] = exref1.Entity_ID'
    +', [INFANT_HEALTH_PROVIDER_0_PRIMARY] = Atbl.[INFANT_HEALTH_PROVIDER_0_PRIMARY]'
    +', [INFANT_HEALTH_IMMUNIZ_0_UPDATE] = Atbl.[INFANT_HEALTH_IMMUNIZ_0_UPDATE]'
    +', [INFANT_HEALTH_IMMUNIZ_1_RECORD] = Atbl.[INFANT_HEALTH_IMMUNIZ_1_RECORD]'
    +', [INFANT_HEALTH_LEAD_0_TEST] = Atbl.[INFANT_HEALTH_LEAD_0_TEST]'
    +', [INFANT_HEALTH_HEIGHT_0_INCHES] = Atbl.[INFANT_HEALTH_HEIGHT_0_INCHES]'
    +', [INFANT_HEALTH_HEIGHT_1_PERCENT] = Atbl.[INFANT_HEALTH_HEIGHT_1_PERCENT]'
    +', [INFANT_HEALTH_HEAD_0_CIRC_INCHES] = Atbl.[INFANT_HEALTH_HEAD_0_CIRC_INCHES]'
    +', [INFANT_HEALTH_ER_0_HAD_VISIT] = Atbl.[INFANT_HEALTH_ER_0_HAD_VISIT]'
    +', [INFANT_HEALTH_ER_1_TYPE] = Atbl.[INFANT_HEALTH_ER_1_TYPE]'
    +', [INFANT_HEALTH_ER_1_INJ_DATE1] = Atbl.[INFANT_HEALTH_ER_1_INJ_DATE1]'
    +', [INFANT_HEALTH_ER_1_INJ_DATE2] = Atbl.[INFANT_HEALTH_ER_1_INJ_DATE2]'
    +', [INFANT_HEALTH_ER_1_INJ_DATE3] = Atbl.[INFANT_HEALTH_ER_1_INJ_DATE3]'
    +', [INFANT_HEALTH_ER_1_INGEST_DATE1] = Atbl.[INFANT_HEALTH_ER_1_INGEST_DATE1]'
    +', [INFANT_HEALTH_ER_1_INGEST_DATE2] = Atbl.[INFANT_HEALTH_ER_1_INGEST_DATE2]'
    +', [INFANT_HEALTH_ER_1_INGEST_DATE3] = Atbl.[INFANT_HEALTH_ER_1_INGEST_DATE3]'
    +', [INFANT_HEALTH_HOSP_0_HAD_VISIT] = Atbl.[INFANT_HEALTH_HOSP_0_HAD_VISIT]'
    +', [INFANT_BREASTMILK_0_EVER_IHC] = Atbl.[INFANT_BREASTMILK_0_EVER_IHC]'
    +', [INFANT_BREASTMILK_1_CONT] = Atbl.[INFANT_BREASTMILK_1_CONT]'
    +', [INFANT_HEALTH_HOSP_1_INJ_DATE1] = Atbl.[INFANT_HEALTH_HOSP_1_INJ_DATE1]'
    +', [INFANT_HEALTH_HOSP_1_INJ_DATE2] = Atbl.[INFANT_HEALTH_HOSP_1_INJ_DATE2]'
    +', [INFANT_HEALTH_HOSP_1_INJ_DATE3] = Atbl.[INFANT_HEALTH_HOSP_1_INJ_DATE3]'
    +', [INFANT_HEALTH_HOSP_1_INGEST_DATE1] = Atbl.[INFANT_HEALTH_HOSP_1_INGEST_DATE1]'
    +', [INFANT_HEALTH_HOSP_1_INGEST_DATE2] = Atbl.[INFANT_HEALTH_HOSP_1_INGEST_DATE2]'
    +', [INFANT_HEALTH_HOSP_1_INGEST_DATE3] = Atbl.[INFANT_HEALTH_HOSP_1_INGEST_DATE3]'
set @SQL2 = ', [INFANT_HEALTH_HOSP_1_TYPE] = Atbl.[INFANT_HEALTH_HOSP_1_TYPE]'
    +', [INFANT_BREASTMILK_1_AGE_STOP] = Atbl.[INFANT_BREASTMILK_1_AGE_STOP]'
    +', [INFANT_BREASTMILK_1_WEEK_STOP] = Atbl.[INFANT_BREASTMILK_1_WEEK_STOP]'
    +', [INFANT_BREASTMILK_1_EXCLUSIVE_WKS] = Atbl.[INFANT_BREASTMILK_1_EXCLUSIVE_WKS]'
    +', [INFANT_SOCIAL_SERVICES_0_REFERRAL] = Atbl.[INFANT_SOCIAL_SERVICES_0_REFERRAL]'
    +', [INFANT_SOCIAL_SERVICES_1_REFDATE1] = Atbl.[INFANT_SOCIAL_SERVICES_1_REFDATE1]'
    +', [INFANT_SOCIAL_SERVICES_1_REFDATE2] = Atbl.[INFANT_SOCIAL_SERVICES_1_REFDATE2]'
    +', [INFANT_SOCIAL_SERVICES_1_REFDATE3] = Atbl.[INFANT_SOCIAL_SERVICES_1_REFDATE3]'
    +', [INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL] = Atbl.[INFANT_SOCIAL_SERVICES_1_NHV_REFERRAL]'
    +', [INFANT_SOCIAL_SERVICES_1_NHV_REFDATE1] = Atbl.[INFANT_SOCIAL_SERVICES_1_NHV_REFDATE1]'
    +', [INFANT_SOCIAL_SERVICES_1_NHV_REFDATE2] = Atbl.[INFANT_SOCIAL_SERVICES_1_NHV_REFDATE2]'
    +', [INFANT_SOCIAL_SERVICES_1_NHV_REFDATE3] = Atbl.[INFANT_SOCIAL_SERVICES_1_NHV_REFDATE3]'
    +', [INFANT_HEALTH_WEIGHT_0_POUNDS] = Atbl.[INFANT_HEALTH_WEIGHT_0_POUNDS]'
    +', [INFANT_HEALTH_WEIGHT_1_OUNCES] = Atbl.[INFANT_HEALTH_WEIGHT_1_OUNCES]'
    +', [INFANT_HEALTH_WEIGHT_1_OZ] = Atbl.[INFANT_HEALTH_WEIGHT_1_OZ]'
    +', [INFANT_HEALTH_WEIGHT_1_PERCENT] = Atbl.[INFANT_HEALTH_WEIGHT_1_PERCENT]'
    +', [CLIENT_0_ID_AGENCY] = Atbl.[CLIENT_0_ID_AGENCY]'
    +', [INFANT_AGES_STAGES_1_COMM] = Atbl.[INFANT_AGES_STAGES_1_COMM]'
    +', [INFANT_AGES_STAGES_0_VERSION] = Atbl.[INFANT_AGES_STAGES_0_VERSION]'
    +', [INFANT_AGES_STAGES_1_GMOTOR] = Atbl.[INFANT_AGES_STAGES_1_GMOTOR]'
    +', [INFANT_AGES_STAGES_1_FMOTOR] = Atbl.[INFANT_AGES_STAGES_1_FMOTOR]'
    +', [INFANT_AGES_STAGES_1_PSOLVE] = Atbl.[INFANT_AGES_STAGES_1_PSOLVE]'
    +', [INFANT_AGES_STAGES_1_PSOCIAL] = Atbl.[INFANT_AGES_STAGES_1_PSOCIAL]'
    +', [INFANT_AGES_STAGES_SE_0_EMOTIONAL] = Atbl.[INFANT_AGES_STAGES_SE_0_EMOTIONAL]'
    +', [INFANT_PERSONAL_0_NAME_LAST] = Atbl.[INFANT_PERSONAL_0_NAME_LAST]'
    +', [INFANT_HEALTH_HEAD_1_REPORT] = Atbl.[INFANT_HEALTH_HEAD_1_REPORT]'
    +', [INFANT_HEALTH_HEIGHT_1_REPORT] = Atbl.[INFANT_HEALTH_HEIGHT_1_REPORT]'
    +', [INFANT_HEALTH_PROVIDER_0_APPT] = Atbl.[INFANT_HEALTH_PROVIDER_0_APPT]'
    +', [INFANT_HEALTH_WEIGHT_1_REPORT] = Atbl.[INFANT_HEALTH_WEIGHT_1_REPORT]'
    +', [INFANT_HEALTH_ER_1_OTHERDT1] = Atbl.[INFANT_HEALTH_ER_1_OTHERDT1]'
    +', [INFANT_HEALTH_ER_1_INGEST_TREAT1] = Atbl.[INFANT_HEALTH_ER_1_INGEST_TREAT1]'
    +', [INFANT_HEALTH_ER_1_INGEST_TREAT2] = Atbl.[INFANT_HEALTH_ER_1_INGEST_TREAT2]'
    +', [INFANT_HEALTH_ER_1_INGEST_TREAT3] = Atbl.[INFANT_HEALTH_ER_1_INGEST_TREAT3]'
    +', [INFANT_HEALTH_ER_1_INJ_TREAT1] = Atbl.[INFANT_HEALTH_ER_1_INJ_TREAT1]'
    +', [INFANT_HEALTH_ER_1_INJ_TREAT2] = Atbl.[INFANT_HEALTH_ER_1_INJ_TREAT2]'
    +', [INFANT_HEALTH_ER_1_OTHER] = Atbl.[INFANT_HEALTH_ER_1_OTHER]'
set @SQL3 = ', [INFANT_HEALTH_ER_1_OTHER_REASON1] = Atbl.[INFANT_HEALTH_ER_1_OTHER_REASON1]'
    +', [INFANT_HEALTH_ER_1_OTHER_REASON2] = Atbl.[INFANT_HEALTH_ER_1_OTHER_REASON2]'
    +', [INFANT_HEALTH_ER_1_OTHER_REASON3] = Atbl.[INFANT_HEALTH_ER_1_OTHER_REASON3]'
    +', [INFANT_HEALTH_ER_1_OTHERDT2] = Atbl.[INFANT_HEALTH_ER_1_OTHERDT2]'
    +', [INFANT_HEALTH_ER_1_OTHERDT3] = Atbl.[INFANT_HEALTH_ER_1_OTHERDT3]'
    +', [INFANT_HOME_0_TOTAL] = Atbl.[INFANT_HOME_0_TOTAL]'
    +', [INFANT_HOME_1_ACCEPTANCE] = Atbl.[INFANT_HOME_1_ACCEPTANCE]'
    +', [INFANT_HOME_1_EXPERIENCE] = Atbl.[INFANT_HOME_1_EXPERIENCE]'
    +', [INFANT_HOME_1_INVOLVEMENT] = Atbl.[INFANT_HOME_1_INVOLVEMENT]'
    +', [INFANT_HOME_1_LEARNING] = Atbl.[INFANT_HOME_1_LEARNING]'
    +', [INFANT_HOME_1_ORGANIZATION] = Atbl.[INFANT_HOME_1_ORGANIZATION]'
    +', [INFANT_HOME_1_RESPONSIVITY] = Atbl.[INFANT_HOME_1_RESPONSIVITY]'
    +', [INFANT_SOCIAL_SERVICES_1_NHV_REASON1] = Atbl.[INFANT_SOCIAL_SERVICES_1_NHV_REASON1]'
    +', [INFANT_SOCIAL_SERVICES_1_NHV_REASON2] = Atbl.[INFANT_SOCIAL_SERVICES_1_NHV_REASON2]'
    +', [INFANT_SOCIAL_SERVICES_1_NHV_REASON3] = Atbl.[INFANT_SOCIAL_SERVICES_1_NHV_REASON3]'
    +', [INFANT_SOCIAL_SERVICES_1_REASON1] = Atbl.[INFANT_SOCIAL_SERVICES_1_REASON1]'
    +', [INFANT_SOCIAL_SERVICES_1_REASON2] = Atbl.[INFANT_SOCIAL_SERVICES_1_REASON2]'
    +', [INFANT_SOCIAL_SERVICES_1_REASON3] = Atbl.[INFANT_SOCIAL_SERVICES_1_REASON3]'
    +', [INFANT_HEALTH_ER_1_INJ_TREAT3] = Atbl.[INFANT_HEALTH_ER_1_INJ_TREAT3]' 
    +', [INFANT_HEALTH_ER_1_INJ_ERvsUC1] = Atbl.[INFANT_HEALTH_ER_1_INJ_ERvsUC1]'
    +', [INFANT_HEALTH_PROVIDER_0_APPT_R2] = Atbl.[INFANT_HEALTH_PROVIDER_0_APPT_R2]'
    +', [INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2] = Atbl.[INFANT_HEALTH_PROVIDER_0_APPT_DETAILSR2]'
    +', [INFANT_HEALTH_ER_1_INGEST_ERvsUC1] = Atbl.[INFANT_HEALTH_ER_1_INGEST_ERvsUC1]'
    +', [INFANT_HEALTH_ER_1_INGEST_ERvsUC2] = Atbl.[INFANT_HEALTH_ER_1_INGEST_ERvsUC2]'
    +', [INFANT_HEALTH_ER_1_INGEST_ERvsUC3] = Atbl.[INFANT_HEALTH_ER_1_INGEST_ERvsUC3]'
    +', [INFANT_HEALTH_ER_1_INJ_ERvsUC2] = Atbl.[INFANT_HEALTH_ER_1_INJ_ERvsUC2]'
    +', [INFANT_HEALTH_ER_1_OTHER_ERvsUC1] = Atbl.[INFANT_HEALTH_ER_1_OTHER_ERvsUC1]'
    +', [INFANT_HEALTH_ER_1_OTHER_ERvsUC2] = Atbl.[INFANT_HEALTH_ER_1_OTHER_ERvsUC2]'
    +', [INFANT_HEALTH_NO_ASQ_COMM] = Atbl.[INFANT_HEALTH_NO_ASQ_COMM]'
    +', [INFANT_HEALTH_NO_ASQ_FINE] = Atbl.[INFANT_HEALTH_NO_ASQ_FINE]'
    +', [INFANT_HEALTH_NO_ASQ_GROSS] = Atbl.[INFANT_HEALTH_NO_ASQ_GROSS]'
    +', [INFANT_HEALTH_NO_ASQ_PERSONAL] = Atbl.[INFANT_HEALTH_NO_ASQ_PERSONAL]'
    +', [INFANT_HEALTH_NO_ASQ_PROBLEM] = Atbl.[INFANT_HEALTH_NO_ASQ_PROBLEM]'
    +', [INFANT_HEALTH_NO_ASQ_TOTAL] = Atbl.[INFANT_HEALTH_NO_ASQ_TOTAL]'
    +', [INFANT_HEALTH_ER_1_INJ_ERvsUC3] = Atbl.[INFANT_HEALTH_ER_1_INJ_ERvsUC3]'
    +', [INFANT_HEALTH_ER_1_OTHER_ERvsUC3] = Atbl.[INFANT_HEALTH_ER_1_OTHER_ERvsUC3]'
    +', [INFANT_PERSONAL_0_SSN] = Atbl.[INFANT_PERSONAL_0_SSN]'
set @SQL4 = ' ,INFANT_HEALTH_IMMUNIZ_UPDATE_YES = atbl.INFANT_HEALTH_IMMUNIZ_UPDATE_YES'
    +' ,INFANT_HEALTH_IMMUNIZ_UPDATE_NO = atbl.INFANT_HEALTH_IMMUNIZ_UPDATE_NO'
    +' ,INFANT_HEALTH_DENTIST = atbl.INFANT_HEALTH_DENTIST'
    +' ,INFANT_HEALTH_DENTIST_STILL_EBF = atbl.INFANT_HEALTH_DENTIST_STILL_EBF'
    +' ,INFANT_SOCIAL_SERVICES_1_REASON1_OTHER = atbl.INFANT_SOCIAL_SERVICES_1_REASON1_OTHER'
    +' ,INFANT_SOCIAL_SERVICES_1_REASON2_OTHER = atbl.INFANT_SOCIAL_SERVICES_1_REASON2_OTHER'
    +' ,INFANT_SOCIAL_SERVICES_1_REASON3_OTHER = atbl.INFANT_SOCIAL_SERVICES_1_REASON3_OTHER'
-- October 2016 Release:
    +' ,[INFANT_INSURANCE_TYPE] = atbl.[INFANT_INSURANCE_TYPE]'
    +' ,[INFANT_AGES_STAGES_SE_VERSION] = atbl.[INFANT_AGES_STAGES_SE_VERSION]'
    +' ,[INFANT_BIRTH_COSLEEP] = atbl.[INFANT_BIRTH_COSLEEP]'
    +' ,[INFANT_BIRTH_READ] = atbl.[INFANT_BIRTH_READ]'
    +' ,[INFANT_BIRTH_SLEEP_BACK] = atbl.[INFANT_BIRTH_SLEEP_BACK]'
    +' ,[INFANT_BIRTH_SLEEP_BEDDING] = atbl.[INFANT_BIRTH_SLEEP_BEDDING]'
    +' ,[INFANT_HEALTH_DENTAL_SOURCE] = atbl.[INFANT_HEALTH_DENTAL_SOURCE]'
    +' ,[INFANT_INSURANCE] = atbl.[INFANT_INSURANCE]'
    +' ,[INFANT_INSURANCE_OTHER] = atbl.[INFANT_INSURANCE_OTHER]'
--  Integration set collumns:
    +', [Master_SurveyID] = ms.SourceSurveyID'
    +', [DW_AuditDate] = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from dbo.INFANT_HEALTH_Survey dwsurvey'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.INFANT_HEALTH_Survey Atbl'
    +'   on dwsurvey.SurveyResponseID = Atbl.DW_SurveyResponseID'
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
    +' and isnull(dwsurvey.AuditDate,convert(datetime,''19700101'',112)) <'
    +' isnull(Atbl.AuditDate,convert(datetime,''19700101'',112))'


    print @SQL1
    print @SQL2
    print @SQL3
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
       +', SQL3 Length = ' +CAST(LEN(@SQL3) as varchar) +', SQL4 Length = ' +CAST(LEN(@SQL4) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL1+@SQL2+@SQL3+@SQL4)



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

print 'End of Process: SP_AGENCYDB_INFANT_HEALTH_SURVEY'
GO
