USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SP_CRM_to_DW_Course_History]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop proc dbo.SP_CRM_to_DW_Course_History
--
CREATE PROCEDURE [dbo].[SP_CRM_to_DW_Course_History]
 (@p_date_prior   smalldatetime = null)
AS
--
-- This process reads the CRM completed courses from a single CRM record, and creates multiple
-- records in the DW for initial population into ETO.  
-- Completed courses are populated into the ETO completed course survey via an API. 

-- Database Links:
-- CRM: CRMsrvr.Nurse_FamilyPartnership_MSCRM. 

DECLARE @count		smallint
DECLARE @Process	nvarchar(50)
set @process = 'SP_CRM_TO_DW_COURSE_HISTORY'

DECLARE @date_prior		smalldatetime
set  @date_prior = convert(smalldatetime,isnull(@p_date_prior,convert(varchar,getdate(),112)),112)

print 'Begin Procedure: SP_CRM_to_DW_Course_History Prior to Date: ' +convert(varchar,@date_prior,120)

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
-- Extract CRM completed courses
----------------------------------------------------------------------------------------
DECLARE @SQL     nvarchar(3000)
DECLARE @loopctr smallint
set @loopctr = 0

while @loopctr < 16
BEGIN
   set @loopctr = @loopctr + 1

   print 'Updating CRM_Completed_Courses (Init Temp Table) for Course# ' +convert(varchar,@loopctr)

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding New CRM Courses'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

   set @SQL = 'insert into dbo.crm_completed_courses
        (ContactId
        ,Course_Nbr
        ,Course_Name
        ,Completion_Date
        ,Reason_For_Education)
       select ContactID, ' +convert(varchar,@loopctr) +', New_Course' +convert(varchar,@loopctr) +'
              , New_Course' +convert(varchar,@loopctr) +'CompletionDate
              ,EducationCodePLTable.Value
         from CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.ContactExtensionBase ContactExtensionBase
         left join CRMsrvr.Nurse_FamilyPartnership_MSCRM.dbo.StringMap EducationCodePLTable
                on ContactExtensionBase.new_programstaffrole = AttributeValue
               and EducationCodePLTable.ObjectTypeCode = 2
               and EducationCodePLTable.AttributeName = ''new_programstaffrole''
        where New_course' +convert(varchar,@loopctr) +' is not null
          and not exists (select Course_Nbr
                            from dbo.crm_completed_courses CCC
                           where ccc.ContactID = ContactExtensionBase.ContactID
                             and CCC.Course_nbr = ' +convert(varchar,@loopctr) +')'

   --print @SQL
   Exec (@SQL)

END -- end while

----------------------------------------------------------------------------------------
-- Populate the DW Staging table with new Completed Courses
----------------------------------------------------------------------------------------
print 'Updating DW_Completed_Courses (Staging Table)'

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Phase = 'Adding to Staging Table'
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

-- Insert into the DW_Completed_Courses Table:
insert into dbo.DW_Completed_Courses
       (Entity_id, ContactID, CRM_Course_Nbr, Course_Name, Completion_date, 
        Reason_For_Education)

       Select IA_Staff.Entity_ID
             ,CCC.ContactID
             ,CCC.Course_Nbr
             ,CCC.Course_Name
             ,CCC.Completion_Date
             ,ccc.Reason_For_Education
         from dbo.IA_Staff
         inner join dbo.crm_completed_courses CCC
                 on IA_Staff.CRM_ContactID = CCC.ContactID
        where IA_Staff.CRM_ContactID is not null
          and CCC.Completion_Date < @date_prior
          and (select count(*)
                 from dbo.DW_Completed_Courses DWCC
                where DWCC.ContactID = CCC.ContactID
                 and DWCC.CRM_Course_Nbr = CCC.Course_Nbr) = 0;

--------- update Process Log ----------------
set nocount on
update dbo.process_log 
   set Action = 'End'
      ,EndDate = getdate()
      ,Phase = null
      ,LogDate = getdate()
 where Process = @process
---------------------------------------------

PRINT 'End of Procedure: SP_CRM_to_DW_Course_History'
GO
