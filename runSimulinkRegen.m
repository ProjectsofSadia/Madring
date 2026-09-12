function out = runSimulinkRegen(sig, p, mdl)
%RUNSIMULINKREGEN  Push the real telemetry-derived signals through Simulink.
    if nargin < 3, mdl = 'madringRegen'; end
    if ~bdIsLoaded(mdl), buildRegenSimulink(p); end

    ts_P_rear   = timeseries(sig.P_rear,   sig.time); %#ok<NASGU>
    ts_P_deploy = timeseries(sig.P_deploy, sig.time); %#ok<NASGU>
    assignin('base','ts_P_rear',   timeseries(sig.P_rear,   sig.time));
    assignin('base','ts_P_deploy', timeseries(sig.P_deploy, sig.time));

    set_param(mdl,'StopTime',num2str(sig.time(end)));
    out = sim(mdl);
    E = out.E_recovered.signals.values(end);
    fprintf('Simulink lap total recoverable electrical energy: %.3f MJ\n', E/1e6);
end
