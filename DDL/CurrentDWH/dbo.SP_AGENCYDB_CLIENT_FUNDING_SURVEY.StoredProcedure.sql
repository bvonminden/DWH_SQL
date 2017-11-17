USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_CLIENT_FUNDING_SURVEY]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_CLIENT_FUNDING_SURVEY
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_CLIENT_FUNDING_SURVEY]
 (@p_datasource      nvarchar(10) = null
 ,@p_no_delete_opt   nvarchar(2)  = null)
AS
--
-- This script controls integration of AgencyDB Surveys to the Data Warehouse 
-- CLIENT_FUNDING_SURVEY table.
--
-- Will exclude from DW if Site Does not exist in dbo.agencies
--
-- Table effected - dbo.Client_Funding_Survey
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
--   20140818 - New Procedure.
--   20140930 - Changed to utilize the ETO SurveyResponse record if found, 
--              creating the xref from the client-defined ID mapping to the orig ETO_SurveyResponseID
--              Else if not identified: create new xref record with next available Non_Entity_ID in sequence.
--   20140930 - Added option to not delete records.  This is to accommodate initial AgencyDB loads 
--              of smaller incremented batches while Agecncy is cleaning up data.  Option is 'Y' to inhibit delete.
--    ** compiled and run, but not tested with data: no AgencyDB databases contain data as of 8/27/2014.
--   20151112 - Amended for additional columns.
--   20160929 - Setup new pseudonyms for the Oct 2016 ETO release.  Retired columns will still be applied for history.
--   20161114 - Moved the preliminary Non_ETO_SurveyResponse_xref processing to a common sub procedure for AgencyDB processing
--              named: dbo.SP_AGENCYDB_Survey_Non_ETO_Xref_Process.
--   20170629 - Added additional conditional logic to match siteid when looking up xrefs to entities and clients,
--              to accommodate multiple sites within the same AgencyDB, using same numbering scheme between sites.
--              Expanded the update statement to use multiple SQL variables (exceeding 4000).

DECLARE @count          smallint
DECLARE @stop_flag      nvarchar(2)
DECLARE @Process        nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @DW_TableName   nvarchar(50)
DECLARE @Agency_TableName        nvarchar(50)
DECLARE @Agency_Full_TableName   nvarchar(100)

set @process          = 'SP_AGENCYDB_CLIENT_FUNDING_SURVEY'
set @DW_Tablename     = 'CLIENT_FUNDING_SURVEY'
set @Agency_Tablename = 'CLIENT_FUNDING_SURVEY'
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)
DECLARE @SQL1            varchar(MAX)
DECLARE @SQL2            varchar(MAX)
DECLARE @SQL3            varchar(MAX)

print 'Processing SP_AGENCYDB_CLIENT_FUNDING_SURVEY: Datasource = ' +isnull(@p_datasource,'NULL')
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

exec dbo.SP_AGENCYDB_Survey_Non_ETO_Xref_Process @process, @p_datasource, @DW_TableName, @Agency_Full_TableName, 'N'


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
    +' insert into dbo.CLIENT_FUNDING_SURVEY'
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
    +', [CLIENT_FUNDING_0_SOURCE_MIECHVP_COM]'
    +', [CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM]'
    +', [CLIENT_FUNDING_0_SOURCE_OTHER]'
    +', [CLIENT_FUNDING_0_SOURCE_OTHER_TXT]'
    +', [CLIENT_FUNDING_1_END_MIECHVP_COM]'
    +', [CLIENT_FUNDING_1_END_MIECHVP_FORM]'
    +', [CLIENT_FUNDING_1_END_OTHER]'
    +', [CLIENT_FUNDING_1_START_MIECHVP_COM]'
    +', [CLIENT_FUNDING_1_START_MIECHVP_FORM]'
    +', [CLIENT_FUNDING_1_START_OTHER]'
    +', [CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL]'
    +', [CLIENT_FUNDING_1_END_MIECHVP_TRIBAL]'
    +', [CLIENT_FUNDING_1_START_MIECHVP_TRIBAL]'
    +', [CLIENT_FUNDING_0_SOURCE_OTHER1]'
    +', [CLIENT_FUNDING_0_SOURCE_OTHER2]'
    +', [CLIENT_FUNDING_0_SOURCE_OTHER3]'
    +', [CLIENT_FUNDING_1_END_OTHER1]'
    +', [CLIENT_FUNDING_1_END_OTHER2]'
    +', [CLIENT_FUNDING_1_END_OTHER3]'
    +', [CLIENT_FUNDING_1_START_OTHER1]'
    +', [CLIENT_FUNDING_1_START_OTHER2]'
    +', [CLIENT_FUNDING_1_START_OTHER3]'
    +', [CLIENT_FUNDING_0_SOURCE_PFS]'
    +', [CLIENT_FUNDING_1_START_PFS]'
    +', [CLIENT_FUNDING_1_END_PFS]'
    +', [NURSE_PERSONAL_0_NAME]'
