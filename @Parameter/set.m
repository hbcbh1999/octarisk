% setting attribute values
function obj = set(obj, varargin)
  % A) Specify fieldnames <-> types key/value pairs
  typestruct = struct(...
                'name', 'char' , ... 
                'id', 'char' , ...
                'description', 'char' , ...
                'type', 'char' , ...
                'path_working_folder', 'char' , ... 
                'folder_archive', 'char' , ... 
                'folder_input', 'char' , ... 
                'folder_static', 'char' , ... 
                'folder_mktdata', 'char' , ... 
                'folder_output', 'char' , ... 
                'folder_output_instruments', 'char' , ... 
                'folder_output_riskfactors', 'char' , ... 
                'folder_output_stresstests', 'char' , ... 
                'folder_output_positions', 'char' , ... 
                'folder_output_mktdata', 'char' , ... 
                'folder_output_reports', 'char' , ... 
                'path_reports', 'char' , ... 
                'path_archive', 'char' , ... 
                'path_input', 'char' , ... 
                'path_static', 'char' , ... 
                'path_mktdata', 'char' , ... 
                'input_filename_instruments', 'char' , ... 
                'input_filename_corr_matrix', 'char' , ... 
                'input_filename_stresstests', 'char' , ... 
                'input_filename_riskfactors', 'char' , ... 
                'input_filename_positions', 'char' , ... 
                'input_filename_mktdata', 'char' , ... ;
                'input_filename_seed', 'char' , ... 
                'input_filename_vola_index', 'char' , ... 
                'input_filename_vola_ir', 'char' , ... 
                'input_filename_surf_stoch', 'char' , ... 
                'input_filename_matrix', 'char' , ... 
                'plotting', 'boolean', ...
                'idx_figure', 'numeric', ...
                'saving', 'boolean', ...
                'archive_flag', 'boolean', ...
                'calc_marg_incr_var', 'boolean', ...
                'stable_seed', 'boolean', ...
                'mc_scen_analysis', 'boolean', ...
                'aggregation_flag', 'boolean', ...
                'calc_sm_scr', 'boolean', ...
                'first_eval', 'boolean', ...
                'use_sobol', 'boolean', ...
                'sobol_seed', 'numeric' , ...
                'mc', 'numeric' , ... 
                'quantile_estimator', 'char', ...
                'quantile_bandwidth', 'numeric', ...
                'quantile', 'numeric' , ... 
                'copulatype', 'char' , ... 
                'nu', 'numeric' , ... 
                'rnd_number_gen', 'char' , ... 
                'valuation_date', 'numeric' , ... 
                'base_currency', 'char' , ... 
                'aggregation_key', 'cell' , ... 
                'mc_timestep', 'char' , ... 
                'mc_timestep_days', 'numeric' , ... 
                'scenario_set', 'cell' , ... 
                'runcode', 'char' , ... 
                'no_stresstests', 'numeric', ...
                'frob_norm_limit', 'numeric', ...
                'scen_number', 'numeric', ...
                'filename_sobol_direction_number', 'char', ...
                'path_sobol_direction_number', 'char', ...
                'timestamp', 'char' 
               );
  % B) store values in object
  if (length (varargin) < 2 || rem (length (varargin), 2) ~= 0)
    error ('Parameter.set: expecting property/value pairs');
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
