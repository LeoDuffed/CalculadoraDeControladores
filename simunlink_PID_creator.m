function simunlink_PID_creator(model_name, Gs, reference, Kp, Ki, Kd)

if ~isa(Gs, 'tf')
    error('La planta G debe ser un objeto de tipo tf.');
end

[num, den] = tfdata(Gs, 'v');

model = model_name;

% Si ya existe un modelo abierto, cerrarlo
if bdIsLoaded(model)
    close_system(model, 0);
end

% Crear modelo
new_system(model);
open_system(model);



%  BLOQUES

% STEP
add_block('simulink/Sources/Step', ...
    [model '/Step'], ...
    'After', num2str(reference), ...
    'Position', [35 185 65 215]);


% SUMADOR DE ERROR
add_block('simulink/Math Operations/Sum', ...
    [model '/Sum'], ...
    'Inputs', '+-', ...
    'Position', [130 190 150 210]);


% Kp
add_block('simulink/Math Operations/Gain', ...
    [model '/Gain'], ...
    'Gain', num2str(Kp), ...
    'Position', [240 185 270 215]);


% Ki
add_block('simulink/Math Operations/Gain', ...
    [model '/Gain1'], ...
    'Gain', num2str(Ki), ...
    'Position', [240 225 270 255]);


% Kd
add_block('simulink/Math Operations/Gain', ...
    [model '/Gain2'], ...
    'Gain', num2str(Kd), ...
    'Position', [240 265 270 295]);


% INTEGRADOR
add_block('simulink/Continuous/Integrator', ...
    [model '/Integrator'], ...
    'Position', [305 225 335 255]);


% DERIVADOR
add_block('simulink/Continuous/Derivative', ...
    [model '/Derivative'], ...
    'Position', [305 265 335 295]);


% SUMADOR DEL PID
add_block('simulink/Math Operations/Sum', ...
    [model '/Sum1'], ...
    'Inputs', '+++', ...
    'Position', [380 230 400 250]);


% Planta
add_block('simulink/Continuous/Transfer Fcn', ...
    [model '/Planta1'], ...
    'Numerator', mat2str(num), ...
    'Denominator', mat2str(den), ...
    'Position', [445 215 545 265]);

% SCOPE
add_block('simulink/Sinks/Scope', ...
    [model '/Scope1'], ...
    'Position', [600 215 650 265]);


%  CONEXIONES

% Referencia → error
add_line(model, 'Step/1', 'Sum/1', 'autorouting', 'on');


% Error → ramas PID
add_line(model, 'Sum/1', 'Gain/1', 'autorouting', 'on');
add_line(model, 'Sum/1', 'Gain1/1', 'autorouting', 'on');
add_line(model, 'Sum/1', 'Gain2/1', 'autorouting', 'on');


% Rama proporcional
add_line(model, 'Gain/1', 'Sum1/1', 'autorouting', 'on');


% Rama integral
add_line(model, 'Gain1/1', 'Integrator/1', 'autorouting', 'on');
add_line(model, 'Integrator/1', 'Sum1/2', 'autorouting', 'on');


% Rama derivativa
add_line(model, 'Gain2/1', 'Derivative/1', 'autorouting', 'on');
add_line(model, 'Derivative/1', 'Sum1/3', 'autorouting', 'on');


% PID → planta
add_line(model, 'Sum1/1', 'Planta1/1', 'autorouting', 'on');


% Planta → Scope
add_line(model, 'Planta1/1', 'Scope1/1', 'autorouting', 'on');


% Retroalimentación negativa
add_line(model, 'Planta1/1', 'Sum/2', ...
    'autorouting', 'on');



%  GUARDAR

save_system(model);

fprintf('\nModelo creado correctamente:\n');
fprintf('  %s.slx\n', model);

end