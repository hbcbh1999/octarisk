% @Position/aggregate.m: Aggregate all positions (to portfolio) or instruments to position
function obj = aggregate (obj, scen_set, instrument_struct, index_struct, para)
    if ~(nargin == 5)
        print_usage ();
    end
      
    if ( strcmpi(obj.type,'PORTFOLIO'))
        theo_value = 0.0;
        theo_exposure = 0.0;
        port_mod_dur = 0.0;
        cash_value = 0.0;
        accr_int = 0.0;
        for (ii=1:1:length(obj.positions))
            pos_obj = obj.positions(ii).object;
            pos_id = obj.positions(ii).id;
            if (isobject(pos_obj))
                % Preaggregate position object
                pos_obj_new = pos_obj.aggregate(scen_set, instrument_struct, index_struct, para);
                pos_value = pos_obj_new.getValue(scen_set);
                pos_value_base = pos_obj_new.getValue('base');
                pos_currency = pos_obj_new.get('currency');
                % Get FX rate:
                if ( strcmp(obj.currency,pos_currency) == 1 )
                    tmp_fx_rate = 1;
                    tmp_fx_rate_base = 1;
                else
                    tmp_fx_index        = strcat('FX_', obj.currency, pos_currency);
                    [tmp_fx_struct_obj object_ret_code]  = get_sub_object(index_struct, tmp_fx_index);
                    if ( object_ret_code == 0 )
                        error('WARNING: No index_struct object found for FX id >>%s<<\n',tmp_fx_index);
                    end 
                    tmp_fx_rate       = tmp_fx_struct_obj.getValue(scen_set);   
                    tmp_fx_rate_base  = tmp_fx_struct_obj.getValue('base');   
                end
                % Fill base and scenario values   
                theo_value_pos = pos_value ./ tmp_fx_rate;  
                theo_value_pos_base = pos_value_base ./ tmp_fx_rate_base;  
                theo_value = theo_value + theo_value_pos;
                if (strcmpi(scen_set,'base'))
                    if ~isempty(pos_obj_new.tpt_90)
                        port_mod_dur = port_mod_dur + ...
                                            theo_value_pos * pos_obj_new.tpt_90;
                    end
                    % include position attribute values in portfolio currency
                    pos_obj_new = pos_obj_new.set('tpt_24',theo_value_pos);
                    pos_obj_new = pos_obj_new.set('tpt_26',theo_value_pos);
                    % clean market value in portfolio currency
                    theo_value_pos_clean = pos_obj_new.tpt_23 ./ tmp_fx_rate;
                    pos_obj_new = pos_obj_new.set('tpt_25',theo_value_pos_clean);
                    % accrued interest
                    accr_int_pos = pos_obj_new.tpt_125 ./ tmp_fx_rate;
                    accr_int = accr_int + accr_int_pos;
                    % exposure in portfolio currency
                    theo_exp_pos = pos_obj_new.tpt_27 ./ tmp_fx_rate;
                    theo_exposure = theo_exposure + theo_exp_pos;
                    pos_obj_new = pos_obj_new.set('tpt_28',theo_exp_pos);
                    pos_obj_new = pos_obj_new.set('tpt_30',theo_exp_pos);
                elseif (strcmpi(scen_set,'stress'))    
                    % convert SCR contributions to portfolio currency
                    scr_ir_up   = pos_obj_new.tpt_97 ./ tmp_fx_rate_base;
                    scr_ir_down = pos_obj_new.tpt_98 ./ tmp_fx_rate_base;
                    pos_obj_new = pos_obj_new.set('tpt_97',scr_ir_up);
                    pos_obj_new = pos_obj_new.set('tpt_98',scr_ir_down);
                    % equity risk
                    scr_eq_down_type1 = pos_obj_new.tpt_99 ./ tmp_fx_rate_base;
                    scr_eq_down_type2 = pos_obj_new.tpt_100 ./ tmp_fx_rate_base;
                    pos_obj_new = pos_obj_new.set('tpt_99',scr_eq_down_type1);
                    pos_obj_new = pos_obj_new.set('tpt_100',scr_eq_down_type2);
                    % property risk
                    scr_prop_down = pos_obj_new.tpt_101 ./ tmp_fx_rate_base;
                    pos_obj_new = pos_obj_new.set('tpt_101',scr_prop_down);
                    % FX risk
                    PnL_stress = theo_value_pos - theo_value_pos_base;
                    if ( length(PnL_stress) >= 7)
                        pos_obj_new = pos_obj_new.set('tpt_105b',PnL_stress(7));
                        pos_obj_new = pos_obj_new.set('tpt_105a',PnL_stress(6));
                    end
                end
                % update cash position
                if (regexpi(pos_id,'CASH'))
                    cash_value = cash_value + theo_value_pos;
                end
                % store position object in portfolio object
                obj.positions(ii).object = pos_obj_new;
            end
        end
        % second loop via all positions to calculate valuation_weight = posvalue / NAV
        if (strcmpi(scen_set,'base'))
            for (ii=1:1:length(obj.positions))
                pos_obj = obj.positions(ii).object;
                pos_id = obj.positions(ii).id;
                if (isobject(pos_obj))
                    % Update valuation_weights and exposure weights
                    if ( theo_value != 0.0)
                        pos_obj.tpt_26 = 100 .* pos_obj.tpt_26 ./ theo_value;
                    end
                    if (theo_exp_pos != 0.0)
                        pos_obj.tpt_30 = 100 .* pos_obj.tpt_30 ./ theo_exposure;
                    end
                    % store position object in portfolio object
                    obj.positions(ii).object = pos_obj; 
                end
            end
         end
         % second loop via all positions to calculate valuation_weight = posvalue / NAV
        if (strcmpi(scen_set,'stress'))
            for (ii=1:1:length(obj.positions))
                pos_obj = obj.positions(ii).object;
                pos_id = obj.positions(ii).id;
                if (isobject(pos_obj))
                    if ( obj.value_base != 0.0)
                        % Update SCR weights
                        pos_obj.tpt_97 =  pos_obj.tpt_97 ./ obj.value_base; % SCR IR up
                        pos_obj.tpt_98 =  pos_obj.tpt_98 ./ obj.value_base; % SCR IR down
                        pos_obj.tpt_99 =  pos_obj.tpt_99 ./ obj.value_base; % SCR EQ down type 1
                        pos_obj.tpt_100 =  pos_obj.tpt_100 ./ obj.value_base; % SCR EQ down type 2
                        pos_obj.tpt_101 =  pos_obj.tpt_101 ./ obj.value_base; % SCR Prop down
                        pos_obj.tpt_105a =  pos_obj.tpt_105a ./ obj.value_base; % SCR FX up
                        pos_obj.tpt_105b =  pos_obj.tpt_105b ./ obj.value_base; % SCR FX down
                    end
                    % store position object in portfolio object
                    obj.positions(ii).object = pos_obj; 
                end
            end
         end
        
    elseif ( strcmpi(obj.type,'POSITION'))
        tmp_id = obj.id;
        tmp_quantity = obj.quantity;
        try
            [tmp_instr_object object_ret_code]  = get_sub_object(instrument_struct, tmp_id);
            if ( object_ret_code == 0 )
                error('octarisk: WARNING: No instrument_struct object found for id >>%s<<\n',tmp_id);
            end 
            % get instrument value / exposure
            tmp_exposure = tmp_instr_object.get('exposure_base');;
            tmp_value = tmp_instr_object.getValue('base');
            tmp_currency = tmp_instr_object.get('currency'); 
            tmp_value_clean = tmp_value; 
            accr_interest = 0.0;
            if ( tmp_instr_object.isProp('accrued_interest'))
                accr_interest = tmp_instr_object.accrued_interest;
                tmp_value_clean = tmp_value_clean - accr_interest;
            end            

            % Get FX rate:
            if ( strcmp(obj.currency,tmp_currency) == 1 )
                tmp_fx_value_shock   = 1;
                tmp_fx_rate_base = 1;
            else
                tmp_fx_index        = strcat('FX_', obj.currency, tmp_currency);
                [tmp_fx_struct_obj object_ret_code]  = get_sub_object(index_struct, tmp_fx_index);
                if ( object_ret_code == 0 )
                    error('WARNING: No index_struct object found for FX id >>%s<<\n',tmp_fx_index);
                end 
                tmp_fx_rate_base    = tmp_fx_struct_obj.getValue('base');
                tmp_fx_value_shock  = tmp_fx_struct_obj.getValue(scen_set);   
            end
            
            % Fill base and scenario values
            if (strcmpi(scen_set,'base'))       
                theo_value = tmp_value .* tmp_quantity ./ tmp_fx_rate_base;
                theo_exposure = tmp_exposure .* tmp_quantity ./ tmp_fx_rate_base;
                theo_value_clean = tmp_value_clean .* tmp_quantity ./ tmp_fx_rate_base;
                accr_interest = accr_interest .* tmp_quantity ./ tmp_fx_rate_base;
            elseif (strcmpi(scen_set,'stress'))  % Stress scenario set
                % Store new Values in Position's struct
                theo_value  = tmp_instr_object.getValue(scen_set) ... 
                                        .*  tmp_quantity ./ tmp_fx_value_shock;
            else    % MC scenario set
                % Store new MC Values in Position's struct
                theo_value   = tmp_instr_object.getValue(scen_set) ...
                                        .* tmp_quantity ./ tmp_fx_value_shock; % convert position PnL into fund currency
            end
            
            % Fill Tripartite template TODO: fill further attributes
            if (strcmpi(scen_set,'base')) 
                % Mod. Duration
                if (tmp_instr_object.isProp('mod_duration'))
                    obj.tpt_90 = tmp_instr_object.get('mod_duration');
                elseif (tmp_instr_object.isProp('duration'))
                    obj.tpt_90 = tmp_instr_object.get('duration');
                end
                % coupon rate
                if (tmp_instr_object.isProp('coupon_rate'))
                    obj.tpt_33 = tmp_instr_object.get('coupon_rate');
                end
                 % currency
                if (tmp_instr_object.isProp('currency'))
                    obj.tpt_21 = tmp_instr_object.get('currency');
                end
                 % reference_curve
                if (tmp_instr_object.isProp('reference_curve'))
                    obj.tpt_36 = tmp_instr_object.get('reference_curve');
                end
                 % nominal amount
                if (tmp_instr_object.isProp('notional'))
                    obj.tpt_19 = tmp_instr_object.get('notional') * obj.quantity;
                end
                % Maturity Date
                if (tmp_instr_object.isProp('maturity_date'))
                    obj.tpt_39 = tmp_instr_object.get('maturity_date');
                end
                % Derivatives: Delta
                if (tmp_instr_object.isProp('theo_delta'))
                    obj.tpt_93 = tmp_instr_object.get('theo_delta');
                end
                % Bonds: Convexity or Derivatives: Gamma
                if (tmp_instr_object.isProp('theo_gamma'))
                    obj.tpt_94 = tmp_instr_object.get('theo_gamma');
                end
                if (tmp_instr_object.isProp('convexity'))
                    obj.tpt_94 = tmp_instr_object.get('convexity');
                end
                % Forward: value of underlying asset
                if (tmp_instr_object.isProp('underlying_price_base'))
                    obj.tpt_29 = tmp_instr_object.get('underlying_price_base');
                end
                % Compounding Frequency
                if (tmp_instr_object.isProp('compounding_freq'))
                    comp_freq = tmp_instr_object.get('compounding_freq');
                    obj.tpt_38 = get_compfreq(comp_freq);
                end
                
                % Forward / Futures strike_price
                if (tmp_instr_object.isProp('strike_price'))
                    obj.tpt_45  = tmp_instr_object.strike_price;
                    obj.tpt_61  = tmp_instr_object.strike_price;
                end 
                
                % Swaption effective date
                if (tmp_instr_object.isProp('effective_date'))
                    obj.tpt_63  = tmp_instr_object.effective_date;
                end
                % Option excersise type
                if (strcmpi(tmp_instr_object.type,'option'))
                    % set option type
                    sub_type = tmp_instr_object.sub_type;
                     if ( regexpi(sub_type,'_EUR_'))        % European (plain vanilla) option
                        obj.tpt_64 = 'EU';
                     elseif ( regexpi(sub_type,'_AM_'))     % American (plain vanilla) option
                        obj.tpt_64 = 'AM';
                     elseif ( regexpi(sub_type,'_BAR_'))    % (European) Barrier option
                        obj.tpt_64 = 'EU';
                     elseif ( regexpi(sub_type,'_ASN_'))    % (European) Asian option
                        obj.tpt_64 = 'AS';
                     elseif ( regexpi(sub_type,'_LBK_'))    % (European) Lookback option
                        obj.tpt_64 = 'EU';
                     elseif ( regexpi(sub_type,'_BIN_'))    % (European) Binary option
                        obj.tpt_64 = 'EU';
                     end
                end
         
                % Call Put Cap Floor
                if (strcmpi(tmp_instr_object.type,'capfloor'))
                    if (tmp_instr_object.CapFlag)
                        obj.tpt_42 = 'Cap';
                        obj.tpt_60 = 'Cap';
                    else
                        obj.tpt_42 = 'Flr';
                        obj.tpt_60 = 'Flr';
                    end
                    % strike price
                    obj.tpt_45  = tmp_instr_object.strike;
                    obj.tpt_61  = tmp_instr_object.strike;
                end
                if (strcmpi(tmp_instr_object.type,'bond'))
                    if (tmp_instr_object.embedded_option_flag)
                        % TODO: what if both call and put schedule set?
                        if isobject(tmp_instr_object.call_schedule)
                            obj.tpt_42 = 'Call';
                            obj.tpt_60 = 'Call';
                            obj.tpt_43 = (tmp_instr_object.call_schedule.nodes(1) + ...
                                                    para_object.valuation_date);
                            obj.tpt_45  = tmp_instr_object.call_schedule.rates_base(1);
                            obj.tpt_61  = tmp_instr_object.call_schedule.rates_base(1);
                        elseif isobject(tmp_instr_object.put_schedule)
                            obj.tpt_42 = 'Put';
                            obj.tpt_60 = 'Put';
                            obj.tpt_43 = (tmp_instr_object.put_schedule.nodes(1) + ...
                                                    para_object.valuation_date);
                            obj.tpt_45  = tmp_instr_object.call_schedule.rates_base(1);
                            obj.tpt_61  = tmp_instr_object.call_schedule.rates_base(1);
                        end                        
                    end
                end
                
                % Derivatives: Vega
                if (tmp_instr_object.isProp('theo_vega'))
                    obj.tpt_94b = tmp_instr_object.get('theo_vega');
                end
                % Derivatives: multiplier
                if (tmp_instr_object.isProp('multiplier'))
                    obj.tpt_20 = tmp_instr_object.get('multiplier');
                end
                
                % Bond subtype (Fixed, Floater, Variable)
                if (strcmpi(tmp_instr_object.type,'bond'))
                    sub_type = tmp_instr_object.sub_type;
                    if (strcmpi(sub_type,'FRB') || strcmpi(sub_type,'FAB') ...
                            || strcmpi(sub_type,'SWAP_FIXED') 
                            || strcmpi(sub_type,'ZCB') || strcmpi(sub_type,'CDS_FIXED'))
                        obj.tpt_32 = 'Fixed';
                    elseif (strcmpi(sub_type,'FRN') || strcmpi(sub_type,'SWAP_FLOATING') ...
                            || strcmpi(sub_type,'CMS_FLOATING') || strcmpi(sub_type,'FRA') ...
                            || strcmpi(sub_type,'FVA') ...
                            || strcmpi(sub_type,'CDS_FLOATING'))
                        obj.tpt_32 = 'Floating';
                        obj.tpt_34 = tmp_instr_object.reference_curve;
                        obj.tpt_36 = tmp_instr_object.reference_curve;
                        obj.tpt_37 = tmp_instr_object.spread;
                    else
                        obj.tpt_32 = 'Variable';
                    end
                end
                
                % set properties of underlying asset
                if (strcmpi(tmp_instr_object.type,'bond') || strcmpi(tmp_instr_object.type,'forward'))
                    und_flag = false;
                    % CDS:
                    if (strcmpi(tmp_instr_object.sub_type,'CDS'))
                        und_id = tmp_instr_object.reference_asset; %ID of underlying
                        [undr_instr_object object_ret_code]  = get_sub_object(instrument_struct, und_id);
                        if ( object_ret_code == 0 )
                            error('WARNING: No instrument_struct object found for id >>%s<<\n',und_id);
                        end
                        und_flag = true;
                    % Bond Future/Forward
                    elseif ( sum(strcmpi(tmp_instr_object.sub_type,{'Bond','BONDFWD','BondFuture'})) > 0 )
                        und_id = tmp_instr_object.underlying_id; %ID of underlying
                        [undr_instr_object object_ret_code]  = get_sub_object(instrument_struct, und_id);
                        if ( object_ret_code == 0 )
                            error('WARNING: No instrument_struct object found for id >>%s<<\n',und_id);
                        end
                        und_flag = true;
                    end
                    if (und_flag)
                        % set underlying attributes
                        obj.tpt_67 = undr_instr_object.id;
                        obj.tpt_68 = 3;    % ID code [1,2,3]
                        obj.tpt_69 = 99;   % type of ID code (other)
                        obj.tpt_70 = undr_instr_object.name;
                        obj.tpt_71 = undr_instr_object.currency;
                        obj.tpt_72 = undr_instr_object.getValue('base');
                        obj.tpt_73 = '';    % country
                        obj.tpt_74 = '';    % economic area
                        obj.tpt_75 = undr_instr_object.coupon_rate;
                        comp_freq = undr_instr_object.get('compounding_freq');
                        obj.tpt_76 = get_compfreq(comp_freq);
                        obj.tpt_77 = undr_instr_object.maturity_date;  
                        obj.tpt_80 = '';    % issuer name 
                        obj.tpt_81 = '';    % issuer ID 
                        obj.tpt_82 = [];    % type of ID code (other)
                        obj.tpt_89 = get_cqs(undr_instr_object.credit_state);
                    end
                end
                % set properties of underlying asset for options
                if (strcmpi(tmp_instr_object.type,'option'))
                    % set underlying attributes
                    obj.tpt_67 = tmp_instr_object.underlying;
                    obj.tpt_68 = 3;    % ID code [1,2,3]
                    obj.tpt_69 = 99;   % type of ID code (other)
                end
                
            elseif (strcmpi(scen_set,'stress')) 
                theo_value_base  = tmp_instr_object.getValue('base') ... 
                                        .*  tmp_quantity ./ tmp_fx_value_shock;
                theo_value_stress  = tmp_instr_object.getValue('stress') ... 
                                        .*  tmp_quantity ./ tmp_fx_value_shock;
                PnL_stress = theo_value_stress - theo_value_base;
                % set properties for SCR contribution calculation
                if ( length(PnL_stress) > 3 )
                    % IR risk
                    scr_ir_up   = PnL_stress(2);
                    scr_ir_down = PnL_stress(3);
                    obj.tpt_97  = scr_ir_up;
                    obj.tpt_98  = scr_ir_down;
                    % equity risk
                    if (tmp_instr_object.isProp('sii_equity_type'))
                        eq_type = tmp_instr_object.('sii_equity_type');
                        if (eq_type == 1)
                            obj.tpt_99  = min(PnL_stress(4),0);
                            obj.tpt_100 = 0.0;
                        elseif (eq_type == 2)
                            obj.tpt_99 = 0.0;
                            obj.tpt_100  = min(PnL_stress(4),0);
                        end
                    else % no equity risk assumed
                        obj.tpt_99 = 0.0;
                        obj.tpt_100 = 0.0;
                    end
                    % Property risk
                    obj.tpt_101  = min(PnL_stress(5),0);
                end
            end   
        catch   % if instrument not found raise warning and populate cell
            fprintf('Instrument ID %s not found for position. There was an error: %s\n',tmp_id,lasterr);
        end
        
    else
        fprintf('Unknown type >>%s<<. Neither position nor portfolio\n',any2str(obj.type));
    end

    % store theo_value vector
    if ( regexp(scen_set,'stress'))
        obj = obj.set('value_stress',theo_value);
    elseif ( strcmp(scen_set,'base'))
        obj = obj.set('value_base',theo_value(1)); 
        obj = obj.set('valuation_date',para.valuation_date);
        obj = obj.set('reporting_date',para.reporting_date);
        if ( strcmpi(obj.type,'PORTFOLIO'))
            obj.tpt_5 = theo_value; 
            % save weighted average of pos mod duration
            obj.tpt_124 = port_mod_dur / theo_value; 
            obj.tpt_126 = accr_int; 
            % set cash ratio
            obj.tpt_9 = 100.0 * cash_value / theo_value;
        elseif ( strcmpi(obj.type,'POSITION'))
            obj.tpt_22 = theo_value; 
            obj.tpt_23 = theo_value_clean; 
            obj.tpt_27 = theo_exposure;
            obj.tpt_125 = accr_interest;
        end  
    else
        obj = obj.set('timestep_mc',scen_set);
        obj = obj.set('value_mc',theo_value);
    end
    
