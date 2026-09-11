function simunlink_PID_creator_2(model_name, Gs, reference, Kp, Ki, Kd)

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


add_block('simulink/Continuous/PID Controller', ...
    [model '/PID Controller'], ...
    'P', num2str(Kp), ...
    'I', num2str(Ki), ...
    'D', num2str(Kd), ...
    'Position', [305 225 335 255]);

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


% Error → PID
add_line(model, 'Sum/1', 'PID Controller/1', 'autorouting', 'on')


% PID → planta
add_line(model, 'PID Controller/1', 'Planta1/1', 'autorouting', 'on');


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