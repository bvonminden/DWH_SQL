USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[SSIS_test]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SSIS_test] AS 
BEGIN   
	SELECT * FROM [DataWarehouse].[dbo].[Agencies];   
END

GO
