%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GIANMARCO PINTON
% FIRST WRITTEN: 2018-06-21
% LAST MODIFIED: 2022-04-07
% Launch Fullwave 2 code, easy matlab wrapper
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Basic variables %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
c0 = 1540;         % average speed of sound (m/s)
f0= 1e6;
omega0 = 2*pi*f0; % center radian frequency of transmitted wave
wX = 2e-2;         % width of simulation field (m)
wY = 6e-2;         % depth of simulation field (m)
duration = wY*2.3/c0;  % duration of simulation (s)
p0 = 1e5; % pressure in Pa
%%% Advanced variables %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ppw = 12;          % number of points per spatial wavelength
cfl = 0.4;         % Courant-Friedrichs-Levi condition
ppp = ppw/cfl;     % points per period
%%% Grid size calculations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lambda = c0/omega0*2*pi; % wavelength (m)
nX = round(wX/lambda*ppw);  % number of lateral elements
nY = round(wY/lambda*ppw);  % number of depth elements
nT = round(duration*c0/lambda*ppw/cfl); % number of time points
dX = c0/omega0*2*pi/ppw % step size in x
dY = dX; % step size in y (please keep step sizes the same)
dT = dX/c0*cfl; % step size in time

ncycles = 2; % number of cycles in pulse
dur = 2; % exponential drop-off of envelope
%%% Generate input coordinates %%%%%%%%%%%%%%%%%%%%%%%%%%%
inmap = zeros(nX,nY); 
inmap(:,1:8)=ones(nX,8);
imagesc(inmap'), axis equal, axis tight
incoords = mapToCoords(inmap); % note zero indexing for compiled code
plot(incoords(:,1),incoords(:,2),'.')
%%% Generate initial conditions based on input coordinates %%%%%%
ncycles = 2; % number of cycles in pulse
dur = 2; % exponential drop-off of envelope
fcen=[round(nX/2) round(nY/1.3)]; % center of focus
t = (0:nT-1)/nT*duration-ncycles/omega0*2*pi;
icvec = exp(-(1.05*t*omega0/(ncycles*pi)).^(2*dur)).*sin(t*omega0)*p0;
plot(icvec)
icmat=repmat(icvec,size(incoords,1)/8,1);
for k=2:8
  t=t-dX/c0; icvec = exp(-(1.05*t*omega0/(ncycles*pi)).^(2*dur)).*sin(t*omega0)*p0;
  icmat=[icmat' repmat(icvec,size(incoords,1)/8,1)']';
end
imagesc(icmat)
%%% Generate output coordinates %%%%%%%%%%%%%%%%%%%%%%%%%%
modX=1; modY=1;
outcoords = coordsMatrix(nX,nY,modX,modY);
plot(outcoords(:,1),outcoords(:,2),'.')
outcoords(:,3)=0; % label zero for total field
outcoords(find(outcoords(:,2)==9),3)=1; % label 1 for transducer surface
idc=find(outcoords(:,3)==0);
idxducer=find(outcoords(:,3)==1);
plot(outcoords(idc,1),outcoords(idc,2),'.'),hold on
plot(outcoords(idxducer,1),outcoords(idxducer,2),'r.'), hold off
%%% Generate field maps %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load vishuman_abdominal_slice
figure(1), imagesc(cmap'), figure(2), imagesc(rhomap')
betamap=Nmap;
cmap=interp2easy(cmap,dm/dX,dm/dX,'nearest');
rhomap=interp2easy(rhomap,dm/dX,dm/dX,'nearest');
Amap=interp2easy(Amap,dm/dX,dm/dX,'nearest');
betamap=interp2easy(betamap,dm/dX,dm/dX,'nearest');

cmap=cmap(round(end/2)-round(nX/2)+1:round(end/2)-round(nX/2)+nX,1:nY);
rhomap=rhomap(round(end/2)-round(nX/2)+1:round(end/2)-round(nX/2)+nX,1:nY);
Amap=Amap(round(end/2)-round(nX/2)+1:round(end/2)-round(nX/2)+nX,1:nY);
betamap=betamap(round(end/2)-round(nX/2)+1:round(end/2)-round(nX/2)+nX,1:nY);


gfilt=(5/10)^2*ppw/2; % correct for pixelization
cmap=imgaussfilt(cmap,gfilt);
rhomap=imgaussfilt(rhomap,gfilt);
Amap=imgaussfilt(Amap,gfilt);
betamap=imgaussfilt(betamap,gfilt);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Focus on transmit and focus on receive%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Walking aperture %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tx.nTx=40; % number of Tx events
tx.dep=nY/1.3*dY; % focal depth (m)
tx.bmw=lambda/2; % beamwidth (m), is this an integer multiple of dX? 

fcen=[round(nX/2) tx.dep/dX]; % center of focus on axis

t = (0:nT-1)/nT*duration-ncycles/omega0*2*pi;
icvec = exp(-(1.05*t*omega0/(ncycles*pi)).^(2*dur)).*sin(t*omega0)*p0;
[icmat dd] = focusCoords(fcen(1),fcen(2),incoords(1:size(incoords,1)/8,:),icvec,cfl);
for k=2:8
  t=t-dX/c0; icvec = exp(-(1.05*t*omega0/(ncycles*pi)).^(2*dur)).*sin(t*omega0)*p0;
  icmat=[icmat' focusCoords(fcen(1),fcen(2),incoords((k-1)*size(incoords,1)/8+1:(k)*size(incoords,1)/8,:),icvec,cfl)']';
end
imagesc(icmat)

% instead of moving the transducer, we will move the maps
nXextend=nX+ceil(tx.bmw/dX*tx.nTx);
%%% Generate field maps %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load vishuman_abdominal_slice
%figure(1), imagesc(cmapextend'), figure(2), imagesc(rhomapextend')
betamap=Nmap;
cmapextend=interp2easy(cmap,dm/dX,dm/dX,'nearest');
rhomapextend=interp2easy(rhomap,dm/dX,dm/dX,'nearest');
Amapextend=interp2easy(Amap,dm/dX,dm/dX,'nearest');
betamapextend=interp2easy(betamap,dm/dX,dm/dX,'nearest');

cmapextend=cmapextend(round(end/2)-round(nXextend/2)+1:round(end/2)-round(nXextend/2)+nXextend,1:nY);
rhomapextend=rhomapextend(round(end/2)-round(nXextend/2)+1:round(end/2)-round(nXextend/2)+nXextend,1:nY);
Amapextend=Amapextend(round(end/2)-round(nXextend/2)+1:round(end/2)-round(nXextend/2)+nXextend,1:nY);
betamapextend=betamapextend(round(end/2)-round(nXextend/2)+1:round(end/2)-round(nXextend/2)+nXextend,1:nY);


gfilt=(5/10)^2*ppw/2; % correct for pixelization
cmapextend=imgaussfilt(cmapextend,gfilt);
rhomapextend=imgaussfilt(rhomapextend,gfilt);
Amapextend=imgaussfilt(Amapextend,gfilt);
betamapextend=imgaussfilt(betamapextend,gfilt);

scat_density=0.05;
scats=rand(nXextend,nY);
scats(find(scats>scat_density))=0;
scats=scats/max(max(scats));
mean(mean(scats))
scats(:,1:10)=0; % don't put scatters inside your transducer
rhosr=0.0375*2; % scatterer impedance contrast 

rhomapextend=rhomapextend-scats*1000*rhosr;
imagesc(rhomapextend'), colorbar

for n=1:tx.nTx
  outdir=['/kulm/scratch/bmm890/txrx_' num2str(n) '/']
  eval(['!mkdir -p ' outdir]);

  cmap=cmapextend(1+(n-1)*round(tx.bmw/dX):(n-1)*round(tx.bmw/dX)+nX,:);
  rhomap=rhomapextend(1+(n-1)*round(tx.bmw/dX):(n-1)*round(tx.bmw/dX)+nX,:);
  Amap=Amapextend(1+(n-1)*round(tx.bmw/dX):(n-1)*round(tx.bmw/dX)+nX,:);
  betamap=betamapextend(1+(n-1)*round(tx.bmw/dX):(n-1)*round(tx.bmw/dX)+nX,:);
  
  imagesc(rhomap'), axis equal, drawnow

  eval(['!cp fullwave2_try6_nln_relaxing ' outdir]);
  
  cwd=pwd; addpath(cwd);
  cd(outdir)
  prep_fullwave2_try6_nln_relaxing9(c0,omega0,wX,wY,duration,p0,ppw,cfl,cmap,rhomap,Amap,betamap,incoords,outcoords,icmat)
  eval('!./fullwave2_try6_nln_relaxing & ')
  cd(cwd);

end


%%% GENERATE IMAGE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
deps = 2e-3:lambda/8:nY*dY/1.1;
lats = 0;
xducercoords = outcoords(idxducer,:);
bm=zeros(length(lats),length(deps),tx.nTx);
idps=cell(length(lats),length(deps));
fnumber=1;

n=round(tx.nTx/2);
 outdir=['/kulm/scratch/bmm890/txrx_' num2str(n) '/']
ncoordsout=size(outcoords,1);
nRun=sizeOfFile([outdir 'genout.dat'])/4/ncoordsout;
pxducer = readGenoutSlice(['genout.dat'],0:nRun-1,size(outcoords,1),idxducer);
imagesc(powcompress(pxducer,1/3))
px=pxducer(:,round(size(pxducer,2)/2));
[val idt0]=max(abs(hilbert(px)))

for n=1:tx.nTx
  outdir=['/kulm/scratch/bmm890/txrx_' num2str(n) '/']

  ncoordsout=size(outcoords,1);
  nRun=sizeOfFile([outdir 'genout.dat'])/4/ncoordsout;
  while(nRun<nT-1)
    pause(0.1)
    nRun=sizeOfFile([outdir 'genout.dat'])/4/ncoordsout;
  end
 pxducer = readGenoutSlice([outdir 'genout.dat'],0:nRun-1,size(outcoords,1),idxducer);
 %imagesc(powcompress(pxducer,1/3)), drawnow
 
  if(n==1)
    idps=cell(length(lats),length(deps));
    for ii=1:length(lats)
      lat=lats(ii);
      for jj=1:length(deps)
        dep=deps(jj);
        fcen=round([lat/dY+mean(xducercoords(:,1)) dep/dY ]);
        idx=find(abs(xducercoords(:,1)-fcen(1))<=fcen(2)/fnumber);
        dd=focusProfile(fcen,xducercoords(idx,:),dT/dY*c0);
        idt=idt0+round(2*dep/double(c0)/(dT));
        idp=double((size(pxducer,1)*(idx-1))+double(idt)+dd);
	idp=idp(find(idp<=size(pxducer,1)*size(pxducer,2)));
        idps{ii,jj}=idp;
      end
    end
  end

  for ii=1:length(lats)
    for jj=1:length(deps)
      bm(ii,jj,n)=sum(pxducer(idps{ii,jj}));
    end
  end
end


%% PLOT THE BMODE IMAGE %%
figure(1)
n=1:tx.nTx; bws=((n-(tx.nTx+1)/2)*tx.bmw);
imagesc(bws*1e3,deps*1e3,dbzero(abs(hilbert(squeeze(bm)))),[-40 0])
colormap gray, colorbar
xlabel('mm'), ylabel('mm')
axis equal, axis tight

% think about speed of sound, idt0, colorbar, sampling, ...

addpath /celerina/gfp/mfs/dumbmat/
figure(1)
n=1:tx.nTx; bws=((n-(tx.nTx+1)/2)*tx.bmw);
img=dbzero(abs(hilbert(squeeze(bm))));
img=interp2easy(img,4,1);
imagesc(bws*1e3,deps*1e3,img,[-40 0])
colormap gray, colorbar
xlabel('mm'), ylabel('mm')
axis equal, axis tight
