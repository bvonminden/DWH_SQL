USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_AGENCY_PROFILE_SURVEY]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_AGENCY_PROFILE_SURVEY
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_AGENCY_PROFILE_SURVEY]
 (@p_datasource      nvarchar(10) = null
 ,@p_no_delete_opt   nvarchar(2)  = null)
AS
--
-- This script controls integration of AgencyDB Surveys to the Data Warehouse 
-- AGENCY_PROFILE_Survey table.
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
--   20140422 - New Procedure.
--   20140917 - Added population of Master_SurveyID colummn.
--   20140930 - Changed to utilize the ETO SurveyResponse record if found, 
--              creating the xref from the client-defined ID mapping to the orig ETO_SurveyResponseID
--              Else if not identified: create new xref record with next available Non_Entity_ID in sequence.
--   20140930 - Added option to not delete records.  This is to accommodate initial AgencyDB loads 
--              of smaller incremented batches while Agecncy is cleaning up data.  Option is 'Y' to inhibit delete.

DECLARE @count        smallint
DECLARE @stop_flag  nvarchar(2)
DECLARE @Process      nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)
DECLARE @Agency_TableName   nvarchar(50)
DECLARE @Agency_Full_TableName   nvarchar(100)

set @process = 'SP_AGENCYDB_AGENCY_PROFILE_SURVEY'
set @DW_Tablename     = 'AGENCY_PROFILE_SURVEY'
set @agency_Tablename = 'AGENCY_PROFILE_SURVEY'
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)
DECLARE @SQL1           varchar(MAX)
DECLARE @SQL2           varchar(MAX)
DECLARE @SQL3           varchar(MAX)
DECLARE @SQL4           varchar(MAX)

print 'Processing SP_AGENCYDB_AGENCY_PROFILE_SURVEY: Datasource = ' +isnull(@p_datasource,'NULL')
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


