USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_REFERRALS_TO_SERVICES_SURVEY]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_REFERRALS_TO_SERVICES_SURVEY
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_REFERRALS_TO_SERVICES_SURVEY]
 (@p_datasource      nvarchar(10) = null
 ,@p_no_delete_opt   nvarchar(2)  = null
 ,@p_no_exec_flag    nvarchar(10) = 'N')
AS
--
-- This script controls integration of AgencyDB Surveys to the Data Warehouse 
-- REFERRALS_TO_SERVICES_Survey table.
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
--   20161114 - Moved the preliminary Non_ETO_SurveyResponse_xref processing to a common sub procedure for AgencyDB processing
--              named: dbo.SP_AGENCYDB_Survey_Non_ETO_Xref_Process.
--   20170511 - Amended to validate the xref to non ETO clients and Entites to validate with site_id.  
--              This is becuase SanDiego is using the same Client_ID and Entity_ID across diferrent sites in the same AgencyDB.

DECLARE @count          smallint
DECLARE @stop_flag      nvarchar(2)
DECLARE @Process        nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)
DECLARE @Agency_TableName        nvarchar(50)
DECLARE @Agency_Full_TableName   nvarchar(100)

set @process          = 'SP_AGENCYDB_REFERRALS_TO_SERVICES_SURVEY'
set @DW_Tablename     = 'REFERRALS_TO_SERVICES_SURVEY'
set @Agency_Tablename = 'REFERRALS_TO_SERVICES_SURVEY'
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)
DECLARE @SQL1            varchar(MAX)
DECLARE @SQL2            varchar(MAX)
DECLARE @SQL3            varchar(MAX)

print 'Processing SP_AGENCYDB_REFERRALS_TO_SERVICES_SURVEY: Datasource = ' +isnull(@p_datasource,'NULL')
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


set @SQL2 = ' '
set @sql3 = ' '

