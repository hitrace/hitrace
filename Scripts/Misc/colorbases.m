function colorbases(imagex,offset,base_locations, residue_locations, whichres,whattoplot,maxplot,maxplot2,colorscheme,makelegend)
%hold off; image(imagex); hold on; axis equal; 
[xsize,ysize,zsize]=size(imagex);
axis([0 ysize 0 xsize]); zoomedin = 0;

numres = length(base_locations);

if (nargin<7) maxplot = max(abs(whattoplot));end;
if (nargin<8) maxplot2 = maxplot;end;
if ~exist('colorscheme') colorscheme = 1;end;
    
square_width = 12;
imagex_color = double(imagex);
count = 1;
for k=whichres
    x=base_locations(1,k - offset);
    y=base_locations(2,k - offset);
    
    distx = base_locations(1,k - offset)-residue_locations(1,k-offset);
    disty = base_locations(2,k - offset)-residue_locations(2,k-offset);
    %   h=rectangle('Position', ...
    %       [x - square_width/2, y - square_width/2, square_width,square_width]);
    colorplot = getcolor(whattoplot(count),maxplot,maxplot2,colorscheme);
    
    deviation=5;
    
    if abs(distx)>abs(disty)
        xthickness = square_width/2;
        ythickness = square_width/4;
        xdeviation = deviation*sign(distx);         ydeviation = 0;       
    else
        xthickness = square_width/4;
        ythickness = square_width/2;
         xdeviation = 0; ydeviation = deviation*sign(disty);   
    end    
    
    bottom = max(floor(y+ydeviation-ythickness),2); top=min(floor(y+ydeviation+ythickness),xsize-1);
    left = max(floor(x+xdeviation-xthickness),2) ;right= min(floor(x+xdeviation+xthickness),ysize-1); 
    xbins =  bottom:top; 
    ybins = left:right;
    for n=1:3
%        imagex_color(xbins,ybins,n) = double(imagex(xbins,ybins,n))*colorplot(n);
        imagex_color(xbins,ybins,n) = 255*colorplot(n);
    end
    
    xbins =  bottom:top; 
    ybins = left-1;
    for n=1:3
        imagex_color(xbins,ybins,n) = 0;
    end
    
    xbins =  bottom:top; 
    ybins = right+1;
    for n=1:3
        imagex_color(xbins,ybins,n) = 0;
    end
    
    xbins =  bottom-1; 
    ybins = left:right;
    for n=1:3
        imagex_color(xbins,ybins,n) = 0;
    end
    
    xbins =  top+1; 
    ybins = left:right;
    for n=1:3
        imagex_color(xbins,ybins,n) = 0;
    end
    count=count+1;
end

%for squares where there is no data 
%for k=1:size(base_locations,2)
%    if (isempty(find(k+offset == whichres)))
%    x=base_locations(1,k);
%    y=base_locations(2,k);
%    xbins = floor(y-square_width/2) :  min(floor(y+square_width/2),xsize); 
%    ybins = floor(x-square_width/2) :  min(floor(x+square_width/2),ysize); 
%        for n=1:3
%            imagex_color(xbins,ybins,n) = double(imagex(xbins,ybins,n))*0.7;
%        end
%    end
%end

%Make a "legend"
if ~exist('makelegend') 
  makelegend=1; 
end

if (makelegend)
numlines = 10;  
x_offset = 5*square_width;
sizebar = 4;
for k=1:-(1/numlines):-1
    ybins = square_width:2*square_width;
    xbins = x_offset + ...
        [round(sizebar*-1*k*square_width) : round(sizebar*-1*k*square_width)+sizebar*square_width/numlines];
    colorplot = getcolor(k, maxplot,maxplot2,colorscheme);
    for n=1:3
        imagex_color(xbins,ybins,n) = double(imagex(xbins,ybins,n))*colorplot(n);
    end
end
end

hold off; image(imagex_color/256); hold on; axis equal

if (makelegend)
k=-1;
text(2*square_width,x_offset+round(sizebar*-1*k*square_width),['-',num2str(abs(maxplot2))]);
k=+1;
text(2*square_width,x_offset+round(sizebar*-1*k*square_width),['+',num2str(maxplot)]);
end

axis off


