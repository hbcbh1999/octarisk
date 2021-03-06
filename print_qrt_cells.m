%# Copyright (C) 2020 Stefan Schlögl <schinzilord@octarisk.com>
%#
%# This program is free software; you can redistribute it and/or modify it under
%# the terms of the GNU General Public License as published by the Free Software
%# Foundation; either version 3 of the License, or (at your option) any later
%# version.
%#
%# This program is distributed in the hope that it will be useful, but WITHOUT
%# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
%# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
%# details.
%#
%# You should have received a copy of the GNU General Public License along with
%# this program; if not, see <http://www.gnu.org/licenses/>.
 
%# -*- texinfo -*-
%# @deftypefn {Function File} {[@var{retcode} ] =} print_qrt_cells(@var{obj},@var{repstruct},@var{para},@var{filepathqrt})
%# Print QRT related attribute values to a file incl. Excel cell coordinates.
%# 
%# @end deftypefn

function [retcode repstruct] = print_qrt_cells(obj,repstruct,para,filepathqrt)

retcode = 1;
assets = repstruct.mvbs_assets;
assets_exp = repstruct.mvbs_asset_exposure;
liabs = repstruct.mvbs_liabilities;
liabs_exp = repstruct.mvbs_liab_exposure;
ownfunds = repstruct.mvbs_ownfunds;
ownfunds_exp = repstruct.mvbs_ownfunds_exposure;

general_struct = struct(   ...
				'B2','id', ...
				'B3','valuation_date', ...
				'B4','reporting_date', ...
				'B5','runcode', ...
				'D11','id', ...
				'D12','id', ...
				'D13','type_of_undertaking', ...
				'D14','country_authorization', ...
				'D15','language_reporting', ...
				'D16','reporting_date', ...
				'D17','financial_year_end', ...
				'D18','reporting_date', ...
				'D19','submission_type', ...
				'D20','currency', ...
				'D21','accounting_standards', ...
				'D22','scr_calculation_method'
				);
				

%~ Sheet	S.23.01.01.01 Own Funds				
%~ Total available own funds to meet the SCR	D41	risk_report	base_value		base_value
%~ Total eligible own funds to meet the SCR	D43	risk_report	base_value		base_value
%~ SCR	D45	risk_report	var_absolute		var_absolute
%~ Ratio of Eligible own funds to SCR	D47	risk_report	solvency_ratio		solvency_ratio

own_funds_struct = struct( ...
				'D41','value_base', ...
				'D43','value_base', ...
				'D45','varhd_abs_at', ...
				'D47','solvency_ratio'
				);

%~ Cellname	Cell				
%~ Sheet	S.25.03.01.02 SCR				
%~ Total undiversified components	C11	risk_report	var_positionsum		var_positionsum
%~ Diversification	C12	risk_report	diversification_amount		diversification_amount
%~ Solvency capital requirement excluding capital add-on	C14	risk_report	var_absolute		var_absolute
%~ Solvency capital requirement	C16	risk_report	var_absolute		var_absolute

scr_struct = struct( ...
				'C11','var_positionsum', ...
				'C12','diversification_amount', ...
				'C14','varhd_abs_at', ...
				'C15','capital_add_on', ...
				'C16','varhd_abs_at_addon'
				);


