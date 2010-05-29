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

package RusticiSoftware.System.Collections;

import java.util.*;

public class ArrayListSupport extends AbstractCollection implements List {

	private ArrayList al = null;

	public ArrayListSupport() {
		al = new ArrayList();
	}

	public ArrayListSupport(int size) {
		al = new ArrayList(size);
	}

	public ArrayListSupport(Object[] a) {
		al = new ArrayList(Arrays.asList(a));
	}

	public ArrayListSupport(java.util.Collection c) {
		al = new ArrayList(c);
	}
	
	public ArrayList getArrayList() {
		return al;
	}
	
	public void setArrayList(ArrayList a) {
		al = a;
	}
	
	// Return Type clashes with add from AbstractList 	
	public int addS(Object o)
	{
		al.add(o);
		return al.size()-2;		
	}
	
	// Return Type clashes with addAll from AbstractList 
	public void addAllS(Collection c)
	{
		al.addAll(c);		
	}

	// Return Type clashes with addAll from AbstractList 
	public void addAll(Object[] a)
	{
		al.addAll(Arrays.asList(a));		
	}

	public void clear()
	{
		al.clear();
	}
		
	public boolean contains(Object o)
	{
		return al.contains(o);
	}
		
	public <T> T[] toArrayS(T[] dummy)
	{
		return (T[]) al.toArray(dummy);
	}
	
	public int[] toArrayS(int[] dummy)
	{
		int idx = 0;
		int[] arrayInt = new int[al.size()];
		for(int v : (ArrayList<Integer>)al)
		   arrayInt[idx++] = v;
		return arrayInt;
	}

	public Object[] toArray()
	{
		return  al.toArray();
	}

	public Iterator iterator() {
		return al.iterator();
	}
	
	public void set___idx(int i, Object v)
	{
		al.set(i, v);
	}

	public Object get(int index) {
		return al.get(index);
	}

	public int size() {
		return al.size();
	}

	public void sort() {
		Collections.sort(al);
	}
//	public Collection toCollection() {
//		return al;
//	}

	
	public void add(int arg0, Object arg1) {
		al.add(arg0, arg1);
	}

	public boolean add(Object arg1) {
		return al.add(arg1);
	}

	
	public boolean addAll(int arg0, Collection arg1) {
		return al.addAll(arg0, arg1);
	}

	
	public int indexOf(Object arg0) {
		return al.indexOf(arg0);
	}

	
	public int lastIndexOf(Object arg0) {
		return al.lastIndexOf(arg0);
	}

	
	public ListIterator listIterator() {
		return al.listIterator();
	}

	
	public ListIterator listIterator(int arg0) {
		return al.listIterator(arg0);
	}

	public Object remove(int arg0) {
		return al.remove(arg0);
	}
	// remove el from this list if it is here
	public void removeS(Object el) {
		al.removeAll(Arrays.asList(new Object[] {el}));
	}

	
	public Object set(int arg0, Object arg1) {
		return al.set(arg0, arg1);
	}

	
	public List subList(int arg0, int arg1) {
		return al.subList(arg0, arg1);
	}
}