set @SQL1 = 'set nocount off'
    +' insert into dbo.REFERRALS_TO_SERVICES_Survey'
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
    +', [SERVICE_REFER_0_TANF]'
    +', [SERVICE_REFER_0_FOODSTAMP]'
    +', [SERVICE_REFER_0_SOCIAL_SECURITY]'
    +', [SERVICE_REFER_0_UNEMPLOYMENT]'
    +', [SERVICE_REFER_0_SUBSID_CHILD_CARE]'
    +', [SERVICE_REFER_0_IPV]'
    +', [SERVICE_REFER_0_CPS]'
    +', [SERVICE_REFER_0_MENTAL]'
    +', [SERVICE_REFER_0_RELATIONSHIP_COUNSELING]'
    +', [SERVICE_REFER_0_SMOKE]'
    +', [SERVICE_REFER_0_ALCOHOL_ABUSE]'
    +', [SERVICE_REFER_0_MEDICAID]'
    +', [SERVICE_REFER_0_SCHIP]'
    +', [SERVICE_REFER_0_PRIVATE_INSURANCE]'
    +', [SERVICE_REFER_0_SPECIAL_NEEDS]'
    +', [SERVICE_REFER_0_PCP]'
    +', [SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY]'
    +', [SERVICE_REFER_0_WIC_CLIENT]'
    +', [SERVICE_REFER_0_CHILD_CARE]'
    +', [SERVICE_REFER_0_JOB_TRAINING]'
    +', [SERVICE_REFER_0_HOUSING]'
    +', [SERVICE_REFER_0_TRANSPORTATION]'
    +', [SERVICE_REFER_0_PREVENT_INJURY]'
    +', [SERVICE_REFER_0_BIRTH_EDUC_CLASS]'
    +', [SERVICE_REFER_0_LACTATION]'
    +', [SERVICE_REFER_0_GED]'
    +', [SERVICE_REFER_0_HIGHER_EDUC]'
    +', [SERVICE_REFER_0_CHARITY]'
    +', [SERVICE_REFER_0_LEGAL_CLIENT]'
    +', [SERVICE_REFER_0_PATERNITY]'
    +', [SERVICE_REFER_0_CHILD_SUPPORT]'
    +', [SERVICE_REFER_0_ADOPTION]'
    +', [SERIVCE_REFER_0_OTHER1_DESC]'
    +', [SERIVCE_REFER_0_OTHER2_DESC]'
    +', [SERIVCE_REFER_0_OTHER3_DESC]'
    +', [SERVICE_REFER_0_DRUG_ABUSE]'
    +', [SERVICE_REFER_0_OTHER]'
    +', [REFERRALS_TO_0_FORM_TYPE]'
    +', [CLIENT_0_ID_NSO]'
    +', [CLIENT_PERSONAL_0_NAME_FIRST]'
    +', [CLIENT_PERSONAL_0_NAME_LAST]'
    +', [CLIENT_PERSONAL_0_DOB_INTAKE]'
    +', [CLIENT_0_ID_AGENCY]'
    +', [NURSE_PERSONAL_0_NAME]'
    +', [SERVICE_REFER_0_DENTAL]'
    +', [SERVICE_REFER_0_INTERVENTION]'
    +', [SERVICE_REFER_0_PCP_R2]'
    +', [SERVICE_REFER_INDIAN_HEALTH]'
    +', [SERVICE_REFER_MILITARY_INS]'
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
    +', Atbl.[SERVICE_REFER_0_TANF]'
    +', Atbl.[SERVICE_REFER_0_FOODSTAMP]'
    +', Atbl.[SERVICE_REFER_0_SOCIAL_SECURITY]'
    +', Atbl.[SERVICE_REFER_0_UNEMPLOYMENT]'
    +', Atbl.[SERVICE_REFER_0_SUBSID_CHILD_CARE]'
    +', Atbl.[SERVICE_REFER_0_IPV]'
    +', Atbl.[SERVICE_REFER_0_CPS]'
    +', Atbl.[SERVICE_REFER_0_MENTAL]'
    +', Atbl.[SERVICE_REFER_0_RELATIONSHIP_COUNSELING]'
    +', Atbl.[SERVICE_REFER_0_SMOKE]'
    +', Atbl.[SERVICE_REFER_0_ALCOHOL_ABUSE]'
    +', Atbl.[SERVICE_REFER_0_MEDICAID]'
    +', Atbl.[SERVICE_REFER_0_SCHIP]'
    +', Atbl.[SERVICE_REFER_0_PRIVATE_INSURANCE]'
    +', Atbl.[SERVICE_REFER_0_SPECIAL_NEEDS]'
    +', Atbl.[SERVICE_REFER_0_PCP]'
    +', Atbl.[SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY]'
    +', Atbl.[SERVICE_REFER_0_WIC_CLIENT]'
    +', Atbl.[SERVICE_REFER_0_CHILD_CARE]'
    +', Atbl.[SERVICE_REFER_0_JOB_TRAINING]'
    +', Atbl.[SERVICE_REFER_0_HOUSING]'
    +', Atbl.[SERVICE_REFER_0_TRANSPORTATION]'
    +', Atbl.[SERVICE_REFER_0_PREVENT_INJURY]'
    +', Atbl.[SERVICE_REFER_0_BIRTH_EDUC_CLASS]'
    +', Atbl.[SERVICE_REFER_0_LACTATION]'
    +', Atbl.[SERVICE_REFER_0_GED]'
    +', Atbl.[SERVICE_REFER_0_HIGHER_EDUC]'
    +', Atbl.[SERVICE_REFER_0_CHARITY]'
    +', Atbl.[SERVICE_REFER_0_LEGAL_CLIENT]'
    +', Atbl.[SERVICE_REFER_0_PATERNITY]'
    +', Atbl.[SERVICE_REFER_0_CHILD_SUPPORT]'
    +', Atbl.[SERVICE_REFER_0_ADOPTION]'
    +', Atbl.[SERIVCE_REFER_0_OTHER1_DESC]'
    +', Atbl.[SERIVCE_REFER_0_OTHER2_DESC]'
    +', Atbl.[SERIVCE_REFER_0_OTHER3_DESC]'
    +', Atbl.[SERVICE_REFER_0_DRUG_ABUSE]'
    +', Atbl.[SERVICE_REFER_0_OTHER]'
    +', Atbl.[REFERRALS_TO_0_FORM_TYPE]'
    +', Atbl.[CLIENT_0_ID_NSO]'
    +', Atbl.[CLIENT_PERSONAL_0_NAME_FIRST]'
    +', Atbl.[CLIENT_PERSONAL_0_NAME_LAST]'
    +', Atbl.[CLIENT_PERSONAL_0_DOB_INTAKE]'
    +', Atbl.[CLIENT_0_ID_AGENCY]'
    +' ,exref1.Entity_ID'
    +', Atbl.[SERVICE_REFER_0_DENTAL]'
    +', Atbl.[SERVICE_REFER_0_INTERVENTION]'
    +', Atbl.[SERVICE_REFER_0_PCP_R2]'
    +', Atbl.[SERVICE_REFER_INDIAN_HEALTH]'
    +', Atbl.[SERVICE_REFER_MILITARY_INS]'
    +', ms.SourceSurveyID'
    +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
