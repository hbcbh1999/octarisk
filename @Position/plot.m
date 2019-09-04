% @Position/plot: Plot figures
function obj = plot(obj, para_object,type,scen_set,stresstest_struct = [],curve_struct = [],riskfactor_struct = [])
  if (nargin < 4)   
		print_usage();
  end
  
 % get path
if ( strcmpi(para_object.path_working_folder,''))
	path_main = pwd;
else
	path_main = para_object.path_working_folder;
end
path_reports = strcat(path_main,'/', ...
			para_object.folder_output,'/',para_object.folder_output_reports);

% determine time step in days
if ( strcmpi(scen_set,'stress') || strcmpi(scen_set,'base'))
	tmp_ts = 0;
else
    if ( strcmpi(scen_set(end),'d') )
		tmp_ts = str2num(scen_set(1:end-1));  % get timestep days
	elseif ( strcmpi(scen_set(end),'y'))
		tmp_ts = 365 * str2num(scen_set(1:end-1));  % get timestep days
	else
		error('Unknown number of days in timestep: %s\n',scen_set);
	end
end

% get report_struct from Portfolio object
repstruct = obj.report_struct;

% set colors
or_green = [0.56863   0.81961   0.13333]; 
or_blue  = [0.085938   0.449219   0.761719]; 
or_orange =  [0.945312   0.398438   0.035156];
% --------------    Liquidity Plotting     -----------------------------
if (strcmpi(type,'liquidity'))    
  if ( strcmpi(scen_set,'base'))
		fprintf('plot: Plotting liquidity information for portfolio >>%s<< into folder: %s\n',obj.id,path_reports);	
		cf_dates = obj.get('cf_dates');
		cf_values = obj.getCF('base');
		xx=1:1:columns(cf_values);
		plot_desc = datestr(datenum(datestr(para_object.valuation_date)) + cf_dates,'mmm');
		hs = figure(1); 
		clf;
		bar(cf_values, 'facecolor', or_blue);
		h=get (gcf, 'currentaxes');
		set(h,'xtick',xx);
		set(h,'xticklabel',plot_desc);
		xlabel('Cash flow date');
		ylabel(strcat('Cash flow amount (in ',obj.currency,')'));
		title('Projected future cash flows','fontsize',12);
		% save plotting
		filename_plot_cf = strcat(path_reports,'/',obj.id,'_cf_plot.png');
		print (hs,filename_plot_cf, "-dpng", "-S600,200");
		filename_plot_cf = strcat(path_reports,'/',obj.id,'_cf_plot.pdf');
		print (hs,filename_plot_cf, "-dpdf", "-S600,200");
  elseif ~( strcmpi(scen_set,'base') || strcmpi(scen_set,'stress'))
		fprintf('plot: Plotting liquidity information for portfolio >>%s<< into folder: %s\n',obj.id,path_reports);	
		cf_dates = obj.get('cf_dates');
		cf_values_base = obj.getCF('base');
		cf_values_mc = obj.getCF(scen_set);
		% take only tail scenarios
		cf_values_mc = mean(cf_values_mc(obj.scenario_numbers,:),1);
		xx=1:1:columns(cf_values_base);
		plot_desc = datestr(datenum(datestr(para_object.valuation_date)) + cf_dates,'mmm');
		hs = figure(1); 
		clf;
		hb = bar([cf_values_base;cf_values_mc]');
		set (hb(1), "facecolor", or_blue);
		set (hb(2), "facecolor", or_orange);
		ha =get (gcf, 'currentaxes');
		set(ha,'xtick',xx);
		set(ha,'xticklabel',plot_desc);
		xlabel('Cash flow date','fontsize',11);
		ylabel(strcat('Cash flow amount (in ',obj.currency,')'),'fontsize',11);
		title('Projected future cash flows','fontsize',12);
		%legend('Base Scenario','Average Tail Scenario');
		% save plotting
		filename_plot_cf = strcat(path_reports,'/',obj.id,'_cf_plot_mc.png');
		print (hs,filename_plot_cf, "-dpng", "-S600,200");
		filename_plot_cf = strcat(path_reports,'/',obj.id,'_cf_plot_mc.pdf');
		print (hs,filename_plot_cf, "-dpdf", "-S600,200");
  else
	  fprintf('plot: No liquidity plotting possible for scenario set %s === \n',scen_set);  
  end  
% --------------    Risk Factor Shock Plotting   -----------------------------
elseif (strcmpi(type,'riskfactor'))    
  if ( strcmpi(scen_set,'stress') || strcmpi(scen_set,'base'))
	  fprintf('plot: Risk Factor Shock plots exists for scenario set >>%s<<\n',scen_set);
  else
	  fprintf('plot: Plotting Risk Factor Shock results for portfolio >>%s<< into folder: %s\n',obj.id,path_reports);	
	  if isstruct(riskfactor_struct)
	    abs_rf_shocks_mean = [];
	    rf_plot_desc = {};
		for kk=1:1:length(riskfactor_struct)
			rf_obj = riskfactor_struct(kk).object;
			if (isobject(rf_obj))
				abs_rf_shocks = rf_obj.getValue(scen_set,'abs') - rf_obj.getValue('base');
				abs_rf_shocks = abs_rf_shocks(obj.scenario_numbers,:);
				if ( sum(strcmpi(rf_obj.model,{'GBM','BKM','REL'})) > 0 ) % store relative shocks only
					abs_rf_shocks_mean = [abs_rf_shocks_mean, mean(abs_rf_shocks)];
					rf_plot_desc = [rf_plot_desc, rf_obj.description];
				end
			end
		end
		abs_rf_shocks_mean = 100 .* abs_rf_shocks_mean;
		% Plot risk factor shocks in meaningful way?!? Spider chart, bar chart?
		xx = 1:1:length(abs_rf_shocks_mean);
        hs = figure(1);
        clf;
        barh(abs_rf_shocks_mean(1:end), 'facecolor', or_blue);
        h=get (gcf, 'currentaxes');
        set(h,'ytick',xx);
        rf_plot_desc = strrep(rf_plot_desc,"RF_","");
        rf_plot_desc = strrep(rf_plot_desc,"_","-");
        set(h,'yticklabel',rf_plot_desc(1:end));
        xlabel('Risk factor shocks (in pct.)','fontsize',14);
        %title('Risk factor shocks in ATS scenarios','fontsize',14);
        grid on;
        % save plotting
        filename_plot_rf = strcat(path_reports,'/',obj.id,'_rf_plot.png');
        print (hs,filename_plot_rf, "-dpng", "-S600,250");
        filename_plot_rf = strcat(path_reports,'/',obj.id,'_rf_plot.pdf');
        print (hs,filename_plot_rf, "-dpdf", "-S600,250");
        
        % ----------------------------------------------------------------------
        % plot RF vs quantile smoothing average
        % Idea: sort all risk factor shocks by portfolio PnL, splinefit for
        % smoothing and plotting of most relevant risk factors
        tmp_rf_shocks = rf_obj.getValue(scen_set,'abs') - rf_obj.getValue('base');
        [sortPnL sortedscennumbers] = sort(obj.getValue(scen_set) - obj.getValue('base'));
        
        spline_struct = struct();
        spline_struct(1).pp = 'dummy';
        len_tail = 0.2*para_object.mc;
        xx=1:1:len_tail;
        rf_cell = {'RF_EQ_EU','RF_EQ_NA','RF_IR_EUR_5Y','RF_IR_USD_5Y','RF_COM_GOLD','RF_ALT_BTC','RF_RE_DM'};
        for kk=1:1:length(rf_cell)
			[rf_obj retcode]= get_sub_object(riskfactor_struct,rf_cell{kk});
			if (retcode == 1)
				if ( sum(strcmpi(rf_obj.model,{'GBM','BKM','REL'})) > 0 ) % store relative shocks only
					tmp_rf_shocks = rf_obj.getValue(scen_set,'abs') - rf_obj.getValue('base');
					tmp_rf_shocks = tmp_rf_shocks(sortedscennumbers,:);
					tmp_rf_shocks = tmp_rf_shocks(1:len_tail,:);
					pp = splinefit (xx', tmp_rf_shocks, 6, "order", 2);
					spline_struct( length(spline_struct) + 1).pp = pp;
					spline_struct( length(spline_struct)).id = strrep(rf_obj.description,'_','');
					spline_struct( length(spline_struct)).distr = tmp_rf_shocks;
				else % BM model scale by 100
					tmp_rf_shocks = 100*(rf_obj.getValue(scen_set,'abs') - rf_obj.getValue('base'));
					tmp_rf_shocks = tmp_rf_shocks(sortedscennumbers,:);
					tmp_rf_shocks = tmp_rf_shocks(1:len_tail,:);
					pp = splinefit (xx', tmp_rf_shocks, 6, "order", 2);
					spline_struct( length(spline_struct) + 1).pp = pp;
					spline_struct( length(spline_struct)).id = strrep(rf_obj.description,'_','');
					spline_struct( length(spline_struct)).distr = tmp_rf_shocks;
				end
			end
		end
		% Plot
		hq = figure(1);
		clf;
		id_cell = {};
		for jj=2:1:length(spline_struct)
			pp = spline_struct(jj).pp;
			%~ distr = spline_struct(jj).distr .* 100;
			id_cell(jj) = spline_struct(jj).id;
			y = ppval (pp, xx') .* 100;
			plot(xx,y,'linewidth',1.2);
			hold on;
			%~ plot(xx,distr,'.');
			%~ hold on;
		end
		hold off;
		ha =get (gcf, 'currentaxes');
		quantile_999 = 0.001 * para_object.mc;
		quantile_95 = 0.05 * para_object.mc;
		quantile_90 = 0.1 * para_object.mc;
		quantile_84 = para_object.mc - normcdf(1)*para_object.mc;
		set(ha,'xtick',[quantile_999 quantile_95 quantile_90 quantile_84 ]);
		set(ha,'xticklabel',{'99.9%','95%','90%','84.1%'});
		xlabel('Quantile','fontsize',14);
		ylabel('Risk Factor Shock (in Pct.)','fontsize',14);
		%title('Risk Factor tail dependency','fontsize',14);
		legend(cellstr(id_cell)(2:end),'fontsize',14,'location','southeast');
		grid on;
		% save plotting
        filename_plot_rf_quantile = strcat(path_reports,'/',obj.id,'_rf_quantile_plot.png');
        print (hq,filename_plot_rf_quantile, "-dpng", "-S1000,400")
        filename_plot_rf_quantile = strcat(path_reports,'/',obj.id,'_rf_quantile_plot.pdf');
        print (hq,filename_plot_rf_quantile, "-dpdf", "-S1000,400")
		% ----------------------------------------------------------------------
      end
  end	      					
% --------------    VaR History Plotting   -----------------------------
elseif (strcmpi(type,'history'))    
  if ( strcmpi(scen_set,'stress') || strcmpi(scen_set,'base'))
	  fprintf('plot: No history VaR plots exists for scenario set >>%s<<\n',scen_set);
  else
	  fprintf('plot: Plotting VaR history results for portfolio >>%s<< into folder: %s\n',obj.id,path_reports);	
	  hist_bv = [obj.hist_base_values,obj.getValue('base')];
	  hist_var = [obj.hist_var_abs,obj.varhd_abs];
	  hist_dates = [obj.hist_report_dates,datestr(para_object.valuation_date)];
	  if (length(hist_bv)>0 && length(hist_bv) == length(hist_var) ...
						&& length(hist_dates) == length(hist_var) ...
						&& length(hist_bv) == length(hist_dates))  	
		
		hvar = figure(1);
		clf;
		xx=1:1:length(hist_bv);
		hist_var_rel = 100 .* hist_var ./ hist_bv;
		% TODO: limit plotting in figure
		upper_warning 	= ones(1,length(hist_bv)) .* hist_var_rel(end) .* 1.02;
		upper_limit 	= ones(1,length(hist_bv)) .* max(hist_var_rel) .* 1.02;
		lower_warning 	= ones(1,length(hist_bv)) .* hist_var_rel(end) .* 0.98;
		lower_limit 	= ones(1,length(hist_bv)) .* min(hist_var_rel) .* 0.98;
		
		[ax h1 h2] = plotyy (xx,hist_bv, xx,hist_var_rel, @plot, @plot);
        xlabel(ax(1),'Reporting Date','fontsize',12);
        set(ax(1),'visible','on');
 		set(ax(2),'visible','on');
        set(ax(1),'layer','top');
        set(ax(1),'xtick',xx);
        set(ax(1),'xlim',[0.8, length(xx)+0.2]);
        set(ax(1),'ylim',[0.98*min(hist_bv), 1.02*max(hist_bv)]);
		set(ax(1),'xticklabel',hist_dates);
		set(ax(2),'layer','top');
		set(ax(2),'xtick',xx);
		set(ax(2),'xlim',[0.8, length(xx)+0.2]);
		set(ax(2),'ylim',[floor(0.97*min(hist_var_rel)), ceil(1.03*max(hist_var_rel))]);
		set(ax(2),'xticklabel',{});
		set (h1,'linewidth',1);
		set (h1,'color',or_blue);
		set (h1,'marker','o');
		set (h1,'markerfacecolor',or_blue);
		set (h1,'markeredgecolor',or_blue);
		set (h2,'linewidth',1);
		set (h2,'color',or_orange);
		set (h2,'marker','o');
		set (h2,'markerfacecolor',or_orange);
		set (h2,'markeredgecolor',or_orange);
		ylabel (ax(1), strcat('Base Value (',obj.currency,')'),'fontsize',12);
		ylabel (ax(2), strcat('VaR relative (in Pct)'),'fontsize',12);
		% save plotting
		filename_plot_varhist = strcat(path_reports,'/',obj.id,'_var_history.png');
		print (hvar,filename_plot_varhist, "-dpng", "-S600,260");	
		filename_plot_varhist = strcat(path_reports,'/',obj.id,'_var_history.pdf');
		print (hvar,filename_plot_varhist, "-dpdf", "-S600,260");		
      else
		fprintf('plot: Plotting VaR history not possible for portfolio >>%s<<, attributes are either not filled or not identical in length\n',obj.id);	
      end	
  end


% -------------    Stress test plotting    ----------------------------- 
elseif (strcmpi(type,'stress'))
  if ~( strcmpi(scen_set,'stress'))
	  fprintf('plot: No stress report exists for scenario set >>%s<<\n',scen_set);
  else
    if (length(stresstest_struct)>0 && nargin == 5)
		fprintf('plot: Plotting stress results for portfolio >>%s<< into folder: %s\n',obj.id,path_reports);
		% prepare stresstest plotting and report output
		stresstest_plot_desc = {stresstest_struct.name};
		p_l_relativ_stress      = 100.*(obj.getValue('stress') - ...
						obj.getValue('base') )./ obj.getValue('base');

        xx = 1:1:length(p_l_relativ_stress)-1;
        hs = figure(1);
        clf;
        barh(p_l_relativ_stress(2:end), 'facecolor', or_blue);
        h=get (gcf, 'currentaxes');
        set(h,'ytick',xx);
        stresstest_plot_desc = strrep(stresstest_plot_desc,"_","");
        set(h,'yticklabel',stresstest_plot_desc(2:end));
        xlabel('Relative PnL (in Pct)','fontsize',14);
        title('Stresstest Results','fontsize',14);
        grid on;
        % save plotting
        filename_plot_stress = strcat(path_reports,'/',obj.id,'_stress_plot.png');
        print (hs,filename_plot_stress, "-dpng", "-S600,300");
        filename_plot_stress = strcat(path_reports,'/',obj.id,'_stress_plot.pdf');
        print (hs,filename_plot_stress, "-dpdf", "-S600,300");
    end % end inner if condition nargin
  end % end stress scen_set condition

 

% -------------    SRRI plotting    ----------------------------- 
elseif (strcmpi(type,'srri'))
  if ( strcmpi(scen_set,'stress') || strcmpi(scen_set,'base'))
	  fprintf('plot: No SRRI plots exists for scenario set >>%s<<\n',scen_set);
  else
      [ret idx_figure] = get_srri(obj.varhd_rel,tmp_ts,para_object.quantile, ...
					path_reports,obj.id,1,obj.getValue('base'),obj.srri_target); 
	  fprintf('plot: Plotting SRRI results for portfolio >>%s<< into folder: %s\n',obj.id,path_reports);						
  end
 
 
% -------------    VaR plotting    ----------------------------- 
elseif (strcmpi(type,'var'))
  if ( strcmpi(scen_set,'stress') || strcmpi(scen_set,'base'))
	  fprintf('plot: No VaR plots exists for scenario set >>%s<<\n',scen_set);
  else
	  printf('plot: Plotting VaR results for portfolio >>%s<< into folder: %s\n',obj.id,path_reports);
	  % required input
	  mc = para_object.mc;
	  mc_var_shock = obj.varhd_abs;
	  mc_var_shock_pct = obj.varhd_rel;
	  p_l_absolut_shock = obj.getValue(scen_set);
	  endstaende_reldiff_shock = obj.getValue(scen_set) ./ obj.getValue('base') -1;
	  fund_currency = obj.currency; 	
      plot_vec = 1:1:mc;
      portfolio_shock = obj.getValue(scen_set) - obj.getValue('base');
	  [p_l_absolut_shock scen_order_shock] = sort(portfolio_shock);  
  
      % Plot 1: Histogram and sorted PnL distribution
      hf1 = figure(1);
      clf;
      subplot (1, 2, 1)
        hist(endstaende_reldiff_shock.*100,40,'facecolor',or_blue);
        %title_string = {'Histogram'; strcat('Portfolio PnL ',scen_set);};
        %title (title_string,'fontsize',12);
        xlabel('Relative shock to portfolio (in Pct)');
      subplot (1, 2, 2)
		plot ( [1, mc], [0, 0], 'color',[0.3 0.3 0.3],'linewidth',1);
		hold on;
        plot ( plot_vec, p_l_absolut_shock,'linewidth',2, 'color',or_blue);
        hold on;
        plot ( [1, mc], [-mc_var_shock, -mc_var_shock], '-','linewidth',1, 'color',or_orange);
        h=get (gcf, 'currentaxes');
        xlabel('MonteCarlo Scenarios');
        set(h,'xtick',[1 mc]);
        set(h,'ytick',[round(min(p_l_absolut_shock)) round(-mc_var_shock/2) 0 ...
							round(mc_var_shock/2) round(max(p_l_absolut_shock))]);
        h=text(0.025*mc,(-0.75*mc_var_shock),num2str(round(-mc_var_shock)));   %add MC Value
        h=text(0.025*mc,(-1.3*mc_var_shock),strcat(num2str(round(mc_var_shock_pct*1000)/10),' %'));   %add MC Value
        ylabel(strcat('Absolute PnL (in ',fund_currency,')'));
        %title_string = {'Sorted PnL';strcat('Portfolio PnL ',scen_set);};
        %title (title_string,'fontsize',12);
        %axis ([1 mc -1.3*mc_var_shock 1.3*mc_var_shock]);
	  % save plotting
	  filename_plot_var = strcat(path_reports,'/',obj.id,'_var_plot.png');
	  print (hf1,filename_plot_var, "-dpng", "-S600,150");
	  filename_plot_var = strcat(path_reports,'/',obj.id,'_var_plot.pdf');
	  print (hf1,filename_plot_var, "-dpdf", "-S600,150");

		% Plot 2: position contributions
	    mc_var_shock = obj.varhd_abs;
	    fund_currency = obj.currency; 	
		pie_chart_values_pos_shock = [];
		pie_chart_values_pos_base = [];
		pie_chart_desc_pos_shock = {};
		pie_chart_desc_pos_base = {};
		% loop through all positions
		for (ii=1:1:length(obj.positions))
			try
			  pos_obj = obj.positions(ii).object;
			  if (isobject(pos_obj))
					pie_chart_values_pos_shock(ii) = (pos_obj.decomp_varhd) ;
					pie_chart_values_pos_base(ii) = pos_obj.getValue('base') ;
					pie_chart_desc_pos_shock(ii) = cellstr( strcat(pos_obj.id));
					pie_chart_desc_pos_base(ii) = cellstr( strcat(pos_obj.id));
			  end
			catch
				printf('Portfolio.print_report: there was an error for position id>>%s<<: %s\n',pos_obj.id,lasterr);
			end
		end
		% prepare vector for piechart:
		[pie_chart_values_sorted_pos_shock sorted_numbers_pos_shock ] = sort(pie_chart_values_pos_shock,'descend');
		[pie_chart_values_sorted_pos_base sorted_numbers_pos_base ] = sort(pie_chart_values_pos_base,'descend');
		
		% plot Top 5 Positions Decomp
		idx = 1; 
		max_positions = 5;
		for ii = 1:1:min(length(pie_chart_values_pos_shock),max_positions);
			pie_chart_values_plot_pos_shock(idx)     = pie_chart_values_sorted_pos_shock(ii) ;
			pie_chart_desc_plot_pos_shock(idx)       = pie_chart_desc_pos_shock(sorted_numbers_pos_shock(ii));
			idx = idx + 1;
		end
		% append remaining part
		if (idx == (max_positions + 1))
			pie_chart_values_plot_pos_shock(idx)     = mc_var_shock - sum(pie_chart_values_plot_pos_shock) ;
			pie_chart_desc_plot_pos_shock(idx)       = "Other";
		end
		pie_chart_values_plot_pos_shock = pie_chart_values_plot_pos_shock ./ sum(pie_chart_values_plot_pos_shock);
		
		% plot Top 5 Positions Basevalue
		idx = 1; 
		max_positions = 5;
		for ii = 1:1:min(length(pie_chart_values_pos_base),max_positions);
			pie_chart_values_plot_pos_base(idx)     = pie_chart_values_sorted_pos_base(ii) ;
			pie_chart_desc_plot_pos_base(idx)       = pie_chart_desc_pos_base(sorted_numbers_pos_base(ii));
			idx = idx + 1;
		end
		% append remaining part
		if (idx == (max_positions + 1))
			pie_chart_values_plot_pos_base(idx)     = obj.getValue('base') - sum(pie_chart_values_plot_pos_base) ;
			pie_chart_desc_plot_pos_base(idx)       = "Other";
		end
		
		pie_chart_values_plot_pos_base = pie_chart_values_plot_pos_base ./ sum(pie_chart_values_plot_pos_base);
		pie_chart_values_plot_pos_shock = pie_chart_values_plot_pos_shock ./ sum(pie_chart_values_plot_pos_shock);
		plot_vec_pie = zeros(1,length(pie_chart_values_plot_pos_shock));
		plot_vec_pie(1) = 1; 
		
		hf2 = figure(2);
		clf; 
		% Position Basevalue contribution
		subplot (1, 2, 1) 
		desc_cell_pos = strrep(pie_chart_desc_plot_pos_base,"_",""); %remove "_"
		pie(pie_chart_values_plot_pos_base, desc_cell_pos, plot_vec_pie);
		%title_string = strcat('Position contribution to Portfolio Basevalue');
		%title(title_string,'fontsize',12);
		axis ('tic', 'off');   
		
		% Position VaR Contribution
		subplot (1, 2, 2) 
		desc_cell_pos = strrep(pie_chart_desc_plot_pos_shock,"_",""); %remove "_"
		pie(pie_chart_values_plot_pos_shock, desc_cell_pos, plot_vec_pie);
		%title_string = strcat('Position contribution to Portfolio VaR');
		%title(title_string,'fontsize',12);
		axis ('tic', 'off');   
		% save plotting
		filename_plot_var_pos_instr = strcat(path_reports,'/',obj.id,'_var_pos_instr.png');
		print (hf2,filename_plot_var_pos_instr, "-dpng", "-S700,200");
		filename_plot_var_pos_instr = strcat(path_reports,'/',obj.id,'_var_pos_instr.pdf');
		print (hf2,filename_plot_var_pos_instr, "-dpdf", "-S700,200");
  end  
      
% -------------    Market Data Curve plotting    ----------------------------- 
elseif (strcmpi(type,'marketdata'))
  if ( strcmpi(scen_set,'stress') || strcmpi(scen_set,'base'))
	fprintf('plot: No mktdata plots exists for scenario set >>%s<<\n',scen_set);
  else
    fprintf('plot: Plotting Market Data results for portfolio >>%s<< into folder: %s\n',obj.id,path_reports);		
    hmarket = figure(1);
    clf;
    % get mktdata curves
    ats_scen = round(length(obj.scenario_numbers)/2);
    if isstruct(curve_struct)
      [curve_obj retcode] = get_sub_object(curve_struct,'IR_EUR');
      if retcode == 0
		 printf('plot: Warning: no curve object found for id  >>%s<<\n',obj.id);	
      else
		  subplot (2, 1, 1)
            nodes = any2str(curve_obj.get('nodes'));
			rates_base = curve_obj.get('rates_base');
			rates_mc = curve_obj.get('rates_mc');
			plot (curve_obj.get('nodes'),rates_base,'color',or_blue,"linewidth",1,'marker','x');
			hold on;
			plot (curve_obj.get('nodes'),rates_mc(obj.scenario_numbers(ats_scen-2),:),'color',or_orange,"linewidth",0.8);
			hold on;
			plot (curve_obj.get('nodes'),rates_mc(obj.scenario_numbers(ats_scen-1),:),'color',or_orange,"linewidth",0.8);
			hold on;
			plot (curve_obj.get('nodes'),rates_mc(obj.scenario_numbers(ats_scen+1),:),'color',or_orange,"linewidth",0.8);
			hold on;
			plot (curve_obj.get('nodes'),rates_mc(obj.scenario_numbers(ats_scen+2),:),'color',or_orange,"linewidth",0.8);
			hold off;
			grid off;
			title(sprintf ("Curve ID %s", strrep(curve_obj.id,'_','\_')), "fontsize",12);
			xlabel('Nodes (in days)', "fontsize",12);
			ylabel('Rates', "fontsize",12);
		    legend('Base Scenario Rates','VaR scenarios',"location","southeast");
      end
      [curve_obj retcode] = get_sub_object(curve_struct,'IR_USD');
      if retcode == 0
		 printf('plot: Warning: no curve object found for id  >>%s<<\n',obj.id);	
      else
		  subplot (2, 1, 2)
            nodes = any2str(curve_obj.get('nodes'));
			rates_base = curve_obj.get('rates_base');
			rates_mc = curve_obj.get('rates_mc');
			plot (curve_obj.get('nodes'),rates_base,'color',or_blue,"linewidth",1,'marker','x');
			hold on;
			plot (curve_obj.get('nodes'),rates_mc(obj.scenario_numbers(ats_scen-2),:),'color',or_orange,"linewidth",0.8);
			hold on;
			plot (curve_obj.get('nodes'),rates_mc(obj.scenario_numbers(ats_scen-1),:),'color',or_orange,"linewidth",0.8);
			hold on;
			plot (curve_obj.get('nodes'),rates_mc(obj.scenario_numbers(ats_scen+1),:),'color',or_orange,"linewidth",0.8);
			hold on;
			plot (curve_obj.get('nodes'),rates_mc(obj.scenario_numbers(ats_scen+2),:),'color',or_orange,"linewidth",0.8);
			hold off;
			grid off;
			title(sprintf ("Curve ID %s", strrep(curve_obj.id,'_','\_')), "fontsize",12);
			xlabel('Nodes (in days)', "fontsize",12);
			ylabel('Rates', "fontsize",12);
		    legend('Base Scenario Rates','VaR scenarios',"location","southeast");
      end
      % save plotting
      filename_mktdata_curves = strcat(path_reports,'/',obj.id,'_mktdata_curves.png');
      print (hmarket,filename_mktdata_curves, "-dpng", "-S800,500");
      filename_mktdata_curves = strcat(path_reports,'/',obj.id,'_mktdata_curves.pdf');
      print (hmarket,filename_mktdata_curves, "-dpdf", "-S800,500");
    end
  end      
% -------------------    else    ------------------------------------       
else
	fprintf('plot: Unknown type %s. Doing nothing.\n',type);
end 		

% update report_struct in object
obj = obj.set('report_struct',repstruct);						
end 