end

% Helper functions
function cqs = get_cqs(rating)
dict = struct(   ...
                'AAA',1, ...
                'AA',1, ...
                'A',2, ...
                'BBB',3, ...
                'BB',4, ...
                'B',52, ...
                'CCC',6, ...
                'CC',6, ...
                'C',6, ...
                'D',6, ...
                'UNRATED', 9 ...
            );
cqs = getfield(dict,upper(rating));

end

function comp_freq = get_compfreq(comp_freq)
    if ischar(comp_freq)
        if ( strcmpi(comp_freq,'daily') || strcmpi(comp_freq,'day'))
            comp_freq = 0;
        elseif ( strcmpi(comp_freq,'weekly') || strcmpi(comp_freq,'week'))
            comp_freq = 52;
        elseif ( strcmpi(comp_freq,'monthly') || strcmpi(comp_freq,'month'))
            comp_freq = 12;
        elseif ( strcmpi(comp_freq,'quarterly')  ||  strcmpi(comp_freq,'quarter'))
            comp_freq = 4;
        elseif ( strcmpi(comp_freq,'semi-annual'))
            comp_freq = 2;
        elseif ( strcmpi(comp_freq,'annual') )
            comp_freq = 1;       
        else
            comp_freq = 0;
        end
    end
    if (comp_freq == 365)
        comp_freq = 1;
    end
end