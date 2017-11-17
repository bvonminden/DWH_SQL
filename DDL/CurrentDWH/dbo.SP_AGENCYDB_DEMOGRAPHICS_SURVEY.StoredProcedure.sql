USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_DEMOGRAPHICS_SURVEY]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_DEMOGRAPHICS_SURVEY
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_DEMOGRAPHICS_SURVEY]
 (@p_datasource      nvarchar(10) = null
 ,@p_no_delete_opt   nvarchar(2)  = null
 ,@p_no_exec_flag    nvarchar(10) = 'N')
AS
--
-- This script controls integration of AgencyDB Surveys to the Data Warehouse 
-- DEMOGRAPHICS_Survey table.
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
--              Added database trigger to inhibit the processing of this procedure (defaulting as always process)
--                This trigger is used to bypass the process w/o having to modify the SSIS integration packages.
--              Added database trigger to inhibit the processing of this procedure (defaulting as always process).
--                This trigger is used to bypass the process w/o having to modify the SSIS integration packages.
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
--   20150623 - Added additional new fields to be integrated.
--   20160706 - Added additional conditional logic to match siteid when looking up xrefs to entities and clients,
--              to accommodate multiple sites within the same AgencyDB, using same numbering scheme between sites.
--   20161026 - Setup new pseudonyms for the Oct 2016 ETO release.  Retired columns will still be applied for history.
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

set @process          = 'SP_AGENCYDB_DEMOGRAPHICS_SURVEY'
set @DW_Tablename     = 'DEMOGRAPHICS_SURVEY'
set @Agency_Tablename = 'DEMOGRAPHICS_SURVEY'
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            nvarchar(MAX)
DECLARE @SQL1            nvarchar(MAX)
DECLARE @SQL2            nvarchar(MAX)
DECLARE @SQL3            nvarchar(MAX)
DECLARE @SQL4            nvarchar(MAX)

print 'Processing SP_AGENCYDB_DEMOGRAPHICS_SURVEY: Datasource = ' +isnull(@p_datasource,'NULL')
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


