/*
   Copyright 2010-2013 Kevin Glynn (kevin.glynn@twigletsoftware.com)
   Copyright 2007-2013 Rustici Software, LLC

This program is free software: you can redistribute it and/or modify
it under the terms of the MIT/X Window System License

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

You should have received a copy of the MIT/X Window System License
along with this program.  If not, see 

   <http://www.opensource.org/licenses/mit-license>
*/

using System;
using System.Text;
namespace Twiglet.CS2J.Utility.Utils
{
	public static class TypeHelper
	{

		public static string buildTypeName(Type t) {
			StringBuilder typeName = new StringBuilder();
			if (t.IsGenericType) {
				typeName.Append(t.GetGenericTypeDefinition().FullName + "[");
				foreach(Type a in t.GetGenericArguments()) {
					if (a.IsGenericParameter) {
						typeName.Append(a.Name + ",");
					}
					else {
						typeName.Append(buildTypeName(a) + ",");
					}
				}
				typeName.Remove(typeName.Length - 1,1);
				typeName.Append("]");
			}
			else if (t.IsGenericParameter) {
				typeName.Append(t.Name);
			}
			else {
				typeName.Append(t.FullName);
			}
			return typeName.ToString();
		}
	}
}

