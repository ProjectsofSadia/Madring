function mdl = buildRegenSimulink(p)
%BUILDREGENSIMULINK Build the independent Simulink recovery calculation.
%
% Telemetry-derived rear-axle electrical potential -> 350 kW saturation ->
% integrator -> cumulative modeled recovered energy.
%
% This is intentionally not a full power-unit, battery, BMS or brake-by-wire model.

    mdl = 'madringRegen';
    if bdIsLoaded(mdl), close_system(mdl,0); end
    new_system(mdl); open_system(mdl);

    add_block('simulink/Sources/From Workspace',[mdl '/P_rear'], ...
        'VariableName','ts_P_rear','Position',[40 70 140 110]);
    add_block('simulink/Discontinuities/Saturation',[mdl '/Ceiling_350kW'], ...
        'UpperLimit',num2str(p.P_max_ERSK),'LowerLimit','0', ...
        'Position',[200 70 280 110]);
    add_block('simulink/Continuous/Integrator',[mdl '/E_recovered'], ...
        'InitialCondition','0','Position',[340 70 390 110]);
    add_block('simulink/Sinks/To Workspace',[mdl '/E_out'], ...
        'VariableName','E_recovered','SaveFormat','Structure With Time', ...
        'Position',[450 70 530 110]);

    add_line(mdl,'P_rear/1','Ceiling_350kW/1','autorouting','on');
    add_line(mdl,'Ceiling_350kW/1','E_recovered/1','autorouting','on');
    add_line(mdl,'E_recovered/1','E_out/1','autorouting','on');

    set_param(mdl,'Solver','ode1','FixedStep','0.01');
    save_system(mdl);
    fprintf('Built Simulink model "%s". The .slx file is generated locally and ignored by Git.\n',mdl);
end
