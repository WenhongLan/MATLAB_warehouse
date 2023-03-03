function visualize_sino(sino_rebin)
[~,N,P] = size(sino_rebin);
middle_P = round(P/2);
theta_each = 180/N;
theta = 0: theta_each:(180-theta_each);
figure;imagesc(sino_rebin(:,:,middle_P)); colormap gray
axis image;set(gca,'YDir','normal');
figure; imagesc(iradon(sino_rebin(:,:,middle_P),theta,440));
axis image;set(gca,'YDir','normal');colormap gray;
end