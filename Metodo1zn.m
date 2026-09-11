% Metodo 1 de Ziegler-Nichols.
function [Kp, Ti, Td, G] = Metodo1zn(tipo, fuente, datos, s)

    tipo = upper(string(tipo));
    fuente = upper(string(fuente));

    fprintf('METODO 1: CURVA DE REACCION\n')

    G = [];

    if fuente == "GRAFICA"

        K = datos.K;
        L = datos.L;
        P = datos.P;

        validarPositivo(K, 'K')
        validarPositivo(L, 'L')
        validarPositivo(P, 'P')

        fprintf('Se utilizaran los valores de la grafica:\n\n')
        fprintf('K = %.8g\n', K)
        fprintf('L = %.8g\n', L)
        fprintf('P = %.8g\n', P)

    elseif fuente == "FUNCION"

        G = sym2tfM1(datos.G_sym, s);

        fprintf('Funcion de transferencia recibida:\n\n')
        G

        [K, L, P, detalle] = obtenerKLP(G);

        imprimirObtencionKLP(K, L, P, detalle)

    else

        error('La fuente debe ser "GRAFICA" o "FUNCION".')
    end

    %% APLICAR LA TABLA

    relacion = P/(K*L);

    switch tipo

        case "P"

            Kp = relacion;
            Ti = inf;
            Td = 0;

        case "PI"

            Kp = 0.9*relacion;
            Ti = L/0.3;
            Td = 0;

        case "PID"

            Kp = 1.2*relacion;
            Ti = 2*L;
            Td = 0.5*L;

        otherwise

            error('El controlador debe ser "P", "PI" o "PID".')
    end

    %% MOSTRAR EL PROCEDIMIENTO

    fprintf('PROCEDIMIENTO PASO A PASO: METODO 1\n')

    fprintf('Datos utilizados:\n\n')
    fprintf('K = %.8g\n', K)
    fprintf('L = %.8g\n', L)
    fprintf('P = %.8g\n\n', P)

    fprintf('Relacion comun:\n\n')
    fprintf('P/(K*L)\n')
    fprintf('= %.8g/(%.8g*%.8g)\n', P, K, L)
    fprintf('= %.8g\n\n', relacion)

    switch tipo

        case "P"

            fprintf('De la tabla para controlador P:\n\n')

            fprintf('Kp = P/(K*L)\n')
            fprintf('Kp = %.8g/(%.8g*%.8g)\n', P, K, L)
            fprintf('Kp = %.8g\n\n', Kp)

            fprintf('Ti = infinito\n')
            fprintf('Td = 0\n')

        case "PI"

            fprintf('De la tabla para controlador PI:\n\n')

            fprintf('Kp = 0.9*P/(K*L)\n')
            fprintf('Kp = 0.9*(%.8g/(%.8g*%.8g))\n', ...
                P, K, L)
            fprintf('Kp = %.8g\n\n', Kp)

            fprintf('Ti = L/0.3\n')
            fprintf('Ti = %.8g/0.3\n', L)
            fprintf('Ti = %.8g\n\n', Ti)

            fprintf('Td = 0\n')

        case "PID"

            fprintf('De la tabla para controlador PID:\n\n')

            fprintf('Kp = 1.2*P/(K*L)\n')
            fprintf('Kp = 1.2*(%.8g/(%.8g*%.8g))\n', ...
                P, K, L)
            fprintf('Kp = %.8g\n\n', Kp)

            fprintf('Ti = 2*L\n')
            fprintf('Ti = 2*%.8g\n', L)
            fprintf('Ti = %.8g\n\n', Ti)

            fprintf('Td = 0.5*L\n')
            fprintf('Td = 0.5*%.8g\n', L)
            fprintf('Td = %.8g\n', Td)
    end
end


%% FUNCIONES LOCALES

function [K, L, P, detalle] = obtenerKLP(G)

    if ~issiso(G)
        error('El sistema debe ser SISO.')
    end

    if ~isstable(G)
        error('El metodo 1 requiere una planta estable.')
    end

    K = dcgain(G);

    validarPositivo(K, 'K')

    try
        info = stepinfo(G);
        tEstablecimiento = info.SettlingTime;
    catch
        tEstablecimiento = NaN;
    end

    if isfinite(tEstablecimiento) && tEstablecimiento > 0
        tFinal = 2*tEstablecimiento;
    else
        tFinal = 20;
    end

    t = linspace(0, tFinal, 6000);

    [y, t] = step(G, t);

    y = real(squeeze(y));
    t = squeeze(t);

    yInicial = y(1);
    yFinal = K;

    dy = gradient(y, t);

    [~, indice] = max(abs(dy));

    m = dy(indice);
    ti = t(indice);
    yi = y(indice);

    if ~isfinite(m) || abs(m) < eps
        error('No se encontro una pendiente maxima valida.')
    end

    L = ti + (yInicial - yi)/m;

    tInterseccionFinal = ti + (yFinal - yi)/m;

    P = tInterseccionFinal - L;

    if L <= 0 || P <= 0

        error(['No se obtuvieron valores positivos de L y P. ' ...
               'Utiliza la opcion GRAFICA.'])
    end

    detalle.m = m;
    detalle.ti = ti;
    detalle.yi = yi;
    detalle.yInicial = yInicial;
    detalle.yFinal = yFinal;
    detalle.tInterseccionFinal = tInterseccionFinal;

    %% GRAFICA

    yTangente = m*(t - ti) + yi;

    figure

    plot(t, y, 'b', 'LineWidth', 2)
    hold on

    plot(t, yTangente, 'r--', 'LineWidth', 1.5)

    yline(yFinal, 'k--', 'Valor final')
    xline(L, 'm--', 'L', 'LineWidth', 1.5)
    xline(L + P, 'g--', 'L + P', 'LineWidth', 1.5)

    plot(ti, yi, 'ko', ...
        'MarkerFaceColor', 'y', ...
        'MarkerSize', 7)

    grid on
    title('Obtencion de K, L y P')
    xlabel('Tiempo')
    ylabel('Salida')

    legend( ...
        'Respuesta al escalon', ...
        'Recta tangente', ...
        'Valor final', ...
        'L', ...
        'L + P', ...
        'Pendiente maxima', ...
        'Location', 'best')

    hold off
