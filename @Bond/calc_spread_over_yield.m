function s = calc_spread_over_yield (bond,valuation_date,discount_curve,call_schedule,put_schedule)
   s = bond;
   % Start parameter
   x0 = 0.01;
   lb = -1;
   ub = 1;

   if ( nargin < 3)
        error('Error: No  discount curve set. Aborting.');
   end
   
   if ischar(valuation_date)
       valuation_date = datenum(valuation_date,1);
   end

   % Get reference curve nodes and rate
        tmp_nodes    = discount_curve.get('nodes');
        tmp_rates    = discount_curve.getValue('base');

    % Get interpolation method
        tmp_interp_discount = discount_curve.get('method_interpolation');
        tmp_curve_dcc       = discount_curve.get('day_count_convention');
        tmp_curve_basis     = discount_curve.get('basis');
        tmp_curve_comp_type = discount_curve.get('compounding_type');
        tmp_curve_comp_freq = discount_curve.get('compounding_freq');
    
    % Get bond related basis and conventions
    basis       = s.basis;
    comp_type   = s.compounding_type;
    comp_freq   = s.compounding_freq;    
  % Check, whether cash flow have already been roll out    
  if ( length(s.cf_values) < 1)
        disp('Warning: No cash flows defined for bond. setting SoY = 0.0')
        s.soy = 0.0;
  else
    % get dirty value
    if s.clean_value_base == true
        value_dirty = s.value_base + s.accrued_interest;
    else
        value_dirty = s.value_base;
    end

    % calculate embedded option value
    if ( bond.embedded_option_flag == true)
        if ( nargin < 5)
            error('Error: No call or put schedule set. Aborting.');
        end
        % check whether call or put schedule have been set
        if isobject(call_schedule)
            if ~(strcmpi(call_schedule.type,'Call Schedule'))
                error('Error: Not a call schedule: >>%s<<. Aborting.',any2str(call_schedule.id));
            end
        else    
            call_schedule = [];
        end
        if isobject(put_schedule)
            if ~(strcmpi(put_schedule.type,'Put Schedule'))
                error('Error: Not a put schedule: >>%s<<. Aborting.',any2str(put_schedule.id));
            end
        else    
            put_schedule = [];
        end
        if (length(put_schedule) == 0 && length(call_schedule) == 0)
            error('Error: At least a call or put schedule have to be set.');
        end
        % call option pricing function
        OptionValue = option_bond_hw('base',bond,discount_curve, ...
                                                    call_schedule,put_schedule);
        % adjust value_dirty by embedded option value:
        value_dirty = value_dirty - OptionValue;
    end
    
    % get cf values and dates (take only first value)
    cf_values = s.cf_values(1,:);
    cf_dates = s.cf_dates;
    
    % get time factors and interpolated rates to speed up valuation function
    [tf_vec rate_vec] = get_bond_tf_rates(valuation_date, ...
            cf_dates, cf_values, 0.0, tmp_nodes, ...
            tmp_rates, basis, comp_type, comp_freq, tmp_interp_discount, ...
            tmp_curve_comp_type, tmp_curve_basis, tmp_curve_comp_freq, false);
    
    % set up objective function
    objfunc = @ (x) phi_soy(x,valuation_date,cf_dates, ...
            cf_values,value_dirty,tmp_curve_comp_type, tmp_curve_basis, ...
            tmp_curve_comp_freq, rate_vec);
    
    % calculate spread over yield (with fixed embedded option value)    
    [spread_over_yield retcode] = calibrate_generic(objfunc,x0,lb,ub);
            
     if ( retcode > 0 ) %failed calibration
        fprintf('Calibration failed for %s. Setting value_base to theo_value.\n',s.id); 
        % calculating theo_value in base case     
        theo_value = pricing_npv(valuation_date,s.cf_dates,s.cf_values(1,:), ...
                0.0,tmp_nodes,tmp_rates, basis, comp_type, ...
                comp_freq, tmp_interp_discount, tmp_curve_comp_type, ...
                tmp_curve_basis, tmp_curve_comp_freq);
        % setting value base to theo value with soy = 0
        s = s.set('value_base',theo_value(1));
        % setting calibration flag to 1 anyhow, since we do not want a failed 
        % calibration a second time...
        s.calibration_flag = 1; 
     else
        s.soy = spread_over_yield;
        s.calibration_flag = 1;
     end
  end
end


%-------------------------------------------------------------------------------
%------------------- Begin Subfunctions ----------------------------------------
 
% Definition Objective Function for spread over yield:  
function obj = phi_soy (x,valuation_date,cf_dates,cf_values,act_value, ...
                comp_type_curve, basis_curve, comp_freq_curve,rate_vec)
        % convert constant spread 
        x = convert_curve_rates(valuation_date,cf_dates', ...
                        x,'continuous','annual',3, ...
                        comp_type_curve,comp_freq_curve,basis_curve)';
        % add spread to interpolated rates
        rate_vec = rate_vec + x;
        % get discount factor
        tmp_df  = discount_factor (valuation_date, valuation_date + cf_dates', ...
                                               rate_vec', comp_type_curve, ...
                                               basis_curve, comp_freq_curve); 
        % Calculate actual NPV of cash flows    
        tmp_npv = cf_values * tmp_df;
        obj = (act_value - tmp_npv).^2;
end    

%------------------------------------------------------------------

