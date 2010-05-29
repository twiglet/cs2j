
-- Rebuild cs parser

cd "\Documents and Settings\DevUser\My Documents\gitrepos\CSharpTranslator"

java -Xmx512m -jar jar\antlr-3.2.jar src\cs2j\CSharp\cs.g
java -Xmx512m -jar jar\antlr-3.2.jar -debug src\cs2j\CSharp\cs.g

src\cs2j\bin\Debug\cs2j.exe -netdir "c:\Documents and Settings\DevUser\My Documents\TrunkBranch\CS2JLibrary" -appdir "c:\Documents and Settings\DevUser\My Documents\Visual Studio 2005\Projects\ScormEngineNetTrunk\src\app\ScormEngine.Core" "c:\Documents and Settings\DevUser\My Documents\Visual Studio 2005\Projects\ScormEngineNetTrunk\src\app\ScormEngine.Core\Logic"

C:\Documents and Settings\DevUser\My Documents\gitrepos\CSharpTranslator>src\cs2
j\bin\Debug\cs2j.exe -netdir "c:\Documents and Settings\DevUser\My Documents\Tru
nkBranch\CS2JLibrary" -appdir "c:\Documents and Settings\DevUser\My Documents\Vi
sual Studio 2005\Projects\ScormEngineNetTrunk\src\app\ScormEngine.Core\Util\Cach
ing\NullCache.cs" "c:\Documents and Settings\DevUser\My Documents\Visual Studio
2005\Projects\ScormEngineNetTrunk\src\app\ScormEngine.Core\Logic"

src\cs2j\bin\Debug\cs2j.exe -mindriver C:\Documents and Settings\DevUser\My Documents\kgtemp\getClass.cs
