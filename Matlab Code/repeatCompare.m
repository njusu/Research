% Compare the following 5 methods: SBA, SAS, USVT, NBS, FANS
% Consider 4 graphons g1 to g4
% Repeat for 100 times, record MSE and MAE for each method
% Results were used to generate Figure 5 in the paper

REPEAT = 100;
MSE_FANS = zeros(2,REPEAT);
MSE_NBS = zeros(2,REPEAT);
MSE_SAS = zeros(2,REPEAT);
MSE_SBA = zeros(2,REPEAT);
MSE_USVT = zeros(2,REPEAT);

L_OPT = zeros(1,REPEAT);

n = 100;
c = 1;
sigma = 0.3;
parfor repeat = 1:REPEAT
    % Generate data
    u = sort(rand(n,1)); % column vec
    P = zeros(n,n);
    for i=1:n
        for j=i:n
            P(i,j) = g1(u(i),u(j),n); % Change g1 to g4
            P(j,i) = P(i,j);
        end
    end
    %[grid1, grid2] = meshgrid(u,u);
    %temp = g2(grid1,grid2,n);
    A = triu(rand(n,n)<P,0); A = 1*(A+A'>0);
    
    % Generate features
    X = cat(2, f1(u,n)/std(f1(u,n))+normrnd(0,sigma,n,1), ...
    f2(u,n)/std(f2(u,n))+normrnd(0,sigma,n,1), ...
    f3(u,n)/std(f3(u,n))+normrnd(0,sigma,n,1), ...
    f4(u,n)/std(f4(u,n))+normrnd(0,sigma,n,1));

    % generate for SBA
    u2 = sort(rand(1,n/2));
    P2 = zeros(n/2,n/2);
    for i=1:(n/2)
        for j=i:(n/2)
            P2(i,j) = g1(u2(i),u2(j),n/2); % Change g1 to g4
            P2(j,i) = P2(i,j);
        end
    end
    A1 = triu(rand(n/2,n/2)<P2,0); A1 = 1*(A1+A1'>0);
    A2 = triu(rand(n/2,n/2)<P2,0); A2 = 1*(A2+A2'>0);
    
    % FANS and NBS
    LAMBDA = [0, 0.05*(1:60)];
    [L2,L1] = CV_FANS(A, X, LAMBDA, 10);
    opt = find(L1==min(L1));
    L_OPT(repeat) = LAMBDA(opt(1));
    P_FANS = FANS(A,X,LAMBDA(opt(1)));
    P_NBS = NBS(A,c);
    %P_NBS = NBSoriginal(A);
    
    % SAS
    deg = mean(A);
    [~, pos] = sort(deg,'descend');
    P_SAS = zeros(n,n);
    P_SAS(pos,pos) = SAS(A);
    
    % SBA
    G = zeros(n/2,n/2,2);
    G(:,:,1) = A1;
    G(:,:,2) = A2;
    % run Demo_crossvalidation.m to choose Delta
    Delta = 0.1; % n=500, all g can use 0.1, g4 can also try 0.05 
    B = estimate_blocks_directed(G,Delta);
    [~,P_SBA] = histogram3D(G,B); % ~ was H
    
    % USVT
    P_USVT = Method_chatterjee((A-0.5).*2);
    P_USVT = P_USVT/2+0.5;
    
    MSE_NBS(:,repeat) = [mean(mean((P_NBS-P).^2)), mean(mean(abs(P_NBS-P)))];
    MSE_SAS(:,repeat) = [mean(mean((P_SAS-P).^2)), mean(mean(abs(P_SAS-P)))];
    MSE_SBA(:,repeat) = [mean(mean((P_SBA-P2).^2)), mean(mean(abs(P_SBA-P2)))];
    MSE_USVT(:,repeat) = [mean(mean((P_USVT-P).^2)), mean(mean(abs(P_USVT-P)))];
    MSE_FANS(:,repeat) = [mean(mean((P_FANS-P).^2)), mean(mean(abs(P_FANS-P)))];

    fprintf('repeat = %3g \n', repeat);
end

mean(MSE_SBA,2)
std(MSE_SBA,0,2)
dlmwrite('g1_n=100_run100.txt',cat(1,MSE_SBA,MSE_SAS,MSE_USVT,MSE_NBS,MSE_FANS));

res = dlmread('g1_n=100_run100.txt');
mean(res,2)
std(res,0,2)

