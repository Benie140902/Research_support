% Assuming the following 18x4 complex matrices are already defined:
% H_true   → True channel coefficients
% H_est_LSE  → Estimated by Algorithm LSE
% H_est_MMSE  → Estimated by Algorithm MMSE


% Generate estimated channel matrices for each algorithm
%H_est_LSE = channelCoef + H_LS;
%H_est_MMSE = channelCoef+ H_MMSE;
lastLayer=size(channelCoef,3);

% Compute MSE for each algorithm (vs the true channel)
for i =1:lastLayer
mse_LSE(:,:,i) = mean(abs(H_LS(:,:,i) - channelCoef(:,:,i)).^2, 'all');
mse_MMSE(:,:,i) = mean(abs(recXpilots_ (:,:,i) - channelCoef(:,:,i)).^2, 'all');

% Display MSE values
fprintf('MSE (H_LSE(%d)): %.6f\n',i, mse_LSE(:,:,i));
fprintf('MSE (H_MMSE(%d)): %.6f\n',i, mse_MMSE(:,:,i));

% Visualize using bar chart
figure;
bar([mse_LSE(:,:,i), mse_MMSE(:,:,i)]);
set(gca, 'XTickLabel', {'H(LSE)', 'H(MMSE)'});
xlabel('Channel coefficients of two different algorithms');
ylabel('Mean Squared Error');
title('MSE Comparison For layer',i);
grid on;
end
