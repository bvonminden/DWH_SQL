USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_DANCE_SURVEY]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_DANCE_SURVEY
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_DANCE_SURVEY]
 (@p_datasource      nvarchar(10) = null
 ,@p_no_delete_opt   nvarchar(2)  = null
 ,@p_no_exec_flag    nvarchar(10) = 'N')
AS
--
-- This script controls integration of AgencyDB Surveys to the Data Warehouse 
--
-- Will exclude from DW if Site Does not exist in dbo.agencies
--
-- Table effected - dbo.DANCE_Survey
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
--   20160513 - New Procedure.
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

set @process          = 'SP_AGENCYDB_DANCE_SURVEY'
set @DW_Tablename     = 'DANCE_SURVEY'
set @Agency_Tablename = 'DANCE_SURVEY'
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            varchar(MAX)
DECLARE @SQL1            varchar(MAX)
DECLARE @SQL2            varchar(MAX)
DECLARE @SQL3            varchar(MAX)
DECLARE @SQL4            varchar(MAX)


print 'Processing SP_AGENCYDB_DANCE_SURVEY: Datasource = ' +isnull(@p_datasource,'NULL')
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
    +' insert into dbo.DANCE_SURVEY'
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
    --+' ,[Master_SurveyID]'
    +' ,[DW_AuditDate]'
    +' ,[NURSE_PERSONAL_0_NAME]'
-- Continue with survey specific columns:
    +' ,[CLIENT_CAC_NA]'
    +' ,[CLIENT_CI_NA]'
    +' ,[CLIENT_EPA_NA]'
    +' ,[CLIENT_NCCO_NA]'
    +' ,[CLIENT_NI_NA]'
    +' ,[CLIENT_NT_NA]'
    +' ,[CLIENT_NVC_NA]'
    +' ,[CLIENT_PC_NA]'
    +' ,[CLIENT_PO_NA]'
    +' ,[CLIENT_PRA_NA]'
    +' ,[CLIENT_RP_NA]'
    +' ,[CLIENT_SCA_NA]'
    +' ,[CLIENT_SE_NA]'
    +' ,[CLIENT_VE_NA]'
    +' ,[CLIENT_VEC_NA]'
    +' ,[CLIENT_VISIT_VARIABLES]'
    +' ,[CLIENT_LS_NA]'
    +' ,[CLIENT_RD_NA]'
    +' ,[CLIENT_VQ_NA]'
    +' ,[CLIENT_0_ID_NSO]'
    +' ,[CLIENT_PERSONAL_0_NAME_FIRST]'
    +' ,[CLIENT_PERSONAL_0_NAME_LAST]'
    +' ,[CLIENT_CAC_COMMENTS]'
    +' ,[CLIENT_CI_COMMENTS]'
    +' ,[CLIENT_EPA_COMMENTS]'
    +' ,[CLIENT_LS_COMMENTS]'
    +' ,[CLIENT_NCCO_COMMENTS]'
    +' ,[CLIENT_NI_COMMENTS]'
    +' ,[CLIENT_NT_COMMENTS]'
    +' ,[CLIENT_NVC_COMMENTS]'
    +' ,[CLIENT_PC_COMMENTS]'
    +' ,[CLIENT_PO_COMMENTS]'
    +' ,[CLIENT_PRA_COMMENTS]'
    +' ,[CLIENT_RD_COMMENTS]'
    +' ,[CLIENT_RP_COMMENTS]'
    +' ,[CLIENT_SCA_COMMENTS]'
    +' ,[CLIENT_SE_COMMENTS]'
    +' ,[CLIENT_VE_COMMENTS]'
    +' ,[CLIENT_VEC_COMMENTS]'
    +' ,[CLIENT_VQ_COMMENTS]'
    +' ,[CLIENT_ACTIVITY_DURATION]'
    +' ,[CLIENT_CAC_PER]'
    +' ,[CLIENT_CHILD_AGE]'
    +' ,[CLIENT_CHILD_DURATION]'
    +' ,[CLIENT_CI_PER]'
    +' ,[CLIENT_EPA_PER]'
    +' ,[CLIENT_LS_PER]'
    +' ,[CLIENT_NCCO_PER]'
    +' ,[CLIENT_NI_PER]'
    +' ,[CLIENT_NT_PER]'
    +' ,[CLIENT_NVC_PER]'
    +' ,[CLIENT_PC_PER]'
    +' ,[CLIENT_PO_PER]'
    +' ,[CLIENT_PRA_PER]'
    +' ,[CLIENT_RD_PER]'
    +' ,[CLIENT_RP_PER]'
    +' ,[CLIENT_SCA_PER]'
    +' ,[CLIENT_SE_PER]'
    +' ,[CLIENT_VE_PER]'
    +' ,[CLIENT_VEC_PER]'
    +' ,[CLIENT_VQ_PER]'
    +')'