print ' '
print 'Creating new survey records'
set @SQL1 = 'set nocount off'
    +' insert into dbo.DEMOGRAPHICS_Survey'
    +' ([SurveyResponseID],[DataSource],[ElementsProcessed]'
    +' ,[SurveyID]'
    +' ,[SurveyDate]'
    +' ,[AuditDate]'
    +' ,[CL_EN_GEN_ID]'
    +' ,[SiteID]'
    +' ,[ProgramID]'
    --+' ,[IA_StaffID]'
    +' ,[ClientID]'
    +' ,[RespondentID]'
    +' ,[CLIENT_PERSONAL_0_VOLUNTARILY_INVOLVED]'
    +' ,[CLIENT_MARITAL_0_STATUS]'
    +' ,[CLIENT_BIO_DAD_0_CONTACT_WITH]'
    +' ,[CLIENT_LIVING_0_WITH]'
    +' ,[CLIENT_LIVING_1_WITH_OTHERS]'
    +' ,[CLIENT_EDUCATION_0_HS_GED]'
    +' ,[CLIENT_EDUCATION_1_HS_GED_LAST_GRADE]'
    +' ,[CLIENT_EDUCATION_1_HIGHER_EDUC_COMP]'
    +' ,[CLIENT_EDUCATION_1_ENROLLED_CURRENT]'
    +' ,[CLIENT_EDUCATION_1_ENROLLED_TYPE]'
    +' ,[CLIENT_EDUCATION_1_ENROLLED_PLAN]'
    +' ,[CLIENT_WORKING_0_CURRENTLY_WORKING]'
    +' ,[CLIENT_INCOME_0_HH_INCOME]'
    +' ,[CLIENT_INCOME_1_LOW_INCOME_QUALIFY]'
    +' ,[CLIENT_0_ID_NSO]'
    +' ,[CLIENT_PERSONAL_0_NAME_FIRST]'
    +' ,[CLIENT_PERSONAL_0_NAME_LAST]'
    +' ,[NURSE_PERSONAL_0_NAME]'
    +' ,[CLIENT_PERSONAL_0_DOB_INTAKE]'
    +' ,[CLIENT_PERSONAL_0_ETHNICITY_INTAKE]'
    +' ,[CLIENT_PERSONAL_0_RACE]'
    +' ,[CLIENT_PERSONAL_LANGUAGE_0_INTAKE]'
    +' ,[CLIENT_0_ID_AGENCY]'
    +' ,[CLIENT_WORKING_1_WORKED_SINCE_BIRTH]'
    +' ,[CLIENT_WORKING_1_WORKED_SINCE_BIRTH_MONTHS]'
    +' ,[CLIENT_BC_0_USED_6MONTHS]'
    +' ,[CLIENT_BC_1_NOT_USED_REASON]'
    +' ,[CLIENT_BC_1_FREQUENCY]'
    +' ,[CLIENT_BC_1_TYPES]'
    +' ,[CLIENT_SUBPREG_0_BEEN_PREGNANT]'
    +' ,[CLIENT_SUBPREG_1_BEGIN_MONTH]'
    +' ,[CLIENT_SUBPREG_1_BEGIN_YEAR]'
    +' ,[CLIENT_SUBPREG_1_PLANNED]'
    +' ,[CLIENT_SUBPREG_1_OUTCOME]'
    +' ,[CLIENT_SECOND_0_CHILD_DOB]'
    +' ,[CLIENT_SECOND_1_CHILD_GENDER]'
    +' ,[CLIENT_SECOND_1_CHILD_BW_POUNDS]'
    +' ,[CLIENT_SECOND_1_CHILD_BW_OZ]'
    +' ,[CLIENT_SECOND_1_CHILD_NICU]'
    +' ,[CLIENT_SECOND_1_CHILD_NICU_DAYS]'
    +' ,[CLIENT_BIO_DAD_1_TIME_WITH]'
    +' ,[ADULTS_1_ENROLL_NO]'
    +' ,[ADULTS_1_ENROLL_PT]'
    +' ,[ADULTS_1_CARE_10]'
    +' ,[ADULTS_1_CARE_20]'
    +' ,[ADULTS_1_CARE_30]'
    +' ,[ADULTS_1_CARE_40]'
    +' ,[ADULTS_1_CARE_LESS10]'
    +' ,[ADULTS_1_COMPLETE_GED]'
    +' ,[ADULTS_1_COMPLETE_HS]'
    +' ,[ADULTS_1_COMPLETE_HS_NO]'
    +' ,[ADULTS_1_ED_TECH]'
    +' ,[ADULTS_1_ED_ASSOCIATE]'
    +' ,[ADULTS_1_ED_BACHELOR]'
    +' ,[ADULTS_1_ED_MASTER]'
    +' ,[ADULTS_1_ED_NONE]'
    +' ,[ADULTS_1_ED_POSTGRAD]'
    +' ,[ADULTS_1_ED_SOME_COLLEGE]'
    +' ,[ADULTS_1_ED_UNKNOWN]'
    +' ,[ADULTS_1_ENROLL_FT]'
    +' ,[ADULTS_1_INS_NO]'
    +' ,[ADULTS_1_INS_PRIVATE]'
    +' ,[ADULTS_1_INS_PUBLIC]'
    +' ,[ADULTS_1_WORK_10]'
    +' ,[ADULTS_1_WORK_20]'
    +' ,[ADULTS_1_WORK_37]'
    +' ,[ADULTS_1_WORK_LESS10]'
    +' ,[ADULTS_1_WORK_UNEMPLOY]'
    +' ,[CLIENT_CARE_0_ER_HOSP]'
    +' ,[CLIENT_EDUCATION_1_ENROLLED_FTPT]'
    +' ,[CLIENT_INCOME_1_HH_SOURCES]'
    +' ,[CLIENT_WORKING_1_CURRENTLY_WORKING_HRS]'
    +' ,[CLIENT_EDUCATION_1_ENROLLED_PT_HRS]'
    +' ,[CLIENT_SCHOOL_MIDDLE_HS]'
    +' ,[CLIENT_ED_PROG_TYPE]'
    +' ,[CLIENT_PROVIDE_CHILDCARE]'
    +' ,[CLIENT_WORKING_2_CURRENTLY_WORKING_NO]'
    +' ,[CLIENT_CARE_0_ER]'
    +' ,[CLIENT_CARE_0_URGENT]'
    +' ,[CLIENT_CARE_0_ER_TIMES]'
    +' ,[CLIENT_CARE_0_URGENT_TIMES]'
    +' ,[CLIENT_INCOME_IN_KIND]'
    +' ,[CLIENT_INCOME_SOURCES]'
    +' ,[CLIENT_MILITARY]'
    +' ,[DELETE ME]'
    +' ,[CLIENT_INCOME_AMOUNT]'
    +' ,[CLIENT_WORKING_1_CURRENTLY_WORKING_NO]'
    +' ,[CLIENT_INCOME_INKIND_OTHER]'
    +' ,[CLIENT_INCOME_OTHER_SOURCES]'
    +' ,[CLIENT_BC_1_TYPES_NEXT6]'
    +' ,[CLIENT_SUBPREG_1_EDD]'
    +' ,[CLIENT_SUBPREG_1_GEST_AGE]'
    +' ,[CLIENT_CARE_0_ER_FEVER_TIMES]'
    +' ,[CLIENT_CARE_0_ER_INFECTION_TIMES]'
    +' ,[CLIENT_CARE_0_ER_INGESTION_TIMES]'
    +' ,[CLIENT_CARE_0_ER_INJURY_TIMES]'
    +' ,[CLIENT_CARE_0_ER_OTHER]'
    +' ,[CLIENT_CARE_0_ER_OTHER_TIMES]'
    +' ,[CLIENT_CARE_0_ER_PURPOSE]'
    +' ,[CLIENT_CARE_0_URGENT_FEVER_TIMES]'
    +' ,[CLIENT_CARE_0_URGENT_INFECTION_TIMES]'
    +' ,[CLIENT_CARE_0_URGENT_INGESTION_TIMES]'
    +' ,[CLIENT_CARE_0_URGENT_INJURY_TIMES]'
    +' ,[CLIENT_CARE_0_URGENT_OTHER]'
    +' ,[CLIENT_CARE_0_URGENT_OTHER_TIMES]'
    +' ,[CLIENT_CARE_0_URGENT_PURPOSE]'
    +' ,[CLIENT_SECOND_1_CHILD_BW_CONVERT_GRAMS]'
    +' ,[CLIENT_SECOND_1_CHILD_BW_GRAMS]'
    +' ,[CLIENT_SECOND_1_CHILD_BW_MEASURE]'
    +' ,[CLIENT_CARE_0_URGENT_PURPOSE_R6]'
    +' ,[CLIENT_CARE_0_ER_PURPOSE_R6]'
    +' ,[CLIENT_SUBPREG]'
    +' ,[CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES]'
    +' ,[CLIENT_CARE_0_ER_INJURY_SELF_TIMES]'
    +' ,[CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES]'
    +' ,[CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES]'
    +' ,[CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES]'
    +' ,[CLIENT_CARE_0_ER_INGESTION_SELF_TIMES]'
    +' ,[CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES]'
    +' ,[CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES]'
    +' ,[CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES]'
    +' ,[CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES]'
    +' ,[CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES]'
    +' ,[CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES]'
    +' ,[CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES]'
    +' ,[CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES]'
    +' ,[CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES]'
    +' ,[CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES]'
