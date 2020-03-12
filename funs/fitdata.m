function [fitParams] = fitdata( data, distribution )


%-- fitting options ---------------------------------------------------
switch(distribution)
    case 'Ex-gaussian'
        data = data(data<1e3 & data>0);
        [phat] = fminsearch('swjMLE', [ 150,36,100],optimset('MaxFunEvals',500));
        fitParams = phat;
    case 'Mix-2-Gaussian'
        [mu, s, t] = fit_mix_gaussian(data,2);
        fitParams = [mu s t];
end