-- October 2016 ETO Release:
    +', [CLIENT_FUNDING_0_SOURCE_OTHER4]'
    +', [CLIENT_FUNDING_1_START_OTHER4]'
    +', [CLIENT_FUNDING_1_END_OTHER4]'
    +', [CLIENT_FUNDING_0_SOURCE_OTHER5]'
    +', [CLIENT_FUNDING_1_START_OTHER5]'
    +', [CLIENT_FUNDING_1_END_OTHER5]'
    +', [CLIENT_FUNDING_0_SOURCE_OTHER6]'
    +', [CLIENT_FUNDING_1_START_OTHER6]'
    +', [CLIENT_FUNDING_1_END_OTHER6]'
-- Integration set columns:
    +', [DW_AuditDate])'
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
    +', Atbl.[CLIENT_FUNDING_0_SOURCE_MIECHVP_COM]'
    +', Atbl.[CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM]'
    +', Atbl.[CLIENT_FUNDING_0_SOURCE_OTHER]'
    +', Atbl.[CLIENT_FUNDING_0_SOURCE_OTHER_TXT]'
    +', Atbl.[CLIENT_FUNDING_1_END_MIECHVP_COM]'
    +', Atbl.[CLIENT_FUNDING_1_END_MIECHVP_FORM]'
    +', Atbl.[CLIENT_FUNDING_1_END_OTHER]'
    +', Atbl.[CLIENT_FUNDING_1_START_MIECHVP_COM]'
    +', Atbl.[CLIENT_FUNDING_1_START_MIECHVP_FORM]'
    +', Atbl.[CLIENT_FUNDING_1_START_OTHER]'
    +', Atbl.[CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL]'
    +', Atbl.[CLIENT_FUNDING_1_END_MIECHVP_TRIBAL]'
    +', Atbl.[CLIENT_FUNDING_1_START_MIECHVP_TRIBAL]'
    +', Atbl.[CLIENT_FUNDING_0_SOURCE_OTHER1]'
    +', Atbl.[CLIENT_FUNDING_0_SOURCE_OTHER2]'
    +', Atbl.[CLIENT_FUNDING_0_SOURCE_OTHER3]'
    +', Atbl.[CLIENT_FUNDING_1_END_OTHER1]'
    +', Atbl.[CLIENT_FUNDING_1_END_OTHER2]'
    +', Atbl.[CLIENT_FUNDING_1_END_OTHER3]'
    +', Atbl.[CLIENT_FUNDING_1_START_OTHER1]'
    +', Atbl.[CLIENT_FUNDING_1_START_OTHER2]'
    +', Atbl.[CLIENT_FUNDING_1_START_OTHER3]'
    +', Atbl.[CLIENT_FUNDING_0_SOURCE_PFS]'
    +', Atbl.[CLIENT_FUNDING_1_START_PFS]'
    +', Atbl.[CLIENT_FUNDING_1_END_PFS]'
    +', exref1.Entity_ID'
