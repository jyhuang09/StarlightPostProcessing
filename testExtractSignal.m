% extract ROI from donor channel and generate trace

%% data file
clear all;
% datFile = '~/priv/data/starlightData/ForXin/0min.tif';
[filename, path] = uigetfile('.tif');
datFile = strcat(path, filename);
datInfo = imfinfo(datFile);
nFrm = length(datInfo);

%% channels
chan = struct;
chan(1).name = '645 - 675 nm';
chan(1).position = [10 0 155 512];
chan(1).flipX = false;
chan(2).name = '700 nm LP';
chan(2).position = [185 0 155 512];
chan(2).flipX = false;
chan(3).name = '675-700 nm';
chan(3).position = [357 0 155 512];
chan(3).flipX = false;
chan(4).name = 'Polymerase donor';
chan(4).position = [690 0 155 512];
chan(4).flipX = true;

%% params
nChan = length(chan);
gCalImgRange = [400, 800];
donorChan = 4;
thetaCal = 0.995;
theta = 0.99;
nSigMax = 256;
rDilate = 1;

%% get calibration image
img = zeros(datInfo(1).Height, datInfo(1).Width, range(gCalImgRange)+1);
for i = gCalImgRange(1) : gCalImgRange(2)
    img(:, :, i-gCalImgRange(1)+1) = imread(datFile, i);
end
img = mean(img, 3);

figure; 
imshow(img, [0, max(img(:))]);
hold on;
for i = 1 : nChan
    rectangle('Position', chan(i).position, 'EdgeColor', 'r');
end
pause; close all;

%% get donor channel
imgDonor = imcrop(img, chan(donorChan).position);
if chan(donorChan).flipX, imgDonor = flipdim(imgDonor, 2); end


%% geometric calibration
hBlob = vision.BlobAnalysis('MaximumCount', nSigMax);
hTrEst = vision.GeometricTransformEstimator;
for i = 1 : nChan
    if i ~= donorChan
        imgChan = imcrop(img, chan(i).position);
        if chan(i).flipX, imgChan = flipdim(imgChan, 2); end
        [~, c0] = step(hBlob, imgDonor>prctile(imgDonor(:), thetaCal*100));
        [~, c] = step(hBlob, imgChan>prctile(imgChan(:), thetaCal*100));
        [d, idx] = min(dist(c0, c'));
        chan(i).T = step(hTrEst, c, c0(idx, :));
        
        temp = step(vision.GeometricTransformer, imgChan, chan(i).T);
        subplot(1, 2, 1); imshowpair(imgChan, imgDonor);
        subplot(1, 2, 2); imshowpair(temp, imgDonor);
        pause;
    end
end

%% get ROIs
hBlob = vision.BlobAnalysis(...
    'AreaOutputPort', true, ...
    'CentroidOutputPort', true, ...
    'BoundingBoxOutputPort', true, ...
    'MajorAxisLengthOutputPort', true, ...
    'MinorAxisLengthOutputPort', true, ...
    'OrientationOutputPort', true, ...
    'EccentricityOutputPort', true, ...
    'EquivalentDiameterSquaredOutputPort', true, ...
    'ExtentOutputPort', true, ...
    'PerimeterOutputPort', true, ...
    'LabelMatrixOutputPort', true, ...
    'ExcludeBorderBlobs', true, ...
    'MaximumCount', nSigMax);
[a, c, bb, majax, minax, ori, ecc, eqdiasq, ext, perim, label] = step(hBlob, imgBlob);
nROI = length(a);

%% get traces
f = @mean;
hTr = vision.GeometricTransformer;
hDilate = vision.MorphologicalDilate('Neighborhood', strel('disk', rDilate));
sig = zeros(nFrm, nChan, nROI);
for i = 1 : nFrm
    img = imread(datFile, i);
    for j = 1 : nChan
        imChan = double(imcrop(img, chan(j).position));
        if chan(j).flipX, imChan = flipdim(imChan, 2); end
        if j~=donorChan, imChan = step(hTr, imChan, chan(j).T); end
        for k = 1 : nROI
            imgMask = label==k;
            imgMask = step(hDilate, imgMask);
            data = imChan(imgMask(:));
            sig(i, j, k) = feval(f, data);
        end
    end
    if mod(i, 100)==0, disp(i); end
end

%% plot traces
figure;
for i = 1 : nROI
    plot(sig(:, :, i)); 
    pause;
end

%% save results
save([datFile, '.mat'], 'chan', 'c', 'nChan', 'nFrm', 'nROI', 'sig');
