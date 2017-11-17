USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_TEAM_MEETING_CONF_SURVEY]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_TEAM_MEETING_CONF_SURVEY
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_TEAM_MEETING_CONF_SURVEY]
 (@p_datasource      nvarchar(10) = null
 ,@p_SurveyResponseID       int = null)
AS
--
-- This script controls integration of AgencyDB Surveys to the Data Warehouse 
-- TEAM_MEETING_CONF_SURVEY table.
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
--   20130401 - New Procedure.

DECLARE @count        smallint
DECLARE @stop_flag  nvarchar(2)
DECLARE @Process      nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)

set @process = 'SP_AGENCYDB_TEAM_MEETING_CONF_SURVEY'
set @DW_Tablename = 'TEAM_MEETING_CONF_SURVEY'
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)
DECLARE @SQL1            nvarchar(MAX)
DECLARE @SQL2            nvarchar(MAX)
DECLARE @SQL3            nvarchar(MAX)

print 'Processing SP_AGENCYDB_TEAM_MEETING_CONF_SURVEY: Datasource = ' +isnull(@p_datasource,'NULL')
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
   print 'Processing SP_AGENCYDB_IA_STAFF - Validate datasource DBSrvr from LOV tables'

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

-- create non_ETO xref entries for new SurveyResponse records from AgencyDB:
set @SQL = 'set nocount off '+
    ' insert into dbo.Non_ETO_SurveyResponse_Xref'
    +' (Non_ETO_ID, Non_ETO_Site_ID, Source, DW_TableName)'
    +'
     select SurveyResponseID, Atbl.SiteID, ''' +@p_datasource +''''  +',''' +@DW_TableName +''''
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.TEAM_MEETING_CONF_SURVEY Atbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' where not exists (select dwxref.SurveyResponseID'
    +' from dbo.Non_ETO_SurveyResponse_Xref dwxref'
    +' where dwxref.source = ''' +@p_datasource +''''
    +' and dwxref.Non_ETO_ID = Atbl.SurveyResponseID'
    +' and dwxref.DW_tableName = ''' +@DW_TableName +''''
    +'   and dwxref.Non_ETO_Site_ID = atbl.SiteID)'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'

    print @SQL
    --EXEC (@SQL)


-- Assign new NON-ETO xref ID to new records from AgencyDB:
print 'Updating AgencyDB source table with DW xref indexes'
set @SQL = 'set nocount off '+
    'update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.TEAM_MEETING_CONF_SURVEY'
    +' Set [DW_SurveyResponseID] = dwxref.[SurveyResponseID]'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.TEAM_MEETING_CONF_SURVEY Atbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' inner join dbo.Non_ETO_SurveyResponse_Xref dwxref'
    +' on dwxref.Non_ETO_ID = Atbl.SurveyResponseID and dwxref.source = ''' +@p_datasource +''''
    +' and dwxref.DW_tableName = ''' +@DW_TableName +''''
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'

    print @SQL
    --EXEC (@SQL)



set @SQL1 = 'set nocount off'
    +' insert into dbo.TEAM_MEETING_CONF_SURVEY'
    +' ([SurveyResponseID],[DataSource],[ElementsProcessed]'
    +' ,[SurveyID]'
    +' ,[SurveyDate]'
    +' ,[AuditDate]'
    +' ,[CL_EN_GEN_ID]'
    +' ,[SiteID]'
    +' ,[ProgramID]'
    +' ,[IA_StaffID]'
    +' ,[ClientID]'
    --+' ,[RespondentID]'
    --+' ,[Entity_ID_Mapped]'
    +' ,[AGENCY_MEETING_0_TYPE]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE1]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE10]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE2]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE3]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE4]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE5]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE6]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE7]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE8]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE9]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF1]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF10]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF2]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF3]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF4]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF5]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF6]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF7]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF8]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_NONSTAFF9]'
    +' ,[AGENCY_MEETING_1_LENGTH]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF1]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF10]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF11]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF12]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF13]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF14]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF15]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF16]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF17]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF18]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF19]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF2]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF20]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF3]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF4]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF5]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF6]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF7]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF8]'
    +' ,[AGENCY_MEETING_1_ATTENDEES_STAFF9]'
    +' ,[DW_AuditDate])'
    +'
     SELECT  DW_SurveyResponseID as SurveyResponseID, ''' +@p_datasource +''''
    +' ,1'
    +' ,Atbl.[SurveyID]'
    +' ,Atbl.[SurveyDate]'
    +' ,Atbl.[AuditDate]'
    +' ,cxref1.Client_ID'
    +' ,Atbl.[SiteID]'
    +' ,Atbl.[ProgramID]'
    +' ,Atbl.[IA_StaffID]'
    +' ,cxref2.Client_ID'
    --+' ,Atbl.[RespondentID]'
    --+' ,Atbl.[Entity_ID_Mapped]'
    +' ,Atbl.[AGENCY_MEETING_0_TYPE]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE1]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE10]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE2]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE3]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE4]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE5]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE6]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE7]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE8]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF_ROLE9]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF1]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF10]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF2]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF3]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF4]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF5]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF6]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF7]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF8]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_NONSTAFF9]'
    +' ,Atbl.[AGENCY_MEETING_1_LENGTH]'

set @SQL2 = '
     ,dbo.Get_Non_ETO_Xref(''Non_ETO_entity_Xref'',''OKLAHOMA'',''DW'',Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF1],NULL) '
    +'   as ATTENDEES_STAFF1'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF10]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF11]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF12]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF13]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF14]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF15]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF16]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF17]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF18]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF19]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF2]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF20]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF3]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF4]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF5]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF6]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF7]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF8]'
    +' ,Atbl.[AGENCY_MEETING_1_ATTENDEES_STAFF9]'
    +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.TEAM_MEETING_CONF_SURVEY Atbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' where Atbl.DW_SurveyResponseID is not null'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'
    +' and not exists (select dwsurvey.SurveyResponseID'
    +' from dbo.TEAM_MEETING_CONF_SURVEY dwsurvey'
    +' where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and dwsurvey.SurveyResponseID = Atbl.DW_SurveyResponseID)'
     

    print @SQL1 
    print @SQL2
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar)
    --EXEC (@SQL1+@SQL2)

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

set @SQL = 'set nocount off'
    +' update dbo.TEAM_MEETING_CONF_SURVEY'
    +' Set [SurveyID] = Atbl.[SurveyID]'    
    +', [SurveyDate] = Atbl.[SurveyDate]'
    +', [AuditDate] = Atbl.[AuditDate]'
    +', [CL_EN_GEN_ID] = cxref1.Client_ID'
    +', [SiteID] = Atbl.[SiteID]'
    +', [ProgramID] = Atbl.[ProgramID]'
    +', [IA_StaffID] = Atbl.[IA_StaffID]'
    +', [ClientID] = cxref2.Client_ID'
    +', [RespondentID] = Atbl.[RespondentID]'
    --+', [CLIENT_PERSONAL_0_NAME_FIRST] = Atbl.[CLIENT_PERSONAL_0_NAME_FIRST]'
    +', [CLIENT_PERSONAL_0_NAME_LAST] = Atbl.[CLIENT_PERSONAL_0_NAME_LAST]'
    +', [CLIENT_PERSONAL_0_DOB_INTAKE] = Atbl.[CLIENT_PERSONAL_0_DOB_INTAKE]'
    +', [CLIENT_EPDS_1_ABLE_TO_LAUGH] = Atbl.[CLIENT_EPDS_1_ABLE_TO_LAUGH]'
    +', [CLIENT_EPDS_1_ENJOY_THINGS] = Atbl.[CLIENT_EPDS_1_ENJOY_THINGS]'
    +', [CLIENT_EPDS_1_BLAME_SELF] = Atbl.[CLIENT_EPDS_1_BLAME_SELF]'
    +', [CLIENT_EPDS_1_ANXIOUS_WORRIED] = Atbl.[CLIENT_EPDS_1_ANXIOUS_WORRIED]'
    +', [CLIENT_EPDS_1_SCARED_PANICKY] = Atbl.[CLIENT_EPDS_1_SCARED_PANICKY]'
    +', [CLIENT_EPDS_1_THINGS_GETTING_ON_TOP] = Atbl.[CLIENT_EPDS_1_THINGS_GETTING_ON_TOP]'
    +', [CLIENT_EPDS_1_DIFFICULTY_SLEEPING] = Atbl.[CLIENT_EPDS_1_DIFFICULTY_SLEEPING]'
    +', [CLIENT_EPDS_1_SAD_MISERABLE] = Atbl.[CLIENT_EPDS_1_SAD_MISERABLE]'
    +', [CLIENT_EPDS_1_BEEN_CRYING] = Atbl.[CLIENT_EPDS_1_BEEN_CRYING]'
    +', [CLIENT_EPDS_1_HARMING_SELF] = Atbl.[CLIENT_EPDS_1_HARMING_SELF]'
    +', [CLIENT_0_ID_NSO] = Atbl.[CLIENT_0_ID_NSO]'
    +', [NURSE_PERSONAL_0_NAME]= exref1.Entity_ID'
    +', [CLIENT_0_ID_AGENCY] = Atbl.[CLIENT_0_ID_AGENCY]'
    +', [LA_CTY_OQ10_EDPS] = Atbl.[LA_CTY_OQ10_EDPS]'
    +', [LA_CTY_PHQ9_SCORE_EDPS] = Atbl.[LA_CTY_PHQ9_SCORE_EDPS]'
    +', [LA_CTY_STRESS_INDEX_EDPS] = Atbl.[LA_CTY_STRESS_INDEX_EDPS]'
    +', [CLIENT_EPS_TOTAL_SCORE] = Atbl.[CLIENT_EPS_TOTAL_SCORE]'
    +', [DW_AuditDate] = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from dbo.TEAM_MEETING_CONF_SURVEY dwsurvey'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.TEAM_MEETING_CONF_SURVEY Atbl'
    +' on dwsurvey.SurveyResponseID = Atbl.DW_SurveyResponseID'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' left join dbo.Non_ETO_Client_Xref cxref1 on cxref1.Source =  ''' +@p_datasource +''''
    +'   and cxref1.Non_ETO_ID = Atbl.CL_EN_GEN_ID' 
    +' left join dbo.Non_ETO_Client_Xref cxref2 on cxref2.Source =  ''' +@p_datasource +''''
    +'   and cxref2.Non_ETO_ID = Atbl.ClientID' 
    +' left join dbo.Non_ETO_Entity_Xref exref1 on exref1.Source =  ''' +@p_datasource +''''
    +'   and exref1.Non_ETO_ID = Atbl.NURSEID' 
    +'
     where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'
    +' and isnull(dwsurvey.AuditDate,convert(datetime,''19700101'',112)) <'
    +' isnull(Atbl.AuditDate,convert(datetime,''19700101'',112))'

    print @SQL
    --EXEC (@SQL)



----------------------------------------------------------------------------------------
print 'Cont: Delete Contacts that no longer exist in AgencyDB'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Deleting ETO Deletions'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL ='set nocount off '+
    ' delete dbo.TEAM_MEETING_CONF_SURVEY'
    +' from dbo.TEAM_MEETING_CONF_SURVEY dwsurvey'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = dwsurvey.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' where dwsurvey.DataSource = ''' +@p_datasource +''''
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', dwsurvey.SiteID) is null'
    +' and not exists (select Atbl.DW_SurveyResponseID'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.TEAM_MEETING_CONF_SURVEY Atbl'
    +' where DW_SurveyResponseID = dwsurvey.SurveyResponseID)'

    print @SQL
    --EXEC (@SQL)


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
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.TEAM_MEETING_CONF_SURVEY Atbl'
    +' where SurveyResponseID = dwxref.Non_ETO_ID)'

    +' and not exists (select dwsurvey.SurveyResponseID'
    +' from dbo.TEAM_MEETING_CONF_SURVEY dwsurvey'
    +' where dwsurvey.SurveyResponseID = dwxref.SurveyResponseID)'

    print @SQL
    --EXEC (@SQL)

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

print 'End of Process: SP_AGENCYDB_TEAM_MEETING_CONF_SURVEY'
GO