-- October 2016 ETO Release:
    +', Atbl.[CLIENT_FUNDING_0_SOURCE_OTHER4]'
    +', Atbl.[CLIENT_FUNDING_1_START_OTHER4]'
    +', Atbl.[CLIENT_FUNDING_1_END_OTHER4]'
    +', Atbl.[CLIENT_FUNDING_0_SOURCE_OTHER5]'
    +', Atbl.[CLIENT_FUNDING_1_START_OTHER5]'
    +', Atbl.[CLIENT_FUNDING_1_END_OTHER5]'
    +', Atbl.[CLIENT_FUNDING_0_SOURCE_OTHER6]'
    +', Atbl.[CLIENT_FUNDING_1_START_OTHER6]'
    +', Atbl.[CLIENT_FUNDING_1_END_OTHER6]'
-- Integration set columns:
    +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.CLIENT_FUNDING_SURVEY Atbl'
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
    +' where Atbl.DW_SurveyResponseID is not null'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'
    +' and not exists (select dwsurvey.SurveyResponseID'
    +' from dbo.CLIENT_FUNDING_SURVEY dwsurvey'
    +' where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and dwsurvey.SurveyResponseID = Atbl.DW_SurveyResponseID)'
     

    print @SQL1
    print @SQL2
    print @SQL3
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar) 
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
set @SQL2 = ''
set @sql3 = ''

set @SQL1 = 'set nocount off'
    +' update dbo.CLIENT_FUNDING_SURVEY'
    +' Set [ElementsProcessed] = 1'
    +', [SurveyID] = Atbl.[SurveyID]'
    +', [SurveyDate] = Atbl.[SurveyDate]'
    +', [AuditDate] = Atbl.[AuditDate]'
    +', [CL_EN_GEN_ID] = cxref1.Client_ID'
    +', [SiteID] = Atbl.[SiteID]'
    +', [ProgramID] = Atbl.[ProgramID]'
    --+', [IA_StaffID] = Atbl.[IA_StaffID]'
    +', [ClientID] = cxref2.Client_ID'
    +', [RespondentID] = Atbl.[RespondentID]'    +', [CLIENT_FUNDING_0_SOURCE_MIECHVP_COM] = Atbl.[CLIENT_FUNDING_0_SOURCE_MIECHVP_COM]'
    +', [CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM] = Atbl.[CLIENT_FUNDING_0_SOURCE_MIECHVP_FORM]'
    +', [CLIENT_FUNDING_0_SOURCE_OTHER] = Atbl.[CLIENT_FUNDING_0_SOURCE_OTHER]'
    +', [CLIENT_FUNDING_0_SOURCE_OTHER_TXT] = Atbl.[CLIENT_FUNDING_0_SOURCE_OTHER_TXT]'
    +', [CLIENT_FUNDING_1_END_MIECHVP_COM] = Atbl.[CLIENT_FUNDING_1_END_MIECHVP_COM]'
    +', [CLIENT_FUNDING_1_END_MIECHVP_FORM] = Atbl.[CLIENT_FUNDING_1_END_MIECHVP_FORM]'
    +', [CLIENT_FUNDING_1_END_OTHER] = Atbl.[CLIENT_FUNDING_1_END_OTHER]'
    +', [CLIENT_FUNDING_1_START_MIECHVP_COM] = Atbl.[CLIENT_FUNDING_1_START_MIECHVP_COM]'
    +', [CLIENT_FUNDING_1_START_MIECHVP_FORM] = Atbl.[CLIENT_FUNDING_1_START_MIECHVP_FORM]'
    +', [CLIENT_FUNDING_1_START_OTHER] = Atbl.[CLIENT_FUNDING_1_START_OTHER]'
    +', [CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL] = Atbl.[CLIENT_FUNDING_0_SOURCE_MIECHVP_TRIBAL]'
    +', [CLIENT_FUNDING_1_END_MIECHVP_TRIBAL] = Atbl.[CLIENT_FUNDING_1_END_MIECHVP_TRIBAL]'
    +', [CLIENT_FUNDING_1_START_MIECHVP_TRIBAL] = Atbl.[CLIENT_FUNDING_1_START_MIECHVP_TRIBAL]'
    +', [CLIENT_FUNDING_0_SOURCE_OTHER1] = Atbl.[CLIENT_FUNDING_0_SOURCE_OTHER1]'
    +', [CLIENT_FUNDING_0_SOURCE_OTHER2] = Atbl.[CLIENT_FUNDING_0_SOURCE_OTHER2]'
    +', [CLIENT_FUNDING_0_SOURCE_OTHER3] = Atbl.[CLIENT_FUNDING_0_SOURCE_OTHER3]'
    +', [CLIENT_FUNDING_1_END_OTHER1] = Atbl.[CLIENT_FUNDING_1_END_OTHER1]'
    +', [CLIENT_FUNDING_1_END_OTHER2] = Atbl.[CLIENT_FUNDING_1_END_OTHER2]'
    +', [CLIENT_FUNDING_1_END_OTHER3] = Atbl.[CLIENT_FUNDING_1_END_OTHER3]'
    +', [CLIENT_FUNDING_1_START_OTHER1] = Atbl.[CLIENT_FUNDING_1_START_OTHER1]'
    +', [CLIENT_FUNDING_1_START_OTHER2] = Atbl.[CLIENT_FUNDING_1_START_OTHER2]'
    +', [CLIENT_FUNDING_1_START_OTHER3] = Atbl.[CLIENT_FUNDING_1_START_OTHER3]'
    +', [CLIENT_FUNDING_0_SOURCE_PFS] = Atbl.[CLIENT_FUNDING_0_SOURCE_PFS]'
    +', [CLIENT_FUNDING_1_START_PFS] = Atbl.[CLIENT_FUNDING_1_START_PFS]'
    +', [CLIENT_FUNDING_1_END_PFS] = Atbl.[CLIENT_FUNDING_1_END_PFS]'
    +', [NURSE_PERSONAL_0_NAME] = exref1.Entity_ID'
