using System;

// Test translation for lock statements

namespace Tester.Hash
{

public class A {
    
    public override int GetHashCode(){
        return 5;
    }

}

public class B {
    
    public void fred(){
        A tmp = new A();
	int x = tmp.GetHashCode();
    }

}

}
