%% Example Title

close all
clear

TMSMAP = [0,0,0               % 0 Transparent
    0,0,0               % 1 Black           0    0    0
    33,200,66            % 2 Medium green   33  200   66
    94,220,120           % 3 Light green    94  220  120
    84,85,237            % 4 Dark blue      84   85  237
    125,118,252           % 5 Light blue    125  118  252
    212,82,77             % 6 Dark red      212   82   77
    66,235,245            % 7 Cyan           66  235  245
    252,85,84             % 8 Medium red    252   85   84
    255,121,120           % 9 Light red     255  121  120
    212,193,84            % A Dark yellow   212  193   84
    230,206,128           % B Light yellow  230  206  128
    33,176,59             % C Dark green     33  176   59
    201,91,186            % D Magenta       201   91  186
    204,204,204           % E Gray          204  204  204
    255,255,255];         % F White         255  255  255

TMSMAP = TMSMAP/255;

path = 'bolid\';
name = 'bolid32.bmp';
[texture,MAP] = imread([ path name]);
dz = 0.25;
z = 0:dz:31;
Scale = round(32./(1+z));
scale = [ unique(Scale) ];


name = 'bolid00.gif';

M = cell(size(texture,2)/32,size(scale,2));
i = 1;
for s = scale
    [t,NMAP] = imresize(texture, MAP, s/32,'nearest'); 
    
    xTMSMAP = TMSMAP;
    xTMSMAP(1,:) = [0 0.231372549019608 0.215686274509804;];
    t = imapprox(t,NMAP,xTMSMAP);
    figure(s)
    image(t)
    colormap(xTMSMAP)
    axis equal
    
     k = im2col(t,[s s],'distinct');
     for n=1:size(k,2)
        t = zeros(32);
        m = fix(1+(32-s)/2);
        t(m:(m+s-1),m:(m+s-1)) = col2im(k(:,n),[s s],[s s],'distinct');
        M{n,i} = uint8(t);
     end
     
    imwrite(M{1,i},xTMSMAP,[ path name ],'gif','LoopCount',Inf,'DelayTime',0);
    for n=2:size(k,2)
        imwrite(M{n,i},xTMSMAP,[ path name ],'gif','WriteMode','append','DelayTime',0);
    end
    name(6:7) = dec2hex(i,2);
    i = i+1;
end


z = 0:0.5:31;

ANI = cell(1);
j = 1;
figure;
for z = 31:-dz:0
    s = round(32/(1+z));
    n = find(scale==s);
    for ani=1:size(M,1)
        image(M{ani,n});
        ANI{j} = M{ani,n};            
        colormap(xTMSMAP)
        j = j+1;
    end
end

name = 'animated_sequence.gif';
imwrite(ANI{1},xTMSMAP,[ path name ],'gif','LoopCount',Inf,'DelayTime',0);
for n=2:size(ANI,2)
    imwrite(ANI{n},xTMSMAP,[ path name ],'gif','WriteMode','append','DelayTime',0);
end
