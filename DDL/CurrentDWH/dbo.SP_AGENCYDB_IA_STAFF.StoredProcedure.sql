USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_AGENCYDB_IA_STAFF]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_AGENCYDB_IA_STAFF
--
CREATE PROCEDURE [dbo].[SP_AGENCYDB_IA_STAFF]
 (@p_datasource      nvarchar(10) = null
 ,@p_entity_id       int = null
 ,@p_no_exec_flag    nvarchar(10) = 'N')
AS
--
-- This script controls integration of AgencyDB Staff to the Data Warehous IA_Staff table.
--
-- ** Temporary solution until the Contacts tables replace the IA_Staff
--
-- Will exclude from DW if Site Does not exist in dbo.agencies
--
-- Table effected - dbo.IA_Staff
--
-- Insert: select and insert when record is found to be missing in the DW.
-- Update: select and update when record exists in DW and has been changed but has been changed flagged by Audit_Date.
--
-- History:
--   20130325 - New Procedure.
--   20130711 - Amendment to accommodate pre-existing LMS non-ETO IA_Staff record.
--   20130827 - Added Disabled indicator to integration.
--   20140114 - Removed usage of Audit_Staff_ID.
--   20140214 - Added site_id to non-ETO_Xref.  This will allow the site_id to represent uniqueness between companies,
--              thus allowing the same entity_id's to be utilized by different Agencydb sites (company).
--   20140324 - Added Site_ID qualifier by datasource, to allow multiple datasources to share the same AgencyDB.
--              Added database trigger to inhibit the processing of this procedure (defaulting as always process).
--                This trigger is used to bypass the process w/o having to modify the SSIS integration packages.
--   20140708 - Amended update to datasource to relate null as 'ETO'.
--   20140830 - Changed to utilize the ETO IA_Staff record if found, and create xref from client defined ID to orig ETO_ID;
--              else, create new xref record with next available Non_Entity_ID in sequence.
--   20140917 - Added exclusion of Agency type (17) IA_Staff records.
--   20150207 - changed to qualify LMS non_eto based upon last_name, first_name instead of full name.
--              Issues arose because of formatting with extra spaces in the middle name area.
--   20150212 - Added the re-mapping of existing ETO records for the same site_id that match the AgencyDB.ETO_Entity_ID.
--              (modified the section of re-mapping to ETO_ENTITY_ID to map only to datasoure 'ETO',
--               then will update the ia_staff.datasource to the agencydb datasource, 
--               thus removing the need to manually update the ia_staff.datasource for a re-map)
--              Added option to not actually execute the SQL statements, used for validation/troubleshooting purposes.
--   20150901 - Added more formatting in status print out.
--   20151119 - Amended to disable IA_Staff records, when no longer existing in the AgencyDB.

DECLARE @count          smallint
DECLARE @stop_flag      nvarchar(2)
DECLARE @Process        nvarchar(50)
DECLARE @AgencyDB_Srvr  nvarchar(30)

set @process = 'SP_AGENCYDB_IA_STAFF'
Set @stop_flag = null
set @AgencyDB_Srvr = 'AGENCYDBSRVR'

DECLARE @AgencyDB       nvarchar(30)
DECLARE @SQL            nvarchar(4000)

print 'Processing SP_AGENCYDB_IA_STAFF: Datasource = ' +isnull(@p_datasource,'NULL')
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
print 'Processing SP_AGENCYDB_IA_STAFF - Check for run inhibit trigger'

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
print 'Processing SP_Contacts - Insert new staff members - AgencyDB=' + @AgencyDB
print 'AgencyDB Server=' +@AgencyDB_Srvr

-- Extraction for Entity:

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Staff'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

print ' '
print 'Re-map existing non_eto_xref records identified as originating from LMS'

-- Check for existing LMS non_ETO_xref that matches by name or CRM_ContactID,
-- If found, override the LMS non_ETO_exref remapping to the new source AgencyDB and entity_id.
-- This is to accommodate people being entered into LMS prior to an AgencyDB integration

-- update existing non_eto_xref records for remap to data originating from LMS:
set @SQL = 'set nocount off'+
     ' update dbo.Non_ETO_Entity_Xref'
    +'   set Non_ETO_ID = AIS.Entity_id'
    +'  ,prior_source = dwxref1.source'
    +'  ,Source = ''' +@p_datasource +''''
    +'  ,Non_ETO_Site_ID = AIS.site_id'
    +'
       from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.IA_Staff AIS'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = AIS.Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +'''' 
    +' inner join dbo.IA_Staff on AIS.Site_ID = IA_Staff.Site_ID'
          +' and ( (AIS.ETO_Entity_ID = IA_Staff.Entity_Id) or'
                +' (upper(AIS.last_name) = upper(IA_Staff.last_Name) and'
                 +' upper(AIS.first_name) = upper(IA_Staff.first_Name) ) or'
                +' (AIS.crm_contactid = IA_Staff.CRM_ContactId and IA_Staff.CRM_ContactId is not null) or'
                +' (AIS.ETO_Entity_ID = IA_Staff.Entity_Id and AIS.Site_ID = IA_Staff.Site_ID)'
               +')'
    +' inner join dbo.Non_ETO_Entity_Xref dwxref1 on IA_Staff.Entity_Id = dwxref1.Entity_ID'
    +' where isnull(AIS.Entity_Type_ID,22) != 17'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', AIS.Site_ID) is null'
    +' and isnull(dwxref1.Source,''ETO'') = ''LMS'''
    +' and not exists '
    +'  (select dwxref.Entity_ID'
    +'    from dbo.Non_ETO_Entity_Xref dwxref'
    +'    where dwxref.source = ''' +@p_datasource +''''
    +'    and dwxref.Non_ETO_ID = AIS.Entity_Id'
    +'    and dwxref.Non_ETO_Site_ID = AIS.Site_ID)'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    exec (@SQL)


print ' '
print 'Create new non_eto_xref for new IA_Staff records from AgencyDB (that originate from ETO)'

-- create non_ETO xref entries for new IA_Staff records from AgencyDB (that originate from ETO):
-- This is driven by the AgencyDB record containing the original ETO Entity_ID 
-- (or one that has been set to an existing IA_Staff record)
set @SQL = 'set nocount off '+
     ' set identity_insert dbo.non_eto_entity_xref on '
    +'  insert into dbo.Non_ETO_Entity_Xref'
    +' (Entity_ID, Non_ETO_ID, Non_ETO_Site_ID, prior_source, Source)'
    +'
     select AIS.ETO_Entity_ID, AIS.entity_id, AIS.Site_ID, isnull(dwIA_Staff.DataSource,''ETO''), ''' +@p_datasource +''''
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.IA_Staff AIS'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = AIS.Site_ID'
          +' and asbd.DataSource =  ''' +@p_datasource +''''
    +' inner join dbo.IA_Staff dwIA_Staff on AIS.ETO_Entity_ID = dwIA_Staff.Entity_ID'
          +' and AIS.Site_ID = dwIA_Staff.Site_ID'
          +' and isnull(dwIA_Staff.DataSource,''ETO'') = ''ETO'''
    +' where isnull(AIS.ETO_Entity_ID,0) != 0'
    +' and isnull(AIS.Entity_Type_ID,22) != 17'
    +' and not exists (select dwxref.Entity_ID'
    +'   from dbo.Non_ETO_Entity_Xref dwxref'
    +'   where dwxref.source = ''' +@p_datasource +''''
    +'   and dwxref.Non_ETO_ID = AIS.Entity_Id'
    +'   and dwxref.Non_ETO_Site_ID = AIS.Site_ID)'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', AIS.Site_ID) is null'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    exec (@SQL)


print ' '
print 'Update non_eto_xref with new datasource for remapped records'

-- update the Ia_Staff datasource for any new re-mapping of non-eto-exref records
set @SQL = 'set nocount off '+
     ' update dbo.IA_Staff'
    +'   set DataSource = dwxref.source'
    +'   from dbo.Non_ETO_Entity_Xref dwxref'
    +'   inner join dbo.IA_Staff on dwxref.Entity_id = Ia_staff.Entity_id'
    +'     and dwxref.prior_source = isnull(ia_staff.datasource,''ETO'')'
    +'   where dwxref.Prior_Source is not null'
    +'   and dwxref.Prior_Source != dwxref.Source'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    exec (@SQL)


print ' '
print 'Create new non_eto_xref for new IA_Staff records from AgencyDB (that did not originate from ETO)'

-- create non_ETO xref entries for new IA_Staff records from AgencyDB (that did not originate from ETO):
set @SQL = 'set nocount off '+
     '  set identity_insert dbo.non_eto_entity_xref off '
    +' insert into dbo.Non_ETO_Entity_Xref'
    +' (Non_ETO_ID, Non_ETO_Site_ID, Source)'
    +'
     select AIS.entity_id, AIS.Site_ID, ''' +@p_datasource +''''
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.IA_Staff AIS'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = AIS.Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' where isnull(AIS.Entity_Type_ID,22) != 17'
    +'   and not exists (select dwxref.Entity_ID'
    +'   from dbo.Non_ETO_Entity_Xref dwxref'
    +'   where dwxref.source = ''' +@p_datasource +''''
    +'   and dwxref.Non_ETO_ID = AIS.Entity_Id'
    +'   and dwxref.Non_ETO_Site_ID = AIS.Site_ID)'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', AIS.Site_ID) is null'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    exec (@SQL)


print ' '
print 'Update AgencyDB with the latest assigned NON-ETO_ID for the defined xref'

-- Update AgencyDB with the latest assigned NON-ETO_ID for the defined xref: 
--  (always updates in case agency overwrites or clears out DW_Entity_ID field):
set @SQL = 'set nocount off '+
    'update ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.IA_Staff'
    +' Set [DW_Entity_ID] = dwxref.[Entity_ID]'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.IA_Staff AIS'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = AIS.Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' inner join dbo.Non_ETO_Entity_Xref dwxref'
    +' on dwxref.Non_ETO_ID = AIS.Entity_ID and dwxref.source = ''' +@p_datasource +''''
    +'   and dwxref.Non_ETO_Site_ID = AIS.Site_ID'
    +' where dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', AIS.Site_ID) is null'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    exec (@SQL)


print ' '
print 'Insert into DW.IA_Staff for non-existing staff records from AgencyDB'

set @SQL = 'set nocount off '+
     ' insert into dbo.IA_Staff'
    +' ([Entity_ID],[DataSource],[Site_ID]'
    +' ,[Full_Name],[Last_Name],[First_Name],[Middle_Name]'
    +' ,[Prefix],[Suffix],[Entity_Type_ID],[Entity_Type],[Entity_Subtype],[Entity_Subtype_ID]'
    +' ,[Program_ID],[Address1],[Address2],[City],[State],[ZipCode],[county],[Email],[Phone1]'
    +' ,[Supervised_By_ID],[START_DATE],[Termination_Date]'
    +' ,[NHV_ID],[NURSE_0_ETHNICITY]'
    +' ,[NURSE_1_RACE],[NURSE_1_RACE_0],[NURSE_1_RACE_1],[NURSE_1_RACE_2],[NURSE_1_RACE_3]'
    +' ,[NURSE_1_RACE_4],[NURSE_1_RACE_5],[NURSE_0_GENDER]'
    +' ,[NURSE_0_YEAR_COMMHEALTH_EXPERIENCE],[NURSE_0_YEAR_NURSING_EXPERIENCE]'
    +' ,[NURSE_0_YEAR_MATERNAL_EXPERIENCE],[NURSE_0_FIRST_HOME_VISIT_DATE]'
    +' ,[NURSE_0_LANGUAGE],[NURSE_0_YEAR_SUPERVISOR_EXPERIENCE],[NURSE_0_BIRTH_YEAR]'
    +' ,[NURSE_0_ID_AGENCY],[NURSE_0_PROGRAM_POSITION1],[NURSE_0_PROGRAM_POSITION2]'
    +' ,[NURSE_PROFESSIONAL_1_REASON_HIRE]'
    +' ,[Date_Created],[Audit_Date]'
    --+' ,[Audit_Staff_ID]'
    +' ,[flag_disregard_disabled],[Disabled])'
    +'
     select  DW_Entity_ID as Entity_ID, ''' +@p_datasource +''''
    +' ,AIS.[Site_ID]'
    +' ,AIS.[Full_Name],AIS.[Last_Name],AIS.[First_Name],AIS.[Middle_Name]'
    +' ,AIS.[Prefix],AIS.[Suffix],AIS.[Entity_Type_ID],AIS.[Entity_Type],AIS.[Entity_Subtype],AIS.[Entity_Subtype_ID]'
    +' ,AIS.[Program_ID],AIS.[Address1],AIS.[Address2],AIS.[City],AIS.[State],AIS.[ZipCode],AIS.[county]'
    +' ,AIS.[Email],AIS.[Phone1],AIS.[Supervised_By_ID],AIS.[START_DATE],AIS.[Termination_Date]'
    +' ,AIS.[NHV_ID],AIS.[NURSE_0_ETHNICITY]'
    +' ,AIS.[NURSE_1_RACE],AIS.[NURSE_1_RACE_0],AIS.[NURSE_1_RACE_1],AIS.[NURSE_1_RACE_2],AIS.[NURSE_1_RACE_3]'
    +' ,AIS.[NURSE_1_RACE_4],AIS.[NURSE_1_RACE_5],AIS.[NURSE_0_GENDER]'
    +' ,AIS.[NURSE_0_YEAR_COMMHEALTH_EXPERIENCE],AIS.[NURSE_0_YEAR_NURSING_EXPERIENCE]'
    +' ,AIS.[NURSE_0_YEAR_MATERNAL_EXPERIENCE],AIS.[NURSE_0_FIRST_HOME_VISIT_DATE]'
    +' ,AIS.[NURSE_0_LANGUAGE],AIS.[NURSE_0_YEAR_SUPERVISOR_EXPERIENCE],AIS.[NURSE_0_BIRTH_YEAR]'
    +' ,AIS.[NURSE_0_ID_AGENCY],AIS.[NURSE_0_PROGRAM_POSITION1],AIS.[NURSE_0_PROGRAM_POSITION2]'
    +' ,AIS.[NURSE_PROFESSIONAL_1_REASON_HIRE]'
    +' ,AIS.[Date_Created],AIS.[Audit_Date]'
    --+' ,AIS.[Audit_Staff_ID]'
    +' ,AIS.[flag_disregard_disabled],AIS.[Disabled]'
    +'
     from ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.IA_Staff AIS'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = AIS.Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' where AIS.DW_Entity_ID is not null'
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', AIS.Site_ID) is null'
    +' and not exists (select dwstaff.Entity_ID'
    +' from dbo.IA_Staff dwstaff'
    +' where dwstaff.Datasource = ''' +@p_datasource +''''
    +' and dwstaff.Entity_Id = AIS.DW_Entity_Id)'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    exec (@SQL)


----------------------------------------------------------------------------------------
print '  Cont: SP_AGENCYDB_IA_STAFF - Update staff changes'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing Staff'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

print ' '
print 'Update IA_Staff for record changes'

set @SQL = 'set nocount off '+
    'update dbo.IA_Staff'
    +' Set [Site_ID] = AIS.[Site_ID]'
    +', [Full_Name] = AIS.[Full_Name]'
    +', [Last_Name] = AIS.[Last_Name]'
    +', [First_Name] = AIS.[First_Name]'
    +', [Middle_Name] = AIS.[Middle_Name]'
    +', [Prefix] = AIS.[Prefix]'
    +', [Suffix] = AIS.[Suffix]'
    +', [Entity_Type_ID] = AIS.[Entity_Type_ID]'
    +', [Entity_Type] = AIS.[Entity_Type]'
    +', [Entity_Subtype] = AIS.[Entity_Subtype]'
    +', [Entity_Subtype_ID] = AIS.[Entity_Subtype_ID]'
    +', [Program_ID] = AIS.[Program_ID]'
    +', [Address1] = AIS.[Address1]'
    +', [Address2] = AIS.[Address2]'
    +', [City] = AIS.[City]'
    +', [State] = AIS.[State]'
    +', [ZipCode] = AIS.[ZipCode]'
    +', [county] = AIS.[county]'
    +', [Email] = AIS.[Email]'
    +', [Phone1] = AIS.[Phone1]'
    +', [Supervised_By_ID] = AIS.[Supervised_By_ID]'
    +', [START_DATE] = AIS.[START_DATE]'
    +', [Termination_Date] = AIS.[Termination_Date]'
    +', [NHV_ID] = AIS.[NHV_ID]'
    +', [NURSE_0_ETHNICITY] = AIS.[NURSE_0_ETHNICITY]'
    +', [NURSE_1_RACE] = AIS.[NURSE_1_RACE]'
    +', [NURSE_1_RACE_0] = AIS.[NURSE_1_RACE_0]'
    +', [NURSE_1_RACE_1] = AIS.[NURSE_1_RACE_1]'
    +', [NURSE_1_RACE_2] = AIS.[NURSE_1_RACE_2]'
    +', [NURSE_1_RACE_3] = AIS.[NURSE_1_RACE_3]'
    +', [NURSE_1_RACE_4] = AIS.[NURSE_1_RACE_4]'
    +', [NURSE_1_RACE_5] = AIS.[NURSE_1_RACE_5]'
    +', [NURSE_0_GENDER] = AIS.[NURSE_0_GENDER]'
    +', [NURSE_0_YEAR_COMMHEALTH_EXPERIENCE] = AIS.[NURSE_0_YEAR_COMMHEALTH_EXPERIENCE]'
    +', [NURSE_0_YEAR_NURSING_EXPERIENCE] = AIS.[NURSE_0_YEAR_NURSING_EXPERIENCE]'
    +', [NURSE_0_YEAR_MATERNAL_EXPERIENCE] = AIS.[NURSE_0_YEAR_MATERNAL_EXPERIENCE]'
    +', [NURSE_0_FIRST_HOME_VISIT_DATE] = AIS.[NURSE_0_FIRST_HOME_VISIT_DATE]'
    +', [NURSE_0_LANGUAGE] = AIS.[NURSE_0_LANGUAGE]'
    +', [NURSE_0_YEAR_SUPERVISOR_EXPERIENCE] = AIS.[NURSE_0_YEAR_SUPERVISOR_EXPERIENCE]'
    +', [NURSE_0_BIRTH_YEAR] = AIS.[NURSE_0_BIRTH_YEAR]'
    +', [NURSE_0_ID_AGENCY] = AIS.[NURSE_0_ID_AGENCY]'
    +', [NURSE_0_PROGRAM_POSITION1] = AIS.[NURSE_0_PROGRAM_POSITION1]'
    +', [NURSE_0_PROGRAM_POSITION2] = AIS.[NURSE_0_PROGRAM_POSITION2]'
    +', [NURSE_PROFESSIONAL_1_REASON_HIRE] = AIS.[NURSE_PROFESSIONAL_1_REASON_HIRE]'
    +', [Date_Created] = AIS.[Date_Created]'
    +', [Audit_Date] = AIS.[Audit_Date]'
    +', [Contacts_Audit_Date] = AIS.[Contacts_Audit_Date]'
    --+', [Audit_Staff_ID] = AIS.[Audit_Staff_ID]'
    +', [Disabled] = AIS.[Disabled]'
    +'
     from dbo.IA_Staff dwstaff'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.IA_Staff AIS'
    +'   on dwstaff.Entity_ID = AIS.DW_Entity_ID'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = AIS.Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +'
     where dwstaff.Datasource = ''' +@p_datasource +''''
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', AIS.Site_ID) is null'
    +' and isnull(dwstaff.Audit_Date,convert(datetime,''19700101'',112)) < 
       isnull(AIS.Audit_Date,convert(datetime,''19700101'',112))'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    exec (@SQL)



print ' '
print 'Update IA_Staff CRM_ContactID and LMS_StudentID if not already identified in DW, but is within AgencyDB'

-- Update CRM_ContactID and LMS_StudentID if not already identified in DW, but is within AgencyDB:
set @SQL = 'set nocount off '+
    'update dbo.IA_Staff'
    +' Set [CRM_ContactID] = COALESCE(dwstaff.CRM_ContactID,AIS.CRM_ContactID)'
    +', [LMS_StudentID] = COALESCE(dwstaff.LMS_StudentID,AIS.LMS_StudentID)'
    +'
     from dbo.IA_Staff dwstaff'
    +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.IA_Staff AIS'
    +'   on dwstaff.Entity_ID = AIS.DW_Entity_ID'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on asbd.Site_ID = AIS.Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +'
     where dwstaff.Datasource = ''' +@p_datasource +''''
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', AIS.Site_ID) is null'
    +' and (dwstaff.CRM_ContactID is null and AIS.CRM_ContactID is not null or
            dwstaff.LMS_StudentID is null and AIS.LMS_StudentID is not null)'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    exec (@SQL)

----------------------------------------------------------------------------------------
print ' '
print '  Cont: SP_AGENCYDB_IA_STAFF - Disable IA_Staff records that no longer exist in AgencyDB'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Deleting ETO Deletions'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- Disable instead of delete becuase they could be historicaly referenced by surveys:
set @SQL =
    ' update dbo.IA_Staff set disabled = 1'
     +' from dbo.IA_Staff dwstaff'
    +' inner join dbo.AgencyDB_Sites_By_DataSource asbd on dwstaff.Site_ID = asbd.Site_ID'
    +'   and asbd.DataSource =  ''' +@p_datasource +''''
    +' where dwstaff.DataSource = ''' +@p_datasource +''''
    +' and dbo.FN_Check_Process_Inhibitor ('''+@process +'''' +', '''+@p_datasource +'''' +', dwstaff.Site_ID) is null'
    +' and not exists (select AIS.Entity_ID'
                      +' from dbo.Non_ETO_Entity_Xref dwxref'
                      +' inner join ' +@AgencyDB_Srvr +'.' +@AgencyDB +'.dbo.IA_Staff AIS'
                           +' on dwxref.non_eto_id = AIS.Entity_ID'
                     +' where dwxref.entity_id = dwstaff.entity_id '
                       +' and dwxref.source = ''' +@p_datasource +'''' +')'

    print @SQL
    IF upper(@p_no_exec_flag) != 'Y'
    exec (@SQL)

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

print 'End of Process: SP_AGENCYDB_IA_STAFF'
GO
