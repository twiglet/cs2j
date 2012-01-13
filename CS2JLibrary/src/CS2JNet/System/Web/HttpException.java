package CS2JNet.System.Web;

public class HttpException extends Exception {
	private int httpCode = -1;
	public int GetHttpCode(){
		return httpCode;
	}
	
	public HttpException(int httpCode, String message){
		super(message);
		this.httpCode = httpCode;
	}
}
