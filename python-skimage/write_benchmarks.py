def write_benchmarks(filename, bench):
    with open(filename, "w") as io:
        io.write("Benchmark,File,Time(s)\n")
        for (b, d) in bench.items():
            for (f, t) in d.items():
                io.write(b)
                io.write(',')
                io.write(f)
                io.write(',')
                io.write(str(t))
                io.write('\n')
