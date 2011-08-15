/*
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

package CS2JNet.System.Text.RegularExpressions;

import java.util.regex.Matcher;

/**
 * @author keving
 *
 */
public class Group {

	private Match match = null;
	private int index = -1;
	/**
	 * @return the matcher
	 */
	public Match getMatch() {
		return match;
	}
	/**
	 * @param matcher the matcher to set
	 */
	public void setMatch(Match match) {
		this.match = match;
	}
	/**
	 * @return the index
	 */
	public int getIndex() {
		return index;
	}
	/**
	 * @param index the index to set
	 */
	public void setIndex(int index) {
		this.index = index;
	}
	
	/**
	 * @return the string matched by group
	 * If index is default then the whole match, else the group(index)
	 */
	public String getValue() {
		return (index >= 0 ? match.getMatcher().group(index) : match.getMatcher().group());
	}


}
