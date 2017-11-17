USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_rpt_AvgAgebyMonth]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_rpt_AvgAgebyMonth]
	-- Add the parameters for the stored procedure here
@Start DATE

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.


    -- Insert statements for procedure here
declare @end date set @end = GETDATE()

Declare @date table(d datetime)
Declare @d datetime

set @d=@Start

While @d<=@End
Begin
	Insert into @date values (@d)
	set @d=DATEADD(MONTH,1,@d)
End

SELECT D,dbo.udf_PA_AvgAge(d) [Average Age],dbo.udf_PA_MinAge(d) [Min Age],dbo.udf_PA_MaxAge(d) [Max Age]
FROM @date
option (recompile)
END

GO
