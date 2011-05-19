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

package CS2JNet.JavaSupport.util;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * @author keving
 *
 */
public class ListSupport {
	
	// If the sequence of elements in stretch appears in l, then returns a new list, a copy of l without
	// the final such sequence. Otherwise returns l.
	public  static <T> List<T> removeFinalStretch(List<T> l, List<T> stretch) {
		List<T> ret = l;
		boolean found = true;
		int endIdx = l.size() - 1;
		while (endIdx >= stretch.size() - 1) {
			// is this the start of a sequence of stretch?
			found = true;
			for (int j = 0; j < stretch.size(); j++) {
				if (l.get(endIdx - j) != stretch.get(stretch.size() - j - 1)) {
					found = false;
					break;
				}
			}
			if (found) {
				break;
			}
			endIdx--;
		}
		if (found) {
			// stretch starts at l(endIdx - stretch.size())
			// don't use subList, create a totally new list.
			ret = new ArrayList<T>(l.size() - stretch.size());
			for (int i = 0; i <= endIdx - stretch.size(); i++){
			    ret.add(l.get(i));
			}
			for (int i = endIdx+1; i < l.size(); i++){
			    ret.add(l.get(i));
			}
		}

		return ret;
	}
	
	public static void main(String[] args) {
		List<Integer> master = Arrays.asList(new Integer[] {0,1,2,3,4,5,1,2,3,4,5});
		List<Integer> find0 = Arrays.asList(new Integer[] {0});
		List<Integer> find1 = Arrays.asList(new Integer[] {2,3,4});
		List<Integer> find2 = Arrays.asList(new Integer[] {2,4});
		List<Integer> find3 = Arrays.asList(new Integer[] {4,5});
		
		for (int i : removeFinalStretch(master,find0)) {
			System.out.printf("%1d ",i);
		}
		System.out.println();
		for (int i : removeFinalStretch(master,find1)) {
			System.out.printf("%1d ",i);
		}
		System.out.println();
		for (int i : removeFinalStretch(master,find2)) {
			System.out.printf("%1d ",i);
		}
		System.out.println();
		for (int i : removeFinalStretch(master,find3)) {
			System.out.printf("%1d ",i);
		}
		System.out.println();
	}

}
