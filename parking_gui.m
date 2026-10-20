% SPDX-License-Identifier: AGPL-3.0-or-later
% Copyright (C) 2026 masanli1
%
function varargout = parking_gui(varargin)
%PARKING_GUI  Interactive virtual-car demo for the reverse-parking pipeline.
%
%   parking_gui
%   parking_gui('slot', 5)
%   parking_gui('selftest', true)     headless snapshot test
%   parking_gui('recordtest', true)   headless full-video recording test
%
%   Controls
%     Random car      sample a feasible start pose in the aisle
%     Click to place  click a free point in the aisle to spawn the car there
%     Start demo      plan + animate the complete reverse-parking manoeuvre
%     Record / Stop   record the current run to results/*.mp4 (AVI fallback)
%     Stop / Reset    stop the playback / clear the scene
%
%   The car is drawn as a body + roof + windows + wheels + lights, and the
%   animation shows the forward approach, the staging stop, the reverse arc
%   and the final straight into the slot.

root = fileparts(mfilename('fullpath'));
addpath(genpath(root));

p = inputParser;
p.addParameter('slot', []);
p.addParameter('selftest', false);
p.addParameter('recordtest', false);
p.parse(varargin{:});
opt = p.Results;

cfg = default_config();
if ~isempty(opt.slot)
    cfg.slots.target = opt.slot;
end
cfg.vis.enabled = false;
cfg.vis.animate = false;
env = build_parking_env(cfg);

S = struct();
S.cfg       = cfg;
S.env       = env;
S.start     = [];
S.res       = [];
S.apath     = [];
S.rpath     = [];
S.stage     = [];
S.hCar      = [];
S.hTrail    = [];
S.hPaths    = [];
S.hStage    = [];
S.placeMode = false;
S.animating = false;
S.stop      = false;
S.delay     = 0.012;
S.showPath  = true;
S.recording = false;
S.recordArmed = false;
S.videoWriter = [];
S.videoFile   = '';
S.videoName   = '';
S.gui       = struct();

rng('shuffle');
build_ui();
reset_scene();

if opt.selftest
    run_selftest();
elseif opt.recordtest
    run_recordtest();
end

if nargout > 0
    varargout{1} = S.gui;
end

% =========================================================================
% UI construction
% =========================================================================
    function build_ui()
        fig = figure('Name', '自动泊车 · 倒车入库演示台', ...
            'NumberTitle', 'off', 'Color', 'w', ...
            'Position', [70 70 1280 780], ...
            'MenuBar', 'none', 'ToolBar', 'none');

        ax = axes('Parent', fig, 'Position', [0.035 0.06 0.66 0.90]);

        panel = uipanel('Parent', fig, 'Title', '控制台', ...
            'FontSize', 12, 'FontWeight', 'bold', ...
            'BackgroundColor', [0.95 0.95 0.95], ...
            'Position', [0.71 0.06 0.27 0.90]);

        uicontrol('Parent', panel, 'Style', 'text', ...
            'String', '虚拟小车 · 倒车入库', ...
            'FontSize', 12, 'FontWeight', 'bold', ...
            'BackgroundColor', [0.95 0.95 0.95], ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', 'Position', [0.06 0.945 0.88 0.035]);

        btnRandom = uicontrol('Parent', panel, 'Style', 'pushbutton', ...
            'String', '① 随机生成小车', 'FontSize', 11, ...
            'BackgroundColor', [0.20 0.65 0.32], 'ForegroundColor', 'w', ...
            'Units', 'normalized', 'Position', [0.06 0.875 0.88 0.060], ...
            'Callback', @cbRandom);

        btnPlace = uicontrol('Parent', panel, 'Style', 'pushbutton', ...
            'String', '② 点击车道放置', 'FontSize', 11, ...
            'BackgroundColor', [0.95 0.72 0.20], ...
            'Units', 'normalized', 'Position', [0.06 0.800 0.88 0.060], ...
            'Callback', @cbPlace);

        btnStart = uicontrol('Parent', panel, 'Style', 'pushbutton', ...
            'String', '③ 开始泊车演示', 'FontSize', 11, 'FontWeight', 'bold', ...
            'BackgroundColor', [0.15 0.45 0.85], 'ForegroundColor', 'w', ...
            'Units', 'normalized', 'Position', [0.06 0.715 0.88 0.065], ...
            'Callback', @cbStart);

        btnStop = uicontrol('Parent', panel, 'Style', 'pushbutton', ...
            'String', '停止', 'FontSize', 10, ...
            'BackgroundColor', [0.85 0.25 0.20], 'ForegroundColor', 'w', ...
            'Units', 'normalized', 'Position', [0.06 0.645 0.40 0.050], ...
            'Enable', 'off', 'Callback', @cbStop);

        btnRecord = uicontrol('Parent', panel, 'Style', 'pushbutton', ...
            'String', '● 录制演示', 'FontSize', 10, ...
            'BackgroundColor', [0.50 0.50 0.50], 'ForegroundColor', 'w', ...
            'Units', 'normalized', 'Position', [0.50 0.645 0.44 0.050], ...
            'Callback', @cbRecord);

        btnReset = uicontrol('Parent', panel, 'Style', 'pushbutton', ...
            'String', '重置场景', 'FontSize', 10, ...
            'Units', 'normalized', 'Position', [0.06 0.585 0.88 0.050], ...
            'Callback', @cbReset);

        uicontrol('Parent', panel, 'Style', 'text', 'String', '目标车位', ...
            'FontSize', 10, 'BackgroundColor', [0.95 0.95 0.95], ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', 'Position', [0.06 0.535 0.34 0.035]);

        ddSlot = uicontrol('Parent', panel, 'Style', 'popupmenu', ...
            'String', arrayfun(@(i) sprintf('车位 %d', i), 1:8, ...
                               'UniformOutput', false), ...
            'Value', cfg.slots.target, 'FontSize', 10, ...
            'Units', 'normalized', 'Position', [0.42 0.525 0.52 0.050], ...
            'Callback', @cbSlot);

        uicontrol('Parent', panel, 'Style', 'text', 'String', '演示速度', ...
            'FontSize', 10, 'BackgroundColor', [0.95 0.95 0.95], ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', 'Position', [0.06 0.475 0.34 0.035]);

        sldSpeed = uicontrol('Parent', panel, 'Style', 'slider', ...
            'Min', 1, 'Max', 10, 'Value', 5, ...
            'Units', 'normalized', 'Position', [0.06 0.435 0.88 0.035], ...
            'Callback', @cbSpeed);

        chkPath = uicontrol('Parent', panel, 'Style', 'checkbox', ...
            'String', '显示规划路径', 'Value', 1, 'FontSize', 10, ...
            'BackgroundColor', [0.95 0.95 0.95], ...
            'Units', 'normalized', 'Position', [0.06 0.375 0.88 0.035], ...
            'Callback', @cbPath);

        uicontrol('Parent', panel, 'Style', 'text', 'String', '运行状态', ...
            'FontSize', 10, 'FontWeight', 'bold', ...
            'BackgroundColor', [0.95 0.95 0.95], ...
            'HorizontalAlignment', 'left', ...
            'Units', 'normalized', 'Position', [0.06 0.325 0.88 0.030]);

        txtStatus = uicontrol('Parent', panel, 'Style', 'text', ...
            'String', {'就绪。',''}, 'FontSize', 9, ...
            'BackgroundColor', [0.97 0.97 0.97], ...
            'HorizontalAlignment', 'left', ...
            'FontName', 'Courier', ...
            'Units', 'normalized', 'Position', [0.06 0.05 0.88 0.245]);

        S.gui.fig       = fig;
        S.gui.ax        = ax;
        S.gui.panel     = panel;
        S.gui.btnRandom = btnRandom;
        S.gui.btnPlace  = btnPlace;
        S.gui.btnStart  = btnStart;
        S.gui.btnStop   = btnStop;
        S.gui.btnRecord = btnRecord;
        S.gui.btnReset  = btnReset;
        S.gui.ddSlot    = ddSlot;
        S.gui.sldSpeed  = sldSpeed;
        S.gui.chkPath   = chkPath;
        S.gui.txtStatus = txtStatus;

        ax.ButtonDownFcn = @cbAxesClick;
        set(fig, 'CloseRequestFcn', @cbClose);
        S.delay = 0.06 / get(sldSpeed, 'Value');
    end

% =========================================================================
% Scene / car drawing
% =========================================================================
    function reset_scene()
        if S.recording
            stop_recording();
        end
        S.recordArmed = false;
        update_record_button();

        S.start = [];
        S.res   = [];
        S.apath = [];
        S.rpath = [];
        S.stage = [];
        S.placeMode = false;
        set(S.gui.btnPlace, 'String', '② 点击车道放置', ...
            'BackgroundColor', [0.95 0.72 0.20]);

        clear_dynamic();
        cla(S.gui.ax);
        plot_environment(S.env, S.gui.ax);
        axis(S.gui.ax, 'equal');
        axis(S.gui.ax, 'tight');
        title(S.gui.ax, '选择“随机生成小车”或在车道上点击放置，然后开始泊车');
        make_axes_clickable();
        set_status({'就绪。', ...
                    '随机生成或点击车道放置一辆虚拟小车。', ...
                    '然后点击“开始泊车演示”。'});
    end

    function make_axes_clickable()
        kids = S.gui.ax.Children;
        for k = 1:numel(kids)
            try
                set(kids(k), 'PickableParts', 'none', 'HitTest', 'off');
            catch
                % Some graphics objects do not expose these properties.
            end
        end
        S.gui.ax.ButtonDownFcn = @cbAxesClick;
    end

    function clear_dynamic()
        if ~isempty(S.hCar) && isfield(S.hCar, 'group') && ...
                ishghandle(S.hCar.group)
            delete(S.hCar.group);
        end
        S.hCar = [];

        if ~isempty(S.hTrail) && all(ishghandle(S.hTrail))
            delete(S.hTrail);
        end
        S.hTrail = [];

        if ~isempty(S.hStage) && all(ishghandle(S.hStage))
            delete(S.hStage);
        end
        S.hStage = [];

        if ~isempty(S.hPaths)
            good = ishghandle(S.hPaths);
            if any(good), delete(S.hPaths(good)); end
        end
        S.hPaths = [];
    end

    function draw_paths()
        if ~S.showPath || isempty(S.apath)
            return;
        end
        h1 = plot(S.gui.ax, S.apath.P(1,:), S.apath.P(2,:), ...
            'b-', 'LineWidth', 1.4);
        h2 = plot(S.gui.ax, S.rpath.P(1,:), S.rpath.P(2,:), ...
            'r--', 'LineWidth', 1.4);
        h3 = plot(S.gui.ax, S.stage(1), S.stage(2), 'mp', ...
            'MarkerSize', 12, 'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'k');
        set([h1 h2 h3], 'PickableParts', 'none', 'HitTest', 'off');
        S.hPaths = [h1 h2 h3];
    end

    function draw_current()
        clear_dynamic();
        if isempty(S.start)
            return;
        end

        draw_paths();

        S.hTrail = plot(S.gui.ax, NaN, NaN, 'c-', 'LineWidth', 2.2);
        set(S.hTrail, 'PickableParts', 'none', 'HitTest', 'off');

        S.hCar = create_virtual_car(S.gui.ax, S.start, S.cfg.veh);

        title(S.gui.ax, sprintf('起点 [%.1f, %.1f, %.0f°]  →  点击“开始泊车演示”', ...
            S.start(1), S.start(2), rad2deg(S.start(3))));
    end

    function ok = set_start(start)
        ok = false;
        start = start(:);

        ap = plan_approach(S.env, start, S.cfg);
        if ~ap.ok
            set_status({'无法从该位置规划前进段。', ap.msg});
            return;
        end

        rp = plan_reverse_path(S.env, ap.stage, ap.R, S.cfg);
        if ~rp.ok
            set_status({'无法生成倒车路径。', rp.msg});
            return;
        end

        S.start = start;
        S.apath = ap.path;
        S.rpath = rp.path;
        S.stage = ap.stage;
        S.res   = [];
        draw_current();

        set_status({'小车已就位。', ...
                    sprintf('起点   : [%.2f, %.2f, %.1f°]', ...
                        start(1), start(2), rad2deg(start(3))), ...
                    sprintf('Staging: [%.2f, %.2f, %.1f°]', ...
                        ap.stage(1), ap.stage(2), rad2deg(ap.stage(3))), ...
                    sprintf('倒车半径: %.2f m', ap.R), ...
                    '', '点击“开始泊车演示”。'});
        ok = true;
    end

% =========================================================================
% Callbacks
% =========================================================================
    function cbRandom(~, ~)
        if S.animating, return; end
        generate_random();
    end

    function generate_random()
        try
            c = make_case(S.env, S.cfg);
        catch err
            set_status({'随机生成失败。', err.message});
            return;
        end
        if set_start(c.start)
            % set_start already updates the status.
            drawnow;
        end
    end

    function cbPlace(~, ~)
        if S.animating, return; end
        S.placeMode = ~S.placeMode;
        if S.placeMode
            set(S.gui.btnPlace, 'String', '点击车道放置中…', ...
                'BackgroundColor', [0.95 0.50 0.10]);
            set_status({'放置模式已开启。', ...
                        '在车道空白处单击，生成一辆虚拟小车。', ...
                        '再次点击按钮可取消。'});
        else
            set(S.gui.btnPlace, 'String', '② 点击车道放置', ...
                'BackgroundColor', [0.95 0.72 0.20]);
            set_status({'已取消放置模式。'});
        end
    end

    function cbAxesClick(~, ~)
        if ~S.placeMode || S.animating
            return;
        end
        pt = S.gui.ax.CurrentPoint;
        pt = pt(1, 1:2);

        [start, ok, msg] = click_to_start(S.env, S.cfg, pt);
        if ~ok
            set_status({'放置失败。', msg, ...
                        '请换一个更靠近车道中部的位置。'});
            return;
        end

        S.placeMode = false;
        set(S.gui.btnPlace, 'String', '② 点击车道放置', ...
            'BackgroundColor', [0.95 0.72 0.20]);
        set_start(start);
    end

    function cbStart(~, ~)
        if S.animating, return; end
        if isempty(S.start)
            generate_random();
            if isempty(S.start), return; end
        end
        run_demo(false);
    end

    function cbStop(~, ~)
        S.stop = true;
        set_status({'正在停止演示…'});
    end

    function cbReset(~, ~)
        if S.animating, return; end
        reset_scene();
    end

    function cbSlot(~, ~)
        if S.animating, return; end
        v = get(S.gui.ddSlot, 'Value');
        S.cfg.slots.target = v;
        S.env = build_parking_env(S.cfg);
        reset_scene();
        set_status({sprintf('目标车位已切换为 %d。', v), ...
                    '请重新生成一辆小车。'});
    end

    function cbSpeed(~, ~)
        v = get(S.gui.sldSpeed, 'Value');
        S.delay = 0.06 / max(1, v);
    end

    function cbPath(~, ~)
        if S.animating
            set(S.gui.chkPath, 'Value', double(S.showPath));
            return;
        end
        S.showPath = logical(get(S.gui.chkPath, 'Value'));
        if ~isempty(S.start)
            draw_current();
        end
    end

% =========================================================================
% Recording
% =========================================================================
    function cbRecord(~, ~)
        if S.recording
            f = S.videoFile;
            stop_recording();
            set_status({'录制已停止。', ['视频: ' f]});
        elseif S.animating
            start_recording();
            if S.recording
                set_status({'● 正在录制当前演示…', ['保存到: ' S.videoFile]});
            end
        else
            S.recordArmed = ~S.recordArmed;
            update_record_button();
            if S.recordArmed
                set_status({'录制已准备。', ...
                            '下次点击“开始泊车演示”会自动录制。'});
            else
                set_status({'录制已取消。'});
            end
        end
    end

    function start_recording()
        if S.recording
            return;
        end

        if ~exist('results', 'dir'), mkdir('results'); end

        if ~isempty(S.videoName)
            fname = fullfile('results', S.videoName);
        else
            fname = fullfile('results', ...
                ['parking_demo_' char(datetime('now', 'Format', 'yyyyMMdd_HHmmss')) '.mp4']);
        end

        vw = [];
        try
            vw = VideoWriter(fname, 'MPEG-4');
            vw.FrameRate = 20;
            vw.Quality   = 90;
            open(vw);
        catch
            if ~isempty(vw)
                try
                    close(vw);
                catch
                    % Writer may not have opened successfully.
                end
            end
            fname = [fname(1:end-4) '.avi'];
            try
                vw = VideoWriter(fname, 'Motion JPEG AVI');
                vw.FrameRate = 20;
                open(vw);
            catch err
                set_status({'无法创建录制文件。', err.message});
                S.recording = false;
                S.videoWriter = [];
                update_record_button();
                return;
            end
        end

        S.videoWriter = vw;
        S.videoFile   = fname;
        S.recording   = true;
        S.recordArmed = false;
        update_record_button();
    end

    function stop_recording()
        if isempty(S.videoWriter) && ~S.recording
            return;
        end
        try
            if ~isempty(S.videoWriter)
                close(S.videoWriter);
            end
        catch
            % The writer may already be closed after an error.
        end
        S.videoWriter = [];
        S.recording   = false;
        update_record_button();
    end

    function update_record_button()
        if ~isfield(S.gui, 'btnRecord') || isempty(S.gui.btnRecord) || ...
                ~ishghandle(S.gui.btnRecord)
            return;
        end
        if S.recording
            set(S.gui.btnRecord, 'String', '■ 停止录制', ...
                'BackgroundColor', [0.85 0.10 0.10], 'Enable', 'on');
        elseif S.recordArmed
            set(S.gui.btnRecord, 'String', '● 已准备录制', ...
                'BackgroundColor', [0.90 0.55 0.10], 'Enable', 'on');
        else
            set(S.gui.btnRecord, 'String', '● 录制演示', ...
                'BackgroundColor', [0.50 0.50 0.50], 'Enable', 'on');
        end
    end

    function write_video_frame()
        if ~S.recording || isempty(S.videoWriter) || ...
                ~ishghandle(S.gui.fig)
            return;
        end
        try
            fr = getframe(S.gui.fig);
            img = fr.cdata;
            if mod(size(img,1), 2) ~= 0
                img = img(1:end-1, :, :);
            end
            if mod(size(img,2), 2) ~= 0
                img = img(:, 1:end-1, :);
            end
            writeVideo(S.videoWriter, img);
        catch err
            stop_recording();
            set_status({'录制中断。', err.message});
        end
    end

    function cbClose(~, ~)
        if S.recording
            stop_recording();
        end
        delete(S.gui.fig);
    end

% =========================================================================
% Simulation + playback
% =========================================================================
    function run_demo(snapshotOnly)
        set_status({'正在计算轨迹…'});
        drawnow;

        res = run_parking_sim(S.env, S.start, S.cfg, ...
            struct('keep_traj', true, 'verbose', false));

        if ~res.plan_ok
            S.recordArmed = false;
            update_record_button();
            set_status({'规划失败。', res.msg});
            return;
        end
        S.res = res;
        S.videoFile = '';
        if ~snapshotOnly && S.recordArmed && ~S.recording
            start_recording();
        end

        % Fresh trail line.
        if ~isempty(S.hTrail) && all(ishghandle(S.hTrail))
            delete(S.hTrail);
        end
        S.hTrail = plot(S.gui.ax, NaN, NaN, 'c-', 'LineWidth', 2.2);
        set(S.hTrail, 'PickableParts', 'none', 'HitTest', 'off');

        n = size(res.traj, 2);

        if snapshotOnly
            k = max(2, round(0.55 * n));
            update_virtual_car(S.hCar, res.traj(:,k), S.cfg.veh);
            set(S.hTrail, 'XData', res.traj(1,1:k), 'YData', res.traj(2,1:k));
            title(S.gui.ax, sprintf('虚拟小车演示 | %s | 进度 %.0f%%', ...
                res.states{k}, 100*k/n));
            set_status({'倒车入库演示快照。', ...
                        sprintf('当前状态: %s', res.states{k}), ...
                        sprintf('仿真进度: %.0f%%', 100*k/n)});
            drawnow;

            if ~exist('results', 'dir'), mkdir('results'); end
            fname = fullfile('results', 'gui_preview.png');
            frame = getframe(S.gui.fig);
            imwrite(frame.cdata, fname);
            set_status({'GUI 自检快照已保存。', fname});
            return;
        end

        S.animating = true;
        S.stop      = false;
        disable_controls(true);
        if S.recording
            set_status({'● 正在录制本次演示…', ...
                        ['保存到: ' S.videoFile]});
        else
            set_status({'正在演示倒车入库…'});
        end

        stopped = false;
        frame_step = max(1, round(n / 350));
        for k = 1:frame_step:n
            if ~ishghandle(S.gui.fig)
                break;
            end
            if S.stop
                stopped = true;
                break;
            end
            update_virtual_car(S.hCar, res.traj(:,k), S.cfg.veh);
            set(S.hTrail, 'XData', res.traj(1,1:k), 'YData', res.traj(2,1:k));
            recTag = '';
            if S.recording
                recTag = '  ● REC';
            end
            title(S.gui.ax, sprintf('虚拟小车 | %s | 进度 %.0f%%%s', ...
                res.states{k}, 100*k/n, recTag));
            drawnow;
            write_video_frame();
            pause(S.delay);
        end

        if ~stopped && ~isempty(S.hCar) && ishghandle(S.hCar.group) && ...
                ishghandle(S.hTrail)
            update_virtual_car(S.hCar, res.traj(:,n), S.cfg.veh);
            set(S.hTrail, 'XData', res.traj(1,:), 'YData', res.traj(2,:));
            title(S.gui.ax, sprintf('泊车完成 | 误差 %.2f m / %.2f°', ...
                res.pos_err, rad2deg(res.head_err)));
            if S.recording
                write_video_frame();
            end
        end

        recorded = S.videoFile;
        if S.recording
            stop_recording();
        end

        S.animating = false;
        S.stop      = false;
        disable_controls(false);

        if stopped
            lines = {'演示已停止。', '小车停在当前帧，未继续播放。'};
            if ~isempty(recorded) && exist(recorded, 'file') == 2
                lines{end+1} = ['视频: ' recorded];
            end
            set_status(lines);
            return;
        end

        if res.success
            lines = {'✅ 倒车入库完成。', ...
                     sprintf('位置误差: %.3f m', res.pos_err), ...
                     sprintf('航向误差: %.2f°', rad2deg(res.head_err)), ...
                     sprintf('仿真时长: %.1f s', res.time), ...
                     sprintf('换挡次数: %d', res.gear_changes)};
        else
            lines = {'⚠ 未成功完成。', res.msg, ...
                     sprintf('位置误差: %.3f m', res.pos_err), ...
                     sprintf('航向误差: %.2f°', rad2deg(res.head_err))};
        end
        if ~isempty(recorded) && exist(recorded, 'file') == 2
            lines{end+1} = ['视频: ' recorded];
        end
        set_status(lines);
    end

    function disable_controls(tf)
        if tf
            state = 'off';
            stopState = 'on';
        else
            state = 'on';
            stopState = 'off';
        end
        set([S.gui.btnRandom, S.gui.btnPlace, S.gui.btnStart, ...
             S.gui.btnReset, S.gui.ddSlot, S.gui.chkPath], 'Enable', state);
        set(S.gui.btnStop, 'Enable', stopState);
    end

    function set_status(lines)
        if ischar(lines)
            lines = {lines};
        end
        set(S.gui.txtStatus, 'String', lines);
        drawnow limitrate;
    end

% =========================================================================
% Self test
% =========================================================================
    function run_selftest()
        set(S.gui.fig, 'Visible', 'off');
        ok = set_start([3.0; 6.5; 0.0; 0.0]);
        if ~ok
            error('parking_gui:selftest', 'selftest could not set the start pose');
        end
        run_demo(true);
        if isempty(S.res) || ~S.res.success
            error('parking_gui:selftest', 'selftest simulation failed');
        end
        fprintf('GUI selftest passed: pos=%.3f m, head=%.2f deg\n', ...
            S.res.pos_err, rad2deg(S.res.head_err));
        close(S.gui.fig);
    end

    function run_recordtest()
        set(S.gui.fig, 'Visible', 'off');
        S.videoName   = 'gui_demo_recording.mp4';
        S.recordArmed = true;
        update_record_button();

        ok = set_start([3.0; 6.5; 0.0; 0.0]);
        if ~ok
            error('parking_gui:recordtest', 'recordtest could not set the start pose');
        end

        run_demo(false);

        if isempty(S.videoFile) || exist(S.videoFile, 'file') ~= 2
            error('parking_gui:recordtest', 'no video file was written');
        end
        info = dir(S.videoFile);
        if info.bytes < 1000
            error('parking_gui:recordtest', 'video file is suspiciously small');
        end

        S.gui.videoFile = S.videoFile;
        fprintf('GUI recording test passed: %s (%.1f KB)\n', ...
            S.videoFile, info.bytes / 1024);
        close(S.gui.fig);
    end
end
