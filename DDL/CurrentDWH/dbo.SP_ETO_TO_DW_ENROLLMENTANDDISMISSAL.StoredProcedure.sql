USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_ETO_TO_DW_ENROLLMENTANDDISMISSAL]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_ETO_TO_DW_ENROLLMENTANDDISMISSAL
--
CREATE PROCEDURE [dbo].[SP_ETO_TO_DW_ENROLLMENTANDDISMISSAL]
 (@p_datasource      nvarchar(10) = null
 ,@p_SurveyResponseID       int = null)
AS
--
-- This script controls integration of ETO ENROLLMENTANDDISMISSALs into the Data Warehouse. 
--
-- Table effected - dbo.ENROLLMENTANDDISMISSAL
-- Two phase loading - from two data tables: 
--    etosolaris.dbo.ClientsxPrograms    (currently enrolled)
--    etosolaris.dbo.ClientsxProgramsHx  (historical data)
--
-- Will import non existing records, will update existing records found to be changed via auditdate.
--
-- History:
--   20131110 - New Procedure.
--   20140227 - Logic change to pull SiteID from programs.AuditStaffID instead of the ClientsXPrograms.AuditStaffID.
--                (this will match the logic in the ProgramsAndSites table).
--            - Changed update logic to re-evaluate and update ProgramID, SiteID, and SourceTableID.

DECLARE @count        smallint
DECLARE @p_stop_flag  nvarchar(2)
DECLARE @Process      nvarchar(50)
DECLARE @runtime 	datetime
DECLARE @DW_TableName   nvarchar(50)

set @process = 'SP_ETO_TO_DW_ENROLLMENTANDDISMISSAL'
set @DW_Tablename = 'ENROLLMENTANDDISMISSAL'
Set @p_stop_flag = null
set @runtime = getdate()

DECLARE @SQL            varchar(MAX)

print 'Processing SP_ETO_TO_DW_ENROLLMENTANDDISMISSAL: Datasource = ETO'
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
print 'Processing SP_ETO_TO_DW_ENROLLMENTANDDISMISSAL ClientXPrograms'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing ClientXPRograms Insert'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- Basic insert for non-existing records - clientsxprograms:
insert into dbo.EnrollmentAndDismissal 
   (DataSource
   ,SourceTable
   ,SourceTableID
   ,CLID
   ,SiteID
   ,ProgramID
   ,ProgramStartDate
   ,EndDate
   ,TerminationReasonID
   ,ReasonForDismissalID
   ,ReasonForDismissal
   ,Disabled
   ,AuditStaffID
   ,AuditDate
   ,ProgramSpecific
   ,EmploymentSpecific
   ,EducationSpecific
   ,RejectionSpecific
   ,MatchSpecific
   ,SequenceOrder
   ,ReasonForDismissalID_Source
   ,SourceReasonForDismissalID
   ,CaseNumber)