-- October 2016 ETO Release:
    +', [CLIENT_FUNDING_0_SOURCE_OTHER4] = Atbl.[CLIENT_FUNDING_0_SOURCE_OTHER4]'
    +', [CLIENT_FUNDING_1_START_OTHER4] = Atbl.[CLIENT_FUNDING_1_START_OTHER4]'
    +', [CLIENT_FUNDING_1_END_OTHER4] = Atbl.[CLIENT_FUNDING_1_END_OTHER4]'
    +', [CLIENT_FUNDING_0_SOURCE_OTHER5] = Atbl.[CLIENT_FUNDING_0_SOURCE_OTHER5]'
    +', [CLIENT_FUNDING_1_START_OTHER5] = Atbl.[CLIENT_FUNDING_1_START_OTHER5]'
    +', [CLIENT_FUNDING_1_END_OTHER5] = Atbl.[CLIENT_FUNDING_1_END_OTHER5]'
    +', [CLIENT_FUNDING_0_SOURCE_OTHER6] = Atbl.[CLIENT_FUNDING_0_SOURCE_OTHER6]'
    +', [CLIENT_FUNDING_1_START_OTHER6] = Atbl.[CLIENT_FUNDING_1_START_OTHER6]'
    +', [CLIENT_FUNDING_1_END_OTHER6] = Atbl.[CLIENT_FUNDING_1_END_OTHER6]'
-- Integration set columns:
    +', [DW_AuditDate] = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
set @SQL2 = ' 
     from dbo.CLIENT_FUNDING_SURVEY dwsurvey'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.CLIENT_FUNDING_SURVEY Atbl'
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

print 'End of Process: SP_AGENCYDB_CLIENT_FUNDING_SURVEY'
GO
