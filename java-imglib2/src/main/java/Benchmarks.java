package benchmarks;

import java.io.*;

import ij.ImageJ;
//import ij.ImagePlus;
// import ij.io.Opener;

import io.scif.img.IO;
import io.scif.img.ImgIOException;

import net.imglib2.Cursor;

import net.imglib2.img.ImagePlusAdapter;
import net.imglib2.img.Img;
// import net.imglib2.img.display.imagej.ImageJFunctions;
import net.imglib2.type.Type;

// import io.scif.config.SCIFIOConfig;
// import io.scif.config.SCIFIOConfig.ImgMode;
// import io.scif.img.ImgIOException;
import io.scif.img.ImgOpener;


// import net.imglib2.img.array.ArrayImgFactory;
// import net.imglib2.img.display.imagej.ImageJFunctions;
import net.imglib2.type.NativeType;
import net.imglib2.type.numeric.NumericType;
// import net.imglib2.type.numeric.integer.UnsignedByteType;
//import net.imglib2.img.planar.PlanarCursor;
// import net.imglib2.img.array.ArrayCursor;

public class Benchmarks
{
    // within this method we define <T> to be a NumericType (depends on the type of ImagePlus)
    // you might want to define it as RealType if you know it cannot be an ImageJ RGB Color image
    public < T extends NumericType< T > & NativeType< T > > Benchmarks(String workdir, String outName) throws java.io.IOException
    {
        File outFile = new File(outName);
        FileOutputStream ostream = new FileOutputStream(outFile);
        BufferedOutputStream bos = new BufferedOutputStream(ostream);
        myPrintln(bos, "Benchmark,File,Time(s)");
        File workDir = new File(workdir);
        File filesList[] = workDir.listFiles();
        ImgOpener imgOpener = new ImgOpener();
        for (File file : filesList) {
            // open a file with ImageJ
            Img< T > img = ( Img< T > ) imgOpener.openImgs( file.getAbsolutePath() ).get(0);
            int niter = 16;
            long startTime = System.nanoTime();
            for (int i = 0; i < niter; i++) {
                invertArrayImage(img);
            }
            long endTime = System.nanoTime();

            myPrintln(bos, "complement,"+removeExtension(file.getName())+","+String.valueOf((double)(endTime-startTime)/(niter*100000000)));
        }
        bos.close();
        System.out.println("All benchmarks completed");
    }

    private < T extends NumericType< T > & NativeType< T > > Img<T> invertArrayImage(final Img<T> input) {
        Img< T > output = input.factory().create( input );
        Cursor<T> cursorInput  = input.cursor();
        Cursor<T> cursorOutput = output.cursor();
        while (cursorInput.hasNext()) {
            cursorInput.fwd();
            cursorOutput.fwd();
            T val = cursorInput.get();
            cursorOutput.get().set(val);
            // cursorOutput.get().set(T.MAX_VALUE - val);
            // cursorOutput.get().set(val.getClass().MAX_VALUE - val);
        }
        return output;
    }

    public static String removeExtension(String fname) {
        int pos = fname.lastIndexOf('.');
        if(pos > -1)
           return fname.substring(0, pos);
        else
           return fname;
     }

    public static void myPrintln(BufferedOutputStream bos, String str) throws java.io.IOException {
        byte[] bytes = str.getBytes();
        bos.write(bytes);
        bos.write('\n');
    }

    public static void main( String[] args ) throws java.io.IOException
    {
        // open an ImageJ window
        new ImageJ();

        System.out.println(args);

        // run the benchmarks
        new Benchmarks(args[0], args[1]);
    }
}
