package benchmarks;

import ij.ImageJ;
import ij.ImagePlus;
import ij.io.Opener;

import java.io.File;

import io.scif.config.SCIFIOConfig;
import io.scif.config.SCIFIOConfig.ImgMode;
import io.scif.img.ImgIOException;
import io.scif.img.ImgOpener;

import net.imglib2.img.ImagePlusAdapter;
import net.imglib2.img.Img;
import net.imglib2.img.array.ArrayImgFactory;
import net.imglib2.img.display.imagej.ImageJFunctions;
import net.imglib2.type.NativeType;
import net.imglib2.type.numeric.NumericType;
import net.imglib2.type.numeric.integer.UnsignedByteType;
//import net.imglib2.img.planar.PlanarCursor;
import net.imglib2.img.array.ArrayCursor;

public class Benchmarks
{
    // within this method we define <T> to be a NumericType (depends on the type of ImagePlus)
    // you might want to define it as RealType if you know it cannot be an ImageJ RGB Color image
    public Benchmarks(String workdir)
    {
        File workDir = new File(workdir);
        File filesList[] = workDir.listFiles();
        ImgOpener imgOpener = new ImgOpener();
        for (File file : filesList) {
            // open a file with ImageJ
            Img< UnsignedByteType > img = ( Img< UnsignedByteType > ) imgOpener.openImgs( file.getAbsolutePath() ).get(0);
            int niter = 16;
            long startTime = System.nanoTime();
            for (int i = 0; i < niter; i++) {
                invertArrayImage(img);
            }
            long endTime = System.nanoTime();
            System.out.println("Invert, "+file+String.valueOf((double)(endTime-startTime)/(niter*1000000))+"ms");
        }
    }

    private void invertArrayImage(final Img<UnsignedByteType> img) {
        //private void invertArrayImage(final Img<T extends NumericType< T > & NativeType< T > img) {
          final ArrayCursor<UnsignedByteType> c =
            (ArrayCursor<UnsignedByteType>) img.cursor();
        while (c.hasNext()) {
            final UnsignedByteType t = c.next();
            final int value = t.get();
            final int result = 255 - value;
            t.set(result);
        }
    }

    public static void main( String[] args )
    {
        // open an ImageJ window
        new ImageJ();

        System.out.println(args);

        // run the benchmarks
        new Benchmarks(args[0]);
    }
}
