function tdata = time_special(workdir, ext)
    tdata = struct();
    fls = {'components2d', 'components3d'};
    for i = 1:length(fls)
        fn = fls{i};
        img = imreadall(fullfile(workdir, [fn, ext]));
        f = @() run_label(img);
        try
            tdata.(fn) = timeit(f);
        catch
            tdata.(fn) = nan;
        end
    end
    fls = {'dblcone2d', 'dblcone3d'};
    for i = 1:length(fls)
        fn = fls{i};
        img = imreadall(fullfile(workdir, [fn, ext]));
        f = @() run_disttform(img);
        tdata.(fn) = timeit(f);
    end
    fls = {'spiral2d', 'spiral3d'};
    for i = 1:length(fls)
        fn = fls{i};
        img = imreadall(fullfile(workdir, [fn, ext]));
        imgb = img >= 127;
        f = @() run_flood(imgb);
        tdata.(fn) = timeit(f);
    end
end

function img = imreadall(fn)
    info = imfinfo(fn);
    if length(info) == 1
        img = imread(fn);
    else
        for i = 1:length(info)
            img(:,:,i) = imread(fn, i);
        end
    end
end

function c = run_label(img)
    c = bwlabel(img);
end

function [d, idx] = run_disttform(img)
    [d, idx] = bwdist(img);  % for comparability also extract the location
end

function f = run_flood(img)
    middle = round(size(img) / 2);
    f = imfill(img, middle);
end