-- October 2016 ETO Release:
    +', [CLIENT_INSURANCE_TYPE]'
    +', [CLIENT_INSURANCE]'
    +', [CLIENT_LIVING_HOMELESS]'
    +', [CLIENT_LIVING_WHERE]'
    +', [CLIENT_INSURANCE_OTHER]'
-- Integration set columns:
    +' ,[Master_SurveyID]'
    +' ,[DW_AuditDate])'

set @SQL2 = '
     SELECT  DW_SurveyResponseID as SurveyResponseID, ''' +@p_datasource +''''
    +' ,1'
    +' ,Atbl.[SurveyID]'
    +' ,Atbl.[SurveyDate]'
    +' ,Atbl.[AuditDate]'
    +' ,cxref1.Client_ID'
    +' ,Atbl.[SiteID]'
    +' ,Atbl.[ProgramID]'
    --+' ,Atbl.[IA_StaffID]'
    +' ,cxref2.Client_ID'
    +' ,Atbl.[RespondentID]'
    +' ,Atbl.[CLIENT_PERSONAL_0_VOLUNTARILY_INVOLVED]'
    +' ,Atbl.[CLIENT_MARITAL_0_STATUS]'
    +' ,Atbl.[CLIENT_BIO_DAD_0_CONTACT_WITH]'
    +' ,Atbl.[CLIENT_LIVING_0_WITH]'
    +' ,Atbl.[CLIENT_LIVING_1_WITH_OTHERS]'
    +' ,Atbl.[CLIENT_EDUCATION_0_HS_GED]'
    +' ,Atbl.[CLIENT_EDUCATION_1_HS_GED_LAST_GRADE]'
    +' ,Atbl.[CLIENT_EDUCATION_1_HIGHER_EDUC_COMP]'
    +' ,Atbl.[CLIENT_EDUCATION_1_ENROLLED_CURRENT]'
    +' ,Atbl.[CLIENT_EDUCATION_1_ENROLLED_TYPE]'
    +' ,Atbl.[CLIENT_EDUCATION_1_ENROLLED_PLAN]'
    +' ,Atbl.[CLIENT_WORKING_0_CURRENTLY_WORKING]'
    +' ,Atbl.[CLIENT_INCOME_0_HH_INCOME]'
    +' ,Atbl.[CLIENT_INCOME_1_LOW_INCOME_QUALIFY]'
    +' ,Atbl.[CLIENT_0_ID_NSO]'
    +' ,Atbl.[CLIENT_PERSONAL_0_NAME_FIRST]'
    +' ,Atbl.[CLIENT_PERSONAL_0_NAME_LAST]'
    +' ,exref1.Entity_ID'
    +' ,Atbl.[CLIENT_PERSONAL_0_DOB_INTAKE]'
    +' ,Atbl.[CLIENT_PERSONAL_0_ETHNICITY_INTAKE]'
    +' ,Atbl.[CLIENT_PERSONAL_0_RACE]'
    +' ,Atbl.[CLIENT_PERSONAL_LANGUAGE_0_INTAKE]'
    +' ,Atbl.[CLIENT_0_ID_AGENCY]'
    +' ,Atbl.[CLIENT_WORKING_1_WORKED_SINCE_BIRTH]'
    +' ,Atbl.[CLIENT_WORKING_1_WORKED_SINCE_BIRTH_MONTHS]'
    +' ,Atbl.[CLIENT_BC_0_USED_6MONTHS]'
    +' ,Atbl.[CLIENT_BC_1_NOT_USED_REASON]'
    +' ,Atbl.[CLIENT_BC_1_FREQUENCY]'
    +' ,Atbl.[CLIENT_BC_1_TYPES]'
    +' ,Atbl.[CLIENT_SUBPREG_0_BEEN_PREGNANT]'
    +' ,Atbl.[CLIENT_SUBPREG_1_BEGIN_MONTH]'
    +' ,Atbl.[CLIENT_SUBPREG_1_BEGIN_YEAR]'
    +' ,Atbl.[CLIENT_SUBPREG_1_PLANNED]'
    +' ,Atbl.[CLIENT_SUBPREG_1_OUTCOME]'
    +' ,Atbl.[CLIENT_SECOND_0_CHILD_DOB]'
    +' ,Atbl.[CLIENT_SECOND_1_CHILD_GENDER]'
    +' ,Atbl.[CLIENT_SECOND_1_CHILD_BW_POUNDS]'
    +' ,Atbl.[CLIENT_SECOND_1_CHILD_BW_OZ]'
    +' ,Atbl.[CLIENT_SECOND_1_CHILD_NICU]'
    +' ,Atbl.[CLIENT_SECOND_1_CHILD_NICU_DAYS]'
    +' ,Atbl.[CLIENT_BIO_DAD_1_TIME_WITH]'
    +' ,Atbl.[ADULTS_1_ENROLL_NO]'
    +' ,Atbl.[ADULTS_1_ENROLL_PT]'
    +' ,Atbl.[ADULTS_1_CARE_10]'
    +' ,Atbl.[ADULTS_1_CARE_20]'
    +' ,Atbl.[ADULTS_1_CARE_30]'
    +' ,Atbl.[ADULTS_1_CARE_40]'
    +' ,Atbl.[ADULTS_1_CARE_LESS10]'
    +' ,Atbl.[ADULTS_1_COMPLETE_GED]'
    +' ,Atbl.[ADULTS_1_COMPLETE_HS]'
    +' ,Atbl.[ADULTS_1_COMPLETE_HS_NO]'
    +' ,Atbl.[ADULTS_1_ED_TECH]'
    +' ,Atbl.[ADULTS_1_ED_ASSOCIATE]'
    +' ,Atbl.[ADULTS_1_ED_BACHELOR]'
    +' ,Atbl.[ADULTS_1_ED_MASTER]'
    +' ,Atbl.[ADULTS_1_ED_NONE]'
    +' ,Atbl.[ADULTS_1_ED_POSTGRAD]'
    +' ,Atbl.[ADULTS_1_ED_SOME_COLLEGE]'
    +' ,Atbl.[ADULTS_1_ED_UNKNOWN]'
    +' ,Atbl.[ADULTS_1_ENROLL_FT]'
    +' ,Atbl.[ADULTS_1_INS_NO]'
    +' ,Atbl.[ADULTS_1_INS_PRIVATE]'
    +' ,Atbl.[ADULTS_1_INS_PUBLIC]'
    +' ,Atbl.[ADULTS_1_WORK_10]'
    +' ,Atbl.[ADULTS_1_WORK_20]'
    +' ,Atbl.[ADULTS_1_WORK_37]'
    +' ,Atbl.[ADULTS_1_WORK_LESS10]'
    +' ,Atbl.[ADULTS_1_WORK_UNEMPLOY]'
    +' ,Atbl.[CLIENT_CARE_0_ER_HOSP]'
    +' ,Atbl.[CLIENT_EDUCATION_1_ENROLLED_FTPT]'
    +' ,Atbl.[CLIENT_INCOME_1_HH_SOURCES]'
    +' ,Atbl.[CLIENT_WORKING_1_CURRENTLY_WORKING_HRS]'
    +' ,Atbl.[CLIENT_EDUCATION_1_ENROLLED_PT_HRS]'
    +' ,Atbl.[CLIENT_SCHOOL_MIDDLE_HS]'
    +' ,Atbl.[CLIENT_ED_PROG_TYPE]'
    +' ,Atbl.[CLIENT_PROVIDE_CHILDCARE]'
    +' ,Atbl.[CLIENT_WORKING_2_CURRENTLY_WORKING_NO]'
    +' ,Atbl.[CLIENT_CARE_0_ER]'
    +' ,Atbl.[CLIENT_CARE_0_URGENT]'
    +' ,Atbl.[CLIENT_CARE_0_ER_TIMES]'
    +' ,Atbl.[CLIENT_CARE_0_URGENT_TIMES]'
    +' ,Atbl.[CLIENT_INCOME_IN_KIND]'
    +' ,Atbl.[CLIENT_INCOME_SOURCES]'
    +' ,Atbl.[CLIENT_MILITARY]'
    +' ,Atbl.[DELETE ME]'
    +' ,Atbl.[CLIENT_INCOME_AMOUNT]'
    +' ,Atbl.[CLIENT_WORKING_1_CURRENTLY_WORKING_NO]'
    +' ,Atbl.[CLIENT_INCOME_INKIND_OTHER]'
    +' ,Atbl.[CLIENT_INCOME_OTHER_SOURCES]'
