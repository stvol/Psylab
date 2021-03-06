function [x,y] = read_psydat(s_name, exp_name) 

% Usage: [x,y] = read_psydat(s_name, exp_name) 
% ----------------------------------------------------------------------
%     read (extract) those data from psydat_* file 
%        -- which is in new version 2 format -- 
%     that belong to the specified subject and experiment.  The
%     filename of the psydat-file is determined from the argument
%     s_name which is append to "psydat_".
%     Output data into structure x and, optionally, same data in
%     matrix format in y 
% 
%   input:   ---------
%          s_name   subject name (initial as found in data file)
%        exp_name   experiment name (as found in data file)
%
%  output:   ---------
%      x   struct variable containing all data belonging to s_name and exp_name
%      y   same data as x, but numeric data only, and in matrix format
%
% Copyright (C) 2006   Martin Hansen, FH OOW  
% Author :  Martin Hansen, Stephanus Volke <psylab AT jade-hs.de>
% Date   :  10 Sep 2003
% Updated:  <23 Okt 2006 00:10, hansen>
% Updated:  <14 Jan 2004 11:30, hansen>
% Updated:  <15 Jun 2015 23:40, volke>

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


file_name = ['psydat_' s_name];
[fid1,msg] = fopen(file_name,'r');
if ~strcmp(msg,''),
  fprintf('fopen on file % returned with message %s\n',file_name, msg);
  return
end

if mpsy_check_psydat_version(file_name) == 1,
  error('file "%s" is probably in psydat format version 1.  Try read_psydat_v1.m instead', file_name);
end



% count correct trials found in psydat file
trial = 0;
% count line number in psydat file
line_number = 0;

stop_flag = 0;

while 1,
  
  % get new line
  lin = fgets(fid1);  line_number = line_number+1;
  if lin == -1, break; end;  % we are now at EOF
  
  % split into space-separated words
  tok = mpsy_split_lines_to_toks(lin);

  % check whether we have a line starting a new block
  if length(tok) == 7 & strcmp(tok(5), 'npar'),
    % second item is experiment name
    ename = char(tok(2));
    % third item is subject name
    sname = char(tok(3));
    %%% fprintf('found entry with s_name= %s, experiment= %s\n', char(tok(3)), char(tok(2)) );
    
    if strcmp(tok(3), s_name),  % check for correct subject name
      if strcmp(tok(2), exp_name), % check for correct experiment name
        trial = trial+1;
	
	nparam = str2num(char(tok(6)));
	x.date(trial)    = tok(4);
	
	for k=1:nparam,
	  % get next line
	  lin = fgets(fid1);  line_number = line_number+1;
	  % split into space-separated words
	  tok = mpsy_split_lines_to_toks(lin);
	  
	  if length(tok) == 5 & strcmp(tok(2), sprintf('PAR%d:',k)),
	    x.par(k).name(trial)  = tok(3);
	    x.par(k).value(trial) = str2num(char(tok(4)));
	    x.par(k).unit(trial) = tok(5);
	  else
	    fclose(fid1);
	    error('sorry, psydat file garbled  in line %d at trial %d. Expecting a line for parameter #%d here.', line_number, trial, k);
	  end
	end % for all parameters
      
	% get next line in the file
	lin = fgets(fid1);   line_number = line_number+1;
    
	% split into space-separated words
	tok = mpsy_split_lines_to_toks(lin);
    
    if strcmp(tok(2), 'VAL:')
        x.plot(trial).vars = cell(tok(3:2:end));
        x.plot(trial).answers = cell(tok(4:2:end));
        
        % get next line in the file
        lin = fgets(fid1);   line_number = line_number+1;
    
        % split into space-separated words
        tok = mpsy_split_lines_to_toks(lin);
    else
       x.plot(trial).vars = [];
       x.plot(trial).answers = [];
    end
    
    
	if length(tok) == 6,
	  x.varname(trial)    = tok(1);
	  x.threshold(trial)  = str2num(char(tok(2)));  % the threshold itself
	  x.thres_sd(trial)   = str2num(char(tok(3)));  % its std. dev.
	  x.thres_min(trial)  = str2num(char(tok(4)));  % min. values during meas. phase
	  x.thres_max(trial)  = str2num(char(tok(5)));  % max. values during meas. phase
	  x.varunit(trial)    = tok(6);
	else
	  fclose(fid1);
	  error('sorry, psydat file garbled in line %d at trial %d. Expecting a line for the threshold data here.', line_number, trial, k);
	end
	
      end % if correct exp.name
    else
      fprintf('*** WARNING, found a different subject name (%s) for experiment %s.\n', s_name, exp_name);
      fprintf('             that line (trial after %d) is skipped\n', trial);
    end % if correct subject name
  end % if correct starting line
end
fclose(fid1);

if trial > 0,
  fprintf('*** info:  found %d matching entries in %s\n',trial,file_name);
else
  warning('*** I''m sorry, no appropriate entries found in file %s\n', file_name);
  x = []; y = [];
  return
end

non_unique = 0;
for k=2:length(x.varname),
  if ~ strcmp(x.varname(1),x.varname(k)),  non_unique=non_unique+1;  end 
  if ~ strcmp(x.varunit(1),x.varunit(k)),  non_unique=non_unique+2;  end 
  for l=1:nparam,
    if ~ strcmp(x.par(l).name(1), x.par(l).name(k)), non_unique=non_unique+2^(2*l-1); end 
    if ~ strcmp(x.par(l).unit(1), x.par(l).unit(k)), non_unique=non_unique+2^(2*l); end 
  end
  
  if non_unique,
    fprintf('***\n*** WARNING:  non-unique (id=%d) name or unit in y, at data set #%d\n***\n',...
	    non_unique, k);
    break
  end
end


% Set a second output variable y, containing same data as x, but skip
% all variables containings string data etc. und leave only numeric
% data, i.e. M.PARAM(:,:) and threshold data.  Arrange them in a
% matrix format
if nargout > 1,
  if non_unique == 0,
    y(:,1) = x.threshold' ;
    y(:,2) = x.thres_sd'  ;
    y(:,3) = x.thres_min' ;
    y(:,4) = x.thres_max' ;
    for k=1:nparam,
      y(:,4+k) = x.par(k).value' ;
    end

    fprintf('*** info:  meaning of the %d cols of y:\n', 4+nparam)
    fprintf('           threshold, thres_sd, thres_min, thres_max, par1')
    for k=2:nparam,   fprintf(', par%d', k);  end
    fprintf(' \n');

  else
    warning('2nd output argument set to zero because of non-unique name(s) or unit(s) in psydat file.');
    y = 0;
  end
end


 
  
% End of file:  read_psydat.m

% Local Variables:
% time-stamp-pattern: "40/Updated:  <%2d %3b %:y %02H:%02M, %u>"
% End:
