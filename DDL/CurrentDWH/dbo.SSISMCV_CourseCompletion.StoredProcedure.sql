USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSISMCV_CourseCompletion]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Michael Osborn
-- Create date: 2/15/2015
-- Description:	Extract of MICHVEI data where the SiteID from the Survey is the
--				same as ExportEntities SiteID and ExportProfileID is the same as the passed ProfileID
-- =============================================
CREATE PROCEDURE [dbo].[SSISMCV_CourseCompletion]
	-- Add the parameters for the stored procedure here
	@ProfileID INT
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT *
	FROM [DataWarehouse].[dbo].[Course_Completion_Survey]
	where CL_EN_GEN_ID in (select CL_EN_GEN_ID from View_MIECHVP_Cleints 
						   where (siteid in(SELECT SiteID FROM [DataWarehouse].dbo.ExportEntities WHERE ExportProfileID = @ProfileID AND ISNULL(ExportDisabled,0) != 1))
						   or (SiteID = 78 and @ProfileID = 34))
	 and ProgramID not in (select ProgramID from dbo.Export_Program_Exclusions where ExportProfileID = @ProfileID) 
 
END

GO
