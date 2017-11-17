USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_CLIENTS]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_CLIENTS
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_CLIENTS]
 (@p_datasource      nvarchar(10) = null
 ,@p_Client_id       int = null
 ,@p_no_exec_flag    nvarchar(10) = 'N')
AS
--
-- This script controls integration of AgencyDB Staff to the Data Warehous Clients table.
--
-- Will exclude from DW if Site Does not exist in dbo.agencies
--
-- Table effected - dbo.Clients
--
-- Insert: select and insert when record is found to be missing in the DW.
-- Update: select and update when record exists in DW and has been changed but has been changed flagged by Audit_Date.
--
-- History:
--   20130325 - New Procedure.
--   20140214 - Added site_id to non-ETO_Xref.  This will allow the site_id to represent uniqueness between companies,
--              thus allowing the same source id to be utilized by different Agencydb sites (company).
--   20140324 - Added Site_ID qualifier by datasource, to allow multiple datasources to share the same AgencyDB.
--              Added database trigger to inhibit the processing of this procedure (defaulting as always process).
--                This trigger is used to bypass the process w/o having to modify the SSIS integration packages.
--   20140830 - Changed to utilize the ETO Clients record if found, and create xref from client defined ID to orig ETO_ID;
--              else, create new xref record with next available Non_Entity_ID in sequence.
--   20141010 - Changed to use the Client_ID as the CaseNumber (they should be the same value).
--   20150122 - Added the inclusion of SSN, Client_Medicaid_Number, Child_Medicaid_Number.
--   20150207 - Added the validation in re-mapping to existing DW clients, to ensure that the eto_client_id is used only once.
--              If multiples found, will bypass that client from re-mapping.
--   20150212 - Added validation to re-mapping to ensure that the eto_client_id actually exists in the DW
--              for the site id with a datasource of 'ETO', else will bypass re-mapping (thus creating new record to DW).
--              Added update to DW.Clients.datasource for positive re-mappings.
--              Added option to not actually execute the SQL statements, used for validation/troubleshooting purposes.
--   20160225 - Amended for new columns to the Clients table.
--   20161011 - Amended for new columns to the Clients table: DECLINED_CELL, ETO_ARCHIVED.
--              -- Archived will only be set for new inserted records, will not be updated (for ETO originating records)
--   20170327 - Amended to update the AgencyDB.Clients.DW_CaseNumber with what is established in the DW.
--   20170511 - Amended to strip dashes from the SSN.  Was causing a buffer overflow for the established 9 char field.

DECLARE @count        smallint
DECLARE @stop_flag  nvarchar(2)
DECLARE @Process      nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)

set @process = 'SP_AGENCYDB_CLIENTS'
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            nvarchar(max)

print 'Processing SP_CLIENTS_FROM_AGENCYDB: Datasource = ' +isnull(@p_datasource,'NULL')
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
   print 'Processing SP_AGENCYDB_Clients - Validate datasource DBSrvr from LOV tables'

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
print 'Cont: Insert new records - AgencyDB=' + @AgencyDB
print 'AgencyDB Server=' +@AgencyDB_Srvr

