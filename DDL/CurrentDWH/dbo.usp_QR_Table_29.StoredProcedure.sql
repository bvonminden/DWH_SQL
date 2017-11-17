USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_QR_Table_29]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
		-- modified 10/5/2015 to new denominator - old fields commented out
-- =============================================
CREATE PROCEDURE [dbo].[usp_QR_Table_29] 
	-- Add the parameters for the stored procedure here
	@Quarter INT
	,@QuarterYear INT
	,@ReportType VARCHAR(50)
	,@State VARCHAR(5)
	,@AgencyID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
DECLARE @QuarterDate VARCHAR(50) 
SET @QuarterDate =	(
						CASE 
							WHEN @Quarter = 1 THEN '3/31/'+CAST(@QuarterYear AS VARCHAR(4)) 
							WHEN @Quarter = 2 THEN '6/30/'+CAST(@QuarterYear AS VARCHAR(4)) 
							WHEN @Quarter = 3 THEN '9/30/'+CAST(@QuarterYear AS VARCHAR(4)) 
							WHEN @Quarter = 4 THEN '12/31/'+CAST(@QuarterYear AS VARCHAR(4)) 
						END
					)
DECLARE @QuarterStart DATE SET @QuarterStart = DATEADD(DD,1,DATEADD(M,-3,CAST(@QuarterDate AS DATE))) 
IF OBJECT_ID('dbo.UC_QR_Table_29', 'U') IS NOT NULL DROP TABLE dbo.UC_QR_Table_29;

SET QUOTED_IDENTIFIER ON

SET NOCOUNT ON;


SELECT 
	DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID) [State]
	,PAS.SITE [Site]
	,PAS.SiteID,MAX(CASE WHEN PAS.ProgramName LIKE '%BRONX%' AND A.State = 'NY' THEN 1 END) [VNS]
	,DataWarehouse.dbo.udf_fn_GetCleanProg(PAS.ProgramID) ProgramName
	,CASE
		WHEN @ReportType = 'National' THEN 1
	END [National]
	,COUNT(DISTINCT
			CASE
				WHEN  DATEADD(month,5,C.INFANT_BIRTH_0_DOB) < @QuarterDate -- denom
				AND (EAD.EndDate IS NULL OR EAD.EndDate > DATEADD(month,5,C.INFANT_BIRTH_0_DOB)) -- denom
				AND ( 
						ASQ.INFANT_AGES_STAGES_1_COMM > = 0
						OR ASQ.INFANT_AGES_STAGES_1_FMOTOR > = 0
						OR ASQ.INFANT_AGES_STAGES_1_GMOTOR > = 0
						OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL > = 0
						OR ASQ.INFANT_AGES_STAGES_1_PSOLVE > = 0
						
						OR

						ASQ.INFANT_HEALTH_NO_ASQ_COMM IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_FINE IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_GROSS IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_PERSONAL IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_PROBLEM IS NOT NULL
					)
					AND ms.SurveyName = 'ASQ-3: Infancy 4 Months'
				THEN C.Client_ID
			END				
		) [Data 4 Mos]
	--,COUNT(DISTINCT
	--		CASE
	--			WHEN ( 
	--					ASQ.INFANT_AGES_STAGES_1_COMM > = 0
	--					OR ASQ.INFANT_AGES_STAGES_1_FMOTOR > = 0
	--					OR ASQ.INFANT_AGES_STAGES_1_GMOTOR > = 0
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL > = 0
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOLVE > = 0
	--					--OR IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL > = 0
	--				)
	--				AND ms.SurveyName = 'ASQ-3: Infancy 4 Months'
	--				AND ( 
	--					ASQ.INFANT_AGES_STAGES_1_COMM <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_FMOTOR <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_GMOTOR <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOLVE <> 0
	--					--OR IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL > = 0
	--				)
	--			THEN C.Client_ID
	--		END				
	--	) [Data 4 Mos]
	,COUNT(DISTINCT
			CASE
				WHEN DATEADD(month,5,C.INFANT_BIRTH_0_DOB) < @QuarterDate -- denom
				AND (EAD.EndDate IS NULL OR EAD.EndDate > DATEADD(month,5,C.INFANT_BIRTH_0_DOB)) -- denom
				AND ( 
						ASQ.INFANT_AGES_STAGES_1_COMM > = 0
						OR ASQ.INFANT_AGES_STAGES_1_FMOTOR > = 0
						OR ASQ.INFANT_AGES_STAGES_1_GMOTOR > = 0
						OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL > = 0
						OR ASQ.INFANT_AGES_STAGES_1_PSOLVE > = 0
					)
					AND ms.SurveyName = 'ASQ-3: Infancy 4 Months'
					AND 
					 (
						ASQ.INFANT_AGES_STAGES_1_COMM BETWEEN 0 AND  34.59
						OR ASQ.INFANT_AGES_STAGES_1_FMOTOR BETWEEN 0 AND  29.61
						OR ASQ.INFANT_AGES_STAGES_1_GMOTOR BETWEEN 0 AND  38.40
						OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL BETWEEN 0 AND  33.15
						OR ASQ.INFANT_AGES_STAGES_1_PSOLVE BETWEEN 0 AND  34.97
					)
				THEN C.Client_ID
			END				
		) [at 4 Mos num]
	,COUNT(DISTINCT
			CASE
				WHEN  DATEADD(month,5,C.INFANT_BIRTH_0_DOB) < @QuarterDate -- denom
				AND (EAD.EndDate IS NULL OR EAD.EndDate > DATEADD(month,5,C.INFANT_BIRTH_0_DOB)) -- denom
				AND ( 
						ASQ.INFANT_AGES_STAGES_1_COMM > = 0
						OR ASQ.INFANT_AGES_STAGES_1_FMOTOR > = 0
						OR ASQ.INFANT_AGES_STAGES_1_GMOTOR > = 0
						OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL > = 0
						OR ASQ.INFANT_AGES_STAGES_1_PSOLVE > = 0
						
						OR

						ASQ.INFANT_HEALTH_NO_ASQ_COMM IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_FINE IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_GROSS IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_PERSONAL IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_PROBLEM IS NOT NULL
					)
					AND ms.SurveyName = 'ASQ-3: Infancy 4 Months'
				THEN C.Client_ID
			END				
		) [at 4 Mos denom]
	--,COUNT(DISTINCT
	--		CASE
	--			WHEN (
	--					ASQ.INFANT_AGES_STAGES_1_COMM BETWEEN 0 AND  34.59
	--					OR ASQ.INFANT_AGES_STAGES_1_FMOTOR BETWEEN 0 AND  29.61
	--					OR ASQ.INFANT_AGES_STAGES_1_GMOTOR BETWEEN 0 AND  38.40
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL BETWEEN 0 AND  33.15
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOLVE BETWEEN 0 AND  34.97
	--				)
	--				AND ms.SurveyName = 'ASQ-3: Infancy 4 Months'
	--				AND ( 
	--					ASQ.INFANT_AGES_STAGES_1_COMM <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_FMOTOR <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_GMOTOR <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOLVE <> 0
	--					--OR IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL > = 0
	--				)
	--			THEN C.Client_ID
	--		END				
	--	) [at 4 Mos]
	,COUNT(DISTINCT
			CASE
				WHEN DATEADD(month,11,C.INFANT_BIRTH_0_DOB) < @QuarterDate -- denom
				AND (EAD.EndDate IS NULL OR EAD.EndDate > DATEADD(month,11,C.INFANT_BIRTH_0_DOB)) -- denom
				AND ( 
						ASQ.INFANT_AGES_STAGES_1_COMM > = 0
						OR ASQ.INFANT_AGES_STAGES_1_FMOTOR > = 0
						OR ASQ.INFANT_AGES_STAGES_1_GMOTOR > = 0
						OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL > = 0
						OR ASQ.INFANT_AGES_STAGES_1_PSOLVE > = 0
						
						OR

						ASQ.INFANT_HEALTH_NO_ASQ_COMM IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_FINE IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_GROSS IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_PERSONAL IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_PROBLEM IS NOT NULL
					)
					AND ms.SurveyName = 'ASQ-3: Infancy 10 Months'
				THEN C.Client_ID
			END				
		) [Data 10 Mos]
	--,COUNT(DISTINCT
	--		CASE
	--			WHEN ( 
	--					ASQ.INFANT_AGES_STAGES_1_COMM > = 0
	--					OR ASQ.INFANT_AGES_STAGES_1_FMOTOR > = 0
	--					OR ASQ.INFANT_AGES_STAGES_1_GMOTOR > = 0
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL > = 0
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOLVE > = 0
	--					--OR IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL > = 0
	--				)
	--				AND ms.SurveyName = 'ASQ-3: Infancy 10 Months'
	--				AND ( 
	--					ASQ.INFANT_AGES_STAGES_1_COMM <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_FMOTOR <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_GMOTOR <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOLVE <> 0
	--					--OR IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL > = 0
	--				)
	--			THEN C.Client_ID
	--		END				
	--	) [Data 10 Mos]
	,COUNT(DISTINCT
			CASE
				WHEN DATEADD(month,11,C.INFANT_BIRTH_0_DOB) < @QuarterDate -- denom
				AND (EAD.EndDate IS NULL OR EAD.EndDate > DATEADD(month,11,C.INFANT_BIRTH_0_DOB)) -- denom
				AND ( 
						ASQ.INFANT_AGES_STAGES_1_COMM > = 0
						OR ASQ.INFANT_AGES_STAGES_1_FMOTOR > = 0
						OR ASQ.INFANT_AGES_STAGES_1_GMOTOR > = 0
						OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL > = 0
						OR ASQ.INFANT_AGES_STAGES_1_PSOLVE > = 0
					)
					AND ms.SurveyName = 'ASQ-3: Infancy 10 Months'
					AND 
					 (
						ASQ.INFANT_AGES_STAGES_1_COMM BETWEEN 0 AND  22.86
						OR ASQ.INFANT_AGES_STAGES_1_FMOTOR BETWEEN 0 AND  37.96
						OR ASQ.INFANT_AGES_STAGES_1_GMOTOR BETWEEN 0 AND  30.06
						OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL BETWEEN 0 AND  27.24
						OR ASQ.INFANT_AGES_STAGES_1_PSOLVE BETWEEN 0 AND  32.50
					)
				THEN C.Client_ID
			END				
		) [at 10 Mos num]
	,COUNT(DISTINCT
			CASE
				WHEN DATEADD(month,11,C.INFANT_BIRTH_0_DOB) < @QuarterDate -- denom
				AND (EAD.EndDate IS NULL OR EAD.EndDate > DATEADD(month,11,C.INFANT_BIRTH_0_DOB)) -- denom
				AND ( 
						ASQ.INFANT_AGES_STAGES_1_COMM > = 0
						OR ASQ.INFANT_AGES_STAGES_1_FMOTOR > = 0
						OR ASQ.INFANT_AGES_STAGES_1_GMOTOR > = 0
						OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL > = 0
						OR ASQ.INFANT_AGES_STAGES_1_PSOLVE > = 0
						
						OR

						ASQ.INFANT_HEALTH_NO_ASQ_COMM IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_FINE IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_GROSS IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_PERSONAL IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_PROBLEM IS NOT NULL
					)
					AND ms.SurveyName = 'ASQ-3: Infancy 10 Months'
				THEN C.Client_ID
			END				
		) [at 10 Mos denom]
	--,COUNT(DISTINCT
	--		CASE
	--			WHEN (
	--					ASQ.INFANT_AGES_STAGES_1_COMM BETWEEN 0 AND  22.86
	--					OR ASQ.INFANT_AGES_STAGES_1_FMOTOR BETWEEN 0 AND  37.96
	--					OR ASQ.INFANT_AGES_STAGES_1_GMOTOR BETWEEN 0 AND  30.06
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL BETWEEN 0 AND  27.24
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOLVE BETWEEN 0 AND  32.50
	--				)
	--				AND ms.SurveyName = 'ASQ-3: Infancy 10 Months'
	--				AND ( 
	--					ASQ.INFANT_AGES_STAGES_1_COMM <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_FMOTOR <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_GMOTOR <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOLVE <> 0
	--					--OR IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL > = 0
	--				)
	--			THEN C.Client_ID
	--		END				
	--	) [at 10 Mos]
	,COUNT(DISTINCT
			CASE
				WHEN  DATEADD(month,15,C.INFANT_BIRTH_0_DOB) < @QuarterDate -- denom
				AND (EAD.EndDate IS NULL OR EAD.EndDate > DATEADD(month,15,C.INFANT_BIRTH_0_DOB)) -- denom
				AND ( 
						ASQ.INFANT_AGES_STAGES_1_COMM > = 0
						OR ASQ.INFANT_AGES_STAGES_1_FMOTOR > = 0
						OR ASQ.INFANT_AGES_STAGES_1_GMOTOR > = 0
						OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL > = 0
						OR ASQ.INFANT_AGES_STAGES_1_PSOLVE > = 0
						
						OR

						ASQ.INFANT_HEALTH_NO_ASQ_COMM IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_FINE IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_GROSS IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_PERSONAL IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_PROBLEM IS NOT NULL
					)
					AND ms.SurveyName = 'ASQ-3: Toddler 14 Months'
				THEN C.Client_ID
			END				
		) [Data 14 Mos]
	--,COUNT(DISTINCT
	--		CASE
	--			WHEN ( 
	--					ASQ.INFANT_AGES_STAGES_1_COMM > = 0
	--					OR ASQ.INFANT_AGES_STAGES_1_FMOTOR > = 0
	--					OR ASQ.INFANT_AGES_STAGES_1_GMOTOR > = 0
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL > = 0
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOLVE > = 0
	--					--OR IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL > = 0
	--				)
	--				AND ms.SurveyName = 'ASQ-3: Toddler 14 Months'
	--				AND ( 
	--					ASQ.INFANT_AGES_STAGES_1_COMM <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_FMOTOR <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_GMOTOR <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOLVE <> 0
	--					--OR IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL > = 0
	--				)
	--			THEN C.Client_ID
	--		END				
	--	) [Data 14 Mos]
	,COUNT(DISTINCT
			CASE
				WHEN  DATEADD(month,15,C.INFANT_BIRTH_0_DOB) < @QuarterDate -- denom
				AND (EAD.EndDate IS NULL OR EAD.EndDate > DATEADD(month,15,C.INFANT_BIRTH_0_DOB)) -- denom
				AND ( 
						ASQ.INFANT_AGES_STAGES_1_COMM > = 0
						OR ASQ.INFANT_AGES_STAGES_1_FMOTOR > = 0
						OR ASQ.INFANT_AGES_STAGES_1_GMOTOR > = 0
						OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL > = 0
						OR ASQ.INFANT_AGES_STAGES_1_PSOLVE > = 0
					)
					AND ms.SurveyName = 'ASQ-3: Toddler 14 Months'
					AND 
					 (
						ASQ.INFANT_AGES_STAGES_1_COMM BETWEEN 0 AND 17.39
						OR ASQ.INFANT_AGES_STAGES_1_FMOTOR BETWEEN 0 AND 23.05
						OR ASQ.INFANT_AGES_STAGES_1_GMOTOR BETWEEN 0 AND 25.79
						OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL BETWEEN 0 AND 23.17
						OR ASQ.INFANT_AGES_STAGES_1_PSOLVE BETWEEN 0 AND 22.55
					)
				THEN C.Client_ID
			END				
		) [at 14 Mos num]
	,COUNT(DISTINCT
			CASE
				WHEN  DATEADD(month,15,C.INFANT_BIRTH_0_DOB) < @QuarterDate -- denom
				AND (EAD.EndDate IS NULL OR EAD.EndDate > DATEADD(month,15,C.INFANT_BIRTH_0_DOB)) -- denom
				AND ( 
						ASQ.INFANT_AGES_STAGES_1_COMM > = 0
						OR ASQ.INFANT_AGES_STAGES_1_FMOTOR > = 0
						OR ASQ.INFANT_AGES_STAGES_1_GMOTOR > = 0
						OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL > = 0
						OR ASQ.INFANT_AGES_STAGES_1_PSOLVE > = 0
						
						OR

						ASQ.INFANT_HEALTH_NO_ASQ_COMM IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_FINE IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_GROSS IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_PERSONAL IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_PROBLEM IS NOT NULL
					)
					AND ms.SurveyName = 'ASQ-3: Toddler 14 Months'
				THEN C.Client_ID
			END				
		) [at 14 Mos denom]
	--,COUNT(DISTINCT
	--		CASE
	--			WHEN (
	--					ASQ.INFANT_AGES_STAGES_1_COMM BETWEEN 0 AND  17.39
	--					OR ASQ.INFANT_AGES_STAGES_1_FMOTOR BETWEEN 0 AND  23.05
	--					OR ASQ.INFANT_AGES_STAGES_1_GMOTOR BETWEEN 0 AND  25.79
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL BETWEEN 0 AND  23.17
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOLVE BETWEEN 0 AND  22.55
	--				)
	--				AND ms.SurveyName = 'ASQ-3: Toddler 14 Months'
	--				AND ( 
	--					ASQ.INFANT_AGES_STAGES_1_COMM <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_FMOTOR <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_GMOTOR <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOLVE <> 0
	--					--OR IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL > = 0
	--				)
	--			THEN C.Client_ID
	--		END				
	--	) [at 14 Mos]
	,COUNT(DISTINCT
			CASE
				WHEN  DATEADD(month,21,C.INFANT_BIRTH_0_DOB) < @QuarterDate -- denom
				AND (EAD.EndDate IS NULL OR EAD.EndDate > DATEADD(month,21,C.INFANT_BIRTH_0_DOB)) -- denom
				AND ( 
						ASQ.INFANT_AGES_STAGES_1_COMM > = 0
						OR ASQ.INFANT_AGES_STAGES_1_FMOTOR > = 0
						OR ASQ.INFANT_AGES_STAGES_1_GMOTOR > = 0
						OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL > = 0
						OR ASQ.INFANT_AGES_STAGES_1_PSOLVE > = 0
						
						OR

						ASQ.INFANT_HEALTH_NO_ASQ_COMM IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_FINE IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_GROSS IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_PERSONAL IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_PROBLEM IS NOT NULL
					)
					AND ms.SurveyName = 'ASQ-3: Toddler 20 Months'
				THEN C.Client_ID
			END				
		) [Data 20 Mos]
		
	--,COUNT(DISTINCT
	--		CASE
	--			WHEN ( 
	--					ASQ.INFANT_AGES_STAGES_1_COMM > = 0
	--					OR ASQ.INFANT_AGES_STAGES_1_FMOTOR > = 0
	--					OR ASQ.INFANT_AGES_STAGES_1_GMOTOR > = 0
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL > = 0
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOLVE > = 0
	--					--OR IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL > = 0
	--				)
	--				AND ms.SurveyName = 'ASQ-3: Toddler 20 Months'
	--				AND ( 
	--					ASQ.INFANT_AGES_STAGES_1_COMM <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_FMOTOR <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_GMOTOR <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOLVE <> 0
	--					--OR IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL > = 0
	--				)
	--			THEN C.Client_ID
	--		END				
	--	) [Data 20 Mos]
	,COUNT(DISTINCT
			CASE
				WHEN  DATEADD(month,21,C.INFANT_BIRTH_0_DOB) < @QuarterDate -- denom
				AND (EAD.EndDate IS NULL OR EAD.EndDate > DATEADD(month,21,C.INFANT_BIRTH_0_DOB)) -- denom
				AND ( 
						ASQ.INFANT_AGES_STAGES_1_COMM > = 0
						OR ASQ.INFANT_AGES_STAGES_1_FMOTOR > = 0
						OR ASQ.INFANT_AGES_STAGES_1_GMOTOR > = 0
						OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL > = 0
						OR ASQ.INFANT_AGES_STAGES_1_PSOLVE > = 0
					)
					AND ms.SurveyName = 'ASQ-3: Toddler 20 Months'
					AND 
					 (
						ASQ.INFANT_AGES_STAGES_1_COMM BETWEEN 0 AND 20.49
						OR ASQ.INFANT_AGES_STAGES_1_FMOTOR BETWEEN 0 AND 36.04
						OR ASQ.INFANT_AGES_STAGES_1_GMOTOR BETWEEN 0 AND 39.88
						OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL BETWEEN 0 AND 33.35
						OR ASQ.INFANT_AGES_STAGES_1_PSOLVE BETWEEN 0 AND 28.83
					)
				THEN C.Client_ID
			END				
		) [at 20 Mos num]
	,COUNT(DISTINCT
			CASE
				WHEN  DATEADD(month,21,C.INFANT_BIRTH_0_DOB) < @QuarterDate -- denom
				AND (EAD.EndDate IS NULL OR EAD.EndDate > DATEADD(month,21,C.INFANT_BIRTH_0_DOB)) -- denom
				AND ( 
						ASQ.INFANT_AGES_STAGES_1_COMM > = 0
						OR ASQ.INFANT_AGES_STAGES_1_FMOTOR > = 0
						OR ASQ.INFANT_AGES_STAGES_1_GMOTOR > = 0
						OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL > = 0
						OR ASQ.INFANT_AGES_STAGES_1_PSOLVE > = 0
						
						OR

						ASQ.INFANT_HEALTH_NO_ASQ_COMM IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_FINE IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_GROSS IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_PERSONAL IS NOT NULL
						OR ASQ.INFANT_HEALTH_NO_ASQ_PROBLEM IS NOT NULL
					)
					AND ms.SurveyName = 'ASQ-3: Toddler 20 Months'
				THEN C.Client_ID
			END				
		) [at 20 Mos denom]
	--,COUNT(DISTINCT
	--		CASE
	--			WHEN (
	--					ASQ.INFANT_AGES_STAGES_1_COMM BETWEEN 0 AND  20.49
	--					OR ASQ.INFANT_AGES_STAGES_1_FMOTOR BETWEEN 0 AND  36.04
	--					OR ASQ.INFANT_AGES_STAGES_1_GMOTOR BETWEEN 0 AND  39.88
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL BETWEEN 0 AND  33.35
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOLVE BETWEEN 0 AND  28.83
	--				)
	--				AND ms.SurveyName = 'ASQ-3: Toddler 20 Months'
	--				AND ( 
	--					ASQ.INFANT_AGES_STAGES_1_COMM <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_FMOTOR <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_GMOTOR <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOCIAL <> 0
	--					OR ASQ.INFANT_AGES_STAGES_1_PSOLVE <> 0
	--					--OR IHS.INFANT_AGES_STAGES_SE_0_EMOTIONAL > = 0
	--				)
	--			THEN C.Client_ID
	--		END				
	--	) [at 20 Mos]
		
	--,COUNT(DISTINCT
	--		CASE
	--			WHEN ASQ.CL_EN_GEN_ID IS NOT NULL
	--				AND ms.SurveyName = 'ASQ-3: Infancy 4 Months'
	--			THEN C.Client_ID
	--		END				
	--	) [Child 4 Mos]
	,COUNT(DISTINCT
			CASE
				WHEN DATEADD(month,5,C.INFANT_BIRTH_0_DOB) < @QuarterDate
				AND (EAD.EndDate IS NULL OR EAD.EndDate > DATEADD(month,5,C.INFANT_BIRTH_0_DOB))
				THEN C.Client_ID
			END				
		) [Child 4 Mos]
	--,COUNT(DISTINCT
	--		CASE
	--			WHEN ASQ.CL_EN_GEN_ID IS NOT NULL
	--				AND ms.SurveyName LIKE 'ASQ-3: Infancy 10 Months'
	--			THEN C.Client_ID
	--		END				
	--	) [Child 10 Mos]
	,COUNT(DISTINCT
			CASE
				WHEN DATEADD(month,11,C.INFANT_BIRTH_0_DOB) < @QuarterDate
				AND (EAD.EndDate IS NULL OR EAD.EndDate > DATEADD(month,11,C.INFANT_BIRTH_0_DOB))
				THEN C.Client_ID
			END				
		) [Child 10 Mos]
	--,COUNT(DISTINCT
	--		CASE
	--			WHEN ASQ.CL_EN_GEN_ID IS NOT NULL
	--				AND ms.SurveyName LIKE 'ASQ-3: Toddler 14 Months'
	--			THEN C.Client_ID
	--		END				
	--	) [Child 14 Mos]
	,COUNT(DISTINCT
			CASE
				WHEN DATEADD(month,15,C.INFANT_BIRTH_0_DOB) < @QuarterDate
				AND (EAD.EndDate IS NULL OR EAD.EndDate > DATEADD(month,15,C.INFANT_BIRTH_0_DOB))
				THEN C.Client_ID
			END				
		) [Child 14 Mos]
	--,COUNT(DISTINCT
	--		CASE
	--			WHEN ASQ.CL_EN_GEN_ID IS NOT NULL
	--				AND ms.SurveyName LIKE 'ASQ-3: Toddler 20 Months'
	--			THEN C.Client_ID
	--		END				
	--	) [Child 20 Mos]
	--,[CLIENT_TRIBAL_0_PARITY]
	,COUNT(DISTINCT
			CASE
				WHEN DATEADD(month,21,C.INFANT_BIRTH_0_DOB) < @QuarterDate
				AND (EAD.EndDate IS NULL OR EAD.EndDate > DATEADD(month,21,C.INFANT_BIRTH_0_DOB))
				THEN C.Client_ID
			END				
		) [Child 20 Mos]
	,[CLIENT_TRIBAL_0_PARITY]
	
