USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_INFANT_BIRTH_SURVEY]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_INFANT_BIRTH_SURVEY
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_INFANT_BIRTH_SURVEY]
 (@p_datasource      nvarchar(10) = null
 ,@p_no_delete_opt   nvarchar(2)  = null
 ,@p_no_exec_flag    nvarchar(10) = 'N')
AS
--
-- This script controls integration of AgencyDB Surveys to the Data Warehouse 
-- INFANT_BIRTH_Survey table.
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
--   20150811 - Added new columns to integraion.
--   20160706 - Added additional conditional logic to match siteid when looking up xrefs to entities and clients,
--              to accommodate multiple sites within the same AgencyDB, using same numbering scheme between sites.
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

set @process = 'SP_AGENCYDB_INFANT_BIRTH_SURVEY'
set @DW_Tablename = 'INFANT_BIRTH_SURVEY'
set @Agency_Tablename = 'INFANTS'
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)
DECLARE @SQL1            varchar(MAX)
DECLARE @SQL2            varchar(MAX)
DECLARE @SQL3            varchar(MAX)

print 'Processing SP_AGENCYDB_INFANT_BIRTH_SURVEY: Datasource = ' +isnull(@p_datasource,'NULL')
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
    +' insert into dbo.INFANT_BIRTH_Survey'
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
    +', [INFANT_PERSONAL_0_FIRST NAME]'
    +', [INFANT_BIRTH_0_DOB]'
    +', [CLIENT_0_ID_NSO]'
    +', [CLIENT_PERSONAL_0_NAME_FIRST]'
    +', [CLIENT_PERSONAL_0_NAME_LAST]'
    +', [NURSE_PERSONAL_0_NAME]'
    +', [INFANT_BIRTH_1_MULTIPLE_BIRTHS]'
    +', [INFANT_PERSONAL_0_ETHNICITY]'
    +', [INFANT_PERSONAL_0_RACE]'
    +', [INFANT_PERSONAL_0_GENDER]'
    +', [INFANT_BIRTH_1_WEIGHT_GRAMS]'
    +', [INFANT_BIRTH_1_WEIGHT_POUNDS]'
    +', [INFANT_BIRTH_1_GEST_AGE]'
    +', [INFANT_BIRTH_1_NICU]'
    +', [INFANT_BIRTH_1_NICU_DAYS]'
    +', [CLIENT_WEIGHT_0_PREG_GAIN]'
    +', [INFANT_BREASTMILK_0_EVER_BIRTH]'
    +', [INFANT_0_ID_NSO2]'
    +', [INFANT_PERSONAL_0_LAST NAME]'
    +', [INFANT_BIRTH_0_CLIENT_ER]'
    +', [INFANT_BIRTH_0_CLIENT_URGENT CARE]'
    +', [INFANT_BIRTH_1_NICU_R2]'
    +', [INFANT_BIRTH_1_NURSERY_R2]'
    +', [INFANT_BIRTH_0_CLIENT_ER_TIMES]'
    +', [INFANT_BIRTH_0_CLIENT_URGENT CARE_TIMES]'
    +', [INFANT_BIRTH_1_NICU_DAYS_R2]'
    +', [INFANT_BIRTH_1_NURSERY_DAYS_R2]'
    +', [INFANT_BIRTH_1_WEIGHT_OUNCES]'
    +', [INFANT_BIRTH_1_WEIGHT_MEASURE]'
    +', [INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS]'
    +', [INFANT_BIRTH_1_LABOR]'
    +', [INFANT_BIRTH_1_DELIVERY]'
    +', [INFANT_BIRTH_1_NEWBORN_SCREEN]'
    +', [INFANT_BIRTH_1_HEARING_SCREEN]'
    +', [INFANT_BIRTH_1_NICU_NURSERY_PURPOSE]'
    +', [INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER]'
    +', [CLIENT_0_ID_AGENCY]'
    +', [INFANT_BIRTH_1_NEWBORN_SCREEN2]'
    +', [INFANT_BIRTH_1_NEWBORN_SCREEN3]'
