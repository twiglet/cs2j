using System;
namespace Tester
{
	// ordinary outer class
	public class FullOuterPartialInner
	{
		public FullOuterPartialInner ()
		{
		}
		
		public partial class PartialMiddle {
			// First part of inner
			public partial class PartialInner {
				
				// interface
				public partial interface PartialIF {
					int metha(int fred);
				}
				
				// member a
				public int a = 0;
			}
			
			// middlea member
			public int middlea = 0;
		
		}
		
		// a outer member
		public int outera = 0;
			

		public partial class PartialMiddle {
			
			// middle b member	
			public int middleb = 0;

			// Second part of inner
			public partial class PartialInner {
				// member b
				public int b = 0;

				public partial interface PartialIF {
					int methb(char fred);
				}
			}
		}
	}
}

