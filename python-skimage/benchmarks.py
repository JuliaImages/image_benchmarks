import skimage
from skimage import io
from skimage import filters
from skimage import exposure
import numpy as np
import timeit
import os
from tqdm import tqdm

nrep = 16

def setup_mean(img):
    return np.repeat(img.reshape((1, *img.shape)), 5, axis=0)
def run_mean(imgr):
    return np.mean(imgr, axis=0)

def run_gradient(img):
    return (skimage.filters.sobel(img, axis=0), skimage.filters.sobel(img, axis=1))

def run_blur(img):
    return skimage.filters.gaussian(img, 5, multichannel=True)  # channel_axis=img.ndim-1)

def run_histeq(img):
    if img.shape[-1] == 3:   # not-very-robust signal of a color image
        imgyiq = skimage.color.rgb2yiq(img)
        # 2 spatial dimensions only, FIXME?
        imgyiq[:,:,0] = skimage.exposure.equalize_hist(imgyiq[:,:,0], nbins = 256)
        return skimage.color.yiq2rgb(imgyiq)
    else:
        return skimage.exposure.equalize_hist(img, nbins = 256)

def time_generics(workdir):
    tasks = {task:{} for task in ["complement", "mean", "gradient", "blur", "histeq"]}
    for fn in tqdm(os.listdir(workdir), desc="Timing generic operations: "):
        img = io.imread(os.path.join(workdir, fn))
        tasks["complement"][fn] = min(timeit.repeat(f'skimage.util.invert(img)', number=1, repeat=nrep, globals={"img": img, "skimage":skimage}))
        tasks["mean"][fn] = min(timeit.repeat(f'run_mean(imgr)', f'imgr = setup_mean(img)', number=1, repeat=nrep, globals={"img": img, "setup_mean":setup_mean, "run_mean":run_mean}))
        tasks["gradient"][fn] = min(timeit.repeat(f'run_gradient(img)', number=1, repeat=nrep, globals={"img": img, "run_gradient":run_gradient}))
        tasks["blur"][fn] = min(timeit.repeat(f'run_blur(img)', number=1, repeat=nrep, globals={"img": img, "run_blur":run_blur}))
        tasks["histeq"][fn] = min(timeit.repeat(f'run_histeq(img)', number=1, repeat=nrep, globals={"img": img, "run_histeq":run_histeq}))
    return tasks

# time_generics("/tmp/imgs")