-- ETO Release October 2016:
    +' ,[INFANT_INSURANCE_TYPE]'
    +' ,[INFANT_INSURANCE_TYPE2]'
    +' ,[INFANT_INSURANCE_TYPE3]'
    +' ,[INFANT_BIRTH_COSLEEP]'
    +' ,[INFANT_BIRTH_COSLEEP2]'
    +' ,[INFANT_BIRTH_COSLEEP3]'
    +' ,[INFANT_BIRTH_READ]'
    +' ,[INFANT_BIRTH_READ2]'
    +' ,[INFANT_BIRTH_READ3]'
    +' ,[INFANT_BIRTH_SLEEP_BACK]'
    +' ,[INFANT_BIRTH_SLEEP_BACK2]'
    +' ,[INFANT_BIRTH_SLEEP_BACK3]'
    +' ,[INFANT_BIRTH_SLEEP_BEDDING]'
    +' ,[INFANT_BIRTH_SLEEP_BEDDING2]'
    +' ,[INFANT_BIRTH_SLEEP_BEDDING3]'
    +' ,[INFANT_INSURANCE]'
    +' ,[INFANT_INSURANCE2]'
    +' ,[INFANT_INSURANCE3]'
    +' ,[INFANT_INSURANCE_OTHER]'
    +' ,[INFANT_INSURANCE_OTHER2]'
    +' ,[INFANT_INSURANCE_OTHER3]'
-- Integration set items:
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
    +', Atbl.[INFANT_PERSONAL_0_FIRST NAME]'
    +', Atbl.[INFANT_BIRTH_0_DOB]'
    +', Atbl.[CLIENT_0_ID_NSO]'
    +', Atbl.[CLIENT_PERSONAL_0_NAME_FIRST]'
    +', Atbl.[CLIENT_PERSONAL_0_NAME_LAST]'
    +' ,exref1.Entity_ID'
    +', Atbl.[INFANT_BIRTH_1_MULTIPLE_BIRTHS]'
    +', Atbl.[INFANT_PERSONAL_0_ETHNICITY]'
    +', Atbl.[INFANT_PERSONAL_0_RACE]'
    +', Atbl.[INFANT_PERSONAL_0_GENDER]'
    +', Atbl.[INFANT_BIRTH_1_WEIGHT_GRAMS]'
    +', Atbl.[INFANT_BIRTH_1_WEIGHT_POUNDS]'
    +', Atbl.[INFANT_BIRTH_1_GEST_AGE]'
    +', Atbl.[INFANT_BIRTH_1_NICU]'
    +', Atbl.[INFANT_BIRTH_1_NICU_DAYS]'
    +', Atbl.[CLIENT_WEIGHT_0_PREG_GAIN]'
    +', Atbl.[INFANT_BREASTMILK_0_EVER_BIRTH]'
    +', Atbl.[INFANT_0_ID_NSO2]'
    +', Atbl.[INFANT_PERSONAL_0_LAST NAME]'
    +', Atbl.[INFANT_BIRTH_0_CLIENT_ER]'
    +', Atbl.[INFANT_BIRTH_0_CLIENT_URGENT CARE]'
    +', Atbl.[INFANT_BIRTH_1_NICU_R2]'
    +', Atbl.[INFANT_BIRTH_1_NURSERY_R2]'
    +', Atbl.[INFANT_BIRTH_0_CLIENT_ER_TIMES]'
    +', Atbl.[INFANT_BIRTH_0_CLIENT_URGENT CARE_TIMES]'
    +', Atbl.[INFANT_BIRTH_1_NICU_DAYS_R2]'
    +', Atbl.[INFANT_BIRTH_1_NURSERY_DAYS_R2]'
    +', Atbl.[INFANT_BIRTH_1_WEIGHT_OUNCES]'
    +', Atbl.[INFANT_BIRTH_1_WEIGHT_MEASURE]'
    +', Atbl.[INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS]'
    +', Atbl.[INFANT_BIRTH_1_LABOR]'
    +', Atbl.[INFANT_BIRTH_1_DELIVERY]'
    +', Atbl.[INFANT_BIRTH_1_NEWBORN_SCREEN]'
    +', Atbl.[INFANT_BIRTH_1_HEARING_SCREEN]'
    +', Atbl.[INFANT_BIRTH_1_NICU_NURSERY_PURPOSE]'
    +', Atbl.[INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER]'
    +', Atbl.[CLIENT_0_ID_AGENCY]'
    +', Atbl.[INFANT_BIRTH_1_NEWBORN_SCREEN2]'
    +', Atbl.[INFANT_BIRTH_1_NEWBORN_SCREEN3]'
