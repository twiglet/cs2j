package CS2JNet.System.Net.Mail;

import java.util.ArrayList;
import javax.mail.internet.InternetAddress;

public class MailMessage 
{

    public MailMessage() throws Exception
    {
        _bcc = new ArrayList();
        _cc = new ArrayList();
        _to = new ArrayList();
    }
    private ArrayList _bcc;
    private ArrayList _cc;
    private ArrayList _to;
    private String _body;
    private InternetAddress _from;
    private String _subject;

    public ArrayList getBcc() throws Exception
    {
        return _bcc;
    }

    public ArrayList getCC() throws Exception
    {
        return _cc;
    }

    public ArrayList getTo() throws Exception
    {
        return _to;
    }

    public String getBody() throws Exception
    {
        return _body;
    }

    public void setBody(String value) throws Exception
    {
        _body = value;
    }

    public InternetAddress getFrom() throws Exception
    {
        return _from;
    }

    public void setFrom(InternetAddress value) throws Exception
    {
        _from = value;
    }

    public String getSubject() throws Exception
    {
        return _subject;
    }

    public void setSubject(String value) throws Exception
    {
        _subject = value;
    }
}
