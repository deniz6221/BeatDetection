audioFile = "aleph.wav";
[audioData,fs] = audioread(audioFile);

%Change mono to stereo
if size(audioData, 2) == 1
    aud = repmat(audioData, 1, 2);
else
    aud = audioData;
end

subBandCount =16;

ampMax = 65535;
audioLen = size(aud, 1);
duration = audioLen/fs;

clipSamples = 5*fs;
midPoint = floor(audioLen / 2);
startSample = max(1, midPoint - floor(clipSamples / 2));
endSample = min(audioLen, midPoint + floor(clipSamples / 2) - 1);

bandSegment = floor((endSample-startSample)/subBandCount);

ak = aud(startSample:endSample, 1);
bk = aud(startSample:endSample, 2);


ak = diff(ak);
bk = diff(bk);

ffab = fft(ak+1j*bk);
tak = real(ffab);
tab = imag(ffab);

logIndices = floor((endSample-startSample)/152);

EbpmMaxes = zeros(subBandCount,2);
lastIdx = 0;
for sub=1:subBandCount
    ws = (sub+1)*logIndices;
    startIdx = lastIdx +1;
    
    endIdx = startIdx + ws-1;
    lastIdx = endIdx;
     
    task = tak(startIdx: endIdx);
    tbsk = tab(startIdx: endIdx);
    
    
    Ebpm = zeros(13,1);
    for f=60:10:180
      
      Ti = (60/f)*fs;
      lk = zeros(ws,1);
      jk = zeros(ws, 1);

      for m=1:ws
          if mod(m , Ti) == 0
              lk(m) = ampMax;
              jk(m) = ampMax;
          end
      end
      tlk = real(fft(lk+1j*jk));
      tjk = imag(fft(lk+1j*jk));
      for k=1:ws
          Ebpm(f/10-5) = Ebpm(f/10-5) + abs((task(k) + 1j*tbsk(k))*(tlk(k)+ 1j*tjk(k)));
      end

    end
    [maxE, indE] = max(Ebpm);
    BPMmax = (indE+1)*5;
    EbpmMaxes(sub, :) = [maxE, BPMmax];
end

totalE = 0;
totalEB = 0;
for c=1:subBandCount
    totalE = totalE + EbpmMaxes(c,1);
    totalEB = totalEB + EbpmMaxes(c,1)*EbpmMaxes(c,2);
end


BPM = totalEB/totalE;

fprintf("BPM For %s: %f\n", audioFile, BPM);
