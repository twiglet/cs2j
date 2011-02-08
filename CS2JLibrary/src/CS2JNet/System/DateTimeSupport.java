/*
   Copyright 2007-2010 Rustici Software, LLC

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

   Author(s):

   Kevin Glynn (kevin.glynn@scorm.com)
*/

package CS2JNet.System;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.Locale;

import CS2JNet.JavaSupport.util.LocaleSupport;

public class DateTimeSupport {
	
	public static String ToString(Date d, String format, Locale loc) {
		
		SimpleDateFormat formatter = null;
		if (format.equals("s")) {
			//TODO: Is this really a db-friendly sortable format?
			formatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", loc);
			//System.out.println(formatter.format(d));
		} else if (format.equals("u")) {
			formatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss'Z'", loc);
		} else if (format.equals("yyyy-MM-ddTHH:mm:ss.ffZ")) {
			formatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SS'Z'", loc);
		} else {
			formatter = new SimpleDateFormat(format, loc);
		}
		
		if (d instanceof DateTZ) {
			formatter.setTimeZone(((DateTZ)d).getTimeZone());
		}
		
		return formatter.format(d);
	}
	
	public static String ToString(Date d, String format) {
		if ("default".equals(format)) {
			SimpleDateFormat formatter = new SimpleDateFormat();
			
			if (d instanceof DateTZ) {
				formatter.setTimeZone(((DateTZ)d).getTimeZone());
			}
			return formatter.format(d);
		}
		else {
			return ToString(d, format, Locale.getDefault());
		}
	}
	
	public static String ToString(Date d) {
		return ToString(d, "default");
	}
	
	private static final String[] DATE_FORMATS = new String[] {
			"E MMM d HH:mm:ss Z yyyy", 
			"MM/dd/yyyy HH:mm:ss a", 
			"yyyy-MM-dd HH:mm:ss'Z'", 
			"yyyy-MM-dd'T'HH:mm:ss'.'SSSZ",
			"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
			"yyyy-MM-dd'T'HH:mm:ss", 
			"yyyy-MM-dd"};
	
	public static Date parse(String s) throws ParseException
	{
		String val = trimMilliSecondsToThreeDigits(s);
		return parse(val, DATE_FORMATS, Locale.getDefault());
	}
	
	protected static String trimMilliSecondsToThreeDigits(String dateString){
		String val = dateString;
		if(val != null){
			int milliStart = val.lastIndexOf(".");
			if(milliStart != -1){
				milliStart = milliStart + 1;
				int milliEnd = val.lastIndexOf("Z");
				milliEnd = (milliEnd == -1) ? val.length() : milliEnd;
				if((milliEnd - milliStart) > 3){
					String newMillis = val.substring(milliStart).substring(0, 3);
					val = val.substring(0, milliStart) + newMillis + val.substring(milliEnd, val.length());
				}
			}
		}
		return val;
	}
	
    public static Date parse(String s, String f) throws ParseException
    {
            return parse(s, new String[] {f}, Locale.getDefault());
            
    }	
	
    public static Date parse(String s, Locale loc) throws ParseException
    {
            return parse(s, DATE_FORMATS, loc);
    }

    public static Date parse(String s, String[] formats, Locale loc) throws ParseException
	{
		for (String f : formats)
		{
			try
			{
				Date d = (new SimpleDateFormat(f)).parse(s);
				// System.out.println("Date: "+ d.toString());
				return d;
			}
			catch (ParseException e)
			{
				continue;
			}
		}

		try
		{
			// check default
			Date d = (new SimpleDateFormat()).parse(s);
			// System.out.println("Date: "+ d.toString());
			return d;
		}
		catch (ParseException e)
		{
			// continue to throw exception
		}
		
		throw new ParseException("Could not parse " + s + " as a date", 0);
	}
    
    public static Date add(Date base,int field, int amount)
    {
    	Calendar cal = Calendar.getInstance();
    	cal.setTime(base);
    	cal.add(field, amount);
    	return cal.getTime();
    }

    public static boolean equals(Date d1, Date d2) {
        return d1 == d2 || (d1 != null && d2 != null && d1.getTime() == d2.getTime());
    }
    
    // null == null, but otherwise all comparisons return false
    public static boolean lessthan(Date d1, Date d2) {
        return d1 != null && d2 != null && d1.before(d2);
    }
    public static boolean lessthanorequal(Date d1, Date d2) {
        return d1 != null && d2 != null && (d1.before(d2) || equals(d1,d2));
    }

}