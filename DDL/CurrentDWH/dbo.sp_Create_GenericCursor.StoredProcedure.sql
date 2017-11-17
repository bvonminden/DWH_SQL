USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[sp_Create_GenericCursor]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Sheri Scott
-- Create date: 12/18/2015
-- Description:	Returns a cursor of the selection parameter.
-- =============================================
CREATE PROCEDURE [dbo].[sp_Create_GenericCursor]
    @vQuery    NVARCHAR(MAX)
   ,@Cursor    CURSOR VARYING OUTPUT
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE 
        @vSQL        AS NVARCHAR(MAX)
    
    SET @vSQL = 'SET @Cursor = CURSOR FORWARD_ONLY STATIC FOR ' + @vQuery + ' OPEN @Cursor;'
    
   
    EXEC sp_executesql
         @vSQL
         ,N'@Cursor cursor output'  
         ,@Cursor OUTPUT;
END 
GO
