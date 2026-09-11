% Metodo 2 de Ziegler-Nichols.
function [Kp, Ti, Td, G] = Metodo2zn(tipo, fuente, datos, s)

    tipo = upper(string(tipo));
    fuente = upper(string(fuente));

    fprintf('METODO 2: GANANCIA CRITICA\n')

    G = [];

    if fuente == "GRAFICA"

        Kcr = datos.Kcr;

        validarPositivo(Kcr, 'Kcr')

        modoPeriodo = upper(string(datos.modoPeriodo));

        if modoPeriodo == "DIRECTO"

            Pcr = datos.Pcr;

            validarPositivo(Pcr, 'Pcr')

            fprintf('El periodo critico fue introducido directamente.\n\n')

        elseif modoPeriodo == "DOS PICOS"

            t1 = datos.tPico1;
            t2 = datos.tPico2;

            if ~isfinite(t1) || ~isfinite(t2) || t2 <= t1

                error(['Los tiempos deben ser finitos y debe ' ...
                       'cumplirse tPico2 > tPico1.'])
            end

            Pcr = t2 - t1;

            fprintf('Calculo del periodo con dos picos:\n\n')
            fprintf('Pcr = t2 - t1\n')
            fprintf('Pcr = %.8g - %.8g\n', t2, t1)
            fprintf('Pcr = %.8g\n\n', Pcr)

        else

            error(['modoPeriodo debe ser "DIRECTO" ' ...
                   'o "DOS PICOS".'])
        end

        fprintf('Valores obtenidos de la grafica:\n\n')
        fprintf('Kcr = %.8g\n', Kcr)
        fprintf('Pcr = %.8g\n', Pcr)

    elseif fuente == "FUNCION"

        G = sym2tfM2(datos.G_sym, s);

        fprintf('Funcion de transferencia recibida:\n\n')
        G

        figure
        margin(G)
        grid on
        title('Margenes de estabilidad de G(s)')

        [Gm, ~, Wcg, ~] = margin(G);

        if isempty(Gm) || isempty(Wcg) || ...
                ~isfinite(Gm) || ~isfinite(Wcg) || ...
                Gm <= 0 || Wcg <= 0

            error(['No se encontro una ganancia critica finita. ' ...
                   'Utiliza la opcion GRAFICA.'])
        end

        Kcr = Gm;
        Wcr = Wcg;
        Pcr = 2*pi/Wcr;

        fprintf('OBTENCION DE Kcr Y Pcr\n')

        fprintf('1. Frecuencia critica:\n')
        fprintf('Wcr = %.8g rad/s\n\n', Wcr)

        fprintf('2. Ganancia critica:\n')
        fprintf('Kcr = margen de ganancia\n')
        fprintf('Kcr = %.8g\n\n', Kcr)

        fprintf('3. Periodo critico:\n')
        fprintf('Pcr = 2*pi/Wcr\n')
        fprintf('Pcr = 2*pi/%.8g\n', Wcr)
        fprintf('Pcr = %.8g\n', Pcr)

    else

        error('La fuente debe ser "GRAFICA" o "FUNCION".')
    end

    %% APLICAR LA TABLA

    switch tipo

        case "P"

            Kp = 0.5*Kcr;
            Ti = inf;
            Td = 0;

        case "PI"

            Kp = 0.45*Kcr;
            Ti = Pcr/1.2;
            Td = 0;

        case "PID"

            Kp = 0.6*Kcr;
            Ti = 0.5*Pcr;
            Td = 0.125*Pcr;

        otherwise

            error('El controlador debe ser "P", "PI" o "PID".')
    end

    %% MOSTRAR EL PROCEDIMIENTO

    fprintf('PROCEDIMIENTO PASO A PASO: METODO 2\n')

    fprintf('Datos utilizados:\n\n')
    fprintf('Kcr = %.8g\n', Kcr)
    fprintf('Pcr = %.8g\n\n', Pcr)

    switch tipo

        case "P"

            fprintf('De la tabla para controlador P:\n\n')

            fprintf('Kp = 0.5*Kcr\n')
            fprintf('Kp = 0.5*%.8g\n', Kcr)
            fprintf('Kp = %.8g\n\n', Kp)

            fprintf('Ti = infinito\n')
            fprintf('Td = 0\n')

        case "PI"

            fprintf('De la tabla para controlador PI:\n\n')

            fprintf('Kp = 0.45*Kcr\n')
            fprintf('Kp = 0.45*%.8g\n', Kcr)
            fprintf('Kp = %.8g\n\n', Kp)

            fprintf('Ti = Pcr/1.2\n')
            fprintf('Ti = %.8g/1.2\n', Pcr)
            fprintf('Ti = %.8g\n\n', Ti)

            fprintf('Td = 0\n')

        case "PID"

            fprintf('De la tabla para controlador PID:\n\n')

            fprintf('Kp = 0.6*Kcr\n')
            fprintf('Kp = 0.6*%.8g\n', Kcr)
            fprintf('Kp = %.8g\n\n', Kp)

            fprintf('Ti = 0.5*Pcr\n')
            fprintf('Ti = 0.5*%.8g\n', Pcr)
            fprintf('Ti = %.8g\n\n', Ti)

            fprintf('Td = 0.125*Pcr\n')
            fprintf('Td = 0.125*%.8g\n', Pcr)
            fprintf('Td = %.8g\n', Td)
    end
