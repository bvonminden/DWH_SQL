USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_REFERRALS_TO_NFP_SURVEY]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_REFERRALS_TO_NFP_SURVEY
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_REFERRALS_TO_NFP_SURVEY]
 (@p_datasource      nvarchar(10) = null
 ,@p_no_delete_opt   nvarchar(2)  = null
 ,@p_no_exec_flag    nvarchar(10) = 'N')
AS
--
-- This script controls integration of AgencyDB Surveys to the Data Warehouse 
-- REFERRALS_TO_NFP_Survey table.
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
--   20160808 - Added additional qualifier of siteid when retrieving either the xref for non_eto_Client or non_eto_entity.
--              This is becuase SanDiego replicates client_ids between sites.
--   20161114 - Moved the preliminary Non_ETO_SurveyResponse_xref processing to a common sub procedure for AgencyDB processing
--              named: dbo.SP_AGENCYDB_Survey_Non_ETO_Xref_Process.
--   20170409 - Added new column for ETO release: REFERRAL_PROSPECT_0_MARKETING_SOURCE.

DECLARE @count        smallint
DECLARE @stop_flag  nvarchar(2)
DECLARE @Process      nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)
DECLARE @Agency_TableName   nvarchar(50)
DECLARE @Agency_Full_TableName   nvarchar(100)

set @process          = 'SP_AGENCYDB_REFERRALS_TO_NFP_SURVEY'
set @DW_Tablename     = 'REFERRALS_TO_NFP_SURVEY'
set @Agency_Tablename = 'REFERRALS_TO_NFP_SURVEY'
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)
DECLARE @SQL1            varchar(MAX)
DECLARE @SQL2            varchar(MAX)
DECLARE @SQL3            varchar(MAX)

print 'Processing SP_AGENCYDB_REFERRALS_TO_NFP_SURVEY: Datasource = ' +isnull(@p_datasource,'NULL')
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


set @SQL2 = ''
set @sql3 = ''

