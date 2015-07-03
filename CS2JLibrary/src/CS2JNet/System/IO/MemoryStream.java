package CS2JNet.System.IO;

import java.io.DataOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.io.UTFDataFormatException;
import java.util.Arrays;

public class MemoryStream extends OutputStream implements DataInOut {

	protected int pos;
	protected int length;
	
	private byte[] buf;
	
	public MemoryStream() {
		this(128);
		
	}

	public MemoryStream(int size) {
		buf = new byte[size];
		length=buf.length;
	}
	
	public MemoryStream(byte[] buffer){
		buf = buffer;
		length=buf.length;
	}

	protected void ensureCapacity(int l) {
		if (l - buf.length > 0)
			grow(l);
		length=l;
	}

	protected void grow(int minCapacity) {
		int oldCapacity = buf.length;
		int newCapacity = oldCapacity << 1;
		if (newCapacity - minCapacity < 0)
			newCapacity = minCapacity;
		if (newCapacity < 0) {
			if (minCapacity < 0) // overflow
				throw new OutOfMemoryError();
			newCapacity = Integer.MAX_VALUE;
		}
		buf = Arrays.copyOf(buf, newCapacity);
	}
	@Override
	public void readFully(byte[] b) throws IOException {
		System.arraycopy(buf, pos, b, 0, length-pos > b.length ? b.length : length-pos);
		
	}

	// EOF
	@Override
	public void readFully(byte[] b, int off, int len) throws IOException {
		System.arraycopy(buf, pos, b, off, length-pos > len ? len : length-pos);
		pos = pos+len < length ? pos+len : length-1;
	}

	@Override
	public int skipBytes(int n) throws IOException {
		ensureCapacity(n+pos);
		pos+=n;
		return pos;
	}

	@Override
	public boolean readBoolean() throws IOException {
		return buf[pos++] != 0 ;
	}

	@Override
	public byte readByte() throws IOException {
		return buf[pos++];
	}

	@Override
	public int readUnsignedByte() throws IOException {
		return buf[pos++] & 0xFF;
	}

	@Override
	public short readShort() throws IOException {
		return (short)(buf[pos++] << 8 + 
					   buf[pos++] & 255);
	}

	@Override
	public int readUnsignedShort() throws IOException {
		return ((buf[pos++] & 255) << 8 + 
				buf[pos++] & 255) & 0xFFFF;
	}

	@Override
	public char readChar() throws IOException {
		return (char)(buf[pos++] << 8 + 
					  buf[pos++] & 255);
	}

	@Override
	public int readInt() throws IOException {
		return (int)((buf[pos++]) 	   << 24 + 
					 (buf[pos++] & 255)<< 16 + 
					 (buf[pos++] & 255)<< 8 + 
					 (buf[pos++] & 255));
	}

	@Override
	public long readLong() throws IOException {
		return (((long)(buf[pos++]) << 56) +
				((long)(buf[pos++] & 255) << 48) +
				((long)(buf[pos++] & 255) << 40) +
				((long)(buf[pos++] & 255) << 32) +
				((long)(buf[pos++] & 255) << 24) + 
				(buf[pos++] & 255)<< 16  + 
				(buf[pos++] & 255)<<  8  + 
				(buf[pos++] & 255));
	}

	@Override
	public float readFloat() throws IOException {
		return Float.intBitsToFloat(readInt());
	}

	@Override
	public double readDouble() throws IOException {
		return Double.longBitsToDouble(readLong());
		
	}

