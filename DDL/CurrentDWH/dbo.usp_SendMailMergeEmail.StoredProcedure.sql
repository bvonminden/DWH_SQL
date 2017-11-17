USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_SendMailMergeEmail]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[usp_SendMailMergeEmail]
  (
   @iMailMergeId int = null,
   @vchFirstName varchar (100) = '',
   @vchLastName varchar (100) = '',
   @vchEmailAddress varchar (100) = '',
   @vchEmailSubject varchar (50) = '',
   @vchEmailBody varchar (1024) = '',
   @vchAttachmentPath1 varchar (255) = '',
   @vchAttachmentPath2 varchar (255) = '',
   @verbose bit = 0,
   @debugMode bit = 0
  )
as
/*
** Object Type: Stored procedure
**
** Object Name: usp_SendMailMergeEmail
**
** Description: Emails a subject and body, possibly with attachments
**
** Return Type: int
**
** Return Code: = 0 (debug mode)
**              < 0 (failure)
**              > 0 (success)
**
** Called From: T-SQL stored procedures, web
**
** Input:
**   Parameter           Description
**   ---------           ------------------------------------------------------
**   @iMailMergeId       A primary key in the MailMerge table
**   @vchFirstName       The first (given) name of the email recipient
**   @vchLastName        The last (family) name of the email recipient
**   @vchEmailAddress    The email address of the recipient
**   @vchEmailSubject    The subject line (text) of the email message
**   @vchEmailBody       The body (text or HTML) of the email message
**   @vchAttachmentPath1 The filesystem path to attachment #1
**   @vchAttachmentPath2 The filesystem path to attachment #2
**   @verbose            Toggles display of dynamic SQL (default: off)
**   @debugMode          Toggles execution of dynamic SQL (default: off)
**
** Note: At least one of these parameters must be populated
** Output: The number of input rows split
**
** Revision History:
** ----------------------------------------------------------------------------
**  Date        Name        Description
** ----------------------------------------------------------------------------
**  06/20/12    EvanB       Initial Creation (based on usp_SendOrderEmail)
**
*/
  -- Declare local scalar variables
  declare @msg varchar (max), @attachmentz varchar (max)
  declare @newLine char (2)

  -- Suppress rowcounts if not running in verbose mode
  if (@verbose = 0) set nocount on

  -- Initialize the email variables
  select @attachmentz = ';', @newLine = Char (13) + Char (10)
  select @msg = @newLine
  
  -- Sanity check: do we have enough info to send an email?
  if ((@iMailMergeId is null) and (Len (@vchEmailAddress) = 0))
    begin
      select @msg = 'Error: need either an iMailMergeId or a vchEmailAddress' + @msg
      if (@verbose = 1) select @msg as msg
      return -1 -- Nope
    end

  -- Yup, so populate the message body with MailMerge data
  if (@iMailMergeId is not null)
    begin
      select @vchFirstName = vchFirstName, @vchLastName = vchLastName, 
             @vchEmailAddress = vchEmailAddress, @vchEmailSubject = vchEmailSubject,
             @vchEmailBody = vchEmailBody, @vchAttachmentPath1 = vchAttachmentPath1,
             @vchAttachmentPath2 = vchAttachmentPath2
        from MailMerge
        where iMailMergeId = @iMailMergeId
          and chStatusCode = 'A'
      if ((@vchFirstName is null) or (Len (@vchFirstName) = 0))
        begin
          select @msg = 'Error: cannot find iMailMergeId #' + Convert (varchar, @iMailMergeId) + @msg
          if (@verbose = 1) select @msg as msg
          return -1
        end
    end
  
  -- Merge the body with the individual data
  select @msg = @vchEmailBody + @msg
  select @msg = Replace (@msg, '~{vchFirstName}', @vchFirstName)
  select @msg = Replace (@msg, '~{vchLastName}', @vchLastName)

  -- Prepare the attachments (if any)
  if (Len (@vchAttachmentPath1) > 0)
    select @attachmentz = @attachmentz + @vchAttachmentPath1 + ';'
  if (Len (@vchAttachmentPath2) > 0)
    select @attachmentz = @attachmentz + @vchAttachmentPath2 + ';'
  -- Remove extra semicolons
  if (@attachmentz = ';') select @attachmentz = ''
  else select @attachmentz = SUBSTRING (@attachmentz, 2, LEN (@attachmentz) - 2)

  -- Display the message?
  if (@verbose = 1)
    select @msg as msg, @vchEmailSubject as subjectLine, @attachmentz as Attachments 
  
  -- Send the message?
  if (@debugMode = 1) select @vchEmailAddress = 'EvanBynum@yahoo.com;EvanBynum@gmail.com'
  if (@debugMode = 0)
    exec msdb..sp_send_dbmail
	    @profile_name = 'DWAdmin', @subject = @vchEmailSubject, @body = @msg,
	    @recipients = @vchEmailAddress, @file_attachments = @attachmentz

GO
