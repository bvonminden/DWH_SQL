USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_Programs_main]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_Programs_main
--
CREATE PROCEDURE [dbo].[SP_Programs_main]
AS
--
-- This script controls updates to the Programs table in the Data Warehouse.
--
-- References DB: CRMSRVR.Nurse_FamilyPartnership_MSCRM
--                DW.Programs
--                DW.EntityXPrograms
--                DW.EntityXProgramHx
--
-- History:
--    20121104 - Changed to update programs for team's new_nfpagencylocationid (was only doing when originally null)
--    20130423 - Added logic to exclude processing of specified sites via dbo.Sites_Excluded.
--    20130718 - Added additional validation on EntityXProgram updates to look for difference in start/end dates,
--               which catches ETO not setting an audit date when programs is changed or ended.
--    20131111 - Added EntityXProgramsHx table updates,
--               Modified EntityXprograms and EntityXProgramsHx to accommodate datasource, and SourceID
--               to accommodate non-ETO data (AgencyDB scripts), thus processing only 'ETO' data.
--               Change to EntityXProgramsHx so that updates / deletes replace truncation of table.
--    20140812 - Added logic to ignore excluded sites when the 'EntityXPrograms','EntityXProgramHx' 
--               are included in the tables_to_ignore field.
--    20160629 - Added logic to handle program/team associations for non-ETO (AgencyDB sites).

DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_PROGRAMS_MAIN'

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
-- Process the Programs
----------------------------------------------------------------------------------------
-- print 'Processing SP_programs_main - Insert new Programs'

---------------------------------------------
set nocount on
update dbo.process_log 
   set Phase = 'Add New Programs'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

insert into dbo.Programs
      (Program_ID
      ,Program_NAME
      ,Site_ID
      ,Supervisor_ID
      ,AuditDate)
select Programs.ProgramID
      ,Programs.ProgramName
      ,Sites.SiteID
      ,dbo.FN_ETO_Program_Supervisor_ID(Programs.ProgramID)
      ,Programs.AuditDate
  from ETOSRVR.etosolaris.dbo.Programs Programs
  LEFT JOIN ETOSRVR.etosolaris.dbo.Staff Staff
         on Programs.AuditStaffID = Staff.StaffID 
  LEFT JOIN ETOSRVR.etosolaris.dbo.sites Sites
         on Staff.SiteID = Sites.SiteID
 where not exists (select nfpprograms.Program_ID
                     from dbo.Programs nfpprograms
                    where nfpprograms.Program_Id = programs.ProgramId)
   and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = Sites.SiteId
                      and isnull(ex2.tables_to_ignore,'') not like 'PROGRAMS');



----------------------------------------------------------------------------------------
--print '  Cont: SP_programs_main - Updating Program changes'

---------------------------------------------
set nocount on
update dbo.process_log 
   set Phase = 'Update Existing Programs'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

Update dbo.Programs
   set Program_NAME = ETOPrograms.ProgramName
      ,auditdate = ETOPrograms.AuditDate
  from dbo.Programs Programs
  INNER JOIN ETOSRVR.etosolaris.dbo.Programs ETOPrograms
          ON ETOPrograms.ProgramID = Programs.Program_ID
 where ETOPrograms.AuditDate > isnull(Programs.AuditDate,convert(datetime,'19700101',112))
   and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = Programs.Site_Id
                      and isnull(ex2.tables_to_ignore,'') not like 'PROGRAMS');


----------------------------------------------------------------------------------------
--print '  Cont: SP_programs_main - Match Staff Program Group to each Program '

---------------------------------------------
set nocount on
update dbo.process_log 
   set Phase = 'Update Programs Teams'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- Update ETO maintained programs:
update dbo.Programs
   set Team_Group_Name = pdg.ProgramDemoGroup
      ,CRM_new_nfpagencylocationid = null
from dbo.Programs programs
left join ETOSRVR.etosolaris.dbo.ProgramXProgramDemoGroups xpdg
     on programs.Program_ID = xpdg.ProgramID
left join ETOSRVR.etosolaris.dbo.ProgramDemoGroups pdg
     on xpdg.ProgramDemoGroupID = pdg.ProgramDemoGroupID