	@Override
	public String readLine() throws IOException {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public String readUTF() throws IOException {
		int utflen = readUnsignedShort();
		byte[] bytearr = new byte[utflen];
		char[] chararr = new char[utflen];
		
		int c, char2, char3;
		int count = 0;
		int chararr_count=0;

		readFully(bytearr, 0, utflen); // Ensure cap first maybe ...

		while (count < utflen) {
			c = (int) bytearr[count] & 0xff;
			if (c > 127) break;
			count++;
			chararr[chararr_count++]=(char)c;
		}

		while (count < utflen) {
			c = (int) bytearr[count] & 0xff;
			switch (c >> 4) {
			case 0: case 1: case 2: case 3: case 4: case 5: case 6: case 7:
				/* 0xxxxxxx*/
				count++;
				chararr[chararr_count++]=(char)c;
				break;
			case 12: case 13:
				/* 110x xxxx   10xx xxxx*/
				count += 2;
				if (count > utflen)
					throw new UTFDataFormatException(
							"malformed input: partial character at end");
				char2 = (int) bytearr[count-1];
				if ((char2 & 0xC0) != 0x80)
					throw new UTFDataFormatException(
							"malformed input around byte " + count);
				chararr[chararr_count++]=(char)(((c & 0x1F) << 6) |
						(char2 & 0x3F));
				break;
			case 14:
				/* 1110 xxxx  10xx xxxx  10xx xxxx */
				count += 3;
				if (count > utflen)
					throw new UTFDataFormatException(
							"malformed input: partial character at end");
				char2 = (int) bytearr[count-2];
				char3 = (int) bytearr[count-1];
				if (((char2 & 0xC0) != 0x80) || ((char3 & 0xC0) != 0x80))
					throw new UTFDataFormatException(
							"malformed input around byte " + (count-1));
				chararr[chararr_count++]=(char)(((c     & 0x0F) << 12) |
						((char2 & 0x3F) << 6)  |
						((char3 & 0x3F) << 0));
				break;
			default:
				/* 10xx xxxx,  1111 xxxx */
				throw new UTFDataFormatException(
						"malformed input around byte " + count);
			}
		}
		// The number of chars produced may be less than utflen
		return new String(chararr, 0, chararr_count);
	}

	@Override
	public void writeBoolean(boolean v) throws IOException {
		ensureCapacity(pos+1);
		buf[pos++] =(byte) (v?1:0);
		
	}

	@Override
	public void writeByte(int v) throws IOException {
		ensureCapacity(pos+1);
		buf[pos++]=(byte)v;
		
	}

	@Override
	public void writeShort(int v) throws IOException {
		ensureCapacity(pos+2);
		buf[pos++]=(byte) ((v >>> 8) & 0xFF);
		buf[pos++]=(byte) ((v >>> 0) & 0xFF);
	}

	@Override
	public void writeChar(int v) throws IOException {
		ensureCapacity(pos+2);
		buf[pos++]=(byte) ((v >>> 8) & 0xFF);
		buf[pos++]=(byte) ((v >>> 0) & 0xFF);
	}

	@Override
	public void writeInt(int v) throws IOException {
		ensureCapacity(pos+4);
		buf[pos++]=(byte) ((v >>> 24) & 0xFF);
		buf[pos++]=(byte) ((v >>> 16) & 0xFF);
		buf[pos++]=(byte) ((v >>>  8) & 0xFF);
		buf[pos++]=(byte) ((v >>>  0) & 0xFF);
	}

	@Override
	public void writeLong(long v) throws IOException {
		ensureCapacity(pos+8);
		buf[pos++]=(byte) (v >>> 56);
		buf[pos++]=(byte) (v >>> 48);
		buf[pos++]=(byte) (v >>> 40);
		buf[pos++]=(byte) (v >>> 32);
		buf[pos++]=(byte) (v >>> 24);
		buf[pos++]=(byte) (v >>> 16);
		buf[pos++]=(byte) (v >>>  8);
		buf[pos++]=(byte) (v >>>  0);
	}

	@Override
	public void writeFloat(float v) throws IOException {
		writeInt(Float.floatToIntBits(v));
	}

	@Override
	public void writeDouble(double v) throws IOException {
		writeLong(Double.doubleToLongBits(v));
		
	}

	@Override
	public void writeBytes(String s) throws IOException {
		int len = s.length();
		for(int i = 0; i < len; i++){
			buf[pos++] = (byte)s.charAt(i);
		}
	}

	@Override
	public void writeChars(String s) throws IOException {
		int len = s.length();
		for(int i = 0; i < len; i++){
			int v = s.charAt(i);
			buf[pos++]=(byte) ((v >>> 8) & 0xFF);
			buf[pos++]=(byte) ((v >>> 0) & 0xFF);
		}
		
	}

	@Override
	public void writeUTF(String s) throws IOException {
		int strlen = s.length();
        int utflen = 0;
        int c;

        /* use charAt instead of copying String to char array */
        for (int i = 0; i < strlen; i++) {
            c = s.charAt(i);
            if ((c >= 0x0001) && (c <= 0x007F)) {
                utflen++;
            } else if (c > 0x07FF) {
                utflen += 3;
            } else {
                utflen += 2;
            }
        }

        if (utflen > 65535)
            throw new UTFDataFormatException(
                "encoded string too long: " + utflen + " bytes");

        buf[pos++] = (byte) ((utflen >>> 8) & 0xFF);
        buf[pos++] = (byte) ((utflen >>> 0) & 0xFF);

        int i=0;
        for (i=0; i<strlen; i++) {
           c = s.charAt(i);
           if (!((c >= 0x0001) && (c <= 0x007F))) break;
           buf[pos++] = (byte) c;
        }

        for (;i < strlen; i++){
            c = s.charAt(i);
            if ((c >= 0x0001) && (c <= 0x007F)) {
            	buf[pos++] = (byte) c;

            } else if (c > 0x07FF) {
            	buf[pos++] = (byte) (0xE0 | ((c >> 12) & 0x0F));
            	buf[pos++] = (byte) (0x80 | ((c >>  6) & 0x3F));
            	buf[pos++] = (byte) (0x80 | ((c >>  0) & 0x3F));
            } else {
            	buf[pos++] = (byte) (0xC0 | ((c >>  6) & 0x1F));
            	buf[pos++] = (byte) (0x80 | ((c >>  0) & 0x3F));
            }
        }
	}

	@Override
	public long length() {
		return length;
	}

	@Override
	public void setLength(long newLength) {
		if (newLength>Integer.MAX_VALUE) 
			length = Integer.MAX_VALUE;
		length=(int)newLength;
		ensureCapacity(length);
		
	}

	@Override
	public void seek(long pos) {
		if (pos>Integer.MAX_VALUE) 
			this.pos = Integer.MAX_VALUE;
		this.pos=(int)pos;
		
	}

	@Override
	public long position() {
		return pos;
	}

	@Override
	public void write(int b) throws IOException {
		ensureCapacity(length+1);
		buf[pos++]=(byte)b;
	}

	@Override
	public byte[] toArray() {
		if (length<buf.length)
			return Arrays.copyOf(buf, length);
		return buf;
	}
	


}