set @SQL3 = '
       ,Atbl.[CLIENT_BC_1_TYPES_NEXT6]'
    +' ,Atbl.[CLIENT_SUBPREG_1_EDD]'
    +' ,Atbl.[CLIENT_SUBPREG_1_GEST_AGE]'
    +' ,Atbl.[CLIENT_CARE_0_ER_FEVER_TIMES]'
    +' ,Atbl.[CLIENT_CARE_0_ER_INFECTION_TIMES]'
    +' ,Atbl.[CLIENT_CARE_0_ER_INGESTION_TIMES]'
    +' ,Atbl.[CLIENT_CARE_0_ER_INJURY_TIMES]'
    +' ,Atbl.[CLIENT_CARE_0_ER_OTHER]'
    +' ,Atbl.[CLIENT_CARE_0_ER_OTHER_TIMES]'
    +' ,Atbl.[CLIENT_CARE_0_ER_PURPOSE]'
    +' ,Atbl.[CLIENT_CARE_0_URGENT_FEVER_TIMES]'
    +' ,Atbl.[CLIENT_CARE_0_URGENT_INFECTION_TIMES]'
    +' ,Atbl.[CLIENT_CARE_0_URGENT_INGESTION_TIMES]'
    +' ,Atbl.[CLIENT_CARE_0_URGENT_INJURY_TIMES]'
    +' ,Atbl.[CLIENT_CARE_0_URGENT_OTHER]'
    +' ,Atbl.[CLIENT_CARE_0_URGENT_OTHER_TIMES]'
    +' ,Atbl.[CLIENT_CARE_0_URGENT_PURPOSE]'
    +' ,Atbl.[CLIENT_SECOND_1_CHILD_BW_CONVERT_GRAMS]'
    +' ,Atbl.[CLIENT_SECOND_1_CHILD_BW_GRAMS]'
    +' ,Atbl.[CLIENT_SECOND_1_CHILD_BW_MEASURE]'
    +' ,atbl.[CLIENT_CARE_0_URGENT_PURPOSE_R6]'
    +' ,atbl.[CLIENT_CARE_0_ER_PURPOSE_R6]'
    +' ,atbl.[CLIENT_SUBPREG]'
    +' ,atbl.[CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES]'
    +' ,atbl.[CLIENT_CARE_0_ER_INJURY_SELF_TIMES]'
    +' ,atbl.[CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES]'
    +' ,atbl.[CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES]'
    +' ,atbl.[CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES]'
    +' ,atbl.[CLIENT_CARE_0_ER_INGESTION_SELF_TIMES]'
    +' ,atbl.[CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES]'
    +' ,atbl.[CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES]'
    +' ,atbl.[CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES]'
    +' ,atbl.[CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES]'
    +' ,atbl.[CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES]'
    +' ,atbl.[CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES]'
    +' ,atbl.[CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES]'
    +' ,atbl.[CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES]'
    +' ,atbl.[CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES]'
    +' ,atbl.[CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES]'
