USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[File_StaffxClient]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Michael Osborn
-- Create date: 08/20/2014
-- Description:	Return Staff Data
-- =============================================
CREATE PROCEDURE [dbo].[File_StaffxClient] 
	-- Add the parameters for the stored procedure here
	@SiteID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--DECLARE @ProfileID INT
--SET @ProfileID = 27

SELECT SXC.[StaffxClientID]
      ,SXC.[StaffID]
      ,SXC.[CLID]
      ,SXC.[ProgramID]
      ,SXC.[AuditStaffID]
      ,SXC.[AuditDate]
  FROM [DataWarehouse].[dbo].[StaffxClient] SXC
INNER JOIN [DataWarehouse].dbo.ProgramsAndSites PAS on PAS.SiteID =@SiteID and PAS.ProgramID = SXC.ProgramID

END


GO
