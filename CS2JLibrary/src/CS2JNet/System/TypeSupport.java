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

/**
 * 
 * 
 * TODO:  This is only partially implemented.  We only need to distinguish public fields
 *  from public static fields. The matchesFlags function needs more work.
 */
package CS2JNet.System;

import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Modifier;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.Date;

import CS2JNet.System.Reflection.BindingFlags;

public class TypeSupport {

	
	private static Class mkRealClass(Class inType)
	{
		if (inType.isPrimitive()) {
			if (inType == Integer.TYPE) {
				return Integer.class;
			}
			if (inType == Boolean.TYPE) {
				return Boolean.class;
			}
			if (inType == Byte.TYPE) {
				return Byte.class;
			}
			if (inType == Short.TYPE) {
				return Short.class;
			}
			if (inType == Long.TYPE) {
				return Long.class;
			}
			if (inType == Float.TYPE) {
				return Float.class;
			}
			if (inType == Double.TYPE) {
				return Double.class;
			}
			if (inType == Character.TYPE) {
				return Character.class;
			}
		}
		return inType;
	}
	
	public static Object InvokeMember(Class type, String name, Class target, Object[] args) throws IllegalArgumentException, SecurityException, IllegalAccessException, InvocationTargetException, NoSuchMethodException, NotImplementedException, ClassNotFoundException, ParseException
	{
		// HELP! We need a meta translator :). Here we hard code the case of <Type>.Parse(str), which is all we 
		// need this method for so far
		
		if (name.equals("Parse") && args.length == 1)
		{
			// Do I really need to special case like this? Why can't everything support valueOf(String) ??
			if (type.getName().equals("java.util.Date")) {
				return DateTimeSupport.parse((String) args[0]);
			}
			return mkRealClass(type).getMethod("valueOf", Class.forName("java.lang.String")).invoke(null, args[0]);
		}
		else
		{
			throw new NotImplementedException("Tried to InvokeMember for " + name);
		}
		
	}
	private static Field[] getAllFields(Class myType, boolean inherited)
	{
		if (inherited)
		{
			return myType.getFields();
		}
		else {
			return myType.getDeclaredFields();	
		}
	}

	private static boolean matchesFlags(Field f, int flags)
	{		
		int modifiers = f.getModifiers();
		
		// Public vs NonPublic
		if (Modifier.isPublic(modifiers)) {
			// Its a public field, are we looking for that?
			if ((flags & BindingFlags.getPublic()) == 0)
				return false;
		}
		else {
			// Its not a public field, are we OK with that?
			if ((flags & BindingFlags.getNonPublic()) == 0)
				return false;
		}
		
		// Static vs Object member
		if (Modifier.isStatic(modifiers)) {
			// Its a static field, are we looking for that?
			if ((flags & BindingFlags.getStatic()) == 0)
				return false;
		}
		else {
			// Its not a static field, are we OK with that?
			if ((flags & BindingFlags.getInstance()) == 0)
				return false;
		}	
		// Phew
		return true;
	}
	
	public static Field[] GetFields(Class myType) {
		return GetFields(myType, BindingFlags.getDefault());
	}

	public static Field[] GetFields(Class myType, int flags) {
		ArrayList<Field> filteredFs = new ArrayList<Field>();
		Field[] fs = getAllFields(myType, (flags & BindingFlags.getDeclaredOnly()) == 0);
		for (Field f : fs) {
			if (matchesFlags(f, flags)) {
				filteredFs.add(f);
			}
		}
		return (Field[]) filteredFs.toArray(new Field[filteredFs.size()]);
		
	}

	public static Field GetField(Class myType, String fieldName, int flags) {

		Field f = null;
		try {
			if ((flags & BindingFlags.getDeclaredOnly()) > 0) {
				f = myType.getDeclaredField(fieldName);
			}
			else {
				f = myType.getField(fieldName);
			}
			if (f != null && matchesFlags(f,flags))
			{
				return f;
			}
			else {
				return null;
			}

		} catch (NoSuchFieldException e) {
			return null;
		}
	}

	public static Field GetField(Class myType,
			String fieldName) throws NoSuchFieldException, Exception {
		return GetField(myType, fieldName, BindingFlags.getDefault());
	}

	public static TypeCode GetTypeCode(Class myType) {
		TypeCode ret = TypeCode.Object;
		
		if (myType.isPrimitive()) {
		
			if (myType.equals(Boolean.TYPE)) {
				ret = TypeCode.Boolean;
			}	
			else if (myType.equals(Character.TYPE)) {
				ret = TypeCode.Char;
			}
			else if (myType.equals(Byte.TYPE)) {
				ret = TypeCode.Byte;
			}
			else if (myType.equals(Short.TYPE)) {
				ret = TypeCode.Int16;
			}
			else if (myType.equals(Integer.TYPE)) {
				ret = TypeCode.Int32;
			}
			else if (myType.equals(Long.TYPE)) {
				ret = TypeCode.Int64;
			}
			else if (myType.equals(Float.TYPE)) {
				ret = TypeCode.Single;
			}
			else if (myType.equals(Double.TYPE)) {
				ret = TypeCode.Double;
			}
			else if (myType.equals(Void.TYPE)) {
				// No equivalent, return object I guess
			}
		}
		else {
			if (myType.isInstance(Boolean.FALSE)) {
				ret = TypeCode.Boolean;
			}	
			else if (myType.isInstance(Character.MAX_VALUE)) {
				ret = TypeCode.Char;
			}
			else if (myType.isInstance(Byte.MAX_VALUE)) {
				ret = TypeCode.Byte;
			}
			else if (myType.isInstance(Short.MAX_VALUE)) {
				ret = TypeCode.Int16;
			}
			else if (myType.isInstance(Integer.MAX_VALUE)) {
				ret = TypeCode.Int32;
			}
			else if (myType.isInstance(Long.MAX_VALUE)) {
				ret = TypeCode.Int64;
			}
			else if (myType.isInstance(Float.MAX_VALUE)) {
				ret = TypeCode.Single;
			}
			else if (myType.isInstance(Double.MAX_VALUE)) {
				ret = TypeCode.Double;
			}
			else if (myType.isInstance(new Date())) {
				ret = TypeCode.Double;
			}
			else if (myType.isInstance("")) {
				ret = TypeCode.String;
			}
		}
		return ret;
	}
	
	public static void Testmain(String[] args)
	{
		Boolean b = true;
		int i = 0;
		System.out.println(TypeCode.Boolean);
		System.out.println(GetTypeCode(b.getClass()));
		System.out.println(GetTypeCode(((Integer)i).getClass()));
	}

}
