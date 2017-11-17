USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[MO_PopulateMOVisits]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		Michael Osborn
-- Create date: 09/24/2013
-- Description:	This will return all first program visits from the HomeVisitEncounter with given Client IDs
-- =============================================
CREATE PROCEDURE [dbo].[MO_PopulateMOVisits]
	-- Add the parameters for the stored procedure here
	@CLIDS varchar(max)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
Declare @SqlQuery Varchar(MAX)

--Declare @CLIDS varchar(max) --Testing
--SET @CLIDS = '505060,455492'--Testing

--Temp table to hold the home visit encounter data
Declare @HVE as Table
(
	RID int,
	SurveyDate datetime,
	CLID int,
	SiteId int,
	ProgramID int,
	ROrder Int,
	FirstStartDate datetime
)

--Build the query which will return all rows from HVE with given client ids. 
--Returned data set will have a row number assigned to it and ranked by client id and programid.
Set @SqlQuery =
 'select Row_number() over(Order By  SurveyDate) As RID,
 SurveyDate, CL_EN_GEN_ID, SiteID, ProgramID 
 ,Rank() Over (Partition by CL_EN_GEN_ID, ProgramID Order By  SurveyDate ) As CaseRank
 ,Null
 from [Home_Visit_Encounter_Survey]
 Where cl_en_gen_id in('+ @CLIDS +')
--Where cl_en_gen_id in(505060,455492)
--Where cl_en_gen_id in(456943)
 order by SurveyDate'

--Fill the temp hve table variable
Insert into @HVE
EXEC (@SqlQuery)--Run the query built

Declare @Index AS INT --Index for traversing the records in @HVE with a while loop
Declare @Max as int --max number of records from the temp var table @HVE
Declare @SurveyDate datetime --The current surveydate where @index = 1
Declare @CLID int --The current client id where @index = 1
Declare @ProgramID int--The current program where @index = 1
Declare @TProgramID int--the current program id at given @index
Declare @SiteID int --The current siteid where @index = 1

Set @Index = 1 --Init the index 
Set @Max = (Select max(Rid) from @HVE)--get the max index value to stop at

While @Index <= @Max --start the loop
	Begin
		SET @TProgramID = (Select ProgramID from @HVE where RID = @Index)--get the program id at current index
		
		IF @Index = 1 --when the index = 1 updat upe the temp @HVE table var. this is the very first record in the temp @HVE
		BEGIN 
				UPDATE @HVE 
				SET FirstStartDate = (select surveydate from @HVE where RID = @Index)
				WHERE RID = @Index 
				SET @CLID = (Select CLID from @HVE where RID = @Index)
				SET @ProgramID = (Select ProgramID from @HVE where RID = @Index)
				SET @SiteID = (Select SiteID from @HVE where RID = @Index)
				SET @SurveyDate = (Select SurveyDate  from @HVE where RID = @Index)
		END
		
		IF @Index > 1 AND @TProgramID <> @programID --When the record is not the the first record (@index >1) and the ProgramID from record 1 is different then updated the temp @HVE
		BEGIN
			   SET @ProgramID = @TProgramID
	           UPDATE @HVE 
			   SET FirstStartDate = (select surveydate from @HVE where RID = @Index)
			   WHERE RID = @Index 
			
		END
	set @Index = @Index + 1	--increment the index to the next record
	END

Insert into MO_Visits
Select SurveyDate,CLID, SiteID, ProgramID,FirstStartDate 
from @HVE WHERE FirstStartDate IS NOT NULL ORDER BY RID --Return only results where a data was added Results

--Select RID, SurveyDate, CLID, SiteID, ProgramID, ROrder, FirstStartDate 
--,Rank() Over (Partition by ROrder Order By FirstStartDate asc) AS [Rank]
--from @HVE WHERE FirstStartDate IS NOT NULL ORDER BY RID --Return only results where a data was added Results

--Select * from @HVE --display all the records. 
END



GO
