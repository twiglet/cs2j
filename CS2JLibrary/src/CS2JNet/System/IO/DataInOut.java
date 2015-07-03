package CS2JNet.System.IO;

import java.io.DataInput;
import java.io.DataOutput;

public interface DataInOut extends DataInput, DataOutput {
	public long length();
	public void setLength(long newLength);
	public void seek(long pos);
	public long position();
	public byte[] toArray();
}
