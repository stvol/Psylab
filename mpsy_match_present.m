% Usage: y = mpsy_match_present
% ----------------------------------------------------------------------
%
%   input:   (none), works on global variables
%  output:   (none), presents signals in matching experiment
%                    fashion, collects and evaluates subjects answer
%
% Copyright (C) 2009         Martin Hansen, FH OOW  
% Author :  Martin Hansen <psylab AT jade-hs.de>
% Date   :  19 Mrz 2007
% Updated:  <19 Mar 2009 08:34, martin>

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



% mount signals together, depending on presentation mode MATCH_ORDER
[m_outsig, test_pos] = mpsy_match(m_test, m_ref, M.MATCH_ORDER, m_quiet, m_presig, m_postsig);

% ... check for clipping
if max(m_outsig) > 1 | min(m_outsig) < -1,
  mpsy_info(M.USE_GUI, afc_fb, '*** WARNING:  overload/clipping of m_outsig***')
  pause(2);
end

% check ear side, add silence on other side if necessary
if ( (M.EARSIDE~=M_BINAURAL) & (min(size(m_outsig)) == 1) ), 
  if M.EARSIDE == M_LEFTSIDE,
    m_outsig = [m_outsig 0*m_outsig];  % mute right side
  elseif M.EARSIDE == M_RIGHTSIDE,
    m_outsig = [0*m_outsig m_outsig];  % mute left side
  else 
    fprintf('\n\n*** ERROR, wrong value of M.EARSIDE.\n'); 
    fprintf('*** must be M_BINAURAL, M_LEFTSIDE or M_RIGHTSIDE\n');
    return
  end
end

% ... clear possible feedback message in GUI
mpsy_info(M.USE_GUI, afc_fb, '', afc_info, '');

% ... and present
if M.USE_MSOUND
  mpsy_msound_present;
else
  sound(m_outsig, M.FS); 

  % the visual indicator mechanism is not supported for matching experiment:
  if ispc,
    %  Matlab 'sound' works asynchronously on WIN PCs, so: 
    %  pause execution for as long as the signal duration
    pause(length(m_outsig)/M.FS);
  end
  
end
clear M.ACT_ANSWER;

% get user answer M.UD ("up-down")
M.UD = -1;
while ~any( M.UD == [ 1 2 8 9]),
  if M.USE_GUI,   %% ----- user answers via mouse/GUI
    set(afc_info, 'String', M.TASK);
    % a pause allows GUI-callbacks to be fetched.  The
    % mpsy_up_down_gui callbacks will set the variable M.UD
    pause(0.5);  
  else
    % prompt user for an answer via keyboard
    M.UD = input(M.TASK);
  end  
  if isempty(M.UD),  M.UD = -1;  end;
end

% M.UD contains user answer for up-down
switch M.UD,
  case 9,        % user-quit request for this experiment
    mpsy_info(M.USE_GUI, afc_fb, '*** user-quit of this experiment ***', afc_info, '');
    M.QUIT = 1;  % set quit-flag, i.e. whole experiment is aborted completely
    pause(2);
    return;      % abort this run, i.e. neither save anything

  case 8,        % user-quit request for this run
    mpsy_info(M.USE_GUI, afc_fb, '*** user-quit of this run ***', afc_info, '');
    pause(2);
    return;      %  abort this run, i.e. neither save anything:

  case 2,
    M.ACT_ANSWER = 0;  % which means:  go up
    feedback=''; 
    
  case 1,
    M.ACT_ANSWER = 1;  % which means:  go down 
    feedback='';
    
  otherwise
     warning('unsupported answer!  going down as a default safety measure');
     M.ACT_ANSWER = 1;  % which means:  go down 
     feedback='';
    
end


% End of file:  mpsy_match_present.m

% Local Variables:
% time-stamp-pattern: "40/Updated:  <%2d %3b %:y %02H:%02M, %u>"
% End:

