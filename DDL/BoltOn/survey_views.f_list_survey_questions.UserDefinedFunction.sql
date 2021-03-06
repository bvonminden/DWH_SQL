USE [dwh_test]
GO
/****** Object:  UserDefinedFunction [survey_views].[f_list_survey_questions]    Script Date: 11/27/2017 1:27:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [survey_views].[f_list_survey_questions]
(
	@p_survey_name varchar(100),
	@p_survey_time_period varchar (100)
)
RETURNS 
@t_result TABLE 
(
	survey_time_period varchar(75),
	question_number smallint,
	question varchar(3400)
)
AS
BEGIN
-- displays the list of questions asked for a given survey
	
insert into @t_result (survey_time_period, question_number, question)
Select
	sq.time_period,
	sq.question_number,
	sq.question
from dbo.dim_survey_question sq
where
	sq.survey_name=@p_survey_name
	and
	sq.time_period = case when @p_survey_time_period='*' then sq.time_period else  @p_survey_time_period	end
order by 
	question_number;

return;	
END
GO
