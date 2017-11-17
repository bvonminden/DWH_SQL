USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_teams_main]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_teams_main
--
CREATE PROCEDURE [dbo].[SP_teams_main]
AS
--
-- This script controls updates to the teams table in the Data Warehouse.
-- Processing ETO Entities identified as Billing Provider.
--
-- Table effected - dbo.Teams
--
-- Insert: select and insert when ETO team entity is found to be missing in the DW.
-- Update: select and update when ETO team entity exists in DW and has been changed in ETO.
--
-- Database Links:
-- CRM: CRMsrvr.Nurse_FamilyPartnership_MSCRM 

-- History:
--   20120830 - New program.
--   20121004 - Added program_id lookups for Supervised, NHV, and Referrals.
--   20121213 - Added logic for CRM matching and updates.
--              Amended for column name changes (Entity_ID to Team_ID).
--   20130423 - Added logic to exclude processing of specified sites via dbo.Sites_Excluded.
--   20130628 - Changed teams program assignment to pull in the last qualified programid found
--              thus preventing an SQL error when multiple program records were qualified.
--              'Update Team Programs' section, selectingmax(vtp.program_id_....)
--   20160629 - Amended to update the Teams.CRM_ID (New_nfpagencylocationid) regardless of site being ETO or not. 


DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_TEAMS_MAIN'

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
print ' '
print 'Processing SP_teams_main - Insert new Teams'
-- Extraction for Teams:

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New Teams'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- Basic Team info (standard attributes):
insert into dbo.Teams
      (Team_ID
      ,Team_Name
      ,Site_ID
      ,Entity_Type_ID
      ,Entity_Type 
      ,Entity_SubType_ID
      ,Entity_SubType 
      ,Team_Status
      ,Address1
      ,Address2 
      ,City
      ,State
      ,ZipCode
      ,County
      ,Phone1
      ,Date_Created
      ,Audit_Date
      ,Audit_Staff_ID
      ,Entity_Disabled
      ,Program_ID_Staff_Supervision
      ,Program_ID_NHV
      ,Program_ID_Referrals)
select Entities.EntityID
      ,EntityName
      ,Sites.SiteID
      ,EntityXEntityType.EntityTypeID
      ,EntityTypes.EntityType 
      ,EntityXEntityType.EntitySubTypeID
      ,EntitySubTypes.EntitySubType 
      ,null as Team_status
      ,Entities.Address1
      ,Entities.Address2 
      ,EZipCodes.City
      ,EZipCodes.State
      ,Entities.ZipCode
      ,EZipCodes.County
      ,Entities.GeneralPhoneNumber
      ,Entities.DateCreated
      ,Entities.AuditDate
      ,Entities.AuditStaffID
      ,Entities.disabled
      ,null
      ,null
      ,null
  from ETOSRVR.etosolaris.dbo.Entities Entities
  -- FYI Note: Possible secondary Type / Subtype selections
  LEFT JOIN ETOSRVR.etosolaris.dbo.EntityXEntityType EntityXEntityType
       JOIN ETOSRVR.etosolaris.dbo.EntityTypes EntityTypes
         ON EntityXEntityType.EntityTypeID = EntityTypes.EntityTypeID
  LEFT JOIN ETOSRVR.etosolaris.dbo.EntitySubTypes EntitySubTypes
         ON EntityXEntityType.EntitySubTypeID = EntitySubTypes.EntitySubTypeID
         ON Entities.EntityID = EntityXEntityType.EntityID
  LEFT JOIN ETOSRVR.etosolaris.dbo.Staff Staff
         on Entities.AuditStaffID = Staff.StaffID 
--  LEFT JOIN ETOSRVR.etosolaris.dbo.ZipCodes EZipCodes -- called locally from copied table
  LEFT JOIN dbo.PostalCodesUnduplicated EZipCodes
	 ON Entities.ZipCode = EZipCodes.ZipCode
  LEFT JOIN ETOSRVR.etosolaris.dbo.sites Sites
         on Staff.SiteID = Sites.SiteID
 where Entities.IsIndividual = 0
   and EntityXEntityType.EntityTypeID = 21
-- discregard disabled test entites:
--   and upper(substring(Entities.EntityName,1,4)) not in('TEST','FAKE')
   and not exists (select nfpteams.Team_ID
                     from dbo.Teams nfpteams
                    where nfpteams.Team_Id = Entities.EntityId)
   and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = Sites.SiteId);



----------------------------------------------------------------------------------------
print '  Cont: SP_Teams_main - Updating Teams basic changes'
-- Extraction for Team:

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing Teams'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

