package CS2JNet.System.Text;

public class StringBuilderSupport {

	// In C# ensureCapacity returns the new capacity
	public static int ensureCapacity(StringBuilder sb, int capacity) {
		sb.ensureCapacity(capacity);
		return sb.capacity();
	}
	// In C# setLength pads with spaces
	public static void setLength(StringBuilder sb, int newLen) {
		if (sb.length() >= newLen) {
			sb.setLength(newLen);
		}
		sb.append(String.format("%1$-" + (newLen - sb.length()) + "s", ""));
	}
	
	public static void main(String[] args) {
		StringBuilder sb = new StringBuilder("hello");
		System.out.println("**" + sb + "**");
		StringBuilderSupport.setLength(sb,7);
		System.out.println("**" + sb + "**");
	}
}