set @SQL2 = '
     SELECT  DW_SurveyResponseID as SurveyResponseID, ''' +@p_datasource +''''
    +' ,1'
    +' ,Atbl.[SurveyID]'
    +' ,Atbl.[SurveyDate]'
    +' ,Atbl.[AuditDate]'
    +' ,cxref1.Client_ID'
    +' ,Atbl.[SiteID]'
    +' ,Atbl.[ProgramID]'
    --+' ,exref2.Entity_ID'
    +' ,cxref2.Client_ID'
    +' ,Atbl.[RespondentID]'
    --+', ms.SourceSurveyID'
    +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +' ,exref1.Entity_ID'
-- continue with Survey Specific columns:
    +' ,Atbl.[CLIENT_CAC_NA]'
    +' ,Atbl.[CLIENT_CI_NA]'
    +' ,Atbl.[CLIENT_EPA_NA]'
    +' ,Atbl.[CLIENT_NCCO_NA]'
    +' ,Atbl.[CLIENT_NI_NA]'
    +' ,Atbl.[CLIENT_NT_NA]'
    +' ,Atbl.[CLIENT_NVC_NA]'
    +' ,Atbl.[CLIENT_PC_NA]'
    +' ,Atbl.[CLIENT_PO_NA]'
    +' ,Atbl.[CLIENT_PRA_NA]'
    +' ,Atbl.[CLIENT_RP_NA]'
    +' ,Atbl.[CLIENT_SCA_NA]'
    +' ,Atbl.[CLIENT_SE_NA]'
    +' ,Atbl.[CLIENT_VE_NA]'
    +' ,Atbl.[CLIENT_VEC_NA]'
    +' ,Atbl.[CLIENT_VISIT_VARIABLES]'
    +' ,Atbl.[CLIENT_LS_NA]'
    +' ,Atbl.[CLIENT_RD_NA]'
    +' ,Atbl.[CLIENT_VQ_NA]'
    +' ,Atbl.[CLIENT_0_ID_NSO]'
    +' ,Atbl.[CLIENT_PERSONAL_0_NAME_FIRST]'
    +' ,Atbl.[CLIENT_PERSONAL_0_NAME_LAST]'
    +' ,Atbl.[CLIENT_CAC_COMMENTS]'
    +' ,Atbl.[CLIENT_CI_COMMENTS]'
    +' ,Atbl.[CLIENT_EPA_COMMENTS]'
    +' ,Atbl.[CLIENT_LS_COMMENTS]'
    +' ,Atbl.[CLIENT_NCCO_COMMENTS]'
    +' ,Atbl.[CLIENT_NI_COMMENTS]'
    +' ,Atbl.[CLIENT_NT_COMMENTS]'
    +' ,Atbl.[CLIENT_NVC_COMMENTS]'
    +' ,Atbl.[CLIENT_PC_COMMENTS]'
    +' ,Atbl.[CLIENT_PO_COMMENTS]'
    +' ,Atbl.[CLIENT_PRA_COMMENTS]'
    +' ,Atbl.[CLIENT_RD_COMMENTS]'
    +' ,Atbl.[CLIENT_RP_COMMENTS]'
    +' ,Atbl.[CLIENT_SCA_COMMENTS]'
    +' ,Atbl.[CLIENT_SE_COMMENTS]'
    +' ,Atbl.[CLIENT_VE_COMMENTS]'
    +' ,Atbl.[CLIENT_VEC_COMMENTS]'
    +' ,Atbl.[CLIENT_VQ_COMMENTS]'
    +' ,Atbl.[CLIENT_ACTIVITY_DURATION]'
    +' ,Atbl.[CLIENT_CAC_PER]'
    +' ,Atbl.[CLIENT_CHILD_AGE]'
    +' ,Atbl.[CLIENT_CHILD_DURATION]'
    +' ,Atbl.[CLIENT_CI_PER]'
    +' ,Atbl.[CLIENT_EPA_PER]'
    +' ,Atbl.[CLIENT_LS_PER]'
    +' ,Atbl.[CLIENT_NCCO_PER]'
    +' ,Atbl.[CLIENT_NI_PER]'
    +' ,Atbl.[CLIENT_NT_PER]'
    +' ,Atbl.[CLIENT_NVC_PER]'
    +' ,Atbl.[CLIENT_PC_PER]'
    +' ,Atbl.[CLIENT_PO_PER]'
    +' ,Atbl.[CLIENT_PRA_PER]'
    +' ,Atbl.[CLIENT_RD_PER]'
    +' ,Atbl.[CLIENT_RP_PER]'
    +' ,Atbl.[CLIENT_SCA_PER]'
    +' ,Atbl.[CLIENT_SE_PER]'
    +' ,Atbl.[CLIENT_VE_PER]'
    +' ,Atbl.[CLIENT_VEC_PER]'
    +' ,Atbl.[CLIENT_VQ_PER]'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.DANCE_SURVEY Atbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.SiteID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' left join dbo.Non_ETO_Client_Xref cxref1 on cxref1.Source =  ''' +@p_datasource +''''
    +'   and cxref1.Non_ETO_ID = Atbl.CL_EN_GEN_ID' 
    +'   and cxref1.Non_ETO_Site_ID = Atbl.SiteID' 
    +' left join dbo.Non_ETO_Client_Xref cxref2 on cxref2.Source =  ''' +@p_datasource +''''
    +'   and cxref2.Non_ETO_ID = Atbl.ClientID' 
    +'   and cxref2.Non_ETO_Site_ID = Atbl.SiteID' 
    +' left join dbo.Non_ETO_Entity_Xref exref1 on exref1.Source =  ''' +@p_datasource +''''
    +'   and exref1.Non_ETO_ID = Atbl.[NURSEID]' 
    +'   and exref1.Non_ETO_Site_ID = Atbl.SiteID' 
    --+' left join dbo.Non_ETO_Entity_Xref exref2 on exref2.Source =  ''' +@p_datasource +''''
    --+'   and exref2.Non_ETO_ID = Atbl.IA_StaffID' 
    +' left join dbo.Mstr_Surveys ms on Atbl.SurveyID = ms.SurveyID'
    +' where Atbl.DW_SurveyResponseID is not null'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'
    +' and not exists (select dwsurvey.SurveyResponseID'
    +' from dbo.DANCE_SURVEY dwsurvey'
    +' where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and dwsurvey.SurveyResponseID = Atbl.DW_SurveyResponseID)'
     

    print @SQL1
    print @SQL2
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar) 
    IF upper(@p_no_exec_flag) != 'Y'
       EXEC (@SQL1+@SQL2+@SQL3+@SQL4)

--   and exists (select nfpagencies.Site_ID
--                     from dbo.Agencies nfpagencies
--                    where nfpagencies.Site_Id = Sites.SiteId);

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
print ' '
print 'Update changes'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL1 = 'set nocount off'
    +' update dbo.DANCE_SURVEY'
    +' Set [SurveyID] = Atbl.[SurveyID]'
    +' ,[SurveyDate] = Atbl.[SurveyDate]'
    +' ,[AuditDate] = Atbl.[AuditDate]'
    +' ,[CL_EN_GEN_ID] = cxref2.Client_ID'
    +' ,[SiteID] = Atbl.[SiteID]'
    +' ,[ProgramID] = Atbl.[ProgramID]'
    --+' ,[IA_StaffID] = exref2.Entity_ID'
    +' ,[ClientID] = cxref2.Client_ID'
    +' ,[RespondentID] = Atbl.[RespondentID]'
    +' ,[NURSE_PERSONAL_0_NAME] = exref1.Entity_ID'
    --+', [Master_SurveyID] = ms.SourceSurveyID'
    +', [DW_AuditDate] = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    -- survey specific items:
    +' ,[CLIENT_CAC_NA] = Atbl.[CLIENT_CAC_NA]'
    +' ,[CLIENT_CI_NA] = Atbl.[CLIENT_CI_NA]'
    +' ,[CLIENT_EPA_NA] = Atbl.[CLIENT_EPA_NA]'
    +' ,[CLIENT_NCCO_NA] = Atbl.[CLIENT_NCCO_NA]'
    +' ,[CLIENT_NI_NA] = Atbl.[CLIENT_NI_NA]'
    +' ,[CLIENT_NT_NA] = Atbl.[CLIENT_NT_NA]'
    +' ,[CLIENT_NVC_NA] = Atbl.[CLIENT_NVC_NA]'
    +' ,[CLIENT_PC_NA] = Atbl.[CLIENT_PC_NA]'
    +' ,[CLIENT_PO_NA] = Atbl.[CLIENT_PO_NA]'
    +' ,[CLIENT_PRA_NA] = Atbl.[CLIENT_PRA_NA]'
    +' ,[CLIENT_RP_NA] = Atbl.[CLIENT_RP_NA]'
    +' ,[CLIENT_SCA_NA] = Atbl.[CLIENT_SCA_NA]'
    +' ,[CLIENT_SE_NA] = Atbl.[CLIENT_SE_NA]'
    +' ,[CLIENT_VE_NA] = Atbl.[CLIENT_VE_NA]'
    +' ,[CLIENT_VEC_NA] = Atbl.[CLIENT_VEC_NA]'
    +' ,[CLIENT_VISIT_VARIABLES] = Atbl.[CLIENT_VISIT_VARIABLES]'
    +' ,[CLIENT_LS_NA] = Atbl.[CLIENT_LS_NA]'
    +' ,[CLIENT_RD_NA] = Atbl.[CLIENT_RD_NA]'
    +' ,[CLIENT_VQ_NA] = Atbl.[CLIENT_VQ_NA]'
    +' ,[CLIENT_0_ID_NSO] = Atbl.[CLIENT_0_ID_NSO]'
    +' ,[CLIENT_PERSONAL_0_NAME_FIRST] = Atbl.[CLIENT_PERSONAL_0_NAME_FIRST]'
    +' ,[CLIENT_PERSONAL_0_NAME_LAST] = Atbl.[CLIENT_PERSONAL_0_NAME_LAST]'
    +' ,[CLIENT_CAC_COMMENTS] = Atbl.[CLIENT_CAC_COMMENTS]'
    +' ,[CLIENT_CI_COMMENTS] = Atbl.[CLIENT_CI_COMMENTS]'
    +' ,[CLIENT_EPA_COMMENTS] = Atbl.[CLIENT_EPA_COMMENTS]'
    +' ,[CLIENT_LS_COMMENTS] = Atbl.[CLIENT_LS_COMMENTS]'
    +' ,[CLIENT_NCCO_COMMENTS] = Atbl.[CLIENT_NCCO_COMMENTS]'
    +' ,[CLIENT_NI_COMMENTS] = Atbl.[CLIENT_NI_COMMENTS]'
    +' ,[CLIENT_NT_COMMENTS] = Atbl.[CLIENT_NT_COMMENTS]'
    +' ,[CLIENT_NVC_COMMENTS] = Atbl.[CLIENT_NVC_COMMENTS]'
    +' ,[CLIENT_PC_COMMENTS] = Atbl.[CLIENT_PC_COMMENTS]'
    +' ,[CLIENT_PO_COMMENTS] = Atbl.[CLIENT_PO_COMMENTS]'
    +' ,[CLIENT_PRA_COMMENTS] = Atbl.[CLIENT_PRA_COMMENTS]'
    +' ,[CLIENT_RD_COMMENTS] = Atbl.[CLIENT_RD_COMMENTS]'
    +' ,[CLIENT_RP_COMMENTS] = Atbl.[CLIENT_RP_COMMENTS]'
    +' ,[CLIENT_SCA_COMMENTS] = Atbl.[CLIENT_SCA_COMMENTS]'
    +' ,[CLIENT_SE_COMMENTS] = Atbl.[CLIENT_SE_COMMENTS]'
    +' ,[CLIENT_VE_COMMENTS] = Atbl.[CLIENT_VE_COMMENTS]'
    +' ,[CLIENT_VEC_COMMENTS] = Atbl.[CLIENT_VEC_COMMENTS]'
    +' ,[CLIENT_VQ_COMMENTS] = Atbl.[CLIENT_VQ_COMMENTS]'
    +' ,[CLIENT_ACTIVITY_DURATION] = Atbl.[CLIENT_ACTIVITY_DURATION]'
set @SQL2 = '
    ,[CLIENT_CAC_PER] = Atbl.[CLIENT_CAC_PER]'
    +' ,[CLIENT_CHILD_AGE] = Atbl.[CLIENT_CHILD_AGE]'
    +' ,[CLIENT_CHILD_DURATION] = Atbl.[CLIENT_CHILD_DURATION]'
    +' ,[CLIENT_CI_PER] = Atbl.[CLIENT_CI_PER]'
    +' ,[CLIENT_EPA_PER] = Atbl.[CLIENT_EPA_PER]'
    +' ,[CLIENT_LS_PER] = Atbl.[CLIENT_LS_PER]'
    +' ,[CLIENT_NCCO_PER] = Atbl.[CLIENT_NCCO_PER]'
    +' ,[CLIENT_NI_PER] = Atbl.[CLIENT_NI_PER]'
    +' ,[CLIENT_NT_PER] = Atbl.[CLIENT_NT_PER]'
    +' ,[CLIENT_NVC_PER] = Atbl.[CLIENT_NVC_PER]'
    +' ,[CLIENT_PC_PER] = Atbl.[CLIENT_PC_PER]'
    +' ,[CLIENT_PO_PER] = Atbl.[CLIENT_PO_PER]'
    +' ,[CLIENT_PRA_PER] = Atbl.[CLIENT_PRA_PER]'
    +' ,[CLIENT_RD_PER] = Atbl.[CLIENT_RD_PER]'
    +' ,[CLIENT_RP_PER] = Atbl.[CLIENT_RP_PER]'
    +' ,[CLIENT_SCA_PER] = Atbl.[CLIENT_SCA_PER]'
    +' ,[CLIENT_SE_PER] = Atbl.[CLIENT_SE_PER]'
    +' ,[CLIENT_VE_PER] = Atbl.[CLIENT_VE_PER]'
    +' ,[CLIENT_VEC_PER] = Atbl.[CLIENT_VEC_PER]'
    +' ,[CLIENT_VQ_PER] = Atbl.[CLIENT_VQ_PER]'
    +'
     from dbo.DANCE_SURVEY dwsurvey'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.DANCE_SURVEY Atbl'
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
    --+' left join dbo.Non_ETO_Entity_Xref exref2 on exref2.Source =  ''' +@p_datasource +''''
    --+'   and exref2.Non_ETO_ID = Atbl.IA_StaffID' 
    +' left join dbo.Mstr_Surveys ms on Atbl.SurveyID = ms.SurveyID' 
    +'
     where dwsurvey.Datasource = ''' +@p_datasource +''''
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.SiteID) is null'
    +' and isnull(dwsurvey.AuditDate,convert(datetime,''19700101'',112)) < '
    +' isnull(Atbl.AuditDate,convert(datetime,''19700101'',112))'

    print @SQL1
    print @SQL2
    print 'SQL1 Length = ' +CAST(LEN(@SQL1) as varchar) +', SQL2 Length = ' +CAST(LEN(@SQL2) as varchar) 
    IF upper(@p_no_exec_flag) != 'Y'
       EXEC (@SQL1+@SQL2+@SQL3+@SQL4)




----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
print ' '
print 'Delete Contacts that no longer exist in AgencyDB'

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

print 'End of Process: SP_AGENCYDB_DANCE_SURVEY'
GO
