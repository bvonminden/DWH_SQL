USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_OK_CLIENTS]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_OK_CLIENTS
--
CREATE PROCEDURE [dbo].[SP_OK_CLIENTS]
 (@p_Client_id       int = null)
AS
--
-- This script controls integration of Oklahoma to the Data Warehous Clients table.
--
-- ** Defaulting Datasource as 'OKLAHOMA'
--               Audit_StaffID = 4614, EntityID=13048, name=Data Migration2, for site 260
--               Site_ID = 260
--
-- Table effected - dbo.Clients
--
-- Insert: select and insert when record is found to be missing in the DW.
-- Update: select and update when record exists in DW and has been changed but has been changed flagged by Audit_Date.
--
-- History:
--   20131219 - New Procedure.
--   20140523 - Updated to pull demographic data from DEMO_INTAKE_TBL instead of View_participants_DW,
--              because demo_intake_tbl populated with translated data instead of coded values.
--   20141006 - Amended to bring in only one occurrance of the client in the demo_intake_view.

DECLARE @p_datasource nvarchar(10)
DECLARE @Source_TableName nvarchar(50)
DECLARE @DW_TableName nvarchar(50)
DECLARE @count        smallint
DECLARE @p_stop_flag  nvarchar(2)
DECLARE @Process      nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @AgencyDB_Srvr  nvarchar(30)
DECLARE @ETO_SiteID             int
DECLARE @ETO_AuditStaffID       int

set @process = 'SP_CLIENTS_FROM_AGENCYDB'
set @DW_Tablename = 'Clients'
set @Source_Tablename = 'DEMO_INTAKE_TBL'
Set @p_stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'
set @runtime = getdate()
set @p_datasource = 'OKLAHOMA'
set @ETO_SiteID = 260
set @ETO_AuditStaffID = 4614

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            nvarchar(max)


print 'Processing SP_OK_CLIENTS: Datasource = ' +isnull(@p_datasource,'NULL')
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
print 'Processing SP_CLIENTS_FROM_AGENCYDB - retrieving datasource DB Srvr from LOV tables'

set @AgencyDB = null;
select @AgencyDB = Value
  from dbo.View_LOV
 where Name = 'AGENCYDB_BY_DATASOURCE'
   and lOV_Item = @p_datasource

IF @AgencyDB is null
BEGIN
   --set @p_flag_stop = 'X';
   print 'Unable to retrieve LOV AgencyDB for datasource, job stopped'
   set nocount on
   update dbo.process_log 
   set Comment = 'failed, can''t retrieve LOV AgencyDB for datasource'
      ,LogDate = getdate()
 where Process = @process

END
ELSE
BEGIN

----------------------------------------------------------------------------------------
print 'SP_OK_CLIENTS - Insert new records - AgencyDB=' + @AgencyDB
print 'AgencyDB Server=' +@AgencyDB_Srvr

-- Extraction for Client:

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Staff'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- create non_ETO xref entries for new records from AgencyDB:
set @SQL = 'set nocount off'
    +' insert into dbo.Non_ETO_Client_Xref'
    +' (Non_ETO_ID, Source)'
    +'
     select Client_0_id_agency, ''' +@p_datasource +''''
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename +' Atbl'
    +' where Atbl.Client_0_id_agency is not null'
    +' and not exists (select dwxref.Client_ID'
    +' from dbo.Non_ETO_Client_Xref dwxref'
    +' where dwxref.source = ''' +@p_datasource +''''
    +' and dwxref.Non_ETO_ID = Atbl.Client_0_id_agency)'
    +' group by client_0_id_agency'

    print @SQL
    EXEC (@SQL)

/*  bypassed because source may be a view
-- Assign new NON-ETO xref ID to new records from AgencyDB:
set @SQL = 'update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename +'
    +' Set [DW_Client_ID] = dwxref.[Client_ID]'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename +' Atbl'
    +' inner join dbo.Non_ETO_Client_Xref dwxref'
    +' on dwxref.Non_ETO_ID = Atbl.Client_0_id_agency and dwxref.source = ''' +@p_datasource +''''

    print @SQL
    --EXEC (@SQL)
*/

set @SQL = 'set nocount off'
    +' insert into dbo.Clients'
    +' ([Client_Id]' 
    +', [DataSource]'
    +', [Site_ID]'
    +', [Last_Name]'
    +', [First_Name]'
    --+', [Middle_Name]'
    --+', [Prefix]'
    --+', [Suffix]'
    +', [DOB]'
    +', [Gender]'
    --+', [Marital_Status]'
    --+', [Address1]'
    --+', [Address2]'
    --+', [City]'
    --+', [State]'
    --+', [ZipCode]'
    --+', [county]'
    --+', [Email]'
    --+', [Home_Phone]'
    --+', [Cell_Phone]'
    --+', [Work_Phone]'
    --+', [Work_Phone_Extension]'
    --+', [Pager]'
    +', [Date_Created]'
    +', [Audit_Date]'
    --+', [Audit_Staff_ID]'
    --+', [Disabled]'
    --+', [Funding_Entity_ID]'
    --+', [Referral_Entity_ID]'
    +', [Assigned_Staff_ID]'
    +', [DEMO_CLIENT_INTAKE_0_ETHNICITY]'
    +', [DEMO_CLIENT_INTAKE_0_RACE]'
    --+', [DEMO_CLIENT_INTAKE_0_RACE_10]'
    +', [DEMO_CLIENT_INTAKE_0_LANGUAGE]'
    +', [CaseNumber]'
    --+', [Last_Demog_Update]'
    --+', [CLIENT_PERSONAL_LANGUAGE_1_DESC]'
    --+', [ReasonForReferral]'
    --+', [DEMO_CLIENT_INTAKE_0_ANCESTRY]'
    +', [DW_AuditDate]'
    +')'
    +'
     SELECT  xref.Client_ID as Client_ID, ''' +@p_datasource +''''  
    +' , '+convert(varchar,@ETO_SiteID) +' as Site_ID'
    +', ClinicSite.Sitecode as Last_Name'
    +', Atbl.CLIENT_0_ID_AGENCY as First_Name'
    --+', Atbl.[Middle_Name]'
    --+', Atbl.[Prefix]'
    --+', Atbl.[Suffix]'
    +', Atbl.[Client_Personal_0_DOB_Intake]'
    +', 1 as [Gender]'
    --+', Atbl.[Marital_Status]'
    --+', Atbl.[Address1]'
    --+', Atbl.[Address2]'
    --+', Atbl.[City]'
    --+', Atbl.[State]'
    --+', Atbl.[ZipCode]'
    --+', Atbl.[county]'
    --+', Atbl.[Email]'
    --+', Atbl.[Home_Phone]'
    --+', Atbl.[Cell_Phone]'
    --+', Atbl.[Work_Phone]'
    --+', Atbl.[Work_Phone_Extension]'
    --+', Atbl.[Pager]'
    +', Atbl.[AnswerDate]'
    +', Atbl.[ChgDateTime]'
    --+', Atbl.[Audit_Staff_ID]'
    --+', Atbl.[Disabled]'
    --+', Atbl.[Funding_Entity_ID]'
    --+', Atbl.[Referral_Entity_ID]'
    +', exref1.Entity_ID'
    +', Atbl.[CLIENT_PERSONAL_0_ETHNICITY_INTAKE]'
    +', Atbl.[CLIENT_PERSONAL_0_RACE]'
    --+', Atbl.[DEMO_CLIENT_INTAKE_0_RACE_10]'
    +', Atbl.[CLIENT_PERSONAL_LANGUAGE_0_INTAKE]'
    +', Atbl.[Client_0_ID_Agency]'
    --+', Atbl.[Last_Demog_Update]'
    --+', Atbl.[CLIENT_PERSONAL_LANGUAGE_1_DESC]'
    --+', Atbl.[ReasonForReferral]'
    --+', null' /* Atbl.[DEMO_CLIENT_INTAKE_0_ANCESTRY]'
    +' ,convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename +' Atbl'
    +'
     inner join dbo.Non_ETO_Client_Xref xref on xref.source = ''' +@p_datasource +''''
    +'  and atbl.Client_0_id_agency = xref.Non_ETO_ID'
    +' 
     left join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Clinic Clinic'
    +'  on Atbl.SiteCode = Clinic.Clinic_no'
    +' 
     left join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.ClinicSite ClinicSite'
    +'  on Clinic.ClinicID = ClinicSite.ClinicID'
    +' 
     left join dbo.Non_ETO_Entity_Xref exref1 on exref1.Source =  ''' +@p_datasource +''''
    +'   and exref1.Non_ETO_ID = Atbl.NurseID' 
    +'
     where not exists (select dwclients.Client_ID'
    +' from dbo.Clients dwclients'
    +' where dwclients.Client_Id = xref.Client_ID'
    --+' and dwclients.Datasource = ''' +@p_datasource +''''
    +')'
    +' and Atbl.answerid = (select MAX(atbl2.answerid)'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename +' Atbl2'
    +' where atbl2.Client_0_id_agency = atbl.Client_0_id_agency)'
     

    print @SQL
    EXEC (@SQL)

--   and exists (select nfpagencies.Site_ID
--                     from dbo.Agencies nfpagencies
--                    where nfpagencies.Site_Id = Sites.SiteId);

----------------------------------------------------------------------------------------
print '  Cont: SP_OK_CLIENTS - Update staff changes'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing Staff'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

set @SQL = 'set nocount off'
    +' update dbo.Clients'
    +' set [Site_ID] = '+convert(varchar,@ETO_SiteID)
    +', [Last_Name] = ClinicSite.Sitecode'
    +', [First_Name] = Atbl.CLIENT_0_ID_AGENCY'
    --+', [Middle_Name] = Atbl.[Middle_Name]'
    --+', [Prefix] = Atbl.[Prefix]'
    --+', [Suffix] = Atbl.[Suffix]'
    +', [DOB] = Atbl.[Client_Personal_0_DOB_Intake]'
    --+', [Gender] = Atbl.[Gender]'
    --+', [Marital_Status] = Atbl.[Marital_Status]'
    --+', [Address1] = Atbl.[Address1]'
    --+', [Address2] = Atbl.[Address2]'
    --+', [City] = Atbl.[City]'
    --+', [State] = Atbl.[State]'
    --+', [ZipCode] = Atbl.[ZipCode]'
    --+', [county] = Atbl.[county]'
    --+', [Email] = Atbl.[Email]'
    --+', [Home_Phone] = Atbl.[Home_Phone]'
    --+', [Cell_Phone] = Atbl.[Cell_Phone]'
    --+', [Work_Phone] = Atbl.[Work_Phone]'
    --+', [Work_Phone_Extension] = Atbl.[Work_Phone_Extension]'
    --+', [Pager] = Atbl.[Pager]'
    +', [Date_Created] = Atbl.[Answerdate]'
    +', [Audit_Date] = Atbl.[ChgDateTime]'
    --+', [Audit_Staff_ID] = Atbl.[Audit_Staff_ID]'
    --+', [Disabled] = Atbl.[Disabled]'
    --+', [Funding_Entity_ID] = Atbl.[Funding_Entity_ID]'
    --+', [Referral_Entity_ID] = Atbl.[Referral_Entity_ID]'
    --+', [Assigned_Staff_ID] = exref1.Entity_ID'     /* NurseID */
    +', [DEMO_CLIENT_INTAKE_0_ETHNICITY] = Atbl.[CLIENT_PERSONAL_0_ETHNICITY_INTAKE]'
    +', [DEMO_CLIENT_INTAKE_0_RACE] = Atbl.[CLIENT_PERSONAL_0_RACE]'
    --+', [DEMO_CLIENT_INTAKE_0_RACE_10] = Atbl.[DEMO_CLIENT_INTAKE_0_RACE_10]'
    +', [DEMO_CLIENT_INTAKE_0_LANGUAGE] = Atbl.[CLIENT_PERSONAL_LANGUAGE_0_INTAKE]'
    +', [CaseNumber] = Atbl.[Client_0_ID_Agency]'
    --+', [Last_Demog_Update] = Atbl.[Last_Demog_Update]'
    --+', [CLIENT_PERSONAL_LANGUAGE_1_DESC] = Atbl.[CLIENT_PERSONAL_LANGUAGE_1_DESC]'
    --+', [ReasonForReferral] = Atbl.[ReasonForReferral]'
    --+', [DEMO_CLIENT_INTAKE_0_ANCESTRY] = Atbl.[DEMO_CLIENT_INTAKE_0_ANCESTRY]'
    +', [DW_AuditDate] = convert(datetime,'''+convert(varchar(23),@runtime,126)+''',126)'
    +'
     from dbo.Clients dwclients'
    +' inner join dbo.Non_ETO_Client_Xref xref on xref.source = ''' +@p_datasource +''''
    +'  and dwclients.Client_ID = xref.Client_ID'
    +' 
     inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename +' Atbl'
    +' on xref.Non_ETO_ID = Atbl.Client_0_id_agency'
    +' 
     left join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.Clinic Clinic'
    +'  on Atbl.SiteCode = Clinic.Clinic_no'
    +' 
     left join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.ClinicSite ClinicSite'
    +'  on Clinic.ClinicID = ClinicSite.ClinicID'
    +' 
     left join dbo.Non_ETO_Entity_Xref exref1 on exref1.Source =  ''' +@p_datasource +''''
    +'   and exref1.Non_ETO_ID = Atbl.NurseID'
    +'
     where dwclients.Datasource = ''' +@p_datasource +''''
    +' and isnull(dwclients.Audit_Date,convert(datetime,''19700101'',112)) < 
           isnull(Atbl.ChgDateTime,convert(datetime,''19700101'',112))'

    print @SQL
    EXEC (@SQL)



----------------------------------------------------------------------------------------
print '  Cont: SP_OK_CLIENTS - Delete Contacts that no longer exist in AgencyDB'

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
    +' and not exists (select Atbl.Client_0_id_agency'
    +' from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.' +@Source_Tablename +' Atbl'
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

print 'End of Process: SP_OK_CLIENTS'
GO
