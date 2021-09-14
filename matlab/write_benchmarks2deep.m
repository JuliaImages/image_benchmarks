function write_benchmarks2deep(filename, bench)
    fid = fopen(filename, 'w');
    fprintf(fid, 'Benchmark,Time(s)\n');
    bs = fieldnames(bench);
    for i = 1:length(bs)
        b = bs{i};
        t = bench.(b);
        fprintf(fid, '%s,%g\n', b, t);
    end
    fclose(fid);
end
