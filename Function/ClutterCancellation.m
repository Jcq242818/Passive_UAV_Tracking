function S_sur_cc = ClutterCancellation(S_sur,S_ref,P,L,CPI,f_s)
num_samples_data = length(S_sur);
if P==0 && L==0
    S_sur_cc = S_sur-S_ref*(S_ref'*S_sur/(norm(S_ref)^2));
else
    X_cc = zeros(num_samples_data,(2*P+1)*(2*L+1));
    for p = -P:P
        for ell = -L:L
            X_cc(:,(p+P)*(2*L+1)+ell+L+1) = circshift(S_ref,ell).* ...
                exp(-1i*2*pi*(p/CPI)*[0:num_samples_data-1].'/f_s);
        end
    end
    S_sur_cc = S_sur - X_cc/(X_cc'*X_cc)*(X_cc'*S_sur);
end
