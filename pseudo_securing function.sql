CREATE FUNCTION survey_views.udf_secure_fact_survey_response
(
	@p_survey_name varchar(100),
	@p_requested_hashing_policy char(10)=null
)
RETURNS 
@result TABLE 
(
	survey_response_id bigint,
	pseudonym varchar(256),
	secured_value varchar(256)
)
AS
BEGIN

if(@p_requested_hashing_policy is null) -- no requested hashing policy so just return as requested
begin

	insert into @result
	select 
		fr.survey_response_id,
		sq.pseudonym,
 		coalesce(fr.text_response,
									cast(fr.numeric_response as varchar),
									cast(fr.date_response as varchar), 
									cast(fr.boolean_response as varchar))
		 as secured_response

	   from fact_survey_response			fr  
		inner join dim_survey_question      sq		on fr.survey_question_key			= sq.survey_question_key
  
	  where 
		sq.survey_name = @p_survey_name
 
	  group by 
  
		fr.survey_response_id,
		sq.pseudonym,
		coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar));

end
else
begin -- in hashing policy so hash if the pseudo matches the policy

	insert into @result
	select 
		fr.survey_response_id,
		sq.pseudonym,
		case
			when (@p_requested_hashing_policy=hpm.policy_codifier) 
			
			then survey_views.f_hash_field( 
								coalesce(fr.text_response,
									cast(fr.numeric_response as varchar),
									cast(fr.date_response as varchar), 
									cast(fr.boolean_response as varchar)))
			
			else 				coalesce(fr.text_response,
									cast(fr.numeric_response as varchar),
									cast(fr.date_response as varchar), 
									cast(fr.boolean_response as varchar))
		 end
		 as secured_response


	   from fact_survey_response					fr  
			inner	join dim_survey_question		sq			on fr.survey_question_key			= sq.survey_question_key
			
			left	join (select distinct z.policy_codifier, z.pseudonym
							 from survey_views.pseudo_security z where z.policy_codifier=@p_requested_hashing_policy)			
													hpm			on (hpm.pseudonym = sq.pseudonym )

  
	  where 
		sq.survey_name			= @p_survey_name

	  group by 
  
		fr.survey_response_id,
		sq.pseudonym,
		coalesce(fr.text_response,cast(fr.numeric_response as varchar),cast(fr.date_response as varchar), cast(fr.boolean_response as varchar)),
		hpm.policy_codifier


end;


 
 return;
END
GO