INTO datawarehouse.[dbo].[UC_QR_Table_29]	
FROM DataWarehouse..Clients C
	INNER JOIN DataWarehouse..UV_EADT EAD
		ON EAD.CLID = C.Client_Id
		AND EAD.ProgramStartDate < = @QuarterDate 
	--INNER JOIN EADT EAD2
	--	ON EAD2.CaseNumber = EAD.CaseNumber
	--	AND EAD2.RankingLatest = 1
	--	AND EAD2.ProgramStartDate < = @QuarterDate 
	INNER JOIN DataWarehouse..UV_PAS PAS
		ON PAS.ProgramID = EAD.ProgramID 
		
		INNER JOIN DataWarehouse..Agencies A
			ON A.Site_ID = PAS.SiteID
	--- removed 4/13/2015 to switch to ASQ3_Survey
	--INNER JOIN DataWarehouse..Infant_Health_Survey IHS
	--	ON IHS.CL_EN_GEN_ID = EAD.CLID
	--	AND IHS.ProgramID = EAD.ProgramID
	--	AND IHS.SurveyDate BETWEEN '10/1/2006' AND @QuarterDate
	LEFT JOIN ASQ3_Survey ASQ
		INNER JOIN DataWarehouse..Mstr_surveys ms
			ON ASQ.SurveyID = ms.SurveyID 
		ON EAD.CLID = ASQ.CL_EN_GEN_ID
		AND EAD.ProgramID = ASQ.ProgramID
		--AND ASQ.SurveyDate <= @QuarterDate -- added to test if it corrects data
	LEFT JOIN DataWarehouse..UC_Client_Exclusion_YWCA YWCA 
		ON YWCA.CLID = EAD.CLID AND EAD.SiteID = 222
	LEFT JOIN DataWarehouse..Tribal_Survey TS
            ON TS.CL_EN_GEN_ID = EAD.CLID
            AND TS.ProgramID = EAD.ProgramID