-- October 2016 ETO Release:
    +', atbl.[CLIENT_INSURANCE_TYPE]'
    +', atbl.[CLIENT_INSURANCE]'
    +', atbl.[CLIENT_LIVING_HOMELESS]'
    +', atbl.[CLIENT_LIVING_WHERE]'
    +', atbl.[CLIENT_INSURANCE_OTHER]'
-- Integration set columns:
    +' ,ms.SourceSurveyID'
    +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
set @SQL3 = @SQL3 +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.DEMOGRAPHICS_Survey Atbl'
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
    +' from dbo.DEMOGRAPHICS_Survey dwsurvey'
    +' where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and dwsurvey.SurveyResponseID = Atbl.DW_SurveyResponseID)'
     

    print @SQL1 
    print @SQL2
    print @SQL3
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) 
          +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
          +', SQL3 Length = ' +CAST(LEN(@SQL3) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL1+@SQL2+@SQL3)

--   and exists (select nfpagencies.Site_ID
--                     from dbo.Agencies nfpagencies
--                    where nfpagencies.Site_Id = Sites.SiteId);

----------------------------------------------------------------------------------------
print ' '
print 'Cont: Update changes'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL1 = 'set nocount off'
    +' update dbo.DEMOGRAPHICS_Survey'
    +' Set [SurveyID] = Atbl.[SurveyID]'
    +', [SurveyDate] = Atbl.[SurveyDate]'
    +', [AuditDate] = Atbl.[AuditDate]'
    +', [CL_EN_GEN_ID] = cxref1.Client_ID'
    +', [SiteID] = Atbl.[SiteID]'
    +', [ProgramID] = Atbl.[ProgramID]'
    --+', [IA_StaffID] = Atbl.[IA_StaffID]'
    +', [ClientID] = cxref2.Client_ID'
    +', [RespondentID] = Atbl.[RespondentID]'
    +', [CLIENT_PERSONAL_0_VOLUNTARILY_INVOLVED] = Atbl.[CLIENT_PERSONAL_0_VOLUNTARILY_INVOLVED]'
    +', [CLIENT_MARITAL_0_STATUS] = Atbl.[CLIENT_MARITAL_0_STATUS]'
    +', [CLIENT_BIO_DAD_0_CONTACT_WITH] = Atbl.[CLIENT_BIO_DAD_0_CONTACT_WITH]'
    +', [CLIENT_LIVING_0_WITH] = Atbl.[CLIENT_LIVING_0_WITH]'
    +', [CLIENT_LIVING_1_WITH_OTHERS] = Atbl.[CLIENT_LIVING_1_WITH_OTHERS]'
    +', [CLIENT_EDUCATION_0_HS_GED] = Atbl.[CLIENT_EDUCATION_0_HS_GED]'
    +', [CLIENT_EDUCATION_1_HS_GED_LAST_GRADE] = Atbl.[CLIENT_EDUCATION_1_HS_GED_LAST_GRADE]'
    +', [CLIENT_EDUCATION_1_HIGHER_EDUC_COMP] = Atbl.[CLIENT_EDUCATION_1_HIGHER_EDUC_COMP]'
    +', [CLIENT_EDUCATION_1_ENROLLED_CURRENT] = Atbl.[CLIENT_EDUCATION_1_ENROLLED_CURRENT]'
    +', [CLIENT_EDUCATION_1_ENROLLED_TYPE] = Atbl.[CLIENT_EDUCATION_1_ENROLLED_TYPE]'
    +', [CLIENT_EDUCATION_1_ENROLLED_PLAN] = Atbl.[CLIENT_EDUCATION_1_ENROLLED_PLAN]'
    +', [CLIENT_WORKING_0_CURRENTLY_WORKING] = Atbl.[CLIENT_WORKING_0_CURRENTLY_WORKING]'
    +', [CLIENT_INCOME_0_HH_INCOME] = Atbl.[CLIENT_INCOME_0_HH_INCOME]'
    +', [CLIENT_INCOME_1_LOW_INCOME_QUALIFY] = Atbl.[CLIENT_INCOME_1_LOW_INCOME_QUALIFY]'
    +', [CLIENT_0_ID_NSO] = Atbl.[CLIENT_0_ID_NSO]'
    +', [CLIENT_PERSONAL_0_NAME_FIRST] = Atbl.[CLIENT_PERSONAL_0_NAME_FIRST]'
    +', [CLIENT_PERSONAL_0_NAME_LAST] = Atbl.[CLIENT_PERSONAL_0_NAME_LAST]'
    +', [NURSE_PERSONAL_0_NAME] = exref1.Entity_ID'
    +', [CLIENT_PERSONAL_0_DOB_INTAKE] = Atbl.[CLIENT_PERSONAL_0_DOB_INTAKE]'
    +', [CLIENT_PERSONAL_0_ETHNICITY_INTAKE] = Atbl.[CLIENT_PERSONAL_0_ETHNICITY_INTAKE]'
    +', [CLIENT_PERSONAL_0_RACE] = Atbl.[CLIENT_PERSONAL_0_RACE]'
    +', [CLIENT_PERSONAL_LANGUAGE_0_INTAKE] = Atbl.[CLIENT_PERSONAL_LANGUAGE_0_INTAKE]'
    +', [CLIENT_0_ID_AGENCY] = Atbl.[CLIENT_0_ID_AGENCY]'
    +', [CLIENT_WORKING_1_WORKED_SINCE_BIRTH] = Atbl.[CLIENT_WORKING_1_WORKED_SINCE_BIRTH]'
    +', [CLIENT_WORKING_1_WORKED_SINCE_BIRTH_MONTHS] = Atbl.[CLIENT_WORKING_1_WORKED_SINCE_BIRTH_MONTHS]'
    +', [CLIENT_BC_0_USED_6MONTHS] = Atbl.[CLIENT_BC_0_USED_6MONTHS]'
    +', [CLIENT_BC_1_NOT_USED_REASON] = Atbl.[CLIENT_BC_1_NOT_USED_REASON]'
    +', [CLIENT_BC_1_FREQUENCY] = Atbl.[CLIENT_BC_1_FREQUENCY]'
    +', [CLIENT_BC_1_TYPES] = Atbl.[CLIENT_BC_1_TYPES]'

