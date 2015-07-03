package CS2JNet.System.IO;

import java.io.File;
import java.io.FileNotFoundException;


public class RandomAccessFile extends java.io.RandomAccessFile implements DataInOut {

	public RandomAccessFile(File file, String mode)
			throws FileNotFoundException {
		super(file, mode);
	}
	public RandomAccessFile(String file, String mode)
			throws FileNotFoundException {
		super(file, mode);
	}
	@Override
	public long length()  {
		try{
			return super.length();
		}catch(Exception ex) {return 0;}
	}
	@Override
	public void setLength(long newLength)  {
		try{
			super.setLength(newLength);
		}catch(Exception ex) {}
	}
	@Override
	public void seek(long pos)  {
		try{
			super.seek(pos);
		}catch(Exception ex) {}
	}
	public long position(){
		try{
			return super.getFilePointer();
		}catch(Exception ex) { return -1;}
	}
	@Override
	public byte[] toArray() {
		try{
			long pos = getFilePointer();
			seek(0);
			byte[] b = new byte[(int)super.length()];
			this.readFully(b);
			seek(pos);
			return b;
		}catch(Exception ex) {}
		return null;
	}
	

}
