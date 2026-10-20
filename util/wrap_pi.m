% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function a = wrap_pi(a)
%WRAP_PI  Wrap angle(s) to (-pi, pi].
a = atan2(sin(a), cos(a));
end
