function tdata = time_generics(workdir)
    tdata = struct();
    fns = dir(workdir);
    for i = 1:length(fns)
        fn = fns(i);
        fn = fn.name;
        if strcmp(fn, '.') || strcmp(fn, '..')
            continue
        end
        [~, name, ~] = fileparts(fn);
        img = imread(fullfile(workdir, fn));
        
        f = @() run_complement(img);
        tdata.complement.(name) = timeit(f);
        imgr = setup_mean(img);
        f = @() run_mean(imgr);
        tdata.mean.(name) = timeit(f);
        f = @() run_gradient(img);
        tdata.gradient.(name) = timeit(f);
        f = @() run_blur(img);
        tdata.blur.(name) = timeit(f);
        f = @() run_histeq(img);
        tdata.histeq.(name) = timeit(f);
    end
end

function cimg = run_complement(img)
    cimg = imcomplement(img);
end
function imgr = setup_mean(img)
    if ismatrix(img)
        imgr = repmat(img, 1, 1, 5);
    elseif ndims(img) == 3
        imgr = repmat(img, 1, 1, 1, 5);
    else
        error('not supported');
    end
end
function imgm = run_mean(imgr)
    imgm = mean(imgr, ndims(imgr));
end
function [gx, gy] = run_gradient(img)
    if ismatrix(img)
        [gx, gy] = imgradientxy(img, 'sobel');
    elseif ndims(img) == 3
        for i = 1:3
            [gx(:, :, i), gy(:, :, i)] = imgradientxy(img(:, :, i), 'sobel');
        end
    end
end
function imgb = run_blur(img)
    imgb = imgaussfilt(img, 5);
end
function imge = run_histeq(img)
    if ismatrix(img)
        imge = histeq(img, 256);
    else
        imgntsc = rgb2ntsc(img);
        imgntsc(:,:,1) = histeq(imgntsc(:,:,1), 256);
        imge = ntsc2rgb(imgntsc);
    end
end
