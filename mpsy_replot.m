function h = mpsy_replot(filename, exp_name, run_idx)
% Usage: h = mpsy_replot(filename, exp_name, run_idx)
% ----------------------------------------------------------------------
%     to be called from mpsy_afc_main  or similar scripts
% 
%   input:   data
%  output:   handle of plot figure
%
% Copyright (C) 2003, 2004   Martin Hansen, FH OOW  
% Author :  Martin Hansen,  <psylab AT jade-hs.de>
% Date   :  27 Jun 2003
% Updated:  <14 Jan 2004 11:30, hansen>

%% This file is part of PSYLAB, a collection of scripts for
%% designing and controlling interactive psychoacoustical listening
%% experiments.  
%% This file is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published
%% by the Free Software Foundation; either version 2 of the License, 
%% or (at your option) any later version.  See the GNU General
%% Public License for more details:  http://www.gnu.org/licenses/gpl
%% This file is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.


x = read_psydat(filename, exp_name);
%x = x(run_idx);

if ~isfield(x, 'plot') || isempty(x.plot(run_idx).vars)
    fprintf('There is no progress data for this run.\n');
    return
end

figure(111);
idx_plus  = find(str2double(x.plot(run_idx).answers) ==1);  % correct answers
idx_minus = find(str2double(x.plot(run_idx).answers) ==0);  % wrong answers

% in case that threshold has not yet been reached, a preliminary
% plot is shown.  Otherwise the plot is Whether threshold has been
% reached, can be checked by the content of M.med_thres, which is
% only set via mpsy_proto
% if isempty(M.med_thres),
  % simple plot
  vars = str2double(x.plot(run_idx).vars);
  plot(1:length(vars), vars,'b.-', idx_plus, vars(idx_plus), 'r+', idx_minus, vars(idx_minus), 'ro');
% else
%   % a somewhat nicer plot.  
%   % Careful:  The field M.familiarization_fidx has been calculated by mpsy_proto.  
%   % The indices at transition between familiarization phase and measurement phase: 
%   idx_trans = [M.familiarization_fidx(end) M.measurement_fidx(1)]; %
%   hp = plot(M.measurement_fidx, M.VARS(M.measurement_fidx), 'k.-', ...
%             M.familiarization_fidx, M.VARS(M.familiarization_fidx), 'k.-', ...
%             idx_trans, M.VARS(idx_trans), 'k--', ...
%             idx_plus, M.VARS(idx_plus), 'r+', ...
%             idx_minus, M.VARS(idx_minus), 'ro');
%   set(hp([2 3]), 'Color', 0.5*[1 1 1]);
% end

xlabel('trial number')
yl = [ x.varname(run_idx) ' [' char(x.varunit(run_idx)) ']'];
ylabel(strrep(yl, '_','\_'));

tit = ['Exp.: ' exp_name ', Parameter: ' char(x.par(1).name(run_idx)) ' = ' num2str(x.par(1).value(run_idx)) ' ' char(x.par(1).unit(run_idx))];

for k=2:length(x.par),
  tit = [tit '  Par.' num2str(k) ': ' char(x.par(k).name(run_idx)) ' = ' num2str(x.par(k).value(run_idx)) ' ' char(x.par(k).unit(run_idx))];
end
title(strrep(tit,'_','\_'));

% add a legend with subject name and date
leg = sprintf('%s: %s',filename,char(x.date(run_idx)));
legend(strrep(leg, '_', '\_') ,0);

% and add text information about median and std.dev., 
% but only if run is finished, i.e. threshold is reached.  This can
% be checked via the variable M.med_thres that is set to a value
% only after a call to mpsy_proto 
  text(0.5*length(vars), 0.5*(x.thres_max(run_idx)+x.thres_min(run_idx)),sprintf('thresh:%g, std:%g', x.threshold(run_idx), x.thres_sd(run_idx)));


% End of file:  mpsy_plot_feedback.m

% Local Variables:
% time-stamp-pattern: "40/Updated:  <%2d %3b %:y %02H:%02M, %u>"
% End:
