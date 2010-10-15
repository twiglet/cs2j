using System;
using System.Text;
namespace cs2j
{
	public static class TypeHelper
	{

		public static string buildTypeName(Type t) {
			StringBuilder typeName = new StringBuilder();
			if (t.IsGenericType) {
				typeName.Append(t.GetGenericTypeDefinition().FullName + "[");
				foreach(Type a in t.GetGenericArguments()) {
					typeName.Append(buildTypeName(a) + ",");
				}
				typeName.Remove(typeName.Length - 1,1);
				typeName.Append("]");
			}
			else {
				typeName.Append(t.FullName);
			}
			return typeName.ToString();
		}
	}
}

