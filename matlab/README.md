# Obtaining Matlab

Matlab requires a license obtainable from The Mathworks.

# Running the Matlab benchmarks

Launch Matlab, navigate to this folder, and then

```
>> tg = time_generics('/tmp/imgbench');

>> write_benchmarks('matlab_generics.csv', tg)

>> ts = time_special('/tmp/imgbench_special', '.tif');

>> write_benchmarks2deep('matlab_special.csv', ts)
```
