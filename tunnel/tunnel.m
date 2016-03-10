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

% MAP = zeros(256,3);
% MAP(1:16,:) = TMSMAP/255;
TMSMAP = TMSMAP/255;


texWidth = 256;
texHeight = 256;
% w = 72;h = 56;
w = 640/10;h = 480/10;

distanceTable = zeros(w,h);
angleTable = zeros(w,h);
buffer = zeros(w,h);

texture = zeros(texWidth,texHeight);
    %//generate texture
for x = 0:(texWidth-1)
    for y = 0:(texHeight-1)
%        texture(x+1,y+1) = bitxor((x<=texWidth/2),(y<=texHeight/2)) *255;%bitxor(fix(x/256), fix(y/1),'int16');
        %texture(x+1,y+1) = (y<=texHeight/2)*255;%(y<=texHeight/2)) *255;%bitxor(fix(x/256), fix(y/1),'int16');
        texture(x+1,y+1) = fix( exp(-0.5/48^2*(y-128)^2)*255);
    end
end
t = kron([ 66,235,245],[0:255]')/255/255;
%t = [(0:255)*0.0;(0:255)*0.0;(0:255);]'/255;
figure
image(texture)
colormap(t)
figure
%s = [0:15;0:15;0:15]'/15;
[texture,MAP] = imapprox(texture,t,TMSMAP);
MAP = TMSMAP; 

%texture = imread('tunnelstonetex.png');[texture ,MAP] = rgb2ind(texture ,TMSMAP,'dither');
% texture = imread('tunnelarboreatex.png');[texture ,MAP] = rgb2ind(texture ,TMSMAP,'dither');
% [texture,MAP] = imread('flame.png');%[texture ,MAP] = rgb2ind(texture ,TMSMAP,'dither');
% [texture,MAP] = imapprox(texture,MAP,TMSMAP);

image(texture)
colormap(MAP)

%     //generate non-linear transformation table
ratio = 32.0;
for x = 0:w-1
    for y = 0:h-1
        distance = mod((ratio * texHeight / sqrt((x - w / 2.0)^2 + (y - h / 2.0)^2)) , texHeight);
        angle = (texWidth * atan2(y - h / 2.0, x - w / 2.0) / pi/2);
        if (angle<0)
            angle=angle+texWidth;
        end
        distanceTable(x+1,y+1) = uint64(distance);
        angleTable(x+1,y+1)    = (angle);
    end
end
		   
%     //begin the loop
animation = 0;
Nf=7;

data = zeros( [size(buffer) Nf]);

for n=1:Nf
    animation = animation+1/Nf
%         //calculate the shift values out of the animation value
    shiftX = (texWidth * 1.0 * animation);
    shiftY = (texHeight * 0.0 * animation);        

    for x = 0:w-1
        for y = 0:h-1
%             //get the texel from the texture by using the tables, shifted with the animation values
            i = fix(mod(uint16(distanceTable(x+1,y+1) + shiftX),texWidth));
            j = fix(mod(uint16(   angleTable(x+1,y+1) + shiftY),texHeight));
            buffer(x+1,y+1) = texture(j+1,i+1);
        end
    end
    data(:,:,n) = buffer;

    [t,newmap] = imresize(1+buffer', MAP, 10,'nearest'); 
    M(n) = im2frame(t,newmap);
end


imwrite(M(1).cdata,M(1).colormap,'test.gif','gif','LoopCount',Inf,'DelayTime',0);
for n=2:Nf
    imwrite(M(n).cdata,M(n).colormap,'test.gif','gif','WriteMode','append','DelayTime',0);
end
    
name = 'data0.bin';
for n=1:Nf
    fid = fopen(['basic\' name],'wb');
    h = [254; 0; 0; 0; 6; 0; 0];
    for m=0:5
        k = [(16*data(1:2:64,(m*8+(1:8)),n)+data(2:2:64,(m*8+(1:8)),n))]';
        h = [h; k(:)];
    end
    fwrite(fid,h,'uint8');
    fclose(fid);
    name(5)=name(5)+1;
end