end


function imprimirObtencionKLP(K, L, P, detalle)

    fprintf('OBTENCION AUTOMATICA DE K, L Y P\n')

    fprintf('1. Ganancia del proceso:\n')
    fprintf('K = %.8g\n\n', K)

    fprintf('2. Punto de pendiente maxima:\n')
    fprintf('ti = %.8g\n', detalle.ti)
    fprintf('yi = %.8g\n', detalle.yi)
    fprintf('m = %.8g\n\n', detalle.m)

    fprintf('3. Recta tangente:\n')
    fprintf('y(t) = m*(t - ti) + yi\n')

    fprintf('y(t) = %.8g*(t - %.8g) + %.8g\n\n', ...
        detalle.m, detalle.ti, detalle.yi)

    fprintf('4. Tiempo muerto aparente:\n')
    fprintf('L = ti + (y_inicial - yi)/m\n')

    fprintf('L = %.8g + (%.8g - %.8g)/%.8g\n', ...
        detalle.ti, detalle.yInicial, ...
        detalle.yi, detalle.m)

    fprintf('L = %.8g\n\n', L)

    fprintf('5. Interseccion con el valor final:\n')
    fprintf('t_final = ti + (y_final - yi)/m\n')

    fprintf('t_final = %.8g\n\n', ...
        detalle.tInterseccionFinal)

    fprintf('6. Constante de tiempo aparente:\n')
    fprintf('P = t_final - L\n')

    fprintf('P = %.8g - %.8g\n', ...
        detalle.tInterseccionFinal, L)

    fprintf('P = %.8g\n', P)
end


function sys = sym2tfM1(G_sym, s)
% Convierte una expresion simbolica en una funcion de transferencia.
%
% Tambien detecta retardos de la forma:
%
%       exp(-L*s)
%
% Ejemplo:
%
%       exp(-1.5*s)/(s^2 + 3*s + 2)
%
% se convierte en:
%
%       1
% -----------------  con InputDelay = 1.5
% s^2 + 3*s + 2

    G_sym = simplify(G_sym);

    %% BUSCAR UN RETARDO EXPONENCIAL

    terminosExp = findSymType(G_sym, 'exp');

    retardo = 0;
    G_racional = G_sym;

    if ~isempty(terminosExp)

        if numel(terminosExp) > 1

            error(['Se encontro mas de un termino exponencial. ' ...
                   'El programa solamente admite un retardo ' ...
                   'de la forma exp(-L*s).'])
        end

        terminoRetardo = terminosExp(1);

        % Para exp(-L*s):
        %
        % diff(exp(-L*s),s)/exp(-L*s) = -L

        coeficienteExponente = simplify( ...
            diff(terminoRetardo, s)/terminoRetardo);

        % El coeficiente debe ser constante y no depender de s.
        if has(coeficienteExponente, s)

            error(['El termino exponencial debe tener la forma ' ...
                   'exp(-L*s), donde L es constante.'])
        end

        retardo_sym = simplify(-coeficienteExponente);

        try
            retardo = double(retardo_sym);
        catch
            error('El tiempo de retardo debe ser un valor numerico.')
        end

        if ~isscalar(retardo) || ~isreal(retardo) || ...
                ~isfinite(retardo) || retardo < 0

            error('El tiempo de retardo debe ser real y no negativo.')
        end

        % Eliminar el retardo para conservar solamente
        % la parte racional.
        G_racional = simplify(G_sym/terminoRetardo);

        fprintf('\nRetardo detectado en G(s):\n')
        fprintf('L_retardo = %.8g segundos\n\n', retardo)
    end

    %% SEPARAR NUMERADOR Y DENOMINADOR

    [num_sym, den_sym] = numden(G_racional);

    num_sym = expand(num_sym);
    den_sym = expand(den_sym);

    %% CONVERTIR LOS POLINOMIOS

    try

        % sym2poly solo recibe un argumento.
        num_coeffs = double(sym2poly(num_sym));
        den_coeffs = double(sym2poly(den_sym));

    catch

        error(['No se pudo convertir la parte racional de G(s). ' ...
               'El numerador y el denominador deben ser ' ...
               'polinomios numericos en s.'])
    end

    %% CREAR LA FUNCION DE TRANSFERENCIA

    sys = minreal(tf(num_coeffs, den_coeffs));

    % Agregar el retardo puro al objeto tf.
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