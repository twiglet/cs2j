/*
   Copyright 2010,2011 Kevin Glynn (kevin.glynn@twigletsoftware.com)
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

