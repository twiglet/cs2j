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

package CS2JNet.System.Globalization;

public class NumberStyles {

	public static int getAllowLeadingWhite() {
		return 1;
	}

	public static int getAllowTrailingWhite() {
		return 2;
	}

	public static int getAllowLeadingSign() {
		return 4;
	}

	public static int getAllowTrailingSign() {
		return 8;
	}

	public static int getAllowParenthesis() {
		return 0x10;
	}

	public static int getAllowDecimalPoint() {
		return 0x20;
	}

	public static int getAllowThousands() {
		return 0x40;
	}

	public static int getAllowExponent() {
		return 0x80;
	}

	public static int getAllowCurrencySymbol() {
		return 0x100;
	}

	public static int getAllowHexSpecifier() {
		return 0x200;
	}

	public static int getInteger()
	{
		return getAllowLeadingWhite() |  getAllowTrailingWhite() | getAllowLeadingSign();
	}

	public static int getHexNumber()
	{
		return getAllowLeadingWhite() |  getAllowTrailingWhite() | getAllowHexSpecifier();
	}

	public static int getAny()
	{
		return getAllowLeadingWhite() |  getAllowTrailingWhite() | getAllowLeadingSign() | getAllowTrailingSign() |
		       getAllowParenthesis() | getAllowDecimalPoint() | getAllowThousands() | getAllowExponent() |
		       getAllowCurrencySymbol();
	}


}
