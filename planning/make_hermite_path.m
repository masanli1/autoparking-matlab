% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function path = make_hermite_path(p0, p1, n)
%MAKE_HERMITE_PATH  Cubic Hermite path with position and heading endpoints.
%
%   path = make_hermite_path([x0;y0;theta0], [x1;y1;theta1], n)
%
%   The path is C1 continuous, passes exactly through both endpoints and
%   respects both headings.  It is used for the forward approach to the
%   staging pose.

if nargin < 3
    d = hypot(p1(1)-p0(1), p1(2)-p0(2));
    n = max(80, ceil(d / 0.10));
end

d  = hypot(p1(1)-p0(1), p1(2)-p0(2));
m0 = [cos(p0(3)); sin(p0(3))] * (d / 3);
m1 = [cos(p1(3)); sin(p1(3))] * (d / 3);

t = linspace(0, 1, n);
t2 = t.^2;
t3 = t2.*t;

h00 =  2*t3 - 3*t2 + 1;
h10 =    t3 - 2*t2 + t;
h01 = -2*t3 + 3*t2;
h11 =    t3 -   t2;

dh00 =  6*t2 - 6*t;
dh10 =  3*t2 - 4*t + 1;
dh01 = -6*t2 + 6*t;
dh11 =  3*t2 - 2*t;

P = h00.*p0(1:2) + h10.*m0 + h01.*p1(1:2) + h11.*m1;
dP = dh00.*p0(1:2) + dh10.*m0 + dh01.*p1(1:2) + dh11.*m1;

theta = atan2(dP(2,:), dP(1,:));
theta = unwrap(theta);
theta(1)   = p0(3);
theta(end) = p1(3);

s = [0, cumsum(hypot(diff(P(1,:)), diff(P(2,:))))];
s(end) = max(s(end), 1e-6);

kappa = gradient(theta, s);
kappa = movmean(kappa, 5);

path.P     = P;
path.theta = theta;
path.s     = s;
path.kappa = kappa;
path.n     = n;
path.ok    = true;
end