select 'ETO' as DataSource
      ,'clientsxprograms' as SourceTable
      ,xprog.ClientxProgramID as SourceTableID
      ,xprog.CLID
      ,Sites.SiteID
      ,xprog.ProgramID
      ,xprog.ProgramStartDate
      ,xprog.EndDate
      ,xprog.TerminationReasonId
      ,rfd.ReasonForDismissalID
      ,rfd.ReasonForDismissal
      ,rfd.Disabled
      ,xprog.AuditStaffID
      ,xprog.AuditDate
      ,rfd.ProgramSpecific
      ,rfd.EmploymentSpecific
      ,rfd.EducationSpecific
      ,rfd.RejectionSpecific
      ,rfd.SequenceOrder
      ,rfd.MatchSpecific
      ,rfd.ReasonForDismissalID_Source
      ,rfd.SourceReasonForDismissalID
      ,Clients.CaseNumber
   FROM ETOSRVR.etosolaris.dbo.ClientsxPrograms xprog
   LEFT join ETOSRVR.etosolaris.dbo.Programs
         on xprog.ProgramID = Programs.ProgramID
   LEFT JOIN ETOSRVR.etosolaris.dbo.Staff Staff
        on Programs.AuditStaffID = Staff.StaffID 
   LEFT JOIN ETOSRVR.etosolaris.dbo.sites Sites
        on Staff.SiteID = Sites.SiteID
   LEFT JOIN ETOSRVR.etosolaris.dbo.reasonsForDismissal rfd
        ON rfd.ReasonForDismissalID = xprog.TerminationReasonId
   LEFT JOIN ETOSRVR.etosolaris.dbo.Clients Clients
        on xprog.CLID = Clients.CLID
  WHERE xprog.EndDate is null
    and not exists (select Site_ID from dbo.Sites_Excluded ex2
                   where ex2.Site_Id = sites.SiteId)
   and not exists (select xtbl.RecID from dbo.ENROLLMENTANDDISMISSAL xtbl
                    where xtbl.DataSource = 'ETO'
                      and xtbl.SourceTable = 'clientsxprograms'
                      and xtbl.SourceTableID = xprog.ClientxProgramID)


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing ClientXPRograms Update'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- Update for modified records - clientsxprograms:
update dbo.ENROLLMENTANDDISMISSAL
   set CLID = xprog.CLID
      ,SiteID = sites.SiteID
      ,ProgramID = xprog.ProgramID
      ,ProgramStartDate = xprog.ProgramStartDate
      ,EndDate = xprog.EndDate
      ,TerminationReasonID = xprog.TerminationReasonId
      ,ReasonForDismissalID = rfd.ReasonForDismissalID
      ,ReasonForDismissal = rfd.ReasonForDismissal
      ,Disabled = rfd.Disabled
      ,AuditStaffID = xprog.AuditStaffID
      ,AuditDate = xprog.AuditDate
      ,ProgramSpecific = rfd.ProgramSpecific
      ,EmploymentSpecific = rfd.EmploymentSpecific
      ,EducationSpecific = rfd.EducationSpecific
      ,Rejectionspecific = rfd.RejectionSpecific
      ,SequenceOrder = rfd.SequenceOrder
      ,MatchSpecific = rfd.MatchSpecific
      ,ReasonForDismissalID_Source = rfd.ReasonForDismissalID_Source
      ,SourceReasonForDismissalID = rfd.SourceReasonForDismissalID
      ,CaseNumber = Clients.CaseNumber
   FROM dbo.ENROLLMENTANDDISMISSAL ead
   inner join ETOSRVR.etosolaris.dbo.ClientsxPrograms xprog
         on ead.SourceTableID = xprog.ClientxProgramID
   LEFT join ETOSRVR.etosolaris.dbo.Programs
         on xprog.ProgramID = Programs.ProgramID
   LEFT JOIN ETOSRVR.etosolaris.dbo.Staff Staff
        on Programs.AuditStaffID = Staff.StaffID 
   LEFT JOIN ETOSRVR.etosolaris.dbo.sites Sites
        on Staff.SiteID = Sites.SiteID
   LEFT JOIN ETOSRVR.etosolaris.dbo.reasonsForDismissal rfd
        ON rfd.ReasonForDismissalID = xprog.TerminationReasonId
   LEFT JOIN ETOSRVR.etosolaris.dbo.Clients Clients
        on xprog.CLID = Clients.CLID
  WHERE ead.DataSource = 'ETO'
    and ead.SourceTable = 'clientsxprograms'
    and xprog.EndDate is null
    and isnull(ead.AuditDate,convert(datetime,'19700101',112)) < xprog.AuditDate


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing ClientXPRograms Delete'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- Delete end-dated records - ClientXPrograms:
delete from dbo.EnrollmentAndDismissal
 where RecID in (
select RecID
   FROM dbo.ENROLLMENTANDDISMISSAL ead
   left join ETOSRVR.etosolaris.dbo.ClientsxPrograms xprog
         on ead.SourceTableID = xprog.ClientxProgramID
  WHERE ead.DataSource = 'ETO'
    and ead.SourceTable = 'clientsxprograms'
    and (xprog.EndDate is not null
         or xprog.ClientXProgramID is null))


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
print 'Processing SP_ETO_TO_DW_ENROLLMENTANDDISMISSAL ClientXProgramHx'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing ClientXPRogramsHX Insert'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- Basic insert for non-existing records - ClientXProgramsHx:
insert into dbo.EnrollmentAndDismissal 
   (DataSource
   ,SourceTable
   ,SourceTableID
   ,CLID
   ,SiteID
   ,ProgramID
   ,ProgramStartDate
   ,EndDate
   ,TerminationReasonID
   ,ReasonForDismissalID
   ,ReasonForDismissal
   ,Disabled
   ,AuditStaffID
   ,AuditDate
   ,ProgramSpecific
   ,EmploymentSpecific
   ,EducationSpecific
   ,RejectionSpecific
   ,MatchSpecific
   ,SequenceOrder
   ,ReasonForDismissalID_Source
   ,SourceReasonForDismissalID
   ,CaseNumber)
