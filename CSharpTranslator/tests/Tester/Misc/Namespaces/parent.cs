using System;

// Test translation for lock statements

namespace Tester.Parent
{

public class ParentClass {
    
    private int loc = 0;
       
    
    public ParentClass(int val)
    {
        loc = val;
    }

    public int GetLoc()
    {
        return loc;
    }

    public override int GetHashCode(){
        return 5;
    }

    private class ChildOne {
        public int COloc = 0;
        private class ChildChildOne
        {
            public ChildChildOne() { }

            public ChildOne p = new ChildOne();
            public ParentClass gp = new ParentClass(4);
        }
    }


}

}
