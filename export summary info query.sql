
declare @profileid int=10;
DECLARE @ProfileName VARCHAR(200)--from varchar
DECLARE @RCount INT
DECLARE @TotalSites INT
DECLARE @SitesSearched INT
DECLARE @SitesFound INT
DECLARE @SitesExcluded INT
--DECLARE @ProfileID INT --Testing
DECLARE @ExportDT DATETIME

--SET @ProfileID = 23 --Testing

SET @ExportDT = GETDATE()
SET @ProfileName = (SELECT ProfileName FROM [survey_views].ExportProfile WHERE ExportProfileID = @ProfileID)
SET @TotalSites = (SELECT Count(*) FROM [survey_views].ExportEntities WHERE ExportProfileID = @ProfileID AND ISNULL(ExportDisabled,0) != 1)
SET @SitesSearched = (SELECT Count(*) FROM [survey_views].ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 0 AND ISNULL(ExportDisabled,0) != 1)
SET @SitesExcluded = (SELECT Count(*) FROM [survey_views].ExportEntities WHERE ExportProfileID = @ProfileID AND ExcludeTribal = 1 AND ISNULL(ExportDisabled,0) != 1)


print @ExportDT;
print @ProfileName;
print @TotalSites;
print @SitesSearched;
print @SitesExcluded