left join ETOSRVR.etosolaris.dbo.ProgramGroupTypes pgt
     on pdg.ProgramGroupTypeID = pgt.ProgramGroupTypeID
 where upper(programs.Program_Name) like '%STAFF SUPERVISION%'
   and pgt.ProgramGroupType = 'Team'
   and isnull(programs.Team_Group_Name,'YYYY') != isnull(pdg.ProgramDemoGroup,'XXXX')
   and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = Programs.Site_Id
                      and isnull(ex2.tables_to_ignore,'') not like 'PROGRAMS')


----------------------------------------------------------------------------------------
--print '  Cont: SP_programs_main - Updating CRM Team Locations'

---------------------------------------------
set nocount on
update dbo.process_log 
   set Phase = 'Update Programs Teams from CRM'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- (delete and rebuild team locations)

delete from dbo.crm_team_locations;

insert into dbo.CRM_Team_Locations
     (new_nfpagencylocationid, New_Name, new_NFPOrganizationID)
select new_nfpagencylocationid, New_Name, new_NFPOrganizationID
 from CRMSRVR.Nurse_FamilyPartnership_MSCRM.dbo.new_nfpagencylocationextensionbase nfpALEB
 where not exists( select new_nfpagencylocationid 
                     from dbo.CRM_Team_Locations
                    where new_nfpagencylocationid =
                          nfpALEB.new_nfpagencylocationid)


-- Update ETO programs matching Team_Group_Name (team names) to get CRM locationid
update dbo.Programs
   set CRM_new_nfpagencylocationid = CRMtl.new_nfpagencylocationid
--      ,AuditDate = getdate()
from dbo.Programs programs
left join dbo.CRM_Team_Locations CRMtl
       on programs.team_group_name = crmtl.New_Name
where programs.team_group_name is not null
  and isnull(convert(varchar(36),programs.CRM_new_nfpagencylocationid),'abcdef') 
         != isnull(convert(varchar(36),CRMtl.new_nfpagencylocationid),'uvwxyz')
   and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = Programs.Site_Id
                      and isnull(ex2.tables_to_ignore,'') not like 'PROGRAMS')



-- Update non-ETO (AgencyDB) Programs for CRM link  (updating only once when found to be null)
--   ** updating only when field is null:
update dbo.Programs
   set Team_Group_Name = isnull(Team_Group_Name,crmtl.New_Name)
      ,CRM_new_nfpagencylocationid = isnull(CRM_new_nfpagencylocationid,CRMtl.new_nfpagencylocationid)
      ,auditdate = GETDATE()
from dbo.Programs programs
inner join dbo.teams on programs.team_id = teams.team_id
left join dbo.CRM_Team_Locations CRMtl
       on teams.team_name = crmtl.New_Name
where (programs.team_group_name is null or
       programs.CRM_new_nfpagencylocationid is null 
       --or (isnull(convert(varchar(36),programs.CRM_new_nfpagencylocationid),'abcdef') 
       --    != isnull(convert(varchar(36),CRMtl.new_nfpagencylocationid),'uvwxyz') ) 
       )
   and programs.Program_Name like '%staff%'
   and programs.site_id in (select Site_ID from dbo.Sites_Excluded ex2
                             where ex2.Site_Id = Programs.Site_Id)
   and CRMtl.New_Name is not null



----------------------------------------------------------------------------------------
--print '  Cont: SP_programs_main - Updating Supervisors'

      set nocount on
      update dbo.process_log 
         set Phase = 'Update Supervisors'
            ,LogDate = getdate()
       where Process = @process

Update dbo.Programs
   set Supervisor_ID = dbo.FN_ETO_Program_Supervisor_ID(Programs.Program_ID)
--      ,AuditDate = getdate()
  from dbo.Programs Programs
 where isnull(Programs.Supervisor_ID,'99999999') != isnull(dbo.FN_ETO_Program_Supervisor_ID(Programs.Program_ID),'99999999')
   and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = Programs.Site_Id
                      and isnull(ex2.tables_to_ignore,'') not like 'PROGRAMS')



