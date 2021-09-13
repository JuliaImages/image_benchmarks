import skimage
from skimage import io
from skimage import filters
from skimage import exposure
import numpy as np
import timeit
import os
from tqdm import tqdm

nrep = 16

def run_complement(img):
    skimage.util.invert(img)

def setup_mean(img):
    return np.repeat(img.reshape((1, *img.shape)), 5, axis=0)
def run_mean(imgr):
    return np.mean(imgr, axis=0)

def run_gradient(img):
    return (skimage.filters.sobel(img, axis=0), skimage.filters.sobel(img, axis=1))

def run_blur(img):
    return skimage.filters.gaussian(img, 5, truncate=2, multichannel=True)  # channel_axis=img.ndim-1)

def run_histeq(img):
    if img.shape[-1] == 3:   # not-very-robust signal of a color image
        imgyiq = skimage.color.rgb2yiq(img)
        # 2 spatial dimensions only, FIXME?
        imgyiq[:,:,0] = skimage.exposure.equalize_hist(imgyiq[:,:,0], nbins = 256)
        return skimage.color.yiq2rgb(imgyiq)
    else:
        return skimage.exposure.equalize_hist(img, nbins = 256)

def time_generics(workdir):
    tdata = {task:{} for task in ["complement", "mean", "gradient", "blur", "histeq"]}
    return time_generics_(tdata, workdir, tdata.keys())

def time_generics_(tdata, workdir, taskitems):
    for fn in tqdm(os.listdir(workdir), desc="Timing generic operations: "):
        img = io.imread(os.path.join(workdir, fn))
        fn, _ = os.path.splitext(fn)
        if "complement" in taskitems:
            tdata["complement"][fn] = min(timeit.repeat(f'run_complement(img)', number=1, repeat=nrep, globals={"img": img, "run_complement":run_complement}))
        if "mean" in taskitems:
            tdata["mean"][fn] = min(timeit.repeat(f'run_mean(imgr)', f'imgr = setup_mean(img)', number=1, repeat=nrep, globals={"img": img, "setup_mean":setup_mean, "run_mean":run_mean}))
        if "gradient" in taskitems:
            tdata["gradient"][fn] = min(timeit.repeat(f'run_gradient(img)', number=1, repeat=nrep, globals={"img": img, "run_gradient":run_gradient}))
        if "blur" in taskitems:
            tdata["blur"][fn] = min(timeit.repeat(f'run_blur(img)', number=1, repeat=nrep, globals={"img": img, "run_blur":run_blur}))
        if "histeq" in taskitems:
            tdata["histeq"][fn] = min(timeit.repeat(f'run_histeq(img)', number=1, repeat=nrep, globals={"img": img, "run_histeq":run_histeq}))
    return tdata

# tdata = time_generics("/tmp/imgs")