-- create non_ETO xref entries for new SurveyResponse records from AgencyDB (that originated from ETO):
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
    +'   and dwxref.Non_ETO_ID = Atbl.SurveyResponseID'
    +'   and dwxref.DW_tableName = ''' +@DW_TableName +''''
    +'   and dwxref.Non_ETO_Site_ID = atbl.SiteID)'
    +'   and exists (select SurveyResponseID from dbo.' +@DW_TableName 
    +' dtbl where dtbl.SurveyResponseID = ETO_SurveyResponseID'
    +' and dtbl.siteid = Atbl.SiteID)'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'

    print @SQL
    EXEC (@SQL)


-- For AgencyDB records that DO NOT originate from ETO:
-- create non_ETO xref entries for new SurveyResponse records from AgencyDB:
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
    EXEC (@SQL)


-- Assign new NON-ETO xref ID to new records from AgencyDB:
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
    EXEC (@SQL)


set @SQL1 = 'set nocount off'
    +' insert into dbo.AGENCY_PROFILE_Survey'
    +' ([SurveyResponseID],[DataSource],[ElementsProcessed]'
    +' ,[SurveyID]'
    +' ,[SurveyDate]'
    +' ,[AuditDate]'
    +' ,[CL_EN_GEN_ID]'
    +' ,[SiteID]'
    +' ,[ProgramID]'
    +' ,[IA_StaffID]'
    +' ,[ClientID]'
    +' ,[RespondentID]'
    +' ,[Entity_ID_Mapped]'
    +' ,[AGENCY_RESEARCH_0_INVOLVEMENT]'
    +' ,[AGENCY_RESEARCH01_1_PI1]'
    +' ,[AGENCY_RESEARCH01_0_PROJECT_NAME]'
    +' ,[AGENCY_RESEARCH01_1_PROJECT_DESCRIPTION]'
    +' ,[AGENCY_RESEARCH01_1_START_DATE]'
    +' ,[AGENCY_RESEARCH01_1_END_DATE]'
    +' ,[AGENCY_RESEARCH01_1_APPROVAL]'
    +' ,[AGENCY_INFO_1_FUNDED_CAPACITY_FTE]'
    +' ,[AGENCY_INFO_1_CONTRACT_CAPACITY_FTE]'
    +' ,[AGENCY_INFO_BOARD_0_MEETING_DATE01]'
    +' ,[AGENCY_INFO_BOARD_0_MEETING_DATE02]'
    +' ,[AGENCY_INFO_BOARD_0_MEETING_DATE03]'
    +' ,[AGENCY_INFO_BOARD_0_MEETING_DATE04]'
    +' ,[AGENCY_FUNDING01_0_FUNDER_NAME]'
    +' ,[AGENCY_FUNDING02_0_FUNDER_NAME]'
    +' ,[AGENCY_FUNDING03_0_FUNDER_NAME]'
    +' ,[AGENCY_FUNDING04_0_FUNDER_NAME]'
    +' ,[AGENCY_FUNDING05_0_FUNDER_NAME]'
    +' ,[AGENCY_FUNDING06_0_FUNDER_NAME]'
    +' ,[AGENCY_FUNDING07_0_FUNDER_NAME]'
    +' ,[AGENCY_FUNDING08_0_FUNDER_NAME]'
    +' ,[AGENCY_FUNDING10_0_FUNDER_NAME]'
    +' ,[AGENCY_FUNDING11_0_FUNDER_NAME]'
    +' ,[AGENCY_FUNDING12_0_FUNDER_NAME]'
    +' ,[AGENCY_FUNDING13_0_FUNDER_NAME]'
    +' ,[AGENCY_FUNDING14_0_FUNDER_NAME]'
    +' ,[AGENCY_FUNDING15_0_FUNDER_NAME]'
    +' ,[AGENCY_FUNDING16_0_FUNDER_NAME]'
    +' ,[AGENCY_FUNDING17_0_FUNDER_NAME]'
    +' ,[AGENCY_FUNDING09_0_FUNDER_NAME]'
    +' ,[AGENCY_FUNDING18_0_FUNDER_NAME]'
    +' ,[AGENCY_FUNDING19_0_FUNDER_NAME]'
    +' ,[AGENCY_FUNDING20_0_FUNDER_NAME]'
    +' ,[AGENCY_FUNDING01_1_START_DATE]'
    +' ,[AGENCY_FUNDING02_1_START_DATE]'
    +' ,[AGENCY_FUNDING03_1_START_DATE]'
    +' ,[AGENCY_FUNDING04_1_START_DATE]'
    +' ,[AGENCY_FUNDING05_1_START_DATE]'
    +' ,[AGENCY_FUNDING06_1_START_DATE]'
    +' ,[AGENCY_FUNDING07_1_START_DATE]'
    +' ,[AGENCY_FUNDING08_1_START_DATE]'
    +' ,[AGENCY_FUNDING09_1_START_DATE]'
    +' ,[AGENCY_FUNDING10_1_START_DATE]'
    +' ,[AGENCY_FUNDING11_1_START_DATE]'
    +' ,[AGENCY_FUNDING12_1_START_DATE]'
    +' ,[AGENCY_FUNDING13_1_START_DATE]'
    +' ,[AGENCY_FUNDING14_1_START_DATE]'
    +' ,[AGENCY_FUNDING15_1_START_DATE]'
    +' ,[AGENCY_FUNDING16_1_START_DATE]'
    +' ,[AGENCY_FUNDING17_1_START_DATE]'
    +' ,[AGENCY_FUNDING18_1_START_DATE]'
    +' ,[AGENCY_FUNDING19_1_START_DATE]'
    +' ,[AGENCY_FUNDING20_1_START_DATE]'
    +' ,[AGENCY_FUNDING01_1_END_DATE]'
    +' ,[AGENCY_FUNDING02_1_END_DATE]'
    +' ,[AGENCY_FUNDING03_1_END_DATE]'
    +' ,[AGENCY_FUNDING04_1_END_DATE]'
    +' ,[AGENCY_FUNDING05_1_END_DATE]'
    +' ,[AGENCY_FUNDING06_1_END_DATE]'
    +' ,[AGENCY_FUNDING07_1_END_DATE]'
    +' ,[AGENCY_FUNDING08_1_END_DATE]'
    +' ,[AGENCY_FUNDING09_1_END_DATE]'
    +' ,[AGENCY_FUNDING10_1_END_DATE]'
    +' ,[AGENCY_FUNDING11_1_END_DATE]'
    +' ,[AGENCY_FUNDING12_1_END_DATE]'
    +' ,[AGENCY_FUNDING13_1_END_DATE]'
    +' ,[AGENCY_FUNDING14_1_END_DATE]'
    +' ,[AGENCY_FUNDING15_1_END_DATE]'
    +' ,[AGENCY_FUNDING16_1_END_DATE]'
    +' ,[AGENCY_FUNDING17_1_END_DATE]'
    +' ,[AGENCY_FUNDING18_1_END_DATE]'
    +' ,[AGENCY_FUNDING19_1_END_DATE]'
    +' ,[AGENCY_FUNDING20_1_END_DATE]'
    +' ,[AGENCY_FUNDING01_1_FUNDER_TYPE]'
    +' ,[AGENCY_FUNDING02_1_FUNDER_TYPE]'
    +' ,[AGENCY_FUNDING03_1_FUNDER_TYPE]'
    +' ,[AGENCY_FUNDING04_1_FUNDER_TYPE]'
    +' ,[AGENCY_FUNDING05_1_FUNDER_TYPE]'
    +' ,[AGENCY_FUNDING06_1_FUNDER_TYPE]'
    +' ,[AGENCY_FUNDING07_1_FUNDER_TYPE]'
    +' ,[AGENCY_FUNDING08_1_FUNDER_TYPE]'
    +' ,[AGENCY_FUNDING09_1_FUNDER_TYPE]'
    +' ,[AGENCY_FUNDING10_1_FUNDER_TYPE]'
    +' ,[AGENCY_FUNDING11_1_FUNDER_TYPE]'
    +' ,[AGENCY_FUNDING12_1_FUNDER_TYPE]'
    +' ,[AGENCY_FUNDING13_1_FUNDER_TYPE]'
    +' ,[AGENCY_FUNDING14_1_FUNDER_TYPE]'
    +' ,[AGENCY_FUNDING15_1_FUNDER_TYPE]'
    +' ,[AGENCY_FUNDING16_1_FUNDER_TYPE]'
    +' ,[AGENCY_FUNDING17_1_FUNDER_TYPE]'
    +' ,[AGENCY_FUNDING18_1_FUNDER_TYPE]'
    +' ,[AGENCY_FUNDING19_1_FUNDER_TYPE]'
    +' ,[AGENCY_FUNDING20_1_FUNDER_TYPE]'
    +' ,[AGENCY_FUNDING01_1_DF_GRANT_TYPE]'
    +' ,[AGENCY_FUNDING02_1_DF_GRANT_TYPE]'
    +' ,[AGENCY_FUNDING03_1_DF_GRANT_TYPE]'
    +' ,[AGENCY_FUNDING04_1_DF_GRANT_TYPE]'
    +' ,[AGENCY_FUNDING05_1_DF_GRANT_TYPE]'
    +' ,[AGENCY_FUNDING06_1_DF_GRANT_TYPE]'
    +' ,[AGENCY_FUNDING07_1_DF_GRANT_TYPE]'
    +' ,[AGENCY_FUNDING08_1_DF_GRANT_TYPE]'
    +' ,[AGENCY_FUNDING09_1_DF_GRANT_TYPE]'
    +' ,[AGENCY_FUNDING10_1_DF_GRANT_TYPE]'
    +' ,[AGENCY_FUNDING11_1_DF_GRANT_TYPE]'
    +' ,[AGENCY_FUNDING12_1_DF_GRANT_TYPE]'
    +' ,[AGENCY_FUNDING13_1_DF_GRANT_TYPE]'
    +' ,[AGENCY_FUNDING14_1_DF_GRANT_TYPE]'
    +' ,[AGENCY_FUNDING15_1_DF_GRANT_TYPE]'
    +' ,[AGENCY_FUNDING16_1_DF_GRANT_TYPE]'
    +' ,[AGENCY_FUNDING17_1_DF_GRANT_TYPE]'
    +' ,[AGENCY_FUNDING18_1_DF_GRANT_TYPE]'
    +' ,[AGENCY_FUNDING19_1_DF_GRANT_TYPE]'
    +' ,[AGENCY_FUNDING20_1_DF_GRANT_TYPE]'
    +' ,[AGENCY_FUNDING01_1_AMOUNT]'
    +' ,[AGENCY_FUNDING02_1_AMOUNT]'
    +' ,[AGENCY_FUNDING03_1_AMOUNT]'
    +' ,[AGENCY_FUNDING04_1_AMOUNT]'
    +' ,[AGENCY_FUNDING05_1_AMOUNT]'
    +' ,[AGENCY_FUNDING06_1_AMOUNT]'
    +' ,[AGENCY_FUNDING07_1_AMOUNT]'
    +' ,[AGENCY_FUNDING08_1_AMOUNT]'
    +' ,[AGENCY_FUNDING09_1_AMOUNT]'
    +' ,[AGENCY_FUNDING10_1_AMOUNT]'
    +' ,[AGENCY_FUNDING11_1_AMOUNT]'
    +' ,[AGENCY_FUNDING12_1_AMOUNT]'
    +' ,[AGENCY_FUNDING13_1_AMOUNT]'
    +' ,[AGENCY_FUNDING14_1_AMOUNT]'
    +' ,[AGENCY_FUNDING15_1_AMOUNT]'
    +' ,[AGENCY_FUNDING16_1_AMOUNT]'
    +' ,[AGENCY_FUNDING17_1_AMOUNT]'
    +' ,[AGENCY_FUNDING18_1_AMOUNT]'
    +' ,[AGENCY_FUNDING19_1_AMOUNT]'
    +' ,[AGENCY_FUNDING20_1_AMOUNT]'
    +', [Master_SurveyID]'
    +' ,[DW_AuditDate])'

    set @SQL2 = '
     SELECT  DW_SurveyResponseID as SurveyResponseID, ''' +@p_datasource +''''
    +' ,1'
    +' ,Atbl.[SurveyID]'
    +' ,Atbl.[SurveyDate]'
    +' ,Atbl.[AuditDate]'
    +' ,cxref1.Client_ID'  --xref from [CL_EN_GEN_ID]
    +' ,Atbl.[SiteID]'
    +' ,Atbl.[ProgramID]'
    +' ,Atbl.[IA_StaffID]'
    +' ,cxref2.Client_ID'  --xref from [ClientID]
    +' ,Atbl.[RespondentID]'
    +' ,Atbl.[Entity_ID_Mapped]'
    +' ,Atbl.[AGENCY_RESEARCH_0_INVOLVEMENT]'
    +' ,Atbl.[AGENCY_RESEARCH01_1_PI1]'
    +' ,Atbl.[AGENCY_RESEARCH01_0_PROJECT_NAME]'
    +' ,Atbl.[AGENCY_RESEARCH01_1_PROJECT_DESCRIPTION]'
    +' ,Atbl.[AGENCY_RESEARCH01_1_START_DATE]'
    +' ,Atbl.[AGENCY_RESEARCH01_1_END_DATE]'
    +' ,Atbl.[AGENCY_RESEARCH01_1_APPROVAL]'
    +' ,Atbl.[AGENCY_INFO_1_FUNDED_CAPACITY_FTE]'
    +' ,Atbl.[AGENCY_INFO_1_CONTRACT_CAPACITY_FTE]'
    +' ,Atbl.[AGENCY_INFO_BOARD_0_MEETING_DATE01]'
    +' ,Atbl.[AGENCY_INFO_BOARD_0_MEETING_DATE02]'
    +' ,Atbl.[AGENCY_INFO_BOARD_0_MEETING_DATE03]'
    +' ,Atbl.[AGENCY_INFO_BOARD_0_MEETING_DATE04]'
    +' ,Atbl.[AGENCY_FUNDING01_0_FUNDER_NAME]'
    +' ,Atbl.[AGENCY_FUNDING02_0_FUNDER_NAME]'
    +' ,Atbl.[AGENCY_FUNDING03_0_FUNDER_NAME]'
    +' ,Atbl.[AGENCY_FUNDING04_0_FUNDER_NAME]'
    +' ,Atbl.[AGENCY_FUNDING05_0_FUNDER_NAME]'
    +' ,Atbl.[AGENCY_FUNDING06_0_FUNDER_NAME]'
    +' ,Atbl.[AGENCY_FUNDING07_0_FUNDER_NAME]'
    +' ,Atbl.[AGENCY_FUNDING08_0_FUNDER_NAME]'
    +' ,Atbl.[AGENCY_FUNDING10_0_FUNDER_NAME]'
    +' ,Atbl.[AGENCY_FUNDING11_0_FUNDER_NAME]'
    +' ,Atbl.[AGENCY_FUNDING12_0_FUNDER_NAME]'
    +' ,Atbl.[AGENCY_FUNDING13_0_FUNDER_NAME]'
    +' ,Atbl.[AGENCY_FUNDING14_0_FUNDER_NAME]'
    +' ,Atbl.[AGENCY_FUNDING15_0_FUNDER_NAME]'
    +' ,Atbl.[AGENCY_FUNDING16_0_FUNDER_NAME]'
    +' ,Atbl.[AGENCY_FUNDING17_0_FUNDER_NAME]'
    +' ,Atbl.[AGENCY_FUNDING09_0_FUNDER_NAME]'
    +' ,Atbl.[AGENCY_FUNDING18_0_FUNDER_NAME]'
    +' ,Atbl.[AGENCY_FUNDING19_0_FUNDER_NAME]'
    +' ,Atbl.[AGENCY_FUNDING20_0_FUNDER_NAME]'
    +' ,Atbl.[AGENCY_FUNDING01_1_START_DATE]'
    +' ,Atbl.[AGENCY_FUNDING02_1_START_DATE]'
    +' ,Atbl.[AGENCY_FUNDING03_1_START_DATE]'
    +' ,Atbl.[AGENCY_FUNDING04_1_START_DATE]'
    +' ,Atbl.[AGENCY_FUNDING05_1_START_DATE]'
    +' ,Atbl.[AGENCY_FUNDING06_1_START_DATE]'
    +' ,Atbl.[AGENCY_FUNDING07_1_START_DATE]'
    +' ,Atbl.[AGENCY_FUNDING08_1_START_DATE]'
    +' ,Atbl.[AGENCY_FUNDING09_1_START_DATE]'
    +' ,Atbl.[AGENCY_FUNDING10_1_START_DATE]'
    +' ,Atbl.[AGENCY_FUNDING11_1_START_DATE]'
    +' ,Atbl.[AGENCY_FUNDING12_1_START_DATE]'
    +' ,Atbl.[AGENCY_FUNDING13_1_START_DATE]'
    +' ,Atbl.[AGENCY_FUNDING14_1_START_DATE]'
    +' ,Atbl.[AGENCY_FUNDING15_1_START_DATE]'
    +' ,Atbl.[AGENCY_FUNDING16_1_START_DATE]'
    +' ,Atbl.[AGENCY_FUNDING17_1_START_DATE]'
    +' ,Atbl.[AGENCY_FUNDING18_1_START_DATE]'
    +' ,Atbl.[AGENCY_FUNDING19_1_START_DATE]'
    +' ,Atbl.[AGENCY_FUNDING20_1_START_DATE]'
    +' ,Atbl.[AGENCY_FUNDING01_1_END_DATE]'
    +' ,Atbl.[AGENCY_FUNDING02_1_END_DATE]'
    +' ,Atbl.[AGENCY_FUNDING03_1_END_DATE]'
    +' ,Atbl.[AGENCY_FUNDING04_1_END_DATE]'
    +' ,Atbl.[AGENCY_FUNDING05_1_END_DATE]'
    +' ,Atbl.[AGENCY_FUNDING06_1_END_DATE]'
    +' ,Atbl.[AGENCY_FUNDING07_1_END_DATE]'
    +' ,Atbl.[AGENCY_FUNDING08_1_END_DATE]'
    +' ,Atbl.[AGENCY_FUNDING09_1_END_DATE]'
    +' ,Atbl.[AGENCY_FUNDING10_1_END_DATE]'
    +' ,Atbl.[AGENCY_FUNDING11_1_END_DATE]'
    +' ,Atbl.[AGENCY_FUNDING12_1_END_DATE]'
    +' ,Atbl.[AGENCY_FUNDING13_1_END_DATE]'
    +' ,Atbl.[AGENCY_FUNDING14_1_END_DATE]'
    +' ,Atbl.[AGENCY_FUNDING15_1_END_DATE]'
    +' ,Atbl.[AGENCY_FUNDING16_1_END_DATE]'
    +' ,Atbl.[AGENCY_FUNDING17_1_END_DATE]'
    +' ,Atbl.[AGENCY_FUNDING18_1_END_DATE]'
    +' ,Atbl.[AGENCY_FUNDING19_1_END_DATE]'
    +' ,Atbl.[AGENCY_FUNDING20_1_END_DATE]'
    +' ,Atbl.[AGENCY_FUNDING01_1_FUNDER_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING02_1_FUNDER_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING03_1_FUNDER_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING04_1_FUNDER_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING05_1_FUNDER_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING06_1_FUNDER_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING07_1_FUNDER_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING08_1_FUNDER_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING09_1_FUNDER_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING10_1_FUNDER_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING11_1_FUNDER_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING12_1_FUNDER_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING13_1_FUNDER_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING14_1_FUNDER_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING15_1_FUNDER_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING16_1_FUNDER_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING17_1_FUNDER_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING18_1_FUNDER_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING19_1_FUNDER_TYPE]'

    set @SQL3 = '
       ,Atbl.[AGENCY_FUNDING20_1_FUNDER_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING01_1_DF_GRANT_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING02_1_DF_GRANT_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING03_1_DF_GRANT_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING04_1_DF_GRANT_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING05_1_DF_GRANT_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING06_1_DF_GRANT_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING07_1_DF_GRANT_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING08_1_DF_GRANT_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING09_1_DF_GRANT_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING10_1_DF_GRANT_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING11_1_DF_GRANT_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING12_1_DF_GRANT_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING13_1_DF_GRANT_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING14_1_DF_GRANT_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING15_1_DF_GRANT_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING16_1_DF_GRANT_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING17_1_DF_GRANT_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING18_1_DF_GRANT_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING19_1_DF_GRANT_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING20_1_DF_GRANT_TYPE]'
    +' ,Atbl.[AGENCY_FUNDING01_1_AMOUNT]'
    +' ,Atbl.[AGENCY_FUNDING02_1_AMOUNT]'
    +' ,Atbl.[AGENCY_FUNDING03_1_AMOUNT]'
    +' ,Atbl.[AGENCY_FUNDING04_1_AMOUNT]'
    +' ,Atbl.[AGENCY_FUNDING05_1_AMOUNT]'
    +' ,Atbl.[AGENCY_FUNDING06_1_AMOUNT]'
    +' ,Atbl.[AGENCY_FUNDING07_1_AMOUNT]'
    +' ,Atbl.[AGENCY_FUNDING08_1_AMOUNT]'
    +' ,Atbl.[AGENCY_FUNDING09_1_AMOUNT]'
    +' ,Atbl.[AGENCY_FUNDING10_1_AMOUNT]'
    +' ,Atbl.[AGENCY_FUNDING11_1_AMOUNT]'
    +' ,Atbl.[AGENCY_FUNDING12_1_AMOUNT]'
    +' ,Atbl.[AGENCY_FUNDING13_1_AMOUNT]'
    +' ,Atbl.[AGENCY_FUNDING14_1_AMOUNT]'
    +' ,Atbl.[AGENCY_FUNDING15_1_AMOUNT]'
    +' ,Atbl.[AGENCY_FUNDING16_1_AMOUNT]'
    +' ,Atbl.[AGENCY_FUNDING17_1_AMOUNT]'
    +' ,Atbl.[AGENCY_FUNDING18_1_AMOUNT]'
    +' ,Atbl.[AGENCY_FUNDING19_1_AMOUNT]'
    +' ,Atbl.[AGENCY_FUNDING20_1_AMOUNT]'
    +', ms.SourceSurveyID'
    +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.AGENCY_PROFILE_Survey Atbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' left join dbo.Non_ETO_Client_Xref cxref1 on cxref1.Source =  ''' +@p_datasource +''''
    +'   and cxref1.Non_ETO_ID = Atbl.CL_EN_GEN_ID' 
    +' left join dbo.Non_ETO_Client_Xref cxref2 on cxref2.Source =  ''' +@p_datasource +''''
    +'   and cxref2.Non_ETO_ID = Atbl.ClientID'  
    +' left join dbo.Mstr_Surveys ms on Atbl.SurveyID = ms.SurveyID'
    +' where Atbl.DW_SurveyResponseID is not null'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'
    +' and not exists (select dwsurvey.SurveyResponseID'
    +' from dbo.AGENCY_PROFILE_Survey dwsurvey'
    +' where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and dwsurvey.SurveyResponseID = Atbl.DW_SurveyResponseID)'
     

    print @SQL1
    print @SQL2
    print @SQL3
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) 
         +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
         +', SQL3 Length = ' +CAST(LEN(@SQL3) as varchar)
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
    +' update dbo.AGENCY_PROFILE_Survey'
    +' Set [SurveyID] = Atbl.[SurveyID]'
    +', [SurveyDate]  = Atbl.[SurveyDate]'
    +', [AuditDate]  = Atbl.[AuditDate]'
    +', [CL_EN_GEN_ID]  = cxref1.Client_ID'  --xref from [CL_EN_GEN_ID]
    +', [SiteID] = Atbl.[SiteID]'
    +', [ProgramID] = Atbl.[ProgramID]'
    +', [IA_StaffID] = Atbl.[IA_StaffID]'
    +', [ClientID] = cxref2.Client_ID'  --xref from [ClientID]
    +', [RespondentID] = Atbl.[RespondentID]'
    +', [Entity_ID_Mapped] = Atbl.[Entity_ID_Mapped]'
    +', [AGENCY_RESEARCH_0_INVOLVEMENT] = Atbl.[AGENCY_RESEARCH_0_INVOLVEMENT]'
    +', [AGENCY_RESEARCH01_1_PI1] = Atbl.[AGENCY_RESEARCH01_1_PI1]'
    +', [AGENCY_RESEARCH01_0_PROJECT_NAME] = Atbl.[AGENCY_RESEARCH01_0_PROJECT_NAME]'
    +', [AGENCY_RESEARCH01_1_PROJECT_DESCRIPTION] = Atbl.[AGENCY_RESEARCH01_1_PROJECT_DESCRIPTION]'
    +', [AGENCY_RESEARCH01_1_START_DATE] = Atbl.[AGENCY_RESEARCH01_1_START_DATE]'
    +', [AGENCY_RESEARCH01_1_END_DATE] = Atbl.[AGENCY_RESEARCH01_1_END_DATE]'
    +', [AGENCY_RESEARCH01_1_APPROVAL] = Atbl.[AGENCY_RESEARCH01_1_APPROVAL]'
    +', [AGENCY_INFO_1_FUNDED_CAPACITY_FTE] = Atbl.[AGENCY_INFO_1_FUNDED_CAPACITY_FTE]'
    +', [AGENCY_INFO_1_CONTRACT_CAPACITY_FTE] = Atbl.[AGENCY_INFO_1_CONTRACT_CAPACITY_FTE]'
    +', [AGENCY_INFO_BOARD_0_MEETING_DATE01] = Atbl.[AGENCY_INFO_BOARD_0_MEETING_DATE01]'
    +', [AGENCY_INFO_BOARD_0_MEETING_DATE02] = Atbl.[AGENCY_INFO_BOARD_0_MEETING_DATE02]'
    +', [AGENCY_INFO_BOARD_0_MEETING_DATE03] = Atbl.[AGENCY_INFO_BOARD_0_MEETING_DATE03]'
    +', [AGENCY_INFO_BOARD_0_MEETING_DATE04] = Atbl.[AGENCY_INFO_BOARD_0_MEETING_DATE04]'
    +', [AGENCY_FUNDING01_0_FUNDER_NAME] = Atbl.[AGENCY_FUNDING01_0_FUNDER_NAME]'
    +', [AGENCY_FUNDING02_0_FUNDER_NAME] = Atbl.[AGENCY_FUNDING02_0_FUNDER_NAME]'
    +', [AGENCY_FUNDING03_0_FUNDER_NAME] = Atbl.[AGENCY_FUNDING03_0_FUNDER_NAME]'
    +', [AGENCY_FUNDING04_0_FUNDER_NAME] = Atbl.[AGENCY_FUNDING04_0_FUNDER_NAME]'
    +', [AGENCY_FUNDING05_0_FUNDER_NAME] = Atbl.[AGENCY_FUNDING05_0_FUNDER_NAME]'
    +', [AGENCY_FUNDING06_0_FUNDER_NAME] = Atbl.[AGENCY_FUNDING06_0_FUNDER_NAME]'
    +', [AGENCY_FUNDING07_0_FUNDER_NAME] = Atbl.[AGENCY_FUNDING07_0_FUNDER_NAME]'
    +', [AGENCY_FUNDING08_0_FUNDER_NAME] = Atbl.[AGENCY_FUNDING08_0_FUNDER_NAME]'
    +', [AGENCY_FUNDING09_0_FUNDER_NAME] = Atbl.[AGENCY_FUNDING09_0_FUNDER_NAME]'
    +', [AGENCY_FUNDING10_0_FUNDER_NAME] = Atbl.[AGENCY_FUNDING10_0_FUNDER_NAME]'
    +', [AGENCY_FUNDING11_0_FUNDER_NAME] = Atbl.[AGENCY_FUNDING11_0_FUNDER_NAME]'
    +', [AGENCY_FUNDING12_0_FUNDER_NAME] = Atbl.[AGENCY_FUNDING12_0_FUNDER_NAME]'
    +', [AGENCY_FUNDING13_0_FUNDER_NAME] = Atbl.[AGENCY_FUNDING13_0_FUNDER_NAME]'
    +', [AGENCY_FUNDING14_0_FUNDER_NAME] = Atbl.[AGENCY_FUNDING14_0_FUNDER_NAME]'
    +', [AGENCY_FUNDING15_0_FUNDER_NAME] = Atbl.[AGENCY_FUNDING15_0_FUNDER_NAME]'
    +', [AGENCY_FUNDING16_0_FUNDER_NAME] = Atbl.[AGENCY_FUNDING16_0_FUNDER_NAME]'
    +', [AGENCY_FUNDING17_0_FUNDER_NAME] = Atbl.[AGENCY_FUNDING17_0_FUNDER_NAME]'
    +', [AGENCY_FUNDING18_0_FUNDER_NAME] = Atbl.[AGENCY_FUNDING18_0_FUNDER_NAME]'
    +', [AGENCY_FUNDING19_0_FUNDER_NAME] = Atbl.[AGENCY_FUNDING19_0_FUNDER_NAME]'
    +', [AGENCY_FUNDING20_0_FUNDER_NAME] = Atbl.[AGENCY_FUNDING20_0_FUNDER_NAME]'
    +', [AGENCY_FUNDING01_1_START_DATE] = Atbl.[AGENCY_FUNDING01_1_START_DATE]'
    +', [AGENCY_FUNDING02_1_START_DATE] = Atbl.[AGENCY_FUNDING02_1_START_DATE]'
    +', [AGENCY_FUNDING03_1_START_DATE] = Atbl.[AGENCY_FUNDING03_1_START_DATE]'
    +', [AGENCY_FUNDING04_1_START_DATE] = Atbl.[AGENCY_FUNDING04_1_START_DATE]'
    +', [AGENCY_FUNDING05_1_START_DATE] = Atbl.[AGENCY_FUNDING05_1_START_DATE]'
    +', [AGENCY_FUNDING06_1_START_DATE] = Atbl.[AGENCY_FUNDING06_1_START_DATE]'
    +', [AGENCY_FUNDING07_1_START_DATE] = Atbl.[AGENCY_FUNDING07_1_START_DATE]'
    +', [AGENCY_FUNDING08_1_START_DATE] = Atbl.[AGENCY_FUNDING08_1_START_DATE]'
    +', [AGENCY_FUNDING09_1_START_DATE] = Atbl.[AGENCY_FUNDING09_1_START_DATE]'
    +', [AGENCY_FUNDING10_1_START_DATE] = Atbl.[AGENCY_FUNDING10_1_START_DATE]'
    +', [AGENCY_FUNDING11_1_START_DATE] = Atbl.[AGENCY_FUNDING11_1_START_DATE]'
    +', [AGENCY_FUNDING12_1_START_DATE] = Atbl.[AGENCY_FUNDING12_1_START_DATE]'
    +', [AGENCY_FUNDING13_1_START_DATE] = Atbl.[AGENCY_FUNDING13_1_START_DATE]'
    +', [AGENCY_FUNDING14_1_START_DATE] = Atbl.[AGENCY_FUNDING14_1_START_DATE]'
    +', [AGENCY_FUNDING15_1_START_DATE] = Atbl.[AGENCY_FUNDING15_1_START_DATE]'
    +', [AGENCY_FUNDING16_1_START_DATE] = Atbl.[AGENCY_FUNDING16_1_START_DATE]'
    +', [AGENCY_FUNDING17_1_START_DATE] = Atbl.[AGENCY_FUNDING17_1_START_DATE]'
    +', [AGENCY_FUNDING18_1_START_DATE] = Atbl.[AGENCY_FUNDING18_1_START_DATE]'
    +', [AGENCY_FUNDING19_1_START_DATE] = Atbl.[AGENCY_FUNDING19_1_START_DATE]'
    +', [AGENCY_FUNDING20_1_START_DATE] = Atbl.[AGENCY_FUNDING20_1_START_DATE]'
   
    set @SQL2 ='
      , [AGENCY_FUNDING01_1_END_DATE] = Atbl.[AGENCY_FUNDING01_1_END_DATE]'
    +', [AGENCY_FUNDING02_1_END_DATE] = Atbl.[AGENCY_FUNDING02_1_END_DATE]'
    +', [AGENCY_FUNDING03_1_END_DATE] = Atbl.[AGENCY_FUNDING03_1_END_DATE]'
    +', [AGENCY_FUNDING04_1_END_DATE] = Atbl.[AGENCY_FUNDING04_1_END_DATE]'
    +', [AGENCY_FUNDING05_1_END_DATE] = Atbl.[AGENCY_FUNDING05_1_END_DATE]'
    +', [AGENCY_FUNDING06_1_END_DATE] = Atbl.[AGENCY_FUNDING06_1_END_DATE]'
    +', [AGENCY_FUNDING07_1_END_DATE] = Atbl.[AGENCY_FUNDING07_1_END_DATE]'
    +', [AGENCY_FUNDING08_1_END_DATE] = Atbl.[AGENCY_FUNDING08_1_END_DATE]'
    +', [AGENCY_FUNDING09_1_END_DATE] = Atbl.[AGENCY_FUNDING09_1_END_DATE]'
    +', [AGENCY_FUNDING10_1_END_DATE] = Atbl.[AGENCY_FUNDING10_1_END_DATE]'
    +', [AGENCY_FUNDING11_1_END_DATE] = Atbl.[AGENCY_FUNDING11_1_END_DATE]'
    +', [AGENCY_FUNDING12_1_END_DATE] = Atbl.[AGENCY_FUNDING12_1_END_DATE]'
    +', [AGENCY_FUNDING13_1_END_DATE] = Atbl.[AGENCY_FUNDING13_1_END_DATE]'
    +', [AGENCY_FUNDING14_1_END_DATE] = Atbl.[AGENCY_FUNDING14_1_END_DATE]'
    +', [AGENCY_FUNDING15_1_END_DATE] = Atbl.[AGENCY_FUNDING15_1_END_DATE]'
    +', [AGENCY_FUNDING16_1_END_DATE] = Atbl.[AGENCY_FUNDING16_1_END_DATE]'
    +', [AGENCY_FUNDING17_1_END_DATE] = Atbl.[AGENCY_FUNDING17_1_END_DATE]'
    +', [AGENCY_FUNDING18_1_END_DATE] = Atbl.[AGENCY_FUNDING18_1_END_DATE]'
    +', [AGENCY_FUNDING19_1_END_DATE] = Atbl.[AGENCY_FUNDING19_1_END_DATE]'
    +', [AGENCY_FUNDING20_1_END_DATE] = Atbl.[AGENCY_FUNDING20_1_END_DATE]'
    +', [AGENCY_FUNDING01_1_FUNDER_TYPE] = Atbl.[AGENCY_FUNDING01_1_FUNDER_TYPE]'
    +', [AGENCY_FUNDING02_1_FUNDER_TYPE] = Atbl.[AGENCY_FUNDING02_1_FUNDER_TYPE]'
    +', [AGENCY_FUNDING03_1_FUNDER_TYPE] = Atbl.[AGENCY_FUNDING03_1_FUNDER_TYPE]'
    +', [AGENCY_FUNDING04_1_FUNDER_TYPE] = Atbl.[AGENCY_FUNDING04_1_FUNDER_TYPE]'
    +', [AGENCY_FUNDING05_1_FUNDER_TYPE] = Atbl.[AGENCY_FUNDING05_1_FUNDER_TYPE]'
    +', [AGENCY_FUNDING06_1_FUNDER_TYPE] = Atbl.[AGENCY_FUNDING06_1_FUNDER_TYPE]'
    +', [AGENCY_FUNDING07_1_FUNDER_TYPE] = Atbl.[AGENCY_FUNDING07_1_FUNDER_TYPE]'
    +', [AGENCY_FUNDING08_1_FUNDER_TYPE] = Atbl.[AGENCY_FUNDING08_1_FUNDER_TYPE]'
    +', [AGENCY_FUNDING09_1_FUNDER_TYPE] = Atbl.[AGENCY_FUNDING09_1_FUNDER_TYPE]'
    +', [AGENCY_FUNDING10_1_FUNDER_TYPE] = Atbl.[AGENCY_FUNDING10_1_FUNDER_TYPE]'
    +', [AGENCY_FUNDING11_1_FUNDER_TYPE] = Atbl.[AGENCY_FUNDING11_1_FUNDER_TYPE]'
    +', [AGENCY_FUNDING12_1_FUNDER_TYPE] = Atbl.[AGENCY_FUNDING12_1_FUNDER_TYPE]'
    +', [AGENCY_FUNDING13_1_FUNDER_TYPE] = Atbl.[AGENCY_FUNDING13_1_FUNDER_TYPE]'
    +', [AGENCY_FUNDING14_1_FUNDER_TYPE] = Atbl.[AGENCY_FUNDING14_1_FUNDER_TYPE]'
    +', [AGENCY_FUNDING15_1_FUNDER_TYPE] = Atbl.[AGENCY_FUNDING15_1_FUNDER_TYPE]'
    +', [AGENCY_FUNDING16_1_FUNDER_TYPE] = Atbl.[AGENCY_FUNDING16_1_FUNDER_TYPE]'
    +', [AGENCY_FUNDING17_1_FUNDER_TYPE] = Atbl.[AGENCY_FUNDING17_1_FUNDER_TYPE]'
    +', [AGENCY_FUNDING18_1_FUNDER_TYPE] = Atbl.[AGENCY_FUNDING18_1_FUNDER_TYPE]'
    +', [AGENCY_FUNDING19_1_FUNDER_TYPE] = Atbl.[AGENCY_FUNDING19_1_FUNDER_TYPE]'
    +', [AGENCY_FUNDING20_1_FUNDER_TYPE] = Atbl.[AGENCY_FUNDING20_1_FUNDER_TYPE]'

    set @SQL2 ='
      , [AGENCY_FUNDING01_1_DF_GRANT_TYPE] = Atbl.[AGENCY_FUNDING01_1_DF_GRANT_TYPE]'
    +', [AGENCY_FUNDING02_1_DF_GRANT_TYPE] = Atbl.[AGENCY_FUNDING02_1_DF_GRANT_TYPE]'
    +', [AGENCY_FUNDING03_1_DF_GRANT_TYPE] = Atbl.[AGENCY_FUNDING03_1_DF_GRANT_TYPE]'
    +', [AGENCY_FUNDING04_1_DF_GRANT_TYPE] = Atbl.[AGENCY_FUNDING04_1_DF_GRANT_TYPE]'
    +', [AGENCY_FUNDING05_1_DF_GRANT_TYPE] = Atbl.[AGENCY_FUNDING05_1_DF_GRANT_TYPE]'
    +', [AGENCY_FUNDING06_1_DF_GRANT_TYPE] = Atbl.[AGENCY_FUNDING06_1_DF_GRANT_TYPE]'
    +', [AGENCY_FUNDING07_1_DF_GRANT_TYPE] = Atbl.[AGENCY_FUNDING07_1_DF_GRANT_TYPE]'
    +', [AGENCY_FUNDING08_1_DF_GRANT_TYPE] = Atbl.[AGENCY_FUNDING08_1_DF_GRANT_TYPE]'
    +', [AGENCY_FUNDING09_1_DF_GRANT_TYPE] = Atbl.[AGENCY_FUNDING09_1_DF_GRANT_TYPE]'
    +', [AGENCY_FUNDING10_1_DF_GRANT_TYPE] = Atbl.[AGENCY_FUNDING10_1_DF_GRANT_TYPE]'
    +', [AGENCY_FUNDING11_1_DF_GRANT_TYPE] = Atbl.[AGENCY_FUNDING11_1_DF_GRANT_TYPE]'
    +', [AGENCY_FUNDING12_1_DF_GRANT_TYPE] = Atbl.[AGENCY_FUNDING12_1_DF_GRANT_TYPE]'
    +', [AGENCY_FUNDING13_1_DF_GRANT_TYPE] = Atbl.[AGENCY_FUNDING13_1_DF_GRANT_TYPE]'
    +', [AGENCY_FUNDING14_1_DF_GRANT_TYPE] = Atbl.[AGENCY_FUNDING14_1_DF_GRANT_TYPE]'
    +', [AGENCY_FUNDING15_1_DF_GRANT_TYPE] = Atbl.[AGENCY_FUNDING15_1_DF_GRANT_TYPE]'
    +', [AGENCY_FUNDING16_1_DF_GRANT_TYPE] = Atbl.[AGENCY_FUNDING16_1_DF_GRANT_TYPE]'
    +', [AGENCY_FUNDING17_1_DF_GRANT_TYPE] = Atbl.[AGENCY_FUNDING17_1_DF_GRANT_TYPE]'
    +', [AGENCY_FUNDING18_1_DF_GRANT_TYPE] = Atbl.[AGENCY_FUNDING18_1_DF_GRANT_TYPE]'
    +', [AGENCY_FUNDING19_1_DF_GRANT_TYPE] = Atbl.[AGENCY_FUNDING19_1_DF_GRANT_TYPE]'
    +', [AGENCY_FUNDING20_1_DF_GRANT_TYPE] = Atbl.[AGENCY_FUNDING20_1_DF_GRANT_TYPE]'
    +', [AGENCY_FUNDING01_1_AMOUNT] = Atbl.[AGENCY_FUNDING01_1_AMOUNT]'
    +', [AGENCY_FUNDING02_1_AMOUNT] = Atbl.[AGENCY_FUNDING02_1_AMOUNT]'
    +', [AGENCY_FUNDING03_1_AMOUNT] = Atbl.[AGENCY_FUNDING03_1_AMOUNT]'
    +', [AGENCY_FUNDING04_1_AMOUNT] = Atbl.[AGENCY_FUNDING04_1_AMOUNT]'
    +', [AGENCY_FUNDING05_1_AMOUNT] = Atbl.[AGENCY_FUNDING05_1_AMOUNT]'
    +', [AGENCY_FUNDING06_1_AMOUNT] = Atbl.[AGENCY_FUNDING06_1_AMOUNT]'
    +', [AGENCY_FUNDING07_1_AMOUNT] = Atbl.[AGENCY_FUNDING07_1_AMOUNT]'
    +', [AGENCY_FUNDING08_1_AMOUNT] = Atbl.[AGENCY_FUNDING08_1_AMOUNT]'
    +', [AGENCY_FUNDING09_1_AMOUNT] = Atbl.[AGENCY_FUNDING09_1_AMOUNT]'
    +', [AGENCY_FUNDING10_1_AMOUNT] = Atbl.[AGENCY_FUNDING10_1_AMOUNT]'
    +', [AGENCY_FUNDING11_1_AMOUNT] = Atbl.[AGENCY_FUNDING11_1_AMOUNT]'
    +', [AGENCY_FUNDING12_1_AMOUNT] = Atbl.[AGENCY_FUNDING12_1_AMOUNT]'
    +', [AGENCY_FUNDING13_1_AMOUNT] = Atbl.[AGENCY_FUNDING13_1_AMOUNT]'
    +', [AGENCY_FUNDING14_1_AMOUNT] = Atbl.[AGENCY_FUNDING14_1_AMOUNT]'
    +', [AGENCY_FUNDING15_1_AMOUNT] = Atbl.[AGENCY_FUNDING15_1_AMOUNT]'
    +', [AGENCY_FUNDING16_1_AMOUNT] = Atbl.[AGENCY_FUNDING16_1_AMOUNT]'
    +', [AGENCY_FUNDING17_1_AMOUNT] = Atbl.[AGENCY_FUNDING17_1_AMOUNT]'
    +', [AGENCY_FUNDING18_1_AMOUNT] = Atbl.[AGENCY_FUNDING18_1_AMOUNT]'
    +', [AGENCY_FUNDING19_1_AMOUNT] = Atbl.[AGENCY_FUNDING19_1_AMOUNT]'
    +', [AGENCY_FUNDING20_1_AMOUNT] = Atbl.[AGENCY_FUNDING20_1_AMOUNT]'
    +', [Master_SurveyID] = ms.SourceSurveyID'
    +', [DW_AuditDate] = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from dbo.AGENCY_PROFILE_Survey dwsurvey'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.AGENCY_PROFILE_Survey Atbl'
    +' on dwsurvey.SurveyResponseID = Atbl.DW_SurveyResponseID'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' left join dbo.Non_ETO_Client_Xref cxref1 on cxref1.Source =  ''' +@p_datasource +''''
    +'   and cxref1.Non_ETO_ID = Atbl.CL_EN_GEN_ID' 
    +' left join dbo.Non_ETO_Client_Xref cxref2 on cxref2.Source =  ''' +@p_datasource +''''
    +'   and cxref2.Non_ETO_ID = Atbl.ClientID' 
    +' left join dbo.Mstr_Surveys ms on Atbl.SurveyID = ms.SurveyID'
    +'
     where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'
    +' and isnull(dwsurvey.AuditDate,convert(datetime,''19700101'',112)) <'
    +' isnull(Atbl.AuditDate,convert(datetime,''19700101'',112))'


    print @SQL1
    print @SQL2
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) 
         +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
    EXEC (@SQL1+@SQL2)



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

print 'End of Process: SP_AGENCYDB_AGENCY_PROFILE_SURVEY'
GO