-- Extraction for Client:

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Staff'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- create non_ETO xref entries for new records from AgencyDB (that originated from ETO):
-- ** disregard if the eto_client_id is used more than once **
-- ** disregard if the eto_client_id does not exist in DW for site **
set @SQL = 'set nocount off '+
    ' set identity_insert dbo.non_eto_Client_xref on '
    +' insert into dbo.Non_ETO_Client_Xref'
    +' (Client_ID, Non_ETO_ID, Non_ETO_Site_ID,Prior_Source, Source)'
    +'
     select Atbl.ETO_Client_ID, Atbl.Client_id, Atbl.Site_ID, isnull(dwClients.DataSource,''ETO''), ''' +@p_datasource +''''
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Clients Atbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' inner join dbo.clients dwClients on atbl.ETO_Client_ID = dwClients.Client_ID'
          +' and atbl.Site_ID = dwClients.Site_ID'
          +' and isnull(dwClients.DataSource,''ETO'') = ''ETO'''
    +' where isnull(Atbl.ETO_Client_ID,0) != 0'
      +' and not exists (select dwxref.Client_ID'
                        +' from dbo.Non_ETO_Client_Xref dwxref'
                       +' where dwxref.source = ''' +@p_datasource +''''
                         +' and dwxref.Non_ETO_ID = Atbl.Client_Id'
                         +' and dwxref.Non_ETO_Site_ID = atbl.Site_ID)'
      +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.Site_ID) is null'
      +' and (select COUNT(*) from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Clients aclients2'
            +' where aclients2.eto_client_id = atbl.eto_client_id) =1'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)


-- update the Clients datasource for any new re-mapping of non-eto-exref records to an existing ETO record:
set @SQL = 'set nocount off '+
     ' update dbo.Clients'
    +'   set DataSource = dwxref.source'
    +'   from dbo.Non_ETO_Client_Xref dwxref'
    +'   inner join dbo.Clients on dwxref.Client_id = Clients.Client_id'
    +'     and dwxref.prior_source = isnull(Clients.datasource,''ETO'')'
    +'   where dwxref.Prior_Source is not null'
    +'   and dwxref.Prior_Source != dwxref.Source'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    exec (@SQL)


-- create non_ETO xref entries for new records from AgencyDB (that DID NOT originated from ETO):
set @SQL = 'set nocount off '+
    ' set identity_insert dbo.non_eto_Client_xref off '
    +' insert into dbo.Non_ETO_Client_Xref'
    +' (Non_ETO_ID, Non_ETO_Site_ID, Source)'
    +'
     select Atbl.Client_id, Atbl.Site_ID, ''' +@p_datasource +''''
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Clients Atbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' where not exists (select dwxref.Client_ID'
    +'   from dbo.Non_ETO_Client_Xref dwxref'
    +'   where dwxref.source = ''' +@p_datasource +''''
    +'   and dwxref.Non_ETO_ID = Atbl.Client_Id'
    +'   and dwxref.Non_ETO_Site_ID = atbl.Site_ID)'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.Site_ID) is null'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)


-- Update AgencyDB with the latest assigned NON-ETO_ID for the defined xref:
--  (always updates in case agency overwrites or clears out DW_Entity_ID field):
set @SQL = 'set nocount off '+
    'update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Clients'
    +' Set [DW_Client_ID] = dwxref.[Client_ID]'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Clients Atbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' inner join dbo.Non_ETO_Client_Xref dwxref'
    +' on dwxref.Non_ETO_ID = Atbl.Client_ID and dwxref.source = ''' +@p_datasource +''''
    +'   and dwxref.Non_ETO_Site_ID = Atbl.Site_ID'
    +' where dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.Site_ID) is null'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)

set @SQL = 'set nocount off '+
    ' insert into dbo.Clients'
    +' ([Client_Id]' 
    +', [DataSource]'
    +', [Site_ID]'
    +', [Last_Name]'
    +', [First_Name]'
    +', [Middle_Name]'
    +', [Prefix]'
    +', [Suffix]'
    +', [DOB]'
    +', [Gender]'
    +', [Marital_Status]'
    +', [Address1]'
    +', [Address2]'
    +', [City]'
    +', [State]'
    +', [ZipCode]'
    +', [county]'
    +', [Email]'
    +', [Home_Phone]'
    +', [Cell_Phone]'
    +', [Work_Phone]'
    +', [Work_Phone_Extension]'
    +', [Pager]'
    +', [Date_Created]'
    +', [Audit_Date]'
    +', [Audit_Staff_ID]'
    +', [Disabled]'
    +', [Funding_Entity_ID]'
    +', [Referral_Entity_ID]'
    +', [Assigned_Staff_ID]'
    +', [CRM_Client_ID]'
    +', [Last_CRM_Update]'
    +', [flag_update_crm]'
    +', [DEMO_CLIENT_INTAKE_0_ETHNICITY]'
    +', [DEMO_CLIENT_INTAKE_0_RACE]'
    +', [DEMO_CLIENT_INTAKE_0_RACE_10]'
    +', [DEMO_CLIENT_INTAKE_0_LANGUAGE]'
    +', [CaseNumber]'
    +', [Last_Demog_Update]'
    +', [CLIENT_PERSONAL_LANGUAGE_1_DESC]'
    --+', [ReasonForReferral]'
    +', [DEMO_CLIENT_INTAKE_0_ANCESTRY]'
    +', SSN'
    +', CLIENT_MEDICAID_NUMBER'
    +', CHILD_MEDICAID_NUMBER'
    +', ReasonForReferral'
    +', INFANT_BIRTH_0_DOB'
    +', PFS_STUDY_VULNERABLE_POP'
    +', [DECLINED_CELL]'
    +', [ETO_ARCHIVED]'
    +', [DW_AuditDate]'
    +')'
    +'
     SELECT  Atbl.DW_Client_ID as Client_ID, ''' +@p_datasource +''''  
    +', Atbl.[Site_ID]'
    +', Atbl.[Last_Name]'
    +', Atbl.[First_Name]'
    +', Atbl.[Middle_Name]'
    +', Atbl.[Prefix]'
    +', Atbl.[Suffix]'
    +', Atbl.[DOB]'
    +', Atbl.[Gender]'
    +', Atbl.[Marital_Status]'
    +', Atbl.[Address1]'
    +', Atbl.[Address2]'
    +', Atbl.[City]'
    +', Atbl.[State]'
    +', Atbl.[ZipCode]'
    +', Atbl.[county]'
    +', Atbl.[Email]'
    +', Atbl.[Home_Phone]'
    +', Atbl.[Cell_Phone]'
    +', Atbl.[Work_Phone]'
    +', Atbl.[Work_Phone_Extension]'
    +', Atbl.[Pager]'
    +', Atbl.[Date_Created]'
    +', Atbl.[Audit_Date]'
    +', Atbl.[Audit_Staff_ID]'
    +', Atbl.[Disabled]'
    +', Atbl.[Funding_Entity_ID]'
    +', Atbl.[Referral_Entity_ID]'
    +', Atbl.[Assigned_Staff_ID]'
    +', Atbl.[CRM_Client_ID]'
    +', Atbl.[Last_CRM_Update]'
    +', Atbl.[flag_update_crm]'
    +', Atbl.[DEMO_CLIENT_INTAKE_0_ETHNICITY]'
    +', Atbl.[DEMO_CLIENT_INTAKE_0_RACE]'
    +', Atbl.[DEMO_CLIENT_INTAKE_0_RACE_10]'
    +', Atbl.[DEMO_CLIENT_INTAKE_0_LANGUAGE]'
    +', Atbl.DW_Client_ID as CaseNumber'
    +', Atbl.[Last_Demog_Update]'
    +', Atbl.[CLIENT_PERSONAL_LANGUAGE_1_DESC]'
    --+', Atbl.[ReasonForReferral]'
    +', Atbl.[DEMO_CLIENT_INTAKE_0_ANCESTRY]'
    +', replace(Atbl.SSN,''-'','''')'
    +', Atbl.CLIENT_MEDICAID_NUMBER'
    +', Atbl.CHILD_MEDICAID_NUMBER'
    +', Atbl.ReasonForReferral'
    +', Atbl.INFANT_BIRTH_0_DOB'
    +', Atbl.PFS_STUDY_VULNERABLE_POP'
    +', Atbl.[DECLINED_CELL]'
    +', Atbl.[ETO_ARCHIVED]'
    +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Clients Atbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' where Atbl.DW_Client_ID is not null'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.Site_ID) is null'
    +' and not exists (select dwclients.Client_ID'
                      +' from dbo.Clients dwclients'
                     +' where dwclients.Datasource = ''' +@p_datasource +''''
                       +' and dwclients.Client_Id = Atbl.DW_Client_Id)'
     

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)

--   and exists (select nfpagencies.Site_ID
--                     from dbo.Agencies nfpagencies
--                    where nfpagencies.Site_Id = Sites.SiteId);

----------------------------------------------------------------------------------------
print 'Cont: Update staff changes'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing Staff'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL = 'set nocount off '+
    'update dbo.Clients'
    +' set [Site_ID] = Atbl.[Site_ID]'
    +', [Last_Name] = Atbl.[Last_Name]'
    +', [First_Name] = Atbl.[First_Name]'
    +', [Middle_Name] = Atbl.[Middle_Name]'
    +', [Prefix] = Atbl.[Prefix]'
    +', [Suffix] = Atbl.[Suffix]'
    +', [DOB] = Atbl.[DOB]'
    +', [Gender] = Atbl.[Gender]'
    +', [Marital_Status] = Atbl.[Marital_Status]'
    +', [Address1] = Atbl.[Address1]'
    +', [Address2] = Atbl.[Address2]'
    +', [City] = Atbl.[City]'
    +', [State] = Atbl.[State]'
    +', [ZipCode] = Atbl.[ZipCode]'
    +', [county] = Atbl.[county]'
    +', [Email] = Atbl.[Email]'
    +', [Home_Phone] = Atbl.[Home_Phone]'
    +', [Cell_Phone] = Atbl.[Cell_Phone]'
    +', [Work_Phone] = Atbl.[Work_Phone]'
    +', [Work_Phone_Extension] = Atbl.[Work_Phone_Extension]'
    +', [Pager] = Atbl.[Pager]'
    +', [Date_Created] = Atbl.[Date_Created]'
    +', [Audit_Date] = Atbl.[Audit_Date]'
    +', [Audit_Staff_ID] = Atbl.[Audit_Staff_ID]'
    +', [Disabled] = Atbl.[Disabled]'
    +', [Funding_Entity_ID] = Atbl.[Funding_Entity_ID]'
    +', [Referral_Entity_ID] = Atbl.[Referral_Entity_ID]'
    +', [Assigned_Staff_ID] = Atbl.[Assigned_Staff_ID]'
    +', [CRM_Client_ID] = Atbl.[CRM_Client_ID]'
    +', [Last_CRM_Update] = Atbl.[Last_CRM_Update]'
    +', [flag_update_crm] = Atbl.[flag_update_crm]'
    +', [DEMO_CLIENT_INTAKE_0_ETHNICITY] = Atbl.[DEMO_CLIENT_INTAKE_0_ETHNICITY]'
    +', [DEMO_CLIENT_INTAKE_0_RACE] = Atbl.[DEMO_CLIENT_INTAKE_0_RACE]'
    +', [DEMO_CLIENT_INTAKE_0_RACE_10] = Atbl.[DEMO_CLIENT_INTAKE_0_RACE_10]'
    +', [DEMO_CLIENT_INTAKE_0_LANGUAGE] = Atbl.[DEMO_CLIENT_INTAKE_0_LANGUAGE]'
    --+', [CaseNumber] = Atbl.[CaseNumber]'
    +', [Last_Demog_Update] = Atbl.[Last_Demog_Update]'
    +', [CLIENT_PERSONAL_LANGUAGE_1_DESC] = Atbl.[CLIENT_PERSONAL_LANGUAGE_1_DESC]'
    --+', [ReasonForReferral] = Atbl.[ReasonForReferral]'
    +', [DEMO_CLIENT_INTAKE_0_ANCESTRY] = Atbl.[DEMO_CLIENT_INTAKE_0_ANCESTRY]'
    +', SSN = replace(Atbl.SSN,''-'','''')'
    +', CLIENT_MEDICAID_NUMBER = Atbl.CLIENT_MEDICAID_NUMBER'
    +', CHILD_MEDICAID_NUMBER = Atbl.CHILD_MEDICAID_NUMBER'
    +', ReasonForReferral = Atbl.ReasonForReferral'
    +', INFANT_BIRTH_0_DOB = Atbl.INFANT_BIRTH_0_DOB'
    +', PFS_STUDY_VULNERABLE_POP = Atbl.PFS_STUDY_VULNERABLE_POP'
    +', [DECLINED_CELL] = Atbl.[DECLINED_CELL]'
    +', [DW_AuditDate] = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from dbo.Clients dwclients'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Clients Atbl'
    +' on dwclients.Client_ID = Atbl.DW_Client_ID'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +'
     where dwclients.Datasource = ''' +@p_datasource +''''
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.Site_ID) is null'
    +' and isnull(dwclients.Audit_Date,convert(datetime,''19700101'',112)) < 
           isnull(Atbl.Audit_Date,convert(datetime,''19700101'',112))'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)


