package CS2JNet.System.Text;

import java.io.UnsupportedEncodingException;

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
}
