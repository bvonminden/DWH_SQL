USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_ETO_Transfers]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_ETO_Transfers
--
CREATE PROCEDURE [dbo].[SP_ETO_Transfers]
AS
--
-- This script controls updates to the Transfers table in the Data Warehouse.
-- Processing ETO via the view etosolaris.dbo.viewStandard_Referrals.
--
-- Table effected - dbo.Transfers
--
-- Insert: select and insert when ETO record is found to be missing in the DW.
-- Update: select and update when ETO recird exists in DW and has been changed in ETO.
-- Update: select and delete when ETO recird no longer exists ETO.
--

-- History: 20150317 New procedure.


DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_ETO_Transfers'

print 'Processing SP_ETO_Transfers'
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
--print ' '
print 'Insert new Records'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New DW Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- New Records:
insert into dbo.transfers
   (Datasource
   ,CLReferralID
   ,CLID
   ,ProgramID_From
   ,ReferredTo
   ,EntityID
   ,TargetSiteID
   ,TargetProgramID
   ,ReferralDate
   ,DateReferralClosed
   ,ReasonForDismissal
   ,ReasonForReferral
   ,CLReferralHxID
   ,ReferralStatus
   ,Notes
   ,TimeSpentonReferral
   ,AuditStaffID
   ,AuditDate)
select 'ETO' as Datasource
       ,CLReferralID
       ,CLID
       ,ProgramID_From
       ,ReferredTo
       ,EntityID
       ,TargetSiteID
       ,TargetProgramID
       ,ReferralDate
       ,DateReferralClosed
       ,ReasonForDismissal
       ,ReasonForReferral
       ,CLReferralHxID
       ,ReferralStatus
       ,Notes
       ,TimeSpentonReferral
       ,AuditStaffID
       ,AuditDate
  from etosolaris.dbo.viewStandard_Referrals vsr1
 where not exists (select nfptbl.TransferID
                     from dbo.Transfers nfptbl
                    where nfptbl.CLReferralID = vsr1.CLReferralID
                      and nfptbl.Datasource = 'ETO')
   --and not exists (select Site_ID from dbo.Sites_Excluded ex2
   --                 where ex2.Site_Id = Sites.SiteId);


----------------------------------------------------------------------------------------
--print ' '
print 'Update Existing records being changed'
-- Extraction for Team:

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Updating Existing DW Records'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

Update dbo.Transfers
   set CLID = vsr.CLID
      ,ProgramID_From = vsr.ProgramID_From
      ,ReferredTo = vsr.ReferredTo
      ,EntityID = vsr.EntityID
      ,TargetSiteID = vsr.TargetSiteID
      ,TargetProgramID = vsr.TargetProgramID
      ,ReferralDate = vsr.ReferralDate
      ,DateReferralClosed = vsr.DateReferralClosed
      ,ReasonForDismissal = vsr.ReasonForDismissal
      ,ReasonForReferral = vsr.ReasonForReferral
      ,CLReferralHxID = vsr.CLReferralHxID
      ,ReferralStatus = vsr.ReferralStatus
      ,Notes = vsr.Notes
      ,TimeSpentonReferral = vsr.TimeSpentonReferral
      ,AuditStaffID = vsr.AuditStaffID
      ,AuditDate = vsr.AuditDate
  from dbo.Transfers
  inner join etosolaris.dbo.viewStandard_Referrals vsr
        on Transfers.CLReferralID = vsr.CLReferralID
 where Transfers.Datasource = 'ETO'
   and isnull(vsr.AuditDate,convert(datetime,'19700101',112)) < Transfers.AuditDate


----------------------------------------------------------------------------------------
--Print ' '
print 'Delete ETO Deleted Entities'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Deleting ETO Record Deletions'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

delete dbo.Transfers
  from dbo.Transfers
 where isnull(DataSource,'ETO') = 'ETO'
   and not exists (select CLReferralID
                     from etosolaris.dbo.viewStandard_Referrals vsr
                    where ClReferralID = Transfers.ClReferralID)


--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------
--Print ' '
print 'End of Process: SP_ETO_Transfers'
GO
