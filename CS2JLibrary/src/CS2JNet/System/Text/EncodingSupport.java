package CS2JNet.System.Text;

import java.io.UnsupportedEncodingException;
import java.nio.charset.Charset;

public class EncodingSupport {

	private String coding = "utf-8";
	public EncodingSupport(String coding) {
		this.coding = coding;
	}
	
	public byte[] getBytes(String input) throws UnsupportedEncodingException {
		return input.getBytes(coding);
	}

	public String getString() {
		return coding;
	}
	
	public Charset getCharset() {
		return Charset.forName(coding);
	}
	
	public static EncodingSupport GetEncoder(String coding) {
		return new EncodingSupport(coding);
	}
}
