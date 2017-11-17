USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[File_StaffxClientHx]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Michael Osborn
-- Create date: 08/20/2014
-- Description:	Return Staff history Data
-- =============================================
CREATE PROCEDURE [dbo].[File_StaffxClientHx] 
	-- Add the parameters for the stored procedure here
	@SiteID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--DECLARE @ProfileID INT
--SET @ProfileID = 27

SELECT SXCH.[StaffxClientID]
      ,SXCH.[StaffID]
      ,SXCH.[CLID]
      ,SXCH.[ProgramID]
      ,SXCH.[StartDate]
      ,SXCH.[EndDate]
      ,SXCH.[AuditStaffID]
      ,SXCH.[AuditDate]
      ,SXCH.[DataSource]
      ,SXCH.[Entity_ID]
  FROM [DataWarehouse].[dbo].[StaffxClientHx] SXCH
  INNER JOIN [DataWarehouse].dbo.ProgramsAndSites PAS on PAS.SiteID =@SiteID  and PAS.ProgramID = SXCH.ProgramID

END


GO
