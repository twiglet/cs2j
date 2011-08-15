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

import CS2JNet.System.NotImplementedException;

/**
 * @author keving
 *
 */
public class GroupCollection {

	private Match match = null;
	
	public static GroupCollection mk(Match m) {
		GroupCollection ret = new GroupCollection();
		ret.match = m;
		return ret;
	}

	/***
	 * 
	 * @param i
	 * @return
	 */
	public Group get(int i) {
		Group ret = new Group();
		ret.setMatch(this.match);
		ret.setIndex(i);
		return ret;
	}

	/***
	 * 
	 * @param name
	 * @return
	 * @throws NotImplementedException 
	 */
	public Group get(String name) throws NotImplementedException {
		throw new NotImplementedException("CS2J: No implementation for named groups in regular expressions");
	}
}