set @SQL2 = ', [CLIENT_SUBPREG_0_BEEN_PREGNANT] = Atbl.[CLIENT_SUBPREG_0_BEEN_PREGNANT]'
    +', [CLIENT_SUBPREG_1_BEGIN_MONTH] = Atbl.[CLIENT_SUBPREG_1_BEGIN_MONTH]'
    +', [CLIENT_SUBPREG_1_BEGIN_YEAR] = Atbl.[CLIENT_SUBPREG_1_BEGIN_YEAR]'
    +', [CLIENT_SUBPREG_1_PLANNED] = Atbl.[CLIENT_SUBPREG_1_PLANNED]'
    +', [CLIENT_SUBPREG_1_OUTCOME] = Atbl.[CLIENT_SUBPREG_1_OUTCOME]'
    +', [CLIENT_SECOND_0_CHILD_DOB] = Atbl.[CLIENT_SECOND_0_CHILD_DOB]'
    +', [CLIENT_SECOND_1_CHILD_GENDER] = Atbl.[CLIENT_SECOND_1_CHILD_GENDER]'
    +', [CLIENT_SECOND_1_CHILD_BW_POUNDS] = Atbl.[CLIENT_SECOND_1_CHILD_BW_POUNDS]'
    +', [CLIENT_SECOND_1_CHILD_BW_OZ] = Atbl.[CLIENT_SECOND_1_CHILD_BW_OZ]'
    +', [CLIENT_SECOND_1_CHILD_NICU] = Atbl.[CLIENT_SECOND_1_CHILD_NICU]'
    +', [CLIENT_SECOND_1_CHILD_NICU_DAYS] = Atbl.[CLIENT_SECOND_1_CHILD_NICU_DAYS]'
    +', [CLIENT_BIO_DAD_1_TIME_WITH] = Atbl.[CLIENT_BIO_DAD_1_TIME_WITH]'
    +', [ADULTS_1_ENROLL_NO] = Atbl.[ADULTS_1_ENROLL_NO]'
    +', [ADULTS_1_ENROLL_PT] = Atbl.[ADULTS_1_ENROLL_PT]'
    +', [ADULTS_1_CARE_10] = Atbl.[ADULTS_1_CARE_10]'
    +', [ADULTS_1_CARE_20] = Atbl.[ADULTS_1_CARE_20]'
    +', [ADULTS_1_CARE_30] = Atbl.[ADULTS_1_CARE_30]'
    +', [ADULTS_1_CARE_40] = Atbl.[ADULTS_1_CARE_40]'
    +', [ADULTS_1_CARE_LESS10] = Atbl.[ADULTS_1_CARE_LESS10]'
    +', [ADULTS_1_COMPLETE_GED] = Atbl.[ADULTS_1_COMPLETE_GED]'
    +', [ADULTS_1_COMPLETE_HS] = Atbl.[ADULTS_1_COMPLETE_HS]'
    +', [ADULTS_1_COMPLETE_HS_NO] = Atbl.[ADULTS_1_COMPLETE_HS_NO]'
    +', [ADULTS_1_ED_TECH] = Atbl.[ADULTS_1_ED_TECH]'
    +', [ADULTS_1_ED_ASSOCIATE] = Atbl.[ADULTS_1_ED_ASSOCIATE]'
    +', [ADULTS_1_ED_BACHELOR] = Atbl.[ADULTS_1_ED_BACHELOR]'
    +', [ADULTS_1_ED_MASTER] = Atbl.[ADULTS_1_ED_MASTER]'
    +', [ADULTS_1_ED_NONE] = Atbl.[ADULTS_1_ED_NONE]'
    +', [ADULTS_1_ED_POSTGRAD] = Atbl.[ADULTS_1_ED_POSTGRAD]'
    +', [ADULTS_1_ED_SOME_COLLEGE] = Atbl.[ADULTS_1_ED_SOME_COLLEGE]'
    +', [ADULTS_1_ED_UNKNOWN] = Atbl.[ADULTS_1_ED_UNKNOWN]'
    +', [ADULTS_1_ENROLL_FT] = Atbl.[ADULTS_1_ENROLL_FT]'
    +', [ADULTS_1_INS_NO] = Atbl.[ADULTS_1_INS_NO]'
    +', [ADULTS_1_INS_PRIVATE] = Atbl.[ADULTS_1_INS_PRIVATE]'
    +', [ADULTS_1_INS_PUBLIC] = Atbl.[ADULTS_1_INS_PUBLIC]'
    +', [ADULTS_1_WORK_10] = Atbl.[ADULTS_1_WORK_10]'
    +', [ADULTS_1_WORK_20] = Atbl.[ADULTS_1_WORK_20]'
    +', [ADULTS_1_WORK_37] = Atbl.[ADULTS_1_WORK_37]'
    +', [ADULTS_1_WORK_LESS10] = Atbl.[ADULTS_1_WORK_LESS10]'
    +', [ADULTS_1_WORK_UNEMPLOY] = Atbl.[ADULTS_1_WORK_UNEMPLOY]'
    +', [CLIENT_CARE_0_ER_HOSP] = Atbl.[CLIENT_CARE_0_ER_HOSP]'
    +', [CLIENT_EDUCATION_1_ENROLLED_FTPT] = Atbl.[CLIENT_EDUCATION_1_ENROLLED_FTPT]'
    +', [CLIENT_INCOME_1_HH_SOURCES] = Atbl.[CLIENT_INCOME_1_HH_SOURCES]'
    +', [CLIENT_WORKING_1_CURRENTLY_WORKING_HRS] = Atbl.[CLIENT_WORKING_1_CURRENTLY_WORKING_HRS]'
    +', [CLIENT_EDUCATION_1_ENROLLED_PT_HRS] = Atbl.[CLIENT_EDUCATION_1_ENROLLED_PT_HRS]'
    +', [CLIENT_SCHOOL_MIDDLE_HS] = Atbl.[CLIENT_SCHOOL_MIDDLE_HS]'
    +', [CLIENT_ED_PROG_TYPE] = Atbl.[CLIENT_ED_PROG_TYPE]'
    +', [CLIENT_PROVIDE_CHILDCARE] = Atbl.[CLIENT_PROVIDE_CHILDCARE]'
    +', [CLIENT_WORKING_2_CURRENTLY_WORKING_NO] = Atbl.[CLIENT_WORKING_2_CURRENTLY_WORKING_NO]'
    +', [CLIENT_CARE_0_ER] = Atbl.[CLIENT_CARE_0_ER]'
    +', [CLIENT_CARE_0_URGENT] = Atbl.[CLIENT_CARE_0_URGENT]'
    +', [CLIENT_CARE_0_ER_TIMES] = Atbl.[CLIENT_CARE_0_ER_TIMES]'
    +', [CLIENT_CARE_0_URGENT_TIMES] = Atbl.[CLIENT_CARE_0_URGENT_TIMES]'
    +', [CLIENT_INCOME_IN_KIND] = Atbl.[CLIENT_INCOME_IN_KIND]'
    +', [CLIENT_INCOME_SOURCES] = Atbl.[CLIENT_INCOME_SOURCES]'
    +', [CLIENT_MILITARY] = Atbl.[CLIENT_MILITARY]'
    +', [DELETE ME] = Atbl.[DELETE ME]'
    +', [CLIENT_INCOME_AMOUNT] = Atbl.[CLIENT_INCOME_AMOUNT]'
    +', [CLIENT_WORKING_1_CURRENTLY_WORKING_NO] = Atbl.[CLIENT_WORKING_1_CURRENTLY_WORKING_NO]'
    +', [CLIENT_INCOME_INKIND_OTHER] = Atbl.[CLIENT_INCOME_INKIND_OTHER]'
    +', [CLIENT_INCOME_OTHER_SOURCES] = Atbl.[CLIENT_INCOME_OTHER_SOURCES]'
    +', [CLIENT_BC_1_TYPES_NEXT6] = Atbl.[CLIENT_BC_1_TYPES_NEXT6]'
    +', [CLIENT_SUBPREG_1_EDD] = Atbl.[CLIENT_SUBPREG_1_EDD]'
