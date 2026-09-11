clc; clear; close all;

% ==================== 0. Configuracion ====================
type = "PID"
syms s Kp Ki Kd real

% ==================== 1. Planta y constantes ====================
% G_s se escribe en vez de s+1/s*(s+1) es (s+1)/(s*(s+1))
%===============================================================
G_s = 4/(s^2+3.6*s+9)
Mp = -1;    % pon -1 si no lo tienes
Ts = 3;
damping = 0.5;   % pon -1 si no lo tienes y se calcula con Mp
wn = -1;

[Mp, Ts, damping, wn, xi] = parametrosSegundoOrden(Mp, Ts, damping, wn);

switch type
    case "P"
        Gc_s = Kp;
    case "PD"
        Gc_s = Kp + Kd*s;
    case "PI"
        Gc_s = Kp + Ki/s;
    case "PID"
        Gc_s = Kp + Ki/s + Kd*s;
    otherwise
        error('Tipo de controlador no soportado: %s', type);
end

disp('Gc(s) = '); pretty(Gc_s)

%% ==================== 2. FT en lazo cerrado ====================
H_s = (Gc_s*G_s)/(1+Gc_s*G_s)
H_s = simplify(H_s);
[H_s_num, H_s_den] = numden(H_s);
Pc_s = H_s_den;

disp('H(s) = '); pretty(H_s)
disp('Pc(s) = '); disp(Pc_s)

%% ==================== 3. Polinomio deseado a partir de Mp/Ts ====================

s1 = -xi*wn + 1i*wn*sqrt(1-xi^2)
s2 = -xi*wn - 1i*wn*sqrt(1-xi^2)
Pd_s = s^2 + 2*xi*wn*s + wn^2;
fprintf("=================================================\n");

%% ==================== 4. Igualar ordenes (agregar polos extra si hace falta) ====================
n_real = polynomialDegree(Pc_s, s)
n_deseado = polynomialDegree(Pd_s, s)

if n_real > n_deseado
    sigma = abs(real(s1));  
    p_extra = -10*sigma;   % regla practica: 10 veces mas lejos
    fprintf('Se agrega polo extra en %.4f (sistema de orden %d vs deseado %d)\n', p_extra, n_real, n_deseado);
    Pd_s = expand((s - p_extra)*Pd_s);
end

disp('Pd(s) final = '); disp(vpa(Pd_s,4))

%% ==================== 5. Igualar coeficientes y resolver ====================
coeffs_c = coeffs(Pc_s, s);
Pc_s = expand(Pc_s / coeffs_c(end));

coeffs_d = coeffs(Pd_s, s);
Pd_s = expand(Pd_s / coeffs_d(end));

coeffs_c = vpa(coeffs(Pc_s, s), 4)
coeffs_d = vpa(coeffs(Pd_s, s), 4)

switch type
    case "P"
        incognitas = [Kp];
    case "PD"
        incognitas = [Kp, Kd];
    case "PI"
        incognitas = [Kp, Ki];
    case "PID"
        incognitas = [Kp, Ki, Kd];
end

ecuaciones = coeffs_c(1:end) == coeffs_d(1:end);  

for k = 1:length(ecuaciones)
    disp(ecuaciones(k))
fprintf("=================\n");
end
sol = solve(ecuaciones, incognitas);

for i = 1:length(incognitas)

    fprintf("=================\n");
    val = double(sol.(char(incognitas(i))));
    fprintf('%s = %.4f\n', char(incognitas(i)), val);
    fprintf("=================\n");
end

%% ==================== 6. Verificacion: armar H final y ver polos ====================
switch type
    case "P"
        H_final = subs(H_s, Kp, double(sol.Kp));
    case "PD"
        H_final = subs(H_s, [Kp, Kd], [double(sol.Kp), double(sol.Kd)]);
    case "PI"
        H_final = subs(H_s, [Kp, Ki], [double(sol.Kp), double(sol.Ki)]);
    case "PID"
        H_final = subs(H_s, [Kp, Ki, Kd], [double(sol.Kp), double(sol.Ki), double(sol.Kd)]);
end

H_final = simplify(H_final);
[N_final, D_final] = numden(H_final);
num = sym2poly(N_final);
den = sym2poly(D_final);

H_final_tf = tf(num, den)

mostrarPolos(H_final_tf);


%% ==================== FUNCIONES ====================

function [Mp, ts, damping, wn, xi] = parametrosSegundoOrden(Mp, ts, damping, wn)
if damping < 0
    if Mp > 0 && Mp < 1
        xi = sqrt((log(Mp)^2) / (pi^2 + log(Mp)^2));
        damping = xi;
        fprintf('Damping calculado a partir de Mp = %.4f\n', damping);
    else
        error('Para calcular damping, Mp debe estar entre 0 y 1.');
    end
else
    xi = damping;
    fprintf('Se usa el damping dado por el usuario = %.4f\n', xi);
end

if wn < 0
    if ts > 0
        wn = 4 / (xi * ts);
        fprintf('wn calculada a partir de ts y xi = %.4f rad/s\n', wn);
    else
        error('No se puede calcular wn: se necesita ts > 0.');
    end
else
    fprintf('Se usa la wn dada por el usuario = %.4f rad/s\n', wn);
end

if ts < 0
    ts = 4 / (xi * wn);
    fprintf('ts calculado a partir de xi y wn = %.4f s\n', ts);
else
    fprintf('Se usa el ts dado por el usuario = %.4f s\n', ts);
end

if Mp < 0
    Mp = exp((-xi*pi) / sqrt(1-xi^2));
    fprintf('Mp calculado a partir de xi = %.4f (%.2f%%)\n', Mp, Mp*100);
else
    fprintf('Se usa el Mp dado por el usuario = %.4f (%.2f%%)\n', Mp, Mp*100);
end
end


function mostrarPolos(sys)
polos = pole(sys);
fprintf('\nPolos del sistema:\n');
disp(polos);
end

function sys = sym2tf(G_sym)
    % SYM2TF Convierte una expresión simbólica en s a un objeto tf.
    %
    % Ejemplo de uso:
    %   syms s
    %   G = (2*s + 1) / (s^2 + 3*s + 2);
    %   sys = sym2tf(G, s);

    % 1. Extraer numerador y denominador simbólicos
    [num_sym, den_sym] = numden(G_sym);

    % 2. Convertir las expresiones simbólicas a vectores de coeficientes
    num_coeffs = double(sym2poly(num_sym));
    den_coeffs = double(sym2poly(den_sym));

    % 3. Crear el objeto de función de transferencia
    sys = tf(num_coeffs, den_coeffs);
end

