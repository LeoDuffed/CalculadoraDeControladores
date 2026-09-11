clc;

model = 'sistema_plantilla';

open_system(model);

blocks = find_system(model, 'Type', 'Block');

fprintf('\n========================================\n');
fprintf('          BLOQUES DEL MODELO\n');
fprintf('========================================\n\n');

for k = 1:length(blocks)

    block = blocks{k};

    fprintf('%d. %s\n', k, block);

    fprintf('   Nombre: %s\n', ...
        get_param(block, 'Name'));

    fprintf('   Tipo: %s\n', ...
        get_param(block, 'BlockType'));

    pos = get_param(block, 'Position');

    fprintf('   Posición: [%d %d %d %d]\n', pos);

    fprintf('\n');

end