# Installing Python libraries

You need to install both Python and [scikit-image](https://scikit-image.org/).

# Running the Python benchmarks

From inside this folder, launch IPython and then

```
In [1]: from benchmarks import *

In [2]: tg = time_generics("/tmp/imgbench");
Timing generic operations:  12%|████████████████▋                          | 5/42 [03:25<25:06, 40.70s/it]

In [3]: from write_benchmarks import *

In [4]: write_benchmarks("python_generics.csv", tg)

In [5]: ts = time_special("/tmp/imgbench_special");

In [6]: write_special_benchmarks("python_special.csv", ts)
```

The progress bar will keep you up-to-date about how far the suite has gotten. (Each task is run multiple times, so it can take many minutes.)
