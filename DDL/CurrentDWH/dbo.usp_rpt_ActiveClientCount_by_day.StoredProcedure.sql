USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_rpt_ActiveClientCount_by_day]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_rpt_ActiveClientCount_by_day]
	-- Add the parameters for the stored procedure here
@StartDate DATE
,@EndDate DATE
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.


    -- Insert statements for procedure here
Declare @date table(d datetime)
Declare @d datetime

set @d=@StartDate

While @d<=@EndDate
Begin
	Insert into @date values (@d)
	set @d=@d+1
End

SELECT D, dbo.udf_ActiveClients(d) [ActiveClientCount]
FROM @date
option (recompile)
END

GO
