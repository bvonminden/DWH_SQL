USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_ETO_Transfers_History]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_ETO_Transfers_History
--
CREATE PROCEDURE [dbo].[SP_ETO_Transfers_History]
AS
--
-- This script builds the historical transfers coming from EnrollmentsAndDismissals.
-- 
-- Transfer types:
--    Site-to-site:        where Case# moves between sites
--    Program-to-Programm: where Case# moves between the 'HOME%' programs
--
-- Table effected - dbo.Transfers
--
-- History: 
--    20150403 New procedure.
--    20150423 - Amendments from review process.
--    20150505 - Amendments from review process, using End_Date instead of AuditDate, process only 'Home Visits'.
--    20150713 - Amend to include the word 'VISIT' in program name qualifier, to exclude referrals and staff programs
--               having the word 'Home' in it's name, such as 'Redmond Home'.


DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_ETO_Transfers_History'

DECLARE @RecID             int
DECLARE @CaseNumber        varchar(50)
DECLARE @CLID              int
DECLARE @AuditDate         datetime
DECLARE @AuditStaffID      int
DECLARE @SiteID            int
DECLARE @ProgramID         int
DECLARE @Disabled          bit
DECLARE @ProgramStartDate  datetime
DECLARE @EndDate           datetime
DECLARE @ReasonForDismissal varchar(50)
--DECLARE @Is_Home_Program   varchar(2)


DECLARE @Last_RecID             int
DECLARE @Last_CaseNumber        varchar(50)
DECLARE @Last_CLID              int
--DECLARE @Last_AuditDate         datetime
DECLARE @Last_SiteID            int
DECLARE @Last_ProgramID         int
DECLARE @Last_ProgramID_Home    int
DECLARE @Last_Disabled          bit
DECLARE @Last_ProgramStartDate  datetime
DECLARE @Last_EndDate           datetime

DECLARE @ReasonForReferral varchar(50)
DECLARE @Cursor_rec_Ctr    int


print 'Processing SP_ETO_Transfers_History'
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
-- Build Cursor of multiple EnrollmentAndDismissals based upon CaseNumber
----------------------------------------------------------------------------------------
DECLARE EAD_Cursor Cursor for
select ead.RecID
      ,ead.CaseNumber
      ,ead.CLID
      ,ead.AuditDate
      ,ead.AuditStaffID
      ,ead.SiteID
      ,ead.ProgramID
      ,ead.Disabled
      ,ead.ProgramStartDate
      ,ead.EndDate
      ,ead.ReasonForDismissal 
      --,case when upper(isnull(Programs.Program_Name,'abc')) like '%HOME%' then 'Y' else 'N' end as Is_Home_Program
  from dbo.EnrollmentAndDismissal ead
  left join dbo.Programs on ead.ProgramID = Programs.Program_ID
 where (select COUNT(*) 
          from dbo.EnrollmentAndDismissal ead2
          inner join dbo.Programs Programs2 on ead2.ProgramID = Programs2.Program_ID
         where ead2.CaseNumber = ead.CaseNumber
           and upper(isnull(Programs2.Program_Name,'abc')) like '%HOME%'
           and upper(isnull(Programs2.Program_Name,'abc')) like '%VISIT%'
           ) > 1
   and upper(isnull(Programs.Program_Name,'abc')) like '%HOME%'
   and upper(isnull(Programs.Program_Name,'abc')) like '%VISIT%'  -- excudes 'Redmond Home' referrals
   --and Programs.ProgramName
-- testing
--and ead.caseNumber = 10000011
 order by ead.CaseNumber, ead.EndDate

Set @Cursor_rec_Ctr = 0
set @Last_ProgramID_Home = null

OPEN EAD_Cursor

FETCH next from EAD_Cursor
      into @RecID
          ,@CaseNumber
          ,@CLID
          ,@AuditDate
          ,@AuditStaffID
          ,@SiteID
          ,@ProgramID
          ,@Disabled
          ,@ProgramStartDate
          ,@EndDate
          ,@ReasonForDismissal
          --,@Is_Home_Program

WHILE @@FETCH_STATUS = 0
BEGIN
   Set @Cursor_rec_Ctr = @Cursor_rec_Ctr + 1
   
/*
print 'rec_ctr=' +rtrim(convert(char,@Cursor_rec_Ctr)) 
    +', last/curr CaseNumber: ' +rtrim(convert(char,isnull(@Last_CaseNumber,0)))
    +'/' +rtrim(convert(char,isnull(@CaseNumber,0)))
    +', CLID: ' +rtrim(convert(char,isnull(@Last_CLID,0)))
    +'/'+rtrim(convert(char,isnull(@CLID,0)))
    +', SiteID: ' +rtrim(convert(char,isnull(@Last_SiteID,0)))
    +'/'+rtrim(convert(char,isnull(@SiteID,0)))
    +', ProgramID: ' +rtrim(convert(char,isnull(@Last_ProgramID,0)))
    +'/'+rtrim(convert(char,isnull(@ProgramID,0)))
*/

   IF @Cursor_rec_Ctr != 1 
   BEGIN

      IF @CaseNumber = @Last_CaseNumber
      BEGIN

         -- check for site or program change
         IF @SiteID != @Last_SiteID or
            @ProgramID != @Last_ProgramID_Home
         BEGIN

            IF @SiteID != @Last_SiteID 
               set @ReasonForReferral = 'Client Transfer (site-to-site)'
            ELSE
               set @ReasonForReferral = 'Client Transfer (team-to-team)'

            insert into dbo.transfer_History
               (Datasource
               ,CLReferralID
               ,CLID
               ,SiteID_From
               ,ProgramID_From
               ,TargetSiteID
               ,TargetProgramID
               ,ReferralDate
               ,ProgramStartDate
               ,ProgramEndDate
               ,AuditDate
               ,AuditStaffID
               ,ReasonForReferral
               ,ReasonForDismissal
               --,DateReferralClosed
               --,ReferredTo
               --,EntityID
               --,CLReferralHxID
               --,ReferralStatus
               --,Notes
               --,TimeSpentonReferral
               )
            VALUES ('EAD_HIST'
                   ,@RecID
                   ,@CLID
                   ,@Last_SiteID
                   ,@Last_ProgramID
                   ,@SiteID
                   ,@ProgramID
                   ,@ProgramStartDate
                   ,@EndDate
                   ,@AuditDate
                   ,@AuditDate
                   ,@AuditStaffID
                   ,@ReasonForReferral
                   ,@ReasonForDismissal)


         END -- transfer found

      END -- Qualified same casenumber

   END  -- bypass for first record in cursor

   set @Last_RecID = @RecID
   set @Last_CaseNumber = @CaseNumber
   set @Last_CLID = @CLID
   set @Last_SiteID = @SiteID
   set @Last_ProgramID = @ProgramID
   set @Last_Disabled = @Disabled 
   set @Last_ProgramStartDate = @ProgramStartDate
   set @Last_EndDate = @EndDate
   set @Last_ProgramID_Home = @ProgramID


   FETCH next from EAD_Cursor
         into @RecID
             ,@CaseNumber
             ,@CLID
             ,@AuditDate
             ,@AuditStaffID
             ,@SiteID
             ,@ProgramID
             ,@Disabled
             ,@ProgramStartDate
             ,@EndDate
             ,@ReasonForDismissal
             --,@Is_Home_Program

END -- End of EAD_Cursor loop

CLOSE EAD_Cursor
DEALLOCATE EAD_Cursor



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
print 'End of Process: SP_ETO_Transfers_History'
GO