Update dbo.Teams
   set Team_Name = EntityName
      ,Site_ID = Sites.SiteID
      ,Entity_Type_ID = EntityXEntityType.EntityTypeID
      ,Entity_Type  = EntityTypes.EntityType 
      ,Entity_SubType_ID = EntityXEntityType.EntitySubTypeID
      ,Entity_SubType  = EntitySubTypes.EntitySubType 
--      ,Teams_Status = 
      ,Address1 = Entities.Address1
      ,Address2  = Entities.Address2
      ,City = EZipCodes.City
      ,State = EZipCodes.State
      ,ZipCode = Entities.ZipCode
      ,County = EZipCodes.County
      ,Phone1 = Entities.GeneralPhoneNumber
      ,Audit_Date = Entities.AuditDate
      ,Audit_Staff_ID = Entities.AuditStaffID
      ,Entity_Disabled = Entities.disabled
  from dbo.Teams Teams
  INNER JOIN ETOSRVR.etosolaris.dbo.Entities Entities
          ON Entities.EntityID = Teams.Team_ID
  -- FYI Note: Possible secondary Type / Subtype selections
  LEFT JOIN ETOSRVR.etosolaris.dbo.EntityXEntityType EntityXEntityType
       JOIN ETOSRVR.etosolaris.dbo.EntityTypes EntityTypes
         ON EntityXEntityType.EntityTypeID = EntityTypes.EntityTypeID
  LEFT JOIN ETOSRVR.etosolaris.dbo.EntitySubTypes EntitySubTypes
         ON EntityXEntityType.EntitySubTypeID = EntitySubTypes.EntitySubTypeID
         ON Entities.EntityID = EntityXEntityType.EntityID
  LEFT JOIN ETOSRVR.etosolaris.dbo.Staff Staff
         on Entities.AuditStaffID = Staff.StaffID 
--  LEFT JOIN ETOSRVR.etosolaris.dbo.ZipCodes EZipCodes   -- called locally from copied table
  LEFT JOIN PostalCodesUnduplicated EZipCodes   
	 ON Entities.ZipCode = EZipCodes.ZipCode
  LEFT JOIN ETOSRVR.etosolaris.dbo.sites Sites
         on Staff.SiteID = Sites.SiteID
 where Entities.IsIndividual = 0
   and (Teams.Audit_Date is null or
        Entities.AuditDate > Teams.Audit_Date)
   and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = Teams.Site_Id);


----------------------------------------------------------------------------------------
print '  Cont: SP_Teams_main - Update Team Programs'

update dbo.Teams
   set Programs_Audit_Date = GETDATE()
      ,Program_ID_Staff_Supervision = (select max(vtp.program_id_supr)
         from etosolaris.dbo.EntityXProgram exp
         left join dbo.view_team_programs vtp 
           on (vtp.program_id_supr = exp.ProgramID
            or vtp.program_id_nhv = exp.ProgramID
            or vtp.program_id_ref = exp.ProgramID)
            and vtp.ProgramGroupType = 'TEAM'
          where exp.EntityID = Teams.Team_id
            and exp.StartDate <= GETDATE()
            and isnull(exp.EndDate,dateadd(d,1,GETDATE())) >= GETDATE())
      ,Program_ID_NHV = (select max(vtp.program_id_nhv)
         from etosolaris.dbo.EntityXProgram exp
         left join dbo.view_team_programs vtp 
           on (vtp.program_id_supr = exp.ProgramID
            or vtp.program_id_nhv = exp.ProgramID
            or vtp.program_id_ref = exp.ProgramID)
            and vtp.ProgramGroupType = 'TEAM'
          where exp.EntityID = Teams.Team_id
            and exp.StartDate <= GETDATE()
            and isnull(exp.EndDate,dateadd(d,1,GETDATE())) >= GETDATE())
      ,Program_ID_Referrals = (select max(vtp.program_id_ref)
         from etosolaris.dbo.EntityXProgram exp
         left join dbo.view_team_programs vtp 
           on (vtp.program_id_supr = exp.ProgramID
            or vtp.program_id_nhv = exp.ProgramID
            or vtp.program_id_ref = exp.ProgramID)
            and vtp.ProgramGroupType = 'TEAM'
          where exp.EntityID = Teams.Team_id
            and exp.StartDate <= GETDATE()
            and isnull(exp.EndDate,dateadd(d,1,GETDATE())) >= GETDATE())
 where Team_ID in
 (select Team_Id 
    from dbo.Teams Teams
    inner join etosolaris.dbo.EntityXProgram exp ON Teams.Team_ID = exp.EntityID 
    left join dbo.view_team_programs vtp 
         on (vtp.program_id_supr = exp.ProgramID
            or vtp.program_id_nhv = exp.ProgramID
            or vtp.program_id_ref = exp.ProgramID)
            and vtp.ProgramGroupType = 'TEAM'
   where isnull(Teams.Program_ID_Staff_Supervision,'123456789') != isnull(vtp.program_id_supr,'123456789')
      or isnull(Teams.Program_ID_NHV,'123456789') != isnull(vtp.program_id_nhv,'123456789')
      or isnull(Teams.Program_ID_Referrals,'123456789') != isnull(vtp.program_id_ref,'123456789'))
   and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = Teams.Site_Id)


