function write_benchmarks(filename, bench)
    fid = fopen(filename, 'w');
    fprintf(fid, 'Benchmark,File,Time(s)\n');
    bs = fieldnames(bench);
    for i = 1:length(bs)
        b = bs{i};
        benchtask = bench.(b);
        fs = fieldnames(benchtask);
        for j = 1:length(fs)
            f = fs{j};
            fprintf(fid, '%s,%s,%g\n', b, f, benchtask.(f));
        end
    end
    fclose(fid);
end