-- ETO Release October 2016:
    +' ,Atbl.[INFANT_INSURANCE_TYPE]'
    +' ,Atbl.[INFANT_INSURANCE_TYPE2]'
    +' ,Atbl.[INFANT_INSURANCE_TYPE3]'
    +' ,Atbl.[INFANT_BIRTH_COSLEEP]'
    +' ,Atbl.[INFANT_BIRTH_COSLEEP2]'
    +' ,Atbl.[INFANT_BIRTH_COSLEEP3]'
    +' ,Atbl.[INFANT_BIRTH_READ]'
    +' ,Atbl.[INFANT_BIRTH_READ2]'
    +' ,Atbl.[INFANT_BIRTH_READ3]'
    +' ,Atbl.[INFANT_BIRTH_SLEEP_BACK]'
    +' ,Atbl.[INFANT_BIRTH_SLEEP_BACK2]'
    +' ,Atbl.[INFANT_BIRTH_SLEEP_BACK3]'
    +' ,Atbl.[INFANT_BIRTH_SLEEP_BEDDING]'
    +' ,Atbl.[INFANT_BIRTH_SLEEP_BEDDING2]'
    +' ,Atbl.[INFANT_BIRTH_SLEEP_BEDDING3]'
    +' ,Atbl.[INFANT_INSURANCE]'
    +' ,Atbl.[INFANT_INSURANCE2]'
    +' ,Atbl.[INFANT_INSURANCE3]'
    +' ,Atbl.[INFANT_INSURANCE_OTHER]'
    +' ,Atbl.[INFANT_INSURANCE_OTHER2]'
    +' ,Atbl.[INFANT_INSURANCE_OTHER3]'
-- Integration set items:
    +', ms.SourceSurveyID'
    +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
