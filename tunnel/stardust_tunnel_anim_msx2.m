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

[img,map,alpha]=imread('grfx data\stardust_tunnel_anim.gif','frames','all');

map(2,:)=TMSMAP(0+1,:);
map(3,:)=TMSMAP(7+1,:);
map(4,:)=TMSMAP(5+1,:);
map(5,:)=TMSMAP(4+1,:);

N = cell(1);
a = uint8(zeros(size(img,1),size(img,2)));

Nf = size(img,4);
ncol = 256;
nrow = 192;

data = zeros( ncol,nrow,Nf);

for n=1:Nf
    b = img(:,:,1,n);
    a = b;
%         image(b); colormap(map);pause
    [s,nmap] = imresize(a,map, [nrow ncol], 'nearest','Colormap','original','Dither',true,'Antialiasing',true);
    s = imapprox(s,nmap,TMSMAP);
    N{n} = s;

    image(s); 
    colormap(TMSMAP);
    pause(0.1);
    data(:,:,n) = s';
end

name = 'strdst.gif';

imwrite(imresize(N{1},TMSMAP,1,'nearest','Colormap','original'),TMSMAP,name,'gif','LoopCount',Inf,'DelayTime',0,'DisposalMethod','restorePrevious');
for n=2:Nf
    imwrite(imresize(N{n},TMSMAP,1,'nearest','Colormap','original'),TMSMAP,name,'gif','WriteMode','append','DelayTime',0,'DisposalMethod','restorePrevious');
end

for n=1:Nf
    name = 'strdst00.png';
    name(8) = name(8)+n-1;
    imwrite(N{n},TMSMAP,name,'png');
    
    X = N{n};
    arry2tile(im2col(X',[8 8],'distinct'),TMSMAP);

    system(['miz\MSX-O-Mizer.exe  -r out.CHR ', name(1:8), 'chr.miz ']);
    system(['miz\MSX-O-Mizer.exe  -r out.CLR ', name(1:8), 'clr.miz ']);

end
    
name = 'data0.bin';
for n=1:Nf
    fid = fopen(['basic\' name],'wb');
    h = [254; 0; 0; 224; 7; 0; 0];
    for m=0:5
        k = [(16*data(1:2:ncol,(m*8+(1:8)),n)+data(2:2:ncol,(m*8+(1:8)),n))]';
        h = [h; k(:)];
    end
    fwrite(fid,h,'uint8');
    fclose(fid);
    name(5) = dec2hex(n,1);
end



