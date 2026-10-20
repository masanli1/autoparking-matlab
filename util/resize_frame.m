% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function out = resize_frame(img, W, H)
%RESIZE_FRAME  Bilinear resize without Image Processing Toolbox.
%
%   out = resize_frame(img, W, H)
%
%   Used by the video renderer when getframe returns a canvas whose pixel
%   size differs from 1920x1080 (e.g. on a Retina display).

if size(img, 1) == H && size(img, 2) == W
    out = img;
    return;
end

[sy, sx, sc] = size(img);
xi = linspace(1, sx, W);
yi = linspace(1, sy, H);
[X, Y] = meshgrid(xi, yi);

out = zeros(H, W, sc, 'single');
for c = 1:sc
    out(:, :, c) = interp2(single(img(:, :, c)), X, Y, 'linear');
end
out = uint8(max(0, min(255, out)));
end