set @SQL3 = '
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Infants Atbl'
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
    +' from dbo.INFANT_BIRTH_Survey dwsurvey'
    +' where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and dwsurvey.SurveyResponseID = Atbl.DW_SurveyResponseID)'
     

    print @SQL1
    print @SQL2
    print @SQL3
    --print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
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
    +' update dbo.INFANT_BIRTH_Survey'
    +' Set [ElementsProcessed] = 1'    +', [SurveyID] = Atbl.[SurveyID]'
    +', [SurveyDate] = Atbl.[SurveyDate]'
    +', [AuditDate] = Atbl.[AuditDate]'
    +', [CL_EN_GEN_ID] = cxref1.Client_ID'
    +', [SiteID] = Atbl.[SiteID]'
    +', [ProgramID] = Atbl.[ProgramID]'
    --+', [IA_StaffID] = Atbl.[IA_StaffID]'
    +', [ClientID] = cxref2.Client_ID'
    +', [RespondentID] = Atbl.[RespondentID]'
    +', [INFANT_0_ID_NSO] = Atbl.[INFANT_0_ID_NSO]'
    +', [INFANT_PERSONAL_0_FIRST NAME] = Atbl.[INFANT_PERSONAL_0_FIRST NAME]'
    +', [INFANT_BIRTH_0_DOB] = Atbl.[INFANT_BIRTH_0_DOB]'
    +', [CLIENT_0_ID_NSO] = Atbl.[CLIENT_0_ID_NSO]'
    +', [CLIENT_PERSONAL_0_NAME_FIRST] = Atbl.[CLIENT_PERSONAL_0_NAME_FIRST]'
    +', [CLIENT_PERSONAL_0_NAME_LAST] = Atbl.[CLIENT_PERSONAL_0_NAME_LAST]'
    +', [NURSE_PERSONAL_0_NAME] = exref1.Entity_ID'
    +', [INFANT_BIRTH_1_MULTIPLE_BIRTHS] = Atbl.[INFANT_BIRTH_1_MULTIPLE_BIRTHS]'
    +', [INFANT_PERSONAL_0_ETHNICITY] = Atbl.[INFANT_PERSONAL_0_ETHNICITY]'
    +', [INFANT_PERSONAL_0_RACE] = Atbl.[INFANT_PERSONAL_0_RACE]'
    +', [INFANT_PERSONAL_0_GENDER] = Atbl.[INFANT_PERSONAL_0_GENDER]'
    +', [INFANT_BIRTH_1_WEIGHT_GRAMS] = Atbl.[INFANT_BIRTH_1_WEIGHT_GRAMS]'
    +', [INFANT_BIRTH_1_WEIGHT_POUNDS] = Atbl.[INFANT_BIRTH_1_WEIGHT_POUNDS]'
    +', [INFANT_BIRTH_1_GEST_AGE] = Atbl.[INFANT_BIRTH_1_GEST_AGE]'
    +', [INFANT_BIRTH_1_NICU] = Atbl.[INFANT_BIRTH_1_NICU]'
    +', [INFANT_BIRTH_1_NICU_DAYS] = Atbl.[INFANT_BIRTH_1_NICU_DAYS]'
    +', [CLIENT_WEIGHT_0_PREG_GAIN] = Atbl.[CLIENT_WEIGHT_0_PREG_GAIN]'
    +', [INFANT_BREASTMILK_0_EVER_BIRTH] = Atbl.[INFANT_BREASTMILK_0_EVER_BIRTH]'
    +', [INFANT_0_ID_NSO2] = Atbl.[INFANT_0_ID_NSO2]'
    +', [INFANT_PERSONAL_0_LAST NAME] = Atbl.[INFANT_PERSONAL_0_LAST NAME]'
    +', [INFANT_BIRTH_0_CLIENT_ER] = Atbl.[INFANT_BIRTH_0_CLIENT_ER]'
    +', [INFANT_BIRTH_0_CLIENT_URGENT CARE] = Atbl.[INFANT_BIRTH_0_CLIENT_URGENT CARE]'
    +', [INFANT_BIRTH_1_NICU_R2] = Atbl.[INFANT_BIRTH_1_NICU_R2]'
    +', [INFANT_BIRTH_1_NURSERY_R2] = Atbl.[INFANT_BIRTH_1_NURSERY_R2]'
    +', [INFANT_BIRTH_0_CLIENT_ER_TIMES] = Atbl.[INFANT_BIRTH_0_CLIENT_ER_TIMES]'
    +', [INFANT_BIRTH_0_CLIENT_URGENT CARE_TIMES] = Atbl.[INFANT_BIRTH_0_CLIENT_URGENT CARE_TIMES]'
    +', [INFANT_BIRTH_1_NICU_DAYS_R2] = Atbl.[INFANT_BIRTH_1_NICU_DAYS_R2]'
    +', [INFANT_BIRTH_1_NURSERY_DAYS_R2] = Atbl.[INFANT_BIRTH_1_NURSERY_DAYS_R2]'
    +', [INFANT_BIRTH_1_WEIGHT_OUNCES] = Atbl.[INFANT_BIRTH_1_WEIGHT_OUNCES]'
    +', [INFANT_BIRTH_1_WEIGHT_MEASURE] = Atbl.[INFANT_BIRTH_1_WEIGHT_MEASURE]'
    +', [INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS] = Atbl.[INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS]'
    +', [CLIENT_0_ID_AGENCY] = Atbl.[CLIENT_0_ID_AGENCY]'
    +', [INFANT_BIRTH_1_LABOR] = Atbl.[INFANT_BIRTH_1_LABOR]'
    +', [INFANT_BIRTH_1_DELIVERY] = Atbl.[INFANT_BIRTH_1_DELIVERY]'
    +', [INFANT_BIRTH_1_NEWBORN_SCREEN] = Atbl.[INFANT_BIRTH_1_NEWBORN_SCREEN]'
    +', [INFANT_BIRTH_1_HEARING_SCREEN] = Atbl.[INFANT_BIRTH_1_HEARING_SCREEN]'
    +', [INFANT_BIRTH_1_NICU_NURSERY_PURPOSE] = Atbl.[INFANT_BIRTH_1_NICU_NURSERY_PURPOSE]'
    +', [INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER] = Atbl.[INFANT_BIRTH_1_NICU_NURSERY_PURPOSE_OTHER]'
    +', [INFANT_BIRTH_1_NEWBORN_SCREEN2] = Atbl.[INFANT_BIRTH_1_NEWBORN_SCREEN2]'
    +', [INFANT_BIRTH_1_NEWBORN_SCREEN3] = Atbl.[INFANT_BIRTH_1_NEWBORN_SCREEN3]'