----------------------------------------------------------------------------------------
print 'Cont: Updating the DW_CaseNumber in the AgencyDB'
-- Update AgencyDB with the latest assigned CaseNumber defined within the DW:
set @SQL = 'set nocount off '+
    'update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Clients'
    +' Set [DW_CaseNumber] = dwclients.CaseNumber'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Clients Atbl'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = Atbl.Site_ID'
       +' and asbd.DataSource =  ''' +@p_datasource +''''
    +' inner join dbo.Non_ETO_Client_Xref dwxref'
       +' on dwxref.Non_ETO_ID = Atbl.Client_ID and dwxref.source = ''' +@p_datasource +''''
       +' and dwxref.Non_ETO_Site_ID = Atbl.Site_ID'
    +' inner join dbo.Clients dwclients'
       +' on dwxref.Client_ID = dwclients.Client_ID'
    +' where dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', Atbl.Site_ID) is null'
      +' and isnull(atbl.DW_CaseNumber,''abc123456'') != isnull(dwclients.CaseNumber,''abc123456'')'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    EXEC (@SQL)


----------------------------------------------------------------------------------------
print 'Cont: Delete Contacts that no longer exist in AgencyDB'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Deleting ETO Deletions'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

/*  commented because survey history may be referencing these records
set @SQL =
    ' delete dbo.Clients'
    +' from dbo.Clients'
    +' where DataSource = @p_datasource'
    +' and not exists (select Atbl.Client_ID'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Clients Atbl'
    +' where DW_Client_ID = Clients.Client_ID)
*/


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

print 'End of Process: SP_AGENCYDB_CLIENTS'
GO
