function [xsel,seqpos] = mark_sequence( image_x, xsel, sequence, ...
					offset, primer_binding_site, ...
					area_pred );
% MARK_SEQUENCE - Tool for rapid manual assignment of bands in electropherograms.
%
%  [xsel] = mark_sequence( image_x, xsel, sequence, ...
%				 JUST_PLOT_SEQUENCE, offset, period, ...
%				 marks,mutpos, area_pred, peak_spacing, USE_GUI);
% Output:
%  xsel = positions of bands across all lanes.
%
% Input:
%  image_x  = matrix of aligned electrophoretic traces.
%  sequence = sequence of reverse-transcribed RNA. Must end at first residue before primer.
%  JUST_PLOT_SEQUENCE = interactive annotation [default: 1] or just plot previous band assignments? [0]. 
%  offset   = value that is added to sequence index to achieve 'historical'/favorite numbering.
%  period   = for labeling sequence, spacing between labels [default 1].
%  marks    = pairs of (index, residue) that indicate where bands should show up. [optional]
%                For example, might be [1 1; 1 4; 2 2;  99999 5]. The last pair has a 'fictional value'.
%  mutpos   = for marks, index for each lane. For example, might be NaN, 1, 2, 999999 [should specify this
%                 if you want marks to show up ]
%
% (C) R. Das, 2008-2011
% (Substantial) modification to script in SAFA (SemiAutomated Footprinting Analysis) software.
%
% It should be possible to dramatically accelerate this by not calling make_plot every time.
% We should get rid of the complicated business with marks/mutpos, and stick to area_pred!
% We should allow input of seqpos (perhaps deprecate 'period').
%
if ~exist('xsel');  xsel = []; end
if ~exist('offset');  offset = -999; end
if ~exist('period');  period = 1; end
if ~exist('marks');  marks = []; end
if ~exist('mutpos');  mutpos = []; end
if ~exist('area_pred'); area_pred = []; end
if ~exist('USE_GUI');  USE_GUI = 0; end

colormap( 1 - gray(100) );

ylim = get(gca,'ylim');
ymin = ylim(1);
ymax = ylim(2);
if ( ymin==0 & ymax==1)
  image( image_x );
  ylim = get(gca,'ylim');
  ymin = ylim(1);
  ymax = ylim(2);
end

contrast_factor = 40/ mean(mean(abs(image_x)));

%  Probably should just remove this... not clear if JUST_PLOT_SEQUENCE flag is needed anymore...
%if (JUST_PLOT_SEQUENCE )
%  if isstruct(USE_GUI); axes(USE_GUI.displayComponents); end;
%  make_plot( image_x, xsel, ymin, ymax, sequence, JUST_PLOT_SEQUENCE, ...
%	     contrast_factor, offset, period,marks,mutpos, area_pred);
%  return;
%end

numlanes = size(image_x,2);

stop_sel = 0;

% not clear if USE_GUI is needed anymore
%if isstruct(USE_GUI)
%  axes(USE_GUI.displayComponents);
%  make_plot( image_x, xsel, ymin, ymax, sequence, JUST_PLOT_SEQUENCE, ...
%	     contrast_factor, offset, period,marks,mutpos, area_pred);
%  uiwait( msgbox( 'Are you ready to interactively annotate the sequence?','Ready?','modal' ) )
%end

