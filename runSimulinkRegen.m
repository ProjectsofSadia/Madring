function out = runSimulinkRegen(sig, p, mdl)
%RUNSIMULINKREGEN Run the independent Simulink integration and compare it
%with the MATLAB calculation. Agreement is an internal consistency check only.

    if nargin < 3, mdl = 'madringRegen'; end
    if ~bdIsLoaded(mdl), buildRegenSimulink(p); end

    assignin('base','ts_P_rear',timeseries(sig.P_rear,sig.time));
    set_param(mdl,'StopTime',num2str(sig.time(end)));
    out = sim(mdl);

    E_sim = out.E_recovered.signals.values(end);
    dt = diff(sig.time);
    E_mat = sum(min(sig.P_rear(1:end-1),p.P_max_ERSK).*dt);
    rel = 100*abs(E_sim-E_mat)/max(E_mat,eps);

    fprintf('\nSimulink modeled recovery : %.3f MJ\n',E_sim/1e6);
    fprintf('MATLAB modeled recovery   : %.3f MJ\n',E_mat/1e6);
    fprintf('Implementation difference : %.2f %%\n',rel);
    fprintf('(Internal consistency check; not validation against measured MGU-K data.)\n');
end
