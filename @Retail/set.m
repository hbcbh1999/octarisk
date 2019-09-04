% setting attribute values
function obj = set(obj, varargin)
  % A) Specify fieldnames <-> types key/value pairs
  typestruct = struct(...
                'accrued_interest', 'numeric' , ...
                'last_coupon_date', 'numeric' , ...
                'ir_shock', 'numeric' , ...
                'soy', 'numeric' , ...
                'convexity', 'numeric' , ...
                'dollar_convexity', 'numeric' , ...
                'cf_values_mc', 'special' , ...
                'cf_values_stress', 'numeric' , ...
                'cf_values', 'numeric' , ...
                'cf_dates', 'numeric' , ...
                'value_mc', 'special' , ...
                'value_stress', 'special' , ...
                'value_base', 'numeric' , ...
                'exposure_base', 'numeric' , ...
                'exposure_stress', 'special' , ...
                'exposure_mc', 'special' , ...
                'timestep_mc', 'special' , ...
                'timestep_mc_cf', 'special' , ...
                'name', 'char' , ...
                'id', 'char' , ...
                'issue_date', 'date' , ...
                'maturity_date', 'date' , ...
                'reference_curve', 'char' , ...
                'discount_curve', 'char' , ...
                'coupon_generation_method', 'char' , ...
                'term', 'numeric' , ...
                'term_unit', 'char', ...
                'compounding_freq', 'charvnumber' , ...
                'day_count_convention', 'char' , ...
                'compounding_type', 'char' , ...
                'sub_type', 'char' , ...
                'valuation_date', 'date' , ...
                'asset_class', 'char' , ...
                'currency', 'char' , ...
                'description', 'char' , ...
                'notional', 'numeric' , ...
                'coupon_rate', 'numeric' , ...
                'business_day_rule', 'numeric' , ...
                'business_day_direction', 'numeric' , ...
                'enable_business_day_rule', 'boolean' , ...
                'prepayment_flag', 'boolean' , ...
                'spread', 'numeric' , ...
                'long_first_period', 'boolean' , ...
                'long_last_period', 'boolean' , ...
                'last_reset_rate', 'numeric' , ...
                'ytm', 'numeric' , ...
                'mod_duration', 'numeric' , ...
                'mac_duration', 'numeric' , ...
                'eff_duration', 'numeric' , ...
                'eff_convexity', 'numeric' , ...
                'dv01', 'numeric' , ...
                'pv01', 'numeric' , ...
                'dollar_duration', 'numeric' , ...
                'spread_duration', 'numeric' , ...
                'in_arrears', 'boolean' , ...
                'notional_at_start', 'boolean' , ...
                'notional_at_end', 'boolean', ...
                'type', 'char', ...
                'basis', 'numeric', ...
                'calibration_flag', 'boolean', ...
                'prorated', 'boolean', ...
                'redemption_values', 'numeric', ...
                'redemption_dates', 'cell', ...
                'savings_startdate', 'date', ...
                'savings_enddate', 'date', ...
                'notice_period', 'numeric', ...
                'notice_period_unit', 'char', ...
                'savings_rate', 'numeric', ...
                'protection_scheme_limit', 'numeric', ...
                'bonus_value_current', 'numeric', ...
                'bonus_value_redemption', 'numeric', ...
                'extra_payment_values', 'numeric', ...
                'extra_payment_dates', 'cell', ...    
                'savings_change_values', 'numeric', ...
                'savings_change_dates', 'cell', ...    
                'region_id', 'cell', ...
				'rating_id', 'cell', ...
				'style_id', 'cell', ...
				'duration_id', 'cell', ...
				'country_id', 'cell', ...
				'country_values', 'numeric', ... 
				'region_values', 'numeric', ... 
				'style_values', 'numeric', ... 
				'rating_values', 'numeric', ...
				'duration_values', 'numeric', ...               
				'esg_score', 'numeric', ...
				'YYYREPLACEINSTRUMENTATTRIBUTEYYY', 'char' , ...
				'issuer', 'char' , ...
				'counterparty', 'char' , ...
				'XXXREPLACEINSTRUMENTATTRIBUTEXXX', 'char' , ...
				'designated_sponsor', 'char' , ...
				'market_maker', 'char' , ...
				'custodian_bank_underlyings', 'char' , ...
				'country_of_origin', 'char' , ...
				'fund_replication', 'char' , ...
                'key_term', 'numeric', ...
                'key_rate_shock', 'numeric', ...
                'key_rate_width', 'numeric', ...
                'key_rate_eff_dur', 'numeric', ...
                'key_rate_mon_dur', 'numeric', ...
                'key_rate_eff_convex', 'numeric', ...
                'key_rate_mon_convex', 'numeric', ...
                'embedded_option_value', 'numeric'...
               );
  % B) store values in object
  if (length (varargin) < 2 || rem (length (varargin), 2) ~= 0)
    error ('set: expecting property/value pairs');
  end
  
  while (length (varargin) > 1)
    prop = varargin{1};
    prop = lower(prop);
    val = varargin{2};
    varargin(1:2) = [];
    % check, if property is an existing field
    if (sum(strcmpi(prop,fieldnames(typestruct)))==0)
        fprintf('set: not an allowed fieldname >>%s<< with value >>%s<< :\n',prop,any2str(val));
        fieldnames(typestruct)
        error ('set: invalid property of %s class: >>%s<<\n',class(obj),prop);
    end
    % get property type:
    type = typestruct.(prop);
    % input checks and validation
    retval = return_checked_input(obj,val,prop,type);
    % store property in object
    obj.(prop) = retval;
  end
end   
