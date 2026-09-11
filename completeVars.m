function [Wn, Xi, Mp, Ts] =  completeVars(Wnd, Xid, Mpd, Tsd)
    Wn = Wnd;
    Xi = Xid;
    Mp = Mpd;
    Ts = Tsd;

    if Wnd ~= -1 && Xi ~= -1
        % Ya tenemos lo que necesitamos
    elseif Mpd ~= -1 && Tsd ~= -1
        Xi = sqrt(log(Mpd)^2/(pi^2 + log(Mpd)^2));
        Wn = 4/(Xid * Tsd);
    elseif Mpd ~= -1 && Wnd ~= -1
        Xi = sqrt(log(Mpd)/pi^2 + log(Mpd)^2);
        Ts = 4/(Xi * Wnd);
    elseif Tsd ~= -1 && Xid ~= -1
        Wn = 4/(Xid * Tsd); 
        Mp = e^((-Xid*pi)/sqrt(1-Xid^2));

    elseif Tsd ~= -1 && Wnd ~= -1
        Xi = 4/(Wnd*Tsd);
        Mp = exp((-Xi*pi)/sqrt(1-Xi^2));
    else
        error("La combinación de variables proporcionado no  es suficiente")
    end
end