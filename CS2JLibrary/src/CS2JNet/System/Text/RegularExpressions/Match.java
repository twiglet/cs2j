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

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * @author keving
 *
 */
public class Match {

	private Matcher matcher = null;
	private boolean lastMatchSuccess = false;
	private int lastMatchStartIdx = 0;
	private int lastMatchLength = 0;
	
	private String input = "";
	private Pattern pat = null;
	
	/**
	 * @return the matcher
	 */
	public Matcher getMatcher() {
		return matcher;
	}
	/**
	 * @param matcher the matcher to set
	 */
	public void setMatcher(Matcher matcher) {
		this.matcher = matcher;
	}
	
	/**
	 * @return the string matched by the last match
	 */
	public String getValue() {
		return matcher.group();
	}
	
	/**
	 * @return the string matched by the last match
	 */
	public boolean getSuccess() {
		return lastMatchSuccess;
	}
	
	/**
	 * @return the length of string matched by the last match
	 */
	public int length() {
		return lastMatchLength;
	}
	
	/**
	 * @return the start index of string matched by the last match
	 */
	public int start() {
		return lastMatchStartIdx;
	}
	
	public Match nextMatch() {
		return mk(this.pat, this.input, 
				this.lastMatchLength == 0 ? this.lastMatchStartIdx + 1 : this.lastMatchStartIdx + this.lastMatchLength);	
	}
	
	public static Match mk(Pattern pat, String input, int startat) {
		Match ret = new Match();
		ret.pat = pat;
		ret.input = input;
		ret.matcher = pat.matcher(input);
		ret.lastMatchSuccess = ret.matcher.find(startat);
		if (ret.lastMatchSuccess) {
			ret.lastMatchStartIdx = ret.matcher.start();
			ret.lastMatchLength = ret.matcher.end() -ret.matcher.start(); 
		}
		return ret;
	}
	
	public static Match mk(Pattern pat, String input) {	
		return mk(pat, input, 0);
	}

	public static List<Match> mkMatches(Pattern pat, String input) {	
		List<Match> ret = new ArrayList<Match>();
		Match m = mk(pat, input);
		while (m.getSuccess()) {
			ret.add(m);
			m = m.nextMatch();
		}
		return ret;
	}


}
