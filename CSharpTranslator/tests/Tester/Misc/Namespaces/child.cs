using System;

// Test translation for lock statements

namespace Tester.Parent.Child
{

    public class ChildClass
    {

        private ParentClass myp = null;


        public ChildClass(int val)
        {
            myp = new ParentClass(val);
	    int tmp = myp.GetHashCode();
        }

    }

}
