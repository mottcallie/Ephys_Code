% testIInj.m

function [iInjOut, iInjParams] = testIInjFn(settings, durScans)
    outDur = 20000;

    iInjParams = [];
    
    out = (linspace(-2,2,outDur))';

    numRep = floor(durScans / outDur);
    
    remainder = mod(durScans, outDur);
    
    iInjOut = repmat(out,numRep,1);
    
    iInjOut = [iInjOut; out(1:remainder)];
    
end