set @SQL2 = '
-- ETO Release October 2016:
     ,[INFANT_INSURANCE_TYPE] = Atbl.[INFANT_INSURANCE_TYPE]'
    +' ,[INFANT_INSURANCE_TYPE2] = Atbl.[INFANT_INSURANCE_TYPE2]'
    +' ,[INFANT_INSURANCE_TYPE3] = Atbl.[INFANT_INSURANCE_TYPE3]'
    +' ,[INFANT_BIRTH_COSLEEP] = Atbl.[INFANT_BIRTH_COSLEEP]'
    +' ,[INFANT_BIRTH_COSLEEP2] = Atbl.[INFANT_BIRTH_COSLEEP2]'
    +' ,[INFANT_BIRTH_COSLEEP3] = Atbl.[INFANT_BIRTH_COSLEEP3]'
    +' ,[INFANT_BIRTH_READ] = Atbl.[INFANT_BIRTH_READ]'
    +' ,[INFANT_BIRTH_READ2] = Atbl.[INFANT_BIRTH_READ2]'
    +' ,[INFANT_BIRTH_READ3] = Atbl.[INFANT_BIRTH_READ3]'
    +' ,[INFANT_BIRTH_SLEEP_BACK] = Atbl.[INFANT_BIRTH_SLEEP_BACK]'
    +' ,[INFANT_BIRTH_SLEEP_BACK2] = Atbl.[INFANT_BIRTH_SLEEP_BACK2]'
    +' ,[INFANT_BIRTH_SLEEP_BACK3] = Atbl.[INFANT_BIRTH_SLEEP_BACK3]'
    +' ,[INFANT_BIRTH_SLEEP_BEDDING] = Atbl.[INFANT_BIRTH_SLEEP_BEDDING]'
    +' ,[INFANT_BIRTH_SLEEP_BEDDING2] = Atbl.[INFANT_BIRTH_SLEEP_BEDDING2]'
    +' ,[INFANT_BIRTH_SLEEP_BEDDING3] = Atbl.[INFANT_BIRTH_SLEEP_BEDDING3]'
    +' ,[INFANT_INSURANCE] = Atbl.[INFANT_INSURANCE]'
    +' ,[INFANT_INSURANCE2] = Atbl.[INFANT_INSURANCE2]'
    +' ,[INFANT_INSURANCE3] = Atbl.[INFANT_INSURANCE3]'
    +' ,[INFANT_INSURANCE_OTHER] = Atbl.[INFANT_INSURANCE_OTHER]'
    +' ,[INFANT_INSURANCE_OTHER2] = Atbl.[INFANT_INSURANCE_OTHER2]'
    +' ,[INFANT_INSURANCE_OTHER3] = Atbl.[INFANT_INSURANCE_OTHER3]'
-- Integration set items:
    +', [Master_SurveyID] = ms.SourceSurveyID'
    +', [DW_AuditDate] = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'

set @SQL3 = '
     from dbo.INFANT_BIRTH_Survey dwsurvey'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Infants Atbl'
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
    --print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
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

print 'End of Process: SP_AGENCYDB_INFANT_BIRTH_SURVEY'
GO