% ###################### S.02.01.02 struct  ####################################
assets_struct = struct( ...
				'B15','Intangible assets', ...
				'B16','Deferred tax assets', ...
				'B17','Pension benefit surplus', ...
				'B18','Property plant and equipment held for own use', ...
				'B19','Investments (other than assets held for index-linked and unit-linked contracts)', ...
				'B20','Property (other than for own use)', ...
				'B21','Holdings in related undertakings including participations', ...
				'B22','Equities', ...
				'B23','Equities - listed', ...
				'B24','Equities - unlisted', ...
				'B25','Bonds', ...
				'B26','Government Bonds', ...
				'B27','Corporate Bonds', ...
				'B28','Structured notes', ...
				'B29','Collateralised securities', ...
				'B30','Collective Investments Undertakings', ...
				'B31','Derivatives', ...
				'B32','Deposits other than cash equivalents', ...
				'B33','Other investments', ...
				'B34','Assets held for index-linked and unit-linked contracts',... 
				'B35','Loans and mortgages', ...
				'B36','Loans on policies', ...
				'B37','Loans and mortgages to individuals', ...
				'B38','Other loans and mortgages', ...
				'B39','Reinsurance recoverables from:', ...
				'B40','Non-life and health similar to non-life', ...
				'B41','Non-life excluding health', ...
				'B42','Health similar to non-life', ...
				'B43','Life and health similar to life, excluding health and index-linked and unit-linked', ...
				'B44','Health similar to life', ...
				'B45','Life excluding health and index-linked and unit-linked', ...
				'B46','Life index-linked and unit-linked', ...
				'B47','Deposits to cedants', ...
				'B48','Insurance and intermediaries receivables', ...
				'B49','Pension claims from government', ...
				'B50','Pension claims from insurance companies', ...
				'B51','Other insurance receivables', ...
				'B52','Reinsurance receivables', ...
				'B53','Receivables (trade not insurance)', ...
				'B54','Own shares (held directly)', ...
				'B55','Amounts due in respect of own fund items or initial fund called up but not yet paid in', ...
				'B56','Cash and cash equivalents', ...
				'B57','Physical commodities', ...
				'B58','Cryptocurrencies',...
				'B59','Any other assets', ...
				'B60','Total assets'
);

liabilities_struct = struct( ...
				'E13','Technical provisions - non-life', ...
				'E14','Technical provisions - non-life (excluding health)', ...
				'E15','Technical provisions - health (similar to non-life)', ...
				'E16','Technical provisions - life (excluding index-linked and unit-linked)', ...
				'E17','Technical provisions - health (similar to life)', ...
				'E18','Technical provisions - life (excluding health and index-linked and unit-linked)', ...
				'E19','Technical provisions - index-linked and unit-linked', ...
				'E20','Other technical provisions', ...
				'E21','Contingent liabilities', ...
				'E22','Provisions other than technical provisions', ...
				'E23','Pension benefit obligations', ...
				'E24','Deposits from reinsurers', ...
				'E25','Deferred tax liabilities', ...
				'E26','Derivatives', ...
				'E27','Debts owed to credit institutions', ...
				'E28','Financial liabilities other than debts owed to credit institutions', ...
				'E29','Insurance and intermediaries payables', ...
				'E30','Reinsurance payables', ...
				'E31','Payables (trade not insurance)', ...
				'E32','Subordinated liabilities', ...
				'E33','Subordinated liabilities not in Basic Own Funds', ...
				'E34','Subordinated liabilities in Basic Own Funds', ...
				'E35','Any other liabilities', ...
				'E36','Total liabilities'
);

mvbs_of_struct = struct( ...
				'E37','Own Funds before tax', ...
				'E38','Deferred tax',...
				'E39','Own Funds after tax'
);


print_to_file_from_obj(obj,para,general_struct,'S.01.02.01',filepathqrt,'w');
print_to_file_from_obj(obj,para,own_funds_struct,'S.23.01.01.01',filepathqrt,'a');
print_to_file_from_obj(obj,para,scr_struct,'S.25.03.01.02',filepathqrt,'a');
print_to_file_from_cell(assets,assets_exp,assets_struct,'S.02.01.02.01',filepathqrt,'a');
print_to_file_from_cell(liabs,liabs_exp,liabilities_struct,'S.02.01.02.01',filepathqrt,'a');
print_to_file_from_cell(ownfunds,ownfunds_exp,mvbs_of_struct,'S.02.01.02.01',filepathqrt,'a');


end