set @SQL1 = 'set nocount off'
    +' insert into dbo.REFERRALS_TO_NFP_Survey'
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
    +', [REFERRAL_PROSPECT_0_SOURCE_CODE]'
    +', [REFERRAL_SOURCE_PRIMARY_0_NAME]'
    +', [REFERRAL_SOURCE_PRIMARY_1_LOCATION]'
    +', [REFERRAL_SOURCE_SECONDARY_0_NAME]'
    +', [REFERRAL_SOURCE_SECONDARY_1_LOCATION]'
    +', [REFERRAL_PROSPECT_0_NOTES]'
    +', [REFERRAL_PROSPECT_DEMO_1_PLANG]'
    +', [REFERRAL_PROSPECT_DEMO_1_NAME_FIRST]'
    +', [REFERRAL_PROSPECT_DEMO_0_NAME_LAST]'
    +', [REFERRAL_PROSPECT_DEMO_1_DOB]'
    +', [REFERRAL_PROSPECT_DEMO_1_STREET]'
    +', [REFERRAL_PROSPECT_DEMO_1_STREET2]'
    +', [REFERRAL_PROSPECT_DEMO_1_ZIP]'
    +', [REFERRAL_PROSPECT_DEMO_1_WORK]'
    +', [REFERRAL_PROSPECT_DEMO_1_PHONE_HOME]'
    +', [REFERRAL_PROSPECT_DEMO_1_CELL]'
    +', [REFERRAL_PROSPECT_DEMO_1_EMAIL]'
    +', [REFERRAL_PROSPECT_DEMO_1_EDD]'
    +', [REFERRAL_PROSPECT_0_WAIT_LIST]'
    +', [REFERRAL_PROSPECT_0_FOLLOWUP_NURSE]'
    +', [LA_CTY_REFERRAL_SCHOOL]'
    +', [LA_CTY_REFERRAL_SOURCE_OTH]'
    +', [REFERRAL_PROSPECT_0_MARKETING_SOURCE]'
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
    +', Atbl.[REFERRAL_PROSPECT_0_SOURCE_CODE]'
    +', Atbl.[REFERRAL_SOURCE_PRIMARY_0_NAME]'
    +', Atbl.[REFERRAL_SOURCE_PRIMARY_1_LOCATION]'
    +', Atbl.[REFERRAL_SOURCE_SECONDARY_0_NAME]'
    +', Atbl.[REFERRAL_SOURCE_SECONDARY_1_LOCATION]'
    +', Atbl.[REFERRAL_PROSPECT_0_NOTES]'
    +', Atbl.[REFERRAL_PROSPECT_DEMO_1_PLANG]'
    +', Atbl.[REFERRAL_PROSPECT_DEMO_1_NAME_FIRST]'
    +', Atbl.[REFERRAL_PROSPECT_DEMO_0_NAME_LAST]'
    +', Atbl.[REFERRAL_PROSPECT_DEMO_1_DOB]'
    +', Atbl.[REFERRAL_PROSPECT_DEMO_1_STREET]'
    +', Atbl.[REFERRAL_PROSPECT_DEMO_1_STREET2]'
    +', Atbl.[REFERRAL_PROSPECT_DEMO_1_ZIP]'
    +', Atbl.[REFERRAL_PROSPECT_DEMO_1_WORK]'
    +', Atbl.[REFERRAL_PROSPECT_DEMO_1_PHONE_HOME]'
    +', Atbl.[REFERRAL_PROSPECT_DEMO_1_CELL]'
    +', Atbl.[REFERRAL_PROSPECT_DEMO_1_EMAIL]'
    +', Atbl.[REFERRAL_PROSPECT_DEMO_1_EDD]'
    +', Atbl.[REFERRAL_PROSPECT_0_WAIT_LIST]'
    +', Atbl.[REFERRAL_PROSPECT_0_FOLLOWUP_NURSE]'
    +', Atbl.[LA_CTY_REFERRAL_SCHOOL]'
    +', Atbl.[LA_CTY_REFERRAL_SOURCE_OTH]'
    +', Atbl.[REFERRAL_PROSPECT_0_MARKETING_SOURCE]'
    +', ms.SourceSurveyID'
    +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.REFERRALS_TO_NFP_Survey Atbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' left join dbo.Non_ETO_Client_Xref cxref1 on cxref1.Source =  ''' +@p_datasource +''''
    +'   and cxref1.Non_ETO_ID = Atbl.CL_EN_GEN_ID' 
    +'   and cxref1.Non_ETO_Site_ID = Atbl.SiteID'
    +' left join dbo.Non_ETO_Client_Xref cxref2 on cxref2.Source =  ''' +@p_datasource +''''
    +'   and cxref2.Non_ETO_ID = Atbl.ClientID'
    +'   and cxref2.Non_ETO_Site_ID = Atbl.SiteID'
    +' left join dbo.Mstr_Surveys ms on Atbl.SurveyID = ms.SurveyID'
    +' where Atbl.DW_SurveyResponseID is not null'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'
    +' and not exists (select dwsurvey.SurveyResponseID'
    +' from dbo.REFERRALS_TO_NFP_Survey dwsurvey'
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
set @SQL2 = ''
set @sql3 = ''

set @SQL1 = 'set nocount off'
    +' update dbo.REFERRALS_TO_NFP_Survey'
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
    +', [REFERRAL_PROSPECT_0_SOURCE_CODE] = Atbl.[REFERRAL_PROSPECT_0_SOURCE_CODE]'
    +', [REFERRAL_SOURCE_PRIMARY_0_NAME] = Atbl.[REFERRAL_SOURCE_PRIMARY_0_NAME]'
    +', [REFERRAL_SOURCE_PRIMARY_1_LOCATION] = Atbl.[REFERRAL_SOURCE_PRIMARY_1_LOCATION]'
    +', [REFERRAL_SOURCE_SECONDARY_0_NAME] = Atbl.[REFERRAL_SOURCE_SECONDARY_0_NAME]'
    +', [REFERRAL_SOURCE_SECONDARY_1_LOCATION] = Atbl.[REFERRAL_SOURCE_SECONDARY_1_LOCATION]'
    +', [REFERRAL_PROSPECT_0_NOTES] = Atbl.[REFERRAL_PROSPECT_0_NOTES]'
    +', [REFERRAL_PROSPECT_DEMO_1_PLANG] = Atbl.[REFERRAL_PROSPECT_DEMO_1_PLANG]'
    +', [REFERRAL_PROSPECT_DEMO_1_NAME_FIRST] = Atbl.[REFERRAL_PROSPECT_DEMO_1_NAME_FIRST]'
    +', [REFERRAL_PROSPECT_DEMO_0_NAME_LAST] = Atbl.[REFERRAL_PROSPECT_DEMO_0_NAME_LAST]'
    +', [REFERRAL_PROSPECT_DEMO_1_DOB] = Atbl.[REFERRAL_PROSPECT_DEMO_1_DOB]'
    +', [REFERRAL_PROSPECT_DEMO_1_STREET] = Atbl.[REFERRAL_PROSPECT_DEMO_1_STREET]'
    +', [REFERRAL_PROSPECT_DEMO_1_STREET2] = Atbl.[REFERRAL_PROSPECT_DEMO_1_STREET2]'
    +', [REFERRAL_PROSPECT_DEMO_1_ZIP] = Atbl.[REFERRAL_PROSPECT_DEMO_1_ZIP]'
    +', [REFERRAL_PROSPECT_DEMO_1_WORK] = Atbl.[REFERRAL_PROSPECT_DEMO_1_WORK]'
    +', [REFERRAL_PROSPECT_DEMO_1_PHONE_HOME] = Atbl.[REFERRAL_PROSPECT_DEMO_1_PHONE_HOME]'
    +', [REFERRAL_PROSPECT_DEMO_1_CELL] = Atbl.[REFERRAL_PROSPECT_DEMO_1_CELL]'
    +', [REFERRAL_PROSPECT_DEMO_1_EMAIL] = Atbl.[REFERRAL_PROSPECT_DEMO_1_EMAIL]'
    +', [REFERRAL_PROSPECT_DEMO_1_EDD] = Atbl.[REFERRAL_PROSPECT_DEMO_1_EDD]'
    +', [REFERRAL_PROSPECT_0_WAIT_LIST] = Atbl.[REFERRAL_PROSPECT_0_WAIT_LIST]'
    +', [REFERRAL_PROSPECT_0_FOLLOWUP_NURSE] = Atbl.[REFERRAL_PROSPECT_0_FOLLOWUP_NURSE]'
    +', [LA_CTY_REFERRAL_SCHOOL] = Atbl.[LA_CTY_REFERRAL_SCHOOL]'
    +', [LA_CTY_REFERRAL_SOURCE_OTH] = Atbl.[LA_CTY_REFERRAL_SOURCE_OTH]'
    +', [REFERRAL_PROSPECT_0_MARKETING_SOURCE] = Atbl.[REFERRAL_PROSPECT_0_MARKETING_SOURCE]'
    +', [Master_SurveyID] = ms.SourceSurveyID'
    +', [DW_AuditDate] = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from dbo.REFERRALS_TO_NFP_Survey dwsurvey'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.REFERRALS_TO_NFP_Survey Atbl'
    +' on dwsurvey.SurveyResponseID = Atbl.DW_SurveyResponseID'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' left join dbo.Non_ETO_Client_Xref cxref1 on cxref1.Source =  ''' +@p_datasource +''''
    +'   and cxref1.Non_ETO_ID = Atbl.CL_EN_GEN_ID' 
    +'   and cxref1.Non_ETO_Site_ID = Atbl.SiteID'
    +' left join dbo.Non_ETO_Client_Xref cxref2 on cxref2.Source =  ''' +@p_datasource +''''
    +'   and cxref2.Non_ETO_ID = Atbl.ClientID' 
    +'   and cxref2.Non_ETO_Site_ID = Atbl.SiteID'
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

print 'End of Process: SP_AGENCYDB_REFERRALS_TO_NFP_SURVEY'
GO