WHERE
	YWCA.CLID IS NULL
	--AND (TS.CLIENT_TRIBAL_0_PARITY LIKE '%PRIMIP%' OR TS.CLIENT_TRIBAL_0_PARITY IS NULL)
	

	
GROUP BY DataWarehouse.dbo.udf_StateVSTribal(A.State,PAS.SiteID)
	,PAS.SITE 
	,PAS.SiteID
	,DataWarehouse.dbo.udf_fn_GetCleanProg(PAS.ProgramID) 	
	,[CLIENT_TRIBAL_0_PARITY]

UNION ALL 

SELECT DISTINCT
	DataWarehouse.dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
	,P.SITE
	,P.SiteID
	,(CASE WHEN P.ProgramName LIKE '%BRONX%' AND P.Abbreviation = 'NY' THEN 1 END) [VNS]
	,DataWarehouse.dbo.udf_fn_GetCleanProg(P.ProgramID) ProgramName
	,CASE
		WHEN @ReportType = 'National' THEN 1
	END [National]
	,0,0,0,0 ,0,0,0,0 ,0,0,0,0 ,0,0,0,0 ,NULL
	
FROM DataWarehouse..UV_PAS P
	--INNER JOIN DataWarehouse..Tribal_Survey T
	--	ON T.SiteID = P.SiteID	
	--	AND T.CLIENT_TRIBAL_0_PARITY IS NOT NULL
	

