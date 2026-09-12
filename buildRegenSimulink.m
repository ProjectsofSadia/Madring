function mdl = buildRegenSimulink(p)
%BUILDREGENSIMULINK  Construct the simplified regen / energy-store model.
%
%   P_rear (From Workspace)  --> Saturation [0, 350 kW] --> P_regen
%                                                   |--> Integrator  E_recovered
%   P_regen - P_deploy  --> Integrator with saturation [0, 4 MJ] --> SOC
%
%   Deliberately small. No BMS, no thermal network, no ICE model.

    mdl = 'madringRegen';
    if bdIsLoaded(mdl), close_system(mdl, 0); end
    new_system(mdl); open_system(mdl);
    add = @(src,name,varargin) add_block(src,[mdl '/' name],varargin{:});

    add('simulink/Sources/From Workspace','P_rear', ...
        'VariableName','ts_P_rear','Position',[30 40 130 80]);
    add('simulink/Sources/From Workspace','P_deploy', ...
        'VariableName','ts_P_deploy','Position',[30 180 130 220]);

    add('simulink/Discontinuities/Saturation','Ceiling_350kW', ...
        'UpperLimit','350e3','LowerLimit','0','Position',[180 40 240 80]);

    add('simulink/Math Operations/Sum','NetPower', ...
        'Inputs','+-','Position',[300 90 330 170]);

    add('simulink/Continuous/Integrator','E_recovered', ...
        'InitialCondition','0','Position',[300 30 340 70]);

    add('simulink/Continuous/Integrator','SOC', ...
        'InitialCondition','2e6','LimitOutput','on', ...
        'UpperSaturationLimit','4e6','LowerSaturationLimit','0', ...
        'Position',[390 110 430 150]);

    add('simulink/Sinks/To Workspace','E_out', ...
        'VariableName','E_recovered','SaveFormat','Structure With Time', ...
        'Position',[420 30 480 70]);
    add('simulink/Sinks/To Workspace','SOC_out', ...
        'VariableName','SOC','SaveFormat','Structure With Time', ...
        'Position',[490 110 550 150]);
    add('simulink/Sinks/To Workspace','P_out', ...
        'VariableName','P_regen','SaveFormat','Structure With Time', ...
        'Position',[300 200 360 240]);

    add_line(mdl,'P_rear/1','Ceiling_350kW/1','autorouting','on');
    add_line(mdl,'Ceiling_350kW/1','E_recovered/1','autorouting','on');
    add_line(mdl,'E_recovered/1','E_out/1','autorouting','on');
    add_line(mdl,'Ceiling_350kW/1','NetPower/1','autorouting','on');
    add_line(mdl,'Ceiling_350kW/1','P_out/1','autorouting','on');
    add_line(mdl,'P_deploy/1','NetPower/2','autorouting','on');
    add_line(mdl,'NetPower/1','SOC/1','autorouting','on');
    add_line(mdl,'SOC/1','SOC_out/1','autorouting','on');

    set_param(mdl,'Solver','ode1','FixedStep','0.01','StopTime','94.077');
    save_system(mdl);
    fprintf('Built Simulink model "%s" (open it to inspect).\n', mdl);
end
