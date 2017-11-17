USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[spWriteStringToFile]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE [dbo].[spWriteStringToFile]
 (
@String Varchar(max), --8000 in SQL Server 2000
@Path VARCHAR(255),
@Filename VARCHAR(100),
@bypass_appended_hdr varchar(2) = null

--
)
AS
DECLARE @objFileSystem    int
DECLARE @objTextStream    int
DECLARE @objErrorObject   int
DECLARE @strErrorMessage  Varchar(1000)
DECLARE @Command          varchar(1000)
DECLARE @hr               int
DECLARE @fileAndPath      varchar(200)

set nocount on

select @strErrorMessage='opening the File System Object'
EXECUTE @hr = sp_OACreate  'Scripting.FileSystemObject' , @objFileSystem OUT

Select @FileAndPath=@path+'\'+@filename
if @HR=0 Select @objErrorObject=@objFileSystem , @strErrorMessage='Creating file "'+@FileAndPath+'"'

-- new with append:
declare @append smallint
EXEC sp_OAMethod @objFileSystem, 'FileExists', @Append out, @FileAndPath

IF @Append = 1
BEGIN
IF @bypass_appended_hdr is not null
   set @string = ''
--open the text stream for append
IF @HR=0 EXECUTE @hr = sp_OAMethod @objFileSystem,'OpenTextFile', @objTextStream OUTPUT, @FileAndPath, 8

END
ELSE
BEGIN

--Create the text file for write
IF @HR=0 EXECUTE @hr = sp_OAMethod @objFileSystem,'CreateTextFile',@objTextStream OUTPUT,@FileAndPath,-1

END

/* orig:
if @HR=0 execute @hr = sp_OAMethod   @objFileSystem   , 'CreateTextFile'
	, @objTextStream OUT, @FileAndPath,2,True
*/

if @HR=0 Select @objErrorObject=@objTextStream, 
	@strErrorMessage='writing to the file "'+@FileAndPath+'"'
if @HR=0 execute @hr = sp_OAMethod  @objTextStream, 'Write', Null, @String

if @HR=0 Select @objErrorObject=@objTextStream, @strErrorMessage='closing the file "'+@FileAndPath+'"'
if @HR=0 execute @hr = sp_OAMethod  @objTextStream, 'Close'

if @hr<>0
	begin
	Declare 
		@Source varchar(255),
		@Description Varchar(255),
		@Helpfile Varchar(255),
		@HelpID int
	
	EXECUTE sp_OAGetErrorInfo  @objErrorObject, 
		@source output,@Description output,@Helpfile output,@HelpID output
	Select @strErrorMessage='Error whilst '
			+coalesce(@strErrorMessage,'doing something')
			+', '+coalesce(@Description,'')
	raiserror (@strErrorMessage,16,1)
	end
EXECUTE  sp_OADestroy @objTextStream
EXECUTE sp_OADestroy @objTextStream

GO