UNION ALL

SELECT DISTINCT
	DataWarehouse.dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
	,P.SITE
	,P.SiteID
	,(CASE WHEN P.ProgramName LIKE '%BRONX%' AND P.Abbreviation = 'NY' THEN 1 END) [VNS]
	,DataWarehouse.dbo.udf_fn_GetCleanProg(P.ProgramID) ProgramName
	,CASE
		WHEN @ReportType = 'National' THEN 1
	END [National]
	,0,0,0,0 ,0,0,0,0 ,0,0,0,0 ,0,0,0,0 ,'Multiparous (pregnant with a second or subsequent child)'
	
FROM DataWarehouse..UV_PAS P
	INNER JOIN DataWarehouse..Tribal_Survey T
		ON T.SiteID = P.SiteID	
		AND T.CLIENT_TRIBAL_0_PARITY IS NOT NULL	
UNION ALL

SELECT DISTINCT
	DataWarehouse.dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
	,P.SITE
	,P.SiteID
	,(CASE WHEN P.ProgramName LIKE '%BRONX%' AND P.Abbreviation = 'NY' THEN 1 END) [VNS]
	,DataWarehouse.dbo.udf_fn_GetCleanProg(P.ProgramID) ProgramName
	,CASE
		WHEN @ReportType = 'National' THEN 1
	END [National]
	,0,0,0,0 ,0,0,0,0 ,0,0,0,0 ,0,0,0,0 ,'Primiparous (pregnant with her first child)'
	
FROM DataWarehouse..UV_PAS P
	INNER JOIN DataWarehouse..Tribal_Survey T
		ON T.SiteID = P.SiteID	
		AND T.CLIENT_TRIBAL_0_PARITY IS NOT NULL
	
--OPTION(RECOMPILE)
END

GO