select 'ETO' as DataSource
      ,'clientsxprogramshx' as SourceTable
      ,xprog.ClientxProgramhxID as SourceTableID
      ,xprog.CLID
      ,xprog.SiteID
      ,xprog.ProgramID
      ,xprog.ProgramStartDate
      ,xprog.EndDate
      ,xprog.TerminationReasonId
      ,rfd.ReasonForDismissalID
      ,rfd.ReasonForDismissal
      ,rfd.Disabled
      ,xprog.AuditStaffID
      ,xprog.AuditDate
      ,rfd.ProgramSpecific
      ,rfd.EmploymentSpecific
      ,rfd.EducationSpecific
      ,rfd.RejectionSpecific
      ,rfd.SequenceOrder
      ,rfd.MatchSpecific
      ,rfd.ReasonForDismissalID_Source
      ,rfd.SourceReasonForDismissalID
      ,Clients.CaseNumber
   FROM ETOSRVR.etosolaris.dbo.ClientsxProgramsHx xprog
   LEFT JOIN ETOSRVR.etosolaris.dbo.reasonsForDismissal rfd
        ON rfd.ReasonForDismissalID = xprog.TerminationReasonId
   LEFT JOIN ETOSRVR.etosolaris.dbo.Clients Clients
        on xprog.CLID = Clients.CLID
  WHERE not exists (select Site_ID from dbo.Sites_Excluded ex2
                   where ex2.Site_Id = xprog.SiteId)
   and not exists (select xtbl.RecID from dbo.ENROLLMENTANDDISMISSAL xtbl
                    where xtbl.DataSource = 'ETO'
                      and xtbl.SourceTable = 'clientsxprogramshx'
                      and xtbl.SourceTableID = xprog.ClientxProgramHxID)


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing ClientXPRogramsHX Update'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- Update for modified records - ClientXProgramsHx:
update dbo.ENROLLMENTANDDISMISSAL
   set CLID = xprog.CLID
      ,SiteID = xprog.SiteID
      ,ProgramID = xprog.ProgramID
      ,ProgramStartDate = xprog.ProgramStartDate
      ,EndDate = xprog.EndDate
      ,TerminationReasonID = xprog.TerminationReasonId
      ,ReasonForDismissalID = rfd.ReasonForDismissalID
      ,ReasonForDismissal = rfd.ReasonForDismissal
      ,Disabled = rfd.Disabled
      ,AuditStaffID = xprog.AuditStaffID
      ,AuditDate = xprog.AuditDate
      ,ProgramSpecific = rfd.ProgramSpecific
      ,EmploymentSpecific = rfd.EmploymentSpecific
      ,EducationSpecific = rfd.EducationSpecific
      ,Rejectionspecific = rfd.RejectionSpecific
      ,SequenceOrder = rfd.SequenceOrder
      ,MatchSpecific = rfd.MatchSpecific
      ,ReasonForDismissalID_Source = rfd.ReasonForDismissalID_Source
      ,SourceReasonForDismissalID = rfd.SourceReasonForDismissalID
      ,CaseNumber = Clients.CaseNumber
   FROM dbo.ENROLLMENTANDDISMISSAL ead
   inner join ETOSRVR.etosolaris.dbo.ClientsxProgramsHx xprog
         on ead.SourceTableID = xprog.ClientxProgramHxID
   LEFT JOIN ETOSRVR.etosolaris.dbo.reasonsForDismissal rfd
        ON rfd.ReasonForDismissalID = xprog.TerminationReasonId
   LEFT JOIN ETOSRVR.etosolaris.dbo.Clients Clients
        on xprog.CLID = Clients.CLID
  WHERE ead.DataSource = 'ETO'
    and ead.SourceTable = 'clientsxprogramshx'
    and isnull(ead.AuditDate,convert(datetime,'19700101',112)) < xprog.AuditDate


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Processing ClientXPRogramsHX Delete'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- Delete removed records - ClientXPrograms:
delete from dbo.EnrollmentAndDismissal
 where RecID in (
select RecID
   FROM dbo.ENROLLMENTANDDISMISSAL ead
  WHERE ead.DataSource = 'ETO'
    and ead.SourceTable = 'clientsxprogramshx'
    and not exists (select xprog.ClientXProgramHxID 
                      from ETOSRVR.etosolaris.dbo.ClientsxProgramsHx xprog
                     where xprog.ClientxProgramHxID = ead.SourceTableID))


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

print 'End of Process: SP_ETO_TO_DW_ENROLLMENTANDDISMISSAL'
GO
