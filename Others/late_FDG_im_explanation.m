clc;clear;

%% This section is to calculate the scan duration vs. moment of scan start 
% after the tracer injection; 
% The sensitivity is perfect (100%)
tau = 109.7 *60; % half life of FDG, unit: second;
A0 = 3e6; % initial activity of the tracer

delta_t_ref = 5 * 60; % ref. scan time; unit: second;
lambda = log(2)/tau; % decay coefficient; unit: second
t1_ref = 3600; % ref. scan start moment after injection; unit: second
syms   t_ref;
n_event_ref = round(double(int(A0*exp(-(lambda*t_ref)), t_ref, [t1_ref t1_ref+delta_t_ref])));
n_event = n_event_ref; % number of events recorded


syms t1 t2 t;

fx = n_event == int(A0*exp(-(lambda*t)), t, [t1 t2]);

fx_t2 = solve(fx,t2);

fx_t2_num = double(subs(fx_t2,t1,3600:60:36000)); % unit: second. 
fx_t2_num_m_sm = double(subs(fx_t2,t1,(1.5:0.5:10).*3600));% unit: second. 

% the resolution of this curve is 1 min.
t1_num = 3600:60:36000;
plot(t1_num./3600,(fx_t2_num-t1_num)./60,'k');
xlabel("start moment of scan after tracer injection, [hrs]");
ylabel("scan time with same Nr. of decay, [mins]");
xlim([0.5 10.5]);
ylim([0 520]);
grid on;

%% True method with 'good' value for scan time setting:
t1_good = (4.5:0.5:10).*3600; % unit: second.
fx_t2_num_good = double(subs(fx_t2,t1,t1_good)) - t1_good; % unit: second
fx_t2_num_good_min = 5.*round(fx_t2_num_good./60./5); %to the multiple of 5
%fx_t2_num_good_min = round(fx_t2_num_good./60,-1); % to multiple of 10


for kk = 1:length(t1_good)
    n_event_good(kk) = int(A0*exp(-(lambda*t)), t, [t1_good(kk) t1_good(kk)+...
        fx_t2_num_good_min(kk).*60]);
end
n_event_good = double(n_event_good); clear kk

hold on;
plot(t1_good./3600, fx_t2_num_good_min,'--^','Color','r');
hold off;
%% based on the simplified method:
% the activity after 1hr of tracer injection (ref.)
A1 = A0*exp(-(lambda*3600));
% the product of activity and scan time. (ref. scan time is 5 mins)
Pro_ref = A1 * 5; % unit: Bq x mins

% the activity after 1.5 to 10 hrs, interval 30 mins
t_x = (1.5:0.5:10).*3600; % unit: second
A_t = A0.*exp(-(lambda.*t_x)); % the activity at each moment mentioned above
% the scan time determined by the simplified method
t_sm = Pro_ref./A_t; % unit: mins

% Nr. of decay with the duration by simplified method:
for kk = 1:length(t_x)
    n_event_sm(kk) = int(A0*exp(-(lambda*t)), t, [t_x(kk) t_x(kk)+t_sm(kk).*60]);
end
n_event_sm = double(n_event_sm);

hold on;
plot(t_x./3600,t_sm,'-x','Color','b');
lgd = legend("True Method","True Method with <Good> value","Simplified Method");
hold off;
set(gca,"FontSize",14);
lgd.Location = 'northwest';

%% The error for the simplified method:
RR = (1 - abs(n_event - n_event_sm)./n_event).*100; % unit: %. Simplified to True
RR2 = (1 - abs(n_event - n_event_good)./n_event).*100; % unit: %. True_good to True
figure; plot(t_x./3600,RR,'--^'); grid on;
hold on;
plot(t1_good./3600,RR2,'--*');hold off
xlim([0.5 10.5]);
ylim([0 105]);
xlabel("start moment of scan after tracer injection, [hrs]");
ylabel("% to the ref. Nr. decay, [%]");
set(gca,"FontSize",14);
lgd2 = legend("Simplified Method","True Method with <Good> Value");
lgd2.Location = "southwest";

%% The example plot to explain the necessarity of True method:
t_decay = 0:10*3600; % unit: second;
A_decay = A0.*exp(-lambda.*t_decay);
figure; plot(t_decay./3600,A_decay,'k');grid on;
xlim([0 10.5]); %ylim([0 10.5e7]);
hold on;

% draw the segements
points_Loc_ref = ...
    [find(t_decay==3600), 0;
    find(t_decay==3600), A_decay(find(t_decay==3600));
    find(t_decay==3900), 0;
    find(t_decay==3900), A_decay(find(t_decay==3900));];

t_2nd = 7; % unit: hour
t2_6 = round(Pro_ref./A_decay(find(t_decay==(3600*t_2nd))).*60);
points_Loc_sm = ...
    [find(t_decay==3600*t_2nd), 0;
    find(t_decay==3600*t_2nd),A_decay(find(t_decay==3600*t_2nd));
    find(t_decay==(3600*t_2nd+t2_6)), 0;
    find(t_decay==(3600*t_2nd+t2_6)), A_decay(find(t_decay==(3600*t_2nd+t2_6)));];

t2_6_real = round(double(subs(fx_t2,t1,3600*t_2nd)));
points_Loc_real = [t2_6_real, 0;
                   t2_6_real, A_decay(find(t_decay==t2_6_real))];

plot([points_Loc_ref(1,1)/3600,points_Loc_ref(2,1)/3600],[points_Loc_ref(1,2),points_Loc_ref(2,2)],'b');
plot([points_Loc_ref(3,1)/3600,points_Loc_ref(4,1)/3600],[points_Loc_ref(3,2),points_Loc_ref(4,2)],'b');

plot([points_Loc_sm(1,1)/3600,points_Loc_sm(2,1)/3600],[points_Loc_sm(1,2),points_Loc_sm(2,2)],'b');
plot([points_Loc_sm(3,1)/3600,points_Loc_sm(4,1)/3600],[points_Loc_sm(3,2),points_Loc_sm(4,2)],'b');

plot([points_Loc_real(1,1)/3600,points_Loc_real(2,1)/3600],[points_Loc_real(1,2),points_Loc_real(2,2)],'r');
hold off;
xlabel("time, [hrs]");
ylabel("Activity, [Bq]");
set(gca,"FontSize",14);

%% formula validation section:
%clc;clear
%syms t1 t2 n_event lambda t A0;

%fx = n_event == int(A0*exp(-(lambda*t)), t, [t1 t2]);

%fx_t2 = solve(fx,t2);