set @SQL3 = '
     , [CLIENT_SUBPREG_1_GEST_AGE] = Atbl.[CLIENT_SUBPREG_1_GEST_AGE]'
    +', [CLIENT_CARE_0_ER_FEVER_TIMES] = Atbl.[CLIENT_CARE_0_ER_FEVER_TIMES]'
    +', [CLIENT_CARE_0_ER_INFECTION_TIMES] = Atbl.[CLIENT_CARE_0_ER_INFECTION_TIMES]'
    +', [CLIENT_CARE_0_ER_INGESTION_TIMES] = Atbl.[CLIENT_CARE_0_ER_INGESTION_TIMES]'
    +', [CLIENT_CARE_0_ER_INJURY_TIMES] = Atbl.[CLIENT_CARE_0_ER_INJURY_TIMES]'
    +', [CLIENT_CARE_0_ER_OTHER] = Atbl.[CLIENT_CARE_0_ER_OTHER]'
    +', [CLIENT_CARE_0_ER_OTHER_TIMES] = Atbl.[CLIENT_CARE_0_ER_OTHER_TIMES]'
    +', [CLIENT_CARE_0_ER_PURPOSE] = Atbl.[CLIENT_CARE_0_ER_PURPOSE]'
    +', [CLIENT_CARE_0_URGENT_FEVER_TIMES] = Atbl.[CLIENT_CARE_0_URGENT_FEVER_TIMES]'
    +', [CLIENT_CARE_0_URGENT_INFECTION_TIMES] = Atbl.[CLIENT_CARE_0_URGENT_INFECTION_TIMES]'
    +', [CLIENT_CARE_0_URGENT_INGESTION_TIMES] = Atbl.[CLIENT_CARE_0_URGENT_INGESTION_TIMES]'
    +', [CLIENT_CARE_0_URGENT_INJURY_TIMES] = Atbl.[CLIENT_CARE_0_URGENT_INJURY_TIMES]'
    +', [CLIENT_CARE_0_URGENT_OTHER] = Atbl.[CLIENT_CARE_0_URGENT_OTHER]'
    +', [CLIENT_CARE_0_URGENT_OTHER_TIMES] = Atbl.[CLIENT_CARE_0_URGENT_OTHER_TIMES]'
    +', [CLIENT_CARE_0_URGENT_PURPOSE] = Atbl.[CLIENT_CARE_0_URGENT_PURPOSE]'
    +', [CLIENT_SECOND_1_CHILD_BW_CONVERT_GRAMS] = Atbl.[CLIENT_SECOND_1_CHILD_BW_CONVERT_GRAMS]'
    +', [CLIENT_SECOND_1_CHILD_BW_GRAMS] = Atbl.[CLIENT_SECOND_1_CHILD_BW_GRAMS]'
    +', [CLIENT_SECOND_1_CHILD_BW_MEASURE] = Atbl.[CLIENT_SECOND_1_CHILD_BW_MEASURE]'
    +' ,[CLIENT_CARE_0_URGENT_PURPOSE_R6] = atbl.[CLIENT_CARE_0_URGENT_PURPOSE_R6]'
    +' ,[CLIENT_CARE_0_ER_PURPOSE_R6] = atbl.[CLIENT_CARE_0_ER_PURPOSE_R6]'
    +' ,[CLIENT_SUBPREG] = atbl.[CLIENT_SUBPREG]'
    +' ,[CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES] = atbl.[CLIENT_CARE_0_ER_INJURY_ACCIDENT_TIMES]'
    +' ,[CLIENT_CARE_0_ER_INJURY_SELF_TIMES] = atbl.[CLIENT_CARE_0_ER_INJURY_SELF_TIMES]'
    +' ,[CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES] = atbl.[CLIENT_CARE_0_ER_INJURY_INTENT_OTHER_TIMES]'
    +' ,[CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES] = atbl.[CLIENT_CARE_0_ER_INJURY_DECLINE_TIMES]'
    +' ,[CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES] = atbl.[CLIENT_CARE_0_ER_INGESTION_ACCIDENT_TIMES]'
    +' ,[CLIENT_CARE_0_ER_INGESTION_SELF_TIMES] = atbl.[CLIENT_CARE_0_ER_INGESTION_SELF_TIMES]'
    +' ,[CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES] = atbl.[CLIENT_CARE_0_ER_INGESTION_INTENT_OTHER_TIMES]'
    +' ,[CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES] = atbl.[CLIENT_CARE_0_ER_INGESTION_DECLINE_TIMES]'
    +' ,[CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES] = atbl.[CLIENT_CARE_0_URGENT_INJURY_ACCIDENT_TIMES]'
    +' ,[CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES] = atbl.[CLIENT_CARE_0_URGENT_INJURY_SELF_TIMES]'
    +' ,[CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES] = atbl.[CLIENT_CARE_0_URGENT_INJURY_INTENT_OTHER_TIMES]'
    +' ,[CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES] = atbl.[CLIENT_CARE_0_URGENT_INJURY_DECLINE_TIMES]'
    +' ,[CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES] = atbl.[CLIENT_CARE_0_URGENT_INGESTION_ACCIDENT_TIMES]'
    +' ,[CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES] = atbl.[CLIENT_CARE_0_URGENT_INGESTION_SELF_TIMES]'
    +' ,[CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES] = atbl.[CLIENT_CARE_0_URGENT_INGESTION_INTENT_OTHER_TIMES]'
    +' ,[CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES] = atbl.[CLIENT_CARE_0_URGENT_INGESTION_DECLINE_TIMES]'
-- October 2016 ETO Release:
    +', [CLIENT_INSURANCE_TYPE] = atbl.[CLIENT_INSURANCE_TYPE]'
    +', [CLIENT_INSURANCE] = atbl.[CLIENT_INSURANCE]'
    +', [CLIENT_LIVING_HOMELESS] = atbl.[CLIENT_LIVING_HOMELESS]'
    +', [CLIENT_LIVING_WHERE] = atbl.[CLIENT_LIVING_WHERE]'
    +', [CLIENT_INSURANCE_OTHER] = atbl.[CLIENT_INSURANCE_OTHER]'
-- Integration set columns:
    +', [Master_SurveyID] = ms.SourceSurveyID'
    +', [DW_AuditDate] = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
set @SQL4 = '
     from dbo.DEMOGRAPHICS_Survey dwsurvey'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.DEMOGRAPHICS_Survey Atbl'
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
    print @SQL4
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL1+@SQL2+@SQL3+@SQL4)



----------------------------------------------------------------------------------------
print ' '
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
print ' '
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

print 'End of Process: SP_AGENCYDB_DEMOGRAPHICS_SURVEY'
GO
