from skimage.feature import corner_harris, corner_shi_tomasi, corner_kitchen_rosenfeld, corner_fast

def run_imcorner_harris(img):
    return corner_harris(img)

def run_imcorner_shi_tomasi(img):
    return corner_shi_tomasi(img)

def run_imcorner_kr(img):
    return corner_kitchen_rosenfeld(img)

def run_imcorner_fastcorners(img):
    return corner_fast(img)