while ~stop_sel

  % not clear if USE_GUI is needed anymore
  %if isstruct(USE_GUI); axes(USE_GUI.displayComponents);; end;

  make_plot( image_x, contrast_factor, ymin, ymax, xsel, ...
	     sequence, offset, primer_binding_site, area_pred );
  
  title( ['j,l -- zoom. i,k -- up/down. q -- quit. left-click -- select. \newline',...
	  'x -- auto-assign. ',...
	  'middle button -- undo.', ' r -- reset.', ' t,b -- page up/down.', sprintf(' # of Annotation: %d / %d', length(xsel),length(sequence))]);
  
  [yselpick, xselpick, button ]  = ginput(1);

 
  if(isempty(button))
      continue;
  end
  switch( button )
   case 1
    xsel = [xsel xselpick];
    xsel = sort( xsel );
   case 2
    xsel = remove_pick( xsel, xselpick );
  end
  
  switch char(button)

    case {'p', 'P'}
      [name path] = uiputfile('xsel.mat', 'Write xsel to matlab file');
      if(name)
          save(strcat(path, name), 'xsel' );
      end
    case {'o','O'}
        [name path] = uigetfile('*.mat', 'Read xsel from matlab file');
        if(name)
            a = load(strcat(path, name));
            xsel = [xsel a.xsel];
            xsel = sort( xsel );
        end
   case {'q','Q','z','Z'}
    stop_sel = 1;
    if( length(xsel) > 0 && (length(xsel) < length(sequence) || length(xsel) > length(sequence)) )
      %if isstruct(USE_GUI)
	%btn = questdlg(sprintf('Warning: You have assigned only %d band position(s), which is less/more than the total number of bands (%d). How do you want to proceed?', length(xsel), length(sequence)), ...
	%	       'Warning!', 'Return to image', 'Force to go','Force to go');
        %if(~strcmp(btn, 'Force to go'))
	%  stop_sel = 0;
        %end
      %else
	%fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
	%fprintf('Warning: You have assigned only %d band position(s), which is less than the total number of bands (%d).\n', length(xsel), length(sequence));
	%fprintf('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
      %end
    end
   case {'e','E'}
    xsel = remove_pick( xsel, xselpick );
   case {'j','J'}
    current_relative_pos =  (xselpick - ymin)/(ymax-ymin);
    yscale = (ymax - ymin)*0.75;
    ymin = xselpick - yscale * (current_relative_pos);
    ymax = xselpick + yscale * ( 1- current_relative_pos);
   case {'l','L'}
    current_relative_pos =  (xselpick - ymin)/(ymax-ymin);
    yscale = (ymax - ymin)/0.75;
    ymin = xselpick - yscale * (current_relative_pos);
    ymax = xselpick + yscale * ( 1- current_relative_pos);
   case {'i','I'}
    yscale = (ymax - ymin);
    ymin = ymin - yscale*0.05;
    ymax = ymax - yscale*0.05;
   case {'k','K'}
    yscale = (ymax - ymin);
    ymin = ymin + yscale*0.05;
    ymax = ymax + yscale*0.05;
   case {'1'}
    contrast_factor = contrast_factor * sqrt(2);
   case {'2'}
    contrast_factor = contrast_factor / sqrt(2);
   % are a,d,w,s even in use? if not, remove.
   case {'a','A'}
    xsel = 1.005*(xsel-min(xsel))+min(xsel);
   case {'d','D'}
    xsel = (1/1.005)*(xsel-min(xsel))+min(xsel);
   case {'w','W'}
    xsel = xsel - 5;
   case {'s','S'}
    xsel = xsel + 5;
   % these are 'big' jumps. again not in use -- so remove?
   case {'b', 'B'}
    yscale = (ymax - ymin);
    ymin = ymin + yscale;
    ymax = ymax + yscale;
   case {'t', 'T'}
    yscale = (ymax - ymin);
    ymin = ymin - yscale;
    ymax = ymax - yscale;
   case {'r', 'R'}
    xsel = []; % reset
   case {'x','X'}
    seqpos = length(sequence) - [1:length(xsel)] + 1 + offset;			

    % um, a guess. Probably could think of a better one...
    peak_spacing = size( image_x, 1 )/ length(  sequence );
      
    if ~exist( 'area_pred' ) | isempty( area_pred )
      fprintf( 'You need to input data_types or area_pred if you want to use auto-assign!\n' )
    else
      input_bounds = [];
      if length( xsel ) == 2; 
	input_bounds = xsel; 
	peak_spacing = ( input_bounds(2) - input_bounds(1) ) / length( sequence );
      end;
      xsel = auto_assign_sequence( image_x, sequence, seqpos, offset, area_pred, peak_spacing, input_bounds, 0 );
    end
  end
  
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if length( xsel ) > length( sequence )+1
  fprintf( 'WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING!\n');
  fprintf( ' Number of selected positions %d exceeds length of sequence %d!\n', length(xsel),length(sequence) );
  fprintf( 'WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING!\n');
end
if length( xsel ) < length( sequence )
  fprintf( 'WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING!\n');
  fprintf( ' Number of selected positions %d is less than length of sequence %d!\n', length(xsel),length(sequence) );
  fprintf( 'WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING!\n');
end

title '';

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function xsel = remove_pick( xsel, xselpick )

if length( xsel ) > 0
  [dummy, closestpick] = min( abs(xsel - xselpick) );
  
  xsel = xsel( [1:(closestpick-1) ...
		(closestpick+1):length(xsel)] ...
	       );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  make_plot( image_x, contrast_factor, ymin, ymax, ...
		     xsel, sequence, offset, primer_binding_site, area_pred );

numlanes = size( image_x, 2 ) ;

% why not just set contrast_factor based on colormap?
% might be much faster.
image(contrast_factor * abs(image_x));

xlim = get(gca,'xlim');
xscale = abs(xlim(1) - xlim(2));
axis( [ 0.5 numlanes+0.5 ymin ymax]);

hold on
xsel_to_plot = find( xsel >= ymin & xsel <= ymax );

SHOW_LINES = 1;

for i = xsel_to_plot
  
  if SHOW_LINES
    %if (~JUST_PLOT_SEQUENCE )
    h1 = plot( [0.5 numlanes+0.5 ], [xsel(i) xsel(i)], 'color',[1 0.5 0] ); 
    %end
  end
  
  SHOW_LABELS = 1;
  show_text = 0;
  mycolor = [ 1 0.5 0];
  if  SHOW_LABELS & i <= length(sequence )
    seqchar = sequence( end- i +1 );
    
    txt_to_show = seqchar;
    seqnum = length(sequence) - i + 1 + offset;
    if  ( ~(offset == -999) ) %& JUST_PLOT_SEQUENCE)
      txt_to_show = [seqchar,num2str( seqnum)];
    end    
    
    show_text = 1;
    if (show_text )
      h2 = text( 0.5, xsel(i), txt_to_show );        
      set(h2,'HorizontalAlignment','right');
    end
  
    if  ( seqchar ==  'A' )
      %mycolor = [0 0 0];
      mycolor = [0 0 1];
    elseif ( seqchar ==  'C' ) 
      mycolor = [0 0.5 1];      
    else 
      if ( seqchar == 'U'| seqchar =='T' | seqchar == 'G' )
	%mycolor = [0.5 0.5 0.5];
	mycolor = [1 0 0];
      end
    end
  end

  SHOW_CIRCLES = 0;
  if SHOW_CIRCLES
    seqpos = length(sequence) - i + 1 + offset;
    goodpoints = find( mutpos == seqpos );
    plot( -0.5 + goodpoints, xsel(i)+0*goodpoints, 'ro' );
  end
  
  SHOW_MARKS = 1;
  %if SHOW_MARKS & ~isempty( marks );
  for j = 1:numlanes
    if (i <= size(area_pred,1))
      if (area_pred(i,j) == 1)	    
	plot( j, xsel(i), 'ro' );
      end
    end
  end
  %end
  
  if (exist( 'h1' ) )
    set(h1,'color',mycolor);
  end
  if ( show_text )
    %set(h2,'color',mycolor,'fontweight','bold');    
    set(h2,'fontweight','bold','fontsize',6,'clipping','off');
  end

end

axis off
hold off;

axis( [ 0.5 numlanes+0.5 ymin ymax]);

%axis on
