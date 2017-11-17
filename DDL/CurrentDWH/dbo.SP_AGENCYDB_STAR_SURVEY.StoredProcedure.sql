USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_STAR_SURVEY]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_STAR_SURVEY
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_STAR_SURVEY]
 (@p_datasource      nvarchar(10) = null
 ,@p_no_delete_opt   nvarchar(2)  = null
 ,@p_no_exec_flag    nvarchar(10) = 'N')
AS
--
-- This script controls integration of AgencyDB Surveys to the Data Warehouse 
-- STAR_Survey table.
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
--   20150620 - New Procedure copied from latest version of dbo.SP_AgencyDB_Relationship_Survey.
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
DECLARE @Agency_TableName   nvarchar(50)
DECLARE @Agency_Full_TableName   nvarchar(100)

set @process          = 'SP_AGENCYDB_STAR_SURVEY'
set @DW_Tablename     = 'STAR_SURVEY'
set @Agency_Tablename = 'STAR_SURVEY'
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)
DECLARE @SQL1            varchar(MAX)
DECLARE @SQL2            varchar(MAX)
DECLARE @SQL3            varchar(MAX)
DECLARE @SQL4            varchar(MAX)

print 'Processing SP_AGENCYDB_STAR_SURVEY: Datasource = ' +isnull(@p_datasource,'NULL')
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
    +' insert into dbo.STAR_Survey'
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
    +' ,[CLIENT_0_ID_NSO]'
    +' ,[CLIENT_PERSONAL_0_NAME_FIRST]'
    +' ,[CLIENT_PERSONAL_0_NAME_LAST]'
    +' ,[CLIENT_PERSONAL_0_DOB_INTAKE]'
    +' ,[NURSE_PERSONAL_0_NAME]'
    +' ,[Master_SurveyID]'
    +' ,[DW_AuditDate]'
    -- survey specific items:
    +' ,[CLIENT_GLOBAL_FACTORS]'
    +' ,[CLIENT_CAREGIVING_FRIENDS_FAM]'
    +' ,[CLIENT_CAREGIVING_RISK_LEVEL]'
    +' ,[CLIENT_CAREGIVING_SERVICES_GOALS]'
    +' ,[CLIENT_CAREGIVING_STAGE_CHANGE]'
    +' ,[CLIENT_CAREGIVING_UNDERSTANDS_RISK]'
    +' ,[CLIENT_CHLD_CARE_FRIENDS_FAM]'
    +' ,[CLIENT_CHLD_CARE_RISK_LEVEL]'
    +' ,[CLIENT_CHLD_CARE_SERVICES_GOALS]'
    +' ,[CLIENT_CHLD_CARE_STAGE_CHANGE]'
    +' ,[CLIENT_CHLD_CARE_UNDERSTANDS_RISK]'
    +' ,[CLIENT_CHLD_HEALTH_FRIENDS_FAM]'
    +' ,[CLIENT_CHLD_HEALTH_RISK_LEVEL]'
    +' ,[CLIENT_CHLD_HEALTH_SERVICES_GOALS]'
    +' ,[CLIENT_CHLD_HEALTH_STAGE_CHANGE]'
    +' ,[CLIENT_CHLD_HEALTH_UNDERSTANDS_RISK]'
    +' ,[CLIENT_CHLD_WELL_FRIENDS_FAM]'
    +' ,[CLIENT_CHLD_WELL_RISK_LEVEL]'
    +' ,[CLIENT_CHLD_WELL_SERVICES_GOALS]'
    +' ,[CLIENT_CHLD_WELL_STAGE_CHANGE]'
    +' ,[CLIENT_CHLD_WELL_UNDERSTANDS_RISK]'
    +' ,[CLIENT_COMM_SVCS_FRIENDS_FAM]'
    +' ,[CLIENT_COMM_SVCS_RISK_LEVEL]'
    +' ,[CLIENT_COMM_SVCS_SERVICES_GOALS]'
    +' ,[CLIENT_COMM_SVCS_STAGE_CHANGE]'
    +' ,[CLIENT_COMM_SVCS_UNDERSTANDS_RISK]'
    +' ,[CLIENT_COMPLICATION_ILL_FRIENDS_FAM]'
    +' ,[CLIENT_COMPLICATION_ILL_RISK_LEVEL]'
    +' ,[CLIENT_COMPLICATION_ILL_SERVICES_GOALS]'
    +' ,[CLIENT_COMPLICATION_ILL_STAGE_CHANGE]'
    +' ,[CLIENT_COMPLICATION_ILL_UNDERSTANDS_RISK]'
    +' ,[CLIENT_CRIMINAL_FRIENDS_FAM]'
    +' ,[CLIENT_CRIMINAL_RISK_LEVEL]'
    +' ,[CLIENT_CRIMINAL_SERVICES_GOALS]'
    +' ,[CLIENT_CRIMINAL_STAGE_CHANGE]'
    +' ,[CLIENT_CRIMINAL_UNDERSTANDS_RISK]'
    +' ,[CLIENT_DISABILITY_FRIENDS_FAM]'
    +' ,[CLIENT_DISABILITY_RISK_LEVEL]'
    +' ,[CLIENT_DISABILITY_SERVICES_GOALS]'
    +' ,[CLIENT_DISABILITY_STAGE_CHANGE]'
    +' ,[CLIENT_DISABILITY_UNDERSTANDS_RISK]'
    +' ,[CLIENT_ECONOMIC_FRIENDS_FAM]'
    +' ,[CLIENT_ECONOMIC_RISK_LEVEL]'
    +' ,[CLIENT_ECONOMIC_SERVICES_GOALS]'
    +' ,[CLIENT_ECONOMIC_STAGE_CHANGE]'
    +' ,[CLIENT_ECONOMIC_UNDERSTANDS_RISK]'
    +' ,[CLIENT_EDUC_FRIENDS_FAM]'
    +' ,[CLIENT_EDUC_RISK_LEVEL]'
    +' ,[CLIENT_EDUC_SERVICES_GOALS]'
    +' ,[CLIENT_EDUC_STAGE_CHANGE]'
    +' ,[CLIENT_EDUC_UNDERSTANDS_RISK]'
    +' ,[CLIENT_ENGLIT_FRIENDS_FAM]'
    +' ,[CLIENT_ENGLIT_RISK_LEVEL]'
    +' ,[CLIENT_ENGLIT_SERVICES_GOALS]'
    +' ,[CLIENT_ENGLIT_STAGE_CHANGE]'
    +' ,[CLIENT_ENGLIT_UNDERSTANDS_RISK]'
    +' ,[CLIENT_ENVIRO_HEALTH_FRIENDS_FAM]'
    +' ,[CLIENT_ENVIRO_HEALTH_RISK_LEVEL]'
    +' ,[CLIENT_ENVIRO_HEALTH_SERVICES_GOALS]'
    +' ,[CLIENT_ENVIRO_HEALTH_STAGE_CHANGE]'
    +' ,[CLIENT_ENVIRO_HEALTH_UNDERSTANDS_RISK]'
    +' ,[CLIENT_HLTH_SVCS_FRIENDS_FAM]'
    +' ,[CLIENT_HLTH_SVCS_RISK_LEVEL]'
    +' ,[CLIENT_HLTH_SVCS_SERVICES_GOALS]'
    +' ,[CLIENT_HLTH_SVCS_STAGE_CHANGE]'
    +' ,[CLIENT_HLTH_SVCS_UNDERSTANDS_RISK]'
    +' ,[CLIENT_HOME_SAFETY_FRIENDS_FAM]'
    +' ,[CLIENT_HOME_SAFETY_RISK_LEVEL]'
    +' ,[CLIENT_HOME_SAFETY_SERVICES_GOALS]'
    +' ,[CLIENT_HOME_SAFETY_STAGE_CHANGE]'
    +' ,[CLIENT_HOME_SAFETY_UNDERSTANDS_RISK]'
    +' ,[CLIENT_HOMELESS_FRIENDS_FAM]'
    +' ,[CLIENT_HOMELESS_RISK_LEVEL]'
    +' ,[CLIENT_HOMELESS_SERVICES_GOALS]'
    +' ,[CLIENT_HOMELESS_STAGE_CHANGE]'
    +' ,[CLIENT_HOMELESS_UNDERSTANDS_RISK]'
    +' ,[CLIENT_IPV_FRIENDS_FAM]'
    +' ,[CLIENT_IPV_RISK_LEVEL]'
    +' ,[CLIENT_IPV_SERVICES_GOALS]'
    +' ,[CLIENT_IPV_STAGE_CHANGE]'
    +' ,[CLIENT_IPV_UNDERSTANDS_RISK]'
    +' ,[CLIENT_LONELY_FRIENDS_FAM]'
    +' ,[CLIENT_LONELY_RISK_LEVEL]'
    +' ,[CLIENT_LONELY_SERVICES_GOALS]'
    +' ,[CLIENT_LONELY_STAGE_CHANGE]'
    +' ,[CLIENT_LONELY_UNDERSTANDS_RISK]'
    +' ,[CLIENT_MENTAL_HEALTH_FRIENDS_FAM]'
    +' ,[CLIENT_MENTAL_HEALTH_RISK_LEVEL]'
    +' ,[CLIENT_MENTAL_HEALTH_SERVICES_GOALS]'
    +' ,[CLIENT_MENTAL_HEALTH_STAGE_CHANGE]'
    +' ,[CLIENT_MENTAL_HEALTH_UNDERSTANDS_RISK]'
    +' ,[CLIENT_PREGPLAN_FRIENDS_FAM]'
    +' ,[CLIENT_PREGPLAN_RISK_LEVEL]'
    +' ,[CLIENT_PREGPLAN_SERVICES_GOALS]'
    +' ,[CLIENT_PREGPLAN_STAGE_CHANGE]'
    +' ,[CLIENT_PREGPLAN_UNDERSTANDS_RISK]'
    +' ,[CLIENT_SUBSTANCE_FRIENDS_FAM]'
    +' ,[CLIENT_SUBSTANCE_RISK_LEVEL]'
    +' ,[CLIENT_SUBSTANCE_SERVICES_GOALS]'
    +' ,[CLIENT_SUBSTANCE_STAGE_CHANGE]'
    +' ,[CLIENT_SUBSTANCE_UNDERSTANDS_RISK]'
    +' ,[CLIENT_UNSAFE_NTWK_FRIENDS_FAM]'
    +' ,[CLIENT_UNSAFE_NTWK_RISK_LEVEL]'
    +' ,[CLIENT_UNSAFE_NTWK_SERVICES_GOALS]'
    +' ,[CLIENT_UNSAFE_NTWK_STAGE_CHANGE]'
    +' ,[CLIENT_UNSAFE_NTWK_UNDERSTANDS_RISK]'
    +' ,[CLIENT_0_ID_AGENCY]'
    +')'

set @SQL2 = 'SELECT  DW_SurveyResponseID as SurveyResponseID, ''' +@p_datasource +''''
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
    +' ,Atbl.[CLIENT_0_ID_NSO]'
    +' ,Atbl.[CLIENT_PERSONAL_0_NAME_FIRST]'
    +' ,Atbl.[CLIENT_PERSONAL_0_NAME_LAST]'
    +' ,Atbl.[CLIENT_PERSONAL_0_DOB_INTAKE]'
    +' ,exref1.Entity_ID'
    +', ms.SourceSurveyID'
    +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    -- survey specific items:
    +' ,Atbl.[CLIENT_GLOBAL_FACTORS]'
    +' ,Atbl.[CLIENT_CAREGIVING_FRIENDS_FAM]'
    +' ,Atbl.[CLIENT_CAREGIVING_RISK_LEVEL]'
    +' ,Atbl.[CLIENT_CAREGIVING_SERVICES_GOALS]'
    +' ,Atbl.[CLIENT_CAREGIVING_STAGE_CHANGE]'
    +' ,Atbl.[CLIENT_CAREGIVING_UNDERSTANDS_RISK]'
    +' ,Atbl.[CLIENT_CHLD_CARE_FRIENDS_FAM]'
    +' ,Atbl.[CLIENT_CHLD_CARE_RISK_LEVEL]'
    +' ,Atbl.[CLIENT_CHLD_CARE_SERVICES_GOALS]'
    +' ,Atbl.[CLIENT_CHLD_CARE_STAGE_CHANGE]'
    +' ,Atbl.[CLIENT_CHLD_CARE_UNDERSTANDS_RISK]'
    +' ,Atbl.[CLIENT_CHLD_HEALTH_FRIENDS_FAM]'
    +' ,Atbl.[CLIENT_CHLD_HEALTH_RISK_LEVEL]'
    +' ,Atbl.[CLIENT_CHLD_HEALTH_SERVICES_GOALS]'
    +' ,Atbl.[CLIENT_CHLD_HEALTH_STAGE_CHANGE]'
    +' ,Atbl.[CLIENT_CHLD_HEALTH_UNDERSTANDS_RISK]'
    +' ,Atbl.[CLIENT_CHLD_WELL_FRIENDS_FAM]'
    +' ,Atbl.[CLIENT_CHLD_WELL_RISK_LEVEL]'
    +' ,Atbl.[CLIENT_CHLD_WELL_SERVICES_GOALS]'
    +' ,Atbl.[CLIENT_CHLD_WELL_STAGE_CHANGE]'
    +' ,Atbl.[CLIENT_CHLD_WELL_UNDERSTANDS_RISK]'
    +' ,Atbl.[CLIENT_COMM_SVCS_FRIENDS_FAM]'
    +' ,Atbl.[CLIENT_COMM_SVCS_RISK_LEVEL]'
    +' ,Atbl.[CLIENT_COMM_SVCS_SERVICES_GOALS]'
    +' ,Atbl.[CLIENT_COMM_SVCS_STAGE_CHANGE]'
    +' ,Atbl.[CLIENT_COMM_SVCS_UNDERSTANDS_RISK]'
    +' ,Atbl.[CLIENT_COMPLICATION_ILL_FRIENDS_FAM]'
    +' ,Atbl.[CLIENT_COMPLICATION_ILL_RISK_LEVEL]'
    +' ,Atbl.[CLIENT_COMPLICATION_ILL_SERVICES_GOALS]'
    +' ,Atbl.[CLIENT_COMPLICATION_ILL_STAGE_CHANGE]'
    +' ,Atbl.[CLIENT_COMPLICATION_ILL_UNDERSTANDS_RISK]'
    +' ,Atbl.[CLIENT_CRIMINAL_FRIENDS_FAM]'
    +' ,Atbl.[CLIENT_CRIMINAL_RISK_LEVEL]'
    +' ,Atbl.[CLIENT_CRIMINAL_SERVICES_GOALS]'
    +' ,Atbl.[CLIENT_CRIMINAL_STAGE_CHANGE]'
    +' ,Atbl.[CLIENT_CRIMINAL_UNDERSTANDS_RISK]'
    +' ,Atbl.[CLIENT_DISABILITY_FRIENDS_FAM]'
    +' ,Atbl.[CLIENT_DISABILITY_RISK_LEVEL]'
    +' ,Atbl.[CLIENT_DISABILITY_SERVICES_GOALS]'
    +' ,Atbl.[CLIENT_DISABILITY_STAGE_CHANGE]'
    +' ,Atbl.[CLIENT_DISABILITY_UNDERSTANDS_RISK]'
    +' ,Atbl.[CLIENT_ECONOMIC_FRIENDS_FAM]'
    +' ,Atbl.[CLIENT_ECONOMIC_RISK_LEVEL]'
    +' ,Atbl.[CLIENT_ECONOMIC_SERVICES_GOALS]'
    +' ,Atbl.[CLIENT_ECONOMIC_STAGE_CHANGE]'
    +' ,Atbl.[CLIENT_ECONOMIC_UNDERSTANDS_RISK]'
    +' ,Atbl.[CLIENT_EDUC_FRIENDS_FAM]'
    +' ,Atbl.[CLIENT_EDUC_RISK_LEVEL]'
    +' ,Atbl.[CLIENT_EDUC_SERVICES_GOALS]'
    +' ,Atbl.[CLIENT_EDUC_STAGE_CHANGE]'
    +' ,Atbl.[CLIENT_EDUC_UNDERSTANDS_RISK]'
    +' ,Atbl.[CLIENT_ENGLIT_FRIENDS_FAM]'
    +' ,Atbl.[CLIENT_ENGLIT_RISK_LEVEL]'
    +' ,Atbl.[CLIENT_ENGLIT_SERVICES_GOALS]'
    +' ,Atbl.[CLIENT_ENGLIT_STAGE_CHANGE]'
    +' ,Atbl.[CLIENT_ENGLIT_UNDERSTANDS_RISK]'
    +' ,Atbl.[CLIENT_ENVIRO_HEALTH_FRIENDS_FAM]'
    +' ,Atbl.[CLIENT_ENVIRO_HEALTH_RISK_LEVEL]'
    +' ,Atbl.[CLIENT_ENVIRO_HEALTH_SERVICES_GOALS]'
    +' ,Atbl.[CLIENT_ENVIRO_HEALTH_STAGE_CHANGE]'
    +' ,Atbl.[CLIENT_ENVIRO_HEALTH_UNDERSTANDS_RISK]'
    +' ,Atbl.[CLIENT_HLTH_SVCS_FRIENDS_FAM]'
    +' ,Atbl.[CLIENT_HLTH_SVCS_RISK_LEVEL]'
    +' ,Atbl.[CLIENT_HLTH_SVCS_SERVICES_GOALS]'
    +' ,Atbl.[CLIENT_HLTH_SVCS_STAGE_CHANGE]'
    +' ,Atbl.[CLIENT_HLTH_SVCS_UNDERSTANDS_RISK]'
    +' ,Atbl.[CLIENT_HOME_SAFETY_FRIENDS_FAM]'
    +' ,Atbl.[CLIENT_HOME_SAFETY_RISK_LEVEL]'
    +' ,Atbl.[CLIENT_HOME_SAFETY_SERVICES_GOALS]'
    +' ,Atbl.[CLIENT_HOME_SAFETY_STAGE_CHANGE]'
    +' ,Atbl.[CLIENT_HOME_SAFETY_UNDERSTANDS_RISK]'
    +' ,Atbl.[CLIENT_HOMELESS_FRIENDS_FAM]'
    +' ,Atbl.[CLIENT_HOMELESS_RISK_LEVEL]'
    +' ,Atbl.[CLIENT_HOMELESS_SERVICES_GOALS]'
    +' ,Atbl.[CLIENT_HOMELESS_STAGE_CHANGE]'
    +' ,Atbl.[CLIENT_HOMELESS_UNDERSTANDS_RISK]'
set @SQL3 = 
    +' ,Atbl.[CLIENT_IPV_FRIENDS_FAM]'
    +' ,Atbl.[CLIENT_IPV_RISK_LEVEL]'
    +' ,Atbl.[CLIENT_IPV_SERVICES_GOALS]'
    +' ,Atbl.[CLIENT_IPV_STAGE_CHANGE]'
    +' ,Atbl.[CLIENT_IPV_UNDERSTANDS_RISK]'
    +' ,Atbl.[CLIENT_LONELY_FRIENDS_FAM]'
    +' ,Atbl.[CLIENT_LONELY_RISK_LEVEL]'
    +' ,Atbl.[CLIENT_LONELY_SERVICES_GOALS]'
    +' ,Atbl.[CLIENT_LONELY_STAGE_CHANGE]'
    +' ,Atbl.[CLIENT_LONELY_UNDERSTANDS_RISK]'
    +' ,Atbl.[CLIENT_MENTAL_HEALTH_FRIENDS_FAM]'
    +' ,Atbl.[CLIENT_MENTAL_HEALTH_RISK_LEVEL]'
    +' ,Atbl.[CLIENT_MENTAL_HEALTH_SERVICES_GOALS]'
    +' ,Atbl.[CLIENT_MENTAL_HEALTH_STAGE_CHANGE]'
    +' ,Atbl.[CLIENT_MENTAL_HEALTH_UNDERSTANDS_RISK]'
    +' ,Atbl.[CLIENT_PREGPLAN_FRIENDS_FAM]'
    +' ,Atbl.[CLIENT_PREGPLAN_RISK_LEVEL]'
    +' ,Atbl.[CLIENT_PREGPLAN_SERVICES_GOALS]'
    +' ,Atbl.[CLIENT_PREGPLAN_STAGE_CHANGE]'
    +' ,Atbl.[CLIENT_PREGPLAN_UNDERSTANDS_RISK]'
    +' ,Atbl.[CLIENT_SUBSTANCE_FRIENDS_FAM]'
    +' ,Atbl.[CLIENT_SUBSTANCE_RISK_LEVEL]'
    +' ,Atbl.[CLIENT_SUBSTANCE_SERVICES_GOALS]'
    +' ,Atbl.[CLIENT_SUBSTANCE_STAGE_CHANGE]'
    +' ,Atbl.[CLIENT_SUBSTANCE_UNDERSTANDS_RISK]'
    +' ,Atbl.[CLIENT_UNSAFE_NTWK_FRIENDS_FAM]'
    +' ,Atbl.[CLIENT_UNSAFE_NTWK_RISK_LEVEL]'
    +' ,Atbl.[CLIENT_UNSAFE_NTWK_SERVICES_GOALS]'
    +' ,Atbl.[CLIENT_UNSAFE_NTWK_STAGE_CHANGE]'
    +' ,Atbl.[CLIENT_UNSAFE_NTWK_UNDERSTANDS_RISK]'
    +' ,Atbl.[CLIENT_0_ID_AGENCY]'
set @SQL4 = ' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.STAR_Survey Atbl'
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
    +' from dbo.STAR_Survey dwsurvey'
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
    +' update dbo.STAR_Survey'
    +' Set [SurveyID] = Atbl.[SurveyID]'
    +' ,[SurveyDate] = Atbl.[SurveyDate]'
    +' ,[AuditDate] = Atbl.[AuditDate]'
    +' ,[CL_EN_GEN_ID] = cxref2.Client_ID'
    +' ,[SiteID] = Atbl.[SiteID]'
    +' ,[ProgramID] = Atbl.[ProgramID]'
    --+' ,[IA_StaffID] = Atbl.[IA_StaffID]'
    +' ,[ClientID] = cxref2.Client_ID'
    +' ,[RespondentID] = Atbl.[RespondentID]'
    +' ,[CLIENT_0_ID_NSO] = Atbl.[CLIENT_0_ID_NSO]'
    +' ,[CLIENT_PERSONAL_0_NAME_FIRST] = Atbl.[CLIENT_PERSONAL_0_NAME_FIRST]'
    +' ,[CLIENT_PERSONAL_0_NAME_LAST] = Atbl.[CLIENT_PERSONAL_0_NAME_LAST]'
    +' ,[CLIENT_PERSONAL_0_DOB_INTAKE] = Atbl.[CLIENT_PERSONAL_0_DOB_INTAKE]'
    +' ,[NURSE_PERSONAL_0_NAME] = exref1.Entity_ID'
    +', [Master_SurveyID] = ms.SourceSurveyID'
    +', [DW_AuditDate] = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    -- survey specific items:
    +' ,[CLIENT_GLOBAL_FACTORS] = Atbl.[CLIENT_GLOBAL_FACTORS]'
    +' ,[CLIENT_CAREGIVING_FRIENDS_FAM] = Atbl.[CLIENT_CAREGIVING_FRIENDS_FAM]'
    +' ,[CLIENT_CAREGIVING_RISK_LEVEL] = Atbl.[CLIENT_CAREGIVING_RISK_LEVEL]'
    +' ,[CLIENT_CAREGIVING_SERVICES_GOALS] = Atbl.[CLIENT_CAREGIVING_SERVICES_GOALS]'
    +' ,[CLIENT_CAREGIVING_STAGE_CHANGE] = Atbl.[CLIENT_CAREGIVING_STAGE_CHANGE]'
    +' ,[CLIENT_CAREGIVING_UNDERSTANDS_RISK] = Atbl.[CLIENT_CAREGIVING_UNDERSTANDS_RISK]'
    +' ,[CLIENT_CHLD_CARE_FRIENDS_FAM] = Atbl.[CLIENT_CHLD_CARE_FRIENDS_FAM]'
    +' ,[CLIENT_CHLD_CARE_RISK_LEVEL] = Atbl.[CLIENT_CHLD_CARE_RISK_LEVEL]'
    +' ,[CLIENT_CHLD_CARE_SERVICES_GOALS] = Atbl.[CLIENT_CHLD_CARE_SERVICES_GOALS]'
    +' ,[CLIENT_CHLD_CARE_STAGE_CHANGE] = Atbl.[CLIENT_CHLD_CARE_STAGE_CHANGE]'
set @SQL2 = ' ,[CLIENT_CHLD_CARE_UNDERSTANDS_RISK] = Atbl.[CLIENT_CHLD_CARE_UNDERSTANDS_RISK]'
    +' ,[CLIENT_CHLD_HEALTH_FRIENDS_FAM] = Atbl.[CLIENT_CHLD_HEALTH_FRIENDS_FAM]'
    +' ,[CLIENT_CHLD_HEALTH_RISK_LEVEL] = Atbl.[CLIENT_CHLD_HEALTH_RISK_LEVEL]'
    +' ,[CLIENT_CHLD_HEALTH_SERVICES_GOALS] = Atbl.[CLIENT_CHLD_HEALTH_SERVICES_GOALS]'
    +' ,[CLIENT_CHLD_HEALTH_STAGE_CHANGE] = Atbl.[CLIENT_CHLD_HEALTH_STAGE_CHANGE]'
    +' ,[CLIENT_CHLD_HEALTH_UNDERSTANDS_RISK] = Atbl.[CLIENT_CHLD_HEALTH_UNDERSTANDS_RISK]'
    +' ,[CLIENT_CHLD_WELL_FRIENDS_FAM] = Atbl.[CLIENT_CHLD_WELL_FRIENDS_FAM]'
    +' ,[CLIENT_CHLD_WELL_RISK_LEVEL] = Atbl.[CLIENT_CHLD_WELL_RISK_LEVEL]'
    +' ,[CLIENT_CHLD_WELL_SERVICES_GOALS] = Atbl.[CLIENT_CHLD_WELL_SERVICES_GOALS]'
    +' ,[CLIENT_CHLD_WELL_STAGE_CHANGE] = Atbl.[CLIENT_CHLD_WELL_STAGE_CHANGE]'
    +' ,[CLIENT_CHLD_WELL_UNDERSTANDS_RISK] = Atbl.[CLIENT_CHLD_WELL_UNDERSTANDS_RISK]'
    +' ,[CLIENT_COMM_SVCS_FRIENDS_FAM] = Atbl.[CLIENT_COMM_SVCS_FRIENDS_FAM]'
    +' ,[CLIENT_COMM_SVCS_RISK_LEVEL] = Atbl.[CLIENT_COMM_SVCS_RISK_LEVEL]'
    +' ,[CLIENT_COMM_SVCS_SERVICES_GOALS] = Atbl.[CLIENT_COMM_SVCS_SERVICES_GOALS]'
    +' ,[CLIENT_COMM_SVCS_STAGE_CHANGE] = Atbl.[CLIENT_COMM_SVCS_STAGE_CHANGE]'
    +' ,[CLIENT_COMM_SVCS_UNDERSTANDS_RISK] = Atbl.[CLIENT_COMM_SVCS_UNDERSTANDS_RISK]'
    +' ,[CLIENT_COMPLICATION_ILL_FRIENDS_FAM] = Atbl.[CLIENT_COMPLICATION_ILL_FRIENDS_FAM]'
    +' ,[CLIENT_COMPLICATION_ILL_RISK_LEVEL] = Atbl.[CLIENT_COMPLICATION_ILL_RISK_LEVEL]'
    +' ,[CLIENT_COMPLICATION_ILL_SERVICES_GOALS] = Atbl.[CLIENT_COMPLICATION_ILL_SERVICES_GOALS]'
    +' ,[CLIENT_COMPLICATION_ILL_STAGE_CHANGE] = Atbl.[CLIENT_COMPLICATION_ILL_STAGE_CHANGE]'
    +' ,[CLIENT_COMPLICATION_ILL_UNDERSTANDS_RISK] = Atbl.[CLIENT_COMPLICATION_ILL_UNDERSTANDS_RISK]'
    +' ,[CLIENT_CRIMINAL_FRIENDS_FAM] = Atbl.[CLIENT_CRIMINAL_FRIENDS_FAM]'
    +' ,[CLIENT_CRIMINAL_RISK_LEVEL] = Atbl.[CLIENT_CRIMINAL_RISK_LEVEL]'
    +' ,[CLIENT_CRIMINAL_SERVICES_GOALS] = Atbl.[CLIENT_CRIMINAL_SERVICES_GOALS]'
    +' ,[CLIENT_CRIMINAL_STAGE_CHANGE] = Atbl.[CLIENT_CRIMINAL_STAGE_CHANGE]'
    +' ,[CLIENT_CRIMINAL_UNDERSTANDS_RISK] = Atbl.[CLIENT_CRIMINAL_UNDERSTANDS_RISK]'
    +' ,[CLIENT_DISABILITY_FRIENDS_FAM] = Atbl.[CLIENT_DISABILITY_FRIENDS_FAM]'
    +' ,[CLIENT_DISABILITY_RISK_LEVEL] = Atbl.[CLIENT_DISABILITY_RISK_LEVEL]'
    +' ,[CLIENT_DISABILITY_SERVICES_GOALS] = Atbl.[CLIENT_DISABILITY_SERVICES_GOALS]'
    +' ,[CLIENT_DISABILITY_STAGE_CHANGE] = Atbl.[CLIENT_DISABILITY_STAGE_CHANGE]'
    +' ,[CLIENT_DISABILITY_UNDERSTANDS_RISK] = Atbl.[CLIENT_DISABILITY_UNDERSTANDS_RISK]'
    +' ,[CLIENT_ECONOMIC_FRIENDS_FAM] = Atbl.[CLIENT_ECONOMIC_FRIENDS_FAM]'
    +' ,[CLIENT_ECONOMIC_RISK_LEVEL] = Atbl.[CLIENT_ECONOMIC_RISK_LEVEL]'
    +' ,[CLIENT_ECONOMIC_SERVICES_GOALS] = Atbl.[CLIENT_ECONOMIC_SERVICES_GOALS]'
set @SQL3 = ' ,[CLIENT_ECONOMIC_STAGE_CHANGE] = Atbl.[CLIENT_ECONOMIC_STAGE_CHANGE]'
    +' ,[CLIENT_ECONOMIC_UNDERSTANDS_RISK] = Atbl.[CLIENT_ECONOMIC_UNDERSTANDS_RISK]'
    +' ,[CLIENT_EDUC_FRIENDS_FAM] = Atbl.[CLIENT_EDUC_FRIENDS_FAM]'
    +' ,[CLIENT_EDUC_RISK_LEVEL] = Atbl.[CLIENT_EDUC_RISK_LEVEL]'
    +' ,[CLIENT_EDUC_SERVICES_GOALS] = Atbl.[CLIENT_EDUC_SERVICES_GOALS]'
    +' ,[CLIENT_EDUC_STAGE_CHANGE] = Atbl.[CLIENT_EDUC_STAGE_CHANGE]'
    +' ,[CLIENT_EDUC_UNDERSTANDS_RISK] = Atbl.[CLIENT_EDUC_UNDERSTANDS_RISK]'
    +' ,[CLIENT_ENGLIT_FRIENDS_FAM] = Atbl.[CLIENT_ENGLIT_FRIENDS_FAM]'
    +' ,[CLIENT_ENGLIT_RISK_LEVEL] = Atbl.[CLIENT_ENGLIT_RISK_LEVEL]'
    +' ,[CLIENT_ENGLIT_SERVICES_GOALS] = Atbl.[CLIENT_ENGLIT_SERVICES_GOALS]'
    +' ,[CLIENT_ENGLIT_STAGE_CHANGE] = Atbl.[CLIENT_ENGLIT_STAGE_CHANGE]'
    +' ,[CLIENT_ENGLIT_UNDERSTANDS_RISK] = Atbl.[CLIENT_ENGLIT_UNDERSTANDS_RISK]'
    +' ,[CLIENT_ENVIRO_HEALTH_FRIENDS_FAM] = Atbl.[CLIENT_ENVIRO_HEALTH_FRIENDS_FAM]'
    +' ,[CLIENT_ENVIRO_HEALTH_RISK_LEVEL] = Atbl.[CLIENT_ENVIRO_HEALTH_RISK_LEVEL]'
    +' ,[CLIENT_ENVIRO_HEALTH_SERVICES_GOALS] = Atbl.[CLIENT_ENVIRO_HEALTH_SERVICES_GOALS]'
    +' ,[CLIENT_ENVIRO_HEALTH_STAGE_CHANGE] = Atbl.[CLIENT_ENVIRO_HEALTH_STAGE_CHANGE]'
    +' ,[CLIENT_ENVIRO_HEALTH_UNDERSTANDS_RISK] = Atbl.[CLIENT_ENVIRO_HEALTH_UNDERSTANDS_RISK]'
    +' ,[CLIENT_HLTH_SVCS_FRIENDS_FAM] = Atbl.[CLIENT_HLTH_SVCS_FRIENDS_FAM]'
    +' ,[CLIENT_HLTH_SVCS_RISK_LEVEL] = Atbl.[CLIENT_HLTH_SVCS_RISK_LEVEL]'
    +' ,[CLIENT_HLTH_SVCS_SERVICES_GOALS] = Atbl.[CLIENT_HLTH_SVCS_SERVICES_GOALS]'
    +' ,[CLIENT_HLTH_SVCS_STAGE_CHANGE] = Atbl.[CLIENT_HLTH_SVCS_STAGE_CHANGE]'
    +' ,[CLIENT_HLTH_SVCS_UNDERSTANDS_RISK] = Atbl.[CLIENT_HLTH_SVCS_UNDERSTANDS_RISK]'
    +' ,[CLIENT_HOME_SAFETY_FRIENDS_FAM] = Atbl.[CLIENT_HOME_SAFETY_FRIENDS_FAM]'
    +' ,[CLIENT_HOME_SAFETY_RISK_LEVEL] = Atbl.[CLIENT_HOME_SAFETY_RISK_LEVEL]'
    +' ,[CLIENT_HOME_SAFETY_SERVICES_GOALS] = Atbl.[CLIENT_HOME_SAFETY_SERVICES_GOALS]'
    +' ,[CLIENT_HOME_SAFETY_STAGE_CHANGE] = Atbl.[CLIENT_HOME_SAFETY_STAGE_CHANGE]'
    +' ,[CLIENT_HOME_SAFETY_UNDERSTANDS_RISK] = Atbl.[CLIENT_HOME_SAFETY_UNDERSTANDS_RISK]'
    +' ,[CLIENT_HOMELESS_FRIENDS_FAM] = Atbl.[CLIENT_HOMELESS_FRIENDS_FAM]'
    +' ,[CLIENT_HOMELESS_RISK_LEVEL] = Atbl.[CLIENT_HOMELESS_RISK_LEVEL]'
    +' ,[CLIENT_HOMELESS_SERVICES_GOALS] = Atbl.[CLIENT_HOMELESS_SERVICES_GOALS]'
    +' ,[CLIENT_HOMELESS_STAGE_CHANGE] = Atbl.[CLIENT_HOMELESS_STAGE_CHANGE]'
    +' ,[CLIENT_HOMELESS_UNDERSTANDS_RISK] = Atbl.[CLIENT_HOMELESS_UNDERSTANDS_RISK]'
    +' ,[CLIENT_IPV_FRIENDS_FAM] = Atbl.[CLIENT_IPV_FRIENDS_FAM]'
    +' ,[CLIENT_IPV_RISK_LEVEL] = Atbl.[CLIENT_IPV_RISK_LEVEL]'
    +' ,[CLIENT_IPV_SERVICES_GOALS] = Atbl.[CLIENT_IPV_SERVICES_GOALS]'
    +' ,[CLIENT_IPV_STAGE_CHANGE] = Atbl.[CLIENT_IPV_STAGE_CHANGE]'
    +' ,[CLIENT_IPV_UNDERSTANDS_RISK] = Atbl.[CLIENT_IPV_UNDERSTANDS_RISK]'
    +' ,[CLIENT_LONELY_FRIENDS_FAM] = Atbl.[CLIENT_LONELY_FRIENDS_FAM]'
    +' ,[CLIENT_LONELY_RISK_LEVEL] = Atbl.[CLIENT_LONELY_RISK_LEVEL]'
    +' ,[CLIENT_LONELY_SERVICES_GOALS] = Atbl.[CLIENT_LONELY_SERVICES_GOALS]'
    +' ,[CLIENT_LONELY_STAGE_CHANGE] = Atbl.[CLIENT_LONELY_STAGE_CHANGE]'
    +' ,[CLIENT_LONELY_UNDERSTANDS_RISK] = Atbl.[CLIENT_LONELY_UNDERSTANDS_RISK]'
    +' ,[CLIENT_MENTAL_HEALTH_FRIENDS_FAM] = Atbl.[CLIENT_MENTAL_HEALTH_FRIENDS_FAM]'
    +' ,[CLIENT_MENTAL_HEALTH_RISK_LEVEL] = Atbl.[CLIENT_MENTAL_HEALTH_RISK_LEVEL]'
set @SQL4 = ' ,[CLIENT_MENTAL_HEALTH_SERVICES_GOALS] = Atbl.[CLIENT_MENTAL_HEALTH_SERVICES_GOALS]'
    +' ,[CLIENT_MENTAL_HEALTH_STAGE_CHANGE] = Atbl.[CLIENT_MENTAL_HEALTH_STAGE_CHANGE]'
    +' ,[CLIENT_MENTAL_HEALTH_UNDERSTANDS_RISK] = Atbl.[CLIENT_MENTAL_HEALTH_UNDERSTANDS_RISK]'
    +' ,[CLIENT_PREGPLAN_FRIENDS_FAM] = Atbl.[CLIENT_PREGPLAN_FRIENDS_FAM]'
    +' ,[CLIENT_PREGPLAN_RISK_LEVEL] = Atbl.[CLIENT_PREGPLAN_RISK_LEVEL]'
    +' ,[CLIENT_PREGPLAN_SERVICES_GOALS] = Atbl.[CLIENT_PREGPLAN_SERVICES_GOALS]'
    +' ,[CLIENT_PREGPLAN_STAGE_CHANGE] = Atbl.[CLIENT_PREGPLAN_STAGE_CHANGE]'
    +' ,[CLIENT_PREGPLAN_UNDERSTANDS_RISK] = Atbl.[CLIENT_PREGPLAN_UNDERSTANDS_RISK]'
    +' ,[CLIENT_SUBSTANCE_FRIENDS_FAM] = Atbl.[CLIENT_SUBSTANCE_FRIENDS_FAM]'
    +' ,[CLIENT_SUBSTANCE_RISK_LEVEL] = Atbl.[CLIENT_SUBSTANCE_RISK_LEVEL]'
    +' ,[CLIENT_SUBSTANCE_SERVICES_GOALS] = Atbl.[CLIENT_SUBSTANCE_SERVICES_GOALS]'
    +' ,[CLIENT_SUBSTANCE_STAGE_CHANGE] = Atbl.[CLIENT_SUBSTANCE_STAGE_CHANGE]'
    +' ,[CLIENT_SUBSTANCE_UNDERSTANDS_RISK] = Atbl.[CLIENT_SUBSTANCE_UNDERSTANDS_RISK]'
    +' ,[CLIENT_UNSAFE_NTWK_FRIENDS_FAM] = Atbl.[CLIENT_UNSAFE_NTWK_FRIENDS_FAM]'
    +' ,[CLIENT_UNSAFE_NTWK_RISK_LEVEL] = Atbl.[CLIENT_UNSAFE_NTWK_RISK_LEVEL]'
    +' ,[CLIENT_UNSAFE_NTWK_SERVICES_GOALS] = Atbl.[CLIENT_UNSAFE_NTWK_SERVICES_GOALS]'
    +' ,[CLIENT_UNSAFE_NTWK_STAGE_CHANGE] = Atbl.[CLIENT_UNSAFE_NTWK_STAGE_CHANGE]'
    +' ,[CLIENT_UNSAFE_NTWK_UNDERSTANDS_RISK] = Atbl.[CLIENT_UNSAFE_NTWK_UNDERSTANDS_RISK]'
    +' ,[CLIENT_0_ID_AGENCY] = Atbl.[CLIENT_0_ID_AGENCY]'
    +'
     from dbo.STAR_Survey dwsurvey'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.STAR_Survey Atbl'
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
    +' and isnull(dwsurvey.AuditDate,convert(datetime,''19700101'',112)) < '
    +' isnull(Atbl.AuditDate,convert(datetime,''19700101'',112))'

    print @SQL1
    print @SQL2
    print @SQL3
    print @SQL4
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar) 
       +', SQL3 Length = ' +CAST(LEN(@SQL3) as varchar) +', SQL4 Length = ' +CAST(LEN(@SQL4) as varchar)
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL1+@SQL2+@SQL3+@SQL4)



----------------------------------------------------------------------------------------
print 'Cont: Delete Responses that no longer exist in AgencyDB'

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

print 'End of Process: SP_AGENCYDB_STAR_SURVEY'
GO