################################################################################
#		Helper functions
function print_to_file_from_cell(listcell,expvec,tmpstruct,sheet,filename,write_or_append)

	fqrt = fopen (filename, write_or_append);
	itemlist = fieldnames(tmpstruct);
	type = '';
	for ii=1:length(itemlist)
		tmp_field = itemlist{ii};
		objkey = getfield(tmpstruct,tmp_field);
		objval = [];
		% retrieve exposure from repstruct
		matchvec = strcmpi(listcell,objkey);
		[rr cc] = size(matchvec);
		if rr >= cc
			matchvec = matchvec';
		end
		idxvec = 1:1:numel(matchvec);
		
		if sum(matchvec) == 1
			idx = matchvec * idxvec';
			objval = expvec(idx);
			type = 'NMBR';
		else
			objval = 0.0;
			type = 'NMBR';
			%error('Cell has not field >>%s<<\n',objkey);
		end
		%printf('%s,%s,%1.2f,%s\n',tmp_field,objkey,objval,type);
		fprintf(fqrt, '%s,%s,%1.2f,%s\n',sheet,tmp_field,objval,type);
	end
	fclose (fqrt);

end

function print_to_file_from_obj(obj,para,tmpstruct,sheet,filename,write_or_append)

	fqrt = fopen (filename, write_or_append);
	itemlist = fieldnames(tmpstruct);
	type = '';
	for ii=1:length(itemlist)
		tmp_field = itemlist{ii};
		objkey = getfield(tmpstruct,tmp_field);
		objval = [];
		if obj.isProp(objkey)
			objval = obj.get(objkey);
		else
			if para.isProp(objkey)
				objval = para.get(objkey);
			else
				objval = [];
				error('Object %s has not field >>%s<<\n',obj.id,objkey);
			end
		end
		% set type
		if isnumeric(objval)
			type = 'NMBR';
		else
			type = 'CHAR';
		end
		% special case date
		if ~isempty(regexpi(objkey,'date'))
			type = 'DATE';
			objval = datestr(objval);
		end
		if strcmpi(type,'NMBR')
			%printf('%s,%s,%1.2f,%s\n',tmp_field,objkey,objval,type);
			fprintf(fqrt, '%s,%s,%1.2f,%s\n',sheet,tmp_field,objval,type);
		else
			%printf('%s,%s,%s,%s\n',tmp_field,objkey,any2str(objval),type);
			fprintf(fqrt, '%s,%s,%s,%s\n',sheet,tmp_field,any2str(objval),type);
		end
		
	end
	fclose (fqrt);

end

%~ para = struct();
%~ obj.portfolio_id = 'PRIVATE';
%~ para.type_of_undertaking = 'Private Portfolio';
%~ para.country_authorization = 'Germany';
%~ para.language_reporting = 'English';
%~ para.reporting_date = '01-May-2020';
%~ obj.valuation_date = '30-Apr-2020';
%~ para.runcode = '30-Apr-2020_1-May-2020_01';
%~ para.financial_year_end = '31-Dec';
%~ para.submission_type = 'Regular';
%~ obj.currency_code = 'EUR';
%~ para.accounting_standards = 'Custom';
%~ para.scr_calculation_method = 'Full Valuation Monte-Carlo';
%~ obj.id = 'Test';
%~ obj.base_value = 103000;
%~ obj.capital_add_on = 0;
%~ obj.varhd_abs_at = 25422;
%~ obj.varhd_abs_at_addon = 25422;
%~ obj.solvency_ratio = 3.89;
%~ obj.var_positionsum = 58745;
%~ obj.diversification_amount = 22222;

%~ repstruct.mvbs_assets = {'Investments (other than assets held for index-linked and unit-linked contracts)','Cryptocurrencies','Total assets'}
%~ repstruct.mvbs_assets_exposure = [666666,7895,672000];

%~ repstruct.mvbs_liabilities = {'Pension benefit obligations','Deferred tax liabilities','Total liabilities'}
%~ repstruct.mvbs_liabilities_exposure = [1000000,78954,1078954];

%~ repstruct.mvbs_ownfunds = {'Own Funds before tax','Deferred tax','Own Funds after tax'}
%~ repstruct.mvbs_ownfunds_exposure = [666666,78954,123123];
