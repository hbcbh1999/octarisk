function s = rollout (retail, value_type, arg1, arg2, arg3, arg4)
  s = retail;
  
  % all other retail types (like FRB etc.)
	if ( nargin < 3)
		valuation_date = today;
	elseif ( nargin == 3)
		valuation_date = arg1;
	elseif ( nargin == 4)
		valuation_date = arg1;	
		curve1_object = arg2;
	elseif ( nargin == 5)
		valuation_date = arg1;	
		curve1_object = arg2;
		curve2_object = arg3;
	else
		error('Wrong number of arguments');
	end
	% call function for rolling out cashflows
	
	if strcmpi(s.sub_type,'DCP')
		[ret_dates ret_values ret_int ret_principal accr_int last_coupon_date] = ...
					rollout_retail_cashflows(valuation_date,value_type,s,curve1_object);
	elseif strcmpi(s.sub_type,'SAVPLAN')
		[ret_dates ret_values ret_int ret_principal accr_int last_coupon_date] = ...
					rollout_retail_cashflows(valuation_date,value_type,s);
	elseif strcmpi(s.sub_type,'RETEXP') || strcmpi(s.sub_type,'GOVPEN') 	% retirements expenses
		% curve1_object = inflation expectation curve
		% curve2_object = longevity table
		[ret_dates ret_values ret_int ret_principal accr_int last_coupon_date] = ...
					rollout_retail_cashflows(valuation_date,value_type,s, ...
					curve1_object, curve2_object);		
	else
		% not defined
	end				

  % set property value pairs to object
  s = s.set('cf_dates',ret_dates);
  s = s.set('accrued_interest',accr_int);
  s = s.set('last_coupon_date',last_coupon_date);
  if ( strcmp(value_type,'stress'))
      s = s.set('cf_values_stress',ret_values);
  elseif ( strcmp(value_type,'base')) 
      s = s.set('cf_values',ret_values);
  else
      s = s.set('cf_values_mc',ret_values,'timestep_mc_cf',value_type);
  end
   
end


