package CS2JNet.System.Net.Mail;

import javax.mail.internet.InternetAddress;

import CS2JNet.System.Collections.ArrayListSupport;

public class MailMessage 
{

    public MailMessage() throws Exception
    {
        _bcc = new ArrayListSupport();
        _cc = new ArrayListSupport();
        _to = new ArrayListSupport();
    }
    private ArrayListSupport _bcc;
    private ArrayListSupport _cc;
    private ArrayListSupport _to;
    private String _body;
    private InternetAddress _from;
    private String _subject;

    public ArrayListSupport getBcc() throws Exception
    {
        return _bcc;
    }

    public ArrayListSupport getCC() throws Exception
    {
        return _cc;
    }

    public ArrayListSupport getTo() throws Exception
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
