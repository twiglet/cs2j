/*
   Copyright 2007,2008,2009,2010 Rustici Software, LLC
   Copyright 2010,2011 Kevin Glynn (kevin.glynn@twigletsoftware.com)

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

   Kevin Glynn (kevin.glynn@twigletsoftware.com)
*/

package CS2JNet.System;

import java.text.ParseException;

public class TimeSpan {
	
	long milliSeconds = 0;

    private static final int MSECS_PER_SECOND = 1000;
    private static final int MSECS_PER_MINUTE = 60*MSECS_PER_SECOND;
    private static final int MSECS_PER_HOUR = 60*MSECS_PER_MINUTE;
    private static final int MSECS_PER_DAY = 24*MSECS_PER_HOUR;

	public TimeSpan(long ms)
	{
		milliSeconds = ms;
	}
	
	public double getTotalSeconds()
	{
		return (milliSeconds / MSECS_PER_SECOND);
	}
	
	public static TimeSpan parse(String s) throws ParseException
	{
		int days = 0;
		int hours = 0;
		int minutes = 0;
		int seconds = 0;
		int msecs = 0;
		
		int sign = 1;
		
		// [ws][-]{ d | [d.]hh:mm[:ss[.ff]] }[ws]
		
		String toParse = StringSupport.Trim(s);;
		
		if (toParse.charAt(0) == '-')
		{
			sign = -1;
			toParse = toParse.substring(1);
		}
		
		if (toParse.indexOf(":") < 0 )
		{
			// just number of days
			days = Integer.parseInt(toParse);
		}
		else
		{
			throw new ParseException("Unparseable date: \"" + s + "\"", 0);
		}
		
		long ms = sign * (msecs + (seconds * MSECS_PER_SECOND) 
				           + (minutes * MSECS_PER_MINUTE)
				           + (hours * MSECS_PER_HOUR)
				           + (days * MSECS_PER_DAY));
		
		return new TimeSpan(ms);
		
		//
			
	}

}