end


%% FUNCIONES LOCALES

function sys = sym2tfM2(G_sym, s)
% Convierte una expresion simbolica en una funcion de transferencia.
% Tambien admite un retardo de la forma exp(-L*s).

    G_sym = simplify(G_sym);

    %% BUSCAR EL RETARDO

    terminosExp = findSymType(G_sym, 'exp');

    retardo = 0;
    G_racional = G_sym;

    if ~isempty(terminosExp)

        if numel(terminosExp) > 1

            error(['Se encontro mas de un termino exponencial. ' ...
                   'Solo se admite un retardo exp(-L*s).'])
        end

        terminoRetardo = terminosExp(1);

        coeficienteExponente = simplify( ...
            diff(terminoRetardo, s)/terminoRetardo);

        if has(coeficienteExponente, s)

            error(['El termino exponencial debe tener la forma ' ...
                   'exp(-L*s), con L constante.'])
        end

        retardo_sym = simplify(-coeficienteExponente);

        try
            retardo = double(retardo_sym);
        catch
            error('El tiempo de retardo debe ser numerico.')
        end

        if ~isscalar(retardo) || ~isreal(retardo) || ...
                ~isfinite(retardo) || retardo < 0

            error('El tiempo de retardo debe ser real y no negativo.')
        end

        G_racional = simplify(G_sym/terminoRetardo);

        fprintf('\nRetardo detectado en G(s):\n')
        fprintf('L_retardo = %.8g segundos\n\n', retardo)
    end

    %% SEPARAR NUMERADOR Y DENOMINADOR

    [num_sym, den_sym] = numden(G_racional);

    num_sym = expand(num_sym);
    den_sym = expand(den_sym);

    %% CONVERTIR A COEFICIENTES

    try

        num_coeffs = double(sym2poly(num_sym));
        den_coeffs = double(sym2poly(den_sym));

    catch

        error(['No se pudo convertir la parte racional de G(s). ' ...
               'El numerador y el denominador deben ser ' ...
               'polinomios numericos en s.'])
    end

    %% CREAR LA FUNCION DE TRANSFERENCIA

    sys = minreal(tf(num_coeffs, den_coeffs));

    if retardo > 0
        sys.InputDelay = retardo;
    end
end


function validarPositivo(valor, nombre)

    if ~(isnumeric(valor) && isscalar(valor) && ...
            isreal(valor) && isfinite(valor) && valor > 0)

        error('%s debe ser un numero real mayor que cero.', nombre)
    end
end