----------------------------------------------------------------------------------------
print '  Cont: SP_Teams_main - Delete ETO Deleted Entities'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Deleting ETO Deletions'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

delete dbo.Teams
  from dbo.Teams
 where isnull(DataSource,'ETO') = 'ETO'
   and not exists (select EntityID
                     from ETOSRVR.etosolaris.dbo.Entities Entities
                    where EntityID = Teams.Team_ID)
   and not exists (select Site_ID from dbo.Sites_Excluded ex2
                    where ex2.Site_Id = Teams.Site_Id)



----------------------------------------------------------------------------------------
PRINT 'Calling SP_ETO_to_DW_Entity_Attributes_Team'

-- Entity Types:
--1	Employer
--2	Referral Source
--6	Funding Source
--7	Education Institution
--16	Individuals
--17	Businesses
--18	Service Providers
--21	Billing Provider
--22	Administrative
--23	Classes
--50	Property
--1000	Vendor

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'CAlling Entity Attributes for TEAM'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

exec SP_ETO_to_DW_Entity_Attributes_Team



----------------------------------------------------------------------------------------
print '  Cont: SP_Teams_main - Processing Teams to CRM'

-- Teams are linked to CRM in the table via a name match:
--   Nurse_FamilyPartnership_MSCRM.dbo.new_nfpagencylocationbase
--   Nurse_FamilyPartnership_MSCRM.dbo.new_nfpagencylocationextensionbase
--
-- Due to differences in separate instances / language code setup, text comparison doesn't translate, 
-- so it errors out upon comparison.  
-- The CRM team names and locationid have been copied to a local table called 
-- dbo.Team_Locations.  ** This is maintained in the SP_Programs_Main process.


-- Log New Teams Matched to CRM:
insert into Teams_Log
       (Team_ID, LogDate, team_name, Action, Status, Comment, CRM_New_NFPAgencyLocationID, Site_ID)
 select teams.team_id, getdate(), teams.team_name
        ,'New Team',null
        ,'Found match in CRM'
        ,ctl.New_nfpagencylocationid
        ,teams.Site_ID
   from dbo.Teams
   join dbo.CRM_Team_Locations ctl on teams.Team_Name = ctl.New_Name
   join dbo.Agencies on teams.Site_ID = agencies.site_id
  where Teams.CRM_ID is null
    and ctl.new_NFPOrganizationID = agencies.CRM_AccountID
--    and not exists (select Site_ID from dbo.Sites_Excluded ex2
--                    where ex2.Site_Id = Teams.Site_Id)


-- Update Matched CRM Teams:
update dbo.teams
   set CRM_ID = ctl.New_nfpagencylocationid
  from dbo.teams
  join dbo.CRM_Team_Locations ctl on teams.Team_Name = ctl.New_Name
 where teams.CRM_ID is null
--   and not exists (select Site_ID from dbo.Sites_Excluded ex2
--                    where ex2.Site_Id = Teams.Site_Id);


-- Log Failed Matches:
insert into Teams_Log
       (Team_ID, LogDate, team_name, Action, Status, Comment, Site_ID)
 select teams.team_id, getdate(), teams.team_name
        ,'New Team','FAILED'
        ,'No CRM Match Found'
        ,teams.Site_ID
   from dbo.Teams
   left join dbo.CRM_Team_Locations ctl on teams.Team_Name = ctl.New_Name
  where Teams.CRM_ID is null
    and ctl.new_nfpagencylocationid is null
    and (upper(team_name) not like ('%TEST%') and
         upper(team_name) not like ('%FAKE%') and
         upper(team_name) not like ('%TRAINING%') and
         upper(team_name) not like ('%DEMO%') and
         team_name not like ('%PoC%'))
--    and not exists (select Site_ID from dbo.Sites_Excluded ex2
--                    where ex2.Site_Id = Teams.Site_Id)


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------


print '  End of Process: SP_teams_main'
GO
