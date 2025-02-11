audioFile = "sevdacicegi.wav";
[audioData,fs] = audioread(audioFile);
C = 6;
%Change mono to stereo
if size(audioData, 2) == 1
    aud = repmat(audioData, 1, 2);
else
    aud = audioData;
end

subBandCount =64;
Es = zeros(subBandCount,1);
Ei = zeros(subBandCount,43);

duration = size(aud,1)/fs;
beatCount = 0;
bn = aud(:, 2);
an = aud(:, 1);


segmentCount = floor(length(an) / 1024);
beats = zeros(segmentCount, 1);
beatTimes = [];

for segInd=1:segmentCount
    beatHappened = 0;
    an_s = an((segInd-1)*1024+1:segInd*1024);
    bn_s = bn((segInd-1)*1024+1:segInd*1024);
    fDom = fft(an_s + bn_s*1i);
    B = zeros(length(fDom), 1);
    for bInd =1:length(fDom)
        B(bInd) = abs(fDom(bInd))^2;
    end
    lastBandSegment = 1;
    for bandInd=1:subBandCount
        avgE = 0;
        tot = 0;
        bandSegment = floor(0.2*(bandInd)+9.5);
        
        for esInd=lastBandSegment:bandSegment +lastBandSegment -1
            tot = tot + B(esInd);
        end
        Es(bandInd) = tot/bandSegment;
        for avgInd=1:43
            avgE = avgE + Ei(bandInd,avgInd);
        end
        lastBandSegment = bandSegment +lastBandSegment;
        
        avgE = avgE/43;
        Ei(bandInd, 2:43) = Ei(bandInd, 1:42);
        Ei(bandInd,1) = Es(bandInd);
        if Es(bandInd) > avgE*C
            beatHappened = 1;            
        end
    end
    if beatHappened
        beats(segInd) = 1;
        beatTimes = [beatTimes; (segInd-1)*segmentCount/fs];
    end
end

beatInterval = diff(beatTimes);
bpm = 60/mean(beatInterval);

fprintf("BPM For %s: %f for C = %d\n", audioFile, bpm, C);