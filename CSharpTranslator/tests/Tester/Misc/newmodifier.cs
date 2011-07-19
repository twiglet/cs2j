using System;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;

namespace Tester.NewModifier
{
class B {
       public virtual void foo() {
               Console.WriteLine("B:foo");
       }
}
class D : B {
       public new void foo() {
               Console.WriteLine("D:foo");
       }
}

public class Test5 {
       public static void T5Main(){
               B b = new D();
               b.foo();
               Console.WriteLine("Done");
       }
}
/*
Output:
B:foo
*/
}
