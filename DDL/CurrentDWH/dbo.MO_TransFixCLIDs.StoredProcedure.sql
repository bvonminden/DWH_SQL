USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[MO_TransFixCLIDs]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Michael Osborn
-- Create date: 08/20/2015
-- Description:	This will return the clids for a given casenumber combined into a string
-- =============================================
CREATE PROCEDURE [dbo].[MO_TransFixCLIDs]
	-- Add the parameters for the stored procedure here
	@CaseNumber INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
--Declare @CaseNumber INT -- Test
Declare @Str Varchar(100)

--Set @CaseNumber = 100821 Test
SET @Str = (
Select Distinct 
    substring(
        (
            Select Distinct  cast(ST1.SrcCLID as varchar(50)) + ',' AS [text()]
            --From dbo.[MO_TransferFix] ST1
            From ##Transfer ST1
            Where ST1.CaseNumber = ST2.CaseNumber
            --ORDER BY ST1.SrcCLID
            For XML PATH ('')
        ), 2, 1000) [Clients]
--From dbo.[MO_TransferFix] ST2 Where CaseNumber = @CaseNumber)
From ##Transfer ST2 Where CaseNumber = @CaseNumber)

Select left(@Str, len(@Str) -1) [CLIDS]
END


GO