set @SQL3 = '
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.REFERRALS_TO_SERVICES_Survey Atbl'
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
    +' from dbo.REFERRALS_TO_SERVICES_Survey dwsurvey'
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
set @SQL2 = ' '
set @sql3 = ' '

set @SQL1 = 'set nocount off'
    +' update dbo.REFERRALS_TO_SERVICES_Survey'
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
    +', [SERVICE_REFER_0_TANF] = Atbl.[SERVICE_REFER_0_TANF]'
    +', [SERVICE_REFER_0_FOODSTAMP] = Atbl.[SERVICE_REFER_0_FOODSTAMP]'
    +', [SERVICE_REFER_0_SOCIAL_SECURITY] = Atbl.[SERVICE_REFER_0_SOCIAL_SECURITY]'
    +', [SERVICE_REFER_0_UNEMPLOYMENT] = Atbl.[SERVICE_REFER_0_UNEMPLOYMENT]'
    +', [SERVICE_REFER_0_SUBSID_CHILD_CARE] = Atbl.[SERVICE_REFER_0_SUBSID_CHILD_CARE]'
    +', [SERVICE_REFER_0_IPV] = Atbl.[SERVICE_REFER_0_IPV]'
    +', [SERVICE_REFER_0_CPS] = Atbl.[SERVICE_REFER_0_CPS]'
    +', [SERVICE_REFER_0_MENTAL] = Atbl.[SERVICE_REFER_0_MENTAL]'
    +', [SERVICE_REFER_0_RELATIONSHIP_COUNSELING] = Atbl.[SERVICE_REFER_0_RELATIONSHIP_COUNSELING]'
    +', [SERVICE_REFER_0_SMOKE] = Atbl.[SERVICE_REFER_0_SMOKE]'
    +', [SERVICE_REFER_0_ALCOHOL_ABUSE] = Atbl.[SERVICE_REFER_0_ALCOHOL_ABUSE]'
    +', [SERVICE_REFER_0_MEDICAID] = Atbl.[SERVICE_REFER_0_MEDICAID]'
    +', [SERVICE_REFER_0_SCHIP] = Atbl.[SERVICE_REFER_0_SCHIP]'
    +', [SERVICE_REFER_0_PRIVATE_INSURANCE] = Atbl.[SERVICE_REFER_0_PRIVATE_INSURANCE]'
    +', [SERVICE_REFER_0_SPECIAL_NEEDS] = Atbl.[SERVICE_REFER_0_SPECIAL_NEEDS]'
    +', [SERVICE_REFER_0_PCP] = Atbl.[SERVICE_REFER_0_PCP]'
    +', [SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY] = Atbl.[SERVICE_REFER_0_DEVELOPMENTAL_DISABILITY]'
    +', [SERVICE_REFER_0_WIC_CLIENT] = Atbl.[SERVICE_REFER_0_WIC_CLIENT]'
    +', [SERVICE_REFER_0_CHILD_CARE] = Atbl.[SERVICE_REFER_0_CHILD_CARE]'
    +', [SERVICE_REFER_0_JOB_TRAINING] = Atbl.[SERVICE_REFER_0_JOB_TRAINING]'
    +', [SERVICE_REFER_0_HOUSING] = Atbl.[SERVICE_REFER_0_HOUSING]'
    +', [SERVICE_REFER_0_TRANSPORTATION] = Atbl.[SERVICE_REFER_0_TRANSPORTATION]'
    +', [SERVICE_REFER_0_PREVENT_INJURY] = Atbl.[SERVICE_REFER_0_PREVENT_INJURY]'
    +', [SERVICE_REFER_0_BIRTH_EDUC_CLASS] = Atbl.[SERVICE_REFER_0_BIRTH_EDUC_CLASS]'
    +', [SERVICE_REFER_0_LACTATION] = Atbl.[SERVICE_REFER_0_LACTATION]'
    +', [SERVICE_REFER_0_GED] = Atbl.[SERVICE_REFER_0_GED]'
    +', [SERVICE_REFER_0_HIGHER_EDUC] = Atbl.[SERVICE_REFER_0_HIGHER_EDUC]'
    +', [SERVICE_REFER_0_CHARITY] = Atbl.[SERVICE_REFER_0_CHARITY]'
    +', [SERVICE_REFER_0_LEGAL_CLIENT] = Atbl.[SERVICE_REFER_0_LEGAL_CLIENT]'
    +', [SERVICE_REFER_0_PATERNITY] = Atbl.[SERVICE_REFER_0_PATERNITY]'
    +', [SERVICE_REFER_0_CHILD_SUPPORT] = Atbl.[SERVICE_REFER_0_CHILD_SUPPORT]'
    +', [SERVICE_REFER_0_ADOPTION] = Atbl.[SERVICE_REFER_0_ADOPTION]'
    +', [SERIVCE_REFER_0_OTHER1_DESC] = Atbl.[SERIVCE_REFER_0_OTHER1_DESC]'
    +', [SERIVCE_REFER_0_OTHER2_DESC] = Atbl.[SERIVCE_REFER_0_OTHER2_DESC]'
    +', [SERIVCE_REFER_0_OTHER3_DESC] = Atbl.[SERIVCE_REFER_0_OTHER3_DESC]'
    +', [SERVICE_REFER_0_DRUG_ABUSE] = Atbl.[SERVICE_REFER_0_DRUG_ABUSE]'
    +', [SERVICE_REFER_0_OTHER] = Atbl.[SERVICE_REFER_0_OTHER]'
    +', [REFERRALS_TO_0_FORM_TYPE] = Atbl.[REFERRALS_TO_0_FORM_TYPE]'
    +', [CLIENT_0_ID_NSO] = Atbl.[CLIENT_0_ID_NSO]'
    +', [CLIENT_PERSONAL_0_NAME_FIRST] = Atbl.[CLIENT_PERSONAL_0_NAME_FIRST]'
    +', [CLIENT_PERSONAL_0_NAME_LAST] = Atbl.[CLIENT_PERSONAL_0_NAME_LAST]'
    +', [CLIENT_PERSONAL_0_DOB_INTAKE] = Atbl.[CLIENT_PERSONAL_0_DOB_INTAKE]'
    +', [CLIENT_0_ID_AGENCY] = Atbl.[CLIENT_0_ID_AGENCY]'
    +', [NURSE_PERSONAL_0_NAME] = exref1.Entity_ID'
    +', [SERVICE_REFER_0_DENTAL] = Atbl.[SERVICE_REFER_0_DENTAL]'
    +', [SERVICE_REFER_0_INTERVENTION] = Atbl.[SERVICE_REFER_0_INTERVENTION]'
    +', [SERVICE_REFER_0_PCP_R2] = Atbl.[SERVICE_REFER_0_PCP_R2]'
    +', [SERVICE_REFER_INDIAN_HEALTH] = Atbl.[SERVICE_REFER_INDIAN_HEALTH]'
    +', [SERVICE_REFER_MILITARY_INS] = Atbl.[SERVICE_REFER_MILITARY_INS]'
    +', [Master_SurveyID] = ms.SourceSurveyID'
    +', [DW_AuditDate] = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
set @SQL2 = '
     from dbo.REFERRALS_TO_SERVICES_Survey dwsurvey'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.REFERRALS_TO_SERVICES_Survey Atbl'
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

print 'End of Process: SP_AGENCYDB_REFERRALS_TO_SERVICES_SURVEY'
GO
