USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_Send_All]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Antoniette Jenik
-- Create date: 7/11/2012
-- Description:	Executes usp_SendMailMergeEmail for each row in the table dbo.MailMerge
-- =============================================
CREATE PROCEDURE [dbo].[usp_Send_All]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

declare @Proc nvarchar(50)
declare @RowCnt int
declare @MaxRows int
declare @ExecSql nvarchar(255)

select @RowCnt = 1
select @Proc = 'usp_SendMailMergeEmail'

-- These next two rows are specific to source table or query
declare @Import table (rownum int IDENTITY (1, 1) Primary key NOT NULL , iMailMergeId varchar(9))
insert into @Import (iMailMergeId) select iMailMergeId from MailMerge

select @MaxRows=count(*) from @Import

while @RowCnt <= @MaxRows
begin
    select @ExecSql = 'exec ' + @Proc + ' ''' + iMailMergeId + '''' from @Import where rownum = @RowCnt 
    --print @ExecSql
    execute sp_executesql @ExecSql
    Select @RowCnt = @RowCnt + 1
end

END
GO
