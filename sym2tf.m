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