----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--print '  Cont: SP_programs_main - Inserting new EntityXPrograms'

---------------------------------------------
      set nocount on
      update dbo.process_log 
         set Phase = 'Inserting EntityXPrograms'
            ,LogDate = getdate()
       where Process = @process
---------------------------------------------

insert into dbo.EntityXPrograms
      (DataSource
      ,EntityXProgram_ID
      ,Entity_ID
      ,Program_ID
      ,StartDate
      ,EndDate
      ,AuditDate)
select 'ETO'
      ,XPrograms.EntityXProgramID
      ,XPrograms.EntityID
      ,XPrograms.ProgramID
      ,XPrograms.StartDate
      ,XPrograms.EndDate
      ,XPrograms.AuditDate
  from ETOSRVR.etosolaris.dbo.EntityXProgram XPrograms
 where not exists (select nfpxprograms.Program_ID
                     from dbo.EntityXPrograms nfpxprograms
                    where nfpxprograms.EntityXProgram_Id = xprograms.EntityXProgramId
                      and nfpxprograms.DataSource = 'ETO')
   and not exists (select ex2.Site_ID 
                     from dbo.programs
                     inner join dbo.Sites_Excluded ex2 on ex2.Site_Id = Programs.Site_Id
                    where Programs.Program_Id = xPrograms.ProgramID
                      and isnull(ex2.tables_to_ignore,'') not like '%EntityXPrograms%');


----------------------------------------------------------------------------------------
--print '  Cont: SP_programs_main - Deleting dropped EntityXPrograms'

---------------------------------------------
      set nocount on
      update dbo.process_log 
         set Phase = 'Deleting EntityXPrograms'
            ,LogDate = getdate()
       where Process = @process
---------------------------------------------

-- Clean up records which have been deleted in ETO:
delete dbo.EntityXPrograms
where EntityXProgram_Id in
(select EntityXProgram_Id
  from dbo.EntityXPrograms nfpxprograms
 where nfpxprograms.DataSource = 'ETO'
   and not exists (select XPrograms.ProgramID
                     from ETOSRVR.etosolaris.dbo.EntityXProgram XPrograms
                    where nfpxprograms.EntityXProgram_Id = xprograms.EntityXProgramId)
);

----------------------------------------------------------------------------------------
--print '  Cont: SP_programs_main - Updating existing EntityXPrograms'

---------------------------------------------
      set nocount on
      update dbo.process_log 
         set Phase = 'Update EntityXPrograms'
            ,LogDate = getdate()
       where Process = @process
---------------------------------------------

update dbo.EntityXPrograms
   set StartDate = ETOXPrograms.StartDate
      ,EndDate = ETOXPrograms.EndDate
      ,AuditDate = ETOXPrograms.AuditDate
  from dbo.EntityXPrograms
  inner join ETOSRVR.etosolaris.dbo.EntityXProgram ETOXPrograms
          on EntityXPrograms.EntityXProgram_ID = ETOXPrograms.EntityXProgramID
 where EntityXPrograms.DataSource = 'ETO'
   and (ETOXPrograms.AuditDate > isnull(EntityXPrograms.AuditDate,convert(datetime,'19700101',112)) 
        or isnull(ETOXPrograms.StartDate,convert(datetime,'19700101',112)) != 
              isnull(EntityXPrograms.Startdate,convert(datetime,'19700101',112)) 
        or isnull(ETOXPrograms.EndDate,convert(datetime,'19700101',112)) != 
              isnull(EntityXPrograms.Enddate,convert(datetime,'19700101',112)) )
   and not exists (select ex2.Site_ID 
                     from dbo.programs
                     inner join dbo.Sites_Excluded ex2 on ex2.Site_Id = Programs.Site_Id
                    where Programs.Program_Id = EntityXPrograms.Program_ID
                      and isnull(ex2.tables_to_ignore,'') not like '%EntityXPrograms%');



----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--print '  Cont: SP_programs_main - Inserting new EntityXProgramHx'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Inserting EntityXProgramHx'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- Basic insert for non-existing records:
insert into dbo.EntityXProgramHx
      (DataSource
      ,[EntityXProgramHxID]
      ,[EntityXProgramID]
      ,[EntityID]
      ,[ProgramID]
      ,[StartDate]
      ,[EndDate]
      ,[AuditStaffID]
      ,[AuditDate])
SELECT 'ETO'
      ,[EntityXProgramHxID]
      ,[EntityXProgramID]
      ,[EntityID]
      ,[ProgramID]
      ,[StartDate]
      ,[EndDate]
      ,[AuditStaffID]
      ,[AuditDate]
  from ETOSRVR.etosolaris.dbo.EntityXProgramHx ETOProgramHx
  inner join dbo.IA_Staff on ETOProgramHx.EntityID = IA_Staff.Entity_ID
 where not exists (select nfpxprogramHx.EntityXProgramHXID
                     from dbo.EntityXProgramHx nfpxprogramHx
                    where nfpxprogramHx.EntityXProgramHxId = ETOProgramHx.EntityXProgramHxId
                      and nfpxprogramHx.DataSource = 'ETO')
   and not exists (select ex2.Site_ID 
                     from dbo.programs
                     inner join dbo.Sites_Excluded ex2 on ex2.Site_Id = Programs.Site_Id
                    where Programs.Program_Id = ETOProgramHx.ProgramID
                      and isnull(ex2.tables_to_ignore,'') not like '%EntityXProgramHx%');


----------------------------------------------------------------------------------------
--print '  Cont: SP_programs_main - Updating EntityXProgramsHx'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating EntityXProgramsHx'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

Update dbo.EntityXProgramHX
   set EntityID = ETOXProgramsHX.EntityID
      ,ProgramID = ETOXProgramsHX.ProgramID
      ,StartDate = ETOXProgramsHX.StartDate
      ,EndDate = ETOXProgramsHX.EndDate
      ,AuditStaffID = ETOXProgramsHX.AuditStaffID
      ,AuditDate = ETOXProgramsHX.AuditDate
  from dbo.EntityXProgramHx nfpexpx
  inner join ETOSRVR.etosolaris.dbo.EntityXProgramHx ETOXProgramsHX
          on nfpexpx.EntityXProgramHxID = ETOXProgramsHX.EntityXProgramHxID
 where nfpexpx.DataSource = 'ETO'
   and (ETOXProgramsHX.AuditDate > isnull(NFPexpx.AuditDate,convert(datetime,'19700101',112)) 
        or isnull(ETOXProgramsHX.StartDate,convert(datetime,'19700101',112)) != 
              isnull(NFPexpx.Startdate,convert(datetime,'19700101',112)) 
        or isnull(ETOXProgramsHX.EndDate,convert(datetime,'19700101',112)) != 
              isnull(NFPexpx.Enddate,convert(datetime,'19700101',112)) )
   and not exists (select ex2.Site_ID 
                     from dbo.programs
                     inner join dbo.Sites_Excluded ex2 on ex2.Site_Id = Programs.Site_Id
                    where Programs.Program_Id = nfpexpx.ProgramID
                      and isnull(ex2.tables_to_ignore,'') not like '%EntityXProgramHx%');

----------------------------------------------------------------------------------------
--print '  Cont: SP_programs_main - Deleting dropped EntityXProgramHx'

---------------------------------------------
      set nocount on
      update dbo.process_log 
         set Phase = 'Deleting EntityXProgramHx'
            ,LogDate = getdate()
       where Process = @process
---------------------------------------------

-- Clean up records which have been deleted in ETO:
delete dbo.EntityXProgramHx
where EntityXProgramHxId in
(select EntityXProgramHxId
  from dbo.EntityXProgramHx nfpxprogramHx
 where nfpxprogramHx.DataSource = 'ETO'
   and not exists (select XPrograms.EntityxProgramHXID
                     from ETOSRVR.etosolaris.dbo.EntityXProgramHx XPrograms
                    where nfpxprogramHx.EntityXProgramHxId = xprograms.EntityXProgramHxId) 
);

---------------------------------------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

print '  End of Process: SP_